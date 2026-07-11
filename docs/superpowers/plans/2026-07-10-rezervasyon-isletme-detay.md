# Rezervasyon Entegrasyonu — İşletme Detay Sayfaları

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** İşletme detay sayfalarına (web + mobil) müşteri tarafı "Rezervasyon Yap" akışı ekler; DB'de `reservations` tablosu ve business reservation ayarları oluşturulur, owner panel rezervasyonları gerçek DB'den çeker.

**Architecture:** Tek Supabase migration (businesses + reservations + 2 RPC); web tarafında `isletme-detay-tablari.tsx` içinde `ReservasyonFormu` client bileşeni `create_reservation_v1` server action'ı çağırır; mobilde `Business` modeline rezervasyon alanları eklenir, yeni `ReservationSheet` bottom sheet `ReservationRepository.submit()` RPC'yi çağırır; owner panel mock veriden gerçek `owner_list_reservations_v1` RPC'ye geçer.

**Tech Stack:** PostgreSQL/Supabase, Next.js 15 Server Actions + `useActionState`, Zod, Flutter/Riverpod, `supabase_flutter`

---

## Dosya Haritası

| Dosya | İşlem | Amaç |
|---|---|---|
| `supabase/migrations/20260711000001_reservations.sql` | Oluştur | DB tablosu + kolonlar + RPCler |
| `uygulamalar/web/src/lib/veri/pazar-okuma.ts:22-227` | Değiştir | businessSelect + return'e rezervasyon alanları ekle |
| `uygulamalar/web/app/(genel)/isletme/[slug]/isletme-detay-tablari.tsx:46-85` | Değiştir | Prop'lar + section render |
| `uygulamalar/web/app/(genel)/isletme/[slug]/page.tsx:121-230` | Değiştir | Yeni prop'ları geçir |
| `uygulamalar/web/app/(genel)/isletme/[slug]/rezervasyon-formu.tsx` | Oluştur | Client form + server action |
| `uygulamalar/web/app/owner/(panel)/reservations/reservations-client.tsx` | Değiştir | Mock → gerçek DB verisi için prop hazırlığı |
| `uygulamalar/web/app/owner/(panel)/reservations/page.tsx` | Değiştir | `owner_list_reservations_v1` RPC çağrısı ekle |
| `uygulamalar/mobil/lib/features/business/domain/business.dart` | Değiştir | `acceptsReservations`, `reservationPhone`, `reservationMinParty`, `reservationMaxParty` alanları |
| `uygulamalar/mobil/lib/features/business/data/reservation_repository.dart` | Oluştur | `submitReservation()` RPC wrapper |
| `uygulamalar/mobil/lib/features/business/ui/reservation_sheet.dart` | Oluştur | Bottom sheet form |
| `uygulamalar/mobil/lib/features/business/ui/sections/business_detail_sections.dart` | Değiştir | "Rezervasyon Yap" bölümü ekle |

---

## Task 1: DB Migration — businesses + reservations tablosu + RPCler

**Files:**
- Create: `supabase/migrations/20260711000001_reservations.sql`

- [ ] **Step 1: Migrasyon dosyasını oluştur**

```sql
-- ─────────────────────────────────────────────────────────────────────────────
-- 1. businesses tablosuna rezervasyon ayar kolonları
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE public.businesses
  ADD COLUMN IF NOT EXISTS accepts_reservations   BOOLEAN  NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS reservation_phone       TEXT,
  ADD COLUMN IF NOT EXISTS reservation_min_party   INT      NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS reservation_max_party   INT      NOT NULL DEFAULT 20,
  ADD COLUMN IF NOT EXISTS reservation_advance_hours INT    NOT NULL DEFAULT 2,
  ADD COLUMN IF NOT EXISTS reservation_window_days  INT    NOT NULL DEFAULT 30,
  ADD COLUMN IF NOT EXISTS reservation_note        TEXT;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. reservations tablosu
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.reservations (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id      UUID        NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  user_id          UUID        REFERENCES auth.users(id),
  guest_name       TEXT        NOT NULL,
  guest_phone      TEXT        NOT NULL,
  guest_email      TEXT,
  party_size       INT         NOT NULL,
  reservation_date DATE        NOT NULL,
  reservation_time TIME        NOT NULL,
  status           TEXT        NOT NULL DEFAULT 'pending',
  channel          TEXT        NOT NULL DEFAULT 'web',
  table_preference TEXT,
  special_request  TEXT,
  owner_note       TEXT,
  reservation_no   TEXT        NOT NULL,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT reservations_status_valid  CHECK (status IN ('pending','confirmed','cancelled','completed')),
  CONSTRAINT reservations_channel_valid CHECK (channel IN ('web','mobile','phone','yeedoy_app')),
  CONSTRAINT reservations_party_size    CHECK (party_size >= 1 AND party_size <= 100)
);

CREATE INDEX IF NOT EXISTS reservations_business_idx  ON public.reservations(business_id);
CREATE INDEX IF NOT EXISTS reservations_date_idx      ON public.reservations(business_id, reservation_date);
CREATE INDEX IF NOT EXISTS reservations_status_idx    ON public.reservations(business_id, status);

ALTER TABLE public.reservations ENABLE ROW LEVEL SECURITY;

-- Müşteri kendi rezervasyonunu görebilir
CREATE POLICY "reservations_owner_read" ON public.reservations
  FOR SELECT TO authenticated
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.owner_claims oc
      WHERE oc.business_id = reservations.business_id
        AND oc.user_id = auth.uid()
        AND oc.status = 'approved'
    )
  );

-- Owner tüm işlemleri yapabilir
CREATE POLICY "reservations_owner_all" ON public.reservations
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.owner_claims oc
      WHERE oc.business_id = reservations.business_id
        AND oc.user_id = auth.uid()
        AND oc.status = 'approved'
    )
  );

CREATE OR REPLACE FUNCTION public.tg_reservations_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END; $$;

CREATE TRIGGER reservations_updated_at
  BEFORE UPDATE ON public.reservations
  FOR EACH ROW EXECUTE FUNCTION public.tg_reservations_updated_at();

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. RPC: create_reservation_v1  (anon + authenticated — müşteri tarafı)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.create_reservation_v1(
  p_business_id    UUID,
  p_guest_name     TEXT,
  p_guest_phone    TEXT,
  p_guest_email    TEXT     DEFAULT NULL,
  p_party_size     INT      DEFAULT 2,
  p_date           DATE     DEFAULT CURRENT_DATE,
  p_time           TIME     DEFAULT '19:00',
  p_channel        TEXT     DEFAULT 'web',
  p_table_preference TEXT   DEFAULT NULL,
  p_special_request  TEXT   DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id       UUID;
  v_no       TEXT;
  v_accepts  BOOLEAN;
  v_min      INT;
  v_max      INT;
BEGIN
  -- işletme rezervasyon kabul ediyor mu?
  SELECT accepts_reservations, reservation_min_party, reservation_max_party
  INTO v_accepts, v_min, v_max
  FROM public.businesses
  WHERE id = p_business_id AND is_active = true;

  IF v_accepts IS NULL THEN
    RAISE EXCEPTION 'not_found: İşletme bulunamadı' USING ERRCODE = 'P0001';
  END IF;
  IF NOT v_accepts THEN
    RAISE EXCEPTION 'validation_error: Bu işletme rezervasyon kabul etmiyor' USING ERRCODE = 'P0003';
  END IF;
  IF p_party_size < v_min OR p_party_size > v_max THEN
    RAISE EXCEPTION 'validation_error: Kişi sayısı % ile % arasında olmalıdır', v_min, v_max USING ERRCODE = 'P0003';
  END IF;
  IF char_length(p_guest_name) < 2 THEN
    RAISE EXCEPTION 'validation_error: Ad en az 2 karakter olmalıdır' USING ERRCODE = 'P0003';
  END IF;
  IF char_length(p_guest_phone) < 10 THEN
    RAISE EXCEPTION 'validation_error: Geçersiz telefon numarası' USING ERRCODE = 'P0003';
  END IF;

  -- Rezervasyon numarası: RZV-YYYY-NNNN
  v_no := 'RZV-' || to_char(now(), 'YYYY') || '-' || lpad(
    (SELECT count(*)::int + 1 FROM public.reservations
     WHERE date_trunc('year', created_at) = date_trunc('year', now()))::text,
    4, '0'
  );

  INSERT INTO public.reservations (
    business_id, user_id, guest_name, guest_phone, guest_email,
    party_size, reservation_date, reservation_time,
    status, channel, table_preference, special_request, reservation_no
  ) VALUES (
    p_business_id, auth.uid(), p_guest_name, p_guest_phone, p_guest_email,
    p_party_size, p_date, p_time,
    'pending', p_channel, p_table_preference, p_special_request, v_no
  )
  RETURNING id INTO v_id;

  RETURN jsonb_build_object('id', v_id, 'reservation_no', v_no);
END;
$$;

REVOKE ALL ON FUNCTION public.create_reservation_v1(UUID,TEXT,TEXT,TEXT,INT,DATE,TIME,TEXT,TEXT,TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_reservation_v1(UUID,TEXT,TEXT,TEXT,INT,DATE,TIME,TEXT,TEXT,TEXT) TO anon, authenticated;
COMMENT ON FUNCTION public.create_reservation_v1 IS 'Müşteri tarafı rezervasyon oluşturma. Called by: isletme/[slug], mobil ReservationSheet.';

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. RPC: owner_list_reservations_v1  (owner panel gerçek veri)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.owner_list_reservations_v1(
  p_business_id UUID,
  p_status      TEXT    DEFAULT NULL,
  p_date_from   DATE    DEFAULT NULL,
  p_date_to     DATE    DEFAULT NULL,
  p_limit       INT     DEFAULT 50,
  p_offset      INT     DEFAULT 0
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_rows  JSONB;
  v_total BIGINT;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.owner_claims oc
    WHERE oc.business_id = p_business_id AND oc.user_id = auth.uid() AND oc.status = 'approved'
  ) THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  SELECT count(*) INTO v_total
  FROM public.reservations r
  WHERE r.business_id = p_business_id
    AND (p_status   IS NULL OR r.status = p_status)
    AND (p_date_from IS NULL OR r.reservation_date >= p_date_from)
    AND (p_date_to   IS NULL OR r.reservation_date <= p_date_to);

  SELECT coalesce(jsonb_agg(to_jsonb(r) ORDER BY r.reservation_date, r.reservation_time), '[]')
  INTO v_rows
  FROM (
    SELECT id, reservation_no, guest_name, guest_phone, guest_email,
           party_size, reservation_date, reservation_time, status, channel,
           table_preference, special_request, owner_note, created_at, updated_at
    FROM public.reservations
    WHERE business_id = p_business_id
      AND (p_status   IS NULL OR status = p_status)
      AND (p_date_from IS NULL OR reservation_date >= p_date_from)
      AND (p_date_to   IS NULL OR reservation_date <= p_date_to)
    ORDER BY reservation_date, reservation_time
    LIMIT p_limit OFFSET p_offset
  ) r;

  RETURN jsonb_build_object('rows', v_rows, 'total', v_total);
END;
$$;

REVOKE ALL ON FUNCTION public.owner_list_reservations_v1(UUID,TEXT,DATE,DATE,INT,INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.owner_list_reservations_v1(UUID,TEXT,DATE,DATE,INT,INT) TO authenticated;
COMMENT ON FUNCTION public.owner_list_reservations_v1 IS 'Owner panel rezervasyon listesi. Called by: owner/reservations/page.tsx.';

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. RPC: owner_update_reservation_status_v1
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.owner_update_reservation_status_v1(
  p_id          UUID,
  p_business_id UUID,
  p_status      TEXT,
  p_owner_note  TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;
  IF p_status NOT IN ('pending','confirmed','cancelled','completed') THEN
    RAISE EXCEPTION 'validation_error: Geçersiz durum' USING ERRCODE = 'P0003';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.owner_claims oc
    WHERE oc.business_id = p_business_id AND oc.user_id = auth.uid() AND oc.status = 'approved'
  ) THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  UPDATE public.reservations
  SET status = p_status,
      owner_note = coalesce(p_owner_note, owner_note)
  WHERE id = p_id AND business_id = p_business_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found: Rezervasyon bulunamadı' USING ERRCODE = 'P0001';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.owner_update_reservation_status_v1(UUID,UUID,TEXT,TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.owner_update_reservation_status_v1(UUID,UUID,TEXT,TEXT) TO authenticated;
COMMENT ON FUNCTION public.owner_update_reservation_status_v1 IS 'Owner panel durum güncelleme. Called by: owner/reservations/.';
```

- [ ] **Step 2: Migrasyon uygula**

```bash
# Local Supabase ile:
supabase db reset   # ya da
supabase migration up
```

Beklenen çıktı: `Applying migration 20260711000001_reservations.sql... OK`

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260711000001_reservations.sql
git commit -m "feat(db): reservations tablosu, businesses rezervasyon kolonları, 3 owner RPC"
```

---

## Task 2: Web — `pazar-okuma.ts` ve `page.tsx` güncelleme

**Files:**
- Modify: `uygulamalar/web/src/lib/veri/pazar-okuma.ts`
- Modify: `uygulamalar/web/app/(genel)/isletme/[slug]/page.tsx`

- [ ] **Step 1: `businessSelect` + return değerini güncelle (`pazar-okuma.ts:22`)**

```typescript
// Satır 22 — VAR:
const businessSelect =
  'id,name,slug,public_slug,description,logo_url,cover_url,category,city,district,address,is_verified,is_active,created_at';

// YENİ:
const businessSelect =
  'id,name,slug,public_slug,description,logo_url,cover_url,category,city,district,address,is_verified,is_active,created_at,' +
  'accepts_reservations,reservation_phone,reservation_min_party,reservation_max_party,reservation_note';
```

- [ ] **Step 2: `getMarketplaceBusinessBySlug` dönüş objesine rezervasyon alanlarını ekle (`pazar-okuma.ts:218-227`)**

```typescript
// VAR:
  return {
    ...card,
    phone: data.phone ?? null,
    website: null,
    lat: data.lat ?? null,
    lng: data.lng ?? null,
    menuHref: menu,
    hours,
  };

// YENİ:
  return {
    ...card,
    phone: data.phone ?? null,
    website: null,
    lat: data.lat ?? null,
    lng: data.lng ?? null,
    menuHref: menu,
    hours,
    acceptsReservations: (data.accepts_reservations as boolean) ?? false,
    reservationPhone: (data.reservation_phone as string | null) ?? null,
    reservationMinParty: (data.reservation_min_party as number) ?? 1,
    reservationMaxParty: (data.reservation_max_party as number) ?? 20,
    reservationNote: (data.reservation_note as string | null) ?? null,
  };
```

- [ ] **Step 3: `IsletmeDetayTablariProps` tipine yeni prop'ları ekle (`isletme-detay-tablari.tsx:46-85`)**

```typescript
// YENİ prop'ları ekle (medianPriceCents'ten sonra):
  acceptsReservations: boolean;
  reservationPhone: string | null;
  reservationMinParty: number;
  reservationMaxParty: number;
  reservationNote: string | null;
  businessId: string;  // rezervasyon form'una geçmek için (zaten var, kontrol et)
```

- [ ] **Step 4: `page.tsx`'de yeni prop'ları `IsletmeDetayTablari`'ye geçir**

```typescript
// IsletmeDetayTablari bileşenine şu prop'ları ekle (mevcut prop'ların yanına):
acceptsReservations={business.acceptsReservations ?? false}
reservationPhone={business.reservationPhone ?? null}
reservationMinParty={business.reservationMinParty ?? 1}
reservationMaxParty={business.reservationMaxParty ?? 20}
reservationNote={business.reservationNote ?? null}
```

- [ ] **Step 5: Typecheck çalıştır**

```bash
cd uygulamalar/web
npm run typecheck
```

Beklenen: sıfır hata (sadece yeni prop'lara bağlı hata varsa bir sonraki task'ta çözülür).

- [ ] **Step 6: Commit**

```bash
git add uygulamalar/web/src/lib/veri/pazar-okuma.ts \
        uygulamalar/web/app/'(genel)'/isletme/'[slug]'/page.tsx \
        uygulamalar/web/app/'(genel)'/isletme/'[slug]'/isletme-detay-tablari.tsx
git commit -m "feat(web): işletme detay sayfasına rezervasyon prop'ları eklendi"
```

---

## Task 3: Web — `ReservasyonFormu` client bileşeni

**Files:**
- Create: `uygulamalar/web/app/(genel)/isletme/[slug]/rezervasyon-formu.tsx`

- [ ] **Step 1: Server action ve form bileşeni oluştur**

```typescript
// uygulamalar/web/app/(genel)/isletme/[slug]/rezervasyon-formu.tsx
'use client';

import { useActionState, useRef } from 'react';
import { createSupabaseBrowserClient } from '@/src/lib/taban-istemci';
import { z } from 'zod';

// ── Server action ──────────────────────────────────────────────────────────

async function submitReservation(
  _prev: { error?: string; success?: boolean } | null,
  formData: FormData,
): Promise<{ error?: string; success?: boolean; reservationNo?: string }> {
  'use server';

  const schema = z.object({
    business_id:       z.string().uuid(),
    guest_name:        z.string().min(2).max(100),
    guest_phone:       z.string().min(10).max(20),
    guest_email:       z.string().email().optional().or(z.literal('')),
    party_size:        z.coerce.number().int().min(1).max(100),
    reservation_date:  z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
    reservation_time:  z.string().regex(/^\d{2}:\d{2}$/),
    special_request:   z.string().max(500).optional(),
  });

  const parsed = schema.safeParse({
    business_id:      formData.get('business_id'),
    guest_name:       formData.get('guest_name'),
    guest_phone:      formData.get('guest_phone'),
    guest_email:      formData.get('guest_email') || undefined,
    party_size:       formData.get('party_size'),
    reservation_date: formData.get('reservation_date'),
    reservation_time: formData.get('reservation_time'),
    special_request:  formData.get('special_request') || undefined,
  });

  if (!parsed.success) return { error: 'Lütfen tüm zorunlu alanları doldurun.' };

  const d = parsed.data;
  const { createSupabaseServerClient } = await import('@/src/lib/taban-sunucu');
  const supabase = await createSupabaseServerClient();
  const { data, error } = await (supabase as any).rpc('create_reservation_v1', {
    p_business_id:     d.business_id,
    p_guest_name:      d.guest_name,
    p_guest_phone:     d.guest_phone,
    p_guest_email:     d.guest_email || null,
    p_party_size:      d.party_size,
    p_date:            d.reservation_date,
    p_time:            d.reservation_time,
    p_channel:         'web',
    p_special_request: d.special_request || null,
  });

  if (error) return { error: error.message ?? 'Rezervasyon oluşturulamadı.' };
  return { success: true, reservationNo: (data as any)?.reservation_no };
}

// ── Component ─────────────────────────────────────────────────────────────

interface Props {
  businessId: string;
  businessName: string;
  minParty: number;
  maxParty: number;
  reservationNote: string | null;
  reservationPhone: string | null;
}

export function ReservasyonFormu({
  businessId, businessName, minParty, maxParty, reservationNote, reservationPhone,
}: Props) {
  const [state, action, pending] = useActionState(submitReservation, null);
  const hasSubmitted = useRef(false);

  // Minimum tarih: bugün + 1 gün
  const minDate = new Date();
  minDate.setDate(minDate.getDate() + 1);
  const minDateStr = minDate.toISOString().split('T')[0];

  if (state?.success) {
    return (
      <div className="rounded-2xl border border-green-200 bg-green-50 p-6 text-center">
        <div className="mb-3 text-3xl">✓</div>
        <p className="text-base font-[800] text-green-800">Rezervasyonunuz alındı!</p>
        <p className="mt-1 text-sm text-green-700">
          Rezervasyon No: <span className="font-mono font-[900]">{state.reservationNo}</span>
        </p>
        <p className="mt-2 text-xs text-green-600">
          {businessName} ekibi en kısa sürede onaylayacak.
          {reservationPhone && <> Sorularınız için: <strong>{reservationPhone}</strong></>}
        </p>
      </div>
    );
  }

  return (
    <form
      action={action}
      onSubmit={() => { hasSubmitted.current = true; }}
      className="flex flex-col gap-4"
    >
      <input type="hidden" name="business_id" value={businessId} />

      <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
        <div>
          <label className="mb-1 block text-xs font-[700] text-[#64748b]">Ad Soyad *</label>
          <input name="guest_name" required minLength={2} maxLength={100}
            placeholder="Adınız Soyadınız"
            className="w-full rounded-xl border border-[#e2e8f0] bg-[#f8fafc] px-3 py-2.5 text-sm text-[#1a1a2e] placeholder:text-[#94a3b8] focus:outline-none focus:ring-2 focus:ring-[#dc2626]/20" />
        </div>
        <div>
          <label className="mb-1 block text-xs font-[700] text-[#64748b]">Telefon *</label>
          <input name="guest_phone" type="tel" required minLength={10} maxLength={20}
            placeholder="05xx xxx xx xx"
            className="w-full rounded-xl border border-[#e2e8f0] bg-[#f8fafc] px-3 py-2.5 text-sm text-[#1a1a2e] placeholder:text-[#94a3b8] focus:outline-none focus:ring-2 focus:ring-[#dc2626]/20" />
        </div>
        <div>
          <label className="mb-1 block text-xs font-[700] text-[#64748b]">Tarih *</label>
          <input name="reservation_date" type="date" required min={minDateStr}
            className="w-full rounded-xl border border-[#e2e8f0] bg-[#f8fafc] px-3 py-2.5 text-sm text-[#1a1a2e] focus:outline-none focus:ring-2 focus:ring-[#dc2626]/20" />
        </div>
        <div>
          <label className="mb-1 block text-xs font-[700] text-[#64748b]">Saat *</label>
          <input name="reservation_time" type="time" required
            className="w-full rounded-xl border border-[#e2e8f0] bg-[#f8fafc] px-3 py-2.5 text-sm text-[#1a1a2e] focus:outline-none focus:ring-2 focus:ring-[#dc2626]/20" />
        </div>
        <div>
          <label className="mb-1 block text-xs font-[700] text-[#64748b]">
            Kişi Sayısı * ({minParty}–{maxParty})
          </label>
          <input name="party_size" type="number" required
            min={minParty} max={maxParty} defaultValue={2}
            className="w-full rounded-xl border border-[#e2e8f0] bg-[#f8fafc] px-3 py-2.5 text-sm text-[#1a1a2e] focus:outline-none focus:ring-2 focus:ring-[#dc2626]/20" />
        </div>
        <div>
          <label className="mb-1 block text-xs font-[700] text-[#64748b]">E-posta</label>
          <input name="guest_email" type="email"
            placeholder="ornek@email.com"
            className="w-full rounded-xl border border-[#e2e8f0] bg-[#f8fafc] px-3 py-2.5 text-sm text-[#1a1a2e] placeholder:text-[#94a3b8] focus:outline-none focus:ring-2 focus:ring-[#dc2626]/20" />
        </div>
      </div>

      <div>
        <label className="mb-1 block text-xs font-[700] text-[#64748b]">Özel İstek</label>
        <textarea name="special_request" rows={2} maxLength={500}
          placeholder="Allerji, masa tercihi, doğum günü vb..."
          className="w-full resize-none rounded-xl border border-[#e2e8f0] bg-[#f8fafc] px-3 py-2.5 text-sm text-[#1a1a2e] placeholder:text-[#94a3b8] focus:outline-none focus:ring-2 focus:ring-[#dc2626]/20" />
      </div>

      {reservationNote && (
        <p className="rounded-xl bg-amber-50 px-3 py-2 text-xs text-amber-700">{reservationNote}</p>
      )}

      {state?.error && (
        <p className="rounded-xl bg-red-50 px-3 py-2 text-sm font-[700] text-red-600">{state.error}</p>
      )}

      <button
        type="submit"
        disabled={pending}
        className="w-full rounded-xl bg-[#dc2626] py-3 text-sm font-[900] text-white transition hover:opacity-90 disabled:opacity-50"
      >
        {pending ? 'Gönderiliyor...' : 'Rezervasyon Yap'}
      </button>
    </form>
  );
}
```

- [ ] **Step 2: `isletme-detay-tablari.tsx`'e rezervasyon section'ı ekle**

`IsletmeDetayTablariProps` bloğunun sonuna yeni prop'ları ekle:
```typescript
  acceptsReservations: boolean;
  reservationPhone: string | null;
  reservationMinParty: number;
  reservationMaxParty: number;
  reservationNote: string | null;
```

`IsletmeDetayTablari` bileşen gövdesinde, "yorumlar" sekmesinden önce (ya da `DetayTab === 'bilgiler'` bloğuna) aşağıdaki bloğu ekle:

```typescript
// import ekle:
import { ReservasyonFormu } from './rezervasyon-formu';

// Bileşen içinde, "bilgiler" tabı bloğuna veya sayfanın üst kısmına:
{acceptsReservations && (
  <div className="rounded-2xl border border-[#f0f0f0] bg-white p-5 shadow-sm">
    <h2 className="mb-4 text-base font-[900] text-[#1a1a2e]">Rezervasyon Yap</h2>
    <ReservasyonFormu
      businessId={businessId}
      businessName={businessName}
      minParty={reservationMinParty}
      maxParty={reservationMaxParty}
      reservationNote={reservationNote}
      reservationPhone={reservationPhone}
    />
  </div>
)}
```

- [ ] **Step 3: Typecheck + lint çalıştır**

```bash
cd uygulamalar/web
npm run typecheck && npm run lint
```

Beklenen: sıfır hata.

- [ ] **Step 4: Commit**

```bash
git add uygulamalar/web/app/'(genel)'/isletme/'[slug]'/rezervasyon-formu.tsx \
        uygulamalar/web/app/'(genel)'/isletme/'[slug]'/isletme-detay-tablari.tsx
git commit -m "feat(web): işletme detay sayfasına Rezervasyon Yap formu eklendi"
```

---

## Task 4: Web — Owner Panel gerçek DB verisine bağlama

**Files:**
- Modify: `uygulamalar/web/app/owner/(panel)/reservations/page.tsx`
- Modify: `uygulamalar/web/app/owner/(panel)/reservations/reservations-client.tsx`

- [ ] **Step 1: `page.tsx`'i gerçek RPC çağrısı yapacak şekilde güncelle**

```typescript
// app/owner/(panel)/reservations/page.tsx
import type { Metadata } from 'next';
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { ReservationsClient, type DbReservation } from './reservations-client';

export const metadata: Metadata = {
  title: 'Rezervasyonlar | Owner Panel',
  robots: { index: false, follow: false },
};

export default async function OwnerReservationsPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect('/login');

  const { data: claim } = await (supabase as any)
    .from('owner_claims')
    .select('business_id')
    .eq('user_id', user.id)
    .eq('status', 'approved')
    .limit(1)
    .maybeSingle() as { data: { business_id: string } | null };

  if (!claim) redirect('/owner/dashboard');

  const { data: result } = await (supabase as any).rpc('owner_list_reservations_v1', {
    p_business_id: claim.business_id,
    p_limit: 50,
    p_offset: 0,
  }) as { data: { rows: DbReservation[]; total: number } | null };

  return (
    <ReservationsClient
      businessId={claim.business_id}
      initialReservations={result?.rows ?? []}
      total={result?.total ?? 0}
    />
  );
}
```

- [ ] **Step 2: `ReservationsClient` prop interface ekle**

`reservations-client.tsx`'in en üstüne `DbReservation` tipini ve `Props` interface'ini ekle, `MOCK` verisini kaldır:

```typescript
export interface DbReservation {
  id: string;
  reservation_no: string;
  guest_name: string;
  guest_phone: string;
  guest_email: string | null;
  party_size: number;
  reservation_date: string;  // "2025-06-06"
  reservation_time: string;  // "19:30:00"
  status: 'pending' | 'confirmed' | 'cancelled' | 'completed';
  channel: 'web' | 'mobile' | 'phone' | 'yeedoy_app';
  table_preference: string | null;
  special_request: string | null;
  owner_note: string | null;
  created_at: string;
}

interface Props {
  businessId: string;
  initialReservations: DbReservation[];
  total: number;
}
```

Mevcut `Reservation` interface'ini `DbReservation`'dan türet:
- `no` → `reservation_no`
- `dateStr` → `reservation_date` (ISO) + formatla
- `time` → `reservation_time` ilk 5 karakter (`"19:30"`)
- `people` → `party_size`
- `channel`: `'web' | 'yeedoy_app' | 'mobile' | 'phone'` → Channel tipine map et
- `hasNote`: `special_request !== null || owner_note !== null`

`MOCK` const'ını sil, `useState<Reservation[]>(MOCK)` yerine `useState<Reservation[]>(initialReservations.map(toReservation))` kullan.

`toReservation` dönüştürücüsü:
```typescript
function toReservation(r: DbReservation): Reservation {
  const dateObj = new Date(r.reservation_date);
  const DAYS = ['Pazar','Pazartesi','Salı','Çarşamba','Perşembe','Cuma','Cumartesi'];
  const MONTHS = ['Ocak','Şubat','Mart','Nisan','Mayıs','Haziran','Temmuz','Ağustos','Eylül','Ekim','Kasım','Aralık'];
  return {
    id: r.id,
    no: r.reservation_no,
    guest: {
      name: r.guest_name,
      phone: r.guest_phone,
      initials: r.guest_name.split(' ').map((w) => w[0] ?? '').join('').slice(0, 2).toUpperCase(),
      color: GUEST_COLORS[r.guest_name.charCodeAt(0) % GUEST_COLORS.length],
    },
    dateStr: `${dateObj.getDate()} ${MONTHS[dateObj.getMonth()]} ${dateObj.getFullYear()}`,
    day: DAYS[dateObj.getDay()],
    time: r.reservation_time.slice(0, 5),
    people: r.party_size,
    status: STATUS_MAP[r.status],
    channel: CHANNEL_MAP[r.channel],
    hasNote: !!(r.special_request || r.owner_note),
    note: r.special_request ?? r.owner_note ?? undefined,
    tablePreference: r.table_preference ?? undefined,
    specialRequest: r.special_request ?? undefined,
    createdAt: new Date(r.created_at).toLocaleDateString('tr-TR', { day:'2-digit', month:'long', year:'numeric', hour:'2-digit', minute:'2-digit' }),
  };
}

const STATUS_MAP: Record<DbReservation['status'], Status> = {
  pending: 'Bekliyor', confirmed: 'Onaylandı', cancelled: 'İptal Edildi', completed: 'Tamamlandı',
};
const CHANNEL_MAP: Record<DbReservation['channel'], Channel> = {
  web: 'Web Sitesi', mobile: 'Yeedoy App', phone: 'Telefon', yeedoy_app: 'Yeedoy App',
};
const GUEST_COLORS = ['#7c3aed','#2563eb','#db2777','#059669','#16a34a','#0891b2','#9333ea'];
```

- [ ] **Step 3: `handleCancel` → gerçek RPC çağrısı**

```typescript
// reservations-client.tsx'e server action import ekle:
import { updateReservationStatus } from './actions';

// actions.ts (yeni dosya):
// 'use server';
// import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
// import { revalidatePath } from 'next/cache';
//
// export async function updateReservationStatus(
//   id: string, businessId: string, status: string
// ): Promise<{ error?: string }> {
//   const supabase = await createSupabaseServerClient();
//   const { error } = await (supabase as any).rpc('owner_update_reservation_status_v1', {
//     p_id: id, p_business_id: businessId, p_status: status,
//   });
//   if (error) return { error: error.message };
//   revalidatePath('/owner/reservations');
//   return {};
// }
```

- [ ] **Step 4: Typecheck**

```bash
cd uygulamalar/web && npm run typecheck
```

- [ ] **Step 5: Commit**

```bash
git add uygulamalar/web/app/owner/'(panel)'/reservations/
git commit -m "feat(web): owner rezervasyon paneli gerçek DB'ye bağlandı"
```

---

## Task 5: Mobil — `Business` modeline rezervasyon alanları ekle

**Files:**
- Modify: `uygulamalar/mobil/lib/features/business/domain/business.dart`

- [ ] **Step 1: `Business` class'ına 4 alan ekle**

```dart
// business.dart — class Business { ... } içinde,
// priceLevel'dan sonra:
  final bool acceptsReservations;
  final String? reservationPhone;
  final int reservationMinParty;
  final int reservationMaxParty;
  final String? reservationNote;
```

Constructor'a ekle:
```dart
  Business({
    // ... mevcut parametreler ...
    this.acceptsReservations = false,
    this.reservationPhone,
    this.reservationMinParty = 1,
    this.reservationMaxParty = 20,
    this.reservationNote,
  });
```

`fromMap` factory'sine ekle:
```dart
    acceptsReservations: (m['accepts_reservations'] as bool?) ?? false,
    reservationPhone: m['reservation_phone'] as String?,
    reservationMinParty: (m['reservation_min_party'] as num?)?.toInt() ?? 1,
    reservationMaxParty: (m['reservation_max_party'] as num?)?.toInt() ?? 20,
    reservationNote: m['reservation_note'] as String?,
```

`toMap()`'e ekle:
```dart
    'accepts_reservations': acceptsReservations,
    'reservation_phone': reservationPhone,
    'reservation_min_party': reservationMinParty,
    'reservation_max_party': reservationMaxParty,
    'reservation_note': reservationNote,
```

- [ ] **Step 2: Dart analizi çalıştır**

```bash
cd uygulamalar/mobil
flutter analyze lib/features/business/domain/business.dart
```

Beklenen: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add uygulamalar/mobil/lib/features/business/domain/business.dart
git commit -m "feat(mobile): Business modeline rezervasyon alanları eklendi"
```

---

## Task 6: Mobil — `ReservationRepository` oluştur

**Files:**
- Create: `uygulamalar/mobil/lib/features/business/data/reservation_repository.dart`

- [ ] **Step 1: Repository sınıfını oluştur**

```dart
// uygulamalar/mobil/lib/features/business/data/reservation_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_provider.dart';

final reservationRepositoryProvider = Provider<ReservationRepository>((ref) {
  return ReservationRepository(ref.watch(supabaseProvider));
});

class ReservationResult {
  const ReservationResult({required this.reservationId, required this.reservationNo});
  final String reservationId;
  final String reservationNo;
}

class ReservationRepository {
  ReservationRepository(this._client);
  final SupabaseClient _client;

  Future<ReservationResult> submitReservation({
    required String businessId,
    required String guestName,
    required String guestPhone,
    String? guestEmail,
    required int partySize,
    required DateTime date,
    required String time,   // "19:30"
    String? tablePreference,
    String? specialRequest,
  }) async {
    final res = await _client.rpc('create_reservation_v1', params: {
      'p_business_id':     businessId,
      'p_guest_name':      guestName,
      'p_guest_phone':     guestPhone,
      'p_guest_email':     guestEmail,
      'p_party_size':      partySize,
      'p_date':            '${date.year.toString().padLeft(4,'0')}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}',
      'p_time':            '$time:00',
      'p_channel':         'mobile',
      'p_table_preference': tablePreference,
      'p_special_request': specialRequest,
    });

    if (res == null) throw Exception('Rezervasyon oluşturulamadı.');
    final data = Map<String, dynamic>.from(res as Map);
    return ReservationResult(
      reservationId: data['id'] as String,
      reservationNo: data['reservation_no'] as String,
    );
  }
}
```

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/features/business/data/reservation_repository.dart
```

- [ ] **Step 3: Commit**

```bash
git add uygulamalar/mobil/lib/features/business/data/reservation_repository.dart
git commit -m "feat(mobile): ReservationRepository eklendi"
```

---

## Task 7: Mobil — `ReservationSheet` bottom sheet

**Files:**
- Create: `uygulamalar/mobil/lib/features/business/ui/reservation_sheet.dart`

- [ ] **Step 1: Bottom sheet bileşenini oluştur**

```dart
// uygulamalar/mobil/lib/features/business/ui/reservation_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/shared/ui/design_system.dart';
import '../domain/business.dart';
import '../data/reservation_repository.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class _ReservationState {
  const _ReservationState({
    this.name = '',
    this.phone = '',
    this.email = '',
    this.partySize = 2,
    this.date,
    this.time = '19:30',
    this.specialRequest = '',
    this.pending = false,
    this.error,
    this.successNo,
  });

  final String name;
  final String phone;
  final String email;
  final int partySize;
  final DateTime? date;
  final String time;
  final String specialRequest;
  final bool pending;
  final String? error;
  final String? successNo;

  _ReservationState copyWith({
    String? name, String? phone, String? email,
    int? partySize, DateTime? date, String? time,
    String? specialRequest, bool? pending,
    String? error, String? successNo,
  }) => _ReservationState(
    name: name ?? this.name,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    partySize: partySize ?? this.partySize,
    date: date ?? this.date,
    time: time ?? this.time,
    specialRequest: specialRequest ?? this.specialRequest,
    pending: pending ?? this.pending,
    error: error,
    successNo: successNo,
  );
}

class _ReservationController extends StateNotifier<_ReservationState> {
  _ReservationController(this._repo) : super(const _ReservationState());
  final ReservationRepository _repo;

  void update(_ReservationState Function(_ReservationState) fn) {
    state = fn(state);
  }

  Future<void> submit(Business business) async {
    if (state.name.trim().length < 2) {
      state = state.copyWith(error: 'Ad Soyad en az 2 karakter olmalıdır.');
      return;
    }
    if (state.phone.trim().length < 10) {
      state = state.copyWith(error: 'Geçerli bir telefon numarası girin.');
      return;
    }
    if (state.date == null) {
      state = state.copyWith(error: 'Lütfen bir tarih seçin.');
      return;
    }
    if (state.partySize < business.reservationMinParty ||
        state.partySize > business.reservationMaxParty) {
      state = state.copyWith(
        error: 'Kişi sayısı ${business.reservationMinParty}–${business.reservationMaxParty} arasında olmalıdır.',
      );
      return;
    }

    state = state.copyWith(pending: true, error: null);
    try {
      final result = await _repo.submitReservation(
        businessId: business.id,
        guestName: state.name.trim(),
        guestPhone: state.phone.trim(),
        guestEmail: state.email.trim().isEmpty ? null : state.email.trim(),
        partySize: state.partySize,
        date: state.date!,
        time: state.time,
        specialRequest: state.specialRequest.trim().isEmpty ? null : state.specialRequest.trim(),
      );
      state = state.copyWith(pending: false, successNo: result.reservationNo);
    } catch (e) {
      state = state.copyWith(pending: false, error: e.toString());
    }
  }
}

final _reservationControllerProvider = StateNotifierProvider.autoDispose<
    _ReservationController, _ReservationState>((ref) {
  return _ReservationController(ref.watch(reservationRepositoryProvider));
});

// ── Sheet entry point ──────────────────────────────────────────────────────────

void showReservationSheet(BuildContext context, Business business) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ProviderScope(
      child: _ReservationSheet(business: business),
    ),
  );
}

// ── Sheet widget ───────────────────────────────────────────────────────────────

class _ReservationSheet extends ConsumerWidget {
  const _ReservationSheet({required this.business});
  final Business business;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_reservationControllerProvider);
    final ctrl = ref.read(_reservationControllerProvider.notifier);
    final tokens = AppTokens.of(context);
    final mediaQuery = MediaQuery.of(context);

    if (state.successNo != null) {
      return _buildSuccess(context, state.successNo!, tokens);
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                height: 4, width: 40,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: EdgeInsets.fromLTRB(tokens.space16, 0, tokens.space16, tokens.space12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rezervasyon Yap',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textStrong)),
                          Text(business.name,
                            style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.muted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              // Form
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.all(tokens.space16),
                  children: [
                    _Field(label: 'Ad Soyad *', child: TextField(
                      onChanged: (v) => ctrl.update((s) => s.copyWith(name: v)),
                      decoration: _inputDecoration('Adınız Soyadınız'),
                    )),
                    SizedBox(height: tokens.space12),
                    _Field(label: 'Telefon *', child: TextField(
                      keyboardType: TextInputType.phone,
                      onChanged: (v) => ctrl.update((s) => s.copyWith(phone: v)),
                      decoration: _inputDecoration('05xx xxx xx xx'),
                    )),
                    SizedBox(height: tokens.space12),
                    Row(children: [
                      Expanded(child: _Field(label: 'Tarih *', child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(const Duration(days: 1)),
                            firstDate: DateTime.now().add(const Duration(days: 1)),
                            lastDate: DateTime.now().add(const Duration(days: 30)),
                            locale: const Locale('tr', 'TR'),
                          );
                          if (picked != null) ctrl.update((s) => s.copyWith(date: picked));
                        },
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(12),
                            color: AppColors.bgSubtle,
                          ),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            state.date == null
                                ? 'Tarih Seçin'
                                : '${state.date!.day}.${state.date!.month}.${state.date!.year}',
                            style: TextStyle(
                              color: state.date == null ? AppColors.muted : AppColors.textStrong,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ))),
                      SizedBox(width: tokens.space12),
                      Expanded(child: _Field(label: 'Saat *', child: InkWell(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 19, minute: 0),
                          );
                          if (picked != null) {
                            final h = picked.hour.toString().padLeft(2, '0');
                            final m = picked.minute.toString().padLeft(2, '0');
                            ctrl.update((s) => s.copyWith(time: '$h:$m'));
                          }
                        },
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(12),
                            color: AppColors.bgSubtle,
                          ),
                          alignment: Alignment.centerLeft,
                          child: Text(state.time,
                            style: const TextStyle(color: AppColors.textStrong, fontSize: 14)),
                        ),
                      ))),
                    ]),
                    SizedBox(height: tokens.space12),
                    _Field(label: 'Kişi Sayısı * (${business.reservationMinParty}–${business.reservationMaxParty})',
                      child: Row(
                        children: [
                          _StepButton(
                            icon: Icons.remove,
                            onTap: () {
                              if (state.partySize > business.reservationMinParty) {
                                ctrl.update((s) => s.copyWith(partySize: s.partySize - 1));
                              }
                            },
                          ),
                          Expanded(child: Center(
                            child: Text('${state.partySize} Kişi',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textStrong)),
                          )),
                          _StepButton(
                            icon: Icons.add,
                            onTap: () {
                              if (state.partySize < business.reservationMaxParty) {
                                ctrl.update((s) => s.copyWith(partySize: s.partySize + 1));
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: tokens.space12),
                    _Field(label: 'Özel İstek', child: TextField(
                      maxLines: 2,
                      onChanged: (v) => ctrl.update((s) => s.copyWith(specialRequest: v)),
                      decoration: _inputDecoration('Allerji, masa tercihi, özel gün vb.'),
                    )),
                    if (business.reservationNote != null) ...[
                      SizedBox(height: tokens.space12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Text(business.reservationNote!,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF92400E))),
                      ),
                    ],
                    if (state.error != null) ...[
                      SizedBox(height: tokens.space12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(state.error!,
                          style: const TextStyle(fontSize: 13, color: Color(0xFFDC2626), fontWeight: FontWeight.w700)),
                      ),
                    ],
                    SizedBox(height: tokens.space24 + mediaQuery.padding.bottom),
                  ],
                ),
              ),
              // Submit button
              Padding(
                padding: EdgeInsets.fromLTRB(
                  tokens.space16, tokens.space12, tokens.space16,
                  tokens.space16 + mediaQuery.padding.bottom,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: state.pending ? null : () => ctrl.submit(business),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: state.pending
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Rezervasyon Yap',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSuccess(BuildContext context, String no, AppTokensData tokens) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.all(tokens.space24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 24),
          Container(
            width: 72, height: 72,
            decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
            child: const Icon(Icons.check, color: Color(0xFF16A34A), size: 36),
          ),
          const SizedBox(height: 16),
          const Text('Rezervasyonunuz Alındı!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textStrong)),
          const SizedBox(height: 8),
          Text('Rezervasyon No: $no',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.muted)),
          const SizedBox(height: 12),
          const Text('İşletme en kısa sürede onaylayacak.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.muted)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kapat'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
  filled: true,
  fillColor: AppColors.bgSubtle,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.border),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.border),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.primary),
  ),
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
);

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: AppColors.textStrong),
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/features/business/ui/reservation_sheet.dart
```

- [ ] **Step 3: Commit**

```bash
git add uygulamalar/mobil/lib/features/business/ui/reservation_sheet.dart
git commit -m "feat(mobile): ReservationSheet bottom sheet eklendi"
```

---

## Task 8: Mobil — Business detail'e "Rezervasyon Yap" butonu ekle

**Files:**
- Modify: `uygulamalar/mobil/lib/features/business/ui/sections/business_detail_sections.dart`

- [ ] **Step 1: Import ekle ve `ReservationSection` widget oluştur**

`business_detail_sections.dart` başına `reservation_sheet.dart` import'u ekle:
```dart
import '../reservation_sheet.dart';
```

Dosyanın sonuna şu widget'ı ekle:

```dart
class ReservationSection extends StatelessWidget {
  const ReservationSection({super.key, required this.business});
  final Business business;

  @override
  Widget build(BuildContext context) {
    if (!business.acceptsReservations) return const SizedBox.shrink();
    final tokens = AppTokens.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.calendar_today_outlined, color: AppColors.primary, size: 20),
            SizedBox(width: tokens.space8),
            const Text('Rezervasyon',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textStrong)),
          ]),
          SizedBox(height: tokens.space8),
          const Text('Masanızı önceden ayırtın, bekleme olmadan gelin.',
            style: TextStyle(fontSize: 13, color: AppColors.muted)),
          if (business.reservationNote != null) ...[
            SizedBox(height: tokens.space8),
            Text(business.reservationNote!,
              style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ],
          SizedBox(height: tokens.space16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => showReservationSheet(context, business),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Rezervasyon Yap',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            ),
          ),
          if (business.reservationPhone != null) ...[
            SizedBox(height: tokens.space8),
            Center(child: Text('Telefon: ${business.reservationPhone}',
              style: const TextStyle(fontSize: 12, color: AppColors.muted))),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: `BusinessHeaderSection` veya `_BusinessSectionsScroll` içine `ReservationSection` ekle**

`business_detail_sections.dart` içindeki `BusinessHeaderSection.build()` metoduna, son `_BusinessHeaderCompactContainer`'dan sonra ekle:

```dart
// BusinessHeaderSection.build() içinde children listesi:
children: [
  _BusinessIdentityCard(business: business),
  const SizedBox(height: 8),
  _BusinessHeaderCompactContainer(business: business),
  const SizedBox(height: 8),
  ReservationSection(business: business),  // ← YENİ
],
```

- [ ] **Step 3: Analyze**

```bash
flutter analyze lib/features/business/
```

Beklenen: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add uygulamalar/mobil/lib/features/business/ui/sections/business_detail_sections.dart
git commit -m "feat(mobile): business detaya Rezervasyon Yap butonu eklendi"
```

---

## Self-Review Checklistesi

**Spec coverage:**
- [x] Task 1: DB tablosu + rezervasyon ayar kolonları + 3 RPC (create, list, status update)
- [x] Task 2: Web — `pazar-okuma.ts` select güncellendi, prop'lar geçildi
- [x] Task 3: Web — müşteri `ReservasyonFormu` bileşeni + server action
- [x] Task 4: Web — owner panel gerçek DB'ye bağlandı
- [x] Task 5: Mobil — `Business` modeli güncellendi
- [x] Task 6: Mobil — `ReservationRepository` oluşturuldu
- [x] Task 7: Mobil — `ReservationSheet` bottom sheet
- [x] Task 8: Mobil — business detail'e buton eklendi

**Tip tutarlılığı:**
- `create_reservation_v1` RPC imzası → `submitReservation()` method params → form field names → hepsi eşleşiyor ✓
- `DbReservation.status` union → `STATUS_MAP` → `Status` tip → `STATUS_STYLES` → hepsi 4 değeri kapsıyor ✓
- `Business.reservationMinParty/MaxParty` → `_ReservationController.submit()` validation → form UI stepper → tutarlı ✓
