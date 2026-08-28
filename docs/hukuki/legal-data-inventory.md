# Yeedoy — Kişisel Veri Envanteri

**Hazırlanma tarihi:** 2026-06-18  
**Hazırlayan:** İş Analizi  
**Kapsam:** Tüm platformlar (mobil Flutter, Next.js web — owner/admin paneli dahil, Supabase backend). Not (2026-06-24): "Personel Flutter Web" uygulaması ürün kapsamından kaldırıldı; işletme personeli operasyonları artık Next.js web (`uygulamalar/web`) üzerinden yürütülüyor.  
**Yönetmelik referansı:** 6698 sayılı KVKK, GDPR (AB vatandaşlarına erişim varsa), Türkiye Elektronik Ticaret Kanunu  

---

## İçindekiler

1. [Kimlik ve Hesap Verileri](#1-kimlik-ve-hesap-verileri)
2. [Konum Verileri](#2-konum-verileri)
3. [Kullanıcı Tarafından Üretilen İçerik](#3-kullanıcı-tarafından-üretilen-içerik)
4. [İşletme Verileri](#4-i̇şletme-verileri)
5. [Bildirim ve Mesajlaşma Verileri](#5-bildirim-ve-mesajlaşma-verileri)
6. [Yasal Uyum ve Gizlilik Talep Verileri](#6-yasal-uyum-ve-gizlilik-talep-verileri)
7. [Analitik ve Teknik Veriler](#7-analitik-ve-teknik-veriler)
8. [Üçüncü Taraf Entegrasyonları](#8-üçüncü-taraf-entegrasyonları)
9. [Veri Saklama Süresi Özeti](#9-veri-saklama-süresi-özeti)
10. [Eksik veya Risk Taşıyan Alanlar](#10-eksik-veya-risk-taşıyan-alanlar)

---

## 1. Kimlik ve Hesap Verileri

| # | Veri Kalemi | Tablo / Kaynak | İşlenme Amacı | Saklama Süresi | Üçüncü Taraf Paylaşımı | Hukuki Dayanak |
|---|-------------|---------------|---------------|----------------|------------------------|----------------|
| 1.1 | E-posta adresi | `auth.users` (Supabase Auth) | Hesap oluşturma, giriş, şifre sıfırlama, pazarlama e-postası (opt-in) | Hesap silinene kadar | Supabase Auth (altyapı), Resend (transactional e-posta) | Sözleşme ifası / Açık rıza (pazarlama) |
| 1.2 | Şifre (hash) | `auth.users` (Supabase Auth) | Kimlik doğrulama | Hesap silinene kadar | Supabase Auth (altyapı, hash olarak) | Sözleşme ifası |
| 1.3 | Telefon numarası | `auth.users` (Supabase Auth) + `owner_claims.phone` | SMS OTP ile giriş, işletme sahipliği başvurusu | Hesap silinene kadar / Talep karara bağlanana kadar | Supabase Auth, SMS sağlayıcısı (Twilio/MessageBird) | Sözleşme ifası |
| 1.4 | Görünen ad (display_name) | `user_profiles.display_name` | Profil sayfası, yorum gösterimi, işbirlikçi liste üyeliği | Hesap silinene kadar | Yok | Sözleşme ifası |
| 1.5 | Avatar / profil fotoğrafı URL | `user_profiles.avatar_url` | Profil sayfası gösterimi | Hesap silinene kadar | Supabase Storage (CDN) | Sözleşme ifası |
| 1.6 | Google OAuth profil bilgisi (ad, e-posta, profil resmi) | `auth.users` (Supabase OAuth) | Google ile giriş | Hesap silinene kadar | Google (kimlik doğrulama için), Supabase Auth | Açık rıza |
| 1.7 | Kullanıcı rolü (authenticated, owner, admin) | `auth.users.app_metadata`, `admin_users`, `owner_claims` | Rol tabanlı erişim kontrolü | Hesap / rol silinene kadar | Yok | Meşru menfaat (güvenlik) |
| 1.8 | Takım üyeliği daveti e-postası | `business_team_memberships.invite_email` | İşletme ekibine davet | Davet kabul / iptal edilene kadar | Resend (davet e-postası için) | Meşru menfaat (sözleşme ifası) |
| 1.9 | İtibari puan (reputation score) | Hesaplama fonksiyonu `get_my_reputation_score_v1` | Topluluk güven skoru | Gerçek zamanlı hesaplama (kalıcı tablo yok) | Yok | Meşru menfaat |
| 1.10 | Gölge-ban durumu (shadow_banned) | `user_profiles.shadow_banned` | İçerik moderasyonu | Hesap silinene kadar | Yok | Meşru menfaat (platform güvenliği) |

---

## 2. Konum Verileri

| # | Veri Kalemi | Tablo / Kaynak | İşlenme Amacı | Saklama Süresi | Üçüncü Taraf Paylaşımı | Hukuki Dayanak |
|---|-------------|---------------|---------------|----------------|------------------------|----------------|
| 2.1 | Kullanıcı şehir / ilçe tercihi | `user_location_prefs.city`, `user_location_prefs.district` | Yakın işletme keşfi, fiyat uyarıları | Kullanıcı silinceye veya güncellemeye kadar | Yok | Açık rıza |
| 2.2 | Konum modu (otomatik / manuel) | `user_location_prefs.mode` | UX tercihi, otomatik konum izin yönetimi | Yukarıdaki ile aynı | Yok | Açık rıza |
| 2.3 | Anlık GPS koordinatları | Cihaz (Flutter `geolocator`), uygulama belleğinde | Yakın işletme arama, mesafe hesaplama | Oturum süresi (kalıcı olarak saklanmaz) | Yok | Açık rıza |
| 2.4 | Fiyat uyarısı için şehir/ilçe | `price_alerts.city`, `price_alerts.district` | Kullanıcının belirttiği fiyat alarmı filtresi | Uyarı silinene kadar | Yok | Açık rıza |
| 2.5 | İşletme adresi (lat/lng, şehir, ilçe) | `businesses.lat`, `businesses.lng`, `businesses.city`, `businesses.district` | Harita gösterimi, mesafe hesabı, public API | Süresiz (kamuya açık veri) | Kamuya açık API yanıtı | Meşru menfaat |

---

## 3. Kullanıcı Tarafından Üretilen İçerik

| # | Veri Kalemi | Tablo / Kaynak | İşlenme Amacı | Saklama Süresi | Üçüncü Taraf Paylaşımı | Hukuki Dayanak |
|---|-------------|---------------|---------------|----------------|------------------------|----------------|
| 3.1 | Yorum metni ve puanı | `reviews.content`, `reviews.rating` | İşletme değerlendirmesi | Kullanıcı silme talebi / moderasyon kararına kadar | Yok (public API'de görünür, anonim değil) | Açık rıza |
| 3.2 | Yorum fotoğrafı (üretilecek) | `menu_item_photos.url` | Menü öğesi görsel doğrulaması | Fotoğraf silinene kadar | Supabase Storage (CDN) | Açık rıza |
| 3.3 | Yorum doğrulanmış ziyaret bayrağı | `reviews.verified_visit` | Güven rozeti gösterimi | Yorum silinene kadar | Yok | Meşru menfaat |
| 3.4 | Fiyat önerisi | `menu_item_price_suggestions.suggested_price_cents`, `created_by` | Topluluk fiyat güncelleme katkısı | Onay/ret kararına kadar; kabul edilirse süresiz | Yok | Açık rıza |
| 3.5 | Favoriler | `user_favorites` (tablo referansı, feature `favorites`) | Kişisel favori listesi | Kullanıcı silene kadar | Yok | Sözleşme ifası |
| 3.6 | İşletme takibi | `business_follows.user_id`, `business_follows.is_subscribed_email` | Feed akışı, e-posta bülteni opt-in | Kullanıcı takibi bırakana kadar | Owner tarafına özetlenmiş sayı; opt-in olanların e-postası Resend'e iletilir | Açık rıza (e-posta için); meşru menfaat (feed için) |
| 3.7 | Kullanıcı takibi (gourmet takip) | `user_follows` (feature `gourmets`) | Sosyal feed akışı | Kullanıcı silinene kadar | Yok | Sözleşme ifası |
| 3.8 | İşbirlikçi liste (collab list) | `collab_lists`, `collab_list_members`, `collab_list_items`, `collab_list_votes` | Arkadaşlarla ortak restoran listesi | Silme işlemine kadar | Yok | Sözleşme ifası |
| 3.9 | Grup rezervasyon talebi | `group_requests` (şehir, ilçe, kişi sayısı, bütçe, notlar) | Toplu rezervasyon / ters açık artırma | Talebin kapanmasına kadar | İşletme sahiplerine görünür | Açık rıza |
| 3.10 | Grup teklif mesajı | `offer_messages.body` | Rezervasyon müzakeresi | Talep silinene kadar | İlgili işletme sahibine görünür | Sözleşme ifası |
| 3.11 | Fiyat uyarısı kriteri | `price_alerts.query`, `price_alerts.max_price_cents` | Bildirim tetikleyicisi | Uyarı silinene kadar | Yok | Açık rıza |
| 3.12 | Başarım (achievement) kaydı | `user_achievements.achievement_id`, `unlocked_at` | Gamifikasyon | Hesap silinene kadar | Yok | Sözleşme ifası |
| 3.13 | Haftalık liderboard gönderisi | `get_weekly_contributor_leaderboard_v1` hesabı | Topluluk katkı sıralaması | Gerçek zamanlı sorgu (kalıcı değil) | Yok | Meşru menfaat |

---

## 4. İşletme Verileri

| # | Veri Kalemi | Tablo / Kaynak | İşlenme Amacı | Saklama Süresi | Üçüncü Taraf Paylaşımı | Hukuki Dayanak |
|---|-------------|---------------|---------------|----------------|------------------------|----------------|
| 4.1 | İşletme sahipliği başvurusu (ad soyad, telefon, kanıt URL'si) | `owner_claims.full_name`, `owner_claims.phone`, `owner_claims.evidence_url` | Sahiplik doğrulaması | Karar tarihinden itibaren 1 yıl (öneri) | Yok | Sözleşme ifası / Açık rıza |
| 4.2 | Menü içeriği (ürün adı, fiyat, açıklama, fotoğraf) | `menu_items`, `menu_sections`, `menu_item_photos` | Genel menü gösterimi | İşletme aktif olduğu sürece; arşivlenenler belirsiz süre | Supabase Storage (CDN), kamuya açık API | Sözleşme ifası |
| 4.3 | Menü anlık görüntüsü (snapshot) | `menu_snapshots.snapshot_json` | Sürüm geçmişi, geri yükleme | 90 gün (öneri; limit mevcut değil) | Yok | Meşru menfaat |
| 4.4 | İşletme çalışma saatleri | `business_hours` | Açık/kapalı gösterimi | İşletme aktif olduğu sürece | Kamuya açık API | Sözleşme ifası |
| 4.5 | İşletme medyası (logo, kapak, hikaye) | `business_media`, `business_stories` | Profil görseli, kampanya | Medya silinene kadar | Supabase Storage (CDN) | Sözleşme ifası |
| 4.6 | QR kod ve kısa bağlantı | `menu_aliases`, kısa kod | Menüye erişim | İşletme aktif olduğu sürece | Yok | Sözleşme ifası |
| 4.7 | Sponsorluk lead bilgisi (telefon, mesaj) | `sponsorship_leads.phone`, `sponsorship_leads.message` | Reklam teklif başvurusu | Talep karara bağlanana kadar | Yok | Açık rıza |
| 4.8 | İşletme ekip üyeliği ve rol | `business_team_memberships` | RBAC yönetimi | Üyelik iptal edilene kadar | Yok | Sözleşme ifası |
| 4.9 | Onboarding ilerleme adımı | `owner_onboarding_progress.step_completed` | Kurulum kılavuzu | İşletme aktif olduğu sürece | Yok | Meşru menfaat |
| 4.10 | İşletme aktivite logu | `business_activity_log` (menü güncellemeleri) | Feed akışı tetikleyicisi | Süresiz (temizleme politikası yok) | Yok | Meşru menfaat |
| 4.11 | Premium/doğrulanmış rozet durumu | `business_premium`, `businesses.is_verified` | Görünürlük özellikleri | Abonelik süresince | Kamuya açık API | Sözleşme ifası |

---

## 5. Bildirim ve Mesajlaşma Verileri

| # | Veri Kalemi | Tablo / Kaynak | İşlenme Amacı | Saklama Süresi | Üçüncü Taraf Paylaşımı | Hukuki Dayanak |
|---|-------------|---------------|---------------|----------------|------------------------|----------------|
| 5.1 | FCM push token | `user_devices.fcm_token` | Push bildirim gönderimi | Son görülmeden 120 gün sonra otomatik silinir; veya kullanıcı oturumu kapatınca | Firebase Cloud Messaging (Google) | Açık rıza |
| 5.2 | Platform ve uygulama sürümü | `user_devices.platform`, `user_devices.app_version` | Bildirim uyumluluk yönetimi | Yukarıdaki ile aynı | Yok | Meşru menfaat |
| 5.3 | Bildirim içeriği (başlık, gövde) | `notifications.title`, `notifications.body` | Kullanıcı inbox gösterimi | Okunana kadar / hesap silinene kadar | Yok | Sözleşme ifası |
| 5.4 | Bildirim okundu bayrağı | `notifications.is_read` | UX durum takibi | Yukarıdaki ile aynı | Yok | Sözleşme ifası |
| 5.5 | Transactional e-posta (yorum cevabı, fiyat uyarısı) | Resend üzerinden gönderim | Kullanıcı bilgilendirmesi | Gönderim logu Resend'de (3. taraf politikası) | Resend (e-posta iletim hizmeti) | Sözleşme ifası |
| 5.6 | Pazarlama e-postası opt-in | `business_follows.is_subscribed_email` | İşletmeden kullanıcıya bülten | Takip bırakılana kadar | Resend (iletim için) | Açık rıza |

---

## 6. Yasal Uyum ve Gizlilik Talep Verileri

| # | Veri Kalemi | Tablo / Kaynak | İşlenme Amacı | Saklama Süresi | Üçüncü Taraf Paylaşımı | Hukuki Dayanak |
|---|-------------|---------------|---------------|----------------|------------------------|----------------|
| 6.1 | Politika kabul kaydı (kullanıcı) | `user_policy_acceptances` (user_id, policy_version_id, accepted_at, ip_address, user_agent, source_app) | KVKK ispat yükümlülüğü | Hesap silinene kadar (önerilen: +3 yıl arşiv) | Yok | Yasal yükümlülük |
| 6.2 | İşletme politika kabul kaydı | `business_policy_acceptances` | İşletme sahipleri için ayrı kabul kanıtı | Yukarıdaki ile aynı | Yok | Yasal yükümlülük |
| 6.3 | Gizlilik başvurusu | `privacy_requests` (request_type, status, details, submitted_at) | KVKK madde 11 başvurusu (erişim, düzeltme, silme, itiraz vb.) | Çözülmeden en az 3 yıl | Yok | Yasal yükümlülük |
| 6.4 | Hesap silme talebi | `account_deletion_requests` (reason, status, requested_at, completed_at) | Hesap silme süreç takibi | Talep tamamlanmadan önce; sonrasında 1 yıl log (öneri) | Yok | Yasal yükümlülük |
| 6.5 | Politika sürüm kataloğu | `policy_versions` (policy_type, version_label, content_hash, published_at, is_active) | Hangi metnin hangi tarihte geçerli olduğunun kanıtı | Süresiz (değiştirilemez kayıt) | Yok | Yasal yükümlülük |
| 6.6 | IP adresi (kabul kaydında) | `user_policy_acceptances.ip_address`, `business_policy_acceptances.ip_address` | Kabul kanıtı için KVKK ispat | Yukarıdaki ile aynı | Yok | Yasal yükümlülük |

Aktif politika türleri (policy_type): `terms`, `privacy`, `cookies`, `community`, `business`, `copyright`, `ai`, `dmca`, `dsa`, `data-safety`, `trust-safety`, `security`, `law-enforcement`, `delete-account`

---

## 7. Analitik ve Teknik Veriler

| # | Veri Kalemi | Tablo / Kaynak | İşlenme Amacı | Saklama Süresi | Üçüncü Taraf Paylaşımı | Hukuki Dayanak |
|---|-------------|---------------|---------------|----------------|------------------------|----------------|
| 7.1 | Menü ve QR olay logu | `analytics_events` (event_name, business_id, menu_id, source, client_id, user_id, meta) | İşletme analitiği, büyüme ölçümü | Sınırsız (temizleme politikası yok) | Yok | Meşru menfaat |
| 7.2 | Web analitik olayları (web) | `analytics.ts` kaynaklı log (page_view, item_click, qr_scanned) | Kullanıcı davranış analizi | Yukarıdaki tabloya yazılır | Yok | Meşru menfaat |
| 7.3 | İstek başlığı (user-agent, IP) | `capture_request_metadata_v1` trigger | Yasal kayıt (yukarı bkz.) | Politika kabul kaydı ile aynı | Yok | Yasal yükümlülük |
| 7.4 | Firebase Crashlytics çökme logu | Firebase Crashlytics SDK (mobil) | Çökme / hata izleme | Firebase / Google veri tutma politikasına göre (yapılandırılabilir) | Firebase / Google (ABD) | Meşru menfaat |
| 7.5 | Rate-limit sayacı | `user_rate_limits` (key, user_id, action, day, count) | Spam koruması | Günlük; eski satırlar temizlenmeli | Yok | Meşru menfaat |
| 7.6 | Sunucu tarafı log (Next.js) | `logger.ts` (JSON yapılandırılmış) | Hata ayıklama, güvenlik | Deployment ortamına göre değişken (öneri: 30 gün) | Yok | Meşru menfaat |
| 7.7 | Menü item aktivite logu | `business_activity_log` (meta JSONB) | Feed tetikleyici, owner analitik | Süresiz (temizleme politikası yok) | Yok | Meşru menfaat |

---

## 8. Üçüncü Taraf Entegrasyonları

| # | Entegrasyon | Aktarılan Veri | Amaç | Güvenlik Mekanizması | Hukuki Dayanak |
|---|------------|---------------|------|----------------------|----------------|
| 8.1 | Supabase (altyapı, Frankfurt / EU) | Tüm kullanıcı ve içerik verileri | Veritabanı, kimlik doğrulama, dosya depolama | RLS, SECURITY DEFINER fonksiyonlar, TLS | Sözleşme ifası / Veri işleme anlaşması |
| 8.2 | Google Sign-In / Firebase Auth | E-posta, ad, profil resmi (Google'dan alınan) | Sosyal giriş | OAuth 2.0 PKCE, ID token doğrulama | Açık rıza |
| 8.3 | Firebase Cloud Messaging (FCM) | FCM push token, bildirim başlığı/gövdesi | Push bildirim iletimi | HTTPS, JWT service account | Açık rıza |
| 8.4 | Resend (e-posta servisi) | E-posta adresi, görünen ad | Transactional ve pazarlama e-posta | API key, TLS | Sözleşme ifası / Açık rıza (pazarlama) |
| 8.5 | Firebase Crashlytics / Analytics / Performance | Anonim çökme trace'leri, kullanım istatistikleri, cihaz bilgisi | Çökme izleme, kullanım analitiği, performans izleme | Firebase SDK güvenlik mekanizmaları, sınırlı PII toplama | Meşru menfaat |
| 8.6 | Twilio / MessageBird (SMS) | Telefon numarası | OTP gönderimi | Supabase Auth üzerinden | Sözleşme ifası |

---

## 9. Veri Saklama Süresi Özeti

| Veri Kategorisi | Önerilen Süre | Mevcut Durum |
|----------------|--------------|--------------|
| Auth verileri (e-posta, şifre hash) | Hesap silinene kadar | Uygun |
| Profil verileri | Hesap silinene kadar | Uygun |
| Politika kabul kayıtları | Hesap silinmesi + 3 yıl | Belirsiz — sınır yok |
| Gizlilik başvuruları | En az 3 yıl | Belirsiz — sınır yok |
| Push token | 120 gün hareketsizlik | Uygulanmış (trigger var) |
| Analitik event log | 24 ay (KVKK önerisi) | Belirsiz — sınır yok |
| İşletme aktivite log | 12 ay | Belirsiz — sınır yok |
| Rate limit sayacı | Günlük | Uygulama gerektiriyor |
| Firebase Crashlytics logu | Firebase / Google politikasına bırakılmış | Belirsiz — Google Cloud DPA'da netleştirilmeli |
| Menü snapshot | 90 gün veya manuel temizlik | Belirsiz — sınır yok |
| FCM bildirim kaydı | Okundu + 30 gün | Belirsiz — sınır yok |

---

## 10. Eksik veya Risk Taşıyan Alanlar

Aşağıdaki alanlar hukuki metin hazırlığından önce adreslenmesi önerilen boşluklardır:

| # | Bulgu | Risk | Önerilen Aksiyon |
|---|-------|------|-----------------|
| R-1 | `analytics_events` tablosunun saklama süresi tanımsız | KVKK'ya göre gereksiz saklama yasağı | Otomatik temizlik job'u ekle (örn. 24 ay sonrası silinsin) |
| R-2 | `business_activity_log` sınır yok | Veri minimizasyon ilkesi ihlali riski | Temizleme politikası belirle |
| R-3 | `menu_snapshots` saklanma süresi belirsiz | Gereksiz veri birikimi | 90 günlük TTL ekle |
| R-4 | `user_policy_acceptances` IP adresi kaydediliyor ancak kullanıcıya politikada bildirilmemişse sorun oluşur | KVKK md. 10 aydınlatma yükümlülüğü | Gizlilik politikasında IP kaydedildiği belirtilmeli |
| R-5 | Pazarlama e-postası için opt-in (`is_subscribed_email`) ayrı bir onay akışında mı alınıyor? Kod açık ama UI akışı doğrulanmadı | KVKK/BTK ticari elektronik ileti yönetmeliği | Opt-in akışının ayrı onay kutusuna dayandığını doğrula |
| R-6 | Firebase Crashlytics stack trace'lerinde istem dışı kullanıcı verisi sızabilir | GDPR/KVKK aktarım riski | Firebase / Google Cloud DPA (Data Processing Amendment) imzalanmalı; ABD aktarımı için KVKK güvencesi doğrulanmalı |
| R-7 | `group_requests` ve `offer_messages` içeriği üçüncü taraf (işletme sahibi) tarafından görülebiliyor | Gizlilik ihlali riski | Kullanıcı aydınlatma metninde açıkça belirt |
| R-8 | `notifications` tablosunda silme politikası yok | Kişisel veri birikim riski | Okunan bildirimleri 90 gün sonra sil |
| R-9 | İşletme sahipliği başvurusunda (owner_claims) saklama süresi belirsiz | KVKK md. 7 silme yükümlülüğü | Karara bağlanan başvurular için 1 yıl + arşiv politikası yaz |
| R-10 | Uygulama içi Siri/Google Assistant kısayolu donasyonu iOS'ta NSUserActivity ile yapılıyor; arama/keşif verisi cihazda önbelleğe alınıyor | Cihaz düzeyinde gizlilik | iOS gizlilik politikasında bu API kullanımı belirtilmeli |

---

*Bu envanter kod denetimi ve migration analizi sonucu üretilmiştir. Gizlilik metinleri (KVKK Aydınlatma Metni, Gizlilik Politikası, Kullanım Şartları) bu envantere dayandırılarak hukuk danışmanı tarafından hazırlanmalıdır.*
