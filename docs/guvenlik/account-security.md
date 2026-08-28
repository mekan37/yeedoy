# Hesap Güvenliği / 2FA — Kanonik Belge

Tarih: 2026-06-08 (birleştirildi)
Birleştirilen kaynaklar: `account-security-2fa-plan.md` (2026-06-06), `account-security-aal2-middleware-plan.md` (2026-06-06), `account-security-2fa-test-plan.md` (2026-06-06) — üçü de bu dosyaya taşındı ve silindi.

Bu belge TOTP tabanlı 2FA'nın MVP planını, AAL2 middleware rollout stratejisini ve test altyapısını tek bir kanonik kaynakta toplar.

---

## 1. Mevcut Durum

- **Hesap güvenliği sayfası (aktif):** `uygulamalar/web/app/(kimlik)/profil/security/page.tsx`
- **2FA bileşeni (aktif):** `uygulamalar/web/app/(kimlik)/profil/security/iki-faktor-ayar.tsx`
- **Şifre sıfırlama:** Çalışıyor — `/sifremi-unuttum` → `supabase.auth.resetPasswordForEmail()` → `/sifre-sifirlama` redirect
- **Supabase JS client:** `@supabase/supabase-js ^2.57.4` + `@supabase/ssr ^0.5.2` — TOTP MFA API'lerinin tamamını destekliyor
- **Eski ingilizce route (`(auth)/profile/security`):** stub cleanup tamamlandı, `/profil/security`'e redirect eklendi (PR 2)

`iki-faktor-ayar.tsx` bileşeni şunları içerir: `enroll()` (QR + secret ile TOTP kayıt), `challenge()`, `verify()` (6 haneli kod doğrulama), `unenroll()`, `listFactors()` (server component'te mevcut faktör kontrolü). UI state makinesi (`idle → loading → enroll → verifying → done → unenrolling`) tam implement edilmiş durumda.

```
not_enabled
  └─ "2FA Kurulumunu Başlat" → loading
      └─ enroll başarılı → enroll (QR + kod input)
          ├─ verify başarılı → done (= enabled)
          └─ verify hatalı → enroll (retry, hata mesajı)
          └─ iptal → not_enabled

enabled
  └─ "2FA'yı Kapat" → unenrolling
      ├─ kod doğrulama (PR 3 ile eklendi) → unenroll → not_enabled
      └─ iptal → enabled
```

### Supabase MFA API'leri

| Metot | Amaç |
|---|---|
| `supabase.auth.mfa.enroll()` | Faktör kayıt — QR ve secret döner |
| `supabase.auth.mfa.challenge()` | Challenge başlat — challengeId döner |
| `supabase.auth.mfa.verify()` | Kod doğrula — session AAL2'ye yükselir |
| `supabase.auth.mfa.unenroll()` | Faktörü sil |
| `supabase.auth.mfa.listFactors()` | Kayıtlı faktörleri listele |
| `supabase.auth.mfa.getAuthenticatorAssuranceLevel()` | Mevcut AAL seviyesini sorgula |

### Neden SMS 2FA Değil?

- SMS provider sözleşmesi (KVKK/IYS) yok — bkz. `docs/bildirim-teslimati/delivery-integration-status.md` (SMS bölümü)
- SMS maliyet ve delivery güvenilirliği riski (Türkiye operatör filtreleri)
- TOTP daha güvenli (phishing-resistant) ve provider-bağımsız

---

## 2. Tespit Edilen Boşluklar — Durum (PR #83 audit'inden)

| # | Boşluk | Çözüm | Durum |
|---|---|---|---|
| 1 | Eski route `(auth)/profile/security` hâlâ "Yakında" stub'ı gösteriyordu | `/profile/security` → `/profil/security` redirect eklendi | ✅ Tamamlandı (PR 2) |
| 2 | `unenroll()` doğrudan çağrılıyor, kod doğrulaması yok | `TwoFactorDisableForm` ile mevcut TOTP kodu zorunlu kılındı | ✅ Tamamlandı (PR 3 / PR #84) |
| 3 | Middleware'de `getAuthenticatorAssuranceLevel()` / AAL2 kontrolü yok | AAL2 rollout planı yazıldı (bkz. §3); kod henüz yazılmadı (Faz 2 bekliyor) | 🟡 Plan hazır, uygulama bekliyor |
| 4 | Recovery / kurtarma yolu tanımsız | Seçenek A (recovery code yok, destek akışı) MVP kararı olarak benimsendi (bkz. §4) | ✅ Karar verildi, UI uyarısı eklendi |
| 5 | Disable akışı kod doğrulaması yapmıyor | #2 ile aynı kapsamda çözüldü | ✅ Tamamlandı (PR 3 / PR #84) |

### Disable Akışı (çözüldü — PR 3)

1. Kullanıcı "2FA'yı Kapat" butonuna tıklar
2. Mevcut TOTP kodu istenir (`challenge()` + `verify()`)
3. Doğrulama başarılı → `unenroll()`

---

## 3. AAL2 Middleware Rollout Planı

### AAL/AMR Kavramları

| currentLevel | nextLevel | Anlamı |
|---|---|---|
| `aal1` | `aal1` | Kullanıcının 2FA'sı yok |
| `aal1` | `aal2` | 2FA etkin ama bu session TOTP doğrulanmamış |
| `aal2` | `aal2` | Bu session TOTP doğrulandı — tam güvenli |

**AMR (Authentication Methods References):** Supabase JWT içinde `amr` claim olarak saklanır. Middleware'de JWT'yi network çağrısız decode ederek AAL seviyesi okunabilir (Faz 2 optimizasyonu — bkz. §3.6).

### 3.1 Mevcut Middleware Analizi (`middleware.ts`)

**Mevcut koruma katmanları:**
- `guardPanelRoute()` — `/owner`, `/admin` (ve TR alias'ları `/sahip`, `/yonetici`) için `auth.getUser()` + rol kontrolü
- `normalizePublicRoute()` — subdomain panel rewrite: `isletme.yeedoy.com` → `/owner`, `ops.yeedoy.com` → `/admin`
- Rate limit: `/api/track`, `/api/media/upload`, `/sunucu/sunum-ayarlari`, `/auth/panel-handoff`, `/qr/*`

**Middleware'in şu anda YAPMADIĞI:** `getAuthenticatorAssuranceLevel()` çağrısı yok — 2FA etkin kullanıcıların AAL2 olmadan panel erişimi mümkün.

### 3.2 Route Sınıflandırması

**1. Public — Auth yok, AAL2 yok:** `/`, `/m/[slug]`, `/b/[slug]`, `/qr/[slug]`, `/giris`, `/kayit`, `/sifremi-unuttum`, `/sifre-sifirlama`, `/yasakli`

> **Önemli:** `/sifremi-unuttum` ve `/sifre-sifirlama` kesinlikle AAL2 gereksinimine sokulmamalı — bu akış sırasında session ya hiç yok ya da AAL1 seviyesinde; AAL2 zorunluluğu sıfır-erişim döngüsüne yol açar.

**2. Auth-only — AAL1 yeterli (kesinlikle AAL2 olmamalı):** `/profil/security` (**kritik:** kullanıcı 2FA'yı burada kuruyor), `/profil`, `/gelen-kutusu`, `/tat-ikizi`, `/favoriler`, `/katki`, `/akilli-akis`, `/sadakat`, `/ortak-listeler`, `/yemek-gunlugum`

**3. Owner — AAL1 yeterli (soft banner; MVP'de zorunlu değil):** `/owner/*`, `/sahip/*` geneli (dashboard, businesses, menus, analytics, marketing, reviews)

**4. High-risk Owner — AAL2 önerilir (Faz 3, MVP'de zorunlu değil):**

| Route | Risk Sebebi |
|---|---|
| `/owner/settings/domain`, `/sahip/ayarlar/alan-adi` | Özel domain değişikliği — DNS manipülasyonu riski |
| `/owner/team`, `/sahip/ekip` | Ekip üye yönetimi — yetkisiz erişim riski |
| `/owner/settings/financials`, `/sahip/finansal` | Finansal veri ve ödeme bilgileri |
| `/owner/sponsorship`, `/sahip/sponsorluk` | Sponsorluk ödeme akışları |

**5. Admin — AAL1 yeterli (soft banner; Faz 2'de AAL2):** `/admin/*`, `/yonetici/*` geneli (dashboard, businesses, reviews, locations, growth)

**6. High-risk Admin — AAL2 zorunlu (MVP hedefi, Faz 2):**

| Route | Risk Sebebi |
|---|---|
| `/admin/users`, `/yonetici/kullanicilar` | Kullanıcı hesabı manipülasyonu riski |
| `/admin/roles`, `/yonetici/roller` | Rol/yetki değişikliği — yüksek privilege |
| `/admin/b2b-exports`, `/yonetici/b2b-dis-aktarim` | Toplu veri dış aktarımı |
| `/admin/sponsorships*`, `/yonetici/sponsorluklar*` | Finansal işlem onayları |
| `/api/admin/*`, `/sunucu/yonetici/*` | Tüm admin API route'ları |
| `/admin/feature-flags`, `/yonetici/feature-flags` | Sistem davranışı değişikliği |
| `/admin/kvkk-gdpr`, `/yonetici/kvkk-gdpr` | Veri koruma işlemleri |

### 3.3 AAL2 Kesinlikle Olmayacak Route'lar

**`/profil/security` — Enrollment sayfası.** Bu route AAL2 gereksinimine sokulursa: 2FA kurulu değil → `nextLevel === 'aal1'` → AAL2 gerekliyse redirect çıkışı → kullanıcı 2FA'yı kuramaz → sonsuz döngü. `(kimlik)/profil/security` her zaman AAL1 ile erişilebilir olmalı; enrollment sonrası session AAL2'ye yükselir (beklenen davranış).

**`/sifremi-unuttum`, `/sifre-sifirlama`.** Şifre sıfırlama akışı sırasında kullanıcı ya oturum açmamıştır ya da yeni oluşan oturum AAL1'dedir.

### 3.4 Redirect / Challenge Akışı

```
Kullanici high-risk route'a erisir
  └─ Middleware: getUser() kontrol
      └─ user yok → /login?redirect=...
  └─ user var, session AAL1
      └─ nextLevel === 'aal2' (2FA etkin, dogrulanmamis)
          └─ /profil/security?challenge=true redirect (Faz 2: challenge akisi)
      └─ nextLevel === 'aal1' (2FA etkin degil)
          └─ Faz 1: soft banner goster, erisim serbest
          └─ Faz 2+: enrollment zorla (admin) veya banner (owner)
  └─ user var, session AAL2
      └─ Erisim serbest
```

### 3.5 Lockout Riskleri

| # | Risk | Senaryo | Önlem |
|---|---|---|---|
| 1 (KRİTİK) | `/profil/security` kilitleme döngüsü | 2FA enrolledı ama TOTP doğrulanmadı → challenge redirect → kullanıcı challenge'ı `/profil/security`'de yapmak istiyor → AAL2 gereksinimine takılıp kilitleniyor | `/profil/security` AAL2 gereksiniminden her zaman muaf tutulmalı; middleware kodunda path listesi açıkça belirlenmeli |
| 2 | Admin kullanıcı 2FA kurulu değil | Faz 2'de high-risk admin route'larına AAL2 zorunlu yapılırsa 2FA'sı olmayan admin "2FA kurmalısınız" engeline takılır | Faz 1 soft banner zorunlu; Faz 2 açılmadan önce tüm admin kullanıcılarının 2FA'sı olduğu doğrulanmalı (migration checklist) |
| 3 | Session refresh sonrası AAL düşüşü | Token refresh sonrası `currentLevel` bazen `aal1`'e dönebilir → AAL2 gerektiren sayfada sürekli challenge | Faz 2 öncesi Supabase sandbox'ta token refresh + AAL persistence test edilmeli; sonuç test matrisine eklenmeli |
| 4 | 2FA unenroll sonrası session durumu | `aal2` → `aal1` düşüşü anlık olabilir; mevcut yüksek-risk sayfasında 401/redirect döngüsü riski | Unenroll sonrası middleware'in session'ı yeniden okuyup okumadığı Faz 2 öncesi test edilmeli; unenroll akışı tamamlanınca güvenli redirect yapılmalı |

### 3.6 Neden Middleware'de `getAuthenticatorAssuranceLevel()` Pahalı?

Her middleware çağrısında Supabase Auth sunucusuna HTTP request atılır — Edge middleware için kritik bir latency sorunu.

**Çözüm — JWT AMR Claim Okuma:** Supabase JWT içindeki `amr` alanı session'ın doğrulama yöntemlerini içerir; middleware'de network çağrısız okunabilir:

```typescript
// Faz 2 PR'inda implemente edilecek
import { jwtDecode } from 'jwt-decode';

function getAalFromJwt(accessToken: string): 'aal1' | 'aal2' {
  const payload = jwtDecode<{ amr?: Array<{ method: string }> }>(accessToken);
  const hasTotpAmr = payload.amr?.some((m) => m.method === 'totp') ?? false;
  return hasTotpAmr ? 'aal2' : 'aal1';
}
```

Bu yöntem network çağrısız çalışır (Edge uyumlu), JWT imzası Supabase tarafından doğrulanmıştır (güvenli) ve `getAuthenticatorAssuranceLevel()` yerine tercih edilmelidir.

### 3.7 Rollout Stratejisi (Aşamalı)

**Faz 1 — Soft Banner (✅ Tamamlandı, PR #87)**
- Middleware değişikliği yok
- Admin/owner panel layout'larında (`AdminShellClient`, `OwnerShellClient`, `YoneticiKabukIstemcisi`, `SahipKabukIstemcisi`) 2FA etkin değilse `TwoFactorBanner` gösterilir
- Veri kaynağı: `supabase.auth.mfa.listFactors()` → `verified` faktör yoksa banner
- Risk: Sıfır (display-only); Rollback: < 5 dakika (component kaldır)

**Faz 2 — Admin High-Risk AAL2 (Faz 1'den en az 1 hafta sonra)**
- Kapsam: `/admin/users`, `/yonetici/kullanicilar`, `/admin/roles`, `/yonetici/roller`, `/admin/b2b-exports`, `/yonetici/b2b-dis-aktarim`, `/api/admin/*`, `/sunucu/yonetici/*`
- Yöntem: `guardPanelRoute()` içinde admin high-risk path'leri için JWT `amr` claim okuma (bkz. §3.6)
- Ön koşul: Faz 1 banner deploy edilmiş, tüm admin kullanıcılarının 2FA'sı olduğu doğrulanmış
- Risk: ORTA — admin kilitlenme riski var, rollback planı hazır olmalı

**Faz 3 — Owner High-Risk AAL2 (Faz 2'den 2 hafta sonra)**
- Kapsam: `/owner/settings/domain`, `/sahip/ayarlar`, `/owner/team`, `/sahip/ekip`, finansal route'lar
- Risk: ORTA

**Faz 4 — Full AAL2 (opsiyonel, uzun vadeli)**
- Kapsam: Tüm auth-required route'larda AAL2 zorunlu
- Risk: YÜKSEK — Faz 3 sonrası değerlendirilecek, MVP kapsamında değil

### 3.8 Rollback Planı

| Faz | Rollback Yöntemi | Süre |
|---|---|---|
| Faz 1 (banner) | Layout bileşeninden banner kodunu kaldır | < 5 dakika |
| Faz 2 (admin AAL2) | Middleware'deki high-risk path listesini boşalt veya AAL2 kontrolünü devre dışı bırak | < 10 dakika |
| Faz 3 (owner AAL2) | Aynı yöntem | < 10 dakika |
| Hızlı devre dışı | `AAL2_ENABLED=false` env var ile feature flag | Anlık (redeploy gerekmez) |

**Feature flag önerisi:** Middleware'deki AAL2 blokları `process.env.AAL2_ENABLED !== 'false'` şartına bağlanabilir.

### 3.9 Özet: Kritik Kararlar

1. `/profil/security` **hiçbir zaman** AAL2 gereksinimine sokulmayacak
2. Şifre sıfırlama route'ları AAL2'den muaf
3. Admin kullanıcıları Faz 2 açılmadan 2FA kurmak zorunda kalacak (Faz 1 banner ile bilgilendirme)
4. JWT AMR claim okuma network çağrısını eler — Faz 2 PR'inde zorunlu optimizasyon
5. Faz sırası atlanamaz: her faz bir öncekinin tamamlanmasını gerektirir

---

## 4. Recovery Code Kararı

Supabase native recovery code üretmiyor.

- **Seçenek A (MVP — uygulandı):** Recovery code yok. Kullanıcıya açıkça bildirilir: "Authenticator uygulamanı güvenli tut. Erişim kaybı = destek talebi gerekir" (`destek@yeedoy.com`).
- **Seçenek B (gelecek, MVP kapsamı dışı):** Uygulama seviyesinde 8x8 karakter recovery code üret, SHA-256 ile hashle, `user_mfa_recovery_codes` tablosuna yaz; activation sırasında tek seferlik göster ve indir. Ek migration + UI gerektirir.

**Lockout / kurtarma yolu:** Şifre sıfırlama (`/sifremi-unuttum`) tek oturum açma yöntemi. Yanlış kod limiti Supabase server-side rate limit ile korunuyor (istemci tarafı ek kontrol gerekmez). 2FA aktif kullanıcı şifresini sıfırladığında yeni oturumda 2FA challenge tetiklenip tetiklenmediği test edilmesi gereken bir senaryodur (bkz. test matrisi §5).

---

## 5. Test Altyapısı ve Planı

### 5.1 Mevcut Test Altyapısı

**Vitest (unit + bileşen):** runner v4.1.5, ortam jsdom v28, setup `vitest.setup.ts`, konfigürasyon `vitest.config.ts` (bu döngüde `@vitejs/plugin-react` eklendi — önceden `.tsx` dosyaları jsdom'da JSX transform eksikliğinden parse edilemiyordu). Komut: `npm run test:unit`.

İlgili test dosyası: `test/ui/two-factor-banner.test.tsx` — `TwoFactorBanner` bileşeni için **7 test, hepsi geçti**:

| Test | Kapsam |
|---|---|
| hasTwoFactor=false → banner render edilir | Render doğru |
| hasTwoFactor=false → CTA butonu görünür | Buton varlığı |
| hasTwoFactor=false → href=/profil/security | Yönlendirme doğru |
| hasTwoFactor=true → hiçbir şey render edilmez | Null return |
| hasTwoFactor=true → alert role yok | DOM temizliği |
| aria-label=iki-faktor-dogrulama-uyarisi | Erişebilirlik |
| SVG aria-hidden=true | Dekoratif ikon gizleme |

**Playwright (E2E):** runner v1.51.1, Chromium, dizin `e2e/`, komut `npm run test:e2e` (`e2e/public-menu.spec.ts` çalıştırır). Auth gerektiren E2E testler için Supabase test ortamı + test kullanıcısı gerekir — henüz kurulmadı.

### 5.2 Neden Gerçek MFA E2E Zor?

1. TOTP secret üretimi `enroll()` ile aktif auth session gerektirir
2. TOTP kodu üretimi için secret extract + `otplib` gibi bir kütüphane gerekir
3. Supabase MFA test sandbox'ı production davranışıyla birebir aynı değildir
4. Her E2E çalıştırmada canlı Supabase auth endpoint'ine istek gider — yavaş, flaky
5. TOTP kodları 30 saniye geçerlilik nedeniyle race condition riski taşır

En sağlıklı alternatif: mock + unit test seviyesinde güvence, kritik akışlar için manuel checklist.

### 5.3 Manuel Test Listesi

**Soft Banner (PR #87):**
- [ ] 2FA kapalı admin hesabıyla `/yonetici`'ye giriş → banner görünür
- [ ] 2FA kapalı owner hesabıyla `/sahip`'e giriş → banner görünür
- [ ] 2FA açık hesapla giriş → banner görünmez
- [ ] Banner "2FA Aç" butonuna tıkla → `/profil/security` açılır
- [ ] `/profil/security` üzerindeyken banner görülmüyor mu kontrol et (loop yok)
- [ ] `listFactors` API timeout atarsa → panel kırılmaz, banner gizlenir (`hasTwoFactor=true` fallback)

**Unenroll güvenliği (PR #84):**
- [ ] TOTP kodu girmeden "Kaldır" tıkla → unenroll tetiklenmez
- [ ] Yanlış TOTP kodu gir → hata mesajı gösterilir, faktör silinmez
- [ ] Doğru TOTP kodu gir → verify başarılı, unenroll çağrılır
- [ ] Başka kullanıcının `factor_id`'siyle unenroll dene → 403/hata alınır

**2FA Enrollment Akışı:**
- [ ] `/profil/security` açılır (auth gerekli, AAL1 yeterli)
- [ ] "2FA Etkinleştir" → QR kodu görünür
- [ ] QR kod authenticator app ile taranır
- [ ] Doğru TOTP kodu girilir → 2FA aktif
- [ ] Tekrar yükleme → 2FA aktif gösterilir

**AAL2 Enforcement (Faz 2 — henüz uygulanmadı, ön-kontrol listesi):**
- [ ] AAL1 session + 2FA aktif → `/yonetici/kullanicilar` erişimi challenge'a yönlendirir
- [ ] AAL2 session → `/yonetici/kullanicilar` erişimi serbest
- [ ] `/profil/security` AAL2 zorlamadan açılır (muaf)
- [ ] 2FA kapalı kullanıcı → soft banner + erişim serbest (enforcement değil)
- [ ] Token refresh sonrası AAL2 korunuyor mu kontrol et
- [ ] Unenroll sonrası session AAL seviyesi ne oldu kontrol et

### 5.4 Test Matrisi (AAL2 Enforcement Senaryoları)

| Senaryo | Beklenen Davranış |
|---|---|
| Session yok, herhangi bir route | Login redirect |
| Session AAL1, 2FA yok, public route | Serbest erişim |
| Session AAL1, 2FA yok, owner route | Faz 1: banner + erişim |
| Session AAL1, 2FA yok, admin high-risk | Faz 2: enrollment yönlendirmesi |
| Session AAL1, 2FA var ama doğrulanmamış, high-risk | Challenge redirect `/profil/security?challenge=true` |
| Session AAL2, high-risk route | Serbest erişim |
| `/profil/security`, session AAL1, 2FA yok | Serbest erişim (enrollment için) |
| `/profil/security`, session AAL1, 2FA var | Serbest erişim (challenge akışını başlatmalı) |
| `/sifremi-unuttum`, session yok | Serbest erişim |
| Admin kullanıcı, AAL1, 2FA var | Faz 2: challenge redirect |
| Admin kullanıcı, AAL2 | Serbest erişim |
| Token refresh sonrası AAL | AAL2 korunmalı — test gerekiyor |
| Unenroll sonrası session AAL | Faz 2 öncesinde test edilmeli |
| Lockout recovery (şifre sıfırla + 2FA aktif) | 2FA bypass olmamalı, challenge gelmeli |

### 5.5 Otomatik Test Çalıştırma

```bash
npm run test:unit         # Tüm unit testler
npm run test:unit:watch   # Watch modda
npm run test              # Typecheck + lint + unit
npm run test:ci           # Tam CI (build dahil)
npm run test:e2e          # E2E (public menu — auth gerektirmez)
```

### 5.6 Test Önceliği

1. **Tamamlandı:** `TwoFactorBanner` unit testleri (7 test, hızlı/güvenilir, infrastructure riski sıfır)
2. **Faz 2 öncesi:** Unenroll flow ve enrollment akışı manuel doğrulama (§5.3)
3. **Faz 2 sonrası:** AAL2 Playwright smoke (challenge redirect) — Supabase test project konfigürasyonu gerekir
4. **Uzun vade:** MFA mock helper ile gerçek enrollment flow otomatik test (`otplib` + test hesabı)

### 5.7 Bilinen Sınırlamalar

- Gerçek TOTP kodu üretimi için `otplib` veya benzeri bir kütüphane gerekir
- Supabase MFA test ortamı production'dan farklı davranabilir
- Playwright testlerinde canlı auth gerekir — CI'da Supabase test project konfigürasyonu şart
- `vi.mock('next/link')` ile Next.js router tamamen mock edildi — navigasyon davranışı değil, render doğruluğu test edilir
- `hideOnSecurityPage` prop'u `TwoFactorBanner`'da yok — loop önleme layout seviyesinde yönetiliyor (security sayfasının kendi layout'u `bannerSlot` geçmez)

---

## 6. Route ve Bileşen Envanteri

| Dosya | Rol | Durum |
|---|---|---|
| `app/(kimlik)/profil/security/page.tsx` | Server component; user + session + `mfa.listFactors()` | ✅ Tamamlandı |
| `app/(kimlik)/profil/security/iki-faktor-ayar.tsx` | Client component; tüm TOTP akışı | ✅ Tamamlandı |
| `app/(kimlik)/profil/security/oturum-kapat.tsx` | Client; sign out butonu | ✅ Tamamlandı |
| `app/(auth)/profile/security/page.tsx` | Eski İngilizce route | ✅ Redirect ile temizlendi (`/profil/security`'e yönlendirir) |
| `uygulamalar/web/src/ui/bilesenler/two-factor-banner.tsx` | Soft banner bileşeni (Faz 1) | ✅ Tamamlandı (PR #87) |
| `TwoFactorDisableForm` | Unenroll öncesi kod doğrulama | ✅ Tamamlandı (PR 3 / #84) |
| `RecoveryWarningBanner` | "Authenticator app'ini güvende tut" uyarısı | ✅ Tamamlandı (PR 2 kapsamında eklendi) |

---

## 7. Implementation PR Sırası (Kanonik)

| PR | Kapsam | Risk | Durum |
|---|---|---|---|
| PR 1 | Audit + plan belgesi (docs-only) | Sıfır | ✅ Tamamlandı |
| PR 2 | Eski route redirect + `RecoveryWarningBanner` | Düşük | ✅ Tamamlandı |
| PR 3 | `TwoFactorDisableForm` — unenroll TOTP doğrulama eksiği giderildi | Orta | ✅ Tamamlandı (PR #84) |
| PR 4 | Eski stub route'u redirect ile temizlendi (docs-only sonrası) | Düşük | ✅ Tamamlandı |
| PR 5 (Faz 1) | Soft banner — admin/owner layout'unda 2FA uyarısı | Sıfır | ✅ Tamamlandı (PR #87) |
| PR 6 | 2FA test planı + `TwoFactorBanner` unit testleri (7 test) | Sıfır | ✅ Tamamlandı |
| PR 7 | Admin high-risk AAL2 middleware + JWT AMR optimizasyonu | Orta | 🔲 Planlandı |
| PR 8 | Owner high-risk AAL2 middleware | Orta | 🔲 Planlandı |
| PR 9 | E2E / smoke testleri (2FA akışları) | Düşük | 🔲 Planlandı |
| PR 10 | Full AAL2 (opsiyonel, değerlendirme sonrası) | Yüksek | ❓ Belirsiz |

---

## 8. Notlar

- `iki-faktor-ayar.tsx` içinde `phase === 'loading'` kontrolü hem enroll hem verify aşamasında kullanılıyor — gelecekte daha granüler state'e bölünmesi okunabilirliği artırır
- Supabase MFA'nın KVKK kapsamında ek kullanıcı verisi taşımadığını doğrula (TOTP secret Supabase sunucularında saklanır)
- AAL2 enforcement (Faz 2-4) ile ilgili açık iş kalemi `docs/kalan-isler.md` içinde izlenir

---

## İlgili Belgeler

- `docs/kalan-isler.md` — AAL2 Faz 2+ açık iş kalemi
- `docs/bildirim-teslimati/delivery-integration-status.md` — SMS/e-posta/push delivery durumu (SMS 2FA neden tercih edilmedi bağlamı)
- `uygulamalar/web/src/ui/bilesenler/two-factor-banner.tsx` — soft banner bileşeni
- `uygulamalar/web/test/ui/two-factor-banner.test.tsx` — unit testler
- `uygulamalar/web/vitest.config.ts` — test konfigürasyonu
