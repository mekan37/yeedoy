# SMS Delivery Integration Plan

> Status: Route + ownership guard deployed. Phone data, consent, opt-out ve provider entegrasyonu eksik.
> **Last updated:** 2026-06-05

---

## Mevcut Durum

| Bileşen | Konum | Durum |
|---|---|---|
| SMS kampanya route | `app/sunucu/sahip/sms-kampanya/route.ts` | Deployed |
| Ownership guard | `hasOwnerBusiness()` helper | Aktif |
| Rate limit | 3 kampanya/saat/kullanici | Aktif |
| Zod input validation | `schema.safeParse()` | Aktif |
| Gercek SMS gonderimu | `// TODO: integrate with Netgsm/Twilio` | **EKSIK** |
| `sms_campaigns` tablosu | Supabase migration | **EKSIK** — route kullanıyor ama migration yok |
| `is_subscribed_sms` opt-in | `business_follows` veya `user_profiles` | **EKSIK** |
| Kullanici telefon numarasi | `user_profiles.phone` | **EKSIK** |
| Opt-out mekanizmasi | STOP komutu handler | **EKSIK** |
| KVKK riza kaydi | Consent tarih + kaynak | **EKSIK** |

Mevcut route davranisi:
- `business_follows` veya `loyalty_cards`'dan abone sayisini tahmin ediyor
- `sms_campaigns` tablosuna kayit atiyor (tablo migration yok — `supabase as any` ile bypass)
- `is_subscribed_sms` filtresi yok — consent kontrolu yapilmiyor
- Gercek SMS gonderimu yok, `sentCount` sadece kaba tahmin

---

## Kritik Eksikler — Gonderimden Once Zorunlu

| # | Eksik | Risk | Gerekli Aksiyon |
|---|---|---|---|
| 1 | Kullanici telefon numarasi | SMS gondericlecek numara yok | `user_profiles.phone` migration |
| 2 | `is_subscribed_sms` opt-in | KVKK/IYS ihlali riski | `business_follows` migration — consent kolonu ekle |
| 3 | Opt-out mekanizmasi | IYS geregi zorunlu, max 3 is gunu | STOP komutu handler + DB kaydi |
| 4 | `sms_campaigns` migration | Tablo yok, route `as any` ile kaciniyor | Migration yazilmali + RLS eklenmeli |
| 5 | KVKK riza kaydi | Ticari elektronik ileti mevzuati | Riza tarihi + kaynagi kayit altina alinmali |
| 6 | SMS provider env var | Gonderim imkansiz | `SMS_API_KEY` vb. env var + sms-client.ts helper |

---

## KVKK / Ticari Elektronik Ileti Mevzuati

Turkiye'de B2C SMS kampanyalari asagidaki yasal cercevede duzenlenmistir:

**6563 Sayili Kanun — Ticari Iletisim ve Ticari Elektronik Iletiler Hakkinda Kanun**

- Alici acik rizasi olmadan ticari SMS gonderilemez
- Riza, onceden alinmali; gonul rizasiyla verilmeli; spesifik olmali
- Opt-out istekleri maksimum 3 is gunu icinde islenmelidir
- Gonderici kimliginin acik sekilde belirtilmesi zorunludur

**IYS — Ileti Yonetim Sistemi**

- Turkiye'de B2C ticari elektronik ileti gondericileri icin zorunlu kayit sistemi
- Tum ticari SMS/email/arama izinleri IYS'e kaydedilmeli
- Tum opt-out'lar IYS'e yansitilmali
- Netgsm ve Ileti Merkezi gibi yerel providerlar IYS entegrasyonunu otomatik olarak saglar

**SMS consent kaydi tutulmalidir:**
- Opt-in tarihi (`consented_at`)
- Opt-in kaynagi (`consent_source`: ör. `loyalty_signup`, `follow_form`, `checkout`)
- Opsiyonel: IP adresi (KVKK kapsaminda dikkatli kullanilmali)

---

## Provider Secenekleri

| Provider | Kapsam | IYS Entegrasyonu | Notlar |
|---|---|---|---|
| **Netgsm** | Turkiye | Mevcut (direkt entegrasyon) | Yerel, yaygın kullanim, Turkiye numara kaynagi |
| **Ileti Merkezi** | Turkiye | Mevcut (direkt entegrasyon) | Yerel, IYS uyumlu API |
| **Verimor** | Turkiye | Mevcut | Yerel, API tabanlı |
| Twilio | Global | Manuel (kendi implementasyonu) | IYS entegrasyonu geregiyle developer tarafi |

**Oneri:** Netgsm veya Ileti Merkezi — Turkiye IYS uyumlulugu icin. Twilio kullanilacaksa IYS API entegrasyonu ayrica yapilmalidir.

---

## Gerekli Env Degiskenleri (Deger Degil, Isim)

```
SMS_PROVIDER=netgsm|ileti-merkezi|twilio
SMS_API_KEY=
SMS_API_SECRET=
SMS_SENDER_ID=
```

Mevcut `.env.example`'da bu degiskenler **yoktur** — eklenmesi gerekiyor.

---

## Teknik Tasarim (MVP — Sirali)

### Adim 1 — Migration: `user_profiles.phone`

```sql
-- Nullable telefon kolonu — kullanici profil sayfasindan doldurulur
ALTER TABLE user_profiles ADD COLUMN phone text;
-- Format kontrolu: +90XXXXXXXXXX (E.164)
ALTER TABLE user_profiles ADD CONSTRAINT user_profiles_phone_format
  CHECK (phone IS NULL OR phone ~ '^\+[1-9]\d{7,14}$');
```

### Adim 2 — Migration: `business_follows.is_subscribed_sms`

```sql
-- SMS opt-in consent kolonu — default false (opt-out)
ALTER TABLE business_follows ADD COLUMN is_subscribed_sms boolean NOT NULL DEFAULT false;
ALTER TABLE business_follows ADD COLUMN sms_consented_at timestamptz;
ALTER TABLE business_follows ADD COLUMN sms_consent_source text;
-- Ornekler: 'loyalty_signup' | 'follow_form' | 'checkout' | 'profile_settings'
```

### Adim 3 — Migration: `sms_campaigns` tablosu

```sql
CREATE TABLE public.sms_campaigns (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  message     text NOT NULL,
  segment     text NOT NULL CHECK (segment IN ('followers', 'loyalty', 'all')),
  sent_count  int NOT NULL DEFAULT 0,
  status      text NOT NULL DEFAULT 'queued'
              CHECK (status IN ('queued', 'scheduled', 'sending', 'sent', 'failed')),
  scheduled_at timestamptz,
  sent_at     timestamptz,
  created_by  uuid NOT NULL REFERENCES auth.users(id),
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- RLS
ALTER TABLE public.sms_campaigns ENABLE ROW LEVEL SECURITY;

CREATE POLICY "owner can view own business campaigns"
  ON public.sms_campaigns FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM business_claims bc
      WHERE bc.business_id = sms_campaigns.business_id
        AND bc.user_id = auth.uid()
        AND bc.status = 'approved'
    )
  );

CREATE POLICY "owner can insert own business campaigns"
  ON public.sms_campaigns FOR INSERT
  WITH CHECK (
    created_by = auth.uid() AND
    EXISTS (
      SELECT 1 FROM business_claims bc
      WHERE bc.business_id = sms_campaigns.business_id
        AND bc.user_id = auth.uid()
        AND bc.status = 'approved'
    )
  );
```

### Adim 4 — Provider Helper: `src/lib/sms/sms-client.ts`

Email ve push'taki fail-safe pattern ayniyla uygulanmali:

```typescript
// src/lib/sms/sms-client.ts
// Env var yoksa provider_not_configured: true dondur — asla throw etme
export async function sendSmsToRecipients(
  phoneNumbers: string[],
  message: string,
  senderId: string,
): Promise<{ success_count: number; failure_count: number; provider_not_configured: boolean }> {
  const apiKey = process.env.SMS_API_KEY?.trim();
  const provider = process.env.SMS_PROVIDER?.trim();

  if (!apiKey || !provider) {
    return { success_count: 0, failure_count: 0, provider_not_configured: true };
  }
  // Provider-specific implementation (Netgsm / Ileti Merkezi / Twilio)
}
```

### Adim 5 — Route Guncelleme

Route'a eklenmesi gerekenler:
- `is_subscribed_sms = true` filtresi (KVKK zorunlu)
- `user_profiles.phone` join'i ile gercek telefon numarasi cekme
- `sms-client.ts` provider cagirisi
- `sent_at` ve `sent_count` guncelleme

### Adim 6 — Opt-out Endpoint

```
POST /api/sms/unsubscribe
```

Gereksinimler:
- SMS'ten gelen STOP komutu handler (provider webhook'u)
- `business_follows.is_subscribed_sms = false` guncelle
- `sms_consented_at` / `sms_consent_source` temizle veya `unsubscribed_at` kaydet
- IYS'e opt-out bildirimi (provider API veya IYS direkt API)
- Maks 3 is gunu SLA — otomatik islem zorunlu

---

## Kisitlamalar / Bu PR'da Yapilmayanlar

- Gercek SMS gonderimu eklenmedi
- Hicbir migration yazilmadi
- Provider baglantisi kurulmadi
- Opt-out mekanizmasi eklenmedi
- Kullanici profil sayfasina telefon alani eklenmedi
- KVKK consent kaydi eklenmedi

---

## Rollout Plani

1. **Oncesinde**: Migration'lar uygulanmali + provider secilmeli + env var'lar hazirlanmali
2. **Alpha**: Admin test segmentiyle dry-run (kendi numaraniza SMS)
3. **Owner beta**: 1 isletme sahibiyle kontrollü test kampanyasi
4. **Rate limit dogrulamasi**: Gunluk max 1000 SMS / kampanya limiti oneriyor — burst koruması
5. **Production rollout**: IYS kaydi tamamlandiktan sonra

---

## Aktivasyon Durumu (Su An)

| Kontrol | Durum | Not |
|---|---|---|
| Route + ownership guard | Var | `hasOwnerBusiness()` aktif |
| Rate limit (3/saat) | Var | `rateLimit()` aktif |
| Zod input validation | Var | `schema.safeParse()` aktif |
| `sms_campaigns` DB migration | Yok | Tablo yok — `as any` ile kaciniyor |
| `user_profiles.phone` | Yok | Telefon numarasi toplanmiyor |
| `is_subscribed_sms` opt-in | Yok | KVKK filtresi uygulanamaz |
| SMS provider env var | Yok | `.env.example`'da tanimli degil |
| Gercek SMS gonderimu | Yok | `// TODO` comment'i mevcut |
| Opt-out handler | Yok | IYS uyumlulugu saglanamaz |
| KVKK riza kaydi | Yok | `consented_at` + `consent_source` yok |

**Sonuc:** Route deploy edilmis ama tum gonderim altyapisi eksik. Provider entegrasyonundan once consent altyapisi zorunlu.

---

## Ilgili Dosyalar

| Dosya | Aciklama |
|---|---|
| `app/sunucu/sahip/sms-kampanya/route.ts` | SMS kampanya endpoint — TODO comment satirinda |
| `app/sahip/pazarlama/sms/page.tsx` | Owner SMS UI — dokunma |
| `app/sahip/pazarlama/sms/sms-istemci.tsx` | Owner SMS client component — dokunma |
| `docs/push-delivery-integration-plan.md` | FCM push icin referans pattern (fail-safe, env var, rollout) |
| `docs/email-delivery-integration-plan.md` | Resend email icin referans pattern (consent filtresi, broken RPC notu) |
