# Sahip Paneli — Eksik Özellikler Tamamlama Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `docs/superpowers/specs/2026-07-22-sahip-panel-eksik-ozellikler-design.md`'de onaylanan 4 özelliği (ekip e-posta daveti, menü kategori yönetimi sayfası, onboarding gerçek takip, yorum profil fotoğrafı) mevcut `/sahip` paneline ekle.

**Architecture:** Her özellik `worktree-owner-panel-turkification` dalından referans alınıp mevcut design-token/isimlendirme konvansiyonlarına uyacak şekilde yeniden yazılır. Server action'lar mevcut `getOwnedMenuContext`/`hasOwnerBusiness` yetkilendirme desenini kullanır. Yeni RPC CLAUDE.md şablonuna uyar.

**Tech Stack:** Next.js 15 App Router, Supabase (Postgres RPC + RLS), Resend (e-posta), Vitest.

---

## Task 1: E-posta modülü + config

**Files:**
- Modify: `uygulamalar/web/src/lib/ayarlar.ts`
- Create: `uygulamalar/web/src/lib/eposta.ts`

- [ ] **Step 1: `ayarlar.ts`'e iki config getter ekle**

`appConfig` nesnesinin sonuna (`revalidateSecret` satırından sonra), mevcut virgülle biten satırın hemen ardına:

```ts
  emailFrom: () => process.env.EMAIL_FROM?.trim() || 'Yeedoy <bildirim@yeedoy.com>',
  resendApiKey: () => process.env.RESEND_API_KEY?.trim() || null,
```

- [ ] **Step 2: `eposta.ts` oluştur**

```ts
import { Resend } from 'resend';
import { appConfig } from '@/src/lib/ayarlar';
import { logger } from '@/src/lib/kayitci';

let client: Resend | null | undefined;

function getClient(): Resend | null {
  if (client !== undefined) return client;
  const apiKey = appConfig.resendApiKey();
  client = apiKey ? new Resend(apiKey) : null;
  return client;
}

export async function sendEmail(params: { to: string; subject: string; html: string }): Promise<boolean> {
  const resend = getClient();
  if (!resend) {
    logger.warn('sendEmail: RESEND_API_KEY tanımlı değil, e-posta gönderilmedi', { to: params.to, subject: params.subject });
    return false;
  }

  try {
    const { error } = await resend.emails.send({
      from: appConfig.emailFrom(),
      to: params.to,
      subject: params.subject,
      html: params.html,
    });
    if (error) {
      logger.error('sendEmail: Resend hatası', { to: params.to, subject: params.subject, error });
      return false;
    }
    return true;
  } catch (error) {
    logger.error('sendEmail: beklenmeyen hata', { to: params.to, subject: params.subject, error });
    return false;
  }
}
```

- [ ] **Step 3: `resend` paketini yükle**

```bash
cd uygulamalar/web && npm install resend
```

- [ ] **Step 4: Typecheck**

Run: `cd uygulamalar/web && npm run typecheck`
Expected: hata yok.

- [ ] **Step 5: Commit**

```bash
git add uygulamalar/web/src/lib/ayarlar.ts uygulamalar/web/src/lib/eposta.ts uygulamalar/web/package.json uygulamalar/web/package-lock.json
git commit -m "feat(web): best-effort e-posta gönderim modülü ekle (Resend, RESEND_API_KEY yoksa no-op)"
```

---

## Task 2: `claim_pending_team_invites_v1` migration

**Files:**
- Create: `supabase/migrations/20260722000001_claim_pending_team_invites.sql`

- [ ] **Step 1: Migration dosyasını oluştur**

```sql
-- Giriş yapan kullanıcının e-postasına eşleşen, henüz kimseye bağlanmamış
-- (user_id IS NULL) bekleyen ekip davetlerini bu hesaba bağlar.
-- Çağıran: uygulamalar/web/app/sunucu/kimlik/giris/route.ts (login sonrası, best-effort).
CREATE OR REPLACE FUNCTION public.claim_pending_team_invites_v1()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_email text;
  v_linked_count int;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  SELECT lower(email::text) INTO v_email FROM auth.users WHERE id = v_user_id;
  IF v_email IS NULL THEN
    RETURN jsonb_build_object('ok', true, 'linked_count', 0);
  END IF;

  WITH linked AS (
    UPDATE public.business_team_memberships
    SET user_id = v_user_id,
        accepted_at = now(),
        updated_at = now()
    WHERE user_id IS NULL
      AND revoked_at IS NULL
      AND lower(coalesce(invite_email, '')) = v_email
    RETURNING id
  )
  SELECT count(*) INTO v_linked_count FROM linked;

  RETURN jsonb_build_object('ok', true, 'linked_count', v_linked_count);
END;
$$;

REVOKE ALL ON FUNCTION public.claim_pending_team_invites_v1() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.claim_pending_team_invites_v1() TO authenticated;
COMMENT ON FUNCTION public.claim_pending_team_invites_v1 IS 'Giriş yapan kullanıcıya ait bekleyen ekip davetlerini hesaba bağlar. Called by: app/sunucu/kimlik/giris/route.ts.';
```

- [ ] **Step 2: Yerelde uygula**

Run: `supabase db reset`
Expected: migration hatasız uygulanır.

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260722000001_claim_pending_team_invites.sql
git commit -m "feat(db): claim_pending_team_invites_v1 RPC ekle — bekleyen ekip davetlerini girişte hesaba bağlar"
```

---

## Task 3: Ekip server action'ları genişlet + login route'a bağla

**Files:**
- Create: `uygulamalar/web/app/sahip/ekip/ekip-sabitleri.ts`
- Modify: `uygulamalar/web/app/sahip/ekip/ekip-islemleri.ts`
- Modify: `uygulamalar/web/app/sunucu/kimlik/giris/route.ts`

**Context:** `page.tsx` şu an `ROLE_LABELS`'ı kendi içinde tanımlıyor (satır 14-20) — bu task'ta bu tanım `ekip-sabitleri.ts`'e taşınıyor, Task 4'te `page.tsx` oradan import edecek şekilde güncellenecek.

- [ ] **Step 1: `ekip-sabitleri.ts` oluştur**

```ts
export const ROLE_LABELS: Record<string, { label: string; className: string }> = {
  owner: { label: 'Sahip', className: 'bg-primary/10 text-primary' },
  manager: { label: 'Yönetici', className: 'bg-purple-50 text-purple-700' },
  editor: { label: 'Editör', className: 'bg-blue-50 text-blue-700' },
  staff: { label: 'Personel', className: 'bg-zinc-100 text-zinc-600' },
  viewer: { label: 'İzleyici', className: 'bg-zinc-50 text-zinc-500' },
};
```

- [ ] **Step 2: `ekip-islemleri.ts`'i genişlet**

Mevcut dosyanın tamamını şu içerikle değiştir (mevcut `addTeamMember` davranışı korunuyor, sadece opsiyonel `password` alanı ve iki yeni action ekleniyor):

```ts
'use server';

import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { createSupabaseServiceClient } from '@/src/lib/taban/hizmet';
import { hasOwnerBusiness } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { sendEmail } from '@/src/lib/eposta';
import { appConfig } from '@/src/lib/ayarlar';
import { ROLE_LABELS } from './ekip-sabitleri';

const ROLE_VALUES = new Set(['manager', 'editor', 'staff', 'viewer']);

export async function addTeamMember(formData: FormData): Promise<void> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect('/giris?redirect=/sahip/ekip');

  const businessId = String(formData.get('businessId') ?? '').trim();
  const email = String(formData.get('email') ?? '').trim().toLowerCase();
  const fullName = String(formData.get('fullName') ?? '').trim();
  const password = String(formData.get('password') ?? '');
  const role = String(formData.get('role') ?? '').trim().toLowerCase();

  if (!businessId || !email || !ROLE_VALUES.has(role)) {
    redirect('/sahip/ekip?durum=gecersiz');
  }
  if (password && password.length < 8) {
    redirect('/sahip/ekip?durum=sifre_kisa');
  }

  const canManageBusiness = await hasOwnerBusiness(supabase as any, user.id, businessId);
  if (!canManageBusiness) {
    redirect('/sahip/ekip?durum=yetkisiz');
  }

  const { data: business } = await (supabase as any)
    .from('businesses')
    .select('name')
    .eq('id', businessId)
    .maybeSingle() as { data: { name: string } | null };
  const businessName = business?.name ?? 'İşletmeniz';

  let mode: 'created' | 'invited' | 'linked' = 'invited';

  if (password) {
    const serviceClient = createSupabaseServiceClient();
    if (!serviceClient) {
      redirect('/sahip/ekip?durum=servis_yok');
    }

    const { data: created, error: createErr } = await serviceClient.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: fullName ? { full_name: fullName } : undefined,
    });

    if (createErr) {
      const alreadyExists = /already.*registered|already.*exists/i.test(createErr.message ?? '');
      if (!alreadyExists) redirect('/sahip/ekip?durum=hesap_hata');
      // E-posta zaten kayıtlı: mevcut hesabın şifresine dokunmuyoruz, sadece ekibe bağlıyoruz.
      mode = 'linked';
    } else {
      mode = 'created';
      if (created.user) {
        try {
          await (serviceClient as any)
            .from('user_profiles')
            .insert({ user_id: created.user.id, display_name: fullName || email.split('@')[0] });
        } catch {
          // profil satırı ikincil — başarısız olsa da hesap oluşturmayı engellemez
        }
      }
    }
  }

  const { data, error } = await (supabase as any).rpc('upsert_team_member_v1', {
    p_business_id: businessId,
    p_email: email,
    p_role: role,
    p_scope: 'this_business',
  });

  if (error || data?.ok === false) {
    const code = data?.code ?? error?.code ?? 'hata';
    redirect(`/sahip/ekip?durum=${encodeURIComponent(code)}`);
  }

  revalidatePath('/sahip/ekip');

  const roleLabel = ROLE_LABELS[role]?.label ?? role;
  const loginUrl = `${appConfig.siteUrl()}/giris`;

  if (mode === 'created') {
    void sendEmail({
      to: email,
      subject: `${businessName} — Yeedoy Sahip Paneli hesabınız hazır`,
      html: `<p>${businessName} işletmesi için Yeedoy Sahip Paneli'nde <strong>${roleLabel}</strong> rolüyle bir hesap oluşturuldu.</p>
             <p>Giriş bilgilerinizi (e-posta ve şifre) işletme sahibinizden öğrenebilirsiniz.</p>
             <p><a href="${loginUrl}">${loginUrl}</a> adresinden giriş yapabilirsiniz.</p>`,
    });
  } else if (mode === 'invited') {
    void sendEmail({
      to: email,
      subject: `${businessName} sizi ekibine davet etti`,
      html: `<p>${businessName} işletmesi sizi Yeedoy Sahip Paneli'nde <strong>${roleLabel}</strong> rolüyle ekibine davet etti.</p>
             <p>Bu e-posta adresiyle <a href="${loginUrl}">${loginUrl}</a> üzerinden kayıt olun veya giriş yapın; daveti otomatik olarak hesabınıza bağlanacaktır.</p>`,
    });
  } else {
    void sendEmail({
      to: email,
      subject: `${businessName} ekibine eklendiniz`,
      html: `<p>${businessName} işletmesi sizi Yeedoy Sahip Paneli'nde <strong>${roleLabel}</strong> rolüyle ekibine ekledi.</p>
             <p>Mevcut hesabınızla <a href="${loginUrl}">${loginUrl}</a> üzerinden giriş yapabilirsiniz.</p>`,
    });
  }

  redirect('/sahip/ekip?durum=eklendi');
}

export async function changeTeamMemberRole(businessId: string, email: string, role: string): Promise<{ error: string } | null> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Oturum bulunamadı' };

  const normalizedRole = role.trim().toLowerCase();
  if (!ROLE_VALUES.has(normalizedRole)) return { error: 'Geçerli bir rol seçin' };

  const canManageBusiness = await hasOwnerBusiness(supabase as any, user.id, businessId);
  if (!canManageBusiness) return { error: 'Bu işletme için ekip yönetimi yetkiniz yok' };

  const { data, error } = await (supabase as any).rpc('upsert_team_member_v1', {
    p_business_id: businessId,
    p_email: email.trim().toLowerCase(),
    p_role: normalizedRole,
    p_scope: 'this_business',
  });

  if (error) return { error: error.message };
  if (data?.ok === false) return { error: data?.code === 'forbidden' ? 'Bu işletme için ekip yönetimi yetkiniz yok' : 'Rol güncellenemedi' };

  revalidatePath('/sahip/ekip');
  return null;
}

export async function removeTeamMember(businessId: string, membershipId: string): Promise<{ error: string } | null> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Oturum bulunamadı' };

  const canManageBusiness = await hasOwnerBusiness(supabase as any, user.id, businessId);
  if (!canManageBusiness) return { error: 'Bu işletme için ekip yönetimi yetkiniz yok' };

  const { data, error } = await (supabase as any).rpc('revoke_team_member_v1', {
    p_business_id: businessId,
    p_membership_id: membershipId,
  });

  if (error) return { error: error.message };
  if (data?.ok === false) return { error: 'Üye kaldırılamadı' };

  revalidatePath('/sahip/ekip');
  return null;
}
```

- [ ] **Step 3: Login route'a `claim_pending_team_invites_v1` çağrısını ekle**

`uygulamalar/web/app/sunucu/kimlik/giris/route.ts` içinde şu mevcut blok var (satır 64-78):

```ts
  const { data, error } = await supabase.auth.signInWithPassword({
    email: parsed.data.email.trim(),
    password: parsed.data.password,
  });

  if (error || !data.session?.user) {
    if (wantsHtmlRedirect) {
      return redirectToLogin('auth_failed', redirectTo);
    }
    return NextResponse.json({ error: error?.message ?? 'auth_failed' }, { status: 401 });
  }

  const effectiveRedirect = parsed.data.redirectTo
    ? redirectTo
    : await resolveRoleBasedRedirect(supabase as any, data.session.user.id);
```

`if (error || !data.session?.user) { ... }` bloğunun kapanışı ile `const effectiveRedirect = ...` satırı arasına ekle:

```ts

  // Bekleyen ekip davetlerini bu girişte hesaba bağla — best-effort, giriş
  // akışını asla engellemez. Rol yönlendirmesinden ÖNCE çalışmalı ki az önce
  // bağlanan üyelik görülebilsin.
  try {
    await supabase.rpc('claim_pending_team_invites_v1');
  } catch {
    // best-effort
  }
```

- [ ] **Step 4: Typecheck + lint**

Run: `cd uygulamalar/web && npm run typecheck && npm run lint`
Expected: hata yok.

- [ ] **Step 5: Commit**

```bash
git add uygulamalar/web/app/sahip/ekip/ekip-sabitleri.ts uygulamalar/web/app/sahip/ekip/ekip-islemleri.ts uygulamalar/web/app/sunucu/kimlik/giris/route.ts
git commit -m "feat(web): ekip üyesi eklerken opsiyonel şifreli hesap oluşturma + e-posta bildirimi, rol değiştir/kaldır action'ları"
```

---

## Task 4: Ekip sayfası UI güncellemesi

**Files:**
- Create: `uygulamalar/web/app/sahip/ekip/ekip-uye-satiri-aksiyonlari.tsx`
- Modify: `uygulamalar/web/app/sahip/ekip/page.tsx`

- [ ] **Step 1: Satır aksiyonları için client component oluştur**

```tsx
'use client';

import { useState, useTransition } from 'react';
import { changeTeamMemberRole, removeTeamMember } from './ekip-islemleri';
import { ROLE_LABELS } from './ekip-sabitleri';

export function EkipUyeSatiriAksiyonlari({
  businessId,
  email,
  role,
  membershipId,
}: {
  businessId: string;
  email: string;
  role: string;
  membershipId: string | null;
}) {
  const [isPending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);

  function handleRoleChange(newRole: string) {
    setError(null);
    startTransition(async () => {
      const result = await changeTeamMemberRole(businessId, email, newRole);
      if (result?.error) setError(result.error);
    });
  }

  function handleRemove() {
    if (!membershipId) return;
    if (!confirm(`${email} ekipten kaldırılsın mı?`)) return;
    setError(null);
    startTransition(async () => {
      const result = await removeTeamMember(businessId, membershipId);
      if (result?.error) setError(result.error);
    });
  }

  return (
    <div className="flex items-center gap-2">
      <select
        value={role}
        disabled={isPending}
        onChange={(e) => handleRoleChange(e.target.value)}
        className="min-h-[32px] rounded-lg border border-border bg-bg px-2 text-[11px] font-[700] text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/30"
      >
        {Object.entries(ROLE_LABELS).filter(([key]) => key !== 'owner').map(([key, cfg]) => (
          <option key={key} value={key}>{cfg.label}</option>
        ))}
      </select>
      {membershipId && (
        <button
          type="button"
          disabled={isPending}
          onClick={handleRemove}
          className="text-[11px] font-[700] text-danger hover:underline disabled:opacity-50"
        >
          Kaldır
        </button>
      )}
      {error && <span className="text-[11px] text-danger">{error}</span>}
    </div>
  );
}
```

- [ ] **Step 2: `page.tsx`'i güncelle**

`ROLE_LABELS` sabit tanımını (satır 14-20) kaldır, yerine import ekle:

```ts
import { ROLE_LABELS } from './ekip-sabitleri';
import { EkipUyeSatiriAksiyonlari } from './ekip-uye-satiri-aksiyonlari';
```

`STATUS_MESSAGES` haritasına yeni durum kodları ekle:

```ts
  sifre_kisa: { text: 'Şifre en az 8 karakter olmalı.', className: 'border-danger/25 bg-danger/[0.08] text-danger' },
  servis_yok: { text: 'Sunucu yapılandırması eksik (SUPABASE_SERVICE_ROLE_KEY tanımlı değil) — şifresiz davet gönderebilirsiniz.', className: 'border-danger/25 bg-danger/[0.08] text-danger' },
  hesap_hata: { text: 'Hesap oluşturulamadı. Tekrar deneyin.', className: 'border-danger/25 bg-danger/[0.08] text-danger' },
```

Ekle formuna (mevcut `grid gap-3 md:grid-cols-[1fr_1.2fr_180px_auto]` yapısını `md:grid-cols-[1fr_1fr_1fr_180px_auto]` yap ve iki alan ekle — Ad Soyad e-posta alanından önce, Şifre rol alanından önce):

```tsx
              <label className="flex flex-col gap-1.5">
                <span className="text-xs font-[800] uppercase tracking-wide text-muted">Ad Soyad (opsiyonel)</span>
                <input
                  name="fullName"
                  type="text"
                  placeholder="Ayşe Yılmaz"
                  className="min-h-[44px] rounded-xl border border-border bg-bg px-3 text-sm text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/30"
                />
              </label>
```

E-posta alanından sonra, Rol alanından önce:

```tsx
              <label className="flex flex-col gap-1.5">
                <span className="text-xs font-[800] uppercase tracking-wide text-muted">Şifre (opsiyonel)</span>
                <input
                  name="password"
                  type="password"
                  minLength={8}
                  placeholder="Boşsa davet gönderilir"
                  className="min-h-[44px] rounded-xl border border-border bg-bg px-3 text-sm text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/30"
                />
              </label>
```

Ekip Üyeleri tablosuna yeni bir "Aksiyonlar" kolonu ekle (`<th>` başlığa, her `<tr>`'a):

```tsx
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Aksiyonlar</th>
```

```tsx
                      <td className="px-5 py-3">
                        {m.source === 'team_membership' ? (
                          <EkipUyeSatiriAksiyonlari
                            businessId={m.business_id}
                            email={m.email ?? ''}
                            role={m.role}
                            membershipId={m.membership_id}
                          />
                        ) : (
                          <span className="text-[11px] text-muted">—</span>
                        )}
                      </td>
```

**"Vardiya Planı (Bu Hafta)" `PanelBolumKarti` bloğunu (satır 211-214) ve dosyanın altındaki `DAYS`, `SHIFTS`, `ShiftScheduler` fonksiyonunu tamamen sil.**

- [ ] **Step 3: Typecheck + lint**

Run: `cd uygulamalar/web && npm run typecheck && npm run lint`
Expected: hata yok, kullanılmayan `TeamMember` alanı/importu kalmadığından emin ol.

- [ ] **Step 4: Commit**

```bash
git add uygulamalar/web/app/sahip/ekip/
git commit -m "feat(web): ekip sayfasına şifre alanı, rol değiştir/kaldır UI'sı ekle; sahte Vardiya Planı kaldırıldı"
```

---

## Task 5: Menü kategori yönetimi sayfası

**Files:**
- Create: `uygulamalar/web/app/sahip/menuler/[menuId]/kategoriler/page.tsx`
- Create: `uygulamalar/web/app/sahip/menuler/[menuId]/kategoriler/kategoriler-istemcisi.tsx`
- Modify: `uygulamalar/web/app/sahip/menuler/[menuId]/duzenle/page.tsx`

- [ ] **Step 1: `page.tsx` oluştur**

```tsx
import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound, redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getMenuWithSections } from '@/src/lib/veri/owner/sahip-menuler';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi } from '@/src/ui/yerlesim/panel-section-card';
import { KategorilerClient } from './kategoriler-istemcisi';

type Props = { params: Promise<{ menuId: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { menuId } = await params;
  const supabase = await createSupabaseServerClient();
  const { data } = await (supabase as any).from('menus').select('title').eq('id', menuId).single() as { data: { title: string } | null };
  return { title: data ? `${data.title} — Kategoriler | Sahip Paneli` : 'Kategoriler | Sahip Paneli', robots: { index: false, follow: false } };
}

export default async function MenuKategorilerPage({ params }: Props) {
  const { menuId } = await params;
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    redirect(`/giris?redirect=${encodeURIComponent(`/sahip/menuler/${menuId}/kategoriler`)}`);
  }

  const detail = await getMenuWithSections(menuId, user.id);
  if (!detail) notFound();

  const { menu, business: biz, sections, items } = detail;

  const itemCounts: Record<string, number> = {};
  for (const item of items) {
    itemCounts[item.section_id] = (itemCounts[item.section_id] ?? 0) + 1;
  }

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow={biz.name}
        title="Kategoriler"
        description={`${menu.title} menüsündeki bölümleri yönetin`}
        actions={
          <Link
            href={`/sahip/menuler/${menuId}/duzenle`}
            className="rounded-xl border border-border bg-card px-3 py-1.5 text-[12px] font-[700] text-textStrong transition-colors hover:bg-bg"
          >
            ← Menü Düzenleyiciye Dön
          </Link>
        }
      />
      <PanelIcerikYuzeyi className="pt-6">
        <KategorilerClient
          menuId={menuId}
          sections={sections.map((section) => ({ id: section.id, title: section.title, sort_order: section.sort_order }))}
          itemCounts={itemCounts}
        />
      </PanelIcerikYuzeyi>
    </div>
  );
}
```

- [ ] **Step 2: `kategoriler-istemcisi.tsx` oluştur**

```tsx
'use client';

import { useState, useTransition } from 'react';
import { createSection, updateSection, deleteSection } from '../duzenle/menu-islemleri';

type Section = { id: string; title: string; sort_order: number };

function PlusIcon() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="12" y1="5" x2="12" y2="19" /><line x1="5" y1="12" x2="19" y2="12" /></svg>;
}
function PencilIcon() {
  return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z" /></svg>;
}
function TrashIcon() {
  return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 6h18" /><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" /></svg>;
}

export function KategorilerClient({
  menuId,
  sections: initSections,
  itemCounts,
}: {
  menuId: string;
  sections: Section[];
  itemCounts: Record<string, number>;
}) {
  const [isPending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [editTitle, setEditTitle] = useState('');
  const [showNew, setShowNew] = useState(false);
  const [newTitle, setNewTitle] = useState('');

  const sections = initSections;

  function run(action: () => Promise<{ error: string } | null>) {
    setError(null);
    startTransition(async () => {
      const result = await action();
      if (result?.error) setError(result.error);
    });
  }

  function handleCreate() {
    const title = newTitle.trim();
    if (!title) return;
    run(async () => {
      const result = await createSection(menuId, title, sections.length);
      if (!result) {
        setNewTitle('');
        setShowNew(false);
      }
      return result;
    });
  }

  function handleUpdate(sectionId: string) {
    const title = editTitle.trim();
    if (!title) return;
    run(async () => {
      const result = await updateSection(sectionId, menuId, title);
      if (!result) setEditingId(null);
      return result;
    });
  }

  function handleDelete(section: Section) {
    const count = itemCounts[section.id] ?? 0;
    const message = count > 0
      ? `"${section.title}" bölümünde ${count} ürün var. Silerseniz bu ürünler de silinir. Emin misiniz?`
      : `"${section.title}" bölümü silinsin mi?`;
    if (!confirm(message)) return;
    run(() => deleteSection(section.id, menuId));
  }

  return (
    <div className="flex flex-col gap-5">
      {error && <div className="rounded-xl bg-red-50 px-4 py-3 text-sm text-red-700">{error}</div>}

      <div className="flex flex-col gap-2">
        {sections.map((section) => (
          <div key={section.id} className="flex items-center justify-between gap-3 rounded-xl border border-border bg-card px-4 py-3">
            {editingId === section.id ? (
              <input
                autoFocus
                value={editTitle}
                onChange={(e) => setEditTitle(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && handleUpdate(section.id)}
                className="min-h-[36px] flex-1 rounded-lg border border-border bg-bg px-2 text-sm font-[700] text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/30"
              />
            ) : (
              <span className="text-sm font-[700] text-textStrong">{section.title}</span>
            )}
            <div className="flex shrink-0 items-center gap-3 text-xs text-muted">
              <span>{itemCounts[section.id] ?? 0} ürün</span>
              {editingId === section.id ? (
                <button type="button" disabled={isPending} onClick={() => handleUpdate(section.id)} className="font-[700] text-primary hover:underline">Kaydet</button>
              ) : (
                <button type="button" disabled={isPending} onClick={() => { setEditingId(section.id); setEditTitle(section.title); }} className="text-textStrong hover:text-primary"><PencilIcon /></button>
              )}
              <button type="button" disabled={isPending} onClick={() => handleDelete(section)} className="text-danger hover:opacity-70"><TrashIcon /></button>
            </div>
          </div>
        ))}
      </div>

      {showNew ? (
        <div className="flex items-center gap-2">
          <input
            autoFocus
            value={newTitle}
            onChange={(e) => setNewTitle(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && handleCreate()}
            placeholder="Bölüm adı"
            className="min-h-[40px] flex-1 rounded-xl border border-border bg-bg px-3 text-sm text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/30"
          />
          <button type="button" disabled={isPending} onClick={handleCreate} className="btn-primary rounded-xl px-4 py-2 text-sm font-[900] text-white">Ekle</button>
          <button type="button" onClick={() => setShowNew(false)} className="rounded-xl border border-border px-4 py-2 text-sm font-[700] text-textStrong">Vazgeç</button>
        </div>
      ) : (
        <button
          type="button"
          onClick={() => setShowNew(true)}
          className="flex items-center justify-center gap-2 rounded-xl border border-dashed border-border px-4 py-3 text-sm font-[700] text-muted hover:border-primary hover:text-primary"
        >
          <PlusIcon /> Yeni Kategori
        </button>
      )}
    </div>
  );
}
```

- [ ] **Step 3: Menü düzenleyiciye "Kategoriler" linki ekle**

`uygulamalar/web/app/sahip/menuler/[menuId]/duzenle/page.tsx` içindeki `actions` bloğunda, "QR Studio" linkinden önce:

```tsx
            <Link
              href={`/sahip/menuler/${menuId}/kategoriler`}
              className="rounded-xl border border-border bg-card px-3 py-1.5 text-[12px] font-[700] text-textStrong transition-colors hover:bg-bg"
            >
              Kategoriler
            </Link>
```

- [ ] **Step 4: Typecheck + lint**

Run: `cd uygulamalar/web && npm run typecheck && npm run lint`
Expected: hata yok.

- [ ] **Step 5: Commit**

```bash
git add uygulamalar/web/app/sahip/menuler/
git commit -m "feat(web): menü düzenleyicisine ayrı bir kategori (bölüm) yönetim sayfası ekle"
```

---

## Task 6: Başlangıç Rehberi gerçek tamamlanma takibi

**Files:**
- Create: `uygulamalar/web/app/sahip/baslangic/baslangic-adimlari.ts`
- Create: `uygulamalar/web/app/sahip/baslangic/baslangic-durumu.ts`
- Modify: `uygulamalar/web/app/sahip/baslangic/page.tsx`
- Modify: `uygulamalar/web/src/ui/kabuk/sahip-kabuk-istemcisi.tsx`
- Test: `uygulamalar/web/test/lib/baslangic-adimlari.test.ts`

**Context:** Mevcut `page.tsx`'te adım 2/3/4 hardcoded `done: false`. Bu task, DB'den gerçek durumu okuyan paylaşılan bir `'use server'` fonksiyon ekliyor; hem sayfa hem sidebar hook'u bu fonksiyonu çağırıyor (kod tekrarı yok). **Önemli:** Next.js `'use server'` dosyalarından sadece async fonksiyon export edilebilir — bu yüzden saf/senkron `computeOnboardingComplete` hesaplaması ayrı, `'use server'` içermeyen bir dosyada (`baslangic-adimlari.ts`) tutuluyor; `baslangic-durumu.ts` ('use server') onu import edip kullanıyor.

- [ ] **Step 1: Saf hesaplama fonksiyonu için test yaz**

`uygulamalar/web/test/lib/baslangic-adimlari.test.ts`:

```ts
import { describe, it, expect } from 'vitest';
import { computeOnboardingComplete } from '@/app/sahip/baslangic/baslangic-adimlari';

describe('computeOnboardingComplete', () => {
  it('hiçbir adım tamamlanmadıysa false döner', () => {
    expect(computeOnboardingComplete({ hasBusiness: false, hasPublishedMenu: false, hasQrCode: false, hasTeamMember: false })).toBe(false);
  });

  it('sadece bazı adımlar tamamlandıysa false döner', () => {
    expect(computeOnboardingComplete({ hasBusiness: true, hasPublishedMenu: true, hasQrCode: false, hasTeamMember: false })).toBe(false);
  });

  it('tüm adımlar tamamlandıysa true döner', () => {
    expect(computeOnboardingComplete({ hasBusiness: true, hasPublishedMenu: true, hasQrCode: true, hasTeamMember: true })).toBe(true);
  });
});
```

- [ ] **Step 2: Testi çalıştır, başarısız olduğunu doğrula**

Run: `cd uygulamalar/web && npx vitest run test/lib/baslangic-adimlari.test.ts`
Expected: FAIL — `baslangic-adimlari` modülü bulunamıyor.

- [ ] **Step 3: `baslangic-adimlari.ts` oluştur (saf mantık, `'use server'` YOK)**

```ts
export type OnboardingFlags = {
  hasBusiness: boolean;
  hasPublishedMenu: boolean;
  hasQrCode: boolean;
  hasTeamMember: boolean;
};

export function computeOnboardingComplete(flags: OnboardingFlags): boolean {
  return flags.hasBusiness && flags.hasPublishedMenu && flags.hasQrCode && flags.hasTeamMember;
}
```

- [ ] **Step 4: Testi tekrar çalıştır, geçtiğini doğrula**

Run: `cd uygulamalar/web && npx vitest run test/lib/baslangic-adimlari.test.ts`
Expected: PASS (3/3).

- [ ] **Step 5: `baslangic-durumu.ts` oluştur (`'use server'`, DB erişimi)**

```ts
'use server';

import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinessIds } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { computeOnboardingComplete, type OnboardingFlags } from './baslangic-adimlari';

export async function getOnboardingStatus(): Promise<OnboardingFlags & { complete: boolean }> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    return { hasBusiness: false, hasPublishedMenu: false, hasQrCode: false, hasTeamMember: false, complete: false };
  }

  const businessIds = await getOwnerBusinessIds(supabase as any, user.id);
  const hasBusiness = businessIds.length > 0;

  if (!hasBusiness) {
    return { hasBusiness: false, hasPublishedMenu: false, hasQrCode: false, hasTeamMember: false, complete: false };
  }

  const [{ count: menuCount }, { count: qrCount }, { count: teamCount }] = await Promise.all([
    (supabase as any).from('menus').select('id', { count: 'exact', head: true }).in('business_id', businessIds).eq('status', 'published'),
    (supabase as any).from('business_qr_codes').select('id', { count: 'exact', head: true }).in('business_id', businessIds),
    (supabase as any).from('business_team_memberships').select('id', { count: 'exact', head: true }).in('business_id', businessIds).is('revoked_at', null).neq('user_id', user.id),
  ]);

  const flags: OnboardingFlags = {
    hasBusiness,
    hasPublishedMenu: (menuCount ?? 0) > 0,
    hasQrCode: (qrCount ?? 0) > 0,
    hasTeamMember: (teamCount ?? 0) > 0,
  };

  return { ...flags, complete: computeOnboardingComplete(flags) };
}
```

- [ ] **Step 6: `page.tsx`'i gerçek duruma göre güncelle**

`getOwnerBusinessIds`/manuel sorgular yerine `getOnboardingStatus()` çağır, `steps` dizisindeki `done`/`pending` alanlarını buradan gelen `flags`'e bağla, en üste ilerleme çubuğu (`X/4 tamamlandı`) ve `flags.complete === true` ise tebrik banner'ı ekle. Adım 1 (`İşletmenizi Ekleyin`) mevcut `hasBusiness`/`hasSubmission`/`submissionPending` mantığını korur (bu zaten doğru çalışıyordu, değişmiyor) — sadece 2/3/4. numaralı adımların `done` değeri artık `flags.hasPublishedMenu` / `flags.hasQrCode` / `flags.hasTeamMember`'dan geliyor.

- [ ] **Step 7: Sidebar'a `useOnboardingComplete` hook'u ekle**

`sahip-kabuk-istemcisi.tsx`'te, mevcut `useCurrentUser` hook'unun hemen altına:

```ts
function useOnboardingComplete() {
  const [complete, setComplete] = useState<boolean | null>(null);
  useEffect(() => {
    void getOnboardingStatus().then((status) => setComplete(status.complete));
  }, []);
  return complete;
}
```

Dosyanın en üstüne import ekle: `import { getOnboardingStatus } from '@/app/sahip/baslangic/baslangic-durumu';`

`SahipKabukIstemcisi` içinde `const user = useCurrentUser();` satırının hemen altına `const onboardingComplete = useOnboardingComplete();` ekle. `navSections={ownerNavSections}` satırını şununla değiştir:

```tsx
        navSections={onboardingComplete === true
          ? ownerNavSections.map((section) => ({
              ...section,
              items: section.items.filter((item) => item.href !== '/sahip/baslangic'),
            }))
          : ownerNavSections}
```

- [ ] **Step 8: Typecheck + lint + tüm unit testler**

Run: `cd uygulamalar/web && npm run typecheck && npm run lint && npm run test:unit`
Expected: hata yok, tüm testler geçiyor.

- [ ] **Step 9: Commit**

```bash
git add uygulamalar/web/app/sahip/baslangic/ uygulamalar/web/src/ui/kabuk/sahip-kabuk-istemcisi.tsx uygulamalar/web/test/lib/baslangic-adimlari.test.ts
git commit -m "feat(web): Başlangıç Rehberi gerçek tamamlanma durumunu takip ediyor, bitince sidebar'dan kalkıyor"
```

---

## Task 7: Yorumlarda profil fotoğrafı

**Files:**
- Modify: `uygulamalar/web/app/sahip/yorumlar/page.tsx`
- Modify: `uygulamalar/web/app/sahip/yorumlar/yorum-satiri.tsx`

- [ ] **Step 1: `page.tsx` sorgusuna `avatar_url` ekle**

`user_profiles` select'inde `'user_id, display_name'` → `'user_id, display_name, avatar_url'`. `profileMap`'in tipini ve değerini `Map<string, { displayName: string | null; avatarUrl: string | null }>` yapacak şekilde güncelle (şu an `profileMap` sadece `display_name` string'i tutuyor):

```ts
  const profileMap = new Map(
    ((profiles ?? []) as Array<{ user_id: string; display_name: string | null; avatar_url: string | null }>)
      .map((profile) => [profile.user_id, { displayName: profile.display_name, avatarUrl: profile.avatar_url }] as const),
  );
```

`YorumSatiri`'a geçirilen `displayName={...}` satırını güncelle:

```tsx
                  displayName={r.user_id ? (profileMap.get(r.user_id)?.displayName ?? null) : null}
                  avatarUrl={r.user_id ? (profileMap.get(r.user_id)?.avatarUrl ?? null) : null}
```

- [ ] **Step 2: `yorum-satiri.tsx`'e `avatarUrl` prop ve `ReviewerAvatar` ekle**

`YorumSatiriProps` interface'ine `avatarUrl: string | null;` ekle, fonksiyon parametrelerine `avatarUrl,` ekle.

Mevcut satır 96-124 (`return (` ile başlayıp ilk `</div>` kapanışına kadar olan blok) şu haliyle:

```tsx
  return (
    <li className="px-5 py-4">
      {/* Yorum başlığı */}
      <div className="flex items-start justify-between gap-4">
        <div className="min-w-0 flex-1">
          <div className="flex flex-wrap items-center gap-2">
            <StarRating rating={rating} />
            <span className="text-xs font-[700] text-textStrong">
              {displayName ?? 'Anonim'}
            </span>
            {businessName && (
              <span className="text-xs text-muted">· {businessName}</span>
            )}
          </div>
          {content && (
            <p className="mt-1.5 text-sm leading-relaxed text-text">{content}</p>
          )}
        </div>
        <div className="shrink-0 text-right">
          <p className="text-xs text-muted">
            {new Date(createdAt).toLocaleDateString('tr-TR')}
          </p>
          {isVisible === false && (
            <span className="mt-1 inline-block rounded-full bg-border px-2 py-0.5 text-[11px] font-[700] text-muted">
              Gizli
            </span>
          )}
        </div>
      </div>
```

Bunu şu şekilde değiştir (sadece `<div className="min-w-0 flex-1">` (yorum başlığı sol taraf) bir `<ReviewerAvatar>` ile sarmalandı, `<div className="shrink-0 text-right">` (sağdaki tarih/gizli rozeti) ve dış `</div>` **aynen korunuyor**):

```tsx
  return (
    <li className="px-5 py-4">
      {/* Yorum başlığı */}
      <div className="flex items-start justify-between gap-4">
        <div className="flex min-w-0 flex-1 items-start gap-3">
          <ReviewerAvatar avatarUrl={avatarUrl} displayName={displayName} />
          <div className="min-w-0 flex-1">
            <div className="flex flex-wrap items-center gap-2">
              <StarRating rating={rating} />
              <span className="text-xs font-[700] text-textStrong">
                {displayName ?? 'Anonim'}
              </span>
              {businessName && (
                <span className="text-xs text-muted">· {businessName}</span>
              )}
            </div>
            {content && (
              <p className="mt-1.5 text-sm leading-relaxed text-text">{content}</p>
            )}
          </div>
        </div>
        <div className="shrink-0 text-right">
          <p className="text-xs text-muted">
            {new Date(createdAt).toLocaleDateString('tr-TR')}
          </p>
          {isVisible === false && (
            <span className="mt-1 inline-block rounded-full bg-border px-2 py-0.5 text-[11px] font-[700] text-muted">
              Gizli
            </span>
          )}
        </div>
      </div>
```

Dosyanın altına (örn. `StarRating` fonksiyonundan hemen önce) ekle:

```tsx
function ReviewerAvatar({ avatarUrl, displayName }: { avatarUrl: string | null; displayName: string | null }) {
  const initial = (displayName ?? 'K').charAt(0).toUpperCase();
  if (avatarUrl) {
    return (
      // eslint-disable-next-line @next/next/no-img-element
      <img
        src={avatarUrl}
        alt={displayName ?? 'Kullanıcı'}
        className="h-9 w-9 shrink-0 rounded-full border border-border object-cover"
      />
    );
  }
  return (
    <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-bg text-[13px] font-[900] text-textStrong">
      {initial}
    </div>
  );
}
```

- [ ] **Step 3: Typecheck + lint**

Run: `cd uygulamalar/web && npm run typecheck && npm run lint`
Expected: hata yok.

- [ ] **Step 4: Commit**

```bash
git add uygulamalar/web/app/sahip/yorumlar/
git commit -m "feat(web): yorumlarda yorumu yapan kullanıcının profil fotoğrafı gösteriliyor"
```

---

## Final Review

Tüm task'lar tamamlandıktan sonra: `cd uygulamalar/web && npm run test:ci` (typecheck + lint + unit + build) çalıştırılıp yeşil olduğu doğrulanmalı. Ardından final code reviewer subagent dispatch edilip, sonrasında `superpowers:finishing-a-development-branch` ile tamamlanmalı.
