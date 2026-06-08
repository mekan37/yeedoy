# 2FA Test Planı

Tarih: 2026-06-06
Onceki: docs/account-security-aal2-middleware-plan.md
Kapsam: PR #83-#87 degisiklikleri + AAL2 enforcement oncesi test tabani

---

## Mevcut Test Altyapisi

### Vitest (Unit + Bilesен Testleri)

- Runner: vitest v4.1.5
- Ortam: jsdom (v28)
- Setup: `vitest.setup.ts` — @testing-library/jest-dom/vitest
- Konfigürasyon: `vitest.config.ts` (plugin-react eklendi bu PR'da)
- Test dizini: `test/` (kok duzeyinde)
- Komut: `npm run test:unit`

Mevcut test dosyalari:
- `test/lib/isletme-yolu.test.ts` — slug/UUID path dogrulama
- `test/lib/menu-baglantilari.test.ts` — menu href insa
- `test/lib/menu-metinleri.test.ts` — menu metin formlari
- `test/lib/kisa-kod.test.ts` — kisa kod normalizasyon
- `test/lib/business-path.test.ts` — EN alias
- `test/lib/menu-links.test.ts` — EN alias
- `test/lib/menu-text.test.ts` — EN alias
- `test/lib/short-code.test.ts` — EN alias
- `test/ui/two-factor-banner.test.tsx` — TwoFactorBanner bileseni (bu PR'da eklendi)

Bu PR'da eklenen degisiklik: `vitest.config.ts` icine `@vitejs/plugin-react` eklendi. Onceden `.tsx` dosyalari jsdom ortaminda parse edilemiyordu (JSX transform eksikti). Plugin eklenmesiyle UI bileseni testleri artik mumkun.

### Playwright (E2E)

- Runner: Playwright v1.51.1
- Browser: Chromium
- Test dizini: `e2e/`
- Komut: `npm run test:e2e` (sadece `e2e/public-menu.spec.ts` calistirir)

Mevcut E2E dosyalari:
- `e2e/public-menu.spec.ts` — acik menu, QR, giris sayfasi yonlendirme testleri
- `e2e/acik-menu.spec.ts` — TR alias
- `e2e/acik-menu-canli.spec.ts` — canli ortam E2E
- `e2e/karanlik-mod.spec.ts` — karanlik mod gorunurlugu
- `e2e/sahip-write-smoke.spec.ts` — owner yazma smoke
- `e2e/kullanici-yolculuklari.spec.ts` — kullanici akim testleri
- `e2e/public-menu-live.spec.ts` — canli menu

Auth gerektiren E2E testler: Tum E2E testleri Next.js dev/prod sunucusuna baglaniyor. Auth gerektiren sayfalari test etmek icin Supabase test ortami + test kullanicisi gerekmekte.

---

## Neden Gercek MFA E2E Zor?

1. **TOTP secret uretimi:** `supabase.auth.mfa.enroll()` cagrilmali — aktif auth session gerekir
2. **TOTP kodu uretimi:** QR URL icinden secret extract edilmeli, `otplib` gibi kutuphane gerekir
3. **Test ortami garantisi:** Supabase MFA test sandbox production davranisiyla birebir ayni degil
4. **Dis bagimlilik:** Her E2E calistirmada canli Supabase auth endpoint'e istek gider — yavas, flaky
5. **Zaman hassasiyeti:** TOTP kodlari 30 saniye gecerliligi nedeniyle race condition riski tasir

En saglikli alternatif: mock + unit test seviyesinde guvence, kritik akislar icin manuel checklist.

---

## Test Kapsami

### Otomatik (Bu PR ile Eklendi)

#### Unit — TwoFactorBanner (`test/ui/two-factor-banner.test.tsx`)

| Test | Kapsam | Durum |
|---|---|---|
| hasTwoFactor=false → banner render edilir | Render dogru | Gecti |
| hasTwoFactor=false → CTA butonu gorunur | Buton varligi | Gecti |
| hasTwoFactor=false → href=/profil/security | Yonlendirme dogru | Gecti |
| hasTwoFactor=true → hicbir sey render edilmez | Null return | Gecti |
| hasTwoFactor=true → alert role yok | DOM temizligi | Gecti |
| aria-label=iki-faktor-dogrulama-uyarisi | Erisebilirlik | Gecti |
| SVG aria-hidden=true | Dekoratif ikon gizleme | Gecti |

Toplam: 7 test, hepsi gecti.

#### Mevcut Unit Testler (Degistirilmedi)

24 test gecmekte — slug, href, metin normalizasyon katmanlari.

---

### Manuel Test Listesi

#### Soft Banner (PR #87)

- [ ] 2FA kapali admin hesabiyla /yonetici'ye giris yap → banner gorunur
- [ ] 2FA kapali owner hesabiyla /sahip'e giris yap → banner gorunur
- [ ] 2FA acik hesapla giris → banner gorunmez
- [ ] Banner "2FA Ac" butonuna tikla → /profil/security acilir
- [ ] /profil/security uzerindeyken banner gorulmuyor mu kontrol et (loop yok)
- [ ] MFA listFactors API timeout atar ise (DevTools → Network throttle) → panel kirilmaz, banner gizlenir (hasTwoFactor=true fallback)

#### Unenroll Guvenligi (PR #84)

- [ ] TOTP kodu girmeden "Kaldir" tikla → unenroll tetiklenmez
- [ ] Yanlis TOTP kodu gir → hata mesaji gosterilir, factor silinmez
- [ ] Dogru TOTP kodu gir → verify basarili, unenroll cagirilir
- [ ] Baska kullanicinin factor_id'siyle unenroll dene → 403/hata alindi

#### 2FA Enrollment Akisi

- [ ] /profil/security acilir (auth gerekli, AAL1 yeterli)
- [ ] "2FA Etkinlestir" → QR kodu gorunur
- [ ] QR kod authenticator app ile taranir
- [ ] Dogru TOTP kodu girilir → 2FA aktif
- [ ] Tekrar yukleme → 2FA aktif gosterilir

#### AAL2 Enforcement (Faz 2 — henuz uygulanmadi, on-check)

- [ ] AAL1 session + 2FA aktif → /yonetici/kullanicilar erisimi challenge'a yonlendirir
- [ ] AAL2 session → /yonetici/kullanicilar erisimi serbest
- [ ] /profil/security AAL2 zorlamadan acilir (muaf)
- [ ] 2FA kapali kullanici → soft banner + erisim serbest (enforcement degil)
- [ ] Token refresh sonrasi AAL2 korunuyor mu kontrol et
- [ ] Unenroll sonrasi session AAL seviyesi ne oldu kontrol et

---

## Otomatik Test Calistirma

```bash
# Tum unit testler
npm run test:unit

# Watch modda
npm run test:unit:watch

# Typecheck + lint + unit
npm run test

# Tam CI (build dahil)
npm run test:ci

# E2E (public menu — auth gerektirmez)
npm run test:e2e
```

---

## Oneri: Test Onceligi

1. **Simdi (bu PR):** TwoFactorBanner unit testleri → hizli, guvenilir, infrastructure riski sifir
2. **Faz 2 oncesi:** Unenroll flow ve enrollment akisi manuel dogrulama (yukaridaki checklist)
3. **Faz 2 sonrasi:** AAL2 Playwright smoke (challenge redirect) — Supabase test project konfigurasyon gerekir
4. **Uzun vade:** MFA mock helper ile gercek enrollment flow otomatik test (`otplib` + test hesabi)

---

## Bilinen Sinirlamalar

- Gercek TOTP kodu uretimi icin `otplib` veya benzeri kutuphane gerekir
- Supabase MFA test ortami production ile farkli davranabilir
- Playwright testlerinde canli auth gerektirir — CI'da Supabase test project konfigurasyonu sart
- `vi.mock('next/link')` ile Next.js router tamamen mock edildi — navigasyon davranisi test edilmez, render dogru test edilir
- `hideOnSecurityPage` prop'u `TwoFactorBanner`'da mevcut degil — loop onleme layout seviyesinde yonetiliyor (bannerSlot layout'tan gelir, security sayfasinin kendi layout'u bannerSlot gecmez)

---

## Ilgili Belgeler

- `docs/account-security-2fa-plan.md` — ilk audit + plan
- `docs/account-security-aal2-middleware-plan.md` — AAL2 rollout plani (Faz 1-4 detaylari)
- `uygulamalar/web/src/ui/bilesenler/two-factor-banner.tsx` — test edilen bilesеn
- `uygulamalar/web/test/ui/two-factor-banner.test.tsx` — unit testler
- `uygulamalar/web/vitest.config.ts` — test konfigurasyonu
