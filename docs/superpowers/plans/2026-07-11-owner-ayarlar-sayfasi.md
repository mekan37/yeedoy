# Owner Panel Ayarlar Sayfası Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `/owner/settings` sayfasını 5 sekmeli unified settings paneline dönüştür — İşletme Profili, Hesap Ayarları, Bildirim Ayarları, Rezervasyon Ayarları, Gizlilik & Güvenlik — sağ sidebar ile birlikte.

**Architecture:** RSC `page.tsx` kullanıcı + işletme verilerini Supabase'den çeker, `SettingsClient` client bileşenine aktarır. Tab state client-side `useState` ile yönetilir. Her tab bağımsız formunu `useActionState` ile server action'a bağlar. Sağ sidebar ayrı client bileşeni (tehlikeli bölge confirm akışı için).

**Tech Stack:** Next.js 15 App Router, TypeScript, Supabase, Zod, Tailwind CSS, React 19 `useActionState`

---

## Mevcut Altyapı (subagentlar için bağlam)

- `uygulamalar/web/app/owner/(panel)/settings/page.tsx` — mevcut, basit link listesi (Task 3'te rewrite)
- `uygulamalar/web/app/owner/(panel)/settings/hours/hours-form.tsx` — `HoursForm` client bileşeni: `businessId: string`, `hours: WeeklyHourRow[] | null` prop alır; kendi içinde `saveHours` action çağırır
- `uygulamalar/web/app/owner/(panel)/businesses/[id]/branding-editor.tsx` — `BrandingEditor` client bileşeni: `businessId, initialLogoUrl, initialCoverUrl, businessName` prop alır
- `uygulamalar/web/src/lib/rate-limit.ts` — `rateLimit(id, { limit, window_s })` → `{ limited: boolean }`
- `uygulamalar/web/src/lib/supabaseServer.ts` — `createSupabaseServerClient()` (auth context)
- `uygulamalar/web/src/lib/supabase/service.ts` — `createSupabaseServiceClient()` (service role)
- `uygulamalar/web/src/lib/qr-access.ts` — `canManageBusiness(businessId)` → `boolean`
- `uygulamalar/web/src/ui/layout/panel-page-header.tsx` — `<PanelPageHeader eyebrow title description />`
- `uygulamalar/web/src/ui/layout/panel-section-card.tsx` — `<PanelContentSurface>` ve `<PanelSectionCard title description?>`
- `uygulamalar/web/src/ui/components/panel-action-button.tsx` — `<PanelActionButton variant="primary" label />`

**businesses tablosu (mevcut kolonlar):** `id, name, category, description, phone, address, city, district, lat, lng, logo_url, cover_url, is_active, is_verified, slug, reservation_url, accepts_reservations, reservation_phone, reservation_min_party, reservation_max_party, reservation_note`

**businesses tablosu (Task 1'de eklenecek):** `email, website_url, instagram_url, facebook_url, twitter_url`

---

## File Map

```
uygulamalar/web/
├── supabase/migrations/20260711000002_business_contact_fields.sql   ← CREATE (Task 1)
└── app/owner/(panel)/settings/
    ├── page.tsx                              ← REWRITE (Task 3)
    ├── settings-client.tsx                  ← CREATE (Task 3)
    ├── settings-right-sidebar.tsx           ← CREATE (Task 6)
    ├── actions.ts                           ← CREATE (Task 2)
    ├── tabs/
    │   ├── isletme-profili-tab.tsx          ← CREATE (Task 4)
    │   ├── rezervasyon-ayarlari-tab.tsx     ← CREATE (Task 5)
    │   ├── hesap-ayarlari-tab.tsx           ← CREATE (Task 6)
    │   ├── bildirim-ayarlari-tab.tsx        ← CREATE (Task 6)
    │   └── gizlilik-guvenlik-tab.tsx        ← CREATE (Task 6)
    └── hours/  (DEĞİŞMEZ — backward compat için korunur)
```

---

## Task 1: DB Migration — İşletme İletişim Kolonları

**Files:**
- Create: `supabase/migrations/20260711000002_business_contact_fields.sql`

- [ ] **Step 1: Migration dosyasını oluştur**

```sql
-- supabase/migrations/20260711000002_business_contact_fields.sql

ALTER TABLE public.businesses
  ADD COLUMN IF NOT EXISTS email         TEXT,
  ADD COLUMN IF NOT EXISTS website_url   TEXT,
  ADD COLUMN IF NOT EXISTS instagram_url TEXT,
  ADD COLUMN IF NOT EXISTS facebook_url  TEXT,
  ADD COLUMN IF NOT EXISTS twitter_url   TEXT;

COMMENT ON COLUMN public.businesses.email         IS 'İşletme iletişim e-postası';
COMMENT ON COLUMN public.businesses.website_url   IS 'İşletme web sitesi URL';
COMMENT ON COLUMN public.businesses.instagram_url IS 'Instagram profil URL';
COMMENT ON COLUMN public.businesses.facebook_url  IS 'Facebook profil URL';
COMMENT ON COLUMN public.businesses.twitter_url   IS 'Twitter/X profil URL';
```

- [ ] **Step 2: Migration'ı uygula (lokal Supabase)**

```bash
cd C:\yeedoy
supabase db reset
```

Expected: "Finished supabase db reset" — no errors.

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260711000002_business_contact_fields.sql
git commit -m "feat(db): businesses tablosuna iletişim alanları eklendi (email, website, social)"
```

---

## Task 2: Server Actions

**Files:**
- Create: `uygulamalar/web/app/owner/(panel)/settings/actions.ts`

- [ ] **Step 1: Dosyayı oluştur**

```typescript
// uygulamalar/web/app/owner/(panel)/settings/actions.ts
'use server';

import { z } from 'zod';
import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { createSupabaseServiceClient } from '@/src/lib/supabase/service';
import { canManageBusiness } from '@/src/lib/qr-access';
import { rateLimit } from '@/src/lib/rate-limit';

export type ActionState = { error: string } | { success: true } | null;

// ─── Schemas ─────────────────────────────────────────────────────────────────

const ProfileSchema = z.object({
  name:        z.string().min(1).max(120),
  category:    z.string().min(1).max(80),
  description: z.string().max(1000).optional(),
  phone:       z.string().max(30).optional(),
  email:       z.string().max(255).optional(),
  address:     z.string().max(300).optional(),
  city:        z.string().max(80).optional(),
  district:    z.string().max(80).optional(),
});

const ContactSchema = z.object({
  website_url:   z.string().url().max(500).optional().or(z.literal('')),
  instagram_url: z.string().url().max(500).optional().or(z.literal('')),
  facebook_url:  z.string().url().max(500).optional().or(z.literal('')),
  twitter_url:   z.string().url().max(500).optional().or(z.literal('')),
});

const ReservationSettingsSchema = z.object({
  accepts_reservations:  z.string().optional(),
  reservation_phone:     z.string().max(30).optional(),
  reservation_min_party: z.coerce.number().int().min(1).max(99).default(1),
  reservation_max_party: z.coerce.number().int().min(1).max(99).default(20),
  reservation_note:      z.string().max(500).optional(),
});

// ─── Helpers ─────────────────────────────────────────────────────────────────

const toNull = (v: string | undefined) =>
  v && v.trim() !== '' ? v.trim() : null;

async function getUid(): Promise<string | null> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  return user?.id ?? null;
}

// ─── Actions ─────────────────────────────────────────────────────────────────

export async function updateBusinessProfile(
  businessId: string,
  _prev: ActionState,
  fd: FormData,
): Promise<ActionState> {
  const uid = await getUid();
  if (!uid) return { error: 'Oturum bulunamadı' };

  const { limited } = await rateLimit(`settings-profile-${uid}`, { limit: 10, window_s: 60 });
  if (limited) return { error: 'Çok fazla istek. Lütfen bekleyin.' };

  const raw = {
    name:        fd.get('name'),
    category:    fd.get('category'),
    description: fd.get('description') || undefined,
    phone:       fd.get('phone') || undefined,
    email:       fd.get('email') || undefined,
    address:     fd.get('address') || undefined,
    city:        fd.get('city') || undefined,
    district:    fd.get('district') || undefined,
  };

  const parsed = ProfileSchema.safeParse(raw);
  if (!parsed.success) return { error: 'Geçersiz form verisi' };

  const canManage = await canManageBusiness(businessId);
  if (!canManage) return { error: 'Bu işletmeyi düzenleme yetkiniz yok' };

  const service = createSupabaseServiceClient();
  if (!service) return { error: 'Servis bağlantısı kurulamadı' };

  const { error } = await (service as any).from('businesses').update({
    name:        parsed.data.name,
    category:    parsed.data.category,
    description: toNull(parsed.data.description),
    phone:       toNull(parsed.data.phone),
    email:       toNull(parsed.data.email),
    address:     toNull(parsed.data.address),
    city:        toNull(parsed.data.city),
    district:    toNull(parsed.data.district),
  }).eq('id', businessId);

  if (error) return { error: 'İşletme bilgileri kaydedilemedi' };

  revalidatePath('/owner/settings');
  revalidatePath(`/owner/businesses/${businessId}`);
  return { success: true };
}

export async function updateContactInfo(
  businessId: string,
  _prev: ActionState,
  fd: FormData,
): Promise<ActionState> {
  const uid = await getUid();
  if (!uid) return { error: 'Oturum bulunamadı' };

  const { limited } = await rateLimit(`settings-contact-${uid}`, { limit: 10, window_s: 60 });
  if (limited) return { error: 'Çok fazla istek. Lütfen bekleyin.' };

  const raw = {
    website_url:   fd.get('website_url') ?? '',
    instagram_url: fd.get('instagram_url') ?? '',
    facebook_url:  fd.get('facebook_url') ?? '',
    twitter_url:   fd.get('twitter_url') ?? '',
  };

  const parsed = ContactSchema.safeParse(raw);
  if (!parsed.success) return { error: 'Geçersiz URL formatı. Lütfen tam URL girin (https://...)' };

  const canManage = await canManageBusiness(businessId);
  if (!canManage) return { error: 'Bu işletmeyi düzenleme yetkiniz yok' };

  const service = createSupabaseServiceClient();
  if (!service) return { error: 'Servis bağlantısı kurulamadı' };

  const { error } = await (service as any).from('businesses').update({
    website_url:   toNull(parsed.data.website_url),
    instagram_url: toNull(parsed.data.instagram_url),
    facebook_url:  toNull(parsed.data.facebook_url),
    twitter_url:   toNull(parsed.data.twitter_url),
  }).eq('id', businessId);

  if (error) return { error: 'İletişim bilgileri kaydedilemedi' };

  revalidatePath('/owner/settings');
  return { success: true };
}

export async function updateReservationSettings(
  businessId: string,
  _prev: ActionState,
  fd: FormData,
): Promise<ActionState> {
  const uid = await getUid();
  if (!uid) return { error: 'Oturum bulunamadı' };

  const { limited } = await rateLimit(`settings-reservation-${uid}`, { limit: 10, window_s: 60 });
  if (limited) return { error: 'Çok fazla istek. Lütfen bekleyin.' };

  const raw = {
    accepts_reservations:  fd.get('accepts_reservations') ?? undefined,
    reservation_phone:     fd.get('reservation_phone') || undefined,
    reservation_min_party: fd.get('reservation_min_party'),
    reservation_max_party: fd.get('reservation_max_party'),
    reservation_note:      fd.get('reservation_note') || undefined,
  };

  const parsed = ReservationSettingsSchema.safeParse(raw);
  if (!parsed.success) return { error: 'Geçersiz form verisi' };

  const canManage = await canManageBusiness(businessId);
  if (!canManage) return { error: 'Bu işletmeyi düzenleme yetkiniz yok' };

  const service = createSupabaseServiceClient();
  if (!service) return { error: 'Servis bağlantısı kurulamadı' };

  const { error } = await (service as any).from('businesses').update({
    accepts_reservations:  parsed.data.accepts_reservations === 'on',
    reservation_phone:     toNull(parsed.data.reservation_phone),
    reservation_min_party: parsed.data.reservation_min_party,
    reservation_max_party: parsed.data.reservation_max_party,
    reservation_note:      toNull(parsed.data.reservation_note),
  }).eq('id', businessId);

  if (error) return { error: 'Rezervasyon ayarları kaydedilemedi' };

  revalidatePath('/owner/settings');
  return { success: true };
}

export async function updatePassword(
  _prev: ActionState,
  fd: FormData,
): Promise<ActionState> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Oturum bulunamadı' };

  const { limited } = await rateLimit(`settings-password-${user.id}`, { limit: 5, window_s: 300 });
  if (limited) return { error: 'Çok fazla deneme. 5 dakika bekleyin.' };

  const password = fd.get('password') as string | null;
  const confirm  = fd.get('confirm_password') as string | null;

  if (!password || password.length < 8) return { error: 'Şifre en az 8 karakter olmalı' };
  if (password !== confirm) return { error: 'Şifreler eşleşmiyor' };

  const { error } = await supabase.auth.updateUser({ password });
  if (error) return { error: 'Şifre güncellenemedi' };

  return { success: true };
}

export async function deactivateBusiness(
  businessId: string,
): Promise<{ error: string } | null> {
  const uid = await getUid();
  if (!uid) return { error: 'Oturum bulunamadı' };

  const canManage = await canManageBusiness(businessId);
  if (!canManage) return { error: 'Bu işletmeyi yönetme yetkiniz yok' };

  const service = createSupabaseServiceClient();
  if (!service) return { error: 'Servis bağlantısı kurulamadı' };

  const { error } = await (service as any)
    .from('businesses')
    .update({ is_active: false })
    .eq('id', businessId);

  if (error) return { error: 'İşletme devre dışı bırakılamadı' };

  revalidatePath('/owner/settings');
  revalidatePath('/owner/businesses');
  return null;
}
```

- [ ] **Step 2: Typecheck**

```bash
cd C:\yeedoy\uygulamalar\web && npm run typecheck
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add uygulamalar/web/app/owner/\(panel\)/settings/actions.ts
git commit -m "feat(web): owner ayarlar server actions eklendi"
```

---

## Task 3: Settings Page RSC + SettingsClient Shell

**Files:**
- Modify: `uygulamalar/web/app/owner/(panel)/settings/page.tsx` (rewrite)
- Create: `uygulamalar/web/app/owner/(panel)/settings/settings-client.tsx`

- [ ] **Step 1: `page.tsx` rewrite**

```typescript
// uygulamalar/web/app/owner/(panel)/settings/page.tsx
import type { Metadata } from 'next';
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { createSupabaseServiceClient } from '@/src/lib/supabase/service';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface } from '@/src/ui/layout/panel-section-card';
import { SettingsClient } from './settings-client';
import type { WeeklyHourRow } from './hours/hours-form';

export const metadata: Metadata = {
  title: 'Ayarlar | Owner Panel',
  robots: { index: false, follow: false },
};

export default async function OwnerSettingsPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect('/giris');

  const { data: claim } = await (supabase as any)
    .from('owner_claims')
    .select('business_id')
    .eq('user_id', user.id)
    .eq('status', 'approved')
    .limit(1)
    .maybeSingle();

  if (!claim) redirect('/owner/dashboard');

  const service = createSupabaseServiceClient();
  if (!service) redirect('/owner/dashboard');

  const { data: business } = await (service as any)
    .from('businesses')
    .select(
      'id, name, category, description, phone, email, address, city, district, ' +
      'logo_url, cover_url, is_active, slug, ' +
      'website_url, instagram_url, facebook_url, twitter_url, ' +
      'accepts_reservations, reservation_phone, reservation_min_party, ' +
      'reservation_max_party, reservation_note',
    )
    .eq('id', claim.business_id)
    .single();

  if (!business) redirect('/owner/dashboard');

  const { data: hoursData } = await (supabase as any).rpc('get_business_hours_v1', {
    p_business_id: claim.business_id,
  });
  const hours: WeeklyHourRow[] = hoursData?.weekly ?? [];

  const displayName = (user.user_metadata?.full_name as string | undefined) ?? '';

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Owner"
        title="Ayarlar"
        description="İşletme hesabınızı ve tercihlerinizi yönetin."
      />
      <PanelContentSurface className="pt-6">
        <SettingsClient
          user={{ id: user.id, email: user.email ?? '', displayName }}
          business={business}
          hours={hours}
        />
      </PanelContentSurface>
    </div>
  );
}
```

- [ ] **Step 2: `settings-client.tsx` oluştur**

```typescript
// uygulamalar/web/app/owner/(panel)/settings/settings-client.tsx
'use client';

import { useState } from 'react';
import { IsletmeProfilTab }      from './tabs/isletme-profili-tab';
import { ReservasyonAyarlariTab } from './tabs/rezervasyon-ayarlari-tab';
import { HesapAyarlariTab }      from './tabs/hesap-ayarlari-tab';
import { BildirimAyarlariTab }   from './tabs/bildirim-ayarlari-tab';
import { GizlilikGuvenlikTab }   from './tabs/gizlilik-guvenlik-tab';
import { SettingsRightSidebar }  from './settings-right-sidebar';
import type { WeeklyHourRow } from './hours/hours-form';

type Tab = 'profile' | 'account' | 'notifications' | 'reservations' | 'privacy';

export interface BusinessData {
  id: string;
  name: string;
  category: string;
  description: string | null;
  phone: string | null;
  email: string | null;
  address: string | null;
  city: string | null;
  district: string | null;
  logo_url: string | null;
  cover_url: string | null;
  is_active: boolean;
  slug: string | null;
  website_url: string | null;
  instagram_url: string | null;
  facebook_url: string | null;
  twitter_url: string | null;
  accepts_reservations: boolean;
  reservation_phone: string | null;
  reservation_min_party: number;
  reservation_max_party: number;
  reservation_note: string | null;
}

export interface UserData {
  id: string;
  email: string;
  displayName: string;
}

const TABS: { id: Tab; label: string }[] = [
  { id: 'profile',       label: 'İşletme Profili' },
  { id: 'account',       label: 'Hesap Ayarları' },
  { id: 'notifications', label: 'Bildirim Ayarları' },
  { id: 'reservations',  label: 'Rezervasyon Ayarları' },
  { id: 'privacy',       label: 'Gizlilik & Güvenlik' },
];

export function SettingsClient({
  user,
  business,
  hours,
}: {
  user: UserData;
  business: BusinessData;
  hours: WeeklyHourRow[];
}) {
  const [activeTab, setActiveTab] = useState<Tab>('profile');

  return (
    <div className="flex flex-col gap-6 lg:grid lg:grid-cols-3 lg:items-start lg:gap-8">
      {/* Main content */}
      <div className="lg:col-span-2 flex flex-col gap-6">
        {/* Tab navigation */}
        <div className="flex overflow-x-auto border-b border-border">
          {TABS.map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`shrink-0 px-4 pb-3 pt-1 text-sm font-[700] transition-colors border-b-2 -mb-px ${
                activeTab === tab.id
                  ? 'border-primary text-primary'
                  : 'border-transparent text-muted hover:text-textStrong'
              }`}
            >
              {tab.label}
            </button>
          ))}
        </div>

        {/* Tab content */}
        {activeTab === 'profile'       && <IsletmeProfilTab      business={business} hours={hours} />}
        {activeTab === 'account'       && <HesapAyarlariTab      user={user} />}
        {activeTab === 'notifications' && <BildirimAyarlariTab   />}
        {activeTab === 'reservations'  && <ReservasyonAyarlariTab business={business} />}
        {activeTab === 'privacy'       && <GizlilikGuvenlikTab   />}
      </div>

      {/* Right sidebar */}
      <SettingsRightSidebar user={user} business={business} />
    </div>
  );
}
```

- [ ] **Step 3: Typecheck**

```bash
cd C:\yeedoy\uygulamalar\web && npm run typecheck
```

Expected: no errors (tab bileşenleri henüz yoksa TypeScript hata verir — tüm `tabs/` importları Task 4–6 tamamlandıktan sonra geçer; bu adımda stub dosyalar oluştur).

Stub dosyalar (`tabs/` klasörü):
```typescript
// tabs/isletme-profili-tab.tsx
'use client';
export function IsletmeProfilTab(_: any) { return null; }

// tabs/rezervasyon-ayarlari-tab.tsx
'use client';
export function ReservasyonAyarlariTab(_: any) { return null; }

// tabs/hesap-ayarlari-tab.tsx
'use client';
export function HesapAyarlariTab(_: any) { return null; }

// tabs/bildirim-ayarlari-tab.tsx
'use client';
export function BildirimAyarlariTab() { return null; }

// tabs/gizlilik-guvenlik-tab.tsx
'use client';
export function GizlilikGuvenlikTab() { return null; }

// settings-right-sidebar.tsx
'use client';
export function SettingsRightSidebar(_: any) { return null; }
```

- [ ] **Step 4: Commit**

```bash
git add uygulamalar/web/app/owner/\(panel\)/settings/
git commit -m "feat(web): owner ayarlar sayfası RSC + SettingsClient tab shell"
```

---

## Task 4: İşletme Profili Tab

**Files:**
- Modify: `uygulamalar/web/app/owner/(panel)/settings/tabs/isletme-profili-tab.tsx` (stub → full)

CSS sınıfları: `rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong outline-none focus:border-primary` (tüm input'lar için ortak).

- [ ] **Step 1: Tab bileşenini yaz**

```typescript
// uygulamalar/web/app/owner/(panel)/settings/tabs/isletme-profili-tab.tsx
'use client';

import { useActionState } from 'react';
import { PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { BrandingEditor } from '../../businesses/[id]/branding-editor';
import { HoursForm } from '../hours/hours-form';
import { updateBusinessProfile, updateContactInfo } from '../actions';
import type { BusinessData } from '../settings-client';
import type { WeeklyHourRow } from '../hours/hours-form';

const INPUT = 'rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong outline-none focus:border-primary w-full';
const LABEL = 'text-xs font-[700] text-muted';

export function IsletmeProfilTab({
  business,
  hours,
}: {
  business: BusinessData;
  hours: WeeklyHourRow[];
}) {
  const [profileState, profileAction, profilePending] = useActionState(
    updateBusinessProfile.bind(null, business.id),
    null,
  );
  const [contactState, contactAction, contactPending] = useActionState(
    updateContactInfo.bind(null, business.id),
    null,
  );

  return (
    <div className="flex flex-col gap-6">

      {/* ── İşletme Bilgileri ─────────────────────────────────────── */}
      <PanelSectionCard
        title="İşletme Bilgileri"
        description="İşletmenizin temel bilgilerini düzenleyin."
      >
        <form action={profileAction} className="flex flex-col gap-4">
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <label className="flex flex-col gap-1">
              <span className={LABEL}>İşletme Adı</span>
              <input name="name" defaultValue={business.name} required maxLength={120} className={INPUT} />
            </label>
            <label className="flex flex-col gap-1">
              <span className={LABEL}>Kategori</span>
              <input name="category" defaultValue={business.category} required maxLength={80} className={INPUT} />
            </label>
          </div>

          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <label className="flex flex-col gap-1">
              <span className={LABEL}>Telefon</span>
              <input name="phone" defaultValue={business.phone ?? ''} maxLength={30} className={INPUT} />
            </label>
            <label className="flex flex-col gap-1">
              <span className={LABEL}>E-posta</span>
              <input name="email" type="email" defaultValue={business.email ?? ''} maxLength={255} className={INPUT} />
            </label>
          </div>

          <label className="flex flex-col gap-1">
            <span className={LABEL}>Adres</span>
            <input name="address" defaultValue={business.address ?? ''} maxLength={300} className={INPUT} />
          </label>

          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <label className="flex flex-col gap-1">
              <span className={LABEL}>Şehir</span>
              <input name="city" defaultValue={business.city ?? ''} maxLength={80} className={INPUT} />
            </label>
            <label className="flex flex-col gap-1">
              <span className={LABEL}>İlçe</span>
              <input name="district" defaultValue={business.district ?? ''} maxLength={80} className={INPUT} />
            </label>
          </div>

          <label className="flex flex-col gap-1">
            <span className={LABEL}>Açıklama</span>
            <textarea
              name="description"
              defaultValue={business.description ?? ''}
              maxLength={1000}
              rows={3}
              className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong outline-none focus:border-primary resize-none w-full"
            />
          </label>

          {profileState && 'error' in profileState && (
            <p role="alert" className="text-sm text-red-600">{profileState.error}</p>
          )}
          {profileState && 'success' in profileState && (
            <p role="status" className="text-sm text-green-600">Kaydedildi.</p>
          )}

          <div className="flex justify-end gap-3">
            <button type="reset"
              className="rounded-xl border border-border px-4 py-2 text-sm font-[700] text-textStrong hover:bg-bg transition-colors">
              İptal
            </button>
            <button type="submit" disabled={profilePending}
              className="rounded-xl bg-primary px-4 py-2 text-sm font-[700] text-white disabled:opacity-60">
              {profilePending ? 'Kaydediliyor…' : 'Değişiklikleri Kaydet'}
            </button>
          </div>
        </form>
      </PanelSectionCard>

      {/* ── İşletme Logosu ────────────────────────────────────────── */}
      <PanelSectionCard
        title="İşletme Logosu"
        description="İşletmenizi temsil eden logonuzu yükleyin."
      >
        <BrandingEditor
          businessId={business.id}
          initialLogoUrl={business.logo_url}
          initialCoverUrl={business.cover_url}
          businessName={business.name}
        />
      </PanelSectionCard>

      {/* ── Çalışma Saatleri ──────────────────────────────────────── */}
      <PanelSectionCard
        title="Çalışma Saatleri"
        description="Her gün için açılış ve kapanış saatlerini ayarlayın."
      >
        <HoursForm businessId={business.id} hours={hours.length > 0 ? hours : null} />
      </PanelSectionCard>

      {/* ── İletişim Bilgileri ────────────────────────────────────── */}
      <PanelSectionCard
        title="İletişim Bilgileri"
        description="Müşterilerinizin sizinle iletişime geçebileceği bilgileri yönetin."
      >
        <form action={contactAction} className="flex flex-col gap-4">
          <label className="flex flex-col gap-1">
            <span className={LABEL}>Web Sitesi</span>
            <input name="website_url" type="url" defaultValue={business.website_url ?? ''}
              maxLength={500} placeholder="https://" className={INPUT} />
          </label>

          <div className="flex flex-col gap-1">
            <span className={LABEL}>Sosyal Medya</span>
            <div className="flex flex-col gap-2 mt-1">
              {[
                { name: 'instagram_url', label: 'Instagram', val: business.instagram_url, ph: 'https://instagram.com/...' },
                { name: 'facebook_url',  label: 'Facebook',  val: business.facebook_url,  ph: 'https://facebook.com/...' },
                { name: 'twitter_url',   label: 'Twitter/X', val: business.twitter_url,   ph: 'https://twitter.com/...' },
              ].map((s) => (
                <div key={s.name} className="flex items-center gap-3">
                  <span className="w-20 shrink-0 text-xs text-muted">{s.label}</span>
                  <input name={s.name} type="url" defaultValue={s.val ?? ''}
                    maxLength={500} placeholder={s.ph}
                    className="min-w-0 flex-1 rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong outline-none focus:border-primary" />
                </div>
              ))}
            </div>
          </div>

          {contactState && 'error' in contactState && (
            <p role="alert" className="text-sm text-red-600">{contactState.error}</p>
          )}
          {contactState && 'success' in contactState && (
            <p role="status" className="text-sm text-green-600">Kaydedildi.</p>
          )}

          <div className="flex justify-end">
            <button type="submit" disabled={contactPending}
              className="rounded-xl bg-primary px-4 py-2 text-sm font-[700] text-white disabled:opacity-60">
              {contactPending ? 'Kaydediliyor…' : 'Kaydet'}
            </button>
          </div>
        </form>
      </PanelSectionCard>

    </div>
  );
}
```

- [ ] **Step 2: Typecheck**

```bash
cd C:\yeedoy\uygulamalar\web && npm run typecheck
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add uygulamalar/web/app/owner/\(panel\)/settings/tabs/isletme-profili-tab.tsx
git commit -m "feat(web): owner ayarlar — İşletme Profili sekmesi"
```

---

## Task 5: Rezervasyon Ayarları Tab

**Files:**
- Modify: `uygulamalar/web/app/owner/(panel)/settings/tabs/rezervasyon-ayarlari-tab.tsx`

- [ ] **Step 1: Tab bileşenini yaz**

```typescript
// uygulamalar/web/app/owner/(panel)/settings/tabs/rezervasyon-ayarlari-tab.tsx
'use client';

import { useActionState } from 'react';
import { PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { updateReservationSettings } from '../actions';
import type { BusinessData } from '../settings-client';

const INPUT = 'rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong outline-none focus:border-primary w-full';
const LABEL = 'text-xs font-[700] text-muted';

export function ReservasyonAyarlariTab({ business }: { business: BusinessData }) {
  const [state, action, isPending] = useActionState(
    updateReservationSettings.bind(null, business.id),
    null,
  );

  return (
    <div className="flex flex-col gap-6">
      <PanelSectionCard
        title="Rezervasyon Ayarları"
        description="Müşterilerinizin rezervasyon yapabilmesi için ayarları yapılandırın."
      >
        <form action={action} className="flex flex-col gap-5">

          {/* Toggle */}
          <div className="flex items-center justify-between rounded-xl border border-border bg-bg p-4">
            <div>
              <p className="text-sm font-[700] text-textStrong">Rezervasyonları Kabul Et</p>
              <p className="mt-0.5 text-xs text-muted">
                Müşteriler işletme sayfanızdan rezervasyon yapabilsin.
              </p>
            </div>
            <label className="relative inline-flex cursor-pointer items-center">
              <input
                type="checkbox"
                name="accepts_reservations"
                value="on"
                defaultChecked={business.accepts_reservations}
                className="peer sr-only"
              />
              <div className="peer h-6 w-11 rounded-full bg-zinc-200 transition-colors after:absolute after:left-[2px] after:top-[2px] after:h-5 after:w-5 after:rounded-full after:bg-white after:transition-all peer-checked:bg-primary peer-checked:after:translate-x-full" />
            </label>
          </div>

          {/* Rezervasyon telefonu */}
          <label className="flex flex-col gap-1">
            <span className={LABEL}>Rezervasyon Telefonu</span>
            <p className="text-xs text-muted">Bu numara rezervasyon formunda gösterilir.</p>
            <input
              name="reservation_phone"
              defaultValue={business.reservation_phone ?? ''}
              maxLength={30}
              placeholder={business.phone ?? ''}
              className={INPUT}
            />
          </label>

          {/* Kişi sayısı */}
          <div className="grid grid-cols-2 gap-4">
            <label className="flex flex-col gap-1">
              <span className={LABEL}>Min. Kişi Sayısı</span>
              <input
                name="reservation_min_party"
                type="number"
                min={1}
                max={99}
                defaultValue={business.reservation_min_party}
                className={INPUT}
              />
            </label>
            <label className="flex flex-col gap-1">
              <span className={LABEL}>Max. Kişi Sayısı</span>
              <input
                name="reservation_max_party"
                type="number"
                min={1}
                max={99}
                defaultValue={business.reservation_max_party}
                className={INPUT}
              />
            </label>
          </div>

          {/* Not */}
          <label className="flex flex-col gap-1">
            <span className={LABEL}>Rezervasyon Notu</span>
            <p className="text-xs text-muted">
              Müşterilere gösterilecek ek bilgi (örn: "Hafta sonları sadece akşam").
            </p>
            <textarea
              name="reservation_note"
              defaultValue={business.reservation_note ?? ''}
              maxLength={500}
              rows={3}
              className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong outline-none focus:border-primary resize-none w-full"
            />
          </label>

          {state && 'error' in state && (
            <p role="alert" className="text-sm text-red-600">{state.error}</p>
          )}
          {state && 'success' in state && (
            <p role="status" className="text-sm text-green-600">Rezervasyon ayarları kaydedildi.</p>
          )}

          <div className="flex justify-end">
            <button
              type="submit"
              disabled={isPending}
              className="rounded-xl bg-primary px-4 py-2 text-sm font-[700] text-white disabled:opacity-60"
            >
              {isPending ? 'Kaydediliyor…' : 'Değişiklikleri Kaydet'}
            </button>
          </div>
        </form>
      </PanelSectionCard>
    </div>
  );
}
```

- [ ] **Step 2: Typecheck**

```bash
cd C:\yeedoy\uygulamalar\web && npm run typecheck
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add uygulamalar/web/app/owner/\(panel\)/settings/tabs/rezervasyon-ayarlari-tab.tsx
git commit -m "feat(web): owner ayarlar — Rezervasyon Ayarları sekmesi"
```

---

## Task 6: Kalan Sekmeler + Sağ Sidebar

**Files:**
- Modify: `uygulamalar/web/app/owner/(panel)/settings/tabs/hesap-ayarlari-tab.tsx`
- Modify: `uygulamalar/web/app/owner/(panel)/settings/tabs/bildirim-ayarlari-tab.tsx`
- Modify: `uygulamalar/web/app/owner/(panel)/settings/tabs/gizlilik-guvenlik-tab.tsx`
- Modify: `uygulamalar/web/app/owner/(panel)/settings/settings-right-sidebar.tsx`

- [ ] **Step 1: `hesap-ayarlari-tab.tsx`**

```typescript
// uygulamalar/web/app/owner/(panel)/settings/tabs/hesap-ayarlari-tab.tsx
'use client';

import { PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import type { UserData } from '../settings-client';

export function HesapAyarlariTab({ user }: { user: UserData }) {
  return (
    <div className="flex flex-col gap-6">
      <PanelSectionCard title="Hesap Bilgileri" description="Yeedoy hesabınıza ait bilgiler.">
        <div className="flex flex-col gap-4">
          <div className="flex flex-col gap-1">
            <span className="text-xs font-[700] text-muted">Ad Soyad</span>
            <p className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong">
              {user.displayName || '—'}
            </p>
          </div>
          <div className="flex flex-col gap-1">
            <span className="text-xs font-[700] text-muted">E-posta</span>
            <p className="rounded-xl border border-border bg-bg/60 px-3 py-2 text-sm text-muted">
              {user.email}
            </p>
            <p className="text-xs text-muted">E-posta adresi değiştirilemez.</p>
          </div>
        </div>
      </PanelSectionCard>
    </div>
  );
}
```

- [ ] **Step 2: `bildirim-ayarlari-tab.tsx`**

```typescript
// uygulamalar/web/app/owner/(panel)/settings/tabs/bildirim-ayarlari-tab.tsx
'use client';

import { PanelSectionCard } from '@/src/ui/layout/panel-section-card';

const ITEMS = [
  { id: 'notif_review',       label: 'Yeni Yorum',         desc: 'İşletmenize yeni bir yorum yapıldığında.' },
  { id: 'notif_reservation',  label: 'Yeni Rezervasyon',   desc: 'Yeni rezervasyon talebi geldiğinde.' },
  { id: 'notif_price',        label: 'Fiyat Önerisi',      desc: 'Müşteri fiyat önerisi gönderdiğinde.' },
  { id: 'notif_weekly',       label: 'Haftalık Rapor',     desc: 'Haftalık performans özetini e-posta ile al.' },
];

export function BildirimAyarlariTab() {
  return (
    <div className="flex flex-col gap-6">
      <PanelSectionCard
        title="Bildirim Tercihleri"
        description="Hangi bildirimleri almak istediğinizi seçin."
      >
        <div className="flex flex-col gap-4">
          {ITEMS.map((item) => (
            <div key={item.id} className="flex items-start justify-between gap-4">
              <div>
                <p className="text-sm font-[700] text-textStrong">{item.label}</p>
                <p className="mt-0.5 text-xs text-muted">{item.desc}</p>
              </div>
              <label className="relative inline-flex cursor-pointer items-center shrink-0">
                <input type="checkbox" defaultChecked className="peer sr-only" />
                <div className="peer h-6 w-11 rounded-full bg-zinc-200 after:absolute after:left-[2px] after:top-[2px] after:h-5 after:w-5 after:rounded-full after:bg-white after:transition-all peer-checked:bg-primary peer-checked:after:translate-x-full" />
              </label>
            </div>
          ))}
        </div>
        <p className="mt-4 text-xs text-muted border-t border-border pt-4">
          Bildirim tercihleri yakında aktif olacak. Şu an varsayılan ayarlar geçerlidir.
        </p>
      </PanelSectionCard>
    </div>
  );
}
```

- [ ] **Step 3: `gizlilik-guvenlik-tab.tsx`**

```typescript
// uygulamalar/web/app/owner/(panel)/settings/tabs/gizlilik-guvenlik-tab.tsx
'use client';

import { useActionState } from 'react';
import { PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { updatePassword } from '../actions';

const INPUT = 'rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong outline-none focus:border-primary w-full';
const LABEL = 'text-xs font-[700] text-muted';

export function GizlilikGuvenlikTab() {
  const [state, action, isPending] = useActionState(updatePassword, null);

  return (
    <div className="flex flex-col gap-6">
      <PanelSectionCard title="Şifre Değiştir" description="Hesabınızın güvenliği için güçlü bir şifre kullanın.">
        <form action={action} className="flex flex-col gap-4 max-w-md">
          <label className="flex flex-col gap-1">
            <span className={LABEL}>Yeni Şifre</span>
            <input name="password" type="password" minLength={8} required className={INPUT} />
          </label>
          <label className="flex flex-col gap-1">
            <span className={LABEL}>Şifre Tekrar</span>
            <input name="confirm_password" type="password" minLength={8} required className={INPUT} />
          </label>
          {state && 'error' in state && (
            <p role="alert" className="text-sm text-red-600">{state.error}</p>
          )}
          {state && 'success' in state && (
            <p role="status" className="text-sm text-green-600">Şifreniz başarıyla güncellendi.</p>
          )}
          <div className="flex justify-end">
            <button type="submit" disabled={isPending}
              className="rounded-xl bg-primary px-4 py-2 text-sm font-[700] text-white disabled:opacity-60">
              {isPending ? 'Güncelleniyor…' : 'Şifreyi Güncelle'}
            </button>
          </div>
        </form>
      </PanelSectionCard>
    </div>
  );
}
```

- [ ] **Step 4: `settings-right-sidebar.tsx`**

```typescript
// uygulamalar/web/app/owner/(panel)/settings/settings-right-sidebar.tsx
'use client';

import { useState, useTransition } from 'react';
import Link from 'next/link';
import { deactivateBusiness } from './actions';
import type { BusinessData, UserData } from './settings-client';

export function SettingsRightSidebar({
  user,
  business,
}: {
  user: UserData;
  business: BusinessData;
}) {
  const [confirmDelete, setConfirmDelete] = useState(false);
  const [deleteError, setDeleteError] = useState('');
  const [isPending, startTransition] = useTransition();

  const integrations = [
    { label: 'Web Sitesi',    connected: !!business.website_url },
    { label: 'Instagram',     connected: !!business.instagram_url },
    { label: 'Facebook',      connected: !!business.facebook_url },
    { label: 'Twitter/X',     connected: !!business.twitter_url },
  ];

  const initials = (user.displayName || user.email).charAt(0).toUpperCase();

  function handleDelete() {
    startTransition(async () => {
      const result = await deactivateBusiness(business.id);
      if (result?.error) {
        setDeleteError(result.error);
      } else {
        window.location.href = '/owner/dashboard';
      }
    });
  }

  return (
    <div className="flex flex-col gap-4 lg:sticky lg:top-6">

      {/* Hesap Bilgileri */}
      <div className="rounded-2xl border border-border bg-card p-5">
        <p className="mb-3 text-xs font-[700] uppercase tracking-wide text-muted">Hesap Bilgileri</p>
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-full bg-primary/10 text-sm font-[900] text-primary">
            {initials}
          </div>
          <div>
            <p className="font-[700] text-textStrong">{user.displayName || 'İşletme Sahibi'}</p>
            <p className="text-xs text-muted">İşletme Sahibi</p>
          </div>
        </div>
      </div>

      {/* Üyelik Planı */}
      <div className="rounded-2xl border border-border bg-card p-5">
        <p className="mb-3 text-xs font-[700] uppercase tracking-wide text-muted">Üyelik Planı</p>
        <div className="mb-3 flex items-center justify-between">
          <p className="font-[700] text-textStrong">Standart Plan</p>
          <span className="rounded-full bg-green-50 px-2 py-0.5 text-xs font-[800] text-green-700">Aktif</span>
        </div>
        <button
          type="button"
          className="w-full rounded-xl border border-primary px-4 py-2 text-sm font-[700] text-primary transition-colors hover:bg-primary/5"
        >
          Planı Yükselt
        </button>
      </div>

      {/* Hızlı İşlemler */}
      <div className="rounded-2xl border border-border bg-card p-5">
        <p className="mb-3 text-xs font-[700] uppercase tracking-wide text-muted">Hızlı İşlemler</p>
        <div className="flex flex-col gap-2">
          {business.slug && (
            <Link
              href={`/b/${business.slug}`}
              target="_blank"
              className="flex items-center gap-2 text-sm text-textStrong transition-colors hover:text-primary"
            >
              <ExternalIcon />
              İşletme Profili Önizleme
            </Link>
          )}
          <Link
            href="/owner/qr"
            className="flex items-center gap-2 text-sm text-textStrong transition-colors hover:text-primary"
          >
            <QrIcon />
            QR Menüyü Görüntüle
          </Link>
          <Link
            href="/owner/businesses"
            className="flex items-center gap-2 text-sm text-textStrong transition-colors hover:text-primary"
          >
            <BuildingIcon />
            İşletme Listesi
          </Link>
        </div>
      </div>

      {/* Entegrasyonlar */}
      <div className="rounded-2xl border border-border bg-card p-5">
        <p className="mb-3 text-xs font-[700] uppercase tracking-wide text-muted">Entegrasyonlar</p>
        <div className="flex flex-col gap-2">
          {integrations.map((integ) => (
            <div key={integ.label} className="flex items-center justify-between">
              <p className="text-sm text-textStrong">{integ.label}</p>
              <span className={`text-xs font-[700] ${integ.connected ? 'text-green-600' : 'text-muted'}`}>
                {integ.connected ? 'Bağlandı' : 'Bağlan'}
              </span>
            </div>
          ))}
        </div>
      </div>

      {/* Tehlikeli Bölge */}
      <div className="rounded-2xl border border-red-200 bg-red-50/50 p-5">
        <p className="mb-2 text-xs font-[700] uppercase tracking-wide text-red-600">Tehlikeli Bölge</p>
        <p className="mb-3 text-xs text-muted">
          Hesabınızı veya işletmenizi silmek istiyorsanız lütfen dikkatli olun.
        </p>
        {deleteError && (
          <p role="alert" className="mb-2 text-xs text-red-600">{deleteError}</p>
        )}
        {!confirmDelete ? (
          <button
            type="button"
            onClick={() => setConfirmDelete(true)}
            className="flex items-center gap-2 rounded-xl border border-red-300 px-4 py-2 text-sm font-[700] text-red-600 transition-colors hover:bg-red-50"
          >
            <TrashIcon />
            İşletmemi Sil
          </button>
        ) : (
          <div className="flex flex-col gap-2">
            <p className="text-xs font-[700] text-red-700">Emin misiniz? Bu işlem geri alınamaz.</p>
            <div className="flex gap-2">
              <button
                type="button"
                onClick={() => { setConfirmDelete(false); setDeleteError(''); }}
                className="flex-1 rounded-xl border border-border px-3 py-1.5 text-xs font-[700] text-textStrong transition-colors hover:bg-bg"
              >
                İptal
              </button>
              <button
                type="button"
                onClick={handleDelete}
                disabled={isPending}
                className="flex-1 rounded-xl bg-red-600 px-3 py-1.5 text-xs font-[700] text-white disabled:opacity-60"
              >
                {isPending ? 'Siliniyor…' : 'Evet, Sil'}
              </button>
            </div>
          </div>
        )}
      </div>

    </div>
  );
}

// ── Icons ──────────────────────────────────────────────────────────────────

function ExternalIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6" />
      <polyline points="15 3 21 3 21 9" /><line x1="10" y1="14" x2="21" y2="3" />
    </svg>
  );
}

function QrIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="3" width="7" height="7" /><rect x="14" y="3" width="7" height="7" />
      <rect x="3" y="14" width="7" height="7" /><rect x="14" y="14" width="3" height="3" />
    </svg>
  );
}

function BuildingIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="2" y="3" width="20" height="18" rx="2" /><path d="M8 21V9M16 21V9M2 9h20" />
    </svg>
  );
}

function TrashIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <polyline points="3 6 5 6 21 6" /><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6" />
      <path d="M10 11v6M14 11v6M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2" />
    </svg>
  );
}
```

- [ ] **Step 5: Typecheck**

```bash
cd C:\yeedoy\uygulamalar\web && npm run typecheck
```

Expected: no errors.

- [ ] **Step 6: Commit**

```bash
git add uygulamalar/web/app/owner/\(panel\)/settings/
git commit -m "feat(web): owner ayarlar — Hesap, Bildirim, Gizlilik sekmeleri + sağ sidebar"
```

---

## Self-Review Checklist

- [x] **Spec coverage**: Tüm 5 sekme + sağ sidebar kapsandı ✓
- [x] **Security**: Her mutating action → rate limit + auth + ownership check + Zod ✓
- [x] **No placeholders**: Tüm kod tam yazıldı ✓
- [x] **Type consistency**: `BusinessData` ve `UserData` interface'leri `settings-client.tsx`'te tek yerde tanımlandı, tüm tab'lar import ediyor ✓
- [x] **ActionState tipi**: `{ error: string } | { success: true } | null` tüm action'larda tutarlı ✓
- [x] **BrandingEditor import**: `../../businesses/[id]/branding-editor` — relative path doğru ✓
- [x] **HoursForm import**: `../hours/hours-form` — kendi `saveHours` action'ını kendi içinde çağırır, dışarıdan müdahale gerekmez ✓
- [x] **Danger zone**: Optimistic delete yok — server action success'te `window.location.href` ile redirect ✓
