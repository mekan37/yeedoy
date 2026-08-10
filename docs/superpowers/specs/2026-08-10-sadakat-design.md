# Sadakat (Loyalty) Sistemi — Design Doc

## Bağlam

Kullanıcının owner panel özellik öncelik sırası **"Destek → Çoklu Şube → Sadakat → CRM"** (bkz. `docs/superpowers/specs/2026-08-06-destek-sistemi-design.md` §Bağlam). Destek ve Çoklu Şube tamamlandı; Sadakat sıradaki özellik.

Repo'da hâlâ iki eski, çakışan ve tamamen ölü sadakat tasarımı duruyor:
- `20260424000007_loyalty_program.sql` — puan-bazlı tasarım (`loyalty_accounts`, `upsert_loyalty_program_v1` vb.)
- `20260507000008_sadakat_karti.sql` — damga-kartı tasarımı (`loyalty_cards`, `create_loyalty_program_v1` vb.), aynı `loyalty_programs` tablosunu ikinci kez farklı şemayla `ALTER` etmiş
- `20260424000010_loyalty_automations.sql` — P4 otomasyon eklentisi (doğum günü/eşik/"sizi özledik"), cron'u zaten `20260723000003_unschedule_dead_cron_jobs.sql`'de bozuk olduğu için iptal edilmiş

Her üçü de hiçbir gerçek UI'a bağlı değil (route'lar redirect/410 ile kapalı, `docs/product/2026-yeedoy-final-scope-source-of-truth.md`'a göre MVP kapsamı dışı işaretlenmiş). Bu doküman, onların yerine geçecek **tek, birleşik ve baştan doğru** bir tasarımı tanımlar. İmplementasyonun ilk adımı eski üç migration'ın etkisini geri almak olacak (aşağıda §Eski Koddan Geçiş).

## Hedefler

- Owner, kendi işletmesi (veya zinciri) için damga-kartı **ya da** puan-sistemi modunda bir sadakat programı kurabilsin.
- Müşteri, damga/puanını QR okutma veya yorum bırakma yoluyla kazanabilsin.
- Owner, kasada QR okutarak damga/puan ekleyebilsin ve eşiğe ulaşan müşterinin ödülünü aynı akıştan "kullanıldı" işaretleyebilsin.
- Müşteri kartlarını hem mobil uygulamada hem web'de görebilsin.
- Zincirlerde (Çoklu Şube) programı zincir çapında tek ve ortak tutmak.
- Premium plan özelliği olarak gate'lemek.

## Kapsam Dışı (v1, YAGNI)

- Doğum günü bonusu, "sizi özledik" hatırlatması, eşiğe yaklaşınca otomatik push — eski tasarımda zaten bozuk çıkmıştı (var olmayan kolona erişiyordu), v1'de yok. İleride ayrı bir faz.
- Müşterinin kendi kendine "ödülü kullandım" işaretlemesi — kötüye kullanım riski nedeniyle yalnızca owner onaylı akış var.
- Şube bazlı ayrı programlar — zincirlerde her zaman tek, ortak program.
- **Fiş/makbuz yükleme ile kazanma** — araştırma sırasında ortaya çıktı: `app/(genel)/makbuz-yukle/`, `app/sunucu/makbuz-ocr/route.ts`, `app/yonetici/fis-basvurulari/` sadakat için değil, **fiyat endeksi** (crowdsourced fiyat doğrulama) özelliği için var; admin onayı sadece inceleme durumu günceller, "onaylandı → ödül ver" çıkışı yok. Sadakat için fiş bazlı kazanma, sıfırdan bir OCR+dolandırıcılık-kontrolü akışı gerektirir — v1 kapsamı dışına alındı, ayrı bir faz olarak ele alınabilir.

## Veri Modeli

```
loyalty_programs
  id                uuid pk
  business_id       uuid null references businesses(id)  -- tekli işletme sahipliği
  chain_id          uuid null references chains(id)       -- zincir sahipliği
                          -- CHECK: (business_id IS NOT NULL) <> (chain_id IS NOT NULL) — ikisinden tam biri set olur.
                          -- Çözümleme: verilen bir p_business_id için önce businesses.chain_id'ye bakılır;
                          -- doluysa o chain_id'nin programı kullanılır, boşsa business_id'nin kendi programı
                          -- (bkz. 20260806000004_coklu_sube_owner.sql — chain_id modeli, chains tablosu).
  mode              text  check in ('stamp','points')
  name              text
  reward_desc       text
  reward_threshold  int   -- damgada "kaç damga", puanda "kaç puan"
  is_active         boolean default false
  created_at        timestamptz default now()

loyalty_members
  id             uuid pk
  program_id     uuid fk -> loyalty_programs(id)
  user_id        uuid fk -> auth.users(id)
  progress       int default 0   -- damga sayısı veya puan
  redeemed_count int default 0
  updated_at     timestamptz default now()
  unique(program_id, user_id)

loyalty_events
  id          uuid pk
  member_id   uuid fk -> loyalty_members(id)
  source      text check in ('qr_scan','review','redeem')
  amount      int
  actor_id    uuid  -- qr_scan: okutan owner/personel; review: null (sistem); redeem: owner
  created_at  timestamptz default now()
```

**RLS:** `loyalty_members` ve `loyalty_events`'te client rollerine (`authenticated`) hiçbir INSERT/UPDATE GRANT'ı yok — tüm yazımlar SECURITY DEFINER RPC'ler üzerinden. Müşteri sadece kendi `loyalty_members` satırını SELECT edebilir. `loyalty_programs` herkese SELECT (public read, mevcut desenle aynı), yazma yalnızca owner/admin.

Bu, eski `loyalty_program.sql`'deki `loyalty_accounts_definer_write` politikasının (yorumda "sadece definer fonksiyon" dese de fiilen `auth.uid() = user_id` ile direkt yazıma açık olan) güvenlik açığını yapısal olarak kapatır.

## RPC Yüzeyi

**Owner (`is_owner_of_business`/zincir eşleniği + premium plan kontrolü ile korunur):**
- `create_loyalty_program_v1(p_business_id, p_mode, p_name, p_reward_desc, p_reward_threshold)` → `is_active=false` başlar
- `set_loyalty_program_active_v1(p_program_id, p_is_active)` — eski tasarımda eksik olan aktivasyon adımı
- `scan_loyalty_qr_v1(p_program_id, p_user_id)` — `source='qr_scan'`, `loyalty_events`'e yazar + `loyalty_members.progress` artırır. Rate limit: aynı `(program_id, user_id)` çiftinde son 60 saniyede ikinci `qr_scan` varsa hata.
- `redeem_loyalty_reward_v1(p_member_id)` — `progress -= reward_threshold`, `redeemed_count += 1`, `source='redeem'` event
- `get_business_loyalty_members_v1(p_business_id)` — owner CRM listesi

**Sistem içi (public RPC değil, trigger tarafından çağrılır):**
- `_award_loyalty_progress(p_program_id, p_user_id, p_amount, p_source)` — yorum onaylanınca (`trg_award_loyalty_on_review` deseni) çağrılır. Client'tan doğrudan erişilemez.

**Müşteri (authenticated):**
- `get_my_loyalty_cards_v1()` — tüm kartları (program adı, mode, progress, threshold, reward_desc, business adı/logo) tek şekilde döner

## Akışlar

1. **Kurulum:** Owner `/sahip/pazarlama/sadakat`'ta (şu an redirect stub, bu implementasyonla gerçek sayfa olacak) mode seçer, program bilgilerini girer → `create_loyalty_program_v1` → sonra `set_loyalty_program_active_v1(true)`.
2. **Kazanma — QR:** Owner kasada tarayıcı kamerasıyla müşteri QR'ını okutur → `scan_loyalty_qr_v1`.
3. **Kazanma — Yorum:** Yorum `approved` olunca trigger `_award_loyalty_progress(..., source='review')` çağırır.
4. **Kullanma:** Eşiğe ulaşan üye owner'a kartını gösterir, owner "Ödülü Kullan" ile `redeem_loyalty_reward_v1` çağırır.
5. **Görüntüleme:** Müşteri mobil "Kartlarım" veya web `/sadakat`'ta `get_my_loyalty_cards_v1()` ile kartlarını görür.

## UI

- **Owner web paneli** (`/sahip/pazarlama/sadakat`): kurulum formu (mode toggle, ad, ödül açıklaması, eşik, aktif/pasif) + QR tarama ekranı (tarayıcı kamerası, ilerleme çubuğu, "+1 Ekle"/"Ödülü Kullan" butonları) + üye listesi (CRM).
- **Mobil "Kartlarım"** (`features/sadakat/` yeniden yazılacak): ilerleme çubuklu kart listesi, her kart işletme adı/logosu + progress + ödül açıklaması gösterir.
- **Web `/sadakat`** (şu an redirect stub, gerçek sayfa olacak): aynı kart listesi, giriş yapmış müşteri için.

Mockup'lar onaylandı (bkz. brainstorming oturumu — sahip kurulum/tarama ekranı ve müşteri kart görünümü).

## Güvenlik

- QR ekleme/redeem sadece owner/personel, kendi işletmesi (veya zinciri) için.
- Rate limit: aynı üye için art arda `qr_scan` engellenir.
- Müşteri kendi `redeem` çağıramaz.
- `loyalty_members`/`loyalty_events` client'a yazma GRANT'ı yok, sadece SECURITY DEFINER RPC üzerinden.
- Review tetikleyicisi public RPC değil, client'tan doğrudan çağrılamaz.
- **Kritik ders (Faz 1'de production'da bulundu ve düzeltildi):** Bu projede yeni oluşturulan her fonksiyon üç ayrı katmandan otomatik yürütme hakkı kazanabilir — (1) Postgres'in "yeni fonksiyon varsayılan olarak PUBLIC'e açık" davranışı, (2) projeye özel `ALTER DEFAULT PRIVILEGES` ile `anon`/`authenticated`'a otomatik GRANT. Sadece `REVOKE ALL ... FROM PUBLIC` yazmak yetmez — `anon` rolü PUBLIC'ten miras yoluyla hâlâ çalıştırabilir. Her yeni fonksiyon (özellikle "internal, hiçbir client'a açık değil" diye tasarlananlar) için üçünü de açıkça kapatmak gerekir: `REVOKE ALL ... FROM PUBLIC` + `REVOKE EXECUTE ... FROM anon` + gerekiyorsa `REVOKE EXECUTE ... FROM authenticated`. `_get_business_plan_tier_v1` (20260803000001_premium_plan_foundation.sql) bu üçünü de doğru uyguluyor, referans alınmalı. Faz 2-4'te yazılacak her yeni RPC bu üç REVOKE'u da içermeli — `mcp__supabase__get_advisors` (security) ile `anon_security_definer_function_executable` / `authenticated_security_definer_function_executable` bulgusu çıkmadığından emin olunmalı, ayrıca advisor cache'i gecikebileceğinden `has_function_privilege('anon', 'public.fn(...)', 'EXECUTE')` ile production'da doğrudan doğrulanmalı.

## Premium Gating

`create_loyalty_program_v1` ve `set_loyalty_program_active_v1`, mevcut premium plan gating altyapısı üzerinden (harita boost'ta kullanılan desenin aynısı — implementasyon planında tam fonksiyon adı doğrulanacak) free plan sahiplerini engeller. Web UI'da kilitli/premium rozeti gösterilir.

## Eski Koddan Geçiş

İmplementasyonun ilk adımı, üç eski migration'ın (`20260424000007`, `20260424000010`, `20260507000008`) tüm tablo/fonksiyon/trigger'larını `DROP` eden bir migration'dır (bu analiz sırasında zaten envanteri çıkarıldı), ardından yukarıdaki yeni şema `CREATE` edilir — aynı migration dosyasında birleştirilebilir. Ölü web dosyaları (`app/(auth)/loyalty/page.tsx`, `app/(kimlik)/sadakat/page.tsx`, `app/sunucu/sahip/sadakat/route.ts`) silinip yerine gerçek sayfalar yazılır; `app/sahip/pazarlama/sadakat/page.tsx` redirect stub'ı gerçek kurulum sayfasına dönüşür. Mobildeki `features/sadakat/` klasörü ve `router.dart`'taki `/loyalty-cards` girişi yeni şemaya göre yeniden yazılır (redirect kaldırılır, gerçek nav girişi eklenir).

## Test Stratejisi

- **DB:** `supabase db reset` ile local doğrulama (proje pgTAP kullanmıyor).
- **Web:** RPC çağıran server action'lar için vitest unit test; Playwright ile owner kurulum + QR tarama e2e akışı.
- **Mobil:** `flutter test` ile `myLoyaltyCardsProvider` ve kart parsing testleri.
