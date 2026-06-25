# YEEDOY Supabase Dirty State Audit (2026-06-24)

**Görev türü:** Salt okuma / sınıflandırma raporu (2026-06-24, STALE — Updated 2026-06-25 post-cleanup). Bu rapor hazırlanırken hiçbir migration, function veya başka dosya değiştirilmedi, silinmedi, stage edilmedi veya commit edilmedi. Tüm bulgular `git status`, `git log --all`, `git diff` ve dosya içerik okumasına dayanır.

**Referans kapsam kaynağı:** `docs/product/2026-yeedoy-final-scope-source-of-truth.md` (2026-06-24, tek güncel karar kaynağı).

**Not (2026-06-25):** Bu rapor 2026-06-24 tarihinde hazırlanmıştır. Forbidden-scope temizlik commit'leri (b5c68cc, 6523c12, vb.) APP/UI katmanını kapatmıştır, ancak bu rapor kontrol ettiği **DB/migration katmanı** değiştirilmemiştir — intentional olarak. Bulguların geçerliliği devam etmektedir; DB nesneleri tutarlılık içinde kalmaktadır.

---

## 1. Özet — UPDATED 2026-06-25

Bu rapor 2026-06-24 tarihinde hazırlanmıştır. Forbidden-scope temizlik app-layer'ı kapatmış, ancak DB layer **intentional olarak korunmuştur**. DB dirty state bulguları geçerliliğini koruyor.

`supabase/migrations/` ve `supabase/functions/` altında toplam **15 dirty (uncommitted) dosya** bulundu (2026-06-24 snapshot):

| Durum | Sayı | Açıklama |
|---|---|---|
| Committed + sonradan değiştirilmiş (working tree `M`) | 2 | `20260616000001_get_smart_recommendations_v1.sql`, `supabase/functions/send-email-campaign/index.ts` |
| Tamamen untracked (`??`), hiç commit edilmemiş | 13 | `20260615000003` ... `20260622000004` arası migration dosyaları |

Kategori dağılımı (sınıflandırma etiketine göre):

| Etiket | Dosya sayısı |
|---|---|
| `DO_NOT_TOUCH_PROD_RISK` | 2 |
| `NEEDS_HUMAN_DECISION` | 1 (`loyal_customers_reward_fields.sql`) |
| `KEEP_FOR_MVP` | 9 |
| `KEEP_FOR_SEPARATE_PR` | 2 |
| `DISCARD_SAFE` | 0 (görülen dosyalar arasında tamamen anlamsız/atılabilir migration yok) |

Önemli not: `loyalty_accounts` / `loyalty_programs` tabloları ve `get_business_loyal_customers_v1` fonksiyonunun **kendisi** zaten committed ve muhtemelen prod'a uygulanmış eski migration'larda mevcut (`20260424000007_loyalty_program.sql`, `20260424000010_loyalty_automations.sql`, `20260507000008_sadakat_karti.sql` — tarih: 2026-04). Bu audit'in kapsamı SADECE şu anki dirty dosyalardır; eski committed loyalty altyapısının kendisi bu raporun konusu değildir (ayrı bir "loyalty teardown" kararı gerektirir).

**2026-06-25 güncelleme:** App-layer loyalty akses ✅ CLOSED (HTTP 410, disabled server actions), ancak DB layer **intentional olarak korunmuştur**. Bu tutarlı bir yapı — katmanlı kapatma yöntemi.

---

## 2. `loyal_customers_reward_fields.sql` Özel Bölümü

**Dosya:** `supabase/migrations/20260622000001_loyal_customers_reward_fields.sql`

**İçerik:** `public.get_business_loyal_customers_v1(p_business_id uuid, p_limit int)` fonksiyonunu **CREATE OR REPLACE** ile aynı imza üzerinde yeniden tanımlıyor. Döndürülen JSON nesnesine üç yeni alan ekliyor:
- `reward_threshold_pts` (← `loyalty_programs.reward_threshold_pts`)
- `reward_type` (← `loyalty_programs.reward_type`)
- `reward_value` (← `loyalty_programs.reward_value`)

Ayrıca `loyalty_programs` tablosuna `LEFT JOIN` ekliyor (önceki versiyon sadece `loyalty_accounts` + `profiles` join'i yapıyordu).

**Git geçmişi:** Bu dosya tamamen **untracked** (`??`). Hiç commit edilmemiş. Ancak **değiştirdiği fonksiyonun kendisi** committed ve prod'a uygulanmış olabilir: `get_business_loyal_customers_v1` ilk olarak `20260424000007_loyalty_program.sql` migration'ında (2026-04-24, committed, HEAD'de mevcut) `create or replace function` ile tanımlanmış. Yani bu dirty dosya, zaten prod'da çalışan eski bir loyalty RPC'sinin **body-replace** versiyonu.

**Kapsam değerlendirmesi:** `docs/product/2026-yeedoy-final-scope-source-of-truth.md` madde 21: *"Sadakat/Loyalty Sistemi — müşteri sadakat puanları, çekinler, ödüller MVP'de değildir."* Bu dosya doğrudan ödül (reward) alanlarını genişletiyor → **kapsam dışı**.

**Prod riski:** ORTA.
- Dosyanın kendisi hiç push edilmemiş (untracked, local'de duruyor) → bu spesifik DEĞİŞİKLİĞİN prod'a gitme riski düşük.
- Ancak değiştirdiği *fonksiyonun kendisi* zaten prod'da committed bir migration ile var → eğer bu dosya commit edilip push edilirse, prod'daki canlı bir RPC'nin davranışı (dönen JSON şekli) değişir. Bu RPC'yi çağıran herhangi bir client (mobil/web/personel) varsa etkilenir.
- Dosya başlığındaki not "No consumers existed yet (grep confirmed)" diyor — yani yazarı zaten bu RPC'nin hiçbir client tarafından çağrılmadığını doğrulamış. Bu, riski azaltıyor ama "tüketici yok" iddiasını bu audit bağımsız olarak doğrulamadı (kapsam dışı, salt-okuma görevi).

**Net öneri:**
1. Bu dosyayı **commit ETME**. Sadakat sistemi MVP kapsamı dışında olduğu için yeni reward alanı eklemek ürün yönüyle gereksiz.
2. Eğer ileride loyalty/sadakat tamamen MVP'den sökülecekse (ayrı stratejik karar), bu dosya o teardown çalışmasının bir parçası olarak **silinmeli**, fonksiyonun kendisi de (`get_business_loyal_customers_v1`) ayrı bir deprecation/drop migration'ı ile ele alınmalı — DROP/ALTER bu görevde yapılmaz, sadece öneri.
3. Şimdilik dosyayı diskte bırakmak (commit etmeden) güvenli; `git status` kirliliği rahatsız ediyorsa `git stash` ile saklanabilir ama bu görev kapsamında hiçbir işlem önerilmiyor — sadece insan kararı.
4. **Sınıflandırma: `NEEDS_HUMAN_DECISION`** — kapsam dışı olduğu açık, ancak "loyalty altyapısının tamamen sökülmesi mi, yoksa sessizce dondurulması mı" ürün kararı bu dosyanın nihai kaderini belirler (sil / ayrı PR'da teardown / öylece bırak).

---

## 3. Migration Dosyaları Tablosu

| Dosya | Zincire dahil mi? | Commit durumu | Prod riski | Öneri | Etiket |
|---|---|---|---|---|---|
| `20260615000003_ornek_yeedoy_hours.sql` | Evet, sıralı timestamp, bağımsız (demo seed data) | Tamamen untracked | Düşük — demo/seed veri, prod'da zararsız idempotent upsert (`on conflict ... do update`) | Commit edilebilir veya atılabilir; demo işletme verisi prod'u bozmaz | `KEEP_FOR_MVP` (demo verisi olsa da "açık/kapalı bilgisi" özelliğini test etmek için gerekli) |
| `20260615000004_search_nearby_price_open.sql` | Evet, sıralı, `search_nearby_businesses_v3` overload'unu DROP+CREATE ediyor | Tamamen untracked | Orta — `drop function if exists` + yeniden `create or replace` kullanıyor; eğer bu overload prod'da zaten farklı bir client tarafından çağrılıyorsa (signature aynı kalıyor: 7 parametre) DROP anlık bir kesinti penceresi yaratabilir ama aynı migration içinde yeniden oluşturuluyor | Kapsamda (Yakın Mekan Keşfi + Açık/Kapalı Bilgisi MVP kapsamında). Commit edilmeli ama local'de test edilip onaylanmalı | `KEEP_FOR_MVP` |
| `20260619000001_remove_ip_metadata_from_policy_acceptances.sql` | Evet, sıralı, bağımsız trigger fonksiyonu + 2 UPDATE veri temizliği | Tamamen untracked | Düşük-Orta — `UPDATE ... SET ip_address = NULL` geri alınamaz veri kaybı (yazarı da kabul ediyor: "amaçsız veri — kabul edilebilir"). Privacy/GDPR kapsamında, KVKK md.10 gerekçeli | Kapsamda (Privacy/GDPR KALABİLİR listesinde). Commit edilmeden önce DBA/hukuk onayı önerilir çünkü veri temizliği geri alınamaz | `KEEP_FOR_SEPARATE_PR` |
| `20260620000001_user_profiles_marketing_email_opt_in.sql` | Evet, sıralı, `20260620000002`'nin ön koşulu | Tamamen untracked | Düşük — sadece `ADD COLUMN IF NOT EXISTS` + `DEFAULT false`, geriye dönük uyumlu, veri kaybı yok | **Önemli ayrım:** Bu, "pazarlama email kampanyası" özelliği değil, kullanıcının global e-posta izni (opt-in) tercih sütunu — KVKK/Privacy kapsamında. Scope dosyasında yasaklanan "marketing automation/email campaign" akışının bir *ön koşulu* olarak da kullanılıyor (bkz. `send-email-campaign`). Privacy açısından KALABİLİR ama bu kolon sadece kampanya gönderimi için kullanılıyorsa kapsam tartışmalı | `NEEDS_HUMAN_DECISION` |
| `20260620000002_r5_marketing_email_rpcs.sql` | Evet, `20260620000001`'e bağımlı | Tamamen untracked | Düşük — 3 RPC (okuma/güncelleme) + 1 RLS policy, hepsi kullanıcının kendi kaydını etkiliyor | RPC'lerin ikisi (`get_my_notification_preferences_v1`, `update_my_marketing_email_opt_in_v1`) Privacy/bildirim tercihi kapsamında savunulabilir. Üçüncüsü (`update_business_follow_email_subscription_v1`) işletme bazlı e-posta aboneliğini yönetiyor — bu da "marketing automation" sınırına yakın. `send-email-campaign` fonksiyonu bu RPC'lerin ürettiği `marketing_email_opt_in` bayrağına bağımlı | `NEEDS_HUMAN_DECISION` |
| `20260620000003_fix_privacy_request_type_and_rpcs.sql` | Evet, sıralı, `20260619000001` + `20260620000001/002`'ye "Bağımlılıklar" notunda referans veriyor (ama gerçek SQL bağımlılığı yok) | Tamamen untracked | Düşük — `ALTER TABLE ... DROP/ADD CONSTRAINT` (CHECK, veri kaybı yok) + 2 yeni RPC. Yazar notu: "mevcut kayıtlar bu değerleri içermiyor" (güvenli) | Kapsamda (privacy/veri silme talebi KALABİLİR listesinde, GDPR/KVKK ile doğrudan ilişkili). Commit edilmeye uygun | `KEEP_FOR_MVP` |
| `20260620000004_claim_evidence_storage.sql` | Evet, sıralı, bağımsız storage bucket+policy seti | Tamamen untracked | Düşük — `on conflict do update` idempotent bucket upsert + policy DROP/CREATE çiftleri, mevcut yetersiz policy'leri (`claim_evidence_admin_select` vb.) temizliyor | Kapsamda (Claim evidence storage KALABİLİR listesinde, owner-claim akışı için temel altyapı) | `KEEP_FOR_MVP` |
| `20260622000001_loyal_customers_reward_fields.sql` | Evet, sıralı, var olan committed RPC'nin body-replace'i | Tamamen untracked (ama değiştirdiği fonksiyon committed) | **Orta** (bkz. Bölüm 2) | Bkz. Bölüm 2 — commit etme, loyalty teardown kararına kadar beklet | `NEEDS_HUMAN_DECISION` |
| `20260622000002_admin_decide_owner_claim_v1_guards.sql` | Evet, sıralı, var olan committed RPC'nin body-replace'i (whitelist + row-count guard ekliyor) | Tamamen untracked | Düşük — sadece ek validasyon (`p_decision not in (...)`, `if not found`) ekliyor, güvenlik iyileştirmesi, davranış kısıtlaması geriye dönük güvenli | Kapsamda (Claim/Moderasyon KALABİLİR). Commit edilmeye uygun, gap-report P1#2 düzeltmesi | `KEEP_FOR_MVP` |
| `20260622000003_user_profiles_language_code.sql` | Evet, sıralı, bağımsız kolon ekleme | Tamamen untracked | Düşük — `ADD COLUMN IF NOT EXISTS` + CHECK constraint, nullable, veri kaybı yok | Kapsam dışı kategorilere girmiyor; genel ürün altyapısı (dil tercihi), MVP'nin temel kullanılabilirlik gereksinimi sayılabilir | `KEEP_FOR_MVP` |
| `20260622000004_owner_claims_evidence_storage_path.sql` | Evet, sıralı, `submit_owner_claim_v1` fonksiyonunu DROP+CREATE ediyor (yeni parametre ekliyor) | Tamamen untracked | Orta — `drop function if exists public.submit_owner_claim_v1(uuid, text, text, text, text)` ile eski 5-parametreli imzayı kaldırıp 6-parametreli yeni imza oluşturuyor. Eğer prod'da eski imzalı bir client hâlâ varsa (örn. henüz deploy edilmemiş eski mobil/web build) çağrı patlayabilir | Kapsamda (Claim evidence KALABİLİR). Commit edilebilir ama deploy sırası: migration + web/mobile client güncellemesi birlikte gitmeli | `KEEP_FOR_MVP` |
| `20260616000001_get_smart_recommendations_v1.sql` (committed, sonradan değiştirilmiş) | Evet, committed migration zincirinde sabit yer alıyor | **Committed + working tree'de değiştirilmiş** | **YÜKSEK** | Bkz. Bölüm 5 | `DO_NOT_TOUCH_PROD_RISK` |

---

## 4. Function Dosyaları Tablosu

| Dosya | Commit durumu | Prod riski | Öneri | Etiket |
|---|---|---|---|---|
| `supabase/functions/send-email-campaign/index.ts` | **Committed + working tree'de değiştirilmiş** (214 satır eklenmiş, 71 satır silinmiş — fonksiyonun ~2/3'ü yeniden yazılmış) | **YÜKSEK** | Bkz. Bölüm 5 | `DO_NOT_TOUCH_PROD_RISK` |

Diğer `supabase/functions/` altındaki tüm dosyalar (`admin-api`, `ai-*`, `media-upload*`, `push-dispatch`, `send-push-campaign`, `verify-domain`, `write-gatekeeper` vb.) `git status` çıktısında **temiz** — bu audit kapsamında dirty değil, incelenmedi.

**Not — kapsam çatışması:** `send-email-campaign` işletme bazlı pazarlama e-posta kampanyası gönderen bir edge function'dır (`email_campaigns` tablosunu okuyup Resend API üzerinden toplu e-posta gönderiyor, hedef segmentasyon `new_30d`/`inactive_30d` destekliyor). `docs/product/2026-yeedoy-final-scope-source-of-truth.md` madde: *"Marketing automation / email campaign MVP'de değildir"* (kullanıcının görev talimatında belirtilen kapsam dışı liste; final-scope dosyasının kendisinde bu ibare lafzen yok ama görev talimatında açıkça listelenmiş). Bu fonksiyonun MEVCUT HALİ (committed, HEAD'deki versiyon) zaten prod'da çalışıyor olabilir — yani "email campaign" özelliği muhtemelen zaten kapsam dışı kalmış bir önceki sprint'ten committed durumda kalmış. Şu anki dirty değişiklik bunu GENİŞLETİYOR (HMAC tabanlı unsubscribe token sistemi ekliyor — KVKK/6563 sayılı kanun gerekçeli), kapsamı azaltmıyor.

---

## 5. DO_NOT_TOUCH_PROD_RISK Detayları

### 5.1 `supabase/migrations/20260616000001_get_smart_recommendations_v1.sql`

**Neden yüksek risk:** Bu dosya **committed bir migration dosyasının kendisinin** working tree'de değiştirilmiş hali. Migration dosyalarının commit edildikten sonra üzerinde değişiklik yapılması, Supabase migration modelinde temel bir anti-pattern'dir: eğer bu dosya `supabase db push` ile prod'a uygulanmışsa, prod veritabanındaki `get_smart_recommendations_v1` fonksiyonu zaten **eski (committed) içerikle** mevcuttur. Dosyanın kendisini sonradan değiştirmek:
- Migration geçmişi (prod'daki `supabase_migrations.schema_migrations` tablosu) bu dosyanın checksum'ını zaten "uygulandı" olarak işaretlemiş olabilir.
- Yeni içerik asla otomatik olarak prod'a gitmez (migration sistemi "bu dosya zaten uygulandı" der) — yani local migration dosyasını değiştirmek SESSİZCE prod ile local'i birbirinden ayırır (drift). Bu, ekibin "migration dosyaları = prod şema kaynağı" güvenini kırar.
- Değişikliğin kendisi de önemli: `LANGUAGE plpgsql` → `LANGUAGE sql`, `search_nearby_businesses_v3` RPC çağrısından doğrudan `businesses` tablosuna join'e geçiş, dönen `image_url`/`cuisine`/`rating` alanlarının kaynak sütunları değişmiş (`b.rating` → `ra.avg_rating` hesaplanmış değer). Bu davranışsal bir fonksiyon değişikliği, kozmetik değil.

**Somut öneri:** Bu dosyayı OLDUĞU GİBİ bırak, dokunma. Eğer bu değişiklik gerçekten gerekliyse:
1. Önce local Supabase'de (read-only sorgu ile, MCP veya CLI `supabase migration list` üzerinden) bu migration'ın prod'a uygulanıp uygulanmadığı doğrulanmalı.
2. Eğer uygulanmamışsa → dosya commit edilebilir (push edilmemiş migration'ı düzeltmek görece güvenli).
3. Eğer uygulanmışsa → bu değişiklik **yeni bir forward migration dosyası** (`202606XXXXXXXX_fix_get_smart_recommendations_v1.sql`) olarak ayrılmalı, mevcut committed dosya asla geriye dönük değiştirilmemeli.
4. Bu karar insan + DBA onayı gerektirir — bu audit görevi kapsamında YAPILMAYACAK.

### 5.2 `supabase/functions/send-email-campaign/index.ts`

**Neden yüksek risk:** Edge function'lar migration sistemi gibi checksum/versiyon takibi yapmaz; `supabase functions deploy` her çalıştırıldığında dosyanın o anki içeriği prod'a gider. Bu nedenle migration'dan farklı bir risk türü: dosyanın kendisi "committed" olsa da, deploy zamanlaması belirsizdir. Risk burada şu:
- Bu fonksiyon committed haliyle zaten prod'da deploy edilmiş **olabilir** (commit geçmişinde mevcut, `git log` ile doğrulandı: dosya en az 2 önceki committe ("commit untracked source files + repo cleanup" ve "temizlik" commit'leri) zaten vardı).
- Şu anki uncommitted değişiklik, fonksiyonun üçte ikisini yeniden yazıyor: HMAC tabanlı unsubscribe token üretimi, çift filtreli (`is_subscribed_email` + `marketing_email_opt_in`) alıcı sorgusu, `UNSUBSCRIBE_HMAC_SECRET` zorunlu kontrolü (fail-closed).
- Bu değişiklik **yeni env değişkenine bağımlı** (`UNSUBSCRIBE_HMAC_SECRET`) ve **yeni migration'a bağımlı** (`20260620000001` — `marketing_email_opt_in` kolonu). Eğer bu fonksiyon deploy edilir ama bağımlı olduğu migration prod'a gitmemişse, fonksiyon prod'da `user_profiles.marketing_email_opt_in` sütunu olmadığı için **tüm kampanya gönderimlerini sessizce 0 alıcıya düşürür veya hata fırlatır**.
- Kapsam çatışması: marketing email campaign özelliği MVP kapsamı dışında tanımlanmış; bu kapsam dışı özelliğe yeni güvenlik/yasal altyapı (HMAC unsubscribe) eklemek, "kapsam dışı özelliği büyütme" anlamına geliyor.

**Somut öneri:** Bu dosyaya dokunma. Önce ürün/hukuk kararı gerekiyor: "email campaign" özelliği gerçekten MVP'den çıkarılacaksa, bu fonksiyonun (ve bağımlı olduğu migration'ların: `20260620000001`, `20260620000002`) tamamen **devre dışı bırakılması veya silinmesi** ayrı bir PR'da ele alınmalı — şu anki "geliştirme" (HMAC unsubscribe ekleme) çabası muhtemelen israf olacak. Eğer email campaign "KALABİLİR" olarak yeniden değerlendirilirse (örn. işletme-müşteri iletişimi gerekçesiyle), bu değişiklik ayrı, izole bir PR'da incelenip deploy sırası (migration önce, function sonra) netleştirilerek commit edilmeli.

---

## 6. Önerilen Sıradaki Adımlar (UYGULANMAYACAK — sadece öneri listesi)

1. **Ürün kararı al:** `marketing_email_opt_in` / `r5_marketing_email_rpcs` / `send-email-campaign` üçlüsünün kaderi netleştirilmeli — bunlar "kullanıcı gizlilik tercihi" (KALABİLİR) ile "pazarlama kampanya otomasyonu" (KAPSAM DIŞI) arasında sınırda. Üç olası yol: (a) tamamen kaldır, (b) sadece opt-in/opt-out tercih RPC'lerini tut, kampanya gönderim fonksiyonunu kaldır, (c) hepsini ayrı bir "Faz 2" PR'ına taşı.
2. **`loyal_customers_reward_fields.sql` için karar:** Sil (loyalty kesin kapsam dışıysa) veya `docs/engineering/` altında zaten var olan loyalty-defer kararlarıyla birlikte ayrı bir "loyalty teardown" PR'ına taşı. Şimdilik commit ETME.
3. **`get_smart_recommendations_v1.sql` ve `send-email-campaign/index.ts` için:** Supabase migration geçmişi tablosuna (read-only) bakarak bu iki dosyanın prod'a uygulanıp uygulanmadığını doğrula (örn. MCP `list_migrations` veya prod `supabase_migrations.schema_migrations` sorgusu). Sonuca göre "yeni forward migration aç" ya da "committed dosyayı normal şekilde güncelle" kararı ver.
4. **Düşük riskli, kapsamda olan 6 migration** (`20260615000003`, `20260615000004`, `20260619000001`, `20260620000003`, `20260620000004`, `20260622000002`, `20260622000003`, `20260622000004`) bir grup halinde gözden geçirilip commit edilebilir — bunlar claim/privacy/açık-kapalı/dil tercihi gibi MVP kapsamına giren, geriye dönük güvenli değişiklikler.
5. **`20260619000001` (IP/UA verisi NULL'lama)** geri alınamaz veri silme içerdiği için commit öncesi ayrıca hukuk/DBA onayı önerilir — diğerlerinden ayrı, kendi PR'ında ele alınmalı.
6. Bu rapor sonrası, `docs/engineering/` altındaki eski raporlarla (`2026-yeedoy-loyalty-mvp-defer-decision.md`, `2026-yeedoy-mvp-scope-prune-audit.md` vb.) çapraz kontrol yapılarak loyalty/marketing kararlarının tutarlılığı teyit edilmeli.
