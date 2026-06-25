# Yeedoy Loyalty/Sadakat — MVP Dışı Bırakma Kararı

> **DEPRECATED / HISTORICAL CONTEXT:** Bu dosya tarihsel analizdir. Güncel scope kararı için bkz. `docs/product/2026-yeedoy-final-scope-source-of-truth.md`.

> **Tarih:** 2026-06-23
> **Kapsam:** Salt okunur statik analiz — `supabase/migrations/`, `supabase/remote_schema_backup.sql`, mobil/personel/web kod tabanı.
> **Bu rapor TAMAMEN READ-ONLY bir karar/analiz dokümanıdır.** Hiçbir kod dosyası değiştirilmedi, hiçbir migration oluşturulmadı, hiçbir SQL çalıştırılmadı/yazılmadı (önerilen SQL'ler dahi gerçek çalıştırılabilir blok olarak yazılmamıştır — sadece tarif edilmiştir).
> **Referans dosyalar:** `docs/research/2026-yeedoy-stratejik-karar-raporu.md`, `docs/engineering/2026-yeedoy-db-scope-cleanup-risk-report.md`, `docs/engineering/2026-yeedoy-mvp-scope-prune-audit.md`, `docs/engineering/mobile-unwired-product-decision-report.md`.
> **Kritik metodolojik not:** `supabase/remote_schema_backup.sql` dosyasının kendi başlığı şunu açıkça belirtiyor: *"Method: Concatenated migration files (CLI dump unavailable — 403 on login role)"* — yani bu dosya **gerçek bir `pg_dump`/`information_schema` sonucu değildir**, sadece migration dosyalarının tarih sırasıyla art arda eklenmiş halidir. Bu oturumda da Supabase MCP read-only araçları (`list_tables`, `execute_sql`) tanımlı değildi. Dolayısıyla bu rapordaki "gerçek production şeması" tespitleri, migration dosyalarının statik okunmasından çıkarılan **en olası senaryodur, kesin teyit değildir.** §6'daki SELECT sorguları çalıştırılana kadar resmi olarak doğrulanmamış kabul edilmelidir.

---

## 1. Executive Summary + Net Karar

**NET KARAR: Loyalty/sadakat MVP'de TAMAMEN KAPALI kalmalı. Hiçbir kullanıcıya/işletmeye açık UI girişi olmamalı. DB nesneleri DROP edilmemeli, sadece additive/guard/comment seviyesinde dokunulmalı.**

Bu karar, final stratejik karar raporu §7/§23'ün "gamification/rozet/görev/check-in MVP'de merkezi mekanik değildir" ve "P2'ye kadar büyük yatırım yapılmaz" ilkesinin doğrudan bir uzantısıdır — sadakat/loyalty bu raporda check-in ile aynı P2 kategorisine giriyor.

**Bu oturumun en kritik 3 bulgusu:**

1. **Şema çakışması doğrulandı VE genişletildi — 2 değil 3 farklı şema varsayımı var.** Önceki raporlar puan-modeli (`20260424000007`, `business_id` PK) ile damga-modeli (`20260507000008`, `id` PK, `stamps_needed`/`reward_desc`) çakışmasını tespit etmişti. Bu oturum **üçüncü bir varsayımsal şema** buldu: web `(auth)/loyalty/page.tsx` ve `(kimlik)/sadakat/page.tsx` kullanıcı sayfaları, `loyalty_cards` tablosundan `.select('id, business_id, points, tier, businesses(...)')` ile **`points` ve `tier` kolonlarını** okumaya çalışıyor — bu kolonlar **hiçbir migration'da hiç tanımlanmamış** (gerçek `loyalty_cards` kolonları: `id, program_id, user_id, stamp_count, redeemed_at, created_at`). Bu üçüncü kod yolu da muhtemelen hatalı/boş sonuç döner.
2. **`20260622000001_loyal_customers_reward_fields.sql` (dünün tarihine yakın) kanıtı netleşti: puan-modeli şeması production'da kazanan/aktif şemadır.** Bu migration `get_business_loyal_customers_v1` fonksiyonunu `lp.reward_threshold_pts`/`lp.reward_type`/`lp.reward_value` kolonlarına `LEFT JOIN public.loyalty_programs lp on lp.business_id = la.business_id` ile erişecek şekilde güncelliyor. Bu, **`loyalty_programs.business_id` kolonunun (puan modeli PK'sı) gerçekten var olduğunu ve hâlâ aktif geliştirildiğini** gösteriyor — `id` PK'lı damga-modeli tablo tanımı hiçbir zaman gerçek tabloyu değiştirmemiş olmalı.
3. **Web owner panelinde, TR sidebar'dan (`sahip-kabuk-istemcisi.tsx`) gizlenmiş olsa da, EN owner panel ağacı (`app/owner/layout.tsx` → `OwnerShellClient`) üzerinden hâlâ TAM ÇALIŞAN, doğru şemayı (puan modeli) kullanan bir sadakat programı yönetim ekranı erişilebilir durumda** (`/owner/marketing` → `/owner/marketing/loyalty`). Bu, "nav'dan gizlendi" varsayımının **yanlış/eksik** olduğu, ayrı bir route ağacından (EN tree) hâlâ canlı erişilebilir bir yüzey olduğu anlamına gelir.

**Sonuç:** Sorun sadece "iki şema çakışıyor" değil; loyalty özelliği **4 farklı kod yolunda 3 farklı (kısmen) tutarsız varsayımla** uygulanmış durumda: (a) mobil müşteri tarafı puan-modeli RPC'lerini doğru çağırıyor, (b) personel/owner tarafı bir önceki düzeltmeyle (2026-06-22) puan-modeline geçirilmiş ve doğru çalışıyor, (c) web owner EN paneli puan-modelini doğru kullanıyor ama TR panelden farklı bir route ağacında, (d) web kullanıcı sayfaları (`/loyalty`, `/sadakat`) ve TR owner sayfası (`/sahip/pazarlama/sadakat`) damga-modeli varsayımıyla yazılmış ve gerçek şemayla uyumsuz veya zaten redirect ile devre dışı.

---

## 2. Şema Çakışması Detaylı Analiz (Kolon Kolon Karşılaştırma)

### 2.1 `loyalty_programs` — iki migration tanımı

| Kolon | `20260424000007_loyalty_program.sql` (puan modeli — KAZANAN, ilk çalışan) | `20260507000008_sadakat_karti.sql` (damga modeli — muhtemelen NO-OP) |
|---|---|---|
| PK | `business_id uuid PRIMARY KEY` | `id uuid PRIMARY KEY DEFAULT gen_random_uuid()` |
| `business_id` | (PK'nın kendisi) | `uuid NOT NULL` (FK, ayrı kolon) |
| `name` | **yok** | `text NOT NULL` |
| `stamps_needed` | **yok** | `int NOT NULL DEFAULT 10` |
| `reward_desc` | **yok** | `text NOT NULL` |
| `is_active` | `boolean default false not null` | `boolean NOT NULL DEFAULT TRUE` |
| `checkin_points` | `int default 10 not null` | **yok** |
| `review_points` | `int default 25 not null` | **yok** |
| `photo_points` | `int default 15 not null` | **yok** |
| `reward_threshold_pts` | `int default 500 not null` | **yok** |
| `reward_type` | `text default 'discount_pct' not null check(...)` | **yok** |
| `reward_value` | `int default 10 not null` | **yok** |
| `birthday_bonus_pts` | `int default 50 not null` | **yok** |
| `created_at` | `timestamptz default now()` | `TIMESTAMPTZ NOT NULL DEFAULT NOW()` |

`CREATE TABLE IF NOT EXISTS` PostgreSQL semantiği: tablo adı zaten varsa **hiçbir kolon kontrolü yapılmadan komut no-op olur**. Migration sırası (dosya adı = uygulama sırası, Supabase migration'ları kronolojik uygular):

1. `20260424000007` çalışır → `loyalty_programs` tablosu **puan-modeli şemasıyla** yaratılır.
2. `20260507000008` çalışır → tablo zaten var → `CREATE TABLE IF NOT EXISTS` **sessizce hiçbir şey yapmaz**, `name`/`stamps_needed`/`reward_desc` kolonları gerçek tabloya **eklenmez**.

**Bu oturumun ek kanıtı (§1 madde 2):** `20260622000001_loyal_customers_reward_fields.sql`, `get_business_loyal_customers_v1` fonksiyonunu `LEFT JOIN public.loyalty_programs lp ON lp.business_id = la.business_id` ile güncelliyor ve `lp.reward_threshold_pts`, `lp.reward_type`, `lp.reward_value` kolonlarını okuyor. Bu migration **dünün tarihine yakın** (2026-06-22) ve **başarıyla** (varsayılan olarak hatasız) deploy edilmiş kabul ediliyor — eğer `loyalty_programs.business_id` kolonu veya `reward_threshold_pts` kolonu gerçekte yoksa, bu migration'ın kendisi `CREATE OR REPLACE FUNCTION` aşamasında **derleme zamanı hata vermezdi** (PL/pgSQL/SQL fonksiyon gövdeleri varsayılan olarak syntax-check edilir ama kolon/tablo varlığı runtime'da kontrol edilir — `check_function_bodies` ayarına bağlı). Yani bu migration'ın "sorunsuz deploy olması" kesin kanıt değildir ama **fonksiyonun amacının ve önceki davranışının** puan-modeli şemasını hedeflediğini gösterir — bu da projenin kendi geliştirme ekibinin puan modelini "gerçek/aktif" şema olarak kabul ettiğinin dolaylı kanıtıdır.

### 2.2 `loyalty_cards` — sadece bir migration'da tanımlı

`20260507000008_sadakat_karti.sql`:
```
id UUID PK, program_id UUID (FK→loyalty_programs.id), user_id UUID, stamp_count INT, redeemed_at TIMESTAMPTZ, created_at TIMESTAMPTZ
```

**Bu tablo `loyalty_programs.id` kolonuna FK veriyor** (`program_id UUID NOT NULL REFERENCES loyalty_programs(id)`). Eğer gerçek `loyalty_programs` tablosunda `id` kolonu yoksa (puan-modeli şemasında PK `business_id`'dir, `id` kolonu hiç yoktur), **bu `CREATE TABLE` ifadesinin kendisi migration apply sırasında hata vermiş olmalıdır** (`loyalty_programs(id)` referans edilen kolon yoksa FK tanımı başarısız olur — bu, `CREATE TABLE IF NOT EXISTS`'in tablo-var-mı kontrolünden farklı bir hata sınıfıdır, çünkü `loyalty_cards` tablosu YENİ bir tablodur, `IF NOT EXISTS` koruması burada işe yaramaz).

**Bu, önceki raporların atladığı kritik bir ek bulgudur:** `loyalty_cards` tablosunun migration'ı, eğer `loyalty_programs.id` kolonu gerçekten yoksa, **kendisi de migration apply aşamasında tamamen başarısız olmuş olabilir** — yani `loyalty_cards` tablosu production'da **hiç var olmayabilir**. Bu, statik analizle kesinleştirilemez, §6'daki SELECT sorgusu ile doğrulanmalıdır (`to_regclass('public.loyalty_cards')`).

### 2.3 Üçüncü varsayımsal şema — web kullanıcı sayfaları

`uygulamalar/web/app/(auth)/loyalty/page.tsx` ve `app/(kimlik)/sadakat/page.tsx`:
```ts
.from('loyalty_cards')
.select('id, business_id, points, tier, businesses(name, slug)')
```

Bu sorgu `loyalty_cards.business_id`, `loyalty_cards.points`, `loyalty_cards.tier` kolonlarını talep ediyor. **Hiçbiri ne puan-modeli ne damga-modeli migration'ında tanımlı değil** (damga-modelinde `loyalty_cards.business_id` yok — `program_id` üzerinden dolaylı erişim var; `points`/`tier` kolonları hiçbir migration'da hiç geçmiyor). Bu sayfalar `error.code !== '42P01'` (relation does not exist) kontrolüyle hatayı yutuyor ve boş liste gösteriyor — yani **gerçek hata olsa da kullanıcıya sessizce "henüz kartınız yok" gösterilir**, crash yok ama veri de asla gelmez.

---

## 3. Hâlâ Loyalty RPC/Tablo Çağıran Kod Listesi (dosya:satır)

### Mobil (`uygulamalar/mobil/`)

| Dosya:satır | Çağrı | Şema uyumu |
|---|---|---|
| `lib/features/sadakat/domain/sadakat_saglayicisi.dart:43-46` | `get_loyalty_status_v1(p_business_id)` | ✅ Puan modeli — gerçek şemayla uyumlu |
| `lib/features/sadakat/domain/sadakat_saglayicisi.dart:128` | `get_my_loyalty_cards_v1()` | ✅ Puan modeli — fonksiyon gövdesi `loyalty_accounts`/`loyalty_programs.business_id`/`reward_threshold_pts` kullanıyor (20260424000007'deki tanım, sonraki migration'da function-level override yok çünkü `20260507000008`'deki `get_my_loyalty_cards_v1` de `CREATE OR REPLACE` ile yazılmış — **iki fonksiyon tanımı arasında hangisinin gerçekten kazandığı migration sırasına bağlı, §4'te ayrı ele alınıyor**) |
| `lib/app/router.dart:343-349` | `/loyalty-cards` route tanımı | Route var, hiçbir UI'dan artık tetiklenmiyor (nav kartı önceki bir cleanup dalgasında kaldırılmış) |
| `lib/features/sadakat/ui/sadakat_kartlarim_sayfasi.dart` | `myLoyaltyCardsProvider`'ı tüketen sayfa | Sadece `/loyalty-cards` route'undan render edilir |

### Personel (`uygulamalar/personel/`)

| Dosya:satır | Çağrı | Şema uyumu |
|---|---|---|
| `lib/features/sadakat/domain/sadakat_bildiricisi.dart:28-31` | `get_business_loyal_customers_v1(p_business_id, p_limit)` | ✅ Puan modeli — `mobile-unwired-product-decision-report.md` §4.1'e göre 2026-06-22'de düzeltildi |
| `lib/features/sadakat/domain/sadakat_bildiricisi.dart:50-57` | `award_loyalty_points_v1(p_user_id, p_business_id, p_points)` | ✅ Puan modeli — parametreler doğru |
| `lib/features/shared/ui/ana_kabuk.dart:9` | Sadakat sekmesi nav'dan gizlenmiş (yorum: "MVP scope: ... sadakat sekmeleri gizlendi") | Nav yok, route/kod kalmış |

### Web (`uygulamalar/web/`)

| Dosya:satır | Çağrı | Şema uyumu | Erişilebilirlik |
|---|---|---|---|
| `app/sunucu/sahip/sadakat/route.ts:26-31` | `create_loyalty_program_v1(p_business_id, p_name, p_stamps_needed, p_reward_desc)` | ❌ Damga modeli — gerçek tablo puan-modeliyse `INSERT INTO loyalty_programs (business_id, name, stamps_needed, reward_desc)` kolon-yok hatası verir | Route handler hâlâ var; sadece `sadakat-form.tsx`'in POST ettiği uç nokta |
| `app/sahip/pazarlama/sadakat/sadakat-form.tsx` | Yukarıdaki route'u çağıran form bileşeni | ❌ Damga modeli | **Render edilmiyor** — `app/sahip/pazarlama/sadakat/page.tsx` zaten `redirect('/sahip/gosterge-panosu')` yapıyor (önceki cleanup dalgasında guard'lanmış), form bileşeni import edilse de sayfa hiç render olmadan redirect tetikleniyor |
| `app/owner/marketing/loyalty/page.tsx` | `getOwnerLoyaltyPrograms()` → `.from('loyalty_programs').select('business_id, is_active, checkin_points, review_points, photo_points, reward_threshold_pts, reward_type, reward_value, birthday_bonus_pts')` | ✅ Puan modeli — gerçek şemayla tam uyumlu | **CANLI VE ERİŞİLEBİLİR** — `app/owner/layout.tsx` → `OwnerShellClient` sidebar'ında "Pazarlama" → `/owner/marketing` → "Sadakat Programı" linki (`owner-shell-client.tsx:25`, `app/owner/marketing/page.tsx:14`) |
| `app/owner/marketing/loyalty/loyalty-actions.ts:78-87` | `upsert_loyalty_program_v1(p_business_id, p_is_active, p_checkin_points, p_review_points, p_photo_points, p_reward_threshold_pts, p_reward_type, p_reward_value)` | ✅ Puan modeli — tam uyumlu, auth + ownership guard + form validation var | **CANLI** — yukarıdaki sayfadan submit edilebilir |
| `src/lib/veri/owner/sadakat.ts:24-45` | `getOwnerLoyaltyPrograms` repository fonksiyonu | ✅ Puan modeli | Yukarıdaki sayfanın repository katmanı |
| `app/(auth)/loyalty/page.tsx:14-20` | `.from('loyalty_cards').select('id, business_id, points, tier, businesses(...)')` | ❌ Hiçbir şemaya uymuyor (`points`/`tier` hiçbir migration'da yok) | Kullanıcı `/loyalty` sayfası — nav linki bulunamadı (grep boş döndü), muhtemelen sadece direkt URL ile erişilebilir |
| `app/(kimlik)/sadakat/page.tsx:38-44` | Aynı sorgu, TR sayfa | ❌ Aynı uyumsuzluk | Aynı durum — nav linki yok |
| `app/sahip/pazarlama/sadakat/page.tsx:10-12` | `redirect('/sahip/gosterge-panosu')` | N/A — guard | TR owner sidebar bu sayfaya zaten link vermiyor (önceki audit'te teyit edilmiş), sayfa kendisi de redirect ile kendini kapatmış — **çift güvenlik** |
| `app/sunucu/sahip/sms-kampanya/route.ts` | İlgisiz (SMS kampanya, loyalty değil) | — | Bu rapor kapsamı dışı |

---

## 4. UI Nav'dan Gizlemek Yeterli mi? — Runtime Erişilebilirlik Analizi

**Hayır, tam olarak yeterli değil — 3 ayrı "hâlâ erişilebilir" yol bulundu:**

1. **Mobil `/loyalty-cards` route'u** — GoRouter'da tanımlı, hiçbir auth/feature-flag guard'ı yok (`router.dart:343-349`). Hiçbir UI butonu artık bu route'a push yapmıyor (nav kartı önceki bir cleanup dalgasında kaldırılmış — bu oturum `features/profile` içinde grep ile teyit etti, sıfır eşleşme). **Ama route GoRouter ağacında tanımlı olduğu için, deep link (`yeedoy://loyalty-cards` benzeri, eğer uygulanmışsa) veya manuel `context.go('/loyalty-cards')` çağrısı ile hâlâ erişilebilir.** Bu "ölü route, kod kalıntısı" — pratik risk düşük ama teorik olarak sıfır değil.

2. **Web `/owner/marketing/loyalty`** — **bu en kritik bulgu.** TR sidebar (`sahip-kabuk-istemcisi.tsx`) bu sayfaya link vermiyor (önceki audit'in MVP-dışı sınıflandırması bu sidebar'a göre yapılmıştı), ama **EN owner route ağacı (`app/owner/layout.tsx`) kendi başına tam fonksiyonel bir panel** — kendi sidebar'ı (`OwnerShellClient`) "Pazarlama" → "Sadakat Programı" linkini içeriyor ve sayfa **gerçekten çalışıyor** (doğru şema, auth guard, ownership guard, rate limit yok ama form validation var). Bu, "nav'dan gizlendi" iddiasının bu route ağacı için **yanlış** olduğu anlamına gelir — TR ve EN route ağaçları arasındaki "hangisi kanon" sorusu önceki audit'te `NEEDS_HUMAN_DECISION` olarak işaretlenmişti (`2026-yeedoy-mvp-scope-prune-audit.md` §7, "Duplicate route ağaçları"), loyalty özelinde bu belirsizlik **doğrudan canlı bir MVP-dışı özelliğin erişilebilir kalmasına yol açıyor**.

3. **Web `/loyalty` ve `/sadakat` kullanıcı sayfaları** — hiçbir nav linki bulunamadı (grep ile `src/ui/` altında sıfır eşleşme), ama Next.js App Router'da bir `page.tsx` dosyası var olduğu sürece **doğrudan URL ile her zaman erişilebilir** (Next.js statik route guard'ı yoksa herkes `/loyalty` yazıp gidebilir). Bu sayfalar auth kontrolü yapıyor (`user` null ise muhtemelen `businesses` join'i patlar ama sayfa try/catch ile sessizce boş liste gösteriyor) — yani bir giriş yapmış kullanıcı bu sayfaya gidip "Henüz puan kartınız yok" boş ekranını görebilir. Düşük risk (boş ekran, crash yok) ama **MVP-dışı bir özelliğin URL'i hâlâ canlı ve indexlenebilir** (metadata `robots: noindex` ile arama motorundan gizlenmiş, ama doğrudan link paylaşımına karşı korumasız).

**Sonuç:** Mobil ve personel tarafında nav-gizleme pratik olarak yeterli (route'lar var ama tetikleyici UI yok). **Web tarafında YETERSİZ** — özellikle `/owner/marketing/loyalty` gerçek bir fonksiyonel yüzey olarak hâlâ açık.

---

## 5. KEEP_HIDDEN / REMOVE_SAFE / DO_NOT_REMOVE_PROD_RISK Sınıflandırması

| # | Öğe | Sınıf | Gerekçe |
|---|---|---|---|
| 1 | `loyalty_programs`, `loyalty_accounts` tabloları (puan modeli) | **DO_NOT_REMOVE_PROD_RISK** | Gerçek/aktif şema, hâlâ geliştiriliyor (20260622 migration), web owner paneli ve personel app bu tabloya gerçekten yazıyor/okuyor olabilir |
| 2 | `loyalty_cards` tablosu (damga modeli) | **DO_NOT_REMOVE_PROD_RISK** (ama varlığı dahi şüpheli) | §2.2'de açıklanan FK riski nedeniyle bu tablo production'da hiç var olmayabilir; varsa da DROP önerilmez, önce §6 sorgusu ile doğrulanmalı |
| 3 | `create_loyalty_program_v1`, `add_loyalty_stamp_v1` RPC'leri | **DO_NOT_REMOVE_PROD_RISK** (ama çağıran tek nokta zaten guard'lı) | Fonksiyonlar production'da kayıtlı olabilir; DROP yerine "kullanılmıyor" olarak işaretlenmeli. Tek çağıran kod (`sunucu/sahip/sadakat/route.ts`) UI tarafı zaten redirect ile kapalı |
| 4 | `get_my_loyalty_cards_v1` (damga-modeli son `CREATE OR REPLACE`, 20260507000008'deki) | **NEEDS_HUMAN_DECISION (acil değil ama önemli)** | Mobil bu fonksiyonu çağırıyor; fonksiyonun GERÇEKTE hangi gövdeyle production'da kayıtlı olduğu (puan mı damga mı) §6 sorgusuyla netleşmeden, mobil tarafın çalışıp çalışmadığı kesinleşmez — bkz. §7 |
| 5 | Mobil `/loyalty-cards` route + `sadakat_kartlarim_sayfasi.dart` | **KEEP_HIDDEN** | Nav'dan zaten kaldırılmış, route/kod kalsın, ek aksiyon gerekmiyor — düşük risk |
| 6 | Personel `sadakat_bildiricisi.dart`, `sadakat_sayfasi.dart`, nav sekmesi | **KEEP_HIDDEN** | Zaten gizlenmiş (CLAUDE.md/MEMORY.md P1-6 notu), kod doğru şemaya göre çalışıyor durumda, dokunma |
| 7 | Web `/sahip/pazarlama/sadakat/page.tsx` (TR, redirect guard'lı) | **KEEP_HIDDEN** | Zaten kendi kendini redirect ile kapatmış, en güvenli durum, dokunma |
| 8 | Web `app/sahip/pazarlama/sadakat/sadakat-form.tsx` | **REMOVE_SAFE** | Hiçbir zaman render edilmiyor (sayfa redirect ile kendini kapatıyor öncesinde), gerçek dead code. Ama düşük öncelik — zararsız, acil silinmesi gerekmiyor |
| 9 | Web `app/sunucu/sahip/sadakat/route.ts` | **KEEP_HIDDEN** (REMOVE_SAFE değil) | Route handler kodu kendisi zararsız (auth+rate-limit+zod var), ama çağırdığı RPC muhtemelen production'da hata veriyor. Silinmesi gerekmiyor çünkü hiçbir UI çağırmıyor; silinirse ileride "neden yok" sorusu sorulur, COMMENT ile işaretlenmesi yeterli |
| 10 | **Web `/owner/marketing/loyalty/page.tsx` + `loyalty-form.tsx` + `loyalty-actions.ts` + `src/lib/veri/owner/sadakat.ts`** | **NEEDS_HUMAN_DECISION (ACİL — bu raporun en kritik maddesi)** | Bu **doğru çalışan, doğru şemayı kullanan, canlı erişilebilir** bir sadakat özelliği. MVP-dışı kararına göre **kapatılmalı** ama "zaten gizli" değil — gerçek bir aktif kapatma aksiyonu (route guard/redirect eklenmesi) gerekiyor. Bu, kod değişikliği gerektirir, bu rapor SADECE bu ihtiyacı tespit eder, kapatmayı bu oturumda yapmaz |
| 11 | Web `app/(auth)/loyalty/page.tsx`, `app/(kimlik)/sadakat/page.tsx` | **NEEDS_HUMAN_DECISION** | Nav linki yok ama URL canlı, hiçbir şemaya uymayan sorgu var (sessizce boş döner, crash yok). MVP-dışı karar gereği kapatılmalı (redirect veya 404), ama düşük risk olduğu için aciliyeti madde 10'dan az |
| 12 | `trg_loyalty_review`, `trg_loyalty_checkin` trigger'ları | **DO_NOT_REMOVE_PROD_RISK** | DROP edilirse review/check-in insert akışını kırabilir (trigger zincirine bağımlı); UI-hide güvenli, DB-DROP yasak |
| 13 | `award_loyalty_points_v1`, `upsert_loyalty_program_v1`, `get_loyalty_status_v1`, `get_my_loyalty_cards_v1` (puan-modeli sürümleri), `get_business_loyal_customers_v1` | **DO_NOT_REMOVE_PROD_RISK** | Mobil + personel + web owner EN paneli tarafından gerçekten kullanılıyor; DROP edilirse 3 farklı yüzeyde runtime hatası |

---

## 6. Mobildeki Damga-Modeli RPC Çağrıları Gerçekten Hata Veriyor mu?

**Soru:** Mobil `get_my_loyalty_cards_v1()` çağrısı production'da hata veriyor mu?

**Cevap: Statik analizle KESİNLEŞTİRİLEMEDİ, ama en olası senaryo "hayır, hata vermiyor, çünkü kazanan fonksiyon gövdesi muhtemelen puan-modeli sürümüdür."**

**Gerekçe:** İki migration'da da `get_my_loyalty_cards_v1` fonksiyonu var:
- `20260424000007` (önce çalışır): `drop function if exists ...; create or replace function ...` — puan modeli gövdesi (`loyalty_accounts`/`loyalty_programs.business_id` okur, JSON array döner).
- `20260507000008` (sonra çalışır): `CREATE OR REPLACE FUNCTION get_my_loyalty_cards_v1() RETURNS TABLE(...)` — damga modeli gövdesi (`loyalty_cards`/`loyalty_programs.id` okur, **farklı return type**: `TABLE(...)` değil `RETURNS jsonb` idi öncekinde).

**Kritik nokta — return type değişikliği:** PostgreSQL'de `CREATE OR REPLACE FUNCTION` aynı isim+parametre imzasına sahip bir fonksiyonun **return type'ını değiştiremez** (`cannot change return type of existing function` hatası verir), eğer return type değişiyorsa önce `DROP FUNCTION` gerekir. `20260424000007`'deki fonksiyon `returns jsonb`, `20260507000008`'deki `RETURNS TABLE(...)` — **bu ikisi farklı return type'lar.** Eğer `20260507000008` migration'ı önce bir `DROP FUNCTION get_my_loyalty_cards_v1()` yapmadan direkt `CREATE OR REPLACE FUNCTION ... RETURNS TABLE(...)` çalıştırdıysa (dosya içeriği bunu doğruluyor — `20260507000008_sadakat_karti.sql:95` satırında öncesinde `DROP FUNCTION` yok), **bu migration'ın kendisi `42P13: cannot change return type of existing function` hatasıyla başarısız olmuş olabilir.**

**Eğer bu migration apply aşamasında başarısız olduysa:** `get_my_loyalty_cards_v1` fonksiyonu production'da hâlâ **puan-modeli gövdesiyle** (jsonb dönen, `20260424000007`'deki) kayıtlıdır ve mobilin `res as List` cast'i (`sadakat_saglayicisi.dart:130`) **doğru çalışır** çünkü puan-modeli fonksiyonu da `jsonb_agg(...)` ile bir array döndürüyor (`mobile-unwired-product-decision-report.md` §4.1'in 2026-06-22 düzeltme notu da bunu doğruluyor: *"fonksiyon jsonb_agg(...) ile bir JSON dizisi döndürüyor ... mobildeki res as List cast'i doğru çalışıyor, runtime crash yok"*).

**Eğer migration başarıyla apply olduysa (örn. Supabase migration runner `DROP FUNCTION`'ı otomatik ima ediyorsa ya da signature'da OUT parametre farkı vardı):** O zaman gerçek kazanan fonksiyon damga-modeli `TABLE(...)` sürümüdür ve bu, `loyalty_cards`/`loyalty_programs.id` join'ine bağımlıdır — eğer `loyalty_cards` tablosu kendisi de var olmuyorsa (§2.2'deki FK riski), bu fonksiyon her çağrıda `relation "loyalty_cards" does not exist` hatası verir.

**Pratik sonuç — "önemi var mı?" sorusuna cevap:**

- **Önceki oturumun (`mobile-unwired-product-decision-report.md`) doğrudan production sorgulamasıyla (`pg_get_functiondef`) doğrulanmış bulgusu bu raporun statik analizinden daha güvenilirdir** ve şunu söylüyor: fonksiyon gerçekten `jsonb_agg` ile array dönüyor, mobil cast'i sorunsuz. Bu, kazanan gövdenin **puan-modeli** olduğunu ima eder.
- **Bu durumda mobil tarafı şu anda muhtemelen ÇALIŞIYOR (hata vermiyor), ama kullanıcıya yanlış/boş veri gösterebilir** — çünkü gösterilen kart UI'ı (`LoyaltyCard.fromMap`) `reward_threshold_pts`/`reward_type`/`reward_value` gibi puan-modeli alanlarını bekliyor ve **gerçek RPC de puan-modeli döndürüyorsa bu zaten uyumlu** (mobil tarafın kod yorumlarındaki "damga modeli" beklentisi aslında yanlış kod-okuma olabilir — `LoyaltyCard.fromMap` ve `LoyaltyStatus.fromMap` alan adlarına bakıldığında **mobil tarafın kendisi de puan-modeli alan adlarını (`points`, `lifetime_points`, `reward_threshold_pts`) bekliyor**, damga-modeli alanı (`stamp_count`, `stamps_needed`) hiç beklemiyor).

**DÜZELTME — bu oturumun mobil koda bakarak ulaştığı netleşme:** Önceki raporların "mobil damga-modeli RPC'leri çağırıyor" ifadesi **yanlış**. Mobil `sadakat_saglayicisi.dart` dosyasının kendisi (`LoyaltyCard`, `LoyaltyStatus` sınıfları, alan adları `points`/`lifetime_points`/`reward_threshold_pts`/`reward_type`/`reward_value`/`checkin_points`/`review_points`) **tamamen puan-modeli arayüzüdür.** Mobil hiçbir yerde `stamps_needed`/`reward_desc`/`stamp_count` gibi damga-modeli alanı okumuyor. Mobil sadece `get_my_loyalty_cards_v1` adlı **fonksiyon ismini** çağırıyor — bu isim her iki migration'da da var ama mobilin beklediği **veri şekli puan-modelidir.**

**Sonuç:** Mobil tarafında aktif bir bug **olabilir ama farklı bir nedenle**: eğer `get_my_loyalty_cards_v1`'in gerçek kazanan gövdesi damga-modeli (`TABLE(...)`) ise, mobil `res as List` cast'i çalışsa da, dönen alan adları (`card_id`, `program_name`, `stamp_count`, `stamps_needed`) mobilin beklediği (`business_id`, `points`, `reward_threshold_pts`) ile **eşleşmez** → `LoyaltyCard.fromMap` her alanı `null`/varsayılan değerle doldurur (`m['points'] as num?` → `null` → `?? 0`), **crash olmaz ama kart her zaman "0 puan" gösterir, sessiz veri kaybı.** Eğer kazanan gövde puan-modeliyse (önceki oturumun doğrulamasına göre daha olası), mobil sorunsuz çalışır.

**Bu, MVP-dışı kararından bağımsız mı, düzeltilmeli mi?**

→ **"Zaten kullanılmıyor, önemi yok" sonucu BU OTURUMDA DOĞRULANDI:** Mobil `/loyalty-cards` route'una artık hiçbir UI butonu erişmiyor (§4 madde 1). Dolayısıyla bu olası bug, **kullanıcı tarafından şu an tetiklenemiyor** — pratik etkisi sıfıra yakın. MVP-dışı kararı zaten bu kod yolunu erişilemez kıldığı için, **bu bug'ın ayrıca acil bir backend düzeltmesi gerektirmiyor.** Eğer ileride (P2 döneminde) loyalty geri açılırsa, bu noktanın §6'daki SELECT sorgusuyla netleştirilip düzeltilmesi gerekir.

---

## 7. Güvenli Cleanup PR Planı (Adım Adım — SADECE TARİF, SQL/migration yazılmadı)

### PR L1 — Web: canlı erişilebilir yüzeyleri kapatma (EN ÖNCELİKLİ)
**Amaç:** §4 madde 2'deki en kritik bulguyu (canlı, çalışan, doğru şemalı ama MVP-dışı `/owner/marketing/loyalty`) kapatmak.
**Kapsam (tarif, kod yazılmadı):**
- `app/owner/marketing/loyalty/page.tsx` başına, `app/sahip/pazarlama/sadakat/page.tsx`'teki gibi bir `redirect('/owner/marketing')` veya `notFound()` eklenmesi önerilir.
- `app/owner/marketing/page.tsx:14`'teki `/owner/marketing/loyalty` link kartının kaldırılması veya "Yakında" rozetiyle pasifleştirilmesi önerilir.
- `app/(auth)/loyalty/page.tsx` ve `app/(kimlik)/sadakat/page.tsx`'e benzer bir `redirect`/`notFound()` eklenmesi önerilir (düşük öncelik, nav linki olmadığı için risk düşük ama URL hâlâ canlı).
**Risk:** Düşük (sadece route guard ekleme, mevcut hiçbir P0 akışına dokunmuyor).
**Test:** `npm run typecheck` + `npm run lint`.

### PR L2 — Web: dead code temizliği
**Amaç:** Gerçek dead code'u (madde 8, `sadakat-form.tsx`) kaldırmak.
**Kapsam:** `app/sahip/pazarlama/sadakat/sadakat-form.tsx` silinebilir (hiçbir zaman render edilmiyor, sayfa zaten redirect). `app/sunucu/sahip/sadakat/route.ts` silinmesi gerekmiyor — zararsız, dokunulmadan bırakılabilir veya üstüne `// DEFERRED P2: MVP dışı, çağıran UI yok` yorumu eklenebilir.
**Risk:** Düşük.
**Test:** `npm run typecheck` + `npm run lint`.

### PR L3 — DB: production şema doğrulaması (İNSAN/MCP OTURUMU GEREKTİRİR)
**Amaç:** §2-§6'daki tüm varsayımları kesinleştirmek.
**Kapsam:** §8'deki SELECT sorgularının bir insan veya Supabase-MCP erişimli oturum tarafından çalıştırılması.
**Risk:** Yok (sadece SELECT).
**Önkoşul:** Yok — hemen yapılabilir, bu rapordan sonraki ilk adım olmalı.

### PR L4 — DB: additive guard/comment migration (PR L3 sonrası, insan kararıyla)
**Amaç:** Hangi RPC setinin "kazanan" olduğu netleştikten sonra, kaybeden/tutarsız RPC setine güvenli bir guard eklemek.
**Kapsam (tarif, SQL yazılmadı):**
- Eğer `create_loyalty_program_v1`/`add_loyalty_stamp_v1` gerçekten kolon-yok hatası veriyorsa: bu fonksiyonlara `RAISE EXCEPTION 'not_implemented: Sadakat programı MVP kapsamı dışındadır' USING ERRCODE = 'P0004';` ekleyen bir guard migration'ı (CLAUDE.md'deki `not_implemented` SQLSTATE şablonu) düşünülebilir — bu DROP değildir, fonksiyon gövdesini güvenli bir hata mesajıyla değiştirir, hiçbir veri kaybı riski yoktur.
- Tüm loyalty tablolarına/fonksiyonlarına `COMMENT ON ... IS 'DEFERRED P2 2026-06-23: Sadakat MVP kapsamı dışı, bkz. docs/engineering/2026-yeedoy-loyalty-mvp-defer-decision.md';` eklenmesi.
**Risk:** Düşük (additive/guard, DROP yok).
**Önkoşul:** PR L3 tamamlanmış olmalı.

### PR L5 — Mobil/Personel: ek aksiyon gerekmiyor
**Amaç:** Doğrulama.
**Kapsam:** Mobil `/loyalty-cards` route'u ve personel sadakat sekmesi zaten nav'dan gizli — **bu rapor ek bir kod değişikliği önermiyor.** Sadece §6'daki bug ihtimali not edilmeli, P2'de loyalty geri açılırsa ele alınmalı.
**Risk:** Yok — aksiyon yok.

---

## 8. Production Doğrulama İçin Önerilen SADECE SELECT/Read-Only Sorgular

Aşağıdaki sorgular **örnek olarak verilmiştir**, bir insan veya Supabase MCP erişimli bir oturum tarafından çalıştırılmalıdır. **Bu rapor bunları çalıştırmamıştır. DROP/ALTER hiçbir zaman önerilmez.**

```sql
-- 1. loyalty_programs gerçek şemasını teyit et (puan modeli mi kazandı, beklendiği gibi)
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'loyalty_programs'
ORDER BY ordinal_position;

-- 2. loyalty_cards tablosunun gerçekten var olup olmadığını teyit et (§2.2 FK riski nedeniyle hiç var olmayabilir)
SELECT to_regclass('public.loyalty_cards') AS table_exists;

-- 3. Eğer varsa, loyalty_cards'ın gerçek kolonlarını gör
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'loyalty_cards'
ORDER BY ordinal_position;

-- 4. get_my_loyalty_cards_v1 fonksiyonunun GERÇEK gövdesini ve return type'ını gör
-- (§6'daki "hangi sürüm kazandı" sorusunu kesin olarak çözer)
SELECT pg_get_functiondef(oid), prorettype::regtype AS return_type
FROM pg_proc
WHERE proname = 'get_my_loyalty_cards_v1';

-- 5. create_loyalty_program_v1 / add_loyalty_stamp_v1 hâlâ kayıtlı mı, hangi gövdeyle
SELECT proname, pg_get_functiondef(oid)
FROM pg_proc
WHERE proname IN ('create_loyalty_program_v1', 'add_loyalty_stamp_v1');

-- 6. Gerçek veri var mı (cleanup önceliklendirmesi + "hiç kullanılmamış" teyidi için)
SELECT count(*) FROM public.loyalty_programs;
SELECT count(*) FROM public.loyalty_accounts;
-- loyalty_cards sadece #2 table_exists = true ise çalıştırılmalı:
-- SELECT count(*) FROM public.loyalty_cards;

-- 7. trg_loyalty_checkin / trg_loyalty_review trigger'larının kurulu olup olmadığı
SELECT tgname, tgrelid::regclass AS table_name, tgenabled
FROM pg_trigger
WHERE tgname IN ('trg_loyalty_checkin', 'trg_loyalty_review');

-- 8. Aktif (is_active=true) herhangi bir loyalty programı var mı
-- (mobile-unwired-product-decision-report.md'nin 2026-06-22 notuna göre canlı DB'de 0 olması bekleniyor)
SELECT count(*) FROM public.loyalty_programs WHERE is_active = true;
```

**Önerilen çalıştırma sırası:**
1. Sorgu 1, 4, 5 — şema/fonksiyon çakışmasının gerçekliğini kesinleştirir (§2, §6'daki tüm varsayımları doğrular/çürütür).
2. Sorgu 2, 3 — `loyalty_cards`'ın hiç var olup olmadığını netleştirir (§2.2 FK riski).
3. Sorgu 6, 8 — gerçek veri/kullanım var mı, cleanup PR L4'ün önceliğini belirler.
4. Sorgu 7 — trigger riskini netleştirir, DB cleanup PR'larının güvenliğini etkiler.

---

## 9. Özet Tablo — Bu Raporun Sonuçları

| Soru | Cevap |
|---|---|
| Loyalty MVP'de açık olmalı mı? | **Hayır — final stratejiye göre tamamen kapalı kalmalı.** |
| Şu an gerçekten tamamen kapalı mı? | **Hayır.** Web `/owner/marketing/loyalty` canlı ve çalışıyor; `/loyalty`, `/sadakat` (kullanıcı sayfaları) URL ile erişilebilir. |
| Mobil/personel tarafı kapalı mı? | **Evet, pratikte kapalı** (route var ama nav yok, ek aksiyon önerilmiyor). |
| DB DROP edilmeli mi? | **Hayır, hiçbir koşulda bu raporun önerisi DROP değildir.** |
| En acil aksiyon ne? | PR L3 (production şema SELECT doğrulaması) + PR L1 (web `/owner/marketing/loyalty` route guard). |
| Mobildeki damga-model RPC çağrısı aktif bug mı? | Olası ama düşük öncelikli — kullanıcı tarafından tetiklenemiyor (nav yok), P2'ye kadar ele alınmasına gerek yok. |
