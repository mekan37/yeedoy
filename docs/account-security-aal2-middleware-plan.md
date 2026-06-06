# AAL2 Middleware Rollout Planı

Tarih: 2026-06-06
Onceki: docs/account-security-2fa-plan.md

---

## Neden Bu PR'da Kod Yazilmadi?

- Middleware'de yanlis AAL2 uygulanirsa admin/owner kullanicilari kilitlenebilir
- `getAuthenticatorAssuranceLevel()` davranisi 2FA etkin olmayan kullanicilarda farklidir
- Rollback plani ve test matrisi once belirlenmeli
- Asamali rollout (soft banner -> admin-only -> full) risk azaltir

---

## Mevcut Middleware Analizi (middleware.ts)

### Mevcut Koruma Katmanlari

`middleware.ts` iki ayri guard fonksiyonu iceriyor:

**`guardPanelRoute()`** — Panel route'lari icin:
- `supabase.auth.getUser()` ile session kontrol eder
- Session yoksa `/login?redirect=...` redirect
- Admin route'lar icin ayrica `supabase.rpc('is_admin')` cagrilir
- Admin olmayan kullaniciya `/forbidden` redirect

**`normalizePublicRoute()`** — Public route normalizasyonu:
- `/m/[slug]` ve `/qr/[slug]` path validasyonu
- `lang` ve `theme` parametre normalizasyonu
- Gecersiz path formatinda 404 HTML yaniti

**Rate limiting** — Seçici route'larda:
- `/api/track` → 60 req/min
- `/api/media/upload` → 20 req/min
- `/api/presentation-settings` → 30 req/min
- `/auth/panel-handoff` → 20 req/min
- `/qr/*` → 20 req/min

### Middleware'in Simdi YAPMADIGИ

`supabase.auth.mfa.getAuthenticatorAssuranceLevel()` hicbir yerde cagrilmiyor. Panel route'lari icin sadece "oturum acik mi?" ve "admin rolü var mi?" kontrolleri yapiliyor. 2FA dogrulama seviyesi (`aal1` vs `aal2`) gecerli middleware'de tamamen gorunmez.

### Subdomain Panel Rewrite Mantigi

```
isletme.yeedoy.com  → /owner/[path]   (OWNER_HOSTNAMES env var)
ops.yeedoy.com      → /admin/[path]   (ADMIN_HOSTNAME env var — gizli)
```

Panel subdomainleri ozel domain lookup'tan once isleniyor; siralamanin bozdugu bir senaryo yok.

---

## Supabase AAL API

```typescript
const { data, error } = await supabase.auth.mfa.getAuthenticatorAssuranceLevel();
// data.currentLevel: 'aal1' | 'aal2'
// data.nextLevel:    'aal1' | 'aal2'
```

| currentLevel | nextLevel | Anlami |
|---|---|---|
| `aal1` | `aal1` | Kullanicinin 2FA'si yok |
| `aal1` | `aal2` | 2FA etkin ama bu session TOTP dogrulanmamis |
| `aal2` | `aal2` | Bu session TOTP dogrulandi — tam guvenli |

**AMR (Authentication Methods References):** Supabase JWT icinde `amr` claim olarak saklanir. Middleware'de JWT'yi network cagrisiz decode ederek AAL seviyesi okunabilir — bu Faz 2 optimizasyonunda kullanilacak.

---

## Route Siniflandirmasi

### 1. Public — Auth yok, AAL2 yok

| Route | Aciklama |
|---|---|
| `/` | Ana sayfa |
| `/m/[slug]` veya `/b/[slug]` | Isletme / public menu sayfasi |
| `/qr/[slug]` | QR kod erisimi |
| `/giris`, `/login` | Giris sayfasi |
| `/kayit`, `/register` | Kayit sayfasi |
| `/sifremi-unuttum`, `/forgot-password` | Sifre sifirlama baslangic |
| `/sifre-sifirlama`, `/reset-password` | Sifre sifirlama tamamlama |
| `/yasakli`, `/forbidden` | Erisim yasagi sayfasi |

**Onemli:** `/sifremi-unuttum` ve `/sifre-sifirlama` route'lari kesinlikle AAL2 gereksinimine sokulmamali. Bu akis sirasinda session ya hic yok ya da AAL1 seviyesinde — AAL2 zorunlulugu sifir-erisim dongusune yol acar.

### 2. Auth-only — AAL1 yeterli (kesinlikle AAL2 olmamali)

| Route | Aciklama | Neden AAL2 olmamali |
|---|---|---|
| `/profil/security` | 2FA enrollment sayfasi | **Kritik:** Kullanici 2FA'yi burada kuruyor; AAL2 gereksinimiyle kilitlenir |
| `/profil` | Profil goruntulemesi | Dusuk risk, AAL2 gereksiz |
| `/gelen-kutusu`, `/inbox` | Bildirim merkezi | Dusuk risk |
| `/tat-ikizi`, `/taste-twin` | Kisisel oneri | Dusuk risk |
| `/favoriler`, `/favorites` | Favoriler listesi | Dusuk risk |
| `/katki`, `/contribute` | Icerik katkisi | Dusuk risk |
| `/akilli-akis`, `/smart-feed` | Kisisel akis | Dusuk risk |
| `/sadakat`, `/loyalty` | Sadakat programi | Dusuk risk |
| `/ortak-listeler`, `/collab-lists` | Kolaboratif listeler | Dusuk risk |
| `/yemek-gunlugum` | Yemek gunlugu | Dusuk risk |

### 3. Owner — AAL1 yeterli (soft banner onerilir, MVP'de zorunlu degil)

| Route Grubu | Durum |
|---|---|
| `/owner/*` | Tum owner panel — genel |
| `/sahip/*` | Turkce alias — genel |
| `/owner/dashboard`, `/sahip/gosterge-panosu` | Genel panel giris |
| `/owner/businesses`, `/sahip/isletmeler` | Isletme listesi |
| `/owner/menus`, `/sahip/menuler` | Menu yonetimi |
| `/owner/analytics`, `/sahip/analitik` | Analitik goruntulemesi |
| `/owner/marketing/*`, `/sahip/pazarlama/*` | Pazarlama araclari |
| `/owner/reviews`, `/sahip/yorumlar` | Yorum yonetimi |

### 4. High-risk Owner — AAL2 onerilir (MVP'de zorunlu degil, Faz 3)

| Route | Risk Sebebi |
|---|---|
| `/owner/settings/domain`, `/sahip/ayarlar/alan-adi` | Ozel domain degisikligi — DNS manipulasyonu riski |
| `/owner/team`, `/sahip/ekip` | Ekip uye yonetimi — yetkisiz erisim riski |
| `/owner/settings/financials`, `/sahip/finansal` | Finansal veri ve odeme bilgileri |
| `/owner/sponsorship`, `/sahip/sponsorluk` | Sponsorluk odeme akislari |

### 5. Admin — AAL1 yeterli (soft banner, Faz 2'de AAL2)

| Route Grubu | Durum |
|---|---|
| `/admin/*`, `/yonetici/*` | Tum admin panel genel erisim |
| `/admin/dashboard`, `/yonetici/gosterge-panosu` | Panel giris |
| `/admin/businesses`, `/yonetici/isletmeler` | Isletme listesi |
| `/admin/reviews`, `/yonetici/yorumlar` | Yorum moderasyon |
| `/admin/locations`, `/yonetici/konumlar` | Konum kalitesi |
| `/admin/growth`, `/yonetici/buyume` | Buyume metrikleri |

### 6. High-risk Admin — AAL2 zorunlu (MVP hedefi, Faz 2)

| Route | Risk Sebebi |
|---|---|
| `/admin/users`, `/yonetici/kullanicilar` | Kullanici hesabi manipulasyonu riski |
| `/admin/roles`, `/yonetici/roller` | Rol/yetki degisikligi — yuksek privilege |
| `/admin/b2b-exports`, `/yonetici/b2b-dis-aktarim` | Toplu veri dis aktarimi |
| `/admin/sponsorships*`, `/yonetici/sponsorluklar*` | Finansal islem onaylari |
| `/api/admin/*` | Tum admin API route'lari |
| `/sunucu/yonetici/*` | Turkce admin API alias |
| `/admin/feature-flags`, `/yonetici/feature-flags` | Sistem davranisi degisikligi |
| `/admin/kvkk-gdpr`, `/yonetici/kvkk-gdpr` | Veri koruma islemleri |

---

## AAL2 Kesinlikle Olmayacak Route'lar

### `/profil/security` — Enrollment sayfasi

Bu route AAL2 gereksinimine sokulursa olusacak senaryo:

```
Kullanici 2FA kurulu degil
→ nextLevel === 'aal1' (2FA yok demek)
→ Eger AAL2 gerekliyse: redirect cikisi
→ Kullanici 2FA'yi kuramaz
→ Sonsuz dongu
```

`(kimlik)/profil/security` her zaman AAL1 ile eriselebilir olmali. Enrollment sonrasi session aal2'ye yukselir — bu beklenen davranis.

### `/sifremi-unuttum`, `/sifre-sifirlama`, `/forgot-password`, `/reset-password`

Sifre sifirlama akisi esnasinda kullanici ya oturum acsik degildir ya da yeni olusan oturum AAL1'dedir. AAL2 zorunlulugu sifir-erisim kilitleme riskini dogurmaz ancak UX'i bozar.

---

## Redirect / Challenge Akisi

```
Kullanici high-risk route'a erisir
  └─ Middleware: getUser() kontrol
      └─ user yok → /login?redirect=...

  └─ user var, session AAL1
      └─ nextLevel === 'aal2' (2FA etkin, dogrulanmamis)
          └─ /profil/security?challenge=true redirect
             (Faz 2 PR'inda bu sayfa challenge akisi balatmali)

      └─ nextLevel === 'aal1' (2FA etkin degil)
          └─ Faz 1: soft banner goster, erisim serbest
          └─ Faz 2+: enrollment zorla (admin icin) veya banner (owner icin)

  └─ user var, session AAL2
      └─ Erisim serbest
```

---

## Lockout Riskleri

### Risk 1 — `/profil/security` Kilitleme Dongusu (KRITIK)

**Senaryo:** AAL2 gereksinimine `/profil/security` dahil edilirse:
- 2FA etkin olmayan kullanici → `nextLevel === 'aal1'` → AAL2 gereksinimine takilmaz (iyi)
- 2FA enrolllandi ama TOTP dogrulanmadi → `nextLevel === 'aal2'`, `currentLevel === 'aal1'` → challenge redirect → kullanici challenge'i nerede yapacak? → `/profil/security`'e gitmek istiyor → AAL2 gereksinimine takiliyor → kilitlendi

**Onlem:** `/profil/security` her zaman AAL2 gereksiniminden muaf tutulacak. Bu middleware kod yazilirken path listesi acikca belirlenmeli.

### Risk 2 — Admin Kullanici 2FA Kurulu Degil

**Senaryo:** Faz 2'de high-risk admin route'larina AAL2 zorunlu yapilirsa:
- Admin kullanicinin 2FA'si yoksa → `nextLevel === 'aal1'` → "2FA kurmalisiniz" uyarisi veya erisim engeli
- Admin `/profil/security` e gidip 2FA kurar → sorun cozulur (enrollment geri dongu yok)

**Onlem:** Faz 1 soft banner zorunlu — Faz 2 acilmadan once tum admin kullanicilarin 2FA'sinin oldugu dogrulanmali. Faz 2 PR'inda migration checklist olmali.

### Risk 3 — Session Refresh Sonrasi AAL Dususu

**Senaryo:** Token refresh sonrasi `currentLevel` bazen `aal1`'e donebilir. Bu durumda AAL2 gerektiren bir sayfaya erisim surekli challenge tetikler.

**Durum:** Supabase'in `aal2` durumunu refresh token boyunca koruyup korumadigi belgelenmemis. Test edilmeli.

**Onlem:** Faz 2 PR oncesinde Supabase sandbox'ta token refresh + aal persistence test senaryosu calistirilmali. Sonuc test matrisine eklenmeli.

### Risk 4 — 2FA Unenroll Sonrasi Session Durumu

**Senaryo:** Kullanici 2FA'yi kaldirinca mevcut session'in AAL seviyesi ne olur? Supabase dokumantasyonu net degil.

**Durum:** `aal2` → `aal1` dususu anliktir ve mevcut yuksek-risk sayfasinda 401/redirect dongusune girebilir.

**Onlem:** Unenroll sonrasi middleware'in session'i yeniden okuyup okumadigi ve nasil davrandigi Faz 2 oncesinde test edilmeli. Unenroll akisi tamamlaninca kullaniciyi guvenli bir redirect'e yonlendirmeli.

---

## Rollout Stratejisi (Asamali)

### Faz 1 — Soft Banner (bu plan sonrasindaki ilk PR)

- **Middleware degisikligi:** Yok
- **Ne yapilir:** Admin ve owner panel layout bilesenlerinde (`AdminShellClient`, `OwnerShellClient`, `YoneticiKabukIstemcisi`, `SahipKabukIstemcisi`) 2FA etkin degilse bilgi banner'i goster
- **Veri kaynagi:** Layout'ta `supabase.auth.mfa.listFactors()` → `verified` faktor yoksa banner
- **Mesaj:** "Hesabinizi korumak icin iki faktörlü dogrulama aktif degildir. Simdi kurun."
- **Risk:** Sifir — display-only, hic bir auth davranisi degismez
- **Rollback:** Component'i kaldir

### Faz 2 — Admin High-Risk AAL2 (Faz 1'den en az 1 hafta sonra)

- **Kapsam:** Sadece `/admin/users`, `/yonetici/kullanicilar`, `/admin/roles`, `/yonetici/roller`, `/admin/b2b-exports`, `/yonetici/b2b-dis-aktarim`, `/api/admin/*`, `/sunucu/yonetici/*`
- **Yontem:** `guardPanelRoute()` icinde admin high-risk path'leri icin `getAuthenticatorAssuranceLevel()` cagrilir
- **Optimizasyon:** JWT'den `amr` claim okuyarak network cagrisiz AAL tespiti (edge middleware icin kritik latency optimizasyonu)
- **Onkosul:** Faz 1 banner deploy edilmis, tum admin kullanicilarin 2FA'si oldugu dogrulanmis
- **Risk:** ORTA — admin kilitlenme riski var, rollback plan hazir

### Faz 3 — Owner High-Risk AAL2 (Faz 2'den 2 hafta sonra)

- **Kapsam:** `/owner/settings/domain`, `/sahip/ayarlar`, `/owner/team`, `/sahip/ekip`, finansal route'lar
- **Risk:** ORTA

### Faz 4 — Full AAL2 (Opsiyonel, uzun vadeli degerlendirme)

- **Kapsam:** Tum auth-required route'larda AAL2 zorunlu
- **Risk:** YUKSEK — production'da dikkatli test, kademeli rollout
- **Not:** Faz 3 sonrasinda degerlendirilecek; MVP kapsaminda degil

---

## Test Matrisi

| Senaryo | Beklenen Davranis |
|---|---|
| Session yok, herhangi bir route | Login redirect |
| Session AAL1, 2FA yok, public route | Serbest erisim |
| Session AAL1, 2FA yok, owner route | Faz 1: banner + erisim |
| Session AAL1, 2FA yok, admin high-risk | Faz 2: enrollment yonlendirmesi |
| Session AAL1, 2FA var ama dogrulanmamis, high-risk | Challenge redirect `/profil/security?challenge=true` |
| Session AAL2, high-risk route | Serbest erisim |
| `/profil/security`, session AAL1, 2FA yok | Serbest erisim (enrollment icin) |
| `/profil/security`, session AAL1, 2FA var | Serbest erisim (challenge akisini baslatmali) |
| `/sifremi-unuttum`, session yok | Serbest erisim |
| Admin kullanici, AAL1, 2FA var | Faz 2: challenge redirect |
| Admin kullanici, AAL2 | Serbest erisim |
| Token refresh sonrasi AAL | AAL2 korunmali — test gerekiyor |
| Unenroll sonrasi session AAL | Faz 2 oncesinde test edilmeli |
| Lockout recovery (sifre sifirla + 2FA aktif) | 2FA bypass olmamali, challenge gelmeli |

---

## Implementation PR Sirasi

| PR | Kapsam | Risk | Durum |
|---|---|---|---|
| PR 1 | Audit + plan belgesi (docs-only) | Sifir | Tamamlandi |
| PR 2 | Unenroll TOTP dogrulama eksigi giderildi | Orta | Tamamlandi |
| PR 3 | Eski stub route'u redirect ile temizlendi | Dusuk | Tamamlandi |
| PR 4 | AAL2 middleware rollout plani (docs-only) | Sifir | Tamamlandi |
| **PR 5 (Faz 1) ✅** | **Soft banner — admin/owner layout'unda 2FA uyarisi** | **Sifir** | **Tamamlandi (PR #87)** |
| PR 6 | Admin high-risk AAL2 middleware + JWT AMR optimizasyonu | Orta | Planlandi |
| PR 7 | Owner high-risk AAL2 middleware | Orta | Planlandi |
| PR 8 | E2E / smoke testleri (2FA akislari) | Dusuk | Planlandi |
| PR 9 | Full AAL2 (opsiyonel, degerlendirme sonrasi) | Yuksek | Belirsiz |

---

## Neden Middleware'de `getAuthenticatorAssuranceLevel()` Pahali?

Her middleware cagrisinda Supabase Auth sunucusuna HTTP request atilir. Edge middleware icin bu kritik bir latency sorunudur.

**Cozum — JWT AMR Claim Okuma:**

Supabase JWT icindeki `amr` (Authentication Methods References) alani session'in dogrulama yontemlerini icerir. Bu claim middleware'de network cagrisiz okunabilir:

```typescript
// Ornek yaklasim (Faz 2 PR'inda implemente edilecek)
import { jwtDecode } from 'jwt-decode';

function getAalFromJwt(accessToken: string): 'aal1' | 'aal2' {
  const payload = jwtDecode<{ amr?: Array<{ method: string }> }>(accessToken);
  const hasTotpAmr = payload.amr?.some((m) => m.method === 'totp') ?? false;
  return hasTotpAmr ? 'aal2' : 'aal1';
}
```

Bu yontem:
- Network cagrisiz calisir (Edge uyumlu)
- JWT imzasi Supabase tarafindan dogrulanmis — guvenli
- `getAuthenticatorAssuranceLevel()` yerine tercih edilmeli

---

## Rollback Plani

| Faz | Rollback Yontemi | Sure |
|---|---|---|
| Faz 1 (banner) | Layout bileseninden banner kodunu kaldir | < 5 dakika |
| Faz 2 (admin AAL2) | Middleware'deki high-risk path listesini bosalt veya AAL2 check'i devre disi biraK | < 10 dakika |
| Faz 3 (owner AAL2) | Ayni yontem | < 10 dakika |
| Hizli devre disi | `NEXT_PUBLIC_AAL2_ENABLED=false` env var ile feature flag eklenebilir | Anlık |

**Feature flag onerisi:** Middleware'deki AAL2 bloklari `process.env.AAL2_ENABLED !== 'false'` sartina baglanabilir. Bu olmadan bile Vercel'de environment variable ile anlik rollback mumkun (redeploy gerekmez, runtime env var degisikligi yeterli).

---

## Ozet: Kritik Kararlar

1. `/profil/security` **hicbir zaman** AAL2 gereksinimine sokulmayacak
2. Sifre sifirlama route'lari AAL2'den muaf
3. Admin kullanicilari Faz 2 acilmadan 2FA kurmak zorunda kalacak (Faz 1 banner ile bilgilendirilecek)
4. JWT AMR claim okuma network cagrisini elimine eder — Faz 2 PR'inda zorunlu optimizasyon
5. Faz sirasi atlanamaz: her faz bir oncekinin tamamlanmasini gerektirir
