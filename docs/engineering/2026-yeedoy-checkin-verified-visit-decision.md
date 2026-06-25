# Yeedoy Check-in / Verified-Visit Karar Raporu

> **DEPRECATED / HISTORICAL CONTEXT:** Bu dosya tarihsel analizdir. Güncel scope kararı için bkz. `docs/product/2026-yeedoy-final-scope-source-of-truth.md`.

> **Tarih:** 2026-06-23
> **Kapsam:** Sadece check-in özelliği — mobil `log_checkin_v1` → `business_checkins` zinciri, web `submit_checkin_v1` → `visits` zinciri, `verified_visit` doğrulanmış yorum sistemiyle ilişkisi.
> **Yöntem:** Salt okunur statik analiz. Migration dosyalarının satır seviyesinde okunması, mobil/web kod tabanının grep/read ile taranması.
> **Bu rapor TAMAMEN READ-ONLY'dir.** Hiçbir dosya değiştirilmedi, hiçbir migration oluşturulmadı, hiçbir SQL çalıştırılmadı. Bu rapordaki tüm SQL örnekleri sadece "ileride böyle bir doğrulama/migration gerekebilir" göstergesi amaçlıdır, gerçek çalıştırılabilir kod bloğu olarak sunulmamıştır.
> **Supabase MCP read-only tool'ları (`list_tables`, `execute_sql` vb.) bu oturumda da tanımlı değildi.** Production'daki gerçek satır sayıları, gerçek tablo şemaları ve hangi trigger'ların kurulu olduğu bu oturumda doğrulanamadı. Tüm bulgular dosya/kod seviyesinde statik kanıttır.

---

## 1. Yönetici Özeti

- Mobil ve web, **iki farklı tabloya** check-in yazıyor: mobil `log_checkin_v1` → `business_checkins` (anon `client_id` bazlı, opsiyonel `user_id`); web `submit_checkin_v1` → `visits` (zorunlu `auth.users` FK'lı `user_id`, günde 1 limit).
- "Son 2 saatte check-in" özet rozetini okuyan `get_business_recent_checkins_v1` RPC'sinin **kesin kazanan/son tanımı** (`20260523000005_perf_rpc_query_fixes.sql:125`, `CREATE OR REPLACE FUNCTION`, migration sıralaması garantili) sadece **`visits`** tablosunu okuyor. Bu, üç ayrı tanımın (base_schema eski hali → check_in.sql → perf_rpc_query_fixes.sql) hepsinin aynı sonuca (visits) yakınsadığı, statik analizle ulaşılabilecek en kesin sonuçtur.
- **Karar açısından en kritik bulgu:** `verified_visit` / doğrulanmış yorum sistemi (`get_business_reviews_v3` içindeki inline `EXISTS` ifadesi, `20260523000005_perf_rpc_query_fixes.sql:62-69`) **doğrudan ve sadece `public.visits` tablosunu** okuyor — `business_checkins`'e hiç referans vermiyor. Yani **mobilin "Buradayım" chip'i `verified_visit` zincirine HİÇ girdi sağlamıyor.** Bu zincire girdi sağlayan tek yol, web'in `submit_checkin_v1` çağrısıdır — ki mobil uygulamada bu RPC'ye giden hiçbir çağrı yoktur.
- Sonuç: mobildeki check-in chip'i şu an **tek bir gözlemlenebilir etkisi olan, ama o etkinin de kullanıcıya hiç görünmediği bir özelliktir**: `trg_loyalty_checkin` trigger'ı üzerinden (kurulu ise) puan-modeli sadakat sistemine (P2, MVP dışı, zaten UI'dan henüz tam bağlı değil) sessizce puan yazdırıyor olabilir. P0 `verified_visit` zincirine hiçbir girdisi yok.
- **Görünürlük:** Bug kullanıcıya hata mesajı olarak GÖRÜNMÜYOR — `_handleCheckIn()` başarı ve hata durumunda **aynı** "Konum bildirimi kaydedildi" snackbar'ını gösteriyor (`business_state_views.dart:185-193`). Görünen tek etki: check-in yapan kullanıcı, aynı işletmenin "son 2 saatte N check-in" özet satırında (`_CheckinsSummaryLine`) kendi check-in'ini hiçbir zaman görmüyor — sayı sessizce eksik kalıyor. Bu küçük, düşük-fark edilirlikte ama gerçek bir veri tutarsızlığıdır.

**Net öneri: Seçenek B + kısmi A — "Buradayım" chip'i ve check-in UI'ı (chip + özet satırı) mobilde UI'dan gizlenmeli; `verified_visit` zaten check-in tablolarına bağımlı değil bu yüzden bu gizleme P0'ı hiç etkilemez. DB tarafına dokunulmaz, üçüncü bir DB doğrulama adımı (production satır sayıları) sonrasında nihai temizlik/birleştirme migration'ı (Seçenek C, düşük öncelik) ayrıca değerlendirilebilir.** Detay ve gerekçe §6'da.

---

## 2. Check-in Çağrı Zincirleri — Doğrulanmış Kod Kanıtı

### Zincir A — Mobil

```
uygulamalar/mobil/lib/features/business/ui/parts/business_state_views.dart
  └─ _ActionChip(label: 'Buradayım', onTap: _handleCheckIn)   [satır 215-219]
       └─ _handleCheckIn()                                      [satır 165-198]
            └─ checkInRepositoryProvider.logCheckin(...)
                 └─ uygulamalar/mobil/lib/features/business/data/check_in_repository.dart
                      └─ _client.rpc('log_checkin_v1', {p_business_id, p_menu_id, p_table_no, p_client_id})
```

`log_checkin_v1` (kesin/tek tanım — `00000000000000_base_schema.sql:12868-12930`):
- `business_checkins` tablosuna INSERT (`business_id`, `menu_id`, `table_no`, `client_id`, `user_id`).
- `client_id` zorunlu (anon cihaz kimliği, `getAnalyticsClientId()`); `user_id` opsiyonel (`auth.uid()`, null olabilir).
- 10 dakikalık aynı `(business_id, client_id, table_no)` dedup penceresi.
- Hata kodları: `invalid_business`, `client_required`, `business_not_found`, `menu_mismatch` — ama bu kodlar **mobil tarafta hiç okunmuyor**, `check_in_repository.dart` sadece exception fırlatıyor/yutuyor.

Mobil UI'da check-in için **giriş yapmış olmak zorunlu** (`_handleCheckIn` içinde `userProvider` null kontrolü, login sheet'e yönlendiriyor) — ama RPC'nin kendisi `user_id`'yi opsiyonel görüyor; mobil pratikte her zaman login sonrası çağırıyor olsa da DB seviyesinde bu garanti edilmiyor.

Okuma tarafı:
```
uygulamalar/mobil/lib/features/business/domain/business_checkins_provider.dart
  └─ businessRecentCheckinsProvider
       └─ client.rpc('get_business_recent_checkins_v1', {p_business_id, p_hours: 2})

uygulamalar/mobil/lib/features/business/ui/sections/business_detail_sections.dart
  └─ _CheckinsSummaryLine (satır ~610-624)  — "Konum doğrulaması: N" metnini render eder
```

### Zincir B — Web

```
uygulamalar/web/src/ui/acik/eylem-istemcisi.tsx:376
  └─ supabase.rpc('submit_checkin_v1', { p_business_id: businessId })
```

`submit_checkin_v1` (`20260507000002_check_in.sql:5-46`):
- `visits` tablosuna INSERT (`user_id`, `business_id`, `note`, `checked_in_at`).
- `user_id` **zorunlu** (`auth.uid()`, null ise `not_authenticated` döner).
- Günde 1 check-in limiti (aynı `user_id` + `business_id` + UTC gün).
- `visits.user_id` kolonu `NOT NULL REFERENCES auth.users(id)` — anonim check-in mümkün değil.

Web aynı zamanda `get_my_checkin_today_v1` ile "bugün check-in yaptın mı" kontrolü yapıyor (mobilde bu RPC'nin karşılığı yok).

### Ortak okuma noktası

Hem mobil (`business_checkins_provider.dart`) hem web (işletme detay sayfası) **aynı RPC'yi** çağırıyor: `get_business_recent_checkins_v1(p_business_id, p_hours=2)`.

---

## 3. `get_business_recent_checkins_v1` — 3 Tanım, Kesin Kazanan

| Sıra | Dosya:satır | Kaynak tablo | Not |
|---|---|---|---|
| 1 (en eski) | `00000000000000_base_schema.sql:8466-8479` | `business_checkins` | base_schema snapshot — ilk/eski hâl, mobil zincirine uygundu |
| 2 | `20260507000002_check_in.sql:90-106` | `visits` | `CREATE OR REPLACE FUNCTION` — kaynak tabloyu `business_checkins`'ten `visits`'e **değiştirdi** |
| 3 (kesin son) | `20260523000005_perf_rpc_query_fixes.sql:125-141` | `visits` | `CREATE OR REPLACE FUNCTION`, sadece `search_path` sertleştirmesi ekliyor, kaynak tablo aynı kalıyor: **`visits`** |

Migration dosya adları kronolojik sırayla uygulanır (Supabase migration sistemi garantisi) ve her ikisi de `CREATE OR REPLACE FUNCTION` kullanıyor (`IF NOT EXISTS` değil) — yani üzerine yazma kesindir, belirsizlik yoktur. **En son ve production'da çalışan tanım `visits` tablosunu okur.**

**Pratik sonuç:** Mobil check-in (`business_checkins`'e yazar) hiçbir zaman bu RPC'nin saydığı sayıya girmez. Sadece web check-in'leri (`visits`'e yazar) sayılır. Mobil kullanıcı "Buradayım"a bastığında kendi katkısının sayaca yansıdığını görmez.

---

## 4. `verified_visit` / Doğrulanmış Yorum Sistemi — Bağımsız mı, Bağımlı mı?

**Kesin cevap: `business_checkins`'e tamamen bağımsız, `visits`'e doğrudan bağımlı.**

`_review_verified_visit` helper fonksiyonu (`20260422000001_verified_visit_badge.sql:9-28`) ilk tasarımda **`crowd_checkins`** adlı (kodda hiçbir migration'da hiç `CREATE TABLE` edilmemiş, sadece bu dosyada referans verilen) bir tabloyu okuyacak şekilde yazılmıştı — bu muhtemelen erken bir taslak/yanlış-isim, hiçbir zaman çalışır hale gelmemiş bir ara adım.

Gerçek production davranışı, performans optimizasyonu migration'ında (`20260523000005_perf_rpc_query_fixes.sql:62-69`) netleşiyor — `get_business_reviews_v3` artık `_review_verified_visit` fonksiyonunu **çağırmıyor**, yerine satır içine (inline) alınmış bir `EXISTS` ifadesi kullanıyor:

```
EXISTS (
  SELECT 1 FROM public.visits v
  WHERE v.user_id = r.user_id
    AND v.business_id = r.business_id
    AND v.checked_in_at >= date_trunc('day', r.created_at)
    AND v.checked_in_at < date_trunc('day', r.created_at) + interval '1 day'
) AS verified_visit
```

Yani bir yorumun `verified_visit = true` olması için: aynı `user_id`'nin, yorumun yazıldığı **takvim gününde** `visits` tablosunda o işletmeye bir check-in kaydı olması gerekiyor. Bu **sadece** `submit_checkin_v1` (web) ile mümkün — `log_checkin_v1` (mobil) `visits`'e hiç yazmıyor.

**Sonuç: Mobil "Buradayım" chip'i, P0 doğrulanmış-yorum zincirine SIFIR girdi sağlıyor.** Mobil kullanıcı check-in yapıp sonra yorum yazsa bile, o yorum hiçbir zaman `verified_visit = true` görünmeyecek — çünkü check-in `business_checkins`'e, doğrulama kontrolü `visits`'e bakıyor.

---

## 5. Rozet/Achievement Bağlantısı

`award_achievement_v1` / achievements_v2 zinciri (`_archive/20260321000013_achievements_v2.sql` ve devamı) tarandı — **hiçbir trigger veya RPC check-in event'ini (`business_checkins` veya `visits` INSERT'i) achievement/rozet tablosuna bağlamıyor.** Achievement sistemi tamamen ayrı bir alt sistem (review/photo/claim gibi başka olaylara bağlı).

Check-in'in DB'de bağlandığı **tek** otomasyon, `trg_loyalty_checkin` trigger'ıdır (`20260424000007_loyalty_program.sql:138-146`):

```
do $$
begin
  if exists (... table_name='business_checkins') then
    create trigger trg_loyalty_checkin
      after insert on public.business_checkins
      for each row execute procedure public.trg_award_loyalty_on_checkin();
  end if;
end $$;
```

- Bu trigger **koşullu** kuruluyor (`business_checkins` tablosu varsa). Önceki DB scope-cleanup raporu (`2026-yeedoy-db-scope-cleanup-risk-report.md` §3) bu tablonun base_schema'da **gerçekten var olduğunu** teyit etti — yani bu trigger'ın production'da kurulu olma ihtimali yüksek (ama bu oturumda da kesin teyit edilemedi, `pg_trigger` sorgusu gerekir).
- Kurulu ise: mobil check-in → `trg_award_loyalty_on_checkin()` → puan-modeli `loyalty_programs.checkin_points` alanına göre `award_loyalty_points_v1` çağrısı → `loyalty_accounts`'a puan yazar.
- Bu, **P2 sadakat/gamification** sistemine sessiz bir girdidir — kullanıcıya hiçbir UI'da gösterilmiyor (mobil kullanıcı arayüzü damga-modeli `SadakatKartlarimSayfasi`/`get_my_loyalty_cards_v1` gösteriyor, oysa bu trigger puan-modeline yazıyor — iki ayrı loyalty şeması arasındaki çakışma, bu raporun kapsamı dışındaki ayrı bir bug, bkz. DB scope-cleanup raporu §4.1).

---

## 6. Sorulara Net Cevaplar

**1. Check-in şu an SADECE gamification/rozet için mi kullanılıyor, yoksa başka bir P0/P1 akışına girdi sağlıyor mu?**

Mobil check-in (`business_checkins`) **hiçbir P0/P1 akışına girdi sağlamıyor.** Tek bağlantısı, koşullu kurulu olabilecek `trg_loyalty_checkin` üzerinden P2 puan-modeli sadakat sistemine. Achievement/rozet sistemine de bağlı değil (rozet check-in'den bağımsız tetikleniyor, başka olaylara bağlı). `get_business_reality_score_v1` RPC'si (base_schema'da var, `business_checkins` sayısını "presence" puanına dahil ediyor) hiçbir mobil/web/personel kod yolunda çağrılmıyor — yani bu da şu an kullanılmayan, ölü bir tüketicidir.

Web check-in (`visits`) ise P0 `verified_visit` zincirine **doğrudan girdi sağlıyor.**

**2. `verified_visit`/doğrulanmış yorum sistemi check-in tablolarına gerçekten bağımlı mı, yoksa bağımsız bir mekanizma mı?**

`visits` tablosuna **doğrudan ve münhasıran bağımlı** (§4). `business_checkins`'e hiç bağımlı değil. Bağımsız bir "QR okutma" veya "fotoğraf kanıtı" mekanizması da kodda bulunamadı — `verified_visit` tek kaynaklı, sadece `visits.checked_in_at` + `visits.user_id` karşılaştırmasına dayanıyor.

**3. Mobilin yazdığı tablo ile okuma RPC'sinin okuduğu tablo neden farklı — migration tarihçesi/sırası ne anlatıyor?**

Migration tarihçesi şunu gösteriyor: check-in özelliği **iki farklı tasarım döneminde iki kez** inşa edilmiş.
- Erken dönem (eski `_archive/20260310_000001_business_checkins.sql`, sonradan `00000000000000_base_schema.sql`'e konsolide edildi): anonim/cihaz-bazlı (`client_id`) check-in modeli, `business_checkins` tablosu. Mobil bu modele göre yazılmış ve **hiç güncellenmemiş**.
- Sonraki dönem (`20260507000002_check_in.sql`, tarih damgası mobil zincirinden ~bir ay sonra): kullanıcı-hesabı bazlı (`auth.users` FK'lı), günlük-limitli yeni bir check-in modeli, `visits` tablosu. Bu, web'in `submit_checkin_v1` ile kullandığı model — ve verified_visit'in de bağlandığı model.
- `get_business_recent_checkins_v1`, ikinci dönemde `CREATE OR REPLACE` ile **kasıtlı olarak** yeni tabloya (`visits`) yönlendirilmiş — ama bu değişiklik yapılırken mobil tarafın `log_checkin_v1`/`business_checkins`'e hâlâ yazdığı fark edilmemiş veya bilerek ele alınmamış. Backend tarafı tabloyu/RPC'yi taşımış, mobil entegrasyonu eski kalmış. Bu, klasik bir "backend modeli değişti, bir client tarafı güncellenmedi" senaryosu.

**4. Bu tutarsızlık kullanıcıya GÖRÜNÜR mü?**

Kısmen ve düşük şiddette görünür — hata mesajı OLARAK görünmez (sessizce başarısız "gibi" davranıyor, ama aslında log_checkin_v1 her zaman başarıyla `business_checkins`'e yazıyor, sadece kimsenin okumadığı bir tabloya). Spesifik olarak:
- `_handleCheckIn()` başarı/hata fark etmeksizin aynı "Konum bildirimi kaydedildi" mesajını gösteriyor (`business_state_views.dart:184-194`) — kullanıcı her durumda "işe yaradı" sanıyor.
- Görünen gerçek etki: kullanıcı check-in yapar, sonra aynı işletme sayfasındaki `_CheckinsSummaryLine` ("Konum doğrulaması: N") sayacının kendi check-in'ini **hiç yansıtmadığını** görür — ama bu sayaç zaten düşük öncelikli/dekoratif bir metin, kullanıcı bunu fark etmesi/önemsemesi düşük olasılık.
- Yorum yazma akışında **hiçbir görünür etkisi yok** çünkü `verified_visit` zaten check-in tablolarına değil `visits`'e bakıyor — mobil kullanıcı zaten hiçbir zaman `verified_visit` rozeti bekleyemez (check-in yapsın yapmasın), bu nedenle "verified_visit beklenip gelmedi" şeklinde bir kullanıcı şikâyeti riski de yok.

**5. MVP için en güvenli karar — B (+ kısmi A)**

> **Seçenek B: Sadece `verified_visit` için gereken minimal altyapı (web `submit_checkin_v1` → `visits`) kalsın; mobildeki gamification/sosyal check-in UI'ı (chip + özet satırı) kapatılsın.**

Gerekçe:
- `verified_visit` zaten `business_checkins`'e değil `visits`'e bağımlı (§4) — bu nedenle mobil chip'i kapatmak P0 doğrulanmış-yorum zincirini **hiçbir şekilde etkilemez.** Önceki oturumların "verified_visit zincirine girdi sağlayıp sağlamadığı netleşmediği için dokunulmadı" tereddütü bu raporla netleşmiştir — netleşmiştir ve **girdi sağlamadığı** kesinleşmiştir.
- Stratejik karar raporu (§7, §23) check-in'i zaten P2/"gamification merkezi mekanik olmasın" listesine koymuş — mobil check-in chip'i şu anki haliyle tam da bu "merkezi olmayan ama yine de canlı" durumdadır (flag-korumasız, business sayfasında her zaman görünür).
- Mobil tarafı kapatmak DB'ye dokunmaz (Seçenek A/B ortak özelliği) — `business_checkins` tablosu, `log_checkin_v1` RPC'si DB'de kalır (DO_NOT_REMOVE_PROD_RISK, önceki raporlarla uyumlu).
- Web tarafı (`submit_checkin_v1` → `visits`) **dokunulmamalı** — bu, P0 `verified_visit` özelliğinin canlı bağımlılığıdır.

Neden A (tam kapatma) değil: A, "tüm check-in'i UI'dan gizle, RPC'lere dokunma" derdi — ama web tarafındaki `submit_checkin_v1` zaten `verified_visit`'in girdisi, onu "check-in" şemsiyesi altında kapatmak yanlışlıkla P0'ı kırma riski taşır. B daha kesin bir ayrım yapıyor: mobil sosyal/gamification check-in'i kapat, web'in doğrulama-amaçlı check-in'ine dokunma.

Neden C (bug-fix migration) şimdi değil: tabloları birleştirmek (mobilin de `submit_checkin_v1`'i çağırması veya RPC'nin her iki tabloyu UNION etmesi) **additive bir DB değişikliği** gerektirir ve şu an hiçbir P0/P1 ihtiyacı bunu zorlamıyor — mobil check-in zaten P2/dekoratif. Mobil UI kapatıldıktan sonra bu ihtiyaç tamamen ortadan kalkar (kapalı bir özelliğin DB tutarlılığını düzeltmenin önceliği yoktur). C, sadece ileride check-in P2 olarak gerçek bir gamification mekaniği olarak geri açılırsa gündeme gelmeli.

Neden D (insan kararı, prod veri görmeden) gerekmiyor: Bu spesifik karar için prod veri gerekmiyor çünkü kanıt zaten kod seviyesinde kesin — `verified_visit`'in `visits`'e bağımlı olduğu, `business_checkins`'e bağımlı olmadığı migration metninden doğrudan okunabiliyor (yorum/SQL niyeti belirsiz değil, `EXISTS (... FROM public.visits ...)` açık). Prod veri sadece "ne kadar kullanıcı şu an mobil check-in yapıyor" sorusuna cevap verir — bu sayı kararın yönünü değiştirmez (zaten P2/dekoratif, etkisiz bir özellik), sadece kapatmanın "kaç kullanıcıyı şaşırtabileceği" risk büyüklüğünü gösterir.

**6. Production verisi görülmeden hangi aksiyon riskli olur?**

- **DROP/migration (Seçenek C, eğer şimdi yapılsaydı) riskli olurdu** — `business_checkins` veya `trg_loyalty_checkin`'in gerçekte kurulu olup olmadığı, kaç satır içerdiği, `loyalty_accounts`'a şu an aktif puan akıp akmadığı bilinmeden bu tabloyu/triggerı değiştirmek (DB scope-cleanup raporu §6 ile uyumlu) — **bu rapor C'yi zaten önermiyor, bu madde sadece gelecekte biri C'yi düşünürse uyarı amaçlı.**
- **Mobil check-in chip'ini tamamen "REMOVE_SAFE" (kod satırlarını silme) yerine "hide" (UI'dan koşullu gizleme) olarak yapmak daha güvenlidir** — DB tarafında ne kadar veri biriktiği bilinmeden RPC çağrı kodunu tamamen silmek yerine, geri alınabilir bir UI gizleme tercih edilmeli (flutter-expert'in genel "güvenli aksiyon" prensibiyle uyumlu, bkz. mvp-scope-prune-audit §14.2).
- Bu rapor kapsamında **DB satır sayısı bilinmemesi B kararını engellemiyor** çünkü B sadece UI/kod tarafında bir değişiklik öneriyor, DB'ye dokunmuyor.

---

## 7. Önerilen Sıradaki Adımlar (sadece tarif, kod/migration yazılmadı)

1. **Mobil UI değişikliği (önerilen, B kararının uygulanması):** `business_state_views.dart`'taki "Buradayım" `_ActionChip`'i ve `business_detail_sections.dart`'taki `_CheckinsSummaryLine` bloğunu kaldır/koşullu gizle. `checkInRepositoryProvider`, `check_in_repository.dart`, `businessRecentCheckinsProvider` dosyaları DB çağrısı kodu olarak kalabilir (kullanılmayan ama silinmemiş, ileride geri açılabilir P2 altyapısı) veya flutter-expert'in önerdiği güvenli-kaldırma sürecinden geçirilebilir — bu rapor ikisi arasında tercih dayatmıyor, sadece "UI'dan kaldır" kararını veriyor.
2. **Web tarafına DOKUNULMAZ** — `submit_checkin_v1`, `get_my_checkin_today_v1`, `eylem-istemcisi.tsx:376` çağrısı P0 `verified_visit` bağımlılığı nedeniyle aynen kalmalı.
3. **DB tarafına DOKUNULMAZ** — `business_checkins` tablosu, `log_checkin_v1` RPC'si, `get_business_recent_checkins_v1` (visits okuyan son hâli) hiçbiri değiştirilmez/silinmez. Bu rapor hiçbir DROP/ALTER önermez.
4. **İleride (opsiyonel, düşük öncelik, sadece bilgi amaçlı tarif — gerçek SQL değil):** Eğer bir gün backend ekibi `business_checkins` ve `visits` arasındaki split-brain'i gerçekten çözmek isterse, iki yol tarif edilebilir (her ikisi de additive, DROP içermez): (a) mobilin `log_checkin_v1` yerine `submit_checkin_v1`'i çağırmaya geçirilmesi — bu durumda mobil check-in de `verified_visit` zincirine girer; (b) `get_business_recent_checkins_v1`'in her iki tabloyu da (`business_checkins` UNION `visits`) sayacak şekilde güncellenmesi. Bu rapor ikisinden birini şimdi önermiyor çünkü B kararıyla mobil chip zaten kapatılacağı için bu ihtiyaç ortadan kalkıyor.
5. **Üçüncül, düşük öncelikli doğrulama (insan/Supabase MCP oturumu, sadece SELECT, B kararı için zorunlu değil ama genel DB sağlığı için önerilir — bu sorgular DB scope-cleanup raporundaki §7 listesiyle örtüşüyor, burada sadece check-in'e özgü olanlar tekrarlanıyor):**
   - `business_checkins` tablosunun var olup olmadığı ve satır sayısı.
   - `trg_loyalty_checkin` trigger'ının `pg_trigger`'da kurulu olup olmadığı.
   - `visits` tablosundaki satır sayısı (web check-in kullanım yoğunluğu — kaç gerçek `verified_visit` üretiliyor, bu da check-in'in P2 değerini ölçmek için faydalı olur ama B kararını değiştirmez).

---

## 8. Sonuç

Check-in özelliği iki ayrı, birbirinden bağımsız gelişmiş alt sisteme bölünmüş durumda: (1) mobilin eski, anonim/cihaz-bazlı, hiçbir P0 akışına bağlı olmayan, sadece olası bir P2 sadakat-puan triggerına bağlı "Buradayım" mekanizması; (2) web'in yeni, kullanıcı-hesabı bazlı, P0 `verified_visit` doğrulanmış-yorum sistemine doğrudan bağlı check-in mekanizması. Bu ayrım statik kod kanıtıyla kesinleştirilmiştir — `verified_visit` hesaplaması `visits` tablosuna bakıyor, `business_checkins`'e hiç bakmıyor.

Bu nedenle mobildeki check-in UI'ını (chip + özet satırı) kapatmak **P0 doğrulanmış-yorum özelliğini hiçbir şekilde riske atmaz** ve final stratejik karar raporunun "gamification/check-in MVP merkezinde olmamalı" ilkesiyle tam uyumludur. Web tarafı ve DB'ye dokunulmaması gerekir.
