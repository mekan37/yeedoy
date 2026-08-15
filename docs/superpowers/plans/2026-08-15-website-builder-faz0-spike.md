# Yeedoy Web — Faz 0 Teknik Spike Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prove that Puck (visual editor), Yeedoy's real business data, and wildcard-subdomain multi-tenant routing work together end-to-end — no payment, no theme catalog, no revision history, no custom domain. Just: owner edits Hero/Menu/Gallery in a panel, publishes, and the change appears on `{subdomain}.yeedoy.localhost` while pulling live menu/photo data from Yeedoy.

**Architecture:** Two new tables (`business_sites`, `site_revisions`, no versioning yet) behind four `SECURITY DEFINER` RPCs following this repo's `has_business_permission_v1` + triple-REVOKE convention. `proxy.ts` gains a wildcard-subdomain resolver that runs after the existing panel-subdomain rewrite and is guarded by a reserved-label denylist. The owner-side editor uses the real `@puckeditor/core` package (MIT-licensed) with three custom Puck components (Hero, Menu, Gallery); the public renderer is a separate, Puck-free route that reads the published config plus live business/menu data directly from existing tables.

**Tech Stack:** Next.js 16 (App Router), React 19, `@puckeditor/core` (Puck editor), Supabase Postgres (RLS + SECURITY DEFINER RPCs), TypeScript, Vitest.

**Design doc:** `docs/superpowers/specs/2026-08-15-website-builder-faz0-spike-design.md`

---

### Task 1: DB — `business_sites` + `site_revisions` tables and RPCs

**Files:**
- Create: `supabase/migrations/20260815000001_website_builder_faz0_spike.sql`

- [ ] **Step 1: Write the migration**

```sql
-- Yeedoy Web — Faz 0 teknik spike. bkz.
-- docs/superpowers/specs/2026-08-15-website-builder-faz0-spike-design.md
--
-- Minimal, gerçek tablolar: entitlement/tema-kataloğu/revision-geçmişi
-- Faz 1+'a ertelendi. Draft/publish ayrımını ve wildcard subdomain
-- çözümlemesini kanıtlamak için yeterli.

CREATE TABLE public.business_sites (
  id                     uuid primary key default gen_random_uuid(),
  business_id            uuid not null references public.businesses(id) on delete cascade,
  subdomain              text not null unique,
  draft_revision_id      uuid,
  published_revision_id  uuid,
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now(),
  published_at           timestamptz,
  unique (business_id)
);

CREATE TABLE public.site_revisions (
  id             uuid primary key default gen_random_uuid(),
  site_id        uuid not null references public.business_sites(id) on delete cascade,
  schema_version integer not null default 1,
  config         jsonb not null,
  created_by     uuid references auth.users(id) on delete set null,
  created_at     timestamptz not null default now()
);

ALTER TABLE public.business_sites ADD CONSTRAINT business_sites_draft_revision_id_fkey
  FOREIGN KEY (draft_revision_id) REFERENCES public.site_revisions(id) ON DELETE SET NULL;
ALTER TABLE public.business_sites ADD CONSTRAINT business_sites_published_revision_id_fkey
  FOREIGN KEY (published_revision_id) REFERENCES public.site_revisions(id) ON DELETE SET NULL;

CREATE INDEX idx_site_revisions_site_id ON public.site_revisions(site_id);

ALTER TABLE public.business_sites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.site_revisions ENABLE ROW LEVEL SECURITY;
-- Bu depodaki güncel desen: client'a hiçbir doğrudan GRANT yok, tüm
-- erişim SECURITY DEFINER RPC üzerinden (bkz. customer_notes/customer_tags,
-- 20260811000004_crm_v2_notes_and_tags.sql).
REVOKE ALL ON public.business_sites FROM anon, authenticated;
REVOKE ALL ON public.site_revisions FROM anon, authenticated;

-- ── create_or_get_business_site_v1 ──────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.create_or_get_business_site_v1(p_business_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_site public.business_sites;
  v_base_slug text;
  v_slug text;
  v_suffix int := 0;
BEGIN
  IF NOT public.has_business_permission_v1(p_business_id, 'menu_write') THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  SELECT * INTO v_site FROM public.business_sites WHERE business_id = p_business_id;
  IF FOUND THEN
    RETURN to_jsonb(v_site);
  END IF;

  SELECT regexp_replace(lower(coalesce(b.slug, b.name)), '[^a-z0-9]+', '-', 'g')
  INTO v_base_slug
  FROM public.businesses b WHERE b.id = p_business_id;
  v_base_slug := trim(both '-' from v_base_slug);
  IF v_base_slug IS NULL OR v_base_slug = '' THEN
    v_base_slug := 'site';
  END IF;

  v_slug := v_base_slug;
  WHILE EXISTS (SELECT 1 FROM public.business_sites WHERE subdomain = v_slug)
    OR v_slug = ANY (ARRAY['ops','isletme','www','api','admin','_vercel','static','assets','cdn','support','help','mail','status','web','app','login','signup','auth','maps'])
  LOOP
    v_suffix := v_suffix + 1;
    v_slug := v_base_slug || '-' || v_suffix;
  END LOOP;

  INSERT INTO public.business_sites (business_id, subdomain)
  VALUES (p_business_id, v_slug)
  RETURNING * INTO v_site;

  RETURN to_jsonb(v_site);
END;
$$;

-- ── save_site_draft_v1 ───────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.save_site_draft_v1(p_site_id uuid, p_config jsonb)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_business_id uuid;
  v_revision_id uuid;
BEGIN
  SELECT business_id INTO v_business_id FROM public.business_sites WHERE id = p_site_id;
  IF v_business_id IS NULL THEN
    RAISE EXCEPTION 'not_found: site' USING ERRCODE = 'P0001';
  END IF;
  IF NOT public.has_business_permission_v1(v_business_id, 'menu_write') THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  INSERT INTO public.site_revisions (site_id, config, created_by)
  VALUES (p_site_id, p_config, auth.uid())
  RETURNING id INTO v_revision_id;

  UPDATE public.business_sites
  SET draft_revision_id = v_revision_id, updated_at = now()
  WHERE id = p_site_id;
END;
$$;

-- ── publish_site_v1 ──────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.publish_site_v1(p_site_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_business_id uuid;
  v_draft_id uuid;
BEGIN
  SELECT business_id, draft_revision_id INTO v_business_id, v_draft_id
  FROM public.business_sites WHERE id = p_site_id;
  IF v_business_id IS NULL THEN
    RAISE EXCEPTION 'not_found: site' USING ERRCODE = 'P0001';
  END IF;
  IF NOT public.has_business_permission_v1(v_business_id, 'menu_write') THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;
  IF v_draft_id IS NULL THEN
    RAISE EXCEPTION 'validation_error: no_draft_to_publish' USING ERRCODE = 'P0003';
  END IF;

  UPDATE public.business_sites
  SET published_revision_id = v_draft_id, published_at = now(), updated_at = now()
  WHERE id = p_site_id;
END;
$$;

-- ── get_published_site_v1 (tek public-okuma yüzeyi) ─────────────────────────
CREATE OR REPLACE FUNCTION public.get_published_site_v1(p_subdomain text)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT jsonb_build_object(
    'business_id', bs.business_id,
    'config', sr.config
  )
  FROM public.business_sites bs
  JOIN public.site_revisions sr ON sr.id = bs.published_revision_id
  WHERE bs.subdomain = lower(trim(p_subdomain));
$$;

REVOKE ALL ON FUNCTION public.create_or_get_business_site_v1(uuid) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.create_or_get_business_site_v1(uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.create_or_get_business_site_v1(uuid) TO authenticated;
COMMENT ON FUNCTION public.create_or_get_business_site_v1 IS 'Faz 0 spike: owner için business_site oluşturur/döner. Called by: app/sahip/web-sitesi/page.tsx.';

REVOKE ALL ON FUNCTION public.save_site_draft_v1(uuid, jsonb) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.save_site_draft_v1(uuid, jsonb) FROM anon;
GRANT EXECUTE ON FUNCTION public.save_site_draft_v1(uuid, jsonb) TO authenticated;
COMMENT ON FUNCTION public.save_site_draft_v1 IS 'Faz 0 spike: yeni bir draft revision yazar. Called by: app/sahip/web-sitesi/web-sitesi-islemleri.ts.';

REVOKE ALL ON FUNCTION public.publish_site_v1(uuid) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.publish_site_v1(uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.publish_site_v1(uuid) TO authenticated;
COMMENT ON FUNCTION public.publish_site_v1 IS 'Faz 0 spike: draft_revision_id -> published_revision_id repoint eder. Called by: app/sahip/web-sitesi/web-sitesi-islemleri.ts.';

REVOKE ALL ON FUNCTION public.get_published_site_v1(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_published_site_v1(text) TO anon, authenticated;
COMMENT ON FUNCTION public.get_published_site_v1 IS 'Faz 0 spike: subdomain''den yayınlanmış site config''ini döner (tek public-okuma yüzeyi, draft asla dönmez). Called by: app/site/[subdomain]/page.tsx.';
```

- [ ] **Step 2: Local doğrulama**

Run: `supabase db reset`
Expected: Tüm migration'lar (bu dosya dahil) hatasız uygulanır.

- [ ] **Step 3: Yetkilendirme smoke test**

```bash
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" <<'EOF'
insert into auth.users (id) values ('a0000000-0000-0000-0000-000000000001'), ('a0000000-0000-0000-0000-000000000002');
insert into public.businesses (id, name, category, is_active, slug) values ('b0000000-0000-0000-0000-000000000001', 'Test Spike Isletme', 'restoran', true, 'test-spike');
insert into public.owner_claims (business_id, user_id, status) values ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'approved');

\echo '--- OWNER creates site ---'
SET ROLE authenticated;
SET request.jwt.claim.sub = 'a0000000-0000-0000-0000-000000000001';
SELECT public.create_or_get_business_site_v1('b0000000-0000-0000-0000-000000000001');

\echo '--- NON-OWNER cannot create site for same business (expect unauthorized) ---'
SET request.jwt.claim.sub = 'a0000000-0000-0000-0000-000000000002';
SELECT public.create_or_get_business_site_v1('b0000000-0000-0000-0000-000000000001');
EOF
```

Expected: Owner çağrısı bir `business_sites` satırı döner (`subdomain = 'test-spike'`); non-owner çağrısı `ERROR: unauthorized` ile başarısız olur.

- [ ] **Step 4: Test verisini temizle**

```bash
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" <<'EOF'
RESET request.jwt.claim.sub;
RESET ROLE;
delete from public.business_sites where business_id = 'b0000000-0000-0000-0000-000000000001';
delete from public.owner_claims where business_id = 'b0000000-0000-0000-0000-000000000001';
delete from public.businesses where id = 'b0000000-0000-0000-0000-000000000001';
delete from auth.users where id in ('a0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000002');
EOF
```

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260815000001_website_builder_faz0_spike.sql
git commit -m "feat(db): Yeedoy Web Faz 0 — business_sites/site_revisions + RPC'ler"
```

---

### Task 2: `proxy.ts` — wildcard subdomain resolver

**Files:**
- Modify: `uygulamalar/web/proxy.ts`
- Test: `uygulamalar/web/test/lib/proxy-site-resolver.test.ts`

- [ ] **Step 1: Write the failing test**

Create `uygulamalar/web/test/lib/proxy-site-resolver.test.ts`:

```typescript
import { describe, it, expect } from 'vitest';
import { normalizeHostname, isReservedSubdomainLabel } from '@/src/lib/site-resolver';

describe('normalizeHostname', () => {
  it('lowercases the host', () => {
    expect(normalizeHostname('ASPAVA-DEMO.yeedoy.localhost')).toBe('aspava-demo.yeedoy.localhost');
  });

  it('strips a trailing dot', () => {
    expect(normalizeHostname('aspava-demo.yeedoy.localhost.')).toBe('aspava-demo.yeedoy.localhost');
  });

  it('strips the port', () => {
    expect(normalizeHostname('aspava-demo.yeedoy.localhost:3000')).toBe('aspava-demo.yeedoy.localhost');
  });
});

describe('isReservedSubdomainLabel', () => {
  it('flags reserved labels regardless of case', () => {
    expect(isReservedSubdomainLabel('OPS')).toBe(true);
    expect(isReservedSubdomainLabel('ops')).toBe(true);
    expect(isReservedSubdomainLabel('isletme')).toBe(true);
    expect(isReservedSubdomainLabel('www')).toBe(true);
  });

  it('does not flag a normal business slug', () => {
    expect(isReservedSubdomainLabel('aspava-demo')).toBe(false);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd uygulamalar/web && pnpm run test:unit -- proxy-site-resolver`
Expected: FAIL — `Cannot find module '@/src/lib/site-resolver'`.

- [ ] **Step 3: Implement the helper**

Create `uygulamalar/web/src/lib/site-resolver.ts`:

```typescript
const RESERVED_SUBDOMAIN_LABELS = new Set([
  'ops', 'isletme', 'www', 'api', 'admin', '_vercel', 'static',
  'assets', 'cdn', 'support', 'help', 'mail', 'status', 'web',
  'app', 'login', 'signup', 'auth', 'maps',
]);

export function normalizeHostname(rawHost: string): string {
  return rawHost.split(':')[0].toLowerCase().replace(/\.$/, '');
}

export function isReservedSubdomainLabel(label: string): boolean {
  return RESERVED_SUBDOMAIN_LABELS.has(label.toLowerCase());
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd uygulamalar/web && pnpm run test:unit -- proxy-site-resolver`
Expected: PASS — 5/5 tests green.

- [ ] **Step 5: Wire the resolver into `proxy.ts`**

Modify `uygulamalar/web/proxy.ts`. Add the import near the top (after existing imports):

```typescript
import { normalizeHostname, isReservedSubdomainLabel } from '@/src/lib/site-resolver';
```

Add a new resolver function after `resolveCustomDomainSlug` (before `export async function proxy`):

```typescript
// ── Wildcard business-site subdomain → site rewrite (Faz 0 spike) ────────────
// {subdomain}.yeedoy.localhost (dev) / {subdomain}.yeedoy.com (prod, later
// phases) resolves to a published business_sites row and rewrites to
// /site/[subdomain]. Runs AFTER the panel-subdomain rewrite and the
// custom-domain lookup, and is guarded by the reserved-label denylist so a
// crafted Host header can never collide with a reserved panel/service name.
const _siteWildcardCache = new Map<string, { exists: boolean; expiresAt: number }>();
const _SITE_WILDCARD_TTL_MS = 5 * 60 * 1_000;

function extractWildcardSubdomain(hostname: string): string | null {
  const wildcardBase = (process.env.SITE_WILDCARD_BASE ?? 'yeedoy.localhost').trim();
  if (!hostname.endsWith(`.${wildcardBase}`)) return null;
  const label = hostname.slice(0, -(wildcardBase.length + 1));
  if (!label || label.includes('.') || isReservedSubdomainLabel(label)) return null;
  return label;
}
```

Modify the `proxy` function — insert the wildcard-subdomain check immediately after the existing custom-domain rewrite block (after the `if (!isOwnHost && hostname && hostname !== '') { ... }` block, before `const panelGuard = await guardPanelRoute(request);`):

```typescript
  const normalizedHostname = normalizeHostname(hostname);
  const wildcardSubdomain = extractWildcardSubdomain(normalizedHostname);
  if (wildcardSubdomain) {
    const url = request.nextUrl.clone();
    const suffix = pathname === '/' ? '' : pathname;
    url.pathname = `/site/${wildcardSubdomain}${suffix}`;
    return NextResponse.rewrite(url);
  }
```

- [ ] **Step 6: Typecheck and lint**

Run: `cd uygulamalar/web && pnpm run typecheck && pnpm run lint`
Expected: no new errors.

- [ ] **Step 7: Commit**

```bash
git add uygulamalar/web/src/lib/site-resolver.ts uygulamalar/web/test/lib/proxy-site-resolver.test.ts uygulamalar/web/proxy.ts
git commit -m "feat(web): Yeedoy Web Faz 0 — wildcard subdomain resolver in proxy.ts"
```

---

### Task 3: Public renderer — `/site/[subdomain]`

**Files:**
- Create: `uygulamalar/web/app/site/[subdomain]/page.tsx`
- Create: `uygulamalar/web/app/site/[subdomain]/hero.tsx`
- Create: `uygulamalar/web/app/site/[subdomain]/menu-section.tsx`
- Create: `uygulamalar/web/app/site/[subdomain]/gallery-section.tsx`

- [ ] **Step 1: Create the Hero component**

Create `uygulamalar/web/app/site/[subdomain]/hero.tsx`:

```tsx
export function Hero({
  title,
  subtitle,
  businessName,
  coverUrl,
}: {
  title: string;
  subtitle: string;
  businessName: string;
  coverUrl: string | null;
}) {
  return (
    <section className="relative flex min-h-[50vh] flex-col items-center justify-center gap-3 bg-card px-6 text-center">
      {coverUrl && (
        <img
          src={coverUrl}
          alt={businessName}
          className="absolute inset-0 h-full w-full object-cover opacity-30"
        />
      )}
      <div className="relative flex flex-col items-center gap-3">
        <h1 className="text-4xl font-black text-textStrong">{title || businessName}</h1>
        {subtitle && <p className="max-w-xl text-lg text-text">{subtitle}</p>}
      </div>
    </section>
  );
}
```

- [ ] **Step 2: Create the Menu component**

Create `uygulamalar/web/app/site/[subdomain]/menu-section.tsx`:

```tsx
type MenuItemRow = {
  id: string;
  name: string;
  price_cents: number | null;
  currency: string | null;
  category_name: string | null;
};

export function MenuSection({ items }: { items: MenuItemRow[] }) {
  if (items.length === 0) {
    return null;
  }

  const byCategory = new Map<string, MenuItemRow[]>();
  for (const item of items) {
    const key = item.category_name ?? 'Menü';
    const bucket = byCategory.get(key) ?? [];
    bucket.push(item);
    byCategory.set(key, bucket);
  }

  return (
    <section className="mx-auto flex max-w-3xl flex-col gap-8 px-6 py-12">
      {Array.from(byCategory.entries()).map(([category, categoryItems]) => (
        <div key={category} className="flex flex-col gap-3">
          <h2 className="text-xl font-bold text-textStrong">{category}</h2>
          <ul className="flex flex-col gap-2">
            {categoryItems.map((item) => (
              <li key={item.id} className="flex items-center justify-between border-b border-border pb-2">
                <span className="text-text">{item.name}</span>
                {item.price_cents !== null && (
                  <span className="font-semibold text-textStrong">
                    {(item.price_cents / 100).toFixed(2)} {item.currency ?? 'TRY'}
                  </span>
                )}
              </li>
            ))}
          </ul>
        </div>
      ))}
    </section>
  );
}
```

- [ ] **Step 3: Create the Gallery component**

Create `uygulamalar/web/app/site/[subdomain]/gallery-section.tsx`:

```tsx
export function GallerySection({ imageUrls }: { imageUrls: string[] }) {
  if (imageUrls.length === 0) {
    return null;
  }

  return (
    <section className="mx-auto grid max-w-4xl grid-cols-2 gap-3 px-6 py-12 sm:grid-cols-3">
      {imageUrls.map((url) => (
        <img key={url} src={url} alt="" className="aspect-square w-full rounded-xl object-cover" />
      ))}
    </section>
  );
}
```

- [ ] **Step 4: Create the page — fetch config + live business data**

Create `uygulamalar/web/app/site/[subdomain]/page.tsx`:

```tsx
import { notFound } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { Hero } from './hero';
import { MenuSection } from './menu-section';
import { GallerySection } from './gallery-section';

type PuckSiteConfig = {
  hero?: { title?: string; subtitle?: string };
};

export default async function BusinessSitePage({
  params,
}: {
  params: Promise<{ subdomain: string }>;
}) {
  const { subdomain } = await params;
  const supabase = await createSupabaseServerClient();

  const { data: published } = (await (supabase as any).rpc('get_published_site_v1', {
    p_subdomain: subdomain,
  })) as { data: { business_id: string; config: PuckSiteConfig } | null };

  if (!published) {
    notFound();
  }

  const { business_id: businessId, config } = published;

  const [{ data: business }, { data: menuItems }] = await Promise.all([
    (supabase as any)
      .from('businesses')
      .select('name, cover_url, logo_url')
      .eq('id', businessId)
      .maybeSingle() as Promise<{ data: { name: string; cover_url: string | null; logo_url: string | null } | null }>,
    (supabase as any)
      .from('menu_items')
      .select('id, name, price_cents, currency, image_url, menu_categories(name)')
      .eq('business_id', businessId)
      .eq('is_available', true)
      .limit(60) as Promise<{
      data: Array<{
        id: string;
        name: string;
        price_cents: number | null;
        currency: string | null;
        image_url: string | null;
        menu_categories: { name: string } | null;
      }> | null;
    }>,
  ]);

  if (!business) {
    notFound();
  }

  const items = (menuItems ?? []).map((item) => ({
    id: item.id,
    name: item.name,
    price_cents: item.price_cents,
    currency: item.currency,
    category_name: item.menu_categories?.name ?? null,
  }));

  const galleryUrls = (menuItems ?? [])
    .map((item) => item.image_url)
    .filter((url): url is string => Boolean(url))
    .slice(0, 9);

  return (
    <main className="flex flex-col">
      <Hero
        title={config.hero?.title ?? ''}
        subtitle={config.hero?.subtitle ?? ''}
        businessName={business.name}
        coverUrl={business.cover_url}
      />
      <MenuSection items={items} />
      <GallerySection imageUrls={galleryUrls} />
    </main>
  );
}
```

- [ ] **Step 5: Typecheck and lint**

Run: `cd uygulamalar/web && pnpm run typecheck && pnpm run lint`
Expected: no new errors.

- [ ] **Step 6: Commit**

```bash
git add uygulamalar/web/app/site/
git commit -m "feat(web): Yeedoy Web Faz 0 — public site renderer (/site/[subdomain])"
```

---

### Task 4: Owner editor — Puck integration

**Files:**
- Modify: `uygulamalar/web/package.json`
- Create: `uygulamalar/web/app/sahip/web-sitesi/page.tsx`
- Create: `uygulamalar/web/app/sahip/web-sitesi/web-sitesi-islemleri.ts`
- Create: `uygulamalar/web/app/sahip/web-sitesi/editor-istemcisi.tsx`
- Create: `uygulamalar/web/app/sahip/web-sitesi/puck-config.ts`

- [ ] **Step 1: Add the Puck dependency**

Run: `cd uygulamalar/web && pnpm add @puckeditor/core@^0.23.0`
Expected: `package.json`/`pnpm-lock.yaml` updated, install succeeds. (License confirmed MIT — see `docs/superpowers/specs/2026-08-15-website-builder-faz0-spike-design.md` §Bağlam.)

**Uygulama zamanında doğrula:** Bu plan Ağustos 2026'daki lisans araştırmasına dayanıyor (paket `@measured/puck` → `@puckeditor/core` olarak yeniden adlandırılmış, v0.23.0). Puck aktif geliştirilen bir paket — gerçek implementasyon anında `npm view @puckeditor/core` ile güncel sürüm/paket adı ve `Puck`/`Config`/`Data` export'larının hâlâ bu adlarla `@puckeditor/core`'un kök paketinden geldiğini (ayrı bir `@puckeditor/react` gibi alt pakete taşınmadığını) teyit et.

- [ ] **Step 2: Define the Puck config**

Create `uygulamalar/web/app/sahip/web-sitesi/puck-config.ts`:

```typescript
import type { Config, Data } from '@puckeditor/core';

export type HeroProps = { title: string; subtitle: string };

export const puckConfig: Config = {
  components: {
    Hero: {
      fields: {
        title: { type: 'text', label: 'Başlık' },
        subtitle: { type: 'text', label: 'Alt başlık' },
      },
      defaultProps: { title: '', subtitle: '' },
      render: ({ title, subtitle }: HeroProps) => (
        <div style={{ padding: 24, textAlign: 'center', background: '#f5f5f5' }}>
          <h1>{title || 'Başlık girin'}</h1>
          <p>{subtitle}</p>
        </div>
      ),
    },
  },
  root: {
    defaultProps: {},
  },
};

export const defaultPuckData: Data = {
  content: [
    { type: 'Hero', props: { id: 'hero-1', title: '', subtitle: '' } },
  ],
  root: { props: {} },
};

// Puck'ın gerçek onPublish veri şekli { content: [...], root: {...} } —
// bu, site_revisions.config'e olduğu gibi yazılmaz; yalnızca sayfanın
// gerçekten kullandığı override'lar (Hero başlığı) çıkarılıp saklanır.
// "Tek kaynak prensibi" (design doc): menü/foto Puck config'ine kopyalanmaz.
export function extractHeroConfig(data: Data): { hero: HeroProps } {
  const heroBlock = data.content.find((block) => block.type === 'Hero');
  const props = (heroBlock?.props ?? {}) as Partial<HeroProps>;
  return {
    hero: {
      title: props.title ?? '',
      subtitle: props.subtitle ?? '',
    },
  };
}
```

- [ ] **Step 3: Write the server actions**

Create `uygulamalar/web/app/sahip/web-sitesi/web-sitesi-islemleri.ts`:

```typescript
'use server';

import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinessIds } from '@/src/lib/veri/owner/sahip-isletmeleri';

export async function siteEkraniniGetir() {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) throw new Error('unauthorized');

  const businessIds = await getOwnerBusinessIds(supabase as any, user.id);
  const businessId = businessIds[0];
  if (!businessId) throw new Error('no_business');

  const { data: site } = (await (supabase as any).rpc('create_or_get_business_site_v1', {
    p_business_id: businessId,
  })) as { data: { id: string; subdomain: string } };

  return site;
}

export async function taslakKaydet(siteId: string, config: unknown) {
  const supabase = await createSupabaseServerClient();
  const { error } = await (supabase as any).rpc('save_site_draft_v1', {
    p_site_id: siteId,
    p_config: config,
  });
  if (error) throw new Error(error.message);
}

export async function siteyiYayinla(siteId: string) {
  const supabase = await createSupabaseServerClient();
  const { error } = await (supabase as any).rpc('publish_site_v1', {
    p_site_id: siteId,
  });
  if (error) throw new Error(error.message);
}
```

- [ ] **Step 4: Write the client editor component**

Create `uygulamalar/web/app/sahip/web-sitesi/editor-istemcisi.tsx`:

```tsx
'use client';

import { useState, useTransition } from 'react';
import { Puck, type Data } from '@puckeditor/core';
import { puckConfig, defaultPuckData, extractHeroConfig } from './puck-config';
import { taslakKaydet, siteyiYayinla } from './web-sitesi-islemleri';

export function EditorIstemcisi({ siteId, subdomain }: { siteId: string; subdomain: string }) {
  const [isPending, startTransition] = useTransition();
  const [status, setStatus] = useState<'idle' | 'saved' | 'published'>('idle');

  return (
    <div className="flex flex-col gap-3">
      <div className="flex items-center justify-between rounded-xl border border-border bg-card p-3">
        <p className="text-sm text-muted">
          Önizleme: <code>{subdomain}.yeedoy.localhost</code>
        </p>
        <div className="flex gap-2">
          {status === 'saved' && <span className="text-sm text-muted">Kaydedildi ✓</span>}
          {status === 'published' && <span className="text-sm text-primary">Yayınlandı ✓</span>}
        </div>
      </div>
      <Puck
        config={puckConfig}
        data={defaultPuckData}
        onPublish={(data: Data) => {
          startTransition(async () => {
            const config = extractHeroConfig(data);
            await taslakKaydet(siteId, config);
            await siteyiYayinla(siteId);
            setStatus('published');
          });
        }}
      />
      {isPending && <p className="text-sm text-muted">İşleniyor…</p>}
    </div>
  );
}
```

**Not — kapsam netliği:** Faz 0'da yalnızca Hero, Puck üzerinden düzenlenebilir. Menu ve Gallery (Task 3) her zaman canlı Yeedoy verisinden otomatik render edilir, Puck canvas'ında yer almaz — "tek kaynak prensibi" gereği ve editör kapsamını küçük tutmak için bilinçli bir sadeleştirme. Menü/galerinin Puck'a taşınması (kategori seçimi, görünüm seçenekleri vb.) Faz 1+'a bırakıldı.

- [ ] **Step 5: Write the page**

Create `uygulamalar/web/app/sahip/web-sitesi/page.tsx`:

```tsx
import type { Metadata } from 'next';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi } from '@/src/ui/yerlesim/panel-section-card';
import { siteEkraniniGetir } from './web-sitesi-islemleri';
import { EditorIstemcisi } from './editor-istemcisi';

export const metadata: Metadata = {
  title: 'Web Sitem | Sahip Paneli',
  robots: { index: false, follow: false },
};

export default async function WebSitesiSayfasi() {
  const site = await siteEkraniniGetir();

  return (
    <div className="flex flex-col gap-6">
      <PanelSayfaBasligi eyebrow="Web Sitem" title="Web Sitem (Beta)" description="Teknik önizleme — Faz 0" />
      <PanelIcerikYuzeyi>
        <EditorIstemcisi siteId={site.id} subdomain={site.subdomain} />
      </PanelIcerikYuzeyi>
    </div>
  );
}
```

- [ ] **Step 6: Typecheck and lint**

Run: `cd uygulamalar/web && pnpm run typecheck && pnpm run lint`
Expected: no new errors. (Puck's own TypeScript types are used as-is — do not add `as any` beyond the existing Supabase RPC-call convention already used elsewhere in this file.)

- [ ] **Step 7: Commit**

```bash
git add uygulamalar/web/package.json uygulamalar/web/pnpm-lock.yaml uygulamalar/web/app/sahip/web-sitesi/
git commit -m "feat(web): Yeedoy Web Faz 0 — Puck owner editor (/sahip/web-sitesi)"
```

---

### Task 5: Manuel uçtan uca doğrulama

**Files:** Yok (yalnızca doğrulama).

- [ ] **Step 1: `.env.local`'a wildcard base ekle (yalnızca yerel)**

`uygulamalar/web/.env.local` dosyasına ekle: `SITE_WILDCARD_BASE=yeedoy.localhost`

- [ ] **Step 2: Dev server'ı başlat**

Run: `cd uygulamalar/web && pnpm run dev` (arka planda).

- [ ] **Step 3: Owner olarak editörü aç, düzenle, yayınla**

`http://localhost:3000/sahip/web-sitesi` adresine gerçek bir owner hesabıyla giriş yap. Hero başlığını değiştir, "Publish" butonuna bas (Puck'ın kendi publish akışı `onPublish`'i tetikler).

- [ ] **Step 4: Yayınlanan siteyi doğrula**

`http://<subdomain>.yeedoy.localhost:3000` adresini aç (tarayıcı `*.localhost`'u otomatik `127.0.0.1`'e çözer). Beklenen: Hero başlığı değişmiş, işletmenin gerçek menü kalemleri kategori bazlı listeleniyor, menü kalemlerinden gelen görseller galeri bölümünde görünüyor.

- [ ] **Step 5: Reserved-label guard'ı doğrula**

`http://ops.yeedoy.localhost:3000` adresini aç. Beklenen: `/site/ops`'a rewrite OLMAZ (reserved label), normal `NextResponse.next()` akışına düşer — admin panel host'unu taklit edemez.

- [ ] **Step 6: Dev server'ı durdur**

- [ ] **Step 7: Kullanıcıya rapor**

Hangi senaryoların doğrulandığını (draft/publish ayrımı, menü/galeri veri bağlama, reserved-subdomain guard) özetle.

---

### Task 6: Son doğrulama

**Files:** (yalnızca doğrulama)

- [ ] **Step 1: Tam web doğrulaması**

Run: `cd uygulamalar/web && pnpm run test:ci`
Expected: typecheck + lint + unit + build hepsi geçer.

- [ ] **Step 2: Supabase tip dosyalarını yeniden üret**

Run: `mcp__supabase__generate_typescript_types`, çıktıyı `uygulamalar/web/src/lib/supabase/database.types.ts` VE `uygulamalar/web/src/lib/taban/veri-tanimlari.ts`'e yaz (bu depodaki ikili-dosya konvansiyonu, bkz. commit `de0c32be`). **Not:** migration önce production'a `supabase db push` ile deploy edilmeden bu adım `business_sites`/`site_revisions` RPC'lerini yeni tiplerde göstermez — bu depodaki bilinen, kabul edilen bir sıralama (bkz. commit `48ee9caa`, `d77c7d5a`).

- [ ] **Step 3: Kullanıcıya rapor**

Faz 0'ın definition-of-done'ının (design doc'taki) karşılanıp karşılanmadığını özetle; Faz 1 (Editor Core: autosave/revision geçmişi/preview) için hangi kod parçalarının aynen kalacağını, hangilerinin genişleyeceğini not et.
