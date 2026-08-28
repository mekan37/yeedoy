# Kritik Gizlilik Eksikleri Raporu

**Hazırlayan:** Uyumluluk Denetçisi  
**Tarih:** 2026-06-17  
**Kapsam:** R-4 ve R-5 — legal-preflight-report.md kaynaklı iki kritik risk  
**Durum:** KESİN BULGULAR — kod tabanı doğrulamasına dayalı

---

## Özet

`legal-preflight-report.md` içinde tanımlanan iki kritik risk (R-4 ve R-5) için tam teknik araştırma tamamlanmıştır. Her iki risk de **A — önce kod değişikliği gerekir** kategorisine girmektedir. Tek başına hukuki metin güncellemesi yeterli değildir; mevcut kullanıcıya dürüstçe taahhüt edilebilecek bir teknik gerçeklik bulunmamaktadır.

---

## R-4: IP Adresi Sessiz Kaydı — Teknik Akış ve Hukuki Durum

### 4.1 Tam Teknik Akış

**Tetikleyici:** Kullanıcı `LegalAcceptancePage`'deki zorunlu onay kutusunu işaretleyip "Devam Et" tuşuna basar.

**İstemci tarafı (Flutter — `legal_repository.dart`):**

```
acceptPolicyVersions(versions) çağrılır
  → her version için user_policy_acceptances tablosuna INSERT
  → gönderilen alanlar: user_id, policy_version_id, accepted_at, source_app, user_agent
  → ip_address alanı Flutter kodu tarafından HİÇ gönderilmez
```

**Sunucu tarafı (PostgreSQL — aktif tetikleyici):**

Dosya: `supabase/migrations/20260414000010_fix_capture_request_metadata_trigger.sql`

```sql
-- trg_user_policy_acceptances_capture_request_metadata_v1
-- BEFORE INSERT ON user_policy_acceptances
IF coalesce(to_jsonb(new)->>'ip_address', '') = '' THEN
  new := jsonb_populate_record(new, jsonb_build_object(
    'ip_address', public.request_ip_v1()
  ));
END IF;
```

`request_ip_v1()` işlevi sırasıyla `x-forwarded-for` ve `x-real-ip` HTTP başlıklarını okur ve ilk değeri döndürür.

**Sonuç:** INSERT tamamlandığında `user_policy_acceptances.ip_address` sütunu kullanıcının IP adresini içerir. Kullanıcı bu konuda hiçbir ön bilgi almamıştır.

### 4.2 Etkilenen Tablolar

Aynı `capture_request_metadata_v1()` tetikleyici işlevi şu tablolarda da çalışır:

| Tablo | Tetikleyici adı |
|---|---|
| `user_policy_acceptances` | `trg_user_policy_acceptances_capture_request_metadata_v1` |
| `business_policy_acceptances` | `trg_business_policy_acceptances_capture_request_metadata_v1` |
| `privacy_requests` | ayrı tetikleyici, aynı işlev |
| `account_deletion_requests` | ayrı tetikleyici, aynı işlev |

Bu rapordaki R-4 analizi `user_policy_acceptances` üzerine yoğunlaşmaktadır; ancak düzeltme planı tüm etkilenen tablolar için geçerlidir.

### 4.3 UI'de Açıklama Var mı?

**`legal_required_consent_card.dart`** — onay kutusu metni:

> "Devam ederek Kullanım Şartları ve Gizlilik Politikası'nı kabul ediyorum."

IP kaydına ilişkin herhangi bir metin yoktur. Kullanıcıya gösterilen ekranda:
- IP adresinin kaydedileceğine dair hiçbir bilgi bulunmamaktadır.
- Gizlilik politikasına bağlantı vardır, ancak bu politikanın henüz yazılmadığı (`legal-preflight-report.md` Bölüm 1'de belgelenmiştir) ve içeriğinin belirsiz olduğu bilinmektedir.
- `helperText` parametresi mevcut çağrı noktalarında boş bırakılmıştır.

`legal_acceptance_page.dart`'ın isteğe bağlı bölümü ("Ek İzinler") de yalnızca pazarlama opt-in ve analitik tercihlerine değinmektedir; IP kaydından bahsetmez.

### 4.4 KVKK Kapsamındaki Hukuki Pozisyon

**6698 sayılı KVKK md. 10 — Aydınlatma Yükümlülüğü:**  
Veri sorumlusu, kişisel verilerin elde edilmesi sırasında bilgilendirme yapmak zorundadır. IP adresi, cihaz başına statik veya uzun süreli kalmadığında bile kişisel veri kapsamındadır (Avrupa Veri Koruma Kurulu kılavuzu ve KVKK Kurul kararları bu yorumu destekler).

**Sorun:** IP kaydı, kullanıcıya herhangi bir aydınlatma yapılmadan ve politika kabulü gerçekleşmeden hemen önce ya da tam sırasında başlar. Mevcut teknik düzenleme KVKK md. 10 yükümlülüğünü ihlal etmektedir.

### 4.5 Minimum Düzeltme Planı

**Seçenek A1 — Tetikleyiciyi kaldır (önerilen):**  
`trg_user_policy_acceptances_capture_request_metadata_v1` tetikleyicisini devre dışı bırakın veya kaldırın. IP adresi kaydı için gerçek bir hukuki ihtiyaç tanımlanana kadar bu veriyi toplamayın.

**Seçenek A2 — Aydınlatma metnini ekle (tetikleyiciyi koruyorsa):**  
Onay ekranına tetikleyici çalışmadan önce görülen, açık bir aydınlatma notu ekleyin. Bu seçenek daha az temiz bir çözümdür ve yazılacak gizlilik politikasında IP kaydına ilişkin tam bir bölüm gerektirmektedir.

**Seçenek A1 tercih edilir** çünkü:
- IP adresinin toplanmasının günlük işletme operasyonu için zorunlu olduğu kanıtlanmamıştır.
- Veri minimizasyonu ilkesi (KVKK md. 4/2-c) gereksiz veri toplamayı yasaklar.
- Tetikleyiciyi kaldırmak, aydınlatma metni yazmaktan teknik olarak daha basittir.

### 4.6 UI Mikro Metin Önerileri (Seçenek A2 için)

Bunlar nihai hukuki metinler değildir; düzeltme yapılması durumunda hukuk danışmanının onaylaması gereken taslak yönlendirmelerdir.

**`legal_required_consent_card.dart` → `helperText` parametresine eklenecek taslak:**

> "Güvenlik ve doğrulama amacıyla bu işlem sırasında IP adresiniz kayıt altına alınır."

**`legal_acceptance_page.dart` → zorunlu onay bölümünün altına eklenecek taslak:**

> "IP adresiniz politika kabulünüzün doğrulanması amacıyla teknik kayıt olarak saklanır. Detaylar için Gizlilik Politikamıza bakınız."

**Önemli kısıt:** Bu metinler yazılacak Gizlilik Politikası'nın IP saklama süresini, amacını ve yasal dayanağını açıkça tanımlamasını gerektirmektedir. Bu bilgiler `legal-preflight-report.md` Bölüm 3'te bilinmeyenler arasında listelenmiştir (`[IP_SAKLAMA_SURESI]`, `[YURT_DISI_AKTARIM_DURUMU]`).

### 4.7 Teknik Görev Listesi (R-4)

- [ ] `user_policy_acceptances.ip_address` ve `user_agent` alanları için saklama ihtiyacı kararı alınır (ürün/hukuk ortak karar)
- [ ] Karar "kaldır" ise: `capture_request_metadata_v1()` tetikleyicisini devre dışı bırakan yeni bir migration yazılır
- [ ] Karar "kaldır" ise: mevcut `ip_address` ve `user_agent` verileri uygun şekilde temizlenir veya silinir (saklama politikası)
- [ ] Karar "koru" ise: `legal_required_consent_card.dart`'a aydınlatma helper text eklenir
- [ ] Karar "koru" ise: Gizlilik Politikası taslağına IP saklama süresi ve amacı bölümü eklenir
- [ ] `business_policy_acceptances`, `privacy_requests`, `account_deletion_requests` tablolarındaki eş tetikleyiciler aynı karar doğrultusunda güncellenir
- [ ] Değişiklik production'a alınmadan önce hukuk danışmanı onayı alınır

---

## R-5: Pazarlama E-posta Opt-In'i Kaydedilmiyor — Teknik Akış ve Hukuki Durum

### 5.1 Tam Teknik Akış

**Veritabanı altyapısı (`20260424000009_email_campaigns.sql`):**

```sql
ALTER TABLE business_follows
  ADD COLUMN is_subscribed_email boolean NOT NULL DEFAULT false;
```

Varsayılan değer `false`'tur — bu doğru bir yaklaşımdır. Kullanıcılar otomatik olarak abone edilmemektedir.

**E-posta kampanya edge function (`send-email-campaign/index.ts`):**

```typescript
.eq("is_subscribed_email", true)
```

Edge function yalnızca `is_subscribed_email = true` olan satırları sorgular. Bu doğru uygulanmıştır.

**Flutter UI (`legal_acceptance_page.dart` — `_submit()` metodu):**

```dart
// İsteğe bağlı onaylar bölümündeki switch:
SwitchListTile(
  title: const Text('Kampanya ve bildirim izinleri'),
  value: _marketingOptIn,       // kullanıcı bu değeri ayarlar
  onChanged: (v) => setState(() => _marketingOptIn = v),
)

// submit metodu:
Future<void> _submit() async {
  await ref.read(legalRepositoryProvider)
    .acceptPolicyVersions(versions);      // sadece bu çağrı yapılır
  // _marketingOptIn DEĞERİ BURADA KULLANILMIYOR
  // is_subscribed_email hiçbir tabloya yazılmıyor
}
```

**`notification_preferences_page.dart`:**

`_emailNotifs` boolean değişkeni bir `Switch` widget'ına bağlıdır ancak bu sayfada da hiçbir Supabase yazma çağrısı bulunmamaktadır. Sayfa tamamen yerel state yönetmektedir; tercihler kalıcı hale getirilmemektedir.

**Sonuç:** Mobileden `business_follows.is_subscribed_email = true` değerini ayarlayacak herhangi bir kod yolu mevcut değildir.

### 5.2 UI'de Opt-In Akışı Var mı?

Evet — ancak işlevsizdir.

`legal_acceptance_page.dart` içinde:
- Ayrı bir isteğe bağlı bölüm mevcuttur ("Ek İzinler") — bu yapı KVKK md. 5 kapsamında açık rıza için doğru bir yaklaşımdır
- Zorunlu onay kutusundan ayrı bir `SwitchListTile` kullanılmaktadır — bu da doğrudur
- Kullanıcı `_marketingOptIn = true` olarak ayarlayabilmektedir

Ancak bu değer `_submit()` içinde kullanılmamaktadır. Switch işlevsel görünmekte, gerçekte hiçbir şeyi kaydetmemektedir.

### 5.3 Mevcut Durumda Abone Olma Yolu Var mı?

Kod tabanı genelinde `is_subscribed_email` alanına `true` yazan herhangi bir kod bulunamamıştır:

- `legal_acceptance_page.dart` → yok (kanıtlandı)
- `notification_preferences_page.dart` → yok (kanıtlandı)
- `follow_repository.dart` → kullanıcı-kullanıcı takip sistemi, `business_follows.is_subscribed_email` ile ilgisi yok
- Mobil uygulama içinde başka bir `is_subscribed_email` referansı bulunamadı

**Anlam:** Ya (a) hiç kimse mobil uygulama aracılığıyla pazarlama e-postasına abone olamamaktadır — opt-in mekanizması ölü bir switch'tir — ya da (b) abonelik başka bir kanaldan (örneğin web, doğrudan DB operasyonu) gerçekleşmektedir ve bu kanalın kodu incelenmemiştir. Mevcut bulgulara göre (a) senaryosu doğrudur.

### 5.4 6563 Sayılı Kanun Kapsamındaki Hukuki Pozisyon

**6563 sayılı Elektronik Ticaretin Düzenlenmesi Hakkında Kanun ve Ticari İletişim Yönetmeliği:**  
Ticari elektronik ileti göndermeden önce alıcının açık onayı alınmalıdır. Onay elde etme ve saklama yükümlülüğü gönderene aittir. Onay, ispatlanabilir şekilde kayıt altında tutulmalıdır.

**Sorun 1:** `is_subscribed_email = true` olarak kayıtlı kullanıcı yoksa ya da bu kayıt nasıl oluşturuldu belirsizse, kampanya gönderilebilecek yasal bir kitle yoktur demektir.

**Sorun 2:** UI'de onay verilmiş gibi görünse de bu onay veritabanına kaydedilmediğinden ispat edilemez. Kullanıcı "ben onay vermedim" derse karşı delil bulunmamaktadır.

**Sorun 3:** `notification_preferences_page.dart`'taki e-posta bildirimleri toggle'ı da kalıcı hale getirilmemektedir. Kullanıcı tercihleri oturum sonrasında kaybolmaktadır.

### 5.5 Minimum Düzeltme Planı

**`legal_acceptance_page.dart` düzeltmesi (zorunlu):**

`_submit()` metoduna `_marketingOptIn` değerini işleyen kod eklenmeli. Bu, `business_follows` tablosunda söz konusu işletmenin takip edilmesini ve `is_subscribed_email` değerinin güncellenmesini gerektirmektedir. Ancak bu noktada mimari bir soru ortaya çıkmaktadır: kabul ekranı işletme bağlamından bağımsızdır, dolayısıyla hangi işletmeye ait `business_follows` kaydının güncelleneceği belirsizdir.

**`follow_repository.dart` düzeltmesi (zorunlu):**  
Kullanıcı bir işletmeyi takip ettiğinde email onayını yönetecek bir yol açılmalıdır. En sağlıklı tasarım: takip akışına ayrı bir `is_subscribed_email` güncelleme adımı veya işletme profil sayfasında bir abonelik toggle'ı eklemektir.

**`notification_preferences_page.dart` düzeltmesi (zorunlu):**  
Sayfa, tercihleri veritabanına kaydetmeden göstermektedir. Kaydedilmeyen tercihler yasal ispat değeri taşımaz.

**Bir RPC gereklidir:**  
`update_business_follow_email_subscription_v1(p_business_id uuid, p_subscribed boolean)` — veya mevcut bir follow RPC'ye parametre eklenmesi.

### 5.6 UI Mikro Metin Önerileri

Bunlar nihai hukuki metinler değildir; düzeltme yapıldıktan sonra kullanılabilecek taslak yönlendirmelerdir.

**`legal_acceptance_page.dart` → marketing switch label'ı için taslak:**

> "Takip ettiğim işletmelerden kampanya ve özel teklif e-postaları almak istiyorum."

**`legal_acceptance_page.dart` → marketing switch subtitle'ı için taslak:**

> "Bu tercihi daha sonra Bildirim Ayarları'ndan değiştirebilirsiniz."

**İşletme profili / takip akışı için abonelik toggle taslağı:**

> "Bu işletmeden e-posta kampanyaları al"  
> "Kampanya göndermeden önce yalnızca e-posta izni veren takipçilere ulaşılır."

**Abonelik iptali footer metni (e-postada) — mevcut edge function:**

Mevcut kod şunu içermektedir: `aboneliğinizi iptal edebilirsiniz`. Bu yeterlidir; ancak unsubscribe bağlantısının gerçekten `is_subscribed_email = false` yazan bir route'a yönlendirdiği doğrulanmalıdır.

### 5.7 Teknik Görev Listesi (R-5)

- [ ] `update_business_follow_email_subscription_v1` RPC'si oluşturulur (`p_business_id uuid`, `p_subscribed boolean`, auth.uid() doğrulaması ile)
- [ ] `legal_acceptance_page.dart`'ın `_submit()` metodu, `_marketingOptIn` değerini yeni RPC'ye ileterek kaydeder (ancak bu ancak kullanıcının belirli işletmeleri takip etmesi bağlamında anlamlıdır — mimari sorusu çözülmeli)
- [ ] İşletme takip akışına e-posta abonelik onayı seçeneği eklenir (önerilen tasarım: takip sırasında veya sonrasında ayrı bir toggle)
- [ ] `notification_preferences_page.dart`'taki `_emailNotifs` toggle'ı kalıcı hale getirilir (Supabase write veya SharedPreferences — yöntem kararlaştırılmalı)
- [ ] E-postadaki unsubscribe bağlantısının (`/settings/notifications`) `is_subscribed_email = false` yazan bir API endpoint'ine yönlendirdiği doğrulanır
- [ ] Onay kayıtları (`is_subscribed_email = true` olan `business_follows` satırları) ne zaman ve nasıl oluşturulduğuna dair audit log mekanizması değerlendirilir (KVKK ispat yükümlülüğü)
- [ ] Tüm düzeltmeler tamamlandıktan sonra hukuk danışmanı opt-in akışını onaylar

---

## Karşılaştırmalı Risk Tablosu

| Risk | Hukuki dayanak | Mevcut durum | Düzeltme tipi |
|---|---|---|---|
| R-4: IP sessiz kaydı | KVKK md. 10 (aydınlatma) | İhlal — kullanıcı bilgilendirilmiyor | A: Önce kod (tetikleyici kaldır veya aydınlatma ekle) |
| R-5: Marketing opt-in kayıt edilmiyor | 6563 md. 6 (onay ispat yükümlülüğü) | İhlal — onay alınıyor ancak saklanmıyor | A: Önce kod (RPC + UI bağlantısı) |

---

## Nihai Öneri: A — Her İki Risk İçin de Önce Kod Değişikliği Gerekir

**R-4 için:** IP kaydının devam etmesine karar verilmesi halinde, gizlilik politikası yazılmadan önce UI'ye aydınlatma metni eklenmeli ve politikada IP saklama süresi ile amacı tanımlanmalıdır. Tetikleyicinin kaldırılması daha temiz bir çözümdür ve tavsiye edilir.

**R-5 için:** Opt-in toggle'ı veritabanıyla bağlantılı olmadan gizlilik politikasına "kullanıcılar pazarlama e-postası için ayrıca onay verir" yazmak teknik olarak yanlış ve potansiyel olarak yanıltıcıdır. Önce `_submit()` düzeltilmeli, RPC yazılmalı, unsubscribe akışı doğrulanmalı; ancak bundan sonra hukuki metinler bu akışı tanımlayabilir.

**Tavsiye edilen sıra:**

1. R-4 kararı: tetikleyiciyi kaldır veya koru (hukuk/ürün ortak kararı, 1 hafta)
2. R-5 Flutter düzeltmesi: `_submit()` + RPC + unsubscribe doğrulaması (1-2 hafta geliştirme)
3. Gizlilik Politikası ve KVKK Aydınlatma Metni yazımı başlar (kod temiz olduktan sonra)

**Hiçbir final hukuki metin, bu teknik düzeltmeler tamamlanmadan yayınlanmamalıdır.**

---

*Bu rapor `docs/arsiv/legal-preflight-report.md` ile birlikte okunmalıdır. Referans dosyalar: `supabase/migrations/20260414000010_fix_capture_request_metadata_trigger.sql`, `supabase/migrations/20260424000009_email_campaigns.sql`, `uygulamalar/mobil/lib/features/legal/ui/legal_acceptance_page.dart`, `uygulamalar/mobil/lib/features/notifications/ui/notification_preferences_page.dart`.*
