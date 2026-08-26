# Supabase Bölge Migrasyonu (Seul → Frankfurt) — Tasarım Dokümanı

## Kök Neden ve Motivasyon

WebPageTest ile yapılan performans denetimi sırasında (2026-08-25), Vercel fonksiyon bölgesinin `iad1` (Washington DC, ABD) olduğu ve Türkiye pazarına yönelik bu ürün için ciddi bir coğrafi gecikme yarattığı tespit edildi. Fonksiyon bölgesi `fra1`'e (Frankfurt) taşındı ve bu doğrulandı (Vercel API üzerinden `regions: ["fra1"]`). Ancak taşıma sonrası WebPageTest'te (Frankfurt test noktasından) TTFB hâlâ ~1,1-1,2 saniye civarında kaldı — beklenenden çok yüksek.

Kök neden araştırması, Supabase projesinin veritabanı bölgesinin **`ap-northeast-2` (Seul, Güney Kore)** olduğunu ortaya çıkardı (kullanıcı Supabase Dashboard'da doğrudan doğruladı). Yani:

- Vercel fonksiyonu artık Frankfurt'ta çalışıyor (tarayıcı → fonksiyon bacağı kısaldı).
- Ama fonksiyonun her sayfa render'ı için yaptığı Supabase sorguları hâlâ Frankfurt ↔ Seul arasında gidip geliyor (fonksiyon → veritabanı bacağı hâlâ yarım dünya öteye gidiyor).

Bu, gerçek kullanıcılar için (özellikle Türkiye'den) kalıcı ve büyüyen bir performans sorunu — ürün büyüdükçe bu gecikme daha fazla kullanıcıyı etkileyecek.

## Ölçek Değerlendirmesi (2026-08-26 itibarıyla)

Migrasyon riskini değerlendirmek için mevcut veri hacmi ölçüldü:

| Kalem | Değer |
|---|---|
| Veritabanı toplam boyutu | 471 MB |
| `businesses` tablosu | 39.952 satır |
| `private.google_maps_places_catalog` | 23.215 satır |
| Storage (`menu-media` bucket) | 119 dosya, ~5,9 MB |
| `auth.users` | 9 kullanıcı (tamamı test/örnek hesap, gerçek canlı kullanıcı yok) |
| pg_cron job'ları | 2 (`notify_favorite_revisit_reminders_v1`, `purge_expired_business_audit_log`) |
| Edge Functions | 7 (`anti-spam-guard`, `write-gatekeeper`, `verify-domain`, `ai-allergen-detect`, `ai-nutrition-estimate`, `ai-menu-image-gen`, `ai-menu-analyze`) |

Bu ölçek küçük — dump/restore ve storage kopyalama dakikalar içinde tamamlanabilir. Gerçek kullanıcı olmadığı için kesinti toleransı kritik değil; kullanıcı bunu doğruladı ("şuan canlıda dursada kullanıcılar tamamen bizim oluşturduğumuz örnek kullanıcılar canlı kullanıcı yok").

## Değerlendirilen Yaklaşımlar

### Seçenek A — Manuel `pg_dump`/`pg_restore` + storage kopyalama + redeploy (SEÇİLDİ)
Supabase'in resmi olarak desteklediği "projeler arası migrasyon" yöntemi. Şema+veri (public/private/auth şemaları dahil, foreign key bütünlüğü korunarak) `pg_dump` ile alınıp yeni Frankfurt projesine restore edilir. Storage dosyaları ayrı bir script ile kopyalanır (pg_dump'ın kapsamı dışında). Basit, düşük riskli, tamamen kontrolümüzde.

### Seçenek B — Supabase destek ekibinden bölge migrasyonu talebi
Böyle otomatik bir özelliğin var olup olmadığı belirsiz; muhtemelen ücretli/yavaş bir destek süreci, kontrolümüz dışında zamanlama. Değerlendirildi, tercih edilmedi.

### Seçenek C — Logical replication ile sıfır-kesinti migrasyon
Gerçek kullanıcı olmadığı için kesinti zaten önemsiz — bu ek karmaşıklık gereksiz. Değerlendirildi, tercih edilmedi.

**Seçenek A ile devam edilecek.**

## Mimari

1. Yeni bir Supabase projesi `eu-central-1` (Frankfurt) bölgesinde oluşturulur.
2. Yeni projede gerekli extension'lar etkinleştirilir (postgis, pg_trgm, pg_cron, pg_net, vb. — eski projedeki tam liste referans alınarak).
3. Eski projeden tam `pg_dump` alınır (public + private + auth şemaları; storage.objects **metadata**'sı dahil ama fiziksel dosyalar hariç).
4. Dump yeni projeye `pg_restore` edilir.
5. Storage'daki 119 dosya ayrı bir script ile eski projeden indirilip yeni projeye yüklenir.
6. 2 pg_cron job'ı yeni projede yeniden oluşturulur (schedule'lar zaten biliniyor).
7. 7 edge function yeniden deploy edilir (kod repo'da `supabase/functions/` altında zaten mevcut).
8. Edge function secret'ları (OPENROUTER_API_KEY, RESEND_API_KEY, Gemini/Cloudflare anahtarları vb.) yeni projeye kopyalanır.
9. Vercel'deki ilgili env var'lar (`NEXT_PUBLIC_SUPABASE_URL`, anon key, service role key, `SUPABASE_DB_URL` — worker `.env` dahil) güncellenir.

## Doğrulama ve Rollback

Her adımdan sonra doğrulama yapılmadan bir sonrakine geçilmez:

1. **Satır sayısı karşılaştırması** — her tablo için eski/yeni proje satır sayıları eşleşmeli.
2. **Storage doğrulama** — dosya sayısı ve toplam boyut eşleşmeli.
3. **Cutover öncesi duman testi** — yeni projeye karşı (staging/lokal'den): giriş yap, işletme ara/görüntüle, yorum yaz, sahip paneli işlemi, admin paneli işlemi.
4. **Cutover** — yalnızca 1-3 tamamen yeşil olduktan sonra Vercel env var'ları değiştirilip production'a deploy edilir.
5. **Cutover sonrası canlı doğrulama** — aynı duman testi `www.yeedoy.com` üzerinden tekrarlanır.
6. **Rollback** — sorun bulunursa Vercel env var'ları anında eski projeye geri çevrilir (eski proje bu süre boyunca dokunulmamış, hâlâ canlı). Eski proje cutover sonrası en az birkaç gün silinmeden/pause edilmeden bekletilir.

## Bileşenler / Dosya Yapısı

Bir kerelik altyapı işi olduğu için ana uygulama kod tabanına dahil edilmez — repo kökünde geçici bir `migration/` klasöründe:

- **`migration/dump_restore.md`** — çalıştırılacak `pg_dump`/`pg_restore` komutları ve sırası (extension etkinleştirme adımı dahil).
- **`migration/storage_copy.mjs`** — 119 dosyayı Supabase Storage API ile eski projeden indirip yeni projeye yükleyen tek seferlik Node script (`@supabase/supabase-js`, iki projenin service role key'iyle).
- **`migration/verify.sql`** — her şema/tablo için eski-yeni satır sayısı karşılaştırma sorguları.
- **`migration/secrets_checklist.md`** — kopyalanması gereken edge function secret'larının ve Vercel env var'larının listesi.

Bu dosyalar migrasyon tamamlanıp doğrulandıktan sonra silinebilir (geçici, tek kullanımlık).

## Bilinen Riskler

- **Auth şeması migrasyonu**: `auth.users` ve ilişkili tabloların (`identities`, `sessions`, `refresh_tokens`, MFA faktörleri) dump/restore edilmesi Supabase tarafından resmi olarak desteklenen bir yöntem, ama dikkatli yapılmalı (instance-specific şifreleme/JWT secret farklılıkları göz önünde bulundurulmalı). Sadece 9 test kullanıcısı olduğu için risk düşük.
- **Edge function secret'ları** pg_dump'ın kapsamında değil — manuel olarak yeniden girilmeli, unutulursa ilgili fonksiyon (ör. AI alerjen/kalori tahmini, e-posta kampanyası) sessizce bozulabilir. `secrets_checklist.md` bu riski azaltmak için var.
- **Worker `.env` dosyaları** (`D:\yeedoy-google-maps-coverage-v5\.env` gibi, ana repo dışında) da güncellenmeli — unutulursa worker eski (artık pasif) projeye bağlanmaya devam eder.
