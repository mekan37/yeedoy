# iyzico Ödeme Entegrasyonu — Kurulum ve Yol Haritası

**Durum (2026-09-03):** Henüz kayıtlı bir şirket (şahıs şirketi dahil) yok. Bu doküman, şirket kurulumundan gerçek kod entegrasyonuna kadar izlenecek sırayı ve her adımın neyi beklediğini/neyi paralel yapılabileceğini netleştiriyor. **Kod entegrasyonu bu dokümanın kapsamında değil** — o, şirket + iyzico onayı tamamlandıktan sonra ayrı bir implementasyon planıyla (superpowers:writing-plans) ele alınacak, çünkü o noktada hem güncel DB şemasını hem iyzico'nun o anki API sözleşmesini yeniden doğrulamak gerekecek.

**Önceki araştırma:** Bu planın dayandığı sağlayıcı karşılaştırması ve yasal gereksinim araştırması bu oturumda yapıldı (iyzico önerisi, BDDK/KVKK/e-fatura bulguları). Kesin yasal prosedürler için (özellikle Faz 0) bir muhasebeci/mali müşavirle teyit şart — bu doküman bir yol haritası, hukuki danışmanlık değil.

---

## Faz 0 — Şirket kuruluşu (önce bu, hiçbir kod işi buna bağlı değil ama gerçek ödeme almak buna bağlı)

- [ ] **Şirket türüne karar ver.** Araştırmaya göre şahıs şirketi iyzico başvurusu için yeterli (sermaye şirketi şartı yok) — daha hızlı ve ucuz kurulur. Limited şirkete geçiş ileride, ciro büyüdükçe her zaman yapılabilir. **Öneri: başlangıç için şahıs şirketi**, ama bunu bir mali müşavirle (vergi yükü, sorumluluk farkı açısından) teyit et.
- [ ] **Bir mali müşavir/muhasebeci ile anlaş** (yoksa). Şirket kuruluşu, vergi levhası, ileride e-fatura/e-arşiv süreci hep bu kişi üzerinden yürüyecek — en başta bulmak sonradan aramaktan iyi.
- [ ] **Vergi dairesine kayıt + vergi levhası al.** İyzico başvurusunun ön şartı bu.
- [ ] **Ticaret sicili kaydı** (şahıs şirketi için genelde vergi kaydıyla birlikte, esnaf sicili veya ticaret sicili — muhasebeciyle netleştir).
- [ ] **İmza sirküleri** çıkart (şirket türüne göre gerekebilir).

**Bu fazın süresi** muhasebeci/vergi dairesi sürecine bağlı — günler değil, genelde 1-2 hafta bandında olabilir (kesin değil, teyit et).

---

## Faz 1 — Yasal metinler (Faz 0 ile paralel yapılabilir, kod değişikliği içerir ama basit)

iyzico başvurusunun ön şartlarından biri sitede bu metinlerin bulunması. Mevcut durumu kontrol et:

- [ ] `uygulamalar/web/app/(genel)/yasal/terms` ve `/yasal/privacy` sayfalarının güncel içeriğini oku.
- [ ] **KVKK aydınlatma metni** var mı, eksikse ekle/güncelle.
- [ ] **Açık rıza metni** — özellikle *tekrarlayan ödeme* için ayrı bir onay kutusu/metni gerekiyor (araştırmada PayTR kaynağı bunu net şart olarak belirtiyor — muhtemelen iyzico için de geçerli, teyit edilecek). Bu, kayıt/yükseltme akışında bir UI elemanı demek — şimdiden not düş, Faz 3'te uygulanır.
- [ ] **Mesafeli satış sözleşmesi** — dijital abonelik hizmeti için şablon metin (avukat/muhasebeci ile netleştir, internette çokça örnek şablon var ama Yeedoy'a özel uyarlanmalı).
- [ ] **Yenileme öncesi bildirim** yükümlülüğü — bu bir UI/otomasyon işi (Faz 3'te), ama metinlerde de belirtilmesi gerekebilir.

---

## Faz 2 — iyzico başvurusu (Faz 0 tamamlanınca)

- [ ] iyzico'ya merchant (üye işyeri) başvurusu yap — vergi levhası, ticaret sicil kaydı, imza sirküleri (varsa) ile.
- [ ] Başvuru onaylanınca **canlı (production) API key + secret key** alınır.
- [ ] **Ayrıca, onay beklenmeden hemen şimdi yapılabilir:** iyzico'nun **sandbox/test ortamı** için ücretsiz bir geliştirici hesabı aç (genelde şirket onayı gerektirmez, sadece kayıt yeterli — **bunu iyzico'nun güncel kayıt sayfasından teyit et**, garanti vermiyorum). Bu sayede Faz 3'ün teknik geliştirmesi, gerçek şirket/merchant onayını beklemeden **paralel** başlayabilir.
- [ ] "Abonelik" (Subscription) ürününün hesapta aktif olduğunu doğrula — bu, standart üye işyeri hesabından ayrı bir ürün olabilir, ayrıca talep etmek gerekebilir.
- [ ] Komisyon oranını ve "Subscription ürün ücreti" (araştırmada aylık ~199₺ olarak geçen, teyit edilmesi gereken bir kalem) net olarak yazılı teyit al.

---

## Faz 3 — Teknik entegrasyon (Faz 2'nin sandbox kısmıyla paralel başlanabilir, canlıya alma Faz 2'nin tam onayını bekler)

**Bu faz, "sonra entegre edicez" dediğin kısım — burada kod yazılmayacak, sadece kapsamın yüksek seviye haritası çıkarılıyor ki geliştirme başladığında nereden başlanacağı belli olsun.**

### 3a. Veri modeli (Supabase)
- Abonelik durumunu takip edecek bir tablo gerekecek (örn. `business_subscriptions`: business_id, plan_tier, iyzico_subscription_reference_id, status, current_period_end, vb.) — **ham kart verisi asla saklanmayacak**, sadece iyzico'nun verdiği referans/token ID.
- Mevcut `businesses` tablosundaki plan/tier bilgisiyle (varsa) ilişkilendirme netleştirilecek.
- Ödeme geçmişi/fatura kaydı için ayrı bir tablo gerekebilir (e-fatura entegrasyonuyla bağlantılı olacak — Faz 0/1'deki muhasebeci görüşmesinde netleşecek).

### 3b. Sunucu tarafı entegrasyon
- iyzico Node.js SDK'sı (`iyzipay-node` veya güncel adıyla ne ise) ile abonelik oluşturma/iptal/plan değiştirme çağrıları — **server-side only**, API key asla client'a sızmayacak (bu oturumda menü analiz özelliğinde kurulan `disari-cagri.ts` tarzı "secret'ların tek bir yerde okunduğu" deseni burada da tekrarlanacak).
- **Webhook endpoint'i** — iyzico'nun tahsilat sonucu/abonelik durumu bildirimlerini alacak bir route handler (imza doğrulaması dahil — bu kritik bir güvenlik noktası, atlanmamalı).
- Başarısız tahsilat (dunning) akışı: kart reddi/limit yetersizliği durumunda ne olacak (otomatik downgrade mi, X gün deneme mi, kullanıcıya bildirim mi) — bu bir ürün kararı, geliştirme başlamadan netleştirilmeli.

### 3c. UI değişiklikleri
- `/fiyatlandirma` ve `/sahip/premium` sayfalarındaki CTA'lar şu an "kayıt ol" veya "destek talebi" ile bitiyor — bunlar gerçek "planı seç ve öde" akışına bağlanacak.
- Kayıt/yükseltme akışında açık rıza onay kutusu (Faz 1'de bahsedilen).
- Sahip panelinde abonelik durumu, sonraki tahsilat tarihi, kart güncelleme, iptal gibi self-servis öğeler.

### 3d. Test
- Sandbox ortamında uçtan uca: abonelik oluşturma, plan değiştirme (upgrade/downgrade), iptal, başarısız kart senaryosu.
- Webhook'ların gerçekten tetiklendiğini ve doğru işlendiğini doğrulama.

---

## Özet — şimdi ne yapmalısın

**Bu hafta başlayabileceklerin (Faz 0 + Faz 1, kod değil):**
1. Mali müşavir bul/görüş, şahıs şirketi kurulum sürecini başlat.
2. `/yasal/terms`, `/yasal/privacy` sayfalarının mevcut içeriğini oku, eksikleri not al.

**Şirket kurulurken paralel yapılabilecek (isteğe bağlı, erken başlamak istersen):**
3. iyzico sandbox/test hesabı açmayı dene (şirket gerektirmeyebilir, doğrula).

**Şirket + iyzico onayı tamamlanınca ("sonra entegre edicez" dediğin an):**
4. Bana haber ver, Faz 3'ü gerçek bir implementasyon planına (superpowers:writing-plans ile, o anki güncel DB şeması ve iyzico API sözleşmesi doğrulanarak) çeviririz ve entegrasyona başlarız.
