# Hesap Güvenliği / 2FA — MVP Planı

Tarih: 2026-06-06

---

## AAL2 Middleware Plani

> **Guncel:** AAL2 middleware rollout plani hazir — bkz. `docs/account-security-aal2-middleware-plan.md`
> Route kapsami, lockout riskleri, asamali rollout stratejisi ve test matrisi o belgede detaylandirilmistir.

---

## Mevcut Durum

- **Hesap güvenliği sayfası (aktif):** `uygulamalar/web/app/(kimlik)/profil/security/page.tsx`
- **2FA bileşeni (aktif):** `uygulamalar/web/app/(kimlik)/profil/security/iki-faktor-ayar.tsx`
- **Hesap güvenliği sayfası (eski, ingilizce route):** `uygulamalar/web/app/(auth)/profile/security/page.tsx`
- **2FA stub (eski route):** `(auth)/profile/security/page.tsx` — `İki Faktörlü Doğrulama` başlığı altında amber `Yakında` badge'i
- **Şifre sıfırlama:** Çalışıyor — `/sifremi-unuttum` → `supabase.auth.resetPasswordForEmail()` → `/sifre-sifirlama` redirect
- **Supabase JS client:** `@supabase/supabase-js ^2.57.4` + `@supabase/ssr ^0.5.2`
- **MFA API desteği:** Mevcut versiyon (`2.x`) tüm TOTP API'lerini destekliyor

---

## Keşif Bulgusu: Aktif Route Zaten Implement Edilmiş

Audit sırasında kritik bir bulgu ortaya çıktı: `(auth)/profile/security` (eski/ingilizce) stub durumdayken, **aktif route olan `(kimlik)/profil/security` tam olarak implement edilmiş durumda.**

`iki-faktor-ayar.tsx` bileşeni şu özellikleri içeriyor:

- `supabase.auth.mfa.enroll()` — QR + secret ile TOTP kayıt
- `supabase.auth.mfa.challenge()` — challenge başlatma
- `supabase.auth.mfa.verify()` — 6 haneli kod doğrulama
- `supabase.auth.mfa.unenroll()` — faktör silme
- `supabase.auth.mfa.listFactors()` — server component'te mevcut faktör kontrolü

UI state makinesi (`idle → loading → enroll → verifying → done → unenrolling`) tam implement edilmiş. QR SVG gösterimi, manuel secret text, numeric-only input, loading/error state'leri mevcut.

**Sonuç:** Aktif route için implementation tamamlanmış; ancak aşağıdaki boşluklar tespit edilmiştir.

---

## Tespit Edilen Boşluklar

### Boşluk 1 — Eski Route Stub Durumda

`app/(auth)/profile/security/page.tsx` hala `Yakında` badge'i gösteriyor. Bu route hala erişilebilir durumdaysa kullanıcı kafa karışıklığı yaratabilir. Çözüm: ya eski route'u aktif route'a redirect et ya da sil.

### Boşluk 2 — Unenroll Doğrulama Eksik

`unenroll()` akışında kullanıcıdan mevcut TOTP kodu istenmeden 2FA doğrudan kaldırılıyor. Hesap ele geçirilmesi senaryosunda saldırgan 2FA'yı kolayca devre dışı bırakabilir. Unenroll öncesinde kod doğrulaması zorunlu olmalı.

### Boşluk 3 — Middleware MFA Seviyesi Kontrolü Yok

`middleware.ts` panel route guard'ları (`/owner`, `/admin`) için `auth.getUser()` ve rol kontrolü yapıyor; ancak `getAuthenticatorAssuranceLevel()` çağrısı yok. 2FA etkin kullanıcıların AAL2 olmadan panel erişimi olası.

### Boşluk 4 — Recovery / Kurtarma Yolu Tanımsız

Authenticator app kaybolduğunda kullanıcı hesabına erişemez. Kurtarma yolu belirsiz — ne kullanıcıya bildirilmiş ne de destek akışı belirlenmiş.

### Boşluk 5 — Disable Akışı Kod Doğrulaması Yapılmıyor

Unenroll tetiklenince Supabase server-side bir challenge gerektirebilir ya da gerektirmeyebilir; bunu client'ta kontrol eden kod yok. Güvenli disable için mevcut kodu verify etmek gerekir.

---

## Supabase MFA Desteği

Supabase Auth TOTP MFA API'si (`@supabase/supabase-js >= 2.x`):

| Metot | Amaç |
|---|---|
| `supabase.auth.mfa.enroll()` | Faktör kayıt — QR ve secret döner |
| `supabase.auth.mfa.challenge()` | Challenge başlat — challengeId döner |
| `supabase.auth.mfa.verify()` | Kod doğrula — session AAL2'ye yükselir |
| `supabase.auth.mfa.unenroll()` | Faktörü sil |
| `supabase.auth.mfa.listFactors()` | Kayıtlı faktörleri listele |
| `supabase.auth.mfa.getAuthenticatorAssuranceLevel()` | Mevcut AAL seviyesini sorgula |

Mevcut client versiyonu (`^2.57.4`) bu API'lerin tamamını destekliyor: **evet**.

---

## Neden SMS 2FA Değil?

- SMS provider sözleşmesi (KVKK/IYS) henüz yok — bu blokerin detayı için bkz. `docs/sms-delivery-integration-plan.md`
- SMS maliyet ve delivery güvenilirliği riski (Türkiye operator filtreleri)
- TOTP daha güvenli (phishing-resistant) ve tamamen provider-bağımsız
- SMS 2FA eklemek için ayrı bir entegrasyon blocker aşılmalı; TOTP için ek altyapı gerekmez

---

## Önerilen Akış: TOTP Authentication

### Enrollment Akışı (zaten implement edilmiş)

1. Kullanıcı `/profil/security` sayfasını açar
2. "2FA Kurulumunu Başlat" butonuna tıklar
3. `supabase.auth.mfa.enroll()` — QR kodu ve secret döner
4. Kullanıcı Google Authenticator / Authy ile QR tarar
5. 6 haneli kod girilir → `challenge()` + `verify()`
6. Başarı: session AAL2 olur, faktör listesinde `status: 'verified'`

### Disable Akışı (boşluk var — PR 3'te düzeltilmeli)

Mevcut: `unenroll()` doğrudan çağrılıyor (doğrulama yok)

Olması gereken:
1. Kullanıcı "2FA'yı Kapat" butonuna tıklar
2. Mevcut TOTP kodu istenir (`challenge()` + `verify()`)
3. Doğrulama başarılı → `unenroll()`

---

## Recovery Code Kararı

Supabase native recovery code üretmiyor. Seçenekler:

**Seçenek A (MVP — uygulandı):** Recovery code yok. Kullanıcıya açıkça bildirilmeli: "Authenticator uygulamanı güvenli tut. Erişim kaybı = destek talebi gerekir." Bu mesaj şu an UI'da eksik.

**Seçenek B (gelecek):** Uygulama seviyesinde 8x8 karakter recovery code üret, SHA-256 ile hashle, `user_mfa_recovery_codes` tablosuna yaz. Activation sırasında tek seferlik göster ve indir. Bu seçenek ek migration + UI gerektirir; MVP kapsamı dışında.

**MVP kararı:** Seçenek A ile devam et. UI'ya "Authenticator uygulamanı güvende tut, erişim kaybında destek@yeedoy.com'a yaz" uyarısı ekle.

---

## Session ve AAL2

- TOTP verify başarılı → Supabase session'ı AAL1'den AAL2'ye yükselir
- Yüksek güvenlikli işlemler için `supabase.auth.mfa.getAuthenticatorAssuranceLevel()` kullanılabilir
- `{ currentLevel: 'aal2', nextLevel: 'aal2' }` → 2FA doğrulandı
- `{ currentLevel: 'aal1', nextLevel: 'aal2' }` → 2FA gerekli ama henüz doğrulanmadı

**Mevcut middleware durumu:** Panel route guard (`/owner`, `/admin`) MFA AAL seviyesi kontrolü yapmıyor. Bu yüksek riskli operasyonlar için opsiyonel bir iyileştirme olarak değerlendirilmeli (PR 4).

---

## Lockout Riski

- Yanlış kod limiti: Supabase server-side rate limit uyguluyor (istemci tarafında ek kontrol gerekmez)
- Recovery yolu: Şifre sıfırlama (`/sifremi-unuttum`) tek oturum açma yöntemi; ancak 2FA aktifken şifre sıfırlama sonrası AAL durumu test edilmedi
- **Test edilmesi gereken senaryo:** 2FA aktif kullanıcı şifresini sıfırlarsa yeni oturumda 2FA challenge tetikleniyor mu?

---

## UI State Makinesi

```
not_enabled
  └─ "2FA Kurulumunu Başlat" → loading
      └─ enroll başarılı → enroll (QR + kod input)
          ├─ verify başarılı → done (= enabled)
          └─ verify hatalı → enroll (retry, hata mesajı)
          └─ iptal → not_enabled

enabled
  └─ "2FA'yı Kapat" → unenrolling
      ├─ [EKSIK] kod doğrulama → unenroll → not_enabled
      └─ iptal → enabled
```

---

## Route ve Bileşen Envanteri

### Mevcut (aktif route)

| Dosya | Rol | Durum |
|---|---|---|
| `app/(kimlik)/profil/security/page.tsx` | Server component; user + session + mfa.listFactors() | Tamamlandı |
| `app/(kimlik)/profil/security/iki-faktor-ayar.tsx` | Client component; tüm TOTP akışı | Tamamlandı (boşluk: disable doğrulama eksik) |
| `app/(kimlik)/profil/security/oturum-kapat.tsx` | Client; sign out butonu | Tamamlandı |

### Eski Route (temizlendi)

| Dosya | Rol | Durum |
|---|---|---|
| `app/(auth)/profile/security/page.tsx` | Eski ingilizce route; "Yakında" badge | Eski stub cleanup tamamlandı — `/profile/security` → `/profil/security` redirect eklendi (bu PR) |

### Henüz Yazılmamış Bileşenler

| Bileşen | Amaç | Hangi PR |
|---|---|---|
| `TwoFactorDisableForm` | Unenroll öncesi kod doğrulama | PR 3 |
| `RecoveryWarningBanner` | "Authenticator app'ini güvende tut" uyarısı | PR 2 |

---

## Test Planı

- [ ] 2FA olmayan kullanıcı enrollment akışını tamamlayabilir
- [ ] QR kodu geçerli bir TOTP uygulamasıyla taranabilir
- [ ] Yanlış kod → hata mesajı (ham Supabase error stringi gösterilmez)
- [ ] Doğru kod → 2FA aktif, `listFactors()` sonucu güncellenir
- [ ] Disable: mevcut kod doğrulama ile kaldırılır (PR 3 sonrası)
- [ ] Disable: yanlış kod → engel (PR 3 sonrası)
- [ ] Middleware: 2FA state mevcut panel route korumalarını bozmaz
- [ ] Session: logout/login sonrası 2FA challenge tetikleniyor mu (AAL1 → AAL2)
- [ ] Şifre sıfırlama + 2FA aktif senaryosu
- [ ] Eski `(auth)/profile/security` route yeni route'a yönlendiriyor mu

---

## Rollback Planı

- TOTP enrollment tamamen client-side; migration gerektirmiyor
- Supabase Dashboard → Authentication → MFA → Disable/Enable ile anında geri alınabilir
- Kod rollback: `IkiFactorAyar` yerine `Yakında` badge'i koy → önceki davranışa dönüş
- Middleware değişikliği en yüksek riskli — PR 4'te ayrı tutuldu

---

## Implementation PR Sırası

| PR | Kapsam | Risk |
|---|---|---|
| **PR 1 (plan)** | Audit + plan belgesi (docs-only) | Sıfır |
| **PR 2 (bu PR)** | Eski route redirect — `/profile/security` → `/profil/security` | Düşük (tamamlandı) |
| **PR 3** | `RecoveryWarningBanner` + disable akışında kod doğrulama (`TwoFactorDisableForm`) | Orta (auth mutation) |
| **PR 4** | Middleware AAL2 kontrolü — panel route guard iyileştirmesi (ayrı PR) | Yüksek (dikkatli test gerekir) |
| **PR 5** | E2E smoke test — enrollment + disable akışı | Düşük |

---

## Notlar

- `(auth)/profile/security` route'unun hala erişilebilir olup olmadığı `(auth)` layout'una bağlı; incelenmeli
- `iki-faktor-ayar.tsx` içinde `phase === 'loading'` kontrolü hem enroll hem verify aşamasında kullanılıyor — gelecekte daha granüler state'e bölünmesi okunabilirliği artırır
- Supabase MFA'nın Türkiye'de KVKK kapsamında kullanıcı verisi içermediğini doğrula (TOTP secret Supabase sunucularında saklanır)
