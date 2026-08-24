# Yemek Görsel Kütüphanesi Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Kod içine gömülü statik 117 stok yemek görseli sözlüğünü DB-tabanlı, admin panelinden yönetilebilen bir kütüphaneye (`stock_dish_images`) dönüştürmek ve sahip panelindeki ürün görsel seçicisine bilinçli bir "Sistemden Seç" seçeneği eklemek.

**Architecture:** Yeni `stock_dish_images` tablosu (id, image_url, keywords text[], is_active) + `get_stock_dish_images_v1()` public RPC (okuma, cache'lenir) + `admin_*` RPC'leri (yazma, admin-only). Eşleştirme tek-aşamalı hale geliyor (kategori-klasör ön-filtresi kaldırılıyor) — admin'in girdiği serbest metin anahtar ifadeler ürün adında geçiyorsa eşleşme sayılır. Web ve mobildeki mevcut eşleştirme *algoritması* (Türkçe normalize + içerir-kontrolü) aynen korunuyor, veri kaynağı statik diziden bu RPC'nin cache'lenmiş sonucuna dönüşüyor. Sahip tarafındaki "Sistemden Seç" yalnızca web'e ekleniyor (mobilde owner-facing ürün editörü yok).

**Tech Stack:** Supabase (Postgres/plpgsql), Next.js 15 (Server Components + Server Actions + Route Handlers), TypeScript, vitest, Flutter/Dart, Riverpod.

**Spec:** `docs/superpowers/specs/2026-08-24-yemek-gorsel-kutuphanesi-design.md`

**Önemli notlar:**
1. Migration'lar doğrudan production DB'ye `psql` ile uygulanır (MCP değil) — bu proje/oturumda zaten kurulu yöntem. Bağlantı: `D:\yeedoy-google-maps-coverage-v5\.env` içindeki `SUPABASE_DB_URL`, veya `uygulamalar/web/.env.local`'daki parçalardan (`NEXT_PUBLIC_SUPABASE_URL`, DB şifresi ayrı bir yerde) birleştirilir — önceki oturumlarda kullanılan tam connection string: `postgresql://postgres.dktdnbeougrmhkzplbap:<şifre>@aws-1-ap-northeast-2.pooler.supabase.com:5432/postgres`.
2. `ALTER TYPE ... ADD VALUE` içeren migration, aynı enum değerini KULLANAN bir sonraki migration'dan ayrı bir `psql -f` çağrısıyla uygulanmalı (Postgres kısıtı: yeni enum değeri eklendiği transaction içinde kullanılamaz). Task 4'te bu iki adım ayrı dosya/ayrı `psql -f` çağrısı olarak tasarlandı.
3. `menu_media_auth_delete`/`insert`/`update` storage politikaları zaten `authenticated` rolüne bucket-geneli izin veriyor (business-scoping yok) — admin upload route'u bu mevcut politikayı kullanır, yeni bir storage policy gerekmez.
4. Gerçek silme (Task 3) v1'de yalnızca `stock_dish_images` satırını kaldırır, Storage dosyasına dokunmaz (spec'te "Kapsam Dışı" olarak not edildi).

---

### Task 1: Migration — `stock_dish_images` tablosu

**Files:**
- Create: `supabase/migrations/20260824000001_stock_dish_images_table.sql`

- [ ] **Step 1: Migration dosyasını yaz**

```sql
CREATE TABLE public.stock_dish_images (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  image_url text NOT NULL,
  keywords text[] NOT NULL DEFAULT '{}',
  is_active boolean NOT NULL DEFAULT true,
  created_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX stock_dish_images_active_idx ON public.stock_dish_images (is_active) WHERE is_active = true;

ALTER TABLE public.stock_dish_images ENABLE ROW LEVEL SECURITY;
-- Politika yok: tüm erişim aşağıdaki SECURITY DEFINER RPC'ler üzerinden (Task 2-3).

COMMENT ON TABLE public.stock_dish_images IS
  'Ürün adı eşleştirmesiyle otomatik/manuel önerilen stok yemek görseli kütüphanesi. Erişim: get_stock_dish_images_v1 (public okuma), admin_* RPC''ler (admin yazma).';
```

- [ ] **Step 2: Uygula ve doğrula**

```bash
psql "$SUPABASE_DB_URL" -f supabase/migrations/20260824000001_stock_dish_images_table.sql
psql "$SUPABASE_DB_URL" -c "select count(*) from public.stock_dish_images"
```
Expected: `CREATE TABLE`, `CREATE INDEX`, ikinci komut `0` döner (henüz veri yok).

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260824000001_stock_dish_images_table.sql
git commit -m "feat(db): stock_dish_images tablosu — yemek görsel kütüphanesi"
```

---

### Task 2: Migration — `get_stock_dish_images_v1()` public RPC

**Files:**
- Create: `supabase/migrations/20260824000002_get_stock_dish_images_v1.sql`

- [ ] **Step 1: Migration dosyasını yaz**

```sql
CREATE OR REPLACE FUNCTION public.get_stock_dish_images_v1()
RETURNS TABLE (id uuid, image_url text, keywords text[])
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT id, image_url, keywords
  FROM public.stock_dish_images
  WHERE is_active = true
  ORDER BY created_at;
$$;

REVOKE ALL ON FUNCTION public.get_stock_dish_images_v1() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_stock_dish_images_v1() TO authenticated, anon;
COMMENT ON FUNCTION public.get_stock_dish_images_v1 IS
  'Aktif stok yemek görsellerini döner (id, image_url, keywords). Public okuma — anonim menü ziyaretçileri dahil. Called by: web varsayilan-yemek-gorseli fetch, mobil menu_page fetch, sahip Sistemden Seç.';
```

- [ ] **Step 2: Uygula ve doğrula**

```bash
psql "$SUPABASE_DB_URL" -f supabase/migrations/20260824000002_get_stock_dish_images_v1.sql
psql "$SUPABASE_DB_URL" -c "select public.get_stock_dish_images_v1()"
```
Expected: `CREATE FUNCTION`, ikinci komut boş sonuç kümesi döner (hata değil — henüz satır yok).

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260824000002_get_stock_dish_images_v1.sql
git commit -m "feat(db): get_stock_dish_images_v1 — public stok görsel okuma RPC'si"
```

---

### Task 3: Migration — admin RPC'leri (list/upsert/delete)

**Files:**
- Create: `supabase/migrations/20260824000003_admin_stock_dish_image_rpcs.sql`

- [ ] **Step 1: Migration dosyasını yaz**

```sql
CREATE OR REPLACE FUNCTION public.admin_list_stock_dish_images_v1()
RETURNS TABLE (id uuid, image_url text, keywords text[], is_active boolean, created_at timestamptz)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;
  RETURN QUERY
    SELECT s.id, s.image_url, s.keywords, s.is_active, s.created_at
    FROM public.stock_dish_images s
    ORDER BY s.created_at DESC;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_list_stock_dish_images_v1() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_list_stock_dish_images_v1() TO authenticated;
COMMENT ON FUNCTION public.admin_list_stock_dish_images_v1 IS
  'Admin: pasif dahil tüm stok görselleri listeler. Called by: app/yonetici/gorsel-kutuphanesi.';

CREATE OR REPLACE FUNCTION public.admin_upsert_stock_dish_image_v1(
  p_id uuid DEFAULT NULL,
  p_image_url text DEFAULT NULL,
  p_keywords text[] DEFAULT NULL,
  p_is_active boolean DEFAULT true
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id uuid;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  IF p_id IS NULL THEN
    IF p_image_url IS NULL OR trim(p_image_url) = '' THEN
      RAISE EXCEPTION 'validation_error: image_url zorunlu' USING ERRCODE = 'P0003';
    END IF;
    INSERT INTO public.stock_dish_images (image_url, keywords, is_active, created_by)
    VALUES (trim(p_image_url), COALESCE(p_keywords, '{}'), COALESCE(p_is_active, true), auth.uid())
    RETURNING id INTO v_id;
  ELSE
    UPDATE public.stock_dish_images
    SET
      image_url = COALESCE(NULLIF(trim(p_image_url), ''), image_url),
      keywords = COALESCE(p_keywords, keywords),
      is_active = COALESCE(p_is_active, is_active),
      updated_at = now()
    WHERE id = p_id
    RETURNING id INTO v_id;
    IF v_id IS NULL THEN
      RAISE EXCEPTION 'not_found' USING ERRCODE = 'P0001';
    END IF;
  END IF;

  RETURN v_id;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_upsert_stock_dish_image_v1(uuid, text, text[], boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_upsert_stock_dish_image_v1(uuid, text, text[], boolean) TO authenticated;
COMMENT ON FUNCTION public.admin_upsert_stock_dish_image_v1 IS
  'Admin: stok görsel oluşturur (p_id=NULL) veya günceller. Called by: app/yonetici/gorsel-kutuphanesi.';

CREATE OR REPLACE FUNCTION public.admin_delete_stock_dish_image_v1(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;
  DELETE FROM public.stock_dish_images WHERE id = p_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found' USING ERRCODE = 'P0001';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_delete_stock_dish_image_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_delete_stock_dish_image_v1(uuid) TO authenticated;
COMMENT ON FUNCTION public.admin_delete_stock_dish_image_v1 IS
  'Admin: kütüphane satırını kalıcı siler (yalnızca DB satırı — Storage dosyası v1 kapsamında silinmez). Called by: app/yonetici/gorsel-kutuphanesi.';
```

- [ ] **Step 2: Uygula ve doğrula**

```bash
psql "$SUPABASE_DB_URL" -f supabase/migrations/20260824000003_admin_stock_dish_image_rpcs.sql
```
Expected: 3× `CREATE FUNCTION`. (Fonksiyonel doğrulama Task 5'te gerçek admin oturumu simülasyonuyla yapılacak — burada sadece syntax/deploy doğrulanır.)

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260824000003_admin_stock_dish_image_rpcs.sql
git commit -m "feat(db): admin_list/upsert/delete_stock_dish_image_v1 RPC'leri"
```

---

### Task 4: Migration — admin izin sistemine yeni sayfa ekleme

**Files:**
- Create: `supabase/migrations/20260824000004_admin_permission_gorsel_kutuphanesi.sql`
- Create: `supabase/migrations/20260824000005_refresh_super_admin_permissions.sql`

**ÖNEMLİ:** Bu iki dosya AYRI `psql -f` çağrılarıyla uygulanmalı (Postgres: `ALTER TYPE ... ADD VALUE` ile eklenen değer, ekleyen transaction'da kullanılamaz).

- [ ] **Step 1: Enum'a yeni değer ekleyen migration'ı yaz**

Create `supabase/migrations/20260824000004_admin_permission_gorsel_kutuphanesi.sql`:

```sql
ALTER TYPE public.admin_permission_key ADD VALUE 'page:gorsel-kutuphanesi';
```

- [ ] **Step 2: Uygula (ayrı psql çağrısı)**

```bash
psql "$SUPABASE_DB_URL" -f supabase/migrations/20260824000004_admin_permission_gorsel_kutuphanesi.sql
```
Expected: `ALTER TYPE`

- [ ] **Step 3: super_admin izinlerini yenileyen migration'ı yaz**

Create `supabase/migrations/20260824000005_refresh_super_admin_permissions.sql`:

```sql
UPDATE public.admin_roles
SET permissions = enum_range(NULL::public.admin_permission_key)
WHERE is_system = true;
```

- [ ] **Step 4: Uygula ve doğrula (ayrı psql çağrısı)**

```bash
psql "$SUPABASE_DB_URL" -f supabase/migrations/20260824000005_refresh_super_admin_permissions.sql
psql "$SUPABASE_DB_URL" -c "select 'page:gorsel-kutuphanesi' = any(permissions) from public.admin_roles where is_system = true limit 1"
```
Expected: `UPDATE 1` (veya kaç sistem rolü varsa), ikinci komut `t` (true) döner.

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260824000004_admin_permission_gorsel_kutuphanesi.sql supabase/migrations/20260824000005_refresh_super_admin_permissions.sql
git commit -m "feat(db): admin_permission_key'e page:gorsel-kutuphanesi eklendi"
```

---

### Task 5: Migration — 117 mevcut görselin kütüphaneye taşınması (seed)

**Files:**
- Create: `scripts/seed-stock-dish-images.mjs` (bir kerelik generator script)
- Create: `supabase/migrations/20260824000006_seed_stock_dish_images.sql` (script'in ürettiği dosya)

- [ ] **Step 1: Generator script'i yaz**

Create `scripts/seed-stock-dish-images.mjs`:

```js
import fs from 'node:fs';

// uygulamalar/web/src/lib/menu/varsayilan-yemek-gorseli.ts'teki YEMEK_SOZLUGU
// ile birebir aynı — bu Task 9'da bu dosyadaki statik sözlük kaldırılacağı
// için burada bir kez, kalıcı SQL veriye dönüştürülmek üzere kopyalanıyor.
const YEMEK_SOZLUGU = {
  corbalar: [
    'anali_kizli', 'arabasi', 'ayak_paca', 'balik', 'bamya', 'beyran', 'brokoli',
    'dil_paca', 'domates', 'dugun', 'ezogelin', 'iskembe', 'kelle_paca', 'kofte',
    'lebeniye', 'mahluta', 'mantar', 'maras_tarhanasi', 'mercimek', 'paca',
    'sehriye', 'siveydiz', 'tarhana', 'tavuk_suyu', 'tuzlama', 'yayla', 'yogurtlu',
  ],
  'salata-meze': [
    'acili_ezme', 'atom', 'babagannus', 'cacik', 'coban', 'deniz_borulcesi',
    'enginar', 'fava', 'gavurdagi', 'haydari', 'humus', 'kopoglu', 'koz_biber',
    'kozlenmis_patlican', 'kisir', 'lahana', 'mevsim', 'muhammara', 'pancar',
    'patates', 'piyaz', 'roka', 'saksuka', 'sezar', 'tarator', 'ton_balikli',
    'tursu', 'yesil', 'yogurtlu_semizotu', 'zeytinyagli_barbunya',
  ],
  sulu_yemekler: [
    'ali_nazik', 'bamya', 'bezelye_etli', 'coban_kavurma', 'dana_haslama',
    'eksili_kofte', 'et_sote', 'etli_guvec', 'etli_lahana', 'etli_nohut',
    'etli_patates', 'hunkar_begendi', 'islim_kebabi', 'ispanak', 'izmir_kofte',
    'kabak', 'kabak_oturtma', 'kapuska', 'karni_yarik', 'kereviz', 'kuru_fasulye',
    'musakka', 'nohut', 'orman_kebabi', 'patates_oturtma', 'patlican_kebabi',
    'pilav_ustu_kuru', 'pirasa', 'sac_kavurma', 'sebzeli_guvec', 'sulu_kofte',
    'tas_kebabi', 'tavuk_haslama', 'tavuk_sote', 'tavuk_yahni', 'taze_fasulye',
    'terbiyeli_kofte', 'turlu', 'yumurtali_ispanak',
  ],
  zeytinyaglilar: [
    'bakla', 'bamya', 'barbunya', 'bezelye', 'biber_dolmasi', 'biber_kizartmasi',
    'borulce', 'bruksel_lahanasi', 'enginar', 'imam_bayildi', 'kabak',
    'kabak_dolmasi', 'kabak_kizartmasi', 'karniyarik', 'kereviz', 'lahana_sarma',
    'patlican_dolmasi', 'patlican_kizartmasi', 'pirasa', 'taze_fasulye',
    'yaprak_sarma',
  ],
};

// Aynı slug birden fazla klasörde farklı fotoğrafla var (ör. "bamya" hem
// çorba hem sulu yemek hem zeytinyağlı) — flat (kategori-önsüzsüz) eşleştirmede
// çakışmayı önlemek için bu satırlara ayırt edici anahtar kelime veriliyor.
// Admin daha sonra "Görsel Kütüphanesi" sayfasından istediği gibi değiştirebilir.
const OVERRIDES = {
  'corbalar/bamya': 'bamya corbasi',
  'sulu_yemekler/bamya': 'etli bamya',
  'zeytinyaglilar/bamya': 'zeytinyagli bamya',
  'sulu_yemekler/kabak': 'kabak yemegi',
  'zeytinyaglilar/kabak': 'zeytinyagli kabak',
  'sulu_yemekler/kereviz': 'kereviz yemegi',
  'zeytinyaglilar/kereviz': 'zeytinyagli kereviz',
  'sulu_yemekler/pirasa': 'pirasa yemegi',
  'zeytinyaglilar/pirasa': 'zeytinyagli pirasa',
  'sulu_yemekler/taze_fasulye': 'taze fasulye yemegi',
  'zeytinyaglilar/taze_fasulye': 'zeytinyagli taze fasulye',
  'salata-meze/enginar': 'enginar salatasi',
  'zeytinyaglilar/enginar': 'zeytinyagli enginar',
};

const SUPABASE_URL = 'https://dktdnbeougrmhkzplbap.supabase.co';

function sqlEscape(s) {
  return s.replace(/'/g, "''");
}

const rows = [];
for (const [klasor, sluglar] of Object.entries(YEMEK_SOZLUGU)) {
  for (const slug of sluglar) {
    const key = `${klasor}/${slug}`;
    const keyword = OVERRIDES[key] ?? slug.replace(/_/g, ' ');
    const imageUrl = `${SUPABASE_URL}/storage/v1/object/public/menu-media/varsayilan-yemekler/${klasor}/${slug}.webp`;
    rows.push(`  ('${sqlEscape(imageUrl)}', ARRAY['${sqlEscape(keyword)}']::text[])`);
  }
}

const sql = `-- 117 mevcut stok görselinin (varsayilan-yemek-gorseli.ts / varsayilan_yemek_sozlugu.dart
-- statik sözlüklerinden taşınan) stock_dish_images tablosuna ilk yükleme migration'ı.
-- Dosyalar Supabase Storage'da (menu-media/varsayilan-yemekler/...) zaten duruyor,
-- yeniden yüklenmiyor — sadece katalog satırı olarak kaydediliyor.
INSERT INTO public.stock_dish_images (image_url, keywords) VALUES
${rows.join(',\n')}
ON CONFLICT DO NOTHING;
`;

fs.writeFileSync('supabase/migrations/20260824000006_seed_stock_dish_images.sql', sql);
console.log(`${rows.length} satır supabase/migrations/20260824000006_seed_stock_dish_images.sql dosyasına yazıldı.`);
```

- [ ] **Step 2: Script'i çalıştır**

```bash
node scripts/seed-stock-dish-images.mjs
```
Expected: `117 satır supabase/migrations/20260824000006_seed_stock_dish_images.sql dosyasına yazıldı.`

- [ ] **Step 3: Üretilen SQL dosyasını gözden geçir**

```bash
grep -c "^  ('" supabase/migrations/20260824000006_seed_stock_dish_images.sql
```
Expected: `117`

- [ ] **Step 4: Uygula ve doğrula**

```bash
psql "$SUPABASE_DB_URL" -f supabase/migrations/20260824000006_seed_stock_dish_images.sql
psql "$SUPABASE_DB_URL" -c "select count(*) from public.stock_dish_images"
psql "$SUPABASE_DB_URL" -c "select image_url, keywords from public.stock_dish_images where keywords @> ARRAY['mercimek']"
```
Expected: `INSERT 0 117`, count sorgusu `117`, üçüncü sorgu `corbalar/mercimek.webp` içeren bir satır döner.

- [ ] **Step 5: Commit**

```bash
git add scripts/seed-stock-dish-images.mjs supabase/migrations/20260824000006_seed_stock_dish_images.sql
git commit -m "feat(db): 117 mevcut stok yemek görseli stock_dish_images'e taşındı"
```

---

### Task 6: Web — Admin görsel yükleme route'u

**Files:**
- Create: `uygulamalar/web/app/sunucu/medya/yonetici-yukleme/route.ts`

- [ ] **Step 1: Route handler'ı yaz**

Mevcut `app/sunucu/medya/yukleme/route.ts`'nin business-scoped deseni admin-context'e uyarlanıyor (`hasOwnerBusiness` yerine `checkAdminAccess`, path business'a değil kütüphaneye özel).

Create `uygulamalar/web/app/sunucu/medya/yonetici-yukleme/route.ts`:

```typescript
import { randomUUID } from 'node:crypto';
import { NextResponse } from 'next/server';
import { createSupabaseServiceClient } from '@/src/lib/taban/hizmet';
import { checkAdminAccess } from '@/src/lib/auth/admin-guard';
import { logger } from '@/src/lib/kayitci';
import { getRequestIdentity, rateLimit, getClientIp } from '@/src/lib/oran-siniri';

const allowedMimeTypes = new Set(['image/jpeg', 'image/png', 'image/webp']);
const maxBytes = 5 * 1024 * 1024;

export async function POST(request: Request) {
  const identity = getRequestIdentity({
    ip: getClientIp(request.headers),
    userAgent: request.headers.get('user-agent'),
  });
  const limit = rateLimit(`media-upload-admin:${identity}`, 10, 60_000);
  if (!limit.ok) {
    return NextResponse.json({ error: 'rate_limited' }, { status: 429 });
  }

  const guard = await checkAdminAccess();
  if (!guard.authorized) {
    return NextResponse.json({ error: 'unauthorized' }, { status: guard.status });
  }

  const formData = await request.formData().catch(() => null);
  if (!formData) {
    return NextResponse.json({ error: 'invalid_payload' }, { status: 400 });
  }

  const file = formData.get('file');
  if (!(file instanceof File)) {
    return NextResponse.json({ error: 'file_required' }, { status: 400 });
  }

  if (!allowedMimeTypes.has(file.type)) {
    return NextResponse.json({ error: 'invalid_mime_type' }, { status: 400 });
  }

  if (file.size > maxBytes) {
    return NextResponse.json({ error: 'file_too_large' }, { status: 400 });
  }

  const service = createSupabaseServiceClient();
  if (!service) {
    return NextResponse.json({ error: 'service_role_required' }, { status: 500 });
  }

  const extension = extensionFromMimeType(file.type);
  const path = `varsayilan-yemekler/kutuphane/${randomUUID()}.${extension}`;
  const { error } = await service.storage.from('menu-media').upload(path, file, {
    contentType: file.type,
    cacheControl: '3600',
    upsert: false,
  });

  if (error) {
    logger.warn('Failed to upload stock dish image', { error });
    return NextResponse.json({ error: 'upload_failed' }, { status: 500 });
  }

  const { data } = service.storage.from('menu-media').getPublicUrl(path);
  return NextResponse.json({
    ok: true,
    data: {
      bucket: 'menu-media',
      path,
      url: data.publicUrl,
      mimeType: file.type,
      size: file.size,
    },
  });
}

function extensionFromMimeType(mimeType: string) {
  switch (mimeType) {
    case 'image/png':
      return 'png';
    case 'image/webp':
      return 'webp';
    case 'image/jpeg':
    default:
      return 'jpg';
  }
}
```

- [ ] **Step 2: Typecheck**

```bash
cd uygulamalar/web && pnpm run typecheck
```
Expected: Hata yok.

- [ ] **Step 3: Commit**

```bash
git add uygulamalar/web/app/sunucu/medya/yonetici-yukleme/route.ts
git commit -m "feat(web): admin görsel kütüphanesi yükleme route'u"
```

---

### Task 7: Web — Admin izin/nav kayıtları

**Files:**
- Modify: `uygulamalar/web/src/lib/admin-izinler.ts`
- Modify: `uygulamalar/web/src/ui/kabuk/yonetici-kabuk-istemcisi.tsx`

- [ ] **Step 1: `admin-izinler.ts`'e yeni izin ekle**

Modify `uygulamalar/web/src/lib/admin-izinler.ts` — `AdminPermissionKey` union'ına ekle:

```typescript
// ÖNCE (son satır):
  | 'page:gelistirme-araclari' | 'page:kvkk-gdpr' | 'page:gecici-yuklemeler';

// SONRA:
  | 'page:gelistirme-araclari' | 'page:kvkk-gdpr' | 'page:gecici-yuklemeler'
  | 'page:gorsel-kutuphanesi';
```

`ADMIN_PERMISSIONS` dizisine ekle (Operasyon grubunun sonuna, `page:konumlar`'dan hemen sonra):

```typescript
  { key: 'page:konumlar', label: 'Konumlar', group: 'Operasyon', href: '/yonetici/konumlar' },
  { key: 'page:gorsel-kutuphanesi', label: 'Görsel Kütüphanesi', group: 'Operasyon', href: '/yonetici/gorsel-kutuphanesi' },
```

- [ ] **Step 2: Nav bileşenine ekle**

Modify `uygulamalar/web/src/ui/kabuk/yonetici-kabuk-istemcisi.tsx` — dosyayı önce oku (görsel kütüphanesi işi öncesindeki gerçek hâlini teyit et: `ImageIcon` importu zaten var mı — `page:fotograf-moderasyon` satırında `<ImageIcon />` kullanılıyor, aynı ikonu tekrar kullan ya da farklı bir ikon bileşeni gerekiyorsa mevcut ikon importlarının hemen yanına ekle). `Operasyon` grubunun `items` dizisine, `konumlar` satırından hemen sonra ekle:

```typescript
      { href: '/yonetici/konumlar', label: 'Konumlar', icon: <MapPinIcon /> },
      { href: '/yonetici/gorsel-kutuphanesi', label: 'Görsel Kütüphanesi', icon: <ImageIcon /> },
```

`ImageIcon` bu dosyada tanımlı değilse (yalnızca `fotograf-moderasyon/fotograf-moderasyon-istemci.tsx` gibi başka bir dosyada tanımlıysa), bu dosyanın kendi ikon tanımları bloğuna aynı stil bir `ImageIcon` fonksiyon bileşeni ekle:

```typescript
function ImageIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="3" width="18" height="18" rx="2" /><circle cx="8.5" cy="8.5" r="1.5" /><polyline points="21 15 16 10 5 21" />
    </svg>
  );
}
```

- [ ] **Step 3: Typecheck**

```bash
cd uygulamalar/web && pnpm run typecheck
```
Expected: Hata yok.

- [ ] **Step 4: Commit**

```bash
git add uygulamalar/web/src/lib/admin-izinler.ts uygulamalar/web/src/ui/kabuk/yonetici-kabuk-istemcisi.tsx
git commit -m "feat(web): admin nav'a Görsel Kütüphanesi sayfası eklendi"
```

---

### Task 8: Web — Admin "Görsel Kütüphanesi" sayfası

**Files:**
- Create: `uygulamalar/web/app/yonetici/gorsel-kutuphanesi/page.tsx`
- Create: `uygulamalar/web/app/yonetici/gorsel-kutuphanesi/gorsel-kutuphanesi-islemleri.ts`
- Create: `uygulamalar/web/app/yonetici/gorsel-kutuphanesi/gorsel-kutuphanesi-istemcisi.tsx`

- [ ] **Step 1: Server actions dosyasını yaz**

Create `uygulamalar/web/app/yonetici/gorsel-kutuphanesi/gorsel-kutuphanesi-islemleri.ts`:

```typescript
'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { checkAdminAccess } from '@/src/lib/auth/admin-guard';
import { logger } from '@/src/lib/kayitci';

type IslemSonucu = { ok: true } | { ok: false; error: string };

export async function gorselKaydet(
  id: string | null,
  imageUrl: string,
  keywords: string[],
  isActive: boolean,
): Promise<IslemSonucu> {
  const guard = await checkAdminAccess();
  if (!guard.authorized) {
    return { ok: false, error: 'unauthorized' };
  }
  const trimmedKeywords = keywords.map((k) => k.trim()).filter(Boolean);
  if (!id && !imageUrl.trim()) {
    return { ok: false, error: 'image_url_required' };
  }

  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as { rpc: (fn: string, args: Record<string, unknown>) => Promise<{ data: unknown; error: unknown }> };

  const { error } = await sb.rpc('admin_upsert_stock_dish_image_v1', {
    p_id: id,
    p_image_url: imageUrl.trim() || null,
    p_keywords: trimmedKeywords,
    p_is_active: isActive,
  });

  if (error) {
    logger.warn('gorselKaydet: RPC hatası', { error, id });
    return { ok: false, error: 'save_failed' };
  }

  revalidatePath('/yonetici/gorsel-kutuphanesi');
  return { ok: true };
}

export async function gorselPasiflestir(id: string, isActive: boolean): Promise<IslemSonucu> {
  const guard = await checkAdminAccess();
  if (!guard.authorized) {
    return { ok: false, error: 'unauthorized' };
  }

  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as { rpc: (fn: string, args: Record<string, unknown>) => Promise<{ data: unknown; error: unknown }> };

  const { error } = await sb.rpc('admin_upsert_stock_dish_image_v1', {
    p_id: id,
    p_is_active: isActive,
  });

  if (error) {
    logger.warn('gorselPasiflestir: RPC hatası', { error, id });
    return { ok: false, error: 'update_failed' };
  }

  revalidatePath('/yonetici/gorsel-kutuphanesi');
  return { ok: true };
}

export async function gorselSil(id: string): Promise<IslemSonucu> {
  const guard = await checkAdminAccess();
  if (!guard.authorized) {
    return { ok: false, error: 'unauthorized' };
  }

  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as { rpc: (fn: string, args: Record<string, unknown>) => Promise<{ data: unknown; error: unknown }> };

  const { error } = await sb.rpc('admin_delete_stock_dish_image_v1', { p_id: id });

  if (error) {
    logger.warn('gorselSil: RPC hatası', { error, id });
    return { ok: false, error: 'delete_failed' };
  }

  revalidatePath('/yonetici/gorsel-kutuphanesi');
  return { ok: true };
}
```

- [ ] **Step 2: Server component (page.tsx) yaz**

Create `uygulamalar/web/app/yonetici/gorsel-kutuphanesi/page.tsx`:

```tsx
import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { hasPermission } from '@/src/lib/yetki-kontrol';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi } from '@/src/ui/yerlesim/panel-section-card';
import { YetkisizErisim } from '@/src/ui/bilesenler/yetkisiz-erisim';
import { GorselKutuphanesiIstemcisi, type StokGorsel } from './gorsel-kutuphanesi-istemcisi';

export const metadata: Metadata = {
  title: 'Görsel Kütüphanesi | Admin Panel',
  robots: { index: false, follow: false },
};

export default async function GorselKutuphanesiPage() {
  const yetkili = await hasPermission('page:gorsel-kutuphanesi');
  if (!yetkili) {
    return (
      <div className="flex flex-col">
        <PanelSayfaBasligi eyebrow="Yönetici" title="Görsel Kütüphanesi" description="Bu sayfayı görüntüleme yetkiniz yok." />
        <PanelIcerikYuzeyi className="pt-6"><YetkisizErisim sayfaAdi="Görsel Kütüphanesi" /></PanelIcerikYuzeyi>
      </div>
    );
  }

  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as { rpc: (fn: string) => Promise<{ data: unknown; error: unknown }> };
  const { data } = await sb.rpc('admin_list_stock_dish_images_v1');
  const gorseller: StokGorsel[] = Array.isArray(data)
    ? (data as any[]).map((r) => ({
        id: r.id,
        image_url: r.image_url,
        keywords: Array.isArray(r.keywords) ? r.keywords : [],
        is_active: r.is_active,
        created_at: r.created_at,
      }))
    : [];

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Yönetim"
        title="Görsel Kütüphanesi"
        description="Sahiplerin ürün görseli yüklemediğinde önerilen stok yemek fotoğraflarını yönetin."
      />
      <PanelIcerikYuzeyi className="pt-6">
        <GorselKutuphanesiIstemcisi initialGorseller={gorseller} />
      </PanelIcerikYuzeyi>
    </div>
  );
}
```

- [ ] **Step 3: Client component (istemci) yaz**

Create `uygulamalar/web/app/yonetici/gorsel-kutuphanesi/gorsel-kutuphanesi-istemcisi.tsx`:

```tsx
'use client';

import Image from 'next/image';
import { useState, useTransition } from 'react';
import { gorselKaydet, gorselPasiflestir, gorselSil } from './gorsel-kutuphanesi-islemleri';

export type StokGorsel = {
  id: string;
  image_url: string;
  keywords: string[];
  is_active: boolean;
  created_at: string;
};

export function GorselKutuphanesiIstemcisi({ initialGorseller }: { initialGorseller: StokGorsel[] }) {
  const [gorseller, setGorseller] = useState(initialGorseller);
  const [isPending, startTransition] = useTransition();
  const [formError, setFormError] = useState<string | null>(null);

  // ── Yeni görsel ekleme formu ──
  const [uploading, setUploading] = useState(false);
  const [yeniUrl, setYeniUrl] = useState('');
  const [yeniKeywordsInput, setYeniKeywordsInput] = useState('');

  async function dosyaYukle(file: File | null) {
    if (!file) return;
    setUploading(true);
    setFormError(null);
    try {
      const formData = new FormData();
      formData.set('file', file);
      const response = await fetch('/sunucu/medya/yonetici-yukleme', { method: 'POST', body: formData });
      const payload = (await response.json().catch(() => null)) as { data?: { url?: string } } | null;
      if (!response.ok || !payload?.data?.url) throw new Error('upload_failed');
      setYeniUrl(payload.data.url);
    } catch {
      setFormError('Görsel yüklenemedi.');
    } finally {
      setUploading(false);
    }
  }

  function yeniGorselEkle() {
    if (!yeniUrl.trim()) {
      setFormError('Önce bir görsel yükleyin.');
      return;
    }
    const keywords = yeniKeywordsInput.split(',').map((k) => k.trim()).filter(Boolean);
    if (keywords.length === 0) {
      setFormError('En az bir anahtar ifade girin.');
      return;
    }
    setFormError(null);
    startTransition(async () => {
      const result = await gorselKaydet(null, yeniUrl, keywords, true);
      if (!result.ok) {
        setFormError(result.error);
        return;
      }
      setGorseller((prev) => [
        { id: crypto.randomUUID(), image_url: yeniUrl, keywords, is_active: true, created_at: new Date().toISOString() },
        ...prev,
      ]);
      setYeniUrl('');
      setYeniKeywordsInput('');
    });
  }

  function pasifDegistir(id: string, aktif: boolean) {
    startTransition(async () => {
      const result = await gorselPasiflestir(id, aktif);
      if (!result.ok) {
        setFormError(result.error);
        return;
      }
      setGorseller((prev) => prev.map((g) => (g.id === id ? { ...g, is_active: aktif } : g)));
    });
  }

  function sil(id: string) {
    if (!confirm('Bu görseli kalıcı olarak silmek istediğinize emin misiniz? Bu görseli daha önce seçmiş ürünler etkilenmez, ama görsel yeni önerilerde artık görünmeyecek.')) return;
    startTransition(async () => {
      const result = await gorselSil(id);
      if (!result.ok) {
        setFormError(result.error);
        return;
      }
      setGorseller((prev) => prev.filter((g) => g.id !== id));
    });
  }

  return (
    <div className="flex flex-col gap-6">
      <div className="rounded-2xl border border-border bg-card p-4">
        <h2 className="text-sm font-black text-textStrong">Yeni Görsel Ekle</h2>
        <div className="mt-3 grid gap-3 sm:grid-cols-[96px_1fr]">
          <div className="relative flex h-24 w-24 items-center justify-center overflow-hidden rounded-xl border border-border bg-bg text-[11px] font-extrabold text-muted">
            {yeniUrl ? <Image src={yeniUrl} alt="" fill sizes="96px" className="object-cover" unoptimized /> : 'Görsel yok'}
          </div>
          <div className="flex flex-col gap-2">
            <label className="inline-flex min-h-10 w-fit cursor-pointer items-center rounded-xl border border-border bg-card px-3 py-2 text-xs font-extrabold text-textStrong hover:bg-white">
              {uploading ? 'Yükleniyor...' : 'Görsel seç'}
              <input type="file" accept="image/png,image/jpeg,image/webp" disabled={uploading} onChange={(e) => dosyaYukle(e.target.files?.[0] ?? null)} className="sr-only" />
            </label>
            <input
              type="text"
              value={yeniKeywordsInput}
              onChange={(e) => setYeniKeywordsInput(e.target.value)}
              placeholder="Anahtar ifadeler, virgülle ayır (ör: mercimek çorbası, kırmızı mercimek çorbası)"
              className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30"
            />
            <button
              type="button"
              onClick={yeniGorselEkle}
              disabled={isPending || uploading}
              className="self-start rounded-xl bg-primary px-3 py-2 text-xs font-extrabold text-white disabled:opacity-60"
            >
              Kütüphaneye Ekle
            </button>
            {formError && <p className="text-xs font-bold text-red-600">{formError}</p>}
          </div>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4">
        {gorseller.map((g) => (
          <div key={g.id} className={`flex flex-col gap-2 rounded-2xl border border-border bg-card p-3 ${!g.is_active ? 'opacity-50' : ''}`}>
            <div className="relative h-28 w-full overflow-hidden rounded-xl">
              <Image src={g.image_url} alt="" fill sizes="200px" className="object-cover" unoptimized />
            </div>
            <div className="flex flex-wrap gap-1">
              {g.keywords.map((k) => (
                <span key={k} className="rounded-full bg-surface px-2 py-0.5 text-[10px] font-bold text-muted">{k}</span>
              ))}
            </div>
            <div className="mt-auto flex items-center justify-between gap-2">
              <label className="flex items-center gap-1.5 text-[11px] font-bold text-textStrong">
                <input type="checkbox" checked={g.is_active} onChange={(e) => pasifDegistir(g.id, e.target.checked)} className="rounded" />
                Aktif
              </label>
              <button type="button" onClick={() => sil(g.id)} className="text-[11px] font-bold text-red-600 hover:underline">Sil</button>
            </div>
          </div>
        ))}
        {gorseller.length === 0 && (
          <p className="col-span-full text-sm text-muted">Henüz kütüphanede görsel yok.</p>
        )}
      </div>
    </div>
  );
}
```

- [ ] **Step 4: Typecheck + lint**

```bash
cd uygulamalar/web && pnpm run typecheck && pnpm run lint
```
Expected: Hata yok. (`PanelSayfaBasligi`/`PanelIcerikYuzeyi`/`YetkisizErisim` import yollarının gerçek dosya konumuyla eşleştiğini typecheck doğrulayacak — `fotograf-moderasyon/page.tsx`'teki import satırlarıyla birebir aynı yollar kullanıldı.)

- [ ] **Step 5: Manuel doğrulama**

```bash
pnpm run dev
```
Tarayıcıda admin oturumuyla `/yonetici/gorsel-kutuphanesi`'ye git.
Expected: Sayfa açılıyor, Task 5'te eklenen 117 görsel ızgara halinde listeleniyor, yeni görsel ekleme formu çalışıyor.

- [ ] **Step 6: Commit**

```bash
git add uygulamalar/web/app/yonetici/gorsel-kutuphanesi/
git commit -m "feat(web): admin Görsel Kütüphanesi sayfası — CRUD"
```

---

### Task 9: Web — `varsayilan-yemek-gorseli.ts` refactor (DB-tabanlı, kategori-önsüzsüz)

**Files:**
- Modify: `uygulamalar/web/src/lib/menu/varsayilan-yemek-gorseli.ts`
- Create: `uygulamalar/web/src/lib/menu/stok-yemek-kutuphanesi.ts`
- Modify: `uygulamalar/web/test/lib/menu/varsayilan-yemek-gorseli.test.ts`

- [ ] **Step 1: Başarısız testi yaz (yeni imza)**

Modify `uygulamalar/web/test/lib/menu/varsayilan-yemek-gorseli.test.ts` — dosyanın tamamını değiştir:

```typescript
import { describe, expect, it } from 'vitest';
import { bulEslesenYemekGorselleri, bulVarsayilanYemekGorseli, type StockDishImage } from '@/src/lib/menu/varsayilan-yemek-gorseli';

const KUTUPHANE: StockDishImage[] = [
  { id: '1', image_url: 'https://x.test/corbalar/mercimek.webp', keywords: ['mercimek çorbası'] },
  { id: '2', image_url: 'https://x.test/sulu_yemekler/ali_nazik.webp', keywords: ['ali nazik'] },
  { id: '3', image_url: 'https://x.test/zeytinyaglilar/barbunya.webp', keywords: ['zeytinyağlı barbunya'] },
  { id: '4', image_url: 'https://x.test/sulu_yemekler/bamya.webp', keywords: ['etli bamya'] },
  { id: '5', image_url: 'https://x.test/corbalar/bamya.webp', keywords: ['bamya çorbası'] },
];

describe('bulVarsayilanYemekGorseli', () => {
  it('ürün adı bir anahtar ifadeyi içeriyorsa ilgili görseli döner', () => {
    expect(bulVarsayilanYemekGorseli('Mercimek Çorbası', KUTUPHANE)).toBe('https://x.test/corbalar/mercimek.webp');
  });

  it('bitişik yazılmış yemek adını da eşleştirir (ör. "Alinazik")', () => {
    expect(bulVarsayilanYemekGorseli('Alinazik Kebap', KUTUPHANE)).toBe('https://x.test/sulu_yemekler/ali_nazik.webp');
  });

  it('aynı kelime birden fazla görselde geçerse en uzun/özgül anahtar kazanır', () => {
    // "Etli Bamya Çorbası" hem "etli bamya" (11 char) hem "bamya çorbası" (13 char)
    // ile eşleşir — daha uzun/özgül olan kazanmalı.
    expect(bulVarsayilanYemekGorseli('Etli Bamya Çorbası', KUTUPHANE)).toBe('https://x.test/corbalar/bamya.webp');
  });

  it('hiçbir anahtar ifade eşleşmiyorsa null döner', () => {
    expect(bulVarsayilanYemekGorseli('Cheeseburger', KUTUPHANE)).toBeNull();
  });

  it('boş kütüphaneyle null döner (hata fırlatmaz)', () => {
    expect(bulVarsayilanYemekGorseli('Mercimek Çorbası', [])).toBeNull();
  });
});

describe('bulEslesenYemekGorselleri', () => {
  it('birden fazla eşleşmeyi en özgülden en genele sıralı döner', () => {
    const sonuc = bulEslesenYemekGorselleri('Etli Bamya Çorbası', KUTUPHANE);
    expect(sonuc.map((s) => s.id)).toEqual(['5', '4']);
  });

  it('eşleşme yoksa boş dizi döner', () => {
    expect(bulEslesenYemekGorselleri('Cheeseburger', KUTUPHANE)).toEqual([]);
  });
});
```

- [ ] **Step 2: Testi çalıştır, başarısız olduğunu doğrula**

```bash
cd uygulamalar/web && pnpm vitest run test/lib/menu/varsayilan-yemek-gorseli.test.ts
```
Expected: FAIL — `bulEslesenYemekGorselleri`/`StockDishImage` export edilmiyor, imza uyuşmazlığı.

- [ ] **Step 3: Modülü yeniden yaz**

Modify `uygulamalar/web/src/lib/menu/varsayilan-yemek-gorseli.ts` — dosyanın tamamını değiştir:

```typescript
/**
 * Sahip görsel yüklemediyse gösterilecek stok yemek fotoğrafını bulur.
 * Kaynak: DB-tabanlı `stock_dish_images` kütüphanesi (get_stock_dish_images_v1
 * RPC'siyle çekilir, bkz. stok-yemek-kutuphanesi.ts) — admin panelinden
 * (`/yonetici/gorsel-kutuphanesi`) yönetilir. Eskiden kod içine gömülü statik
 * bir sözlüktü, artık salt eşleştirme algoritması burada, veri kütüphaneden
 * gelir.
 */

export type StockDishImage = { id: string; image_url: string; keywords: string[] };

// Türkçe karakterleri sadeleştirip tüm boşluk/noktalama işaretlerini siler —
// "Karnıyarık", "karni_yarik" ve "Karnı Yarık" hepsi "karniyarik" olur, böylece
// hem admin'in girdiği anahtar ifade hem sahibin yazım biçimi (bitişik/ayrık)
// eşleşmeyi bozmaz.
function normalizeTr(s: string): string {
  return s
    .toLocaleLowerCase('tr')
    .replace(/ç/g, 'c')
    .replace(/ğ/g, 'g')
    .replace(/ı/g, 'i')
    .replace(/ö/g, 'o')
    .replace(/ş/g, 's')
    .replace(/ü/g, 'u')
    .replace(/[^a-z0-9]+/g, '');
}

/**
 * Ürün adına eşleşen tüm stok görselleri, en uzun/özgül anahtar ifadeden en
 * genele doğru sıralı döner. Owner-facing "Sistemden Seç" adayları için.
 */
export function bulEslesenYemekGorselleri(urunAdi: string, library: StockDishImage[]): StockDishImage[] {
  const n = normalizeTr(urunAdi);
  if (!n) return [];

  const scored: Array<{ item: StockDishImage; len: number }> = [];
  for (const item of library) {
    let bestLen = 0;
    for (const kw of item.keywords) {
      const nk = normalizeTr(kw);
      if (nk && n.includes(nk) && nk.length > bestLen) bestLen = nk.length;
    }
    if (bestLen > 0) scored.push({ item, len: bestLen });
  }
  scored.sort((a, b) => b.len - a.len);
  return scored.map((s) => s.item);
}

/**
 * Otomatik sessiz fallback için tek (en iyi) eşleşmenin image_url'ini döner,
 * eşleşme yoksa null (çağıran taraf mevcut jenerik ikon/emoji fallback'ine
 * düşmeli).
 */
export function bulVarsayilanYemekGorseli(urunAdi: string, library: StockDishImage[]): string | null {
  return bulEslesenYemekGorselleri(urunAdi, library)[0]?.image_url ?? null;
}
```

- [ ] **Step 4: Fetch/cache modülünü yaz**

Create `uygulamalar/web/src/lib/menu/stok-yemek-kutuphanesi.ts`:

```typescript
import { createSupabaseBrowserClient } from '@/src/lib/supabaseClient';
import type { StockDishImage } from './varsayilan-yemek-gorseli';

// Sayfa/sekme yüklendiğinde bir kez çekilir, aynı tarayıcı oturumunda tekrar
// kullanılır — kütüphane küçük (bugün 117 satır) ve yavaş büyüyor, ürün
// başına ayrı RPC çağrısına gerek yok.
let cache: Promise<StockDishImage[]> | null = null;

export function getStokYemekKutuphanesi(): Promise<StockDishImage[]> {
  if (!cache) {
    cache = fetchStokYemekKutuphanesi();
  }
  return cache;
}

async function fetchStokYemekKutuphanesi(): Promise<StockDishImage[]> {
  try {
    const supabase = createSupabaseBrowserClient();
    const sb = supabase as unknown as { rpc: (fn: string) => Promise<{ data: unknown; error: unknown }> };
    const { data, error } = await sb.rpc('get_stock_dish_images_v1');
    if (error || !Array.isArray(data)) return [];
    return (data as any[]).map((r) => ({
      id: String(r.id),
      image_url: String(r.image_url),
      keywords: Array.isArray(r.keywords) ? r.keywords.map(String) : [],
    }));
  } catch {
    return [];
  }
}
```

- [ ] **Step 5: Testi çalıştır, geçtiğini doğrula**

```bash
pnpm vitest run test/lib/menu/varsayilan-yemek-gorseli.test.ts
```
Expected: PASS (7/7)

- [ ] **Step 6: Typecheck**

```bash
pnpm run typecheck
```
Expected: `menu-duzen.tsx`'te eski 3-parametreli çağrı (`bulVarsayilanYemekGorseli(item.name, catName)`) artık tip hatası verecek — bu Task 10'da düzeltilecek. Bu adımda hatayı görüp not almak yeterli, henüz düzeltme.

- [ ] **Step 7: Commit**

```bash
git add uygulamalar/web/src/lib/menu/varsayilan-yemek-gorseli.ts uygulamalar/web/src/lib/menu/stok-yemek-kutuphanesi.ts uygulamalar/web/test/lib/menu/varsayilan-yemek-gorseli.test.ts
git commit -m "refactor(web): varsayilan-yemek-gorseli DB-tabanlı kütüphaneye taşındı"
```

---

### Task 10: Web — `menu-duzen.tsx` entegrasyonu

**Files:**
- Modify: `uygulamalar/web/src/ui/bolumler/menu-sayfasi/menu-duzen.tsx`

- [ ] **Step 1: Dosyayı oku, mevcut `catName`/`bulVarsayilanYemekGorseli` kullanımını bul**

Read `uygulamalar/web/src/ui/bolumler/menu-sayfasi/menu-duzen.tsx` — Task 9'daki tip hatası şu satırlardan gelecek: `UrunSatiri` bileşeninin `catName` prop'u ve `bulVarsayilanYemekGorseli(item.name, catName)` çağrısı (2026-08-24'te bu oturumun daha önceki bir aşamasında eklenmişti). Kategori-önsüz filtre kaldırıldığı için `catName` prop'una artık gerek yok — DB-tabanlı kütüphane bileşenin en üstünde bir kez çekilip `UrunSatiri`'ye geçirilecek.

- [ ] **Step 2: `useState`/`useEffect` importu ve kütüphane state'i ekle**

Modify import satırını:

```typescript
// ÖNCE:
import { useState } from 'react';

// SONRA:
import { useEffect, useState } from 'react';
```

`bulVarsayilanYemekGorseli` importunu güncelle:

```typescript
// ÖNCE:
import { bulVarsayilanYemekGorseli } from '@/src/lib/menu/varsayilan-yemek-gorseli';

// SONRA:
import { bulVarsayilanYemekGorseli, type StockDishImage } from '@/src/lib/menu/varsayilan-yemek-gorseli';
import { getStokYemekKutuphanesi } from '@/src/lib/menu/stok-yemek-kutuphanesi';
```

`MenuDuzen` bileşeninin state tanımlarının hemen altına (mevcut `useState` satırlarının bulunduğu bloğa) ekle:

```typescript
  const [stokKutuphanesi, setStokKutuphanesi] = useState<StockDishImage[]>([]);

  useEffect(() => {
    getStokYemekKutuphanesi().then(setStokKutuphanesi);
  }, []);
```

- [ ] **Step 3: `UrunSatiri` çağrısını ve bileşenini güncelle**

`UrunSatiri` çağrı satırını değiştir:

```typescript
// ÖNCE:
                        <UrunSatiri key={item.id} item={item} catName={catName} />

// SONRA:
                        <UrunSatiri key={item.id} item={item} stokKutuphanesi={stokKutuphanesi} />
```

`UrunSatiri` fonksiyon imzasını ve içindeki çağrıyı değiştir:

```typescript
// ÖNCE:
function UrunSatiri({ item, catName }: { item: MenuItemRecord; catName?: string }) {
  const varsayilanUrl = item.image_url ? null : bulVarsayilanYemekGorseli(item.name, catName);

// SONRA:
function UrunSatiri({ item, stokKutuphanesi }: { item: MenuItemRecord; stokKutuphanesi: StockDishImage[] }) {
  const varsayilanUrl = item.image_url ? null : bulVarsayilanYemekGorseli(item.name, stokKutuphanesi);
```

- [ ] **Step 4: Typecheck**

```bash
cd uygulamalar/web && pnpm run typecheck
```
Expected: Hata yok.

- [ ] **Step 5: Lint + tüm testler**

```bash
pnpm run lint && pnpm run test:unit
```
Expected: 0 hata, tüm testler geçer.

- [ ] **Step 6: Commit**

```bash
git add uygulamalar/web/src/ui/bolumler/menu-sayfasi/menu-duzen.tsx
git commit -m "refactor(web): menu-duzen artık DB-tabanlı stok kütüphanesini kullanıyor"
```

---

### Task 11: Web — `urun-paneli.tsx`'e "Sistemden Seç" ekleme

**Files:**
- Modify: `uygulamalar/web/app/sahip/menuler/[menuId]/duzenle/bilesenler/urun-paneli.tsx`

- [ ] **Step 1: Dosyayı oku, `ImageUrlField` bileşenini teyit et**

Read `uygulamalar/web/app/sahip/menuler/[menuId]/duzenle/bilesenler/urun-paneli.tsx` — `ImageUrlField` bileşeninin gerçek güncel hâlini doğrula (özellikle `url`/`setUrl`/`uploading`/`aiGenerating`/`isBusy` state'leri ve buton satırının yapısı).

- [ ] **Step 2: Import ekle**

Dosyanın en üstüne ekle:

```typescript
import { bulEslesenYemekGorselleri, type StockDishImage } from '../../../../../../src/lib/menu/varsayilan-yemek-gorseli';
import { getStokYemekKutuphanesi } from '../../../../../../src/lib/menu/stok-yemek-kutuphanesi';
```

(Gerçek göreli yol derinliğini dosyanın konumuna göre doğrula — `app/sahip/menuler/[menuId]/duzenle/bilesenler/` içinden `src/lib/menu/`'ye kaç `../` gerektiğini say; alternatif olarak proje `@/` path alias'ını destekliyorsa (diğer dosyalarda `@/src/lib/...` kullanıldığı görüldü) onu tercih et: `import { ... } from '@/src/lib/menu/varsayilan-yemek-gorseli';`.)

- [ ] **Step 3: `ImageUrlField`'e state ve fonksiyon ekle**

`ImageUrlField` bileşeninin state tanımlarının hemen altına ekle:

```typescript
  const [stokAcik, setStokAcik] = useState(false);
  const [stokAdaylar, setStokAdaylar] = useState<StockDishImage[]>([]);
  const [stokYukleniyor, setStokYukleniyor] = useState(false);

  async function sistemdenSecAc() {
    if (stokAcik) { setStokAcik(false); return; }
    const nameInput = itemNameRef.current?.elements.namedItem('name') as HTMLInputElement | null;
    const name = nameInput?.value?.trim();
    if (!name) { setUploadError('Sistemden seçmeden önce ürün adını girin.'); return; }
    setStokYukleniyor(true);
    setUploadError(null);
    try {
      const kutuphane = await getStokYemekKutuphanesi();
      setStokAdaylar(bulEslesenYemekGorselleri(name, kutuphane).slice(0, 12));
      setStokAcik(true);
    } finally {
      setStokYukleniyor(false);
    }
  }
```

- [ ] **Step 4: Buton grubuna "Sistemden seç" ekle ve aday ızgarasını render et**

Mevcut buton grubuna ("Bilgisayardan seç" label'ından hemen sonra) ekle:

```tsx
// ÖNCE:
          <label className="inline-flex min-h-10 cursor-pointer items-center rounded-xl border border-border bg-card px-3 py-2 text-xs font-extrabold text-textStrong hover:bg-white">
            {uploading ? 'Yükleniyor...' : 'Bilgisayardan seç'}
            <input type="file" accept="image/png,image/jpeg,image/webp" disabled={isBusy} onChange={(event) => upload(event.target.files?.[0] ?? null)} className="sr-only" />
          </label>
          {url && (

// SONRA:
          <label className="inline-flex min-h-10 cursor-pointer items-center rounded-xl border border-border bg-card px-3 py-2 text-xs font-extrabold text-textStrong hover:bg-white">
            {uploading ? 'Yükleniyor...' : 'Bilgisayardan seç'}
            <input type="file" accept="image/png,image/jpeg,image/webp" disabled={isBusy} onChange={(event) => upload(event.target.files?.[0] ?? null)} className="sr-only" />
          </label>
          <button type="button" onClick={sistemdenSecAc} disabled={isBusy || stokYukleniyor} className="inline-flex min-h-10 items-center rounded-xl border border-border bg-card px-3 py-2 text-xs font-extrabold text-textStrong hover:bg-white disabled:opacity-60 cursor-pointer">
            {stokYukleniyor ? 'Aranıyor...' : '🖼️ Sistemden seç'}
          </button>
          {url && (
```

`ImageUrlField`'in JSX'inin en sonuna (mevcut buton grubunu saran `<div className="flex flex-wrap items-center gap-2">...</div>` kapanışından hemen sonra, `uploadError` satırından sonra) ekle:

```tsx
        {stokAcik && (
          <div className="flex flex-wrap gap-2 rounded-xl border border-border bg-bg p-2">
            {stokAdaylar.length === 0 ? (
              <p className="text-xs text-muted">Eşleşen stok görsel bulunamadı.</p>
            ) : (
              stokAdaylar.map((aday) => (
                <button
                  key={aday.id}
                  type="button"
                  onClick={() => { setUrl(aday.image_url); setStokAcik(false); }}
                  className="relative h-16 w-16 overflow-hidden rounded-lg border border-border hover:ring-2 hover:ring-primary cursor-pointer"
                >
                  <Image src={aday.image_url} alt="" fill sizes="64px" className="object-cover" unoptimized />
                </button>
              ))
            )}
          </div>
        )}
```

- [ ] **Step 5: Typecheck**

```bash
cd uygulamalar/web && pnpm run typecheck
```
Expected: Hata yok. (Göreli import yolu hatası varsa Step 2'deki notu izleyip `@/` alias'ına geç.)

- [ ] **Step 6: Manuel doğrulama**

```bash
pnpm run dev
```
Sahip panelinde bir menüye git, "Yeni Ürün" aç, ürün adına "Mercimek Çorbası" yaz, görsel alanındaki "🖼️ Sistemden seç" butonuna tıkla.
Expected: Eşleşen stok görsel(ler) küçük ızgara halinde beliriyor, birine tıklayınca üstteki 96px önizleme o görsele dönüyor.

- [ ] **Step 7: Commit**

```bash
git add uygulamalar/web/app/sahip/menuler/[menuId]/duzenle/bilesenler/urun-paneli.tsx
git commit -m "feat(web): ürün görsel seçicisine 'Sistemden seç' eklendi"
```

---

### Task 12: Mobil — `varsayilan_yemek_sozlugu.dart` refactor + `menu_page.dart` entegrasyonu

**Files:**
- Modify: `uygulamalar/mobil/lib/features/menus/data/varsayilan_yemek_sozlugu.dart`
- Modify: `uygulamalar/mobil/lib/features/menus/ui/menu_page.dart`
- Modify: `uygulamalar/mobil/test/features/menus/data/varsayilan_yemek_sozlugu_test.dart`

- [ ] **Step 1: Başarısız testi yaz (yeni imza)**

Modify `uygulamalar/mobil/test/features/menus/data/varsayilan_yemek_sozlugu_test.dart` — dosyanın tamamını değiştir:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/features/menus/data/varsayilan_yemek_sozlugu.dart';

void main() {
  final kutuphane = [
    const StockDishImage(id: '1', imageUrl: 'https://x.test/corbalar/mercimek.webp', keywords: ['mercimek çorbası']),
    const StockDishImage(id: '2', imageUrl: 'https://x.test/sulu_yemekler/ali_nazik.webp', keywords: ['ali nazik']),
    const StockDishImage(id: '4', imageUrl: 'https://x.test/sulu_yemekler/bamya.webp', keywords: ['etli bamya']),
    const StockDishImage(id: '5', imageUrl: 'https://x.test/corbalar/bamya.webp', keywords: ['bamya çorbası']),
  ];

  group('VarsayilanYemekSozlugu.bul', () {
    test('urun adi bir anahtar ifadeyi iceriyorsa ilgili gorseli doner', () {
      expect(
        VarsayilanYemekSozlugu.bul('Mercimek Corbasi', kutuphane),
        'https://x.test/corbalar/mercimek.webp',
      );
    });

    test('bitisik yazilmis yemek adini da eslestirir (or. "Alinazik")', () {
      expect(
        VarsayilanYemekSozlugu.bul('Alinazik Kebap', kutuphane),
        'https://x.test/sulu_yemekler/ali_nazik.webp',
      );
    });

    test('ayni kelime birden fazla goselde geçerse en uzun/ozgul anahtar kazanir', () {
      expect(
        VarsayilanYemekSozlugu.bul('Etli Bamya Corbasi', kutuphane),
        'https://x.test/corbalar/bamya.webp',
      );
    });

    test('hicbir anahtar ifade eslesmiyorsa null doner', () {
      expect(VarsayilanYemekSozlugu.bul('Cheeseburger', kutuphane), isNull);
    });

    test('bos kutuphaneyle null doner (hata firlatmaz)', () {
      expect(VarsayilanYemekSozlugu.bul('Mercimek Corbasi', const []), isNull);
    });
  });

  group('StockDishImage.fromMap', () {
    test('gecerli map alanlarini dogru parse eder', () {
      final item = StockDishImage.fromMap({
        'id': '42',
        'image_url': 'https://x.test/a.webp',
        'keywords': ['a', 'b'],
      });
      expect(item.id, '42');
      expect(item.imageUrl, 'https://x.test/a.webp');
      expect(item.keywords, ['a', 'b']);
    });

    test('eksik keywords alaniyla bos listeye duser', () {
      final item = StockDishImage.fromMap({'id': '1', 'image_url': 'https://x.test/a.webp'});
      expect(item.keywords, isEmpty);
    });
  });
}
```

- [ ] **Step 2: Testi çalıştır, başarısız olduğunu doğrula**

```bash
cd uygulamalar/mobil && flutter test test/features/menus/data/varsayilan_yemek_sozlugu_test.dart
```
Expected: FAIL — `StockDishImage` tanımlı değil, `bul` imza uyuşmazlığı.

- [ ] **Step 3: Modülü yeniden yaz**

Modify `uygulamalar/mobil/lib/features/menus/data/varsayilan_yemek_sozlugu.dart` — dosyanın tamamını değiştir:

```dart
/// Sahip görsel yüklemediyse gösterilecek stok yemek fotoğrafını bulur.
///
/// Kaynak: DB-tabanlı `stock_dish_images` kütüphanesi (get_stock_dish_images_v1
/// RPC'siyle çekilir, bkz. menu_page.dart'taki _stockDishImagesProvider) —
/// admin panelinden (`/yonetici/gorsel-kutuphanesi`) yönetilir. Web
/// karşılığı: uygulamalar/web/src/lib/menu/varsayilan-yemek-gorseli.ts —
/// aynı eşleştirme algoritması, ayrı Dart implementasyonu (Dart/TS runtime
/// paylaşımı mümkün olmadığı için).
class StockDishImage {
  const StockDishImage({
    required this.id,
    required this.imageUrl,
    required this.keywords,
  });

  final String id;
  final String imageUrl;
  final List<String> keywords;

  factory StockDishImage.fromMap(Map<String, dynamic> map) {
    return StockDishImage(
      id: (map['id'] ?? '').toString(),
      imageUrl: (map['image_url'] ?? '').toString(),
      keywords: ((map['keywords'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class VarsayilanYemekSozlugu {
  const VarsayilanYemekSozlugu._();

  // Türkçe karakterleri sadeleştirip tüm boşluk/noktalama işaretlerini siler
  // — "Karnıyarık", "karni_yarik" ve "Karnı Yarık" hepsi "karniyarik" olur,
  // böylece hem admin'in girdiği anahtar ifade hem sahibin yazım biçimi
  // (bitişik/ayrık) eşleşmeyi bozmaz.
  static String _normalize(String s) {
    var n = s.toLowerCase();
    n = n
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u');
    return n.replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  /// Ürün adına eşleşen en iyi (en uzun/özgül anahtar ifadeli) stok görselin
  /// URL'ini döner. Eşleşme yoksa null — çağıran taraf mevcut jenerik
  /// ikon/placeholder'a düşmeli.
  static String? bul(String urunAdi, List<StockDishImage> kutuphane) {
    final n = _normalize(urunAdi);
    if (n.isEmpty) return null;

    String? bestUrl;
    var bestLen = 0;
    for (final item in kutuphane) {
      for (final kw in item.keywords) {
        final nk = _normalize(kw);
        if (nk.isNotEmpty && n.contains(nk) && nk.length > bestLen) {
          bestLen = nk.length;
          bestUrl = item.imageUrl;
        }
      }
    }
    return bestUrl;
  }
}
```

- [ ] **Step 4: Testi çalıştır, geçtiğini doğrula**

```bash
flutter test test/features/menus/data/varsayilan_yemek_sozlugu_test.dart
```
Expected: PASS (7/7)

- [ ] **Step 5: `menu_page.dart`'a provider ekle ve entegre et**

Read `uygulamalar/mobil/lib/features/menus/ui/menu_page.dart` — mevcut `_menuItemVariantsProvider` tanımının (satır ~87-125 civarı, `supabaseProvider` kullanan `FutureProvider.autoDispose.family`) hemen altına, aynı dosyada yeni bir provider ekle:

```dart
final _stockDishImagesProvider = FutureProvider.autoDispose<List<StockDishImage>>((ref) async {
  final client = ref.watch(supabaseProvider);
  final res = await client.rpc('get_stock_dish_images_v1');
  if (res is! List) return const [];
  return res
      .whereType<Map>()
      .map((m) => StockDishImage.fromMap(m.cast<String, dynamic>()))
      .toList();
});
```

Dosyanın en üstündeki import bloğuna ekle:

```dart
import '../data/varsayilan_yemek_sozlugu.dart';
```

`_MenuPageState.build()` metodunun içinde (mevcut `ref.watch(...)` çağrılarının yakınında, `itemsBySection`/`variantsByItem` gibi verinin hazırlandığı yerde) ekle:

```dart
final stockDishImagesAsync = ref.watch(_stockDishImagesProvider);
final stockDishImages = stockDishImagesAsync.value ?? const <StockDishImage>[];
```

Üç `_MenuItemRow(...)` çağrı sitesinin (satır ~476, ~507, ~536 civarı — Task 12 öncesi bu oturumda `categoryAdi: section.title` eklenmişti, yalnızca ilk çağrı sitesinde) HER ÜÇÜNE de `stockDishImages: stockDishImages,` parametresini ekle; `categoryAdi: section.title,` satırını kaldır (artık kullanılmıyor — kategori-önsüz flat eşleştirmeye geçildi):

```dart
// ÖNCE (ilk çağrı sitesi, satır ~476 civarı):
                        _MenuItemRow(
                          t: t,
                          item: item,
                          variants: variantsByItem[item.id] ?? const [],
                          lastPriceAt: _priceAgeMap[item.id],
                          priceAgeError: _ageError,
                          categoryAdi: section.title,
                          onVerifyTap: () => _openVerifyPriceSheet(item),

// SONRA:
                        _MenuItemRow(
                          t: t,
                          item: item,
                          variants: variantsByItem[item.id] ?? const [],
                          lastPriceAt: _priceAgeMap[item.id],
                          priceAgeError: _ageError,
                          stockDishImages: stockDishImages,
                          onVerifyTap: () => _openVerifyPriceSheet(item),
```

Diğer iki çağrı sitesinde (categoryAdi hiç yoktu) sadece `stockDishImages: stockDishImages,` satırını `priceAgeError: _ageError,`'den hemen sonra ekle.

- [ ] **Step 6: `_MenuItemRow` widget'ını güncelle**

`_MenuItemRow` constructor'ını ve alanını değiştir:

```dart
// ÖNCE:
class _MenuItemRow extends StatefulWidget {
  const _MenuItemRow({
    required this.t,
    required this.item,
    required this.variants,
    required this.onTap,
    required this.onVerifyTap,
    required this.lastPriceAt,
    required this.priceAgeError,
    this.categoryAdi,
  });
  final AppLocalizations t;
  final MenuItem item;
  final List<_MenuItemVariant> variants;
  final VoidCallback onTap;
  final VoidCallback onVerifyTap;
  final DateTime? lastPriceAt;
  final Object? priceAgeError;
  final String? categoryAdi;

// SONRA:
class _MenuItemRow extends StatefulWidget {
  const _MenuItemRow({
    required this.t,
    required this.item,
    required this.variants,
    required this.onTap,
    required this.onVerifyTap,
    required this.lastPriceAt,
    required this.priceAgeError,
    required this.stockDishImages,
  });
  final AppLocalizations t;
  final MenuItem item;
  final List<_MenuItemVariant> variants;
  final VoidCallback onTap;
  final VoidCallback onVerifyTap;
  final DateTime? lastPriceAt;
  final Object? priceAgeError;
  final List<StockDishImage> stockDishImages;
```

`_MenuItemRowState.build()` içindeki hesaplamayı değiştir:

```dart
// ÖNCE:
    final varsayilanGorselUrl = (imageUrl == null && dataBytes == null)
        ? VarsayilanYemekSozlugu.bul(item.name, widget.categoryAdi)
        : null;

// SONRA:
    final varsayilanGorselUrl = (imageUrl == null && dataBytes == null)
        ? VarsayilanYemekSozlugu.bul(item.name, widget.stockDishImages)
        : null;
```

- [ ] **Step 7: `flutter analyze` çalıştır**

```bash
flutter analyze
```
Expected: `No issues found!`

- [ ] **Step 8: İlgili testleri çalıştır**

```bash
flutter test test/features/menus/
```
Expected: Tüm testler PASS, regresyon yok.

- [ ] **Step 9: Commit**

```bash
git add uygulamalar/mobil/lib/features/menus/data/varsayilan_yemek_sozlugu.dart uygulamalar/mobil/lib/features/menus/ui/menu_page.dart uygulamalar/mobil/test/features/menus/data/varsayilan_yemek_sozlugu_test.dart
git commit -m "refactor(mobil): varsayilan_yemek_sozlugu DB-tabanlı kütüphaneye taşındı"
```

---

### Task 13: Doğrulama — tam test paketi + manuel senaryo listesi

**Files:** (yok — yalnızca doğrulama)

- [ ] **Step 1: Web tam kontrol**

```bash
cd uygulamalar/web
pnpm run typecheck
pnpm run lint
pnpm run test:unit
```
Expected: Üçü de hatasız/başarısız test olmadan biter.

- [ ] **Step 2: Mobil tam kontrol**

```bash
cd uygulamalar/mobil
flutter analyze
flutter test
```
Expected: `No issues found!`, tüm testler geçer (Task 12'den önceki test paketiyle karşılaştır — yeni başarısızlık olmamalı; varsa `git stash` ile Task 12 öncesi duruma dönüp aynı testin zaten başarısız olup olmadığını doğrula, bu oturumda daha önce kullanılan yöntem).

- [ ] **Step 3: Supabase advisors kontrolü**

Yeni 6 fonksiyon (`get_stock_dish_images_v1`, `admin_list/upsert/delete_stock_dish_image_v1`) ve yeni tablo (`stock_dish_images`) için beklenmeyen güvenlik bulgusu var mı kontrol et (`mcp__supabase__get_advisors(type=security)` ya da eşdeğer).
Expected: `stock_dish_images` için RLS-enabled-no-policy bir INFO bulgusu beklenir (kasıtlı — tüm erişim RPC üzerinden), başka yeni WARN/ERROR olmamalı. `get_stock_dish_images_v1`'in `anon`'a açık SECURITY DEFINER fonksiyon olması beklenen bir INFO/WARN'dır (kasıtlı, public okuma).

- [ ] **Step 4: Uçtan uca manuel senaryo listesi**

- Admin `/yonetici/gorsel-kutuphanesi`'nde yeni bir görsel yükleyip anahtar ifade ekliyor → listede görünüyor.
- Admin bir görseli pasifleştiriyor → sahip panelinde "Sistemden Seç" artık bu görseli önermiyor, ama daha önce bu görseli seçmiş bir ürünün görseli bozulmuyor.
- Sahip yeni ürün eklerken "Mercimek Çorbası" yazıp "🖼️ Sistemden seç"e tıklıyor → eşleşen görsel(ler) çıkıyor, birini seçince form alanı doluyor, kaydedince ürünün `image_url`'i o görsel oluyor.
- Görselsiz bir ürün, adı hiçbir kütüphane girdisiyle eşleşmiyorsa hem sahip önizlemesinde hem public QR menü sayfasında mevcut jenerik 🍽️ ikonuna düşüyor (regresyon yok).
- Mobil müşteri menü sayfasında görselsiz bir ürün, adı eşleşiyorsa stok fotoğrafı, eşleşmiyorsa jenerik tabak ikonunu gösteriyor (regresyon yok — Task 12 öncesi de bu davranış vardı, sadece veri kaynağı değişti).

- [ ] **Step 5: Plan dosyasındaki tüm checkbox'ları işaretle**

`docs/superpowers/plans/2026-08-24-yemek-gorsel-kutuphanesi.md` içindeki tüm `- [ ]` satırlarını `- [x]` yap.

```bash
cd /c/yeedoy
sed -i 's/^- \[ \]/- [x]/' docs/superpowers/plans/2026-08-24-yemek-gorsel-kutuphanesi.md
```

- [ ] **Step 6: Final commit**

```bash
git add -A
git commit -m "chore: yemek görsel kütüphanesi doğrulama turu tamamlandı"
```

---

## Self-Review Notu

Spec'teki her madde bir task'a karşılık geliyor: veri modeli → Task 1, eşleştirme mantığı → Task 9/12, erişim/performans RPC'leri → Task 2-3, admin paneli → Task 4/6-8, sahip tarafı entegrasyonu → Task 10-11, 117 görselin taşınması → Task 5, test/doğrulama planı → Task 13. Mobilde owner-facing CRUD olmadığı doğrulaması (plan yazımı sırasında) Task 12'nin kapsamını "sadece veri kaynağı güncellemesi"yle sınırladı — spec'teki düzeltmeyle tutarlı. `ImageUrlField`'in gerçek kompakt yapısı (tam ekran sekme değil) Task 11'de mockup'tan ziyade gerçek dosya okunarak uyarlandı. Type tutarlılığı: `StockDishImage` (web TS ve mobil Dart, iki ayrı ama paralel tanım), `bulEslesenYemekGorselleri`/`bulVarsayilanYemekGorseli` (web) ve `VarsayilanYemekSozlugu.bul` (mobil) imzaları Task 9/12 boyunca tutarlı kullanıldı.
