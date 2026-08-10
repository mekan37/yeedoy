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
- Müşteri, damga/puanını QR okutma, yorum bırakma veya fiş/makbuz OCR yoluyla kazanabilsin.
- Owner, kasada QR okutarak damga/puan ekleyebilsin ve eşiğe ulaşan müşterinin ödülünü aynı akıştan "kullanıldı" işaretleyebilsin.
- Müşteri kartlarını hem mobil uygulamada hem web'de görebilsin.
- Zincirlerde (Çoklu Şube) programı zincir çapında tek ve ortak tutmak.
- Premium plan özelliği olarak gate'lemek.

## Kapsam Dışı (v1, YAGNI)

- Doğum günü bonusu, "sizi özledik" hatırlatması, eşiğe yaklaşınca otomatik push — eski tasarımda zaten bozuk çıkmıştı (var olmayan kolona erişiyordu), v1'de yok. İleride ayrı bir faz.
- Müşterinin kendi kendine "ödülü kullandım" işaretlemesi — kötüye kullanım riski nedeniyle yalnızca owner onaylı akış var.
- Şube bazlı ayrı programlar — zincirlerde her zaman tek, ortak program.

## Veri Modeli

```
loyalty_programs
  id                uuid pk
  business_id       uuid  -- tekli işletmede kendi id, zincirde zincir çapası id
                          -- (Çoklu Şube'nin mevcut zincir çözümleme mekanizması
                          -- kullanılır: uygulamalar/web/app/sahip/coklu-sube/coklu-sube-yardimcilari.ts)
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
  source      text check in ('qr_scan','review','receipt_ocr','redeem')
  amount      int
  actor_id    uuid  -- qr_scan: okutan owner/personel; review/receipt_ocr: null (sistem); redeem: owner
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

**Sistem içi (public RPC değil, trigger/OCR sonrası sunucu tarafından çağrılır):**
- `_award_loyalty_progress(p_program_id, p_user_id, p_amount, p_source)` — yorum onaylanınca (`trg_award_loyalty_on_review` deseni) veya makbuz OCR onaylanınca çağrılır. Client'tan doğrudan erişilemez.

**Müşteri (authenticated):**
- `get_my_loyalty_cards_v1()` — tüm kartları (program adı, mode, progress, threshold, reward_desc, business adı/logo) tek şekilde döner

## Akışlar

1. **Kurulum:** Owner `/sahip/pazarlama/sadakat`'ta (şu an redirect stub, bu implementasyonla gerçek sayfa olacak) mode seçer, program bilgilerini girer → `create_loyalty_program_v1` → sonra `set_loyalty_program_active_v1(true)`.
2. **Kazanma — QR:** Owner kasada tarayıcı kamerasıyla müşteri QR'ını okutur → `scan_loyalty_qr_v1`.
3. **Kazanma — Yorum:** Yorum `approved` olunca trigger `_award_loyalty_progress(..., source='review')` çağırır.
4. **Kazanma — Fiş OCR:** Mevcut makbuz-ocr akışının onay adımı sonunda aynı iç fonksiyon `source='receipt_ocr'` ile çağrılır.
5. **Kullanma:** Eşiğe ulaşan üye owner'a kartını gösterir, owner "Ödülü Kullan" ile `redeem_loyalty_reward_v1` çağırır.
6. **Görüntüleme:** Müşteri mobil "Kartlarım" veya web `/sadakat`'ta `get_my_loyalty_cards_v1()` ile kartlarını görür.

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
- Review/OCR tetikleyicileri public RPC değil, client'tan doğrudan çağrılamaz.

## Premium Gating

`create_loyalty_program_v1` ve `set_loyalty_program_active_v1`, mevcut premium plan gating altyapısı üzerinden (harita boost'ta kullanılan desenin aynısı — implementasyon planında tam fonksiyon adı doğrulanacak) free plan sahiplerini engeller. Web UI'da kilitli/premium rozeti gösterilir.

## Eski Koddan Geçiş

İmplementasyonun ilk adımı, üç eski migration'ın (`20260424000007`, `20260424000010`, `20260507000008`) tüm tablo/fonksiyon/trigger'larını `DROP` eden bir migration'dır (bu analiz sırasında zaten envanteri çıkarıldı), ardından yukarıdaki yeni şema `CREATE` edilir — aynı migration dosyasında birleştirilebilir. Ölü web dosyaları (`app/(auth)/loyalty/page.tsx`, `app/(kimlik)/sadakat/page.tsx`, `app/sunucu/sahip/sadakat/route.ts`) silinip yerine gerçek sayfalar yazılır; `app/sahip/pazarlama/sadakat/page.tsx` redirect stub'ı gerçek kurulum sayfasına dönüşür. Mobildeki `features/sadakat/` klasörü ve `router.dart`'taki `/loyalty-cards` girişi yeni şemaya göre yeniden yazılır (redirect kaldırılır, gerçek nav girişi eklenir).

## Test Stratejisi

- **DB:** `supabase db reset` ile local doğrulama (proje pgTAP kullanmıyor).
- **Web:** RPC çağıran server action'lar için vitest unit test; Playwright ile owner kurulum + QR tarama e2e akışı.
- **Mobil:** `flutter test` ile `myLoyaltyCardsProvider` ve kart parsing testleri.
