# Admin Rol/İzin Sistemi (Plan A) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Admin panelinde sayfa-bazlı gerçek izin kontrolü için veri modelini (admin_roles + admin_permission_key enum), RPC'leri ve Roller sayfasının tam CRUD UI'ını kurmak. Bu plan bittiğinde sistem eksiksiz çalışır ve test edilebilir; mevcut 25 admin sayfasına fiili `requirePermission` kısıtlaması eklemek ayrı bir Plan B'dir (kapsam dışı).

**Architecture:** 2 yeni tablo yerine 1 tablo (`admin_roles`) + kapalı bir Postgres enum (`admin_permission_key`, admin_roles.permissions dizi kolonu) — ayrı bir "permissions" join tablosu yok (izin kataloğu sabit/kod tanımlı). `admin_users.role_id` ile bağlanır. Tüm yazma işlemleri SECURITY DEFINER RPC'ler üzerinden (`has_permission_v1('page:roller')` guard'lı); `admin_roles` tablosuna doğrudan yazma GRANT'ı verilmez (yalnızca SELECT). Next.js tarafında `hasPermission()` server helper'ı + kenar çubuğu client-side izin listesine göre filtrelenir.

**Tech Stack:** Next.js 15 App Router (server components + route handlers), Supabase Postgres (SECURITY DEFINER RPC), Zod, mevcut panel UI bileşenleri (`PanelSayfaBasligi`, `PanelBolumKarti`, `MetricCard`, `PanelEmptyState`).

**Doğrulama yaklaşımı:** Bu admin-panel CRUD sayfalarında (bu oturumda daha önce yapılan Müşteri Destek/Fraud Tespiti/Feature Flags/API Anahtarları gibi) yerleşik konvansiyon vitest birim testi değil, `pnpm run typecheck` + `pnpm run lint` (0 hata) + tarayıcıda uçtan uca doğrulama + gerekli yerlerde doğrudan SQL doğrulama sorgusu. Bu plan da aynı yerleşik konvansiyonu izler — her dosya için ayrı test adımı yerine, tüm dosyalar yazıldıktan sonra tek bir konsolide doğrulama görevi (Task 14) vardır.

---

### Task 1: Migration dosyasını yaz

**Files:**
- Create: `supabase/migrations/20260819140000_admin_roller_izin_sistemi.sql`

- [ ] **Step 1: Migration dosyasını oluştur**

```sql
-- Admin panel: sayfa bazlı rol/izin sistemi.
-- Bugüne kadar public.is_admin() ikili bir kontroldü (admin_users üyeliği = tam erişim).
-- Bu migration admin_users üyelerine rol atayıp, rolün hangi admin sayfalarını
-- görebileceğini admin_roles.permissions dizisiyle tanımlanabilir hale getirir.
-- Route/page seviyesinde fiili kısıtlama (Plan B) ayrı bir migration/PR'da gelecek;
-- bu migration yalnızca veri modelini ve RPC'leri kurar.

CREATE TYPE public.admin_permission_key AS ENUM (
  'page:isletmeler', 'page:zincirler', 'page:kuyruklar', 'page:isletme-basvurulari',
  'page:raporlar', 'page:kullanicilar', 'page:yorumlar', 'page:itirazlar',
  'page:fis-basvurulari', 'page:cop-kutusu', 'page:olaylar', 'page:konumlar',
  'page:analitik', 'page:musteri-destek', 'page:oneriler', 'page:fiyat-onerileri',
  'page:fraud-tespiti', 'page:fotograf-moderasyon', 'page:feature-flags',
  'page:api-anahtarlari', 'page:roller', 'page:gozlemlenebilirlik',
  'page:gelistirme-araclari', 'page:kvkk-gdpr', 'page:gecici-yuklemeler'
);

CREATE TABLE public.admin_roles (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name         text NOT NULL CHECK (char_length(btrim(name)) BETWEEN 1 AND 60),
  description  text CHECK (description IS NULL OR char_length(description) <= 200),
  is_system    boolean NOT NULL DEFAULT false,
  is_active    boolean NOT NULL DEFAULT true,
  permissions  public.admin_permission_key[] NOT NULL DEFAULT '{}',
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now(),
  created_by   uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  updated_by   uuid REFERENCES auth.users(id) ON DELETE SET NULL
);

CREATE UNIQUE INDEX admin_roles_name_key ON public.admin_roles (lower(name));

ALTER TABLE public.admin_roles ENABLE ROW LEVEL SECURITY;

-- Yalnızca SELECT policy + GRANT: tüm yazmalar aşağıdaki SECURITY DEFINER RPC'ler
-- üzerinden. Böylece bir admin, page:roller izni olmasa bile PostgREST ile
-- doğrudan admin_roles'a yazıp izin sistemini bypass edemez (RPC'ler kendi
-- has_permission_v1('page:roller') guard'ını taşır, GRANT INSERT/UPDATE/DELETE
-- authenticated'a hiç verilmez).
CREATE POLICY "admin_roles_admin_select"
  ON public.admin_roles
  FOR SELECT
  TO authenticated
  USING (public.is_admin());

GRANT SELECT ON public.admin_roles TO authenticated;

-- ── admin_users: rol ata ──────────────────────────────────────────────────────
ALTER TABLE public.admin_users ADD COLUMN role_id uuid REFERENCES public.admin_roles(id);

-- Seed: tek sistem rolü — Süper Admin, tüm izinler, silinemez/düzenlenemez/pasife alınamaz.
INSERT INTO public.admin_roles (name, description, is_system, is_active, permissions)
VALUES (
  'Süper Admin',
  'Sistemin tüm yetkilerine sahiptir.',
  true,
  true,
  enum_range(NULL::public.admin_permission_key)
);

-- Mevcut tüm admin_users üyelerini Süper Admin'e bağla (kimse rolsüz kalmaz, kilitlenme riski yok).
UPDATE public.admin_users
SET role_id = (SELECT id FROM public.admin_roles WHERE is_system = true LIMIT 1)
WHERE role_id IS NULL;

ALTER TABLE public.admin_users ALTER COLUMN role_id SET NOT NULL;

CREATE INDEX idx_admin_users_role_id ON public.admin_users (role_id);

-- ── updated_at otomasyonu ────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION private.tg_admin_roles_set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_admin_roles_set_updated_at
  BEFORE UPDATE ON public.admin_roles
  FOR EACH ROW
  EXECUTE FUNCTION private.tg_admin_roles_set_updated_at();

-- ── RPC'ler ──────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.has_permission_v1(p_permission public.admin_permission_key)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.admin_users au
    JOIN public.admin_roles r ON r.id = au.role_id
    WHERE au.user_id = auth.uid()
      AND r.is_active
      AND p_permission = ANY(r.permissions)
  );
$$;

REVOKE ALL ON FUNCTION public.has_permission_v1(public.admin_permission_key) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.has_permission_v1(public.admin_permission_key) TO authenticated;
COMMENT ON FUNCTION public.has_permission_v1 IS 'Çağıranın admin_roles.permissions dizisinde p_permission olup olmadığını döner. Rol pasifse (is_active=false) her zaman false. Called by: src/lib/yetki-kontrol.ts, admin_*_role_v1 RPC guard''ları.';


CREATE OR REPLACE FUNCTION public.get_my_admin_role_v1()
RETURNS TABLE(role_name text, permissions public.admin_permission_key[])
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT r.name, r.permissions
  FROM public.admin_users au
  JOIN public.admin_roles r ON r.id = au.role_id
  WHERE au.user_id = auth.uid();
$$;

REVOKE ALL ON FUNCTION public.get_my_admin_role_v1() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_my_admin_role_v1() TO authenticated;
COMMENT ON FUNCTION public.get_my_admin_role_v1 IS 'Çağıranın admin rolü adını ve izin listesini döner. Admin değilse boş sonuç seti. Called by: src/ui/kabuk/yonetici-kabuk-istemcisi.tsx (kenar çubuğu filtrelemesi ve rozet).';


CREATE OR REPLACE FUNCTION public.admin_create_role_v1(
  p_name        text,
  p_description text,
  p_permissions public.admin_permission_key[]
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id uuid;
BEGIN
  IF NOT public.has_permission_v1('page:roller') THEN
    RAISE EXCEPTION 'unauthorized: Rol yönetimi izniniz yok' USING ERRCODE = 'P0002';
  END IF;

  IF btrim(coalesce(p_name, '')) = '' THEN
    RAISE EXCEPTION 'validation_error: Rol adı zorunlu' USING ERRCODE = 'P0003';
  END IF;

  INSERT INTO public.admin_roles (name, description, permissions, created_by, updated_by)
  VALUES (btrim(p_name), nullif(btrim(coalesce(p_description, '')), ''), coalesce(p_permissions, '{}'), auth.uid(), auth.uid())
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_create_role_v1(text, text, public.admin_permission_key[]) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_create_role_v1(text, text, public.admin_permission_key[]) TO authenticated;
COMMENT ON FUNCTION public.admin_create_role_v1 IS 'Yeni özel admin rolü oluşturur. page:roller izni gerektirir. Called by: app/sunucu/yonetici/roller/route.ts (POST).';


CREATE OR REPLACE FUNCTION public.admin_update_role_v1(
  p_role_id     uuid,
  p_name        text,
  p_description text,
  p_permissions public.admin_permission_key[],
  p_is_active   boolean
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_is_system boolean;
BEGIN
  IF NOT public.has_permission_v1('page:roller') THEN
    RAISE EXCEPTION 'unauthorized: Rol yönetimi izniniz yok' USING ERRCODE = 'P0002';
  END IF;

  SELECT is_system INTO v_is_system FROM public.admin_roles WHERE id = p_role_id;
  IF v_is_system IS NULL THEN
    RAISE EXCEPTION 'not_found: Rol bulunamadı' USING ERRCODE = 'P0001';
  END IF;
  IF v_is_system THEN
    RAISE EXCEPTION 'validation_error: Sistem rolü düzenlenemez' USING ERRCODE = 'P0003';
  END IF;
  IF btrim(coalesce(p_name, '')) = '' THEN
    RAISE EXCEPTION 'validation_error: Rol adı zorunlu' USING ERRCODE = 'P0003';
  END IF;

  UPDATE public.admin_roles
  SET name = btrim(p_name),
      description = nullif(btrim(coalesce(p_description, '')), ''),
      permissions = coalesce(p_permissions, '{}'),
      is_active = p_is_active,
      updated_by = auth.uid()
  WHERE id = p_role_id;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_update_role_v1(uuid, text, text, public.admin_permission_key[], boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_update_role_v1(uuid, text, text, public.admin_permission_key[], boolean) TO authenticated;
COMMENT ON FUNCTION public.admin_update_role_v1 IS 'Özel admin rolünü günceller. Sistem rolleri (Süper Admin) düzenlenemez. Called by: app/sunucu/yonetici/roller/route.ts (PATCH).';


CREATE OR REPLACE FUNCTION public.admin_delete_role_v1(p_role_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_is_system boolean;
  v_assigned  integer;
BEGIN
  IF NOT public.has_permission_v1('page:roller') THEN
    RAISE EXCEPTION 'unauthorized: Rol yönetimi izniniz yok' USING ERRCODE = 'P0002';
  END IF;

  SELECT is_system INTO v_is_system FROM public.admin_roles WHERE id = p_role_id;
  IF v_is_system IS NULL THEN
    RAISE EXCEPTION 'not_found: Rol bulunamadı' USING ERRCODE = 'P0001';
  END IF;
  IF v_is_system THEN
    RAISE EXCEPTION 'validation_error: Sistem rolü silinemez' USING ERRCODE = 'P0003';
  END IF;

  SELECT count(*) INTO v_assigned FROM public.admin_users WHERE role_id = p_role_id;
  IF v_assigned > 0 THEN
    RAISE EXCEPTION 'validation_error: Bu role atanmış % kullanıcı var, önce başka role taşıyın', v_assigned
      USING ERRCODE = 'P0003';
  END IF;

  DELETE FROM public.admin_roles WHERE id = p_role_id;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_delete_role_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_delete_role_v1(uuid) TO authenticated;
COMMENT ON FUNCTION public.admin_delete_role_v1 IS 'Özel admin rolünü siler. Sistem rolü veya hala kullanıcı atanmışsa reddeder. Called by: app/sunucu/yonetici/roller/route.ts (DELETE).';


CREATE OR REPLACE FUNCTION public.admin_assign_user_role_v1(p_user_id uuid, p_role_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.has_permission_v1('page:roller') THEN
    RAISE EXCEPTION 'unauthorized: Rol yönetimi izniniz yok' USING ERRCODE = 'P0002';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.admin_roles WHERE id = p_role_id) THEN
    RAISE EXCEPTION 'not_found: Rol bulunamadı' USING ERRCODE = 'P0001';
  END IF;

  UPDATE public.admin_users SET role_id = p_role_id WHERE user_id = p_user_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found: Kullanıcı admin_users üyesi değil' USING ERRCODE = 'P0001';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_assign_user_role_v1(uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_assign_user_role_v1(uuid, uuid) TO authenticated;
COMMENT ON FUNCTION public.admin_assign_user_role_v1 IS 'Var olan bir admin_users üyesinin rolünü değiştirir. Yeni admin_users üyesi EKLEMEZ. Called by: app/sunucu/yonetici/roller/kullanici-ata/route.ts (PATCH).';
```

---

### Task 2: Migration'ı uygula ve doğrula

- [ ] **Step 1: Migration'ı canlı projeye uygula**

`mcp__supabase__apply_migration` aracıyla `name: "admin_roller_izin_sistemi"`, Task 1'deki tam SQL içeriğiyle çağır (proje: `dktdnbeougrmhkzplbap`). Bu hem canlıya uygular hem migration geçmişine yazar.

- [ ] **Step 2: Kimsenin rolsüz kalmadığını doğrula**

`mcp__supabase__execute_sql`:
```sql
select count(*) as rolsuz from public.admin_users where role_id is null;
```
Beklenen: `rolsuz = 0`. Farklıysa migration'ı gözden geçir (Step 1'e dön), Task 3'e geçme.

- [ ] **Step 3: Süper Admin rolünün tüm izinlere sahip olduğunu doğrula**

```sql
select
  array_length(permissions, 1) as izin_sayisi,
  (select count(*) from unnest(enum_range(null::public.admin_permission_key))) as enum_sayisi
from public.admin_roles where is_system = true;
```
Beklenen: iki sayı eşit (25).

- [ ] **Step 4: `mcp__supabase__get_advisors(type="security")` çalıştır**

Yeni tablo/RPC'lerle ilgili beklenmeyen bulgu olmadığını doğrula.

---

### Task 3: İzin kataloğu — `src/lib/admin-izinler.ts`

**Files:**
- Create: `uygulamalar/web/src/lib/admin-izinler.ts`

- [ ] **Step 1: Dosyayı oluştur**

```ts
export type AdminPermissionKey =
  | 'page:isletmeler' | 'page:zincirler' | 'page:kuyruklar' | 'page:isletme-basvurulari'
  | 'page:raporlar' | 'page:kullanicilar' | 'page:yorumlar' | 'page:itirazlar'
  | 'page:fis-basvurulari' | 'page:cop-kutusu' | 'page:olaylar' | 'page:konumlar'
  | 'page:analitik' | 'page:musteri-destek' | 'page:oneriler' | 'page:fiyat-onerileri'
  | 'page:fraud-tespiti' | 'page:fotograf-moderasyon' | 'page:feature-flags'
  | 'page:api-anahtarlari' | 'page:roller' | 'page:gozlemlenebilirlik'
  | 'page:gelistirme-araclari' | 'page:kvkk-gdpr' | 'page:gecici-yuklemeler';

export interface AdminPermissionInfo {
  key: AdminPermissionKey;
  label: string;
  group: 'Operasyon' | 'Büyüme ve Gelir' | 'Güvenlik ve Sistem';
  href: string;
}

// src/ui/kabuk/yonetici-kabuk-istemcisi.tsx'teki adminNavSections ile birebir
// senkron tutulmalı (yeni bir admin sayfası eklenince buraya da eklenir, ve
// migration'daki admin_permission_key enum'una da eklenir).
export const ADMIN_PERMISSIONS: AdminPermissionInfo[] = [
  { key: 'page:isletmeler', label: 'İşletmeler', group: 'Operasyon', href: '/yonetici/isletmeler' },
  { key: 'page:zincirler', label: 'Zincirler', group: 'Operasyon', href: '/yonetici/zincirler' },
  { key: 'page:kuyruklar', label: 'Kuyruklar', group: 'Operasyon', href: '/yonetici/kuyruklar' },
  { key: 'page:isletme-basvurulari', label: 'İşletme Talepleri', group: 'Operasyon', href: '/yonetici/isletme-basvurulari' },
  { key: 'page:raporlar', label: 'Raporlar', group: 'Operasyon', href: '/yonetici/raporlar' },
  { key: 'page:kullanicilar', label: 'Kullanıcılar', group: 'Operasyon', href: '/yonetici/kullanicilar' },
  { key: 'page:yorumlar', label: 'Yorumlar', group: 'Operasyon', href: '/yonetici/yorumlar' },
  { key: 'page:itirazlar', label: 'İtirazlar', group: 'Operasyon', href: '/yonetici/itirazlar' },
  { key: 'page:fis-basvurulari', label: 'Fiş Başvuruları', group: 'Operasyon', href: '/yonetici/fis-basvurulari' },
  { key: 'page:cop-kutusu', label: 'Silinmiş Menüler', group: 'Operasyon', href: '/yonetici/cop-kutusu' },
  { key: 'page:olaylar', label: 'Olaylar', group: 'Operasyon', href: '/yonetici/olaylar' },
  { key: 'page:konumlar', label: 'Konumlar', group: 'Operasyon', href: '/yonetici/konumlar' },
  { key: 'page:analitik', label: 'Analitik', group: 'Büyüme ve Gelir', href: '/yonetici/analitik' },
  { key: 'page:musteri-destek', label: 'Müşteri Destek', group: 'Büyüme ve Gelir', href: '/yonetici/musteri-destek' },
  { key: 'page:oneriler', label: 'Öneriler', group: 'Büyüme ve Gelir', href: '/yonetici/oneriler' },
  { key: 'page:fiyat-onerileri', label: 'Fiyat Önerileri', group: 'Büyüme ve Gelir', href: '/yonetici/fiyat-onerileri' },
  { key: 'page:fraud-tespiti', label: 'Fraud Tespiti', group: 'Güvenlik ve Sistem', href: '/yonetici/fraud-tespiti' },
  { key: 'page:fotograf-moderasyon', label: 'Fotoğraf Moderasyon', group: 'Güvenlik ve Sistem', href: '/yonetici/fotograf-moderasyon' },
  { key: 'page:feature-flags', label: 'Feature Flags', group: 'Güvenlik ve Sistem', href: '/yonetici/feature-flags' },
  { key: 'page:api-anahtarlari', label: 'API Anahtarları', group: 'Güvenlik ve Sistem', href: '/yonetici/api-anahtarlari' },
  { key: 'page:roller', label: 'Roller', group: 'Güvenlik ve Sistem', href: '/yonetici/roller' },
  { key: 'page:gozlemlenebilirlik', label: 'Gözlemlenebilirlik', group: 'Güvenlik ve Sistem', href: '/yonetici/gozlemlenebilirlik' },
  { key: 'page:gelistirme-araclari', label: 'Geliştirici Araçları', group: 'Güvenlik ve Sistem', href: '/yonetici/gelistirme-araclari' },
  { key: 'page:kvkk-gdpr', label: 'KVKK / GDPR', group: 'Güvenlik ve Sistem', href: '/yonetici/kvkk-gdpr' },
  { key: 'page:gecici-yuklemeler', label: 'Geçici Yüklemeler', group: 'Güvenlik ve Sistem', href: '/yonetici/gecici-yuklemeler' },
];

export const ADMIN_PERMISSION_GROUPS = Array.from(new Set(ADMIN_PERMISSIONS.map((p) => p.group)));
```

---

### Task 4: Sunucu yetki yardımcısı — `src/lib/yetki-kontrol.ts`

**Files:**
- Create: `uygulamalar/web/src/lib/yetki-kontrol.ts`

- [ ] **Step 1: Dosyayı oluştur**

```ts
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import type { AdminPermissionKey } from '@/src/lib/admin-izinler';

/** Server Component'lerde sayfa erişimi kontrolü için. route.ts'lerde is_admin() + RPC'nin kendi has_permission_v1 guard'ı yeterli, bu helper'a gerek yok. */
export async function hasPermission(permission: AdminPermissionKey): Promise<boolean> {
  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as { rpc: (fn: string, args?: Record<string, unknown>) => Promise<{ data: unknown }> };
  const { data } = await sb.rpc('has_permission_v1', { p_permission: permission });
  return data === true;
}
```

---

### Task 5: Yetkisiz erişim bileşeni — `src/ui/bilesenler/yetkisiz-erisim.tsx`

**Files:**
- Create: `uygulamalar/web/src/ui/bilesenler/yetkisiz-erisim.tsx`

- [ ] **Step 1: Dosyayı oluştur**

```tsx
import { PanelEmptyState } from './panel-bos-durum';

export function YetkisizErisim({ sayfaAdi }: { sayfaAdi: string }) {
  return (
    <PanelEmptyState
      icon={<LockIcon />}
      title="Bu sayfaya erişim yetkiniz yok"
      description={`${sayfaAdi} sayfasını görüntülemek için gereken izne sahip değilsiniz. İhtiyacınız varsa bir Süper Admin'den rolünüze bu izni eklemesini isteyin.`}
    />
  );
}

function LockIcon() {
  return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="11" width="18" height="11" rx="2" ry="2" /><path d="M7 11V7a5 5 0 0 1 10 0v4" />
    </svg>
  );
}
```

---

### Task 6: Rol CRUD route'u — `app/sunucu/yonetici/roller/route.ts`

**Files:**
- Create: `uygulamalar/web/app/sunucu/yonetici/roller/route.ts`

- [ ] **Step 1: Dosyayı oluştur**

```ts
import { NextResponse } from 'next/server';
import { rateLimit } from '@/src/lib/oran-siniri';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { z } from 'zod';
import { ADMIN_PERMISSIONS, type AdminPermissionKey } from '@/src/lib/admin-izinler';

const permissionKeys = ADMIN_PERMISSIONS.map((p) => p.key) as [AdminPermissionKey, ...AdminPermissionKey[]];
const permissionEnum = z.enum(permissionKeys);

const createSchema = z.object({
  name: z.string().min(1).max(60),
  description: z.string().max(200).optional(),
  permissions: z.array(permissionEnum),
});
const updateSchema = z.object({
  id: z.string().uuid(),
  name: z.string().min(1).max(60),
  description: z.string().max(200).optional(),
  permissions: z.array(permissionEnum),
  isActive: z.boolean(),
});
const deleteSchema = z.object({ id: z.string().uuid() });

type SupabaseAny = { rpc: (fn: string, args?: Record<string, unknown>) => Promise<{ data: unknown; error: { message?: string } | null }> };

async function guard(sb: SupabaseAny, userId: string): Promise<NextResponse | null> {
  const { data: isAdmin } = await sb.rpc('is_admin');
  if (!isAdmin) return NextResponse.json({ error: 'forbidden' }, { status: 403 });

  const rl = rateLimit(`roller:${userId}`, 30, 3_600_000);
  if (!rl.ok) return NextResponse.json({ error: 'rate_limited' }, { status: 429 });

  const { data: dbRate } = await sb.rpc('consume_rate_limit_v1', { p_action: 'admin_roller_write', p_daily_limit: 30 });
  if (dbRate && (dbRate as { ok?: boolean }).ok === false) {
    return NextResponse.json({ error: 'rate_limited' }, { status: 429 });
  }
  return null;
}

function mapPgError(error: { message?: string } | null): { status: number; error: string } {
  const msg = error?.message ?? '';
  if (msg.includes('unauthorized')) return { status: 403, error: 'forbidden' };
  if (msg.includes('not_found')) return { status: 404, error: 'not_found' };
  if (msg.includes('validation_error')) return { status: 422, error: msg.replace('validation_error: ', '') };
  return { status: 500, error: 'internal_error' };
}

export async function POST(request: Request) {
  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as SupabaseAny;
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'unauthorized' }, { status: 401 });

  const guardRes = await guard(sb, user.id);
  if (guardRes) return guardRes;

  const parsed = createSchema.safeParse(await request.json().catch(() => null));
  if (!parsed.success) return NextResponse.json({ error: 'invalid_payload', issues: parsed.error.flatten().fieldErrors }, { status: 400 });

  const { data, error } = await sb.rpc('admin_create_role_v1', {
    p_name: parsed.data.name,
    p_description: parsed.data.description ?? null,
    p_permissions: parsed.data.permissions,
  });
  if (error) {
    const m = mapPgError(error);
    return NextResponse.json({ error: m.error }, { status: m.status });
  }
  return NextResponse.json({ data: { id: data } }, { status: 200 });
}

export async function PATCH(request: Request) {
  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as SupabaseAny;
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'unauthorized' }, { status: 401 });

  const guardRes = await guard(sb, user.id);
  if (guardRes) return guardRes;

  const parsed = updateSchema.safeParse(await request.json().catch(() => null));
  if (!parsed.success) return NextResponse.json({ error: 'invalid_payload', issues: parsed.error.flatten().fieldErrors }, { status: 400 });

  const { error } = await sb.rpc('admin_update_role_v1', {
    p_role_id: parsed.data.id,
    p_name: parsed.data.name,
    p_description: parsed.data.description ?? null,
    p_permissions: parsed.data.permissions,
    p_is_active: parsed.data.isActive,
  });
  if (error) {
    const m = mapPgError(error);
    return NextResponse.json({ error: m.error }, { status: m.status });
  }
  return NextResponse.json({ data: { ok: true } }, { status: 200 });
}

export async function DELETE(request: Request) {
  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as SupabaseAny;
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'unauthorized' }, { status: 401 });

  const guardRes = await guard(sb, user.id);
  if (guardRes) return guardRes;

  const parsed = deleteSchema.safeParse(await request.json().catch(() => null));
  if (!parsed.success) return NextResponse.json({ error: 'invalid_payload' }, { status: 400 });

  const { error } = await sb.rpc('admin_delete_role_v1', { p_role_id: parsed.data.id });
  if (error) {
    const m = mapPgError(error);
    return NextResponse.json({ error: m.error }, { status: m.status });
  }
  return NextResponse.json({ data: { ok: true } }, { status: 200 });
}
```

---

### Task 7: Kullanıcı-rol atama route'u — `app/sunucu/yonetici/roller/kullanici-ata/route.ts`

**Files:**
- Create: `uygulamalar/web/app/sunucu/yonetici/roller/kullanici-ata/route.ts`

- [ ] **Step 1: Dosyayı oluştur**

```ts
import { NextResponse } from 'next/server';
import { rateLimit } from '@/src/lib/oran-siniri';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { z } from 'zod';

const schema = z.object({ userId: z.string().uuid(), roleId: z.string().uuid() });

export async function PATCH(request: Request) {
  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as { rpc: (fn: string, args?: Record<string, unknown>) => Promise<{ data: unknown; error: { message?: string } | null }> };
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'unauthorized' }, { status: 401 });

  const { data: isAdmin } = await sb.rpc('is_admin');
  if (!isAdmin) return NextResponse.json({ error: 'forbidden' }, { status: 403 });

  const rl = rateLimit(`roller-atama:${user.id}`, 30, 3_600_000);
  if (!rl.ok) return NextResponse.json({ error: 'rate_limited' }, { status: 429 });

  const { data: dbRate } = await sb.rpc('consume_rate_limit_v1', { p_action: 'admin_rol_atama', p_daily_limit: 30 });
  if (dbRate && (dbRate as { ok?: boolean }).ok === false) {
    return NextResponse.json({ error: 'rate_limited' }, { status: 429 });
  }

  const parsed = schema.safeParse(await request.json().catch(() => null));
  if (!parsed.success) return NextResponse.json({ error: 'invalid_payload' }, { status: 400 });

  const { error } = await sb.rpc('admin_assign_user_role_v1', { p_user_id: parsed.data.userId, p_role_id: parsed.data.roleId });
  if (error) {
    const msg = error.message ?? '';
    if (msg.includes('unauthorized')) return NextResponse.json({ error: 'forbidden' }, { status: 403 });
    if (msg.includes('not_found')) return NextResponse.json({ error: 'not_found' }, { status: 404 });
    return NextResponse.json({ error: 'internal_error' }, { status: 500 });
  }
  return NextResponse.json({ data: { ok: true } }, { status: 200 });
}
```

---

### Task 8: Yardımcı fonksiyonlar — `app/yonetici/roller/roller-yardimcilari.ts`

**Files:**
- Create: `uygulamalar/web/app/yonetici/roller/roller-yardimcilari.ts`

- [ ] **Step 1: Dosyayı oluştur**

```ts
import type { AdminPermissionKey } from '@/src/lib/admin-izinler';

export interface AdminRole {
  id: string;
  name: string;
  description: string | null;
  is_system: boolean;
  is_active: boolean;
  permissions: AdminPermissionKey[];
  created_at: string;
  updated_at: string;
  updated_by: string | null;
  updated_by_name?: string | null;
  userCount: number;
}

export function trend(current: number, previous: number): { value: number; label?: string } | undefined {
  if (previous === 0) return current === 0 ? undefined : { value: 100, label: 'önceki 7 gün: 0' };
  const pct = Math.round(((current - previous) / previous) * 100);
  return { value: pct, label: `önceki 7 gün: ${previous}` };
}

export function goreliZaman(iso: string): string {
  const diffMs = Date.now() - new Date(iso).getTime();
  const diffDay = Math.floor(diffMs / 86_400_000);
  if (diffDay < 1) return 'bugün';
  if (diffDay === 1) return '1 gün önce';
  if (diffDay < 7) return `${diffDay} gün önce`;
  const diffWeek = Math.floor(diffDay / 7);
  if (diffWeek < 5) return `${diffWeek} hafta önce`;
  return new Date(iso).toLocaleDateString('tr-TR');
}

export function rolCsvOlustur(rows: AdminRole[]): string {
  const header = ['Rol Adı', 'Açıklama', 'Tür', 'Kullanıcı Sayısı', 'Durum', 'Son Güncelleme', 'Güncelleyen'];
  const lines = rows.map((r) => [
    r.name,
    r.description ?? '',
    r.is_system ? 'Sistem' : 'Özel',
    String(r.userCount),
    r.is_active ? 'Aktif' : 'Pasif',
    new Date(r.updated_at).toLocaleString('tr-TR'),
    r.updated_by_name ?? '',
  ].map((v) => `"${String(v).replace(/"/g, '""')}"`).join(','));
  return [header.join(','), ...lines].join('\n');
}
```

---

### Task 9: Rol oluştur/düzenle modalı — `app/yonetici/roller/rol-modal.tsx`

**Files:**
- Create: `uygulamalar/web/app/yonetici/roller/rol-modal.tsx`

- [ ] **Step 1: Dosyayı oluştur**

```tsx
'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { X } from 'lucide-react';
import { ADMIN_PERMISSIONS, ADMIN_PERMISSION_GROUPS, type AdminPermissionKey } from '@/src/lib/admin-izinler';
import type { AdminRole } from './roller-yardimcilari';

export function YeniRolButonu({ variant = 'primary' }: { variant?: 'primary' | 'list' }) {
  const [open, setOpen] = useState(false);
  return (
    <>
      {variant === 'primary' ? (
        <button
          type="button"
          onClick={() => setOpen(true)}
          className="flex items-center gap-2 rounded-xl bg-primary px-4 py-2.5 text-sm font-extrabold text-white transition-opacity hover:opacity-90"
        >
          <PlusIcon /> Yeni Rol Oluştur
        </button>
      ) : (
        <button
          type="button"
          onClick={() => setOpen(true)}
          className="flex items-center gap-3 rounded-xl border border-border px-3 py-2.5 text-left transition-colors hover:border-primary/30 hover:bg-black/2"
        >
          <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-(--yd-color-primary)"><PlusIcon /></div>
          <div className="min-w-0">
            <p className="text-xs font-extrabold text-textStrong">Yeni Rol Oluştur</p>
            <p className="truncate text-[10px] text-muted">Sıfırdan yeni bir rol tanımlayın</p>
          </div>
        </button>
      )}
      {open && <RolModal onClose={() => setOpen(false)} />}
    </>
  );
}

export function EditRolButonu({ role }: { role: AdminRole }) {
  const [open, setOpen] = useState(false);
  return (
    <>
      <button
        type="button"
        onClick={() => setOpen(true)}
        title="Düzenle"
        className="rounded-lg border border-border px-2.5 py-1.5 text-xs font-bold text-textStrong transition-colors hover:border-primary/30 hover:text-primary"
      >
        Düzenle
      </button>
      {open && <RolModal onClose={() => setOpen(false)} role={role} />}
    </>
  );
}

function RolModal({ onClose, role }: { onClose: () => void; role?: AdminRole }) {
  const router = useRouter();
  const [pending, setPending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [name, setName] = useState(role?.name ?? '');
  const [description, setDescription] = useState(role?.description ?? '');
  const [isActive, setIsActive] = useState(role?.is_active ?? true);
  const [permissions, setPermissions] = useState<Set<AdminPermissionKey>>(new Set(role?.permissions ?? []));

  const readOnly = role?.is_system ?? false;

  function toggle(key: AdminPermissionKey) {
    setPermissions((prev) => {
      const s = new Set(prev);
      if (s.has(key)) s.delete(key); else s.add(key);
      return s;
    });
  }
  function toggleGroup(group: string, hepsi: boolean) {
    const keys = ADMIN_PERMISSIONS.filter((p) => p.group === group).map((p) => p.key);
    setPermissions((prev) => {
      const s = new Set(prev);
      keys.forEach((k) => { if (hepsi) s.add(k); else s.delete(k); });
      return s;
    });
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!name.trim() || readOnly) return;
    setPending(true);
    setError(null);
    try {
      const body = { name: name.trim(), description: description.trim() || undefined, permissions: Array.from(permissions) };
      const res = role
        ? await fetch('/sunucu/yonetici/roller', { method: 'PATCH', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ id: role.id, ...body, isActive }) })
        : await fetch('/sunucu/yonetici/roller', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) });
      const json = await res.json().catch(() => ({}));
      if (!res.ok) { setError(json.error ?? 'Hata oluştu'); return; }
      router.refresh();
      onClose();
    } catch {
      setError('Bağlantı hatası');
    } finally {
      setPending(false);
    }
  }

  return (
    <>
      <div className="fixed inset-0 z-40 bg-black/30" onClick={onClose} aria-hidden="true" />
      <div className="fixed left-1/2 top-1/2 z-50 w-full max-w-xl -translate-x-1/2 -translate-y-1/2 rounded-2xl border border-border bg-white p-6 shadow-2xl">
        <div className="mb-4 flex items-center justify-between">
          <h2 className="text-lg font-black text-textStrong">{role ? 'Rolü Düzenle' : 'Yeni Rol'}</h2>
          <button onClick={onClose} className="rounded-lg p-1.5 text-muted hover:bg-black/4 hover:text-textStrong" aria-label="Kapat">
            <X className="h-4 w-4" />
          </button>
        </div>

        {readOnly ? (
          <p className="rounded-xl border border-border bg-cardAlt px-4 py-3 text-sm text-muted">Sistem rolleri (Süper Admin) düzenlenemez.</p>
        ) : (
          <form onSubmit={handleSubmit} className="flex max-h-[70vh] flex-col gap-4 overflow-y-auto">
            <div className="flex flex-col gap-1.5">
              <label className="text-sm font-bold text-textStrong">Rol Adı</label>
              <input type="text" value={name} onChange={(e) => setName(e.target.value)} required maxLength={60} className="input-yd rounded-xl px-3 py-2.5 text-sm" placeholder="ör. Destek Ekibi" />
            </div>
            <div className="flex flex-col gap-1.5">
              <label className="text-sm font-bold text-textStrong">Açıklama</label>
              <input type="text" value={description} onChange={(e) => setDescription(e.target.value)} maxLength={200} className="input-yd rounded-xl px-3 py-2.5 text-sm" placeholder="Bu rol ne için kullanılıyor?" />
            </div>
            {role && (
              <label className="flex items-center gap-2 text-sm font-bold text-textStrong">
                <input type="checkbox" checked={isActive} onChange={(e) => setIsActive(e.target.checked)} className="h-4 w-4 rounded border-border" />
                Aktif
              </label>
            )}
            <div className="flex flex-col gap-3">
              <p className="text-sm font-bold text-textStrong">İzinler ({permissions.size} seçili)</p>
              {ADMIN_PERMISSION_GROUPS.map((group) => {
                const items = ADMIN_PERMISSIONS.filter((p) => p.group === group);
                const hepsiSecili = items.every((p) => permissions.has(p.key));
                return (
                  <div key={group} className="rounded-xl border border-border p-3">
                    <div className="mb-2 flex items-center justify-between">
                      <p className="text-xs font-extrabold uppercase tracking-wide text-muted">{group}</p>
                      <button type="button" onClick={() => toggleGroup(group, !hepsiSecili)} className="text-[11px] font-bold text-primary hover:underline">
                        {hepsiSecili ? 'Hiçbirini seçme' : 'Hepsini seç'}
                      </button>
                    </div>
                    <div className="grid grid-cols-2 gap-1.5 sm:grid-cols-3">
                      {items.map((p) => (
                        <label key={p.key} className="flex items-center gap-1.5 text-xs font-bold text-textStrong">
                          <input type="checkbox" checked={permissions.has(p.key)} onChange={() => toggle(p.key)} className="h-3.5 w-3.5 rounded border-border" />
                          {p.label}
                        </label>
                      ))}
                    </div>
                  </div>
                );
              })}
            </div>
            {error && <p className="text-sm font-bold text-danger">{error}</p>}
            <div className="flex justify-end gap-2">
              <button type="button" onClick={onClose} className="rounded-xl border border-border px-4 py-2.5 text-sm font-bold text-muted hover:text-textStrong">İptal</button>
              <button type="submit" disabled={pending} className="rounded-xl bg-primary px-4 py-2.5 text-sm font-bold text-white disabled:opacity-50">
                {pending ? 'Kaydediliyor…' : role ? 'Kaydet' : 'Rol Oluştur'}
              </button>
            </div>
          </form>
        )}
      </div>
    </>
  );
}

function PlusIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="12" y1="5" x2="12" y2="19" /><line x1="5" y1="12" x2="19" y2="12" /></svg>;
}
```

---

### Task 10: Rol tablosu (+ kullanıcı atama) — `app/yonetici/roller/rol-tablosu.tsx`

**Files:**
- Create: `uygulamalar/web/app/yonetici/roller/rol-tablosu.tsx`

- [ ] **Step 1: Dosyayı oluştur**

```tsx
'use client';

import { Fragment, useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import type { AdminRole } from './roller-yardimcilari';
import { EditRolButonu } from './rol-modal';

interface Uye { user_id: string; role_id: string; created_at: string }

export function RolTablosu({ roles, members, nameByUserId }: { roles: AdminRole[]; members: Uye[]; nameByUserId: Record<string, string> }) {
  const router = useRouter();
  const [genisletilen, setGenisletilen] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();
  const [tasima, setTasima] = useState<Record<string, string>>({});

  function tasi(userId: string, currentRoleId: string) {
    const hedefRoleId = tasima[userId];
    if (!hedefRoleId || hedefRoleId === currentRoleId) return;
    startTransition(async () => {
      const res = await fetch('/sunucu/yonetici/roller/kullanici-ata', {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ userId, roleId: hedefRoleId }),
      });
      const json = await res.json().catch(() => ({}));
      if (!res.ok) { alert(json.error ?? 'Taşınamadı'); return; }
      router.refresh();
    });
  }

  function sil(roleId: string) {
    if (!confirm('Bu rol silinecek. Devam et?')) return;
    startTransition(async () => {
      const res = await fetch('/sunucu/yonetici/roller', {
        method: 'DELETE',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id: roleId }),
      });
      const json = await res.json().catch(() => ({}));
      if (!res.ok) { alert(json.error ?? 'Silinemedi'); return; }
      router.refresh();
    });
  }

  return (
    <div className="overflow-hidden rounded-2xl border border-border bg-card">
      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-border text-left">
              <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Rol Adı</th>
              <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Açıklama</th>
              <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Tür</th>
              <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Kullanıcı Sayısı</th>
              <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Durum</th>
              <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Son Güncelleme</th>
              <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">İşlemler</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {roles.map((r) => {
              const uyeler = members.filter((m) => m.role_id === r.id);
              const acik = genisletilen === r.id;
              return (
                <Fragment key={r.id}>
                  <tr className="hover:bg-black/2">
                    <td className="px-4 py-3">
                      <span className="font-extrabold text-textStrong">{r.name}</span>
                      <span className="ml-1.5 rounded-full bg-zinc-100 px-2 py-0.5 text-[10px] font-bold text-zinc-600">{r.is_system ? 'Sistem' : 'Özel'}</span>
                    </td>
                    <td className="max-w-[220px] px-4 py-3 text-xs text-muted">{r.description ?? '—'}</td>
                    <td className="px-4 py-3 text-xs text-muted">{r.is_system ? 'Sistem' : 'Özel'}</td>
                    <td className="px-4 py-3">
                      <button
                        type="button"
                        onClick={() => setGenisletilen(acik ? null : r.id)}
                        disabled={uyeler.length === 0}
                        className="font-extrabold text-primary underline decoration-dotted disabled:text-muted disabled:no-underline"
                      >
                        {uyeler.length}
                      </button>
                    </td>
                    <td className="px-4 py-3">
                      <span className={`inline-flex rounded-full px-2 py-0.5 text-[10px] font-bold ${r.is_active ? 'bg-emerald-50 text-emerald-700' : 'bg-zinc-100 text-zinc-600'}`}>
                        {r.is_active ? 'Aktif' : 'Pasif'}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-xs text-muted">
                      <p>{new Date(r.updated_at).toLocaleDateString('tr-TR')}</p>
                      {r.updated_by_name && <p className="text-[10px]">{r.updated_by_name}</p>}
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-1.5">
                        <EditRolButonu role={r} />
                        <button
                          type="button"
                          disabled={r.is_system || uyeler.length > 0 || isPending}
                          onClick={() => sil(r.id)}
                          title={r.is_system ? 'Sistem rolü silinemez' : uyeler.length > 0 ? 'Önce kullanıcıları başka role taşıyın' : 'Sil'}
                          className="rounded-lg border border-danger/30 px-2.5 py-1.5 text-xs font-bold text-danger transition-colors hover:bg-danger/6 disabled:cursor-not-allowed disabled:opacity-40"
                        >
                          Sil
                        </button>
                      </div>
                    </td>
                  </tr>
                  {acik && uyeler.length > 0 && (
                    <tr>
                      <td colSpan={7} className="bg-cardAlt px-6 py-4">
                        <p className="mb-2 text-[11px] font-extrabold uppercase tracking-wide text-muted">Bu Role Atanmış Kullanıcılar</p>
                        <div className="flex flex-col gap-2">
                          {uyeler.map((u) => (
                            <div key={u.user_id} className="flex items-center justify-between gap-3 rounded-lg border border-border bg-card px-3 py-2">
                              <span className="text-xs font-bold text-textStrong">{nameByUserId[u.user_id] ?? u.user_id.slice(0, 12)}</span>
                              <div className="flex items-center gap-2">
                                <select
                                  value={tasima[u.user_id] ?? r.id}
                                  onChange={(e) => setTasima((prev) => ({ ...prev, [u.user_id]: e.target.value }))}
                                  className="rounded-lg border border-border bg-bg px-2 py-1 text-xs font-bold text-textStrong"
                                >
                                  {roles.map((rr) => <option key={rr.id} value={rr.id}>{rr.name}</option>)}
                                </select>
                                <button type="button" disabled={isPending} onClick={() => tasi(u.user_id, r.id)} className="rounded-lg bg-primary px-2.5 py-1 text-xs font-bold text-white disabled:opacity-50">
                                  Taşı
                                </button>
                              </div>
                            </div>
                          ))}
                        </div>
                      </td>
                    </tr>
                  )}
                </Fragment>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}
```

---

### Task 11: CSV dışa aktarma — `app/yonetici/roller/disa-aktar-butonu.tsx`

**Files:**
- Create: `uygulamalar/web/app/yonetici/roller/disa-aktar-butonu.tsx`

- [ ] **Step 1: Dosyayı oluştur**

```tsx
'use client';

import { rolCsvOlustur, type AdminRole } from './roller-yardimcilari';

export function DisaAktarButonu({ rows }: { rows: AdminRole[] }) {
  function disaAktar() {
    const csv = rolCsvOlustur(rows);
    const blob = new Blob(['﻿' + csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `roller-${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  }

  return (
    <button
      type="button"
      onClick={disaAktar}
      disabled={rows.length === 0}
      title="Bu görünümdeki (filtrelenmiş) rolleri CSV olarak indir"
      className="flex min-h-11 items-center gap-2 rounded-xl border border-border px-4 text-xs font-extrabold text-textStrong transition-colors hover:border-primary/30 hover:text-primary disabled:cursor-not-allowed disabled:opacity-50"
    >
      <DownloadIcon /> Dışa Aktar
    </button>
  );
}

function DownloadIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" /><polyline points="7 10 12 15 17 10" /><line x1="12" y1="15" x2="12" y2="3" />
    </svg>
  );
}
```

---

### Task 12: Roller sayfasını tamamen yeniden yaz — `app/yonetici/roller/page.tsx`

**Files:**
- Modify (tam değiştir): `uygulamalar/web/app/yonetici/roller/page.tsx`

- [ ] **Step 1: Dosyanın tamamını aşağıdaki içerikle değiştir**

```tsx
import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { MetricCard } from '@/src/ui/bilesenler/olcum-karti';
import { YetkisizErisim } from '@/src/ui/bilesenler/yetkisiz-erisim';
import { hasPermission } from '@/src/lib/yetki-kontrol';
import { trend, goreliZaman, type AdminRole } from './roller-yardimcilari';
import { RolTablosu } from './rol-tablosu';
import { YeniRolButonu } from './rol-modal';
import { DisaAktarButonu } from './disa-aktar-butonu';

export const metadata: Metadata = {
  title: 'Roller | Yönetici Paneli',
  robots: { index: false, follow: false },
};

const DAY = 86_400_000;

type Props = { searchParams: Promise<{ q?: string; durum?: string }> };

export default async function RollerPage({ searchParams }: Props) {
  const yetkili = await hasPermission('page:roller');
  if (!yetkili) {
    return (
      <div className="flex flex-col">
        <PanelSayfaBasligi eyebrow="Yönetici" title="Roller" description="Kullanıcı rollerini yönetin ve her rol için izinleri tanımlayın." />
        <PanelIcerikYuzeyi className="pt-6"><YetkisizErisim sayfaAdi="Roller" /></PanelIcerikYuzeyi>
      </div>
    );
  }

  const { q = '', durum = '' } = await searchParams;
  const supabase = await createSupabaseServerClient();
  const sb = supabase as any;

  const [{ data: rawRoles }, { data: rawMembers }] = await Promise.all([
    sb.from('admin_roles').select('id, name, description, is_system, is_active, permissions, created_at, updated_at, updated_by').order('created_at', { ascending: true }),
    sb.from('admin_users').select('user_id, role_id, created_at'),
  ]);

  const roles = (rawRoles ?? []) as Array<Omit<AdminRole, 'userCount' | 'updated_by_name'>>;
  const members = (rawMembers ?? []) as Array<{ user_id: string; role_id: string; created_at: string }>;

  const countByRole = new Map<string, number>();
  for (const m of members) countByRole.set(m.role_id, (countByRole.get(m.role_id) ?? 0) + 1);

  const updaterIds = Array.from(new Set(roles.map((r) => r.updated_by).filter((v): v is string => !!v)));
  const memberIds = Array.from(new Set(members.map((m) => m.user_id)));
  const profileIds = Array.from(new Set([...updaterIds, ...memberIds]));
  const nameByUserId = new Map<string, string>();
  if (profileIds.length > 0) {
    const { data: profiles } = await sb.from('user_profiles').select('user_id, display_name').in('user_id', profileIds);
    for (const p of (profiles ?? []) as Array<{ user_id: string; display_name: string | null }>) {
      if (p.display_name) nameByUserId.set(p.user_id, p.display_name);
    }
  }

  const withCounts: AdminRole[] = roles.map((r) => ({
    ...r,
    userCount: countByRole.get(r.id) ?? 0,
    updated_by_name: r.updated_by ? nameByUserId.get(r.updated_by) ?? null : null,
  }));

  const qNorm = q.trim().toLocaleLowerCase('tr-TR');
  const filtered = withCounts.filter((r) => {
    if (durum === 'aktif' && !r.is_active) return false;
    if (durum === 'pasif' && r.is_active) return false;
    if (qNorm) {
      const hay = `${r.name} ${r.description ?? ''}`.toLocaleLowerCase('tr-TR');
      if (!hay.includes(qNorm)) return false;
    }
    return true;
  });

  const total = withCounts.length;
  const activeCount = withCounts.filter((r) => r.is_active).length;
  const systemCount = withCounts.filter((r) => r.is_system).length;
  const customCount = total - systemCount;
  const assignedUserCount = members.length;

  const now = Date.now();
  const thisWeek = withCounts.filter((r) => new Date(r.updated_at).getTime() >= now - 7 * DAY).length;
  const lastWeek = withCounts.filter((r) => {
    const ts = new Date(r.updated_at).getTime();
    return ts >= now - 14 * DAY && ts < now - 7 * DAY;
  }).length;

  const sonGuncellenen = [...withCounts].sort((a, b) => new Date(b.updated_at).getTime() - new Date(a.updated_at).getTime())[0];

  const turDagilimi: Array<[string, number, string]> = ([
    ['Sistem', systemCount, '#7c3aed'],
    ['Özel', customCount, '#2563eb'],
  ] as Array<[string, number, string]>).filter(([, n]) => n > 0);

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Yönetici"
        title="Roller"
        description="Kullanıcı rollerini yönetin ve her rol için izinleri tanımlayın."
        actions={<YeniRolButonu />}
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-6">
          <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-6">
            <MetricCard title="Toplam Rol" value={total.toLocaleString('tr-TR')} icon={<UsersIcon />} />
            <MetricCard title="Aktif Rol" value={activeCount.toLocaleString('tr-TR')} subtitle={total ? `%${Math.round((activeCount / total) * 100)}` : undefined} icon={<CheckIcon />} trend={trend(thisWeek, lastWeek)} />
            <MetricCard title="Sistem Rolü" value={systemCount.toLocaleString('tr-TR')} subtitle="Sistem tarafından tanımlı" icon={<LockIcon />} />
            <MetricCard title="Özel Rol" value={customCount.toLocaleString('tr-TR')} subtitle="Özel olarak oluşturulmuş" icon={<PlusIcon />} />
            <MetricCard title="Kullanıcı Atanan" value={assignedUserCount.toLocaleString('tr-TR')} subtitle="Toplam admin kullanıcı" icon={<ShieldIcon />} />
            <MetricCard title="Son Güncelleme" value={sonGuncellenen ? goreliZaman(sonGuncellenen.updated_at) : '—'} subtitle={sonGuncellenen?.updated_by_name ?? undefined} icon={<ClockIcon />} />
          </div>

          <div className="grid gap-6 lg:grid-cols-[1fr_300px]">
            <div className="flex min-w-0 flex-col gap-4">
              <form method="get" className="grid gap-3 rounded-xl border border-border bg-card p-3 md:grid-cols-3">
                <input
                  name="q"
                  defaultValue={q}
                  placeholder="Rol adı, açıklama ara..."
                  className="min-h-11 rounded-xl border border-border bg-bg px-4 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30 md:col-span-2"
                />
                <select name="durum" defaultValue={durum} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30">
                  <option value="">Durum: Tümü</option>
                  <option value="aktif">Aktif</option>
                  <option value="pasif">Pasif</option>
                </select>
                <div className="flex gap-2 md:col-span-3">
                  <button type="submit" className="min-h-11 rounded-xl bg-primary px-4 text-sm font-extrabold text-white transition-opacity hover:opacity-90">Filtrele</button>
                  <Link href="/yonetici/roller" className="flex min-h-11 items-center rounded-xl border border-border px-4 text-sm font-bold text-muted hover:bg-black/4">Temizle</Link>
                  <div className="ml-auto"><DisaAktarButonu rows={filtered} /></div>
                </div>
              </form>

              {filtered.length === 0 ? (
                <PanelEmptyState
                  icon={<UsersIcon />}
                  title={total === 0 ? 'Henüz rol yok' : 'Sonuç bulunamadı'}
                  description={total === 0 ? 'Sistem kurulumunda Süper Admin rolü otomatik oluşturulur.' : 'Seçili filtrelere uygun rol yok.'}
                />
              ) : (
                <RolTablosu roles={filtered} members={members} nameByUserId={Object.fromEntries(nameByUserId)} />
              )}
            </div>

            <div className="flex flex-col gap-4">
              <PanelBolumKarti title="Rol Türlerine Göre Dağılım">
                {turDagilimi.length === 0 ? <p className="text-xs text-muted">Veri yok.</p> : <Donut veriler={turDagilimi} toplam={total} />}
              </PanelBolumKarti>

              <PanelBolumKarti title="Rol Durumuna Göre Dağılım">
                <div className="flex flex-col gap-3">
                  {([['Aktif', activeCount, '#059669'], ['Pasif', total - activeCount, '#94a3b8']] as Array<[string, number, string]>).map(([label, n, renk]) => (
                    <div key={label} className="flex flex-col gap-1">
                      <div className="flex items-center justify-between text-xs">
                        <span className="font-bold text-textStrong">{label}</span>
                        <span className="font-extrabold text-muted">{n} {total ? `(%${Math.round((n / total) * 100)})` : ''}</span>
                      </div>
                      <div className="h-2 overflow-hidden rounded-full bg-black/8">
                        <div className="h-full rounded-full" style={{ width: `${total ? (n / total) * 100 : 0}%`, background: renk }} />
                      </div>
                    </div>
                  ))}
                </div>
              </PanelBolumKarti>

              <PanelBolumKarti title="Hızlı İşlemler">
                <div className="flex flex-col gap-2">
                  <YeniRolButonu variant="list" />
                  <p className="rounded-xl border border-border px-3 py-2.5 text-[10px] text-muted">
                    Bir rolün kullanıcı sayısına tıklayarak o role atanmış kullanıcıları görüp başka role taşıyabilirsiniz.
                  </p>
                </div>
              </PanelBolumKarti>
            </div>
          </div>
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}

function Donut({ veriler, toplam }: { veriler: Array<[string, number, string]>; toplam: number }) {
  const R = 60, CX = 70, CY = 70, STROKE = 22;
  const CIRCUM = 2 * Math.PI * R;
  const uzunluklar = veriler.map(([, n]) => (n / toplam) * CIRCUM);
  const offsetler = uzunluklar.reduce<number[]>((acc, u, i) => { acc.push(i === 0 ? 0 : acc[i - 1] + uzunluklar[i - 1]); return acc; }, []);

  return (
    <div className="flex flex-col items-center gap-4">
      <svg viewBox="0 0 140 140" width="140" height="140">
        <g transform={`rotate(-90 ${CX} ${CY})`}>
          {veriler.map(([label, , renk], i) => (
            <circle key={label} cx={CX} cy={CY} r={R} fill="none" stroke={renk} strokeWidth={STROKE} strokeDasharray={`${uzunluklar[i]} ${CIRCUM - uzunluklar[i]}`} strokeDashoffset={-offsetler[i]} />
          ))}
        </g>
        <text x={CX} y={CY - 4} textAnchor="middle" fontSize="18" fontWeight="900" fill="var(--yd-color-text-strong)" fontFamily="inherit">{toplam.toLocaleString('tr-TR')}</text>
        <text x={CX} y={CY + 14} textAnchor="middle" fontSize="9" fill="var(--yd-color-muted)" fontFamily="inherit">Toplam</text>
      </svg>
      <div className="flex w-full flex-col gap-1.5">
        {veriler.map(([label, n, renk]) => (
          <div key={label} className="flex items-center justify-between gap-2 text-[11px]">
            <span className="flex min-w-0 items-center gap-1.5 font-bold text-textStrong">
              <span className="h-2 w-2 shrink-0 rounded-full" style={{ background: renk }} />
              <span className="truncate">{label}</span>
            </span>
            <span className="shrink-0 font-extrabold text-muted">{n.toLocaleString('tr-TR')} · %{Math.round((n / toplam) * 100)}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

function UsersIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /><path d="M23 21v-2a4 4 0 0 0-3-3.87" /><path d="M16 3.13a4 4 0 0 1 0 7.75" /></svg>; }
function CheckIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" /><polyline points="22 4 12 14.01 9 11.01" /></svg>; }
function LockIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="11" width="18" height="11" rx="2" ry="2" /><path d="M7 11V7a5 5 0 0 1 10 0v4" /></svg>; }
function PlusIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="12" y1="5" x2="12" y2="19" /><line x1="5" y1="12" x2="19" y2="12" /></svg>; }
function ShieldIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" /></svg>; }
function ClockIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10" /><polyline points="12 6 12 12 16 14" /></svg>; }
```

- [ ] **Step 2: Eski dosyaların artık kullanılmadığını doğrula ve kalıntı yoksa devam et**

`app/yonetici/roller/page.tsx` üstteki içerikle tam değiştirildiği için eski `ROLES`, `getUserRole`, `PermissionMatrix`, `PERMISSIONS`, `getProfilesByUserIds`, `getMetadataText` artık yok — bu normal, ayrı bir silme adımı gerekmiyor (dosya baştan yazıldı).

---

### Task 13: Kenar çubuğunu gerçek role bağla — `yonetici-kabuk-istemcisi.tsx`

**Files:**
- Modify: `uygulamalar/web/src/ui/kabuk/yonetici-kabuk-istemcisi.tsx:1-108`

- [ ] **Step 1: Import ekle**

`old_string`:
```tsx
import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';
import { usePanelStore } from '@/src/lib/panel-deposu';
```
`new_string`:
```tsx
import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';
import { usePanelStore } from '@/src/lib/panel-deposu';
import { ADMIN_PERMISSIONS } from '@/src/lib/admin-izinler';
```

- [ ] **Step 2: `ROL_ETIKETLERI` sabitini ve `useCurrentAdmin`'i gerçek role bağlı hale getir**

`old_string`:
```tsx
const ROL_ETIKETLERI: Record<string, string> = {
  super_admin: 'Süper Yönetici',
  admin: 'Yönetici',
  community_mod: 'Moderatör',
};

function useCurrentAdmin() {
  const [admin, setAdmin] = useState<{ email: string | null; displayName: string; roleLabel: string } | null>(null);
  useEffect(() => {
    const supabase = createSupabaseBrowserClient();
    void supabase.auth.getSession().then(({ data }) => {
      const user = data.session?.user;
      if (!user) return;
      const role = String(user.app_metadata?.role ?? user.user_metadata?.role ?? 'admin').toLocaleLowerCase('tr-TR');
      const localPart = user.email?.split('@')[0] ?? 'Admin';
      const displayName = localPart.charAt(0).toUpperCase() + localPart.slice(1);
      setAdmin({ email: user.email ?? null, displayName, roleLabel: ROL_ETIKETLERI[role] ?? 'Yönetici' });
    });
  }, []);
  return admin;
}

function navSectionsWithBadges(sections: NavSection[], countsByHref: Record<string, number>): NavSection[] {
  return sections.map((section) => ({
    ...section,
    items: section.items.map((item) => {
      const count = countsByHref[item.href];
      if (!count || count <= 0) return item;
      return { ...item, badge: count > 99 ? '99+' : String(count), badgeTone: 'primary' as const };
    }),
  }));
}
```
`new_string`:
```tsx
function useCurrentAdmin() {
  const [admin, setAdmin] = useState<{ email: string | null; displayName: string; roleLabel: string; permissions: string[] } | null>(null);
  useEffect(() => {
    const supabase = createSupabaseBrowserClient();
    void supabase.auth.getSession().then(async ({ data }) => {
      const user = data.session?.user;
      if (!user) return;
      const localPart = user.email?.split('@')[0] ?? 'Admin';
      const displayName = localPart.charAt(0).toUpperCase() + localPart.slice(1);
      const { data: roleRows } = await (supabase as any).rpc('get_my_admin_role_v1');
      const roleRow = Array.isArray(roleRows) ? roleRows[0] : null;
      setAdmin({
        email: user.email ?? null,
        displayName,
        roleLabel: roleRow?.role_name ?? 'Yönetici',
        permissions: roleRow?.permissions ?? [],
      });
    });
  }, []);
  return admin;
}

function navSectionsWithBadges(sections: NavSection[], countsByHref: Record<string, number>): NavSection[] {
  return sections.map((section) => ({
    ...section,
    items: section.items.map((item) => {
      const count = countsByHref[item.href];
      if (!count || count <= 0) return item;
      return { ...item, badge: count > 99 ? '99+' : String(count), badgeTone: 'primary' as const };
    }),
  }));
}

/** permissions === null: henüz yüklenmedi, tüm sayfalar gösterilir (yanıp-sönmeyi önler). Plan A'da hiçbir route henüz gerçekten kısıtlı değil, bu filtre sadece kenar çubuğu görünürlüğü içindir. */
function navSectionsWithPermissions(sections: NavSection[], permissions: string[] | null): NavSection[] {
  if (permissions === null) return sections;
  const izinliHref = new Set(ADMIN_PERMISSIONS.filter((p) => permissions.includes(p.key)).map((p) => p.href));
  return sections
    .map((section) => ({
      ...section,
      items: section.items.filter((item) => item.href === '/yonetici/gosterge-panosu' || izinliHref.has(item.href)),
    }))
    .filter((section) => section.items.length > 0);
}
```

- [ ] **Step 3: `navSections` prop'unu her iki filtreyi de uygulayacak şekilde güncelle**

`old_string`:
```tsx
        navSections={navSectionsWithBadges(adminNavSections, {
          '/yonetici/itirazlar': bekleyenItirazSayisi,
          '/yonetici/kuyruklar': bekleyenKuyrukSayisi,
        })}
```
`new_string`:
```tsx
        navSections={navSectionsWithPermissions(
          navSectionsWithBadges(adminNavSections, {
            '/yonetici/itirazlar': bekleyenItirazSayisi,
            '/yonetici/kuyruklar': bekleyenKuyrukSayisi,
          }),
          admin ? admin.permissions : null,
        )}
```

---

### Task 14: Konsolide doğrulama

- [ ] **Step 1: Typecheck**

Run: `cd uygulamalar/web && pnpm run typecheck`
Expected: çıktı yok / hata yok.

- [ ] **Step 2: Lint**

Run: `cd uygulamalar/web && pnpm run lint`
Expected: `0 errors` (mevcut `Date.now` purity uyarıları gibi önceden var olan warning'ler kabul edilebilir, bu oturumdaki tüm önceki sayfalarla aynı gate).

- [ ] **Step 3: Tarayıcıda uçtan uca doğrulama — dikkatli, geçici test rolüyle**

1. `/yonetici/roller` sayfasını aç, mockup'a uyarlanmış hali gör: 6 stat kartı (Toplam Rol=1, Aktif Rol=1, Sistem Rolü=1, Özel Rol=0, Kullanıcı Atanan=gerçek admin sayısı, Son Güncelleme), tabloda tek satır "Süper Admin" (Sistem rozeti, Sil butonu disabled, Düzenle tıklanınca "Sistem rolleri düzenlenemez" mesajı).
2. "Yeni Rol Oluştur" ile geçici bir test rolü oluştur (ör. `test_gecici_rol`, yalnızca `page:musteri-destek` izniyle) — listede görünmeli, Özel Rol sayacı 1'e çıkmalı.
3. Test rolünü düzenle (açıklama değiştir, bir izin daha ekle) — kaydedilip listeye yansıdığını doğrula.
4. Test rolünü sil — `admin_users`'a atanmış kimse olmadığı için başarıyla silinmeli, listeden kalkmalı.
5. Konsolda hata olmadığını `read_console_messages` ile doğrula.

- [ ] **Step 4: Kenar çubuğu filtrelemesini SQL üzerinden dikkatli test et (gerçek admin'i geçici olarak değiştirip hemen geri al)**

1. `mcp__supabase__execute_sql` ile geçici bir test rolü oluştur: yalnızca `{page:musteri-destek}` izniyle.
2. Gerçek admin kullanıcının `admin_users.role_id`'sini bu test rolüne geçici olarak ata (tek satır UPDATE, `user_id` ve orijinal `role_id`'yi not al).
3. Tarayıcıda `/yonetici` sayfasını yenile — kenar çubuğunda yalnızca "Genel Bakış" ve "Müşteri Destek" görünmeli, diğer 24 öğe gizli olmalı. (Plan A'da route'lar hâlâ açık olduğu için doğrudan URL'e gidilirse sayfa yine açılır — bu beklenen, Plan B'nin işi.)
4. **Hemen** admin'in `role_id`'sini orijinal (Süper Admin) değerine geri al — `UPDATE admin_users SET role_id = '<orijinal-id>' WHERE user_id = '<admin-id>'`.
5. Sayfayı yenile, kenar çubuğunun tamamen geri geldiğini doğrula.
6. Test rolünü sil.

- [ ] **Step 5: Güvenlik danışmanı**

`mcp__supabase__get_advisors(type="security")` — yeni tablo/RPC'lerle ilgili beklenmeyen bulgu olmadığını doğrula.

- [ ] **Step 6: Değişiklikleri commit et**

Kullanıcıdan onay alınmadan commit YAPILMAZ (proje kuralı: yalnızca kullanıcı açıkça istediğinde commit edilir). Bu adım, kullanıcı "commit et" dediğinde çalıştırılır.
