# Menü Düzenleyici Yeniden Tasarımı Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `/sahip/menuler/[menuId]/duzenle` sayfasını, kullanıcının referans görseline göre (istatistik kartları, kategori sekmeleri, filtrelenebilir/sürüklenebilir tablo, toplu işlemler, yan panelde düzenleme, sidebar widget'ları) baştan inşa etmek. Bu bir restorasyon değil — hem eski `app/owner` hem şu anki `app/sahip` sürümünde bu tasarım hiç var olmadı.

**Architecture:** Mevcut `menu-duzenleyici-istemcisi.tsx` (869 satır, tek dosya, accordion UI) küçük, odaklı bileşenlere bölünüyor (`bilesenler/` alt klasörü). Veri modeli değişmiyor (`menu_sections`="Kategori", `menu_items.is_available`=durum). Üç yeni server action ekleniyor (sıralama, toplu işlemler, kopyalama). Sürükle-bırak native HTML5 `draggable` API ile yapılıyor — yeni bağımlılık eklenmiyor.

**Tech Stack:** Next.js 15 (App Router, Server Actions), React (Client Components), Supabase, Vitest, Tailwind (semantic design tokens).

---

### Task 0: Ön hazırlık — `updated_at` alanını veri akışına ekle

**Files:**
- Modify: `uygulamalar/web/app/sahip/menuler/[menuId]/duzenle/page.tsx`

`menu_items` tablosunda `updated_at` kolonu zaten var ve `getMenuWithSections`'ın `select('*')` sorgusu onu zaten çekiyor, ama `page.tsx` bunu `MenuEditorClient`'a aktarmıyor. "Son Güncelleme" istatistik kartı için gerekli.

- [ ] **Step 1: `page.tsx`'teki items map'ine `updated_at` ekle**

`uygulamalar/web/app/sahip/menuler/[menuId]/duzenle/page.tsx` içinde, `items={items.map((item) => ({...}))}` bloğunu bul (satır ~104-117) ve `sort_order: item.sort_order,` satırından hemen sonra şunu ekle:

```tsx
            sort_order: item.sort_order,
            updated_at: item.updated_at,
```

- [ ] **Step 2: Typecheck çalıştır**

Run: `cd uygulamalar/web && pnpm run typecheck`
Expected: Şu an `MenuEditorClient`'ın `Item` tipinde `updated_at` olmadığı için hata verecek — bu beklenen, Task 1'de düzeltilecek. Bu adımda sadece `page.tsx` tarafında hata olmadığını doğrula (hata varsa `Item` tipi ile ilgili olmalı, `page.tsx`'in kendisiyle ilgili değil).

- [ ] **Step 3: Commit**

```bash
git add uygulamalar/web/app/sahip/menuler/[menuId]/duzenle/page.tsx
git commit -m "feat(web): menü düzenleyici — updated_at alanını veri akışına ekle (istatistik kartları için)"
```

---

### Task 1: Yardımcı fonksiyonlar + testler

**Files:**
- Create: `uygulamalar/web/app/sahip/menuler/[menuId]/duzenle/menu-duzenleyici-yardimcilari.ts`
- Test: `uygulamalar/web/test/lib/menu-duzenleyici-yardimcilari.test.ts`

Paylaşılan tipler (`Section`, `Item`) ve saf hesaplama fonksiyonları (istatistikler, arama/filtre, sütun sıralama) — hiçbir DB/React bağımlılığı yok, tam TDD.

- [ ] **Step 1: Başarısız testi yaz**

`uygulamalar/web/test/lib/menu-duzenleyici-yardimcilari.test.ts`:

```ts
import { describe, it, expect } from 'vitest';
import {
  formatPrice,
  computeStats,
  filterItems,
  sortItems,
  type Item,
  type Section,
} from '@/app/sahip/menuler/[menuId]/duzenle/menu-duzenleyici-yardimcilari';

const SECTIONS: Section[] = [
  { id: 's1', title: 'Kahvaltı', sort_order: 0 },
  { id: 's2', title: 'İçecekler', sort_order: 1 },
];

const ITEMS: Item[] = [
  {
    id: 'i1', name: 'Serpme Kahvaltı', description: null, image_url: null,
    price_cents: 29500, currency: 'TRY', is_available: true, section_id: 's1',
    sort_order: 0, calories_min: null, portion_size: null, portion_unit: null,
    updated_at: '2026-07-06T09:40:00Z',
  },
  {
    id: 'i2', name: 'Flat White', description: null, image_url: null,
    price_cents: 9500, currency: 'TRY', is_available: false, section_id: 's2',
    sort_order: 0, calories_min: null, portion_size: null, portion_unit: null,
    updated_at: '2026-07-04T16:22:00Z',
  },
  {
    id: 'i3', name: 'Soğuk Kahve', description: null, image_url: null,
    price_cents: 11000, currency: 'TRY', is_available: true, section_id: 's2',
    sort_order: 1, calories_min: null, portion_size: null, portion_unit: null,
    updated_at: '2026-07-08T12:30:00Z',
  },
];

describe('formatPrice', () => {
  it('kuruşu TL string olarak biçimlendirir', () => {
    expect(formatPrice(9500)).toBe('95,00 ₺');
  });
});

describe('computeStats', () => {
  it('kategori/ürün/aktif/pasif sayılarını ve en son güncelleme tarihini hesaplar', () => {
    const stats = computeStats(SECTIONS, ITEMS);
    expect(stats.toplamKategori).toBe(2);
    expect(stats.toplamUrun).toBe(3);
    expect(stats.aktifUrun).toBe(2);
    expect(stats.pasifUrun).toBe(1);
    expect(stats.sonGuncelleme).toBe('2026-07-08T12:30:00Z');
  });

  it('ürün yokken sonGuncelleme null döner', () => {
    const stats = computeStats(SECTIONS, []);
    expect(stats.sonGuncelleme).toBeNull();
  });
});

describe('filterItems', () => {
  it('arama metnine göre ada/açıklamaya göre filtreler (case-insensitive)', () => {
    const result = filterItems(ITEMS, { search: 'kahv', sectionId: null, status: 'all' });
    expect(result.map((i) => i.id).sort()).toEqual(['i1', 'i3']);
  });

  it('kategoriye göre filtreler', () => {
    const result = filterItems(ITEMS, { search: '', sectionId: 's2', status: 'all' });
    expect(result.map((i) => i.id).sort()).toEqual(['i2', 'i3']);
  });

  it('duruma göre filtreler', () => {
    const result = filterItems(ITEMS, { search: '', sectionId: null, status: 'active' });
    expect(result.map((i) => i.id).sort()).toEqual(['i1', 'i3']);
  });

  it('filtreler birlikte AND mantığıyla uygulanır', () => {
    const result = filterItems(ITEMS, { search: '', sectionId: 's2', status: 'passive' });
    expect(result.map((i) => i.id)).toEqual(['i2']);
  });
});

describe('sortItems', () => {
  it('manuel modda sort_order sırasını korur', () => {
    const result = sortItems(ITEMS, 'manual');
    expect(result.map((i) => i.id)).toEqual(['i1', 'i2', 'i3']);
  });

  it('isme göre alfabetik sıralar', () => {
    const result = sortItems(ITEMS, 'name');
    expect(result.map((i) => i.id)).toEqual(['i2', 'i1', 'i3']);
  });

  it('fiyata göre artan sıralar', () => {
    const result = sortItems(ITEMS, 'price');
    expect(result.map((i) => i.id)).toEqual(['i2', 'i3', 'i1']);
  });

  it('son güncellemeye göre en yeni önce sıralar', () => {
    const result = sortItems(ITEMS, 'updated');
    expect(result.map((i) => i.id)).toEqual(['i3', 'i1', 'i2']);
  });
});
```

- [ ] **Step 2: Testin başarısız olduğunu doğrula**

Run: `cd uygulamalar/web && pnpm vitest run test/lib/menu-duzenleyici-yardimcilari.test.ts`
Expected: FAIL — modül bulunamadı hatası (`menu-duzenleyici-yardimcilari` henüz yok).

- [ ] **Step 3: Yardımcı modülü yaz**

`uygulamalar/web/app/sahip/menuler/[menuId]/duzenle/menu-duzenleyici-yardimcilari.ts`:

```ts
export type Section = { id: string; title: string; sort_order: number };

export type Item = {
  id: string;
  name: string;
  description: string | null;
  image_url: string | null;
  price_cents: number;
  currency: string;
  is_available: boolean;
  section_id: string;
  sort_order: number;
  calories_min: number | null;
  portion_size: number | null;
  portion_unit: string | null;
  updated_at: string;
};

export function formatPrice(cents: number): string {
  return (cents / 100).toLocaleString('tr-TR', { minimumFractionDigits: 2 }) + ' ₺';
}

export interface MenuStats {
  toplamKategori: number;
  toplamUrun: number;
  aktifUrun: number;
  pasifUrun: number;
  sonGuncelleme: string | null;
}

export function computeStats(sections: Section[], items: Item[]): MenuStats {
  const aktifUrun = items.filter((i) => i.is_available).length;
  let sonGuncelleme: string | null = null;
  for (const item of items) {
    if (sonGuncelleme === null || item.updated_at > sonGuncelleme) {
      sonGuncelleme = item.updated_at;
    }
  }
  return {
    toplamKategori: sections.length,
    toplamUrun: items.length,
    aktifUrun,
    pasifUrun: items.length - aktifUrun,
    sonGuncelleme,
  };
}

export type StatusFilter = 'all' | 'active' | 'passive';

export interface ItemFilters {
  search: string;
  sectionId: string | null;
  status: StatusFilter;
}

export function filterItems(items: Item[], filters: ItemFilters): Item[] {
  const search = filters.search.trim().toLowerCase();
  return items.filter((item) => {
    if (filters.sectionId && item.section_id !== filters.sectionId) return false;
    if (filters.status === 'active' && !item.is_available) return false;
    if (filters.status === 'passive' && item.is_available) return false;
    if (search) {
      const haystack = `${item.name} ${item.description ?? ''}`.toLowerCase();
      if (!haystack.includes(search)) return false;
    }
    return true;
  });
}

export type SortMode = 'manual' | 'name' | 'price' | 'updated';

export function sortItems(items: Item[], mode: SortMode): Item[] {
  const copy = [...items];
  switch (mode) {
    case 'name':
      return copy.sort((a, b) => a.name.localeCompare(b.name, 'tr'));
    case 'price':
      return copy.sort((a, b) => a.price_cents - b.price_cents);
    case 'updated':
      return copy.sort((a, b) => (a.updated_at < b.updated_at ? 1 : a.updated_at > b.updated_at ? -1 : 0));
    case 'manual':
    default:
      return copy.sort((a, b) => a.sort_order - b.sort_order);
  }
}
```

- [ ] **Step 4: Testin geçtiğini doğrula**

Run: `cd uygulamalar/web && pnpm vitest run test/lib/menu-duzenleyici-yardimcilari.test.ts`
Expected: PASS — 10 test.

- [ ] **Step 5: Commit**

```bash
git add uygulamalar/web/app/sahip/menuler/'[menuId]'/duzenle/menu-duzenleyici-yardimcilari.ts uygulamalar/web/test/lib/menu-duzenleyici-yardimcilari.test.ts
git commit -m "feat(web): menü düzenleyici — saf yardımcı fonksiyonlar (istatistik/filtre/sıralama) + testler"
```

---

### Task 2: Server action — sıralama (`reorderItem`)

**Files:**
- Modify: `uygulamalar/web/app/sahip/menuler/[menuId]/duzenle/menu-islemleri.ts`
- Test: `uygulamalar/web/test/lib/menu-islemleri-reorder.test.ts`

Mevcut `upsertItem` UPDATE'te `sort_order`'ı kabul etmiyor (sadece INSERT'te otomatik atanıyor). Sürükle-bırak için dar kapsamlı, dedike bir action gerekiyor.

`menu-islemleri.ts`'in üst kısmındaki `getOwnedMenuContext` yardımcı fonksiyonunu ve `ActionResult`/`revalidateMenuEditor` tanımlarını oku (dosyanın en üstü) — yeni fonksiyon bunları aynı şekilde kullanacak.

- [ ] **Step 1: `reorderItem` fonksiyonunu ekle**

`uygulamalar/web/app/sahip/menuler/[menuId]/duzenle/menu-islemleri.ts`'nin sonuna ekle (mevcut `deleteItem`'dan hemen sonra):

```ts
export async function reorderItem(
  itemId: string,
  menuId: string,
  newSortOrder: number,
): Promise<ActionResult> {
  const context = await getOwnedMenuContext(menuId);
  if (!context.ok) return { error: context.error };

  const { data: sections } = await (context.supabase as any)
    .from('menu_sections')
    .select('id')
    .eq('menu_id', menuId) as { data: Array<{ id: string }> | null };
  const sectionIds = (sections ?? []).map((section) => section.id);
  if (sectionIds.length === 0) return { error: 'Bölüm bulunamadı' };

  const { error } = await (context.supabase as any)
    .from('menu_items')
    .update({ sort_order: newSortOrder })
    .eq('id', itemId)
    .in('section_id', sectionIds);
  if (error) return { error: error.message };

  revalidateMenuEditor(menuId);
  return null;
}
```

- [ ] **Step 2: Test yaz**

`uygulamalar/web/test/lib/menu-islemleri-reorder.test.ts` — bu dosya server action'ı gerçek Supabase olmadan test edemez (server-only, `createSupabaseServerClient` gerektirir); bu nedenle burada bir INTEGRATION değil, dosyanın export ettiği fonksiyonun var olduğunu ve tip imzasının doğru olduğunu doğrulayan bir derleme-zamanı testi yeterlidir:

```ts
import { describe, it, expect } from 'vitest';
import { reorderItem } from '@/app/sahip/menuler/[menuId]/duzenle/menu-islemleri';

describe('reorderItem', () => {
  it('bir fonksiyon olarak export edilir', () => {
    expect(typeof reorderItem).toBe('function');
  });
});
```

(Gerçek DB davranışı Task 12'deki manuel/dev-server doğrulamasında test edilecek — bu codebase'de server action'lar için genel konvansiyon budur, bkz. mevcut `upsertItem`/`deleteItem` için de ayrı bir DB-entegrasyon testi yok.)

- [ ] **Step 3: Typecheck + test çalıştır**

Run: `cd uygulamalar/web && pnpm run typecheck && pnpm vitest run test/lib/menu-islemleri-reorder.test.ts`
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add uygulamalar/web/app/sahip/menuler/'[menuId]'/duzenle/menu-islemleri.ts uygulamalar/web/test/lib/menu-islemleri-reorder.test.ts
git commit -m "feat(web): menü düzenleyici — reorderItem server action (sürükle-bırak sıralama için)"
```

---

### Task 3: Server actions — toplu işlemler + kopyalama

**Files:**
- Modify: `uygulamalar/web/app/sahip/menuler/[menuId]/duzenle/menu-islemleri.ts`
- Test: `uygulamalar/web/test/lib/menu-islemleri-toplu.test.ts`

Toplu aktif/pasif, toplu kategori değiştirme, toplu (kalıcı) silme, ve tekli ürün kopyalama.

- [ ] **Step 1: Fonksiyonları ekle**

`uygulamalar/web/app/sahip/menuler/[menuId]/duzenle/menu-islemleri.ts`'nin sonuna ekle:

```ts
export async function bulkSetAvailability(
  itemIds: string[],
  menuId: string,
  isAvailable: boolean,
): Promise<ActionResult> {
  if (itemIds.length === 0) return null;
  const context = await getOwnedMenuContext(menuId);
  if (!context.ok) return { error: context.error };

  const { data: sections } = await (context.supabase as any)
    .from('menu_sections')
    .select('id')
    .eq('menu_id', menuId) as { data: Array<{ id: string }> | null };
  const sectionIds = (sections ?? []).map((section) => section.id);
  if (sectionIds.length === 0) return { error: 'Bölüm bulunamadı' };

  const { error } = await (context.supabase as any)
    .from('menu_items')
    .update({ is_available: isAvailable })
    .in('id', itemIds)
    .in('section_id', sectionIds);
  if (error) return { error: error.message };

  revalidateMenuEditor(menuId);
  return null;
}

export async function bulkMoveSection(
  itemIds: string[],
  menuId: string,
  targetSectionId: string,
): Promise<ActionResult> {
  if (itemIds.length === 0) return null;
  const context = await getOwnedMenuContext(menuId);
  if (!context.ok) return { error: context.error };

  const { data: sections } = await (context.supabase as any)
    .from('menu_sections')
    .select('id')
    .eq('menu_id', menuId) as { data: Array<{ id: string }> | null };
  const sectionIds = (sections ?? []).map((section) => section.id);
  if (!sectionIds.includes(targetSectionId)) return { error: 'Hedef bölüm bu menüye ait değil' };

  const { error } = await (context.supabase as any)
    .from('menu_items')
    .update({ section_id: targetSectionId })
    .in('id', itemIds)
    .in('section_id', sectionIds);
  if (error) return { error: error.message };

  revalidateMenuEditor(menuId);
  return null;
}

export async function bulkDeleteItems(
  itemIds: string[],
  menuId: string,
): Promise<ActionResult> {
  if (itemIds.length === 0) return null;
  const context = await getOwnedMenuContext(menuId);
  if (!context.ok) return { error: context.error };

  const { data: sections } = await (context.supabase as any)
    .from('menu_sections')
    .select('id')
    .eq('menu_id', menuId) as { data: Array<{ id: string }> | null };
  const sectionIds = (sections ?? []).map((section) => section.id);
  if (sectionIds.length === 0) return { error: 'Bölüm bulunamadı' };

  const { error } = await (context.supabase as any)
    .from('menu_items')
    .delete()
    .in('id', itemIds)
    .in('section_id', sectionIds);
  if (error) return { error: error.message };

  revalidateMenuEditor(menuId);
  return null;
}

export async function duplicateItem(
  itemId: string,
  menuId: string,
): Promise<{ error: string } | { itemId: string }> {
  const context = await getOwnedMenuContext(menuId);
  if (!context.ok) return { error: context.error };

  const { data: sections } = await (context.supabase as any)
    .from('menu_sections')
    .select('id')
    .eq('menu_id', menuId) as { data: Array<{ id: string }> | null };
  const sectionIds = (sections ?? []).map((section) => section.id);
  if (sectionIds.length === 0) return { error: 'Bölüm bulunamadı' };

  const { data: original, error: fetchErr } = await (context.supabase as any)
    .from('menu_items')
    .select('name, description, image_url, price_cents, currency, is_available, section_id, calories_min, calories_max, portion_size, portion_unit, calorie_source')
    .eq('id', itemId)
    .in('section_id', sectionIds)
    .maybeSingle() as { data: Record<string, unknown> | null; error: { message: string } | null };
  if (fetchErr) return { error: fetchErr.message };
  if (!original) return { error: 'Ürün bulunamadı' };

  const { count } = await (context.supabase as any)
    .from('menu_items')
    .select('id', { count: 'exact', head: true })
    .eq('section_id', original.section_id as string) as { count: number | null };

  const { data: copy, error: insertErr } = await (context.supabase as any)
    .from('menu_items')
    .insert({
      ...original,
      name: `${original.name as string} (Kopya)`,
      business_id: context.businessId,
      sort_order: count ?? 0,
    })
    .select('id')
    .single() as { data: { id: string } | null; error: { message: string } | null };
  if (insertErr) return { error: insertErr.message };

  revalidateMenuEditor(menuId);
  return { itemId: copy?.id ?? '' };
}
```

- [ ] **Step 2: Test yaz**

`uygulamalar/web/test/lib/menu-islemleri-toplu.test.ts`:

```ts
import { describe, it, expect } from 'vitest';
import {
  bulkSetAvailability,
  bulkMoveSection,
  bulkDeleteItems,
  duplicateItem,
} from '@/app/sahip/menuler/[menuId]/duzenle/menu-islemleri';

describe('toplu işlem action ları', () => {
  it('fonksiyonlar export edilir', () => {
    expect(typeof bulkSetAvailability).toBe('function');
    expect(typeof bulkMoveSection).toBe('function');
    expect(typeof bulkDeleteItems).toBe('function');
    expect(typeof duplicateItem).toBe('function');
  });

  it('boş itemIds listesiyle bulkSetAvailability erken döner (DB çağrısı yapmadan)', async () => {
    const result = await bulkSetAvailability([], 'menu-1', true);
    expect(result).toBeNull();
  });

  it('boş itemIds listesiyle bulkMoveSection erken döner', async () => {
    const result = await bulkMoveSection([], 'menu-1', 'section-1');
    expect(result).toBeNull();
  });

  it('boş itemIds listesiyle bulkDeleteItems erken döner', async () => {
    const result = await bulkDeleteItems([], 'menu-1');
    expect(result).toBeNull();
  });
});
```

- [ ] **Step 3: Typecheck + test çalıştır**

Run: `cd uygulamalar/web && pnpm run typecheck && pnpm vitest run test/lib/menu-islemleri-toplu.test.ts`
Expected: PASS — 4 test (boş-liste testleri gerçek DB çağrısı yapmadan `getOwnedMenuContext`'e ulaşmadan erken dönmeli; bu, fonksiyonların en başındaki `if (itemIds.length === 0) return null;` guard'ı sayesinde `createSupabaseServerClient` gibi ortam bağımlılıklarına ihtiyaç duymadan test edilebilir).

- [ ] **Step 4: Commit**

```bash
git add uygulamalar/web/app/sahip/menuler/'[menuId]'/duzenle/menu-islemleri.ts uygulamalar/web/test/lib/menu-islemleri-toplu.test.ts
git commit -m "feat(web): menü düzenleyici — toplu aktif/pasif, kategori taşıma, toplu silme, kopyalama action'ları"
```

---

### Task 4: İstatistik Kartları bileşeni

**Files:**
- Create: `uygulamalar/web/app/sahip/menuler/[menuId]/duzenle/bilesenler/istatistik-kartlari.tsx`

- [ ] **Step 1: Bileşeni yaz**

```tsx
import { MenuStats } from '../menu-duzenleyici-yardimcilari';

function formatTarih(iso: string | null): string {
  if (!iso) return '—';
  return new Date(iso).toLocaleDateString('tr-TR', { day: '2-digit', month: 'short', year: 'numeric' });
}

export function IstatistikKartlari({ stats }: { stats: MenuStats }) {
  const kartlar = [
    { label: 'Toplam Kategori', value: String(stats.toplamKategori), icon: <KategoriIcon /> },
    { label: 'Toplam Ürün', value: String(stats.toplamUrun), icon: <UrunIcon /> },
    { label: 'Aktif Ürün', value: String(stats.aktifUrun), icon: <AktifIcon /> },
    { label: 'Pasif Ürün', value: String(stats.pasifUrun), icon: <PasifIcon /> },
    { label: 'Son Güncelleme', value: formatTarih(stats.sonGuncelleme), icon: <SaatIcon /> },
  ];

  return (
    <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-5">
      {kartlar.map((kart) => (
        <div key={kart.label} className="rounded-2xl border border-border bg-card p-4 shadow-xs">
          <div className="mb-2 flex h-8 w-8 items-center justify-center rounded-lg bg-primary/10 text-primary">
            {kart.icon}
          </div>
          <p className="text-[11px] font-bold uppercase tracking-wide text-muted">{kart.label}</p>
          <p className="mt-0.5 text-lg font-black text-textStrong">{kart.value}</p>
        </div>
      ))}
    </div>
  );
}

function KategoriIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/></svg>;
}
function UrunIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M20 7L12 3 4 7v10l8 4 8-4V7z"/><path d="M4 7l8 4 8-4M12 11v10"/></svg>;
}
function AktifIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M20 6L9 17l-5-5"/></svg>;
}
function PasifIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><circle cx="12" cy="12" r="10"/><line x1="8" y1="12" x2="16" y2="12"/></svg>;
}
function SaatIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>;
}
```

- [ ] **Step 2: Typecheck**

Run: `cd uygulamalar/web && pnpm run typecheck`
Expected: PASS (bu bileşen henüz hiçbir yerden import edilmiyor, sadece kendi içinde derlenebilir olmalı).

- [ ] **Step 3: Commit**

```bash
git add uygulamalar/web/app/sahip/menuler/'[menuId]'/duzenle/bilesenler/istatistik-kartlari.tsx
git commit -m "feat(web): menü düzenleyici — istatistik kartları bileşeni"
```

---

### Task 5: Kategori Sekmeleri bileşeni

**Files:**
- Create: `uygulamalar/web/app/sahip/menuler/[menuId]/duzenle/bilesenler/kategori-sekmeleri.tsx`

- [ ] **Step 1: Bileşeni yaz**

```tsx
import { Section } from '../menu-duzenleyici-yardimcilari';

export function KategoriSekmeleri({
  sections,
  itemCounts,
  activeSectionId,
  onChange,
}: {
  sections: Section[];
  itemCounts: Record<string, number>;
  activeSectionId: string | null;
  onChange: (sectionId: string | null) => void;
}) {
  const toplam = Object.values(itemCounts).reduce((sum, n) => sum + n, 0);

  return (
    <div className="flex flex-wrap gap-1 border-b border-border">
      <SekmeButonu
        label="Tümü"
        count={toplam}
        active={activeSectionId === null}
        onClick={() => onChange(null)}
      />
      {sections.map((section) => (
        <SekmeButonu
          key={section.id}
          label={section.title}
          count={itemCounts[section.id] ?? 0}
          active={activeSectionId === section.id}
          onClick={() => onChange(section.id)}
        />
      ))}
    </div>
  );
}

function SekmeButonu({
  label,
  count,
  active,
  onClick,
}: {
  label: string;
  count: number;
  active: boolean;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`shrink-0 border-b-2 px-3 py-2 text-sm font-bold transition-colors cursor-pointer ${
        active
          ? 'border-primary text-primary'
          : 'border-transparent text-muted hover:text-textStrong'
      }`}
    >
      {label} <span className="text-xs font-semibold text-muted">({count})</span>
    </button>
  );
}
```

- [ ] **Step 2: Typecheck**

Run: `cd uygulamalar/web && pnpm run typecheck`
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add uygulamalar/web/app/sahip/menuler/'[menuId]'/duzenle/bilesenler/kategori-sekmeleri.tsx
git commit -m "feat(web): menü düzenleyici — kategori sekmeleri bileşeni"
```

---

### Task 6: Araç Çubuğu bileşeni

**Files:**
- Create: `uygulamalar/web/app/sahip/menuler/[menuId]/duzenle/bilesenler/arac-cubugu.tsx`

Arama, kategori/durum filtresi, sıralama, ve seçili satır varsa Toplu İşlemler menüsü. Tüm state parent'ta (orchestrator) tutulur, bu bileşen saf kontrollerdir.

- [ ] **Step 1: Bileşeni yaz**

```tsx
'use client';

import { useState } from 'react';
import { Section, StatusFilter, SortMode } from '../menu-duzenleyici-yardimcilari';

export function AracCubugu({
  search,
  onSearchChange,
  sections,
  sectionId,
  onSectionChange,
  status,
  onStatusChange,
  sortMode,
  onSortModeChange,
  selectedCount,
  onBulkSetAvailability,
  onBulkMoveSection,
  onBulkDelete,
}: {
  search: string;
  onSearchChange: (value: string) => void;
  sections: Section[];
  sectionId: string | null;
  onSectionChange: (value: string | null) => void;
  status: StatusFilter;
  onStatusChange: (value: StatusFilter) => void;
  sortMode: SortMode;
  onSortModeChange: (value: SortMode) => void;
  selectedCount: number;
  onBulkSetAvailability: (isAvailable: boolean) => void;
  onBulkMoveSection: (sectionId: string) => void;
  onBulkDelete: () => void;
}) {
  const [bulkMenuOpen, setBulkMenuOpen] = useState(false);

  return (
    <div className="flex flex-wrap items-center gap-2">
      <input
        value={search}
        onChange={(e) => onSearchChange(e.target.value)}
        placeholder="Ürün ara..."
        className="min-w-[200px] flex-1 rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30"
      />
      <select
        value={sectionId ?? ''}
        onChange={(e) => onSectionChange(e.target.value || null)}
        className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30"
      >
        <option value="">Tüm Kategoriler</option>
        {sections.map((s) => (
          <option key={s.id} value={s.id}>{s.title}</option>
        ))}
      </select>
      <select
        value={status}
        onChange={(e) => onStatusChange(e.target.value as StatusFilter)}
        className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30"
      >
        <option value="all">Tümü</option>
        <option value="active">Aktif</option>
        <option value="passive">Pasif</option>
      </select>
      <select
        value={sortMode}
        onChange={(e) => onSortModeChange(e.target.value as SortMode)}
        className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30"
      >
        <option value="manual">Manuel Sıralama</option>
        <option value="name">İsme Göre</option>
        <option value="price">Fiyata Göre</option>
        <option value="updated">Son Güncellemeye Göre</option>
      </select>

      <div className="relative">
        <button
          type="button"
          disabled={selectedCount === 0}
          onClick={() => setBulkMenuOpen((v) => !v)}
          className="rounded-xl border border-border bg-card px-3 py-2 text-sm font-bold text-textStrong disabled:cursor-not-allowed disabled:opacity-50 hover:bg-bg cursor-pointer"
        >
          Toplu İşlemler {selectedCount > 0 && `(${selectedCount})`}
        </button>
        {bulkMenuOpen && selectedCount > 0 && (
          <div className="absolute right-0 top-full z-10 mt-1 w-56 rounded-xl border border-border bg-card p-1 shadow-yd2">
            <button
              type="button"
              onClick={() => { onBulkSetAvailability(true); setBulkMenuOpen(false); }}
              className="block w-full rounded-lg px-3 py-2 text-left text-sm font-semibold text-textStrong hover:bg-bg cursor-pointer"
            >
              Aktif Yap
            </button>
            <button
              type="button"
              onClick={() => { onBulkSetAvailability(false); setBulkMenuOpen(false); }}
              className="block w-full rounded-lg px-3 py-2 text-left text-sm font-semibold text-textStrong hover:bg-bg cursor-pointer"
            >
              Pasif Yap
            </button>
            {sections.length > 0 && (
              <div className="border-t border-border px-3 py-2">
                <p className="mb-1 text-xs font-bold text-muted">Kategoriye Taşı</p>
                <select
                  onChange={(e) => {
                    if (e.target.value) { onBulkMoveSection(e.target.value); setBulkMenuOpen(false); }
                  }}
                  defaultValue=""
                  className="w-full rounded-lg border border-border bg-bg px-2 py-1.5 text-xs text-textStrong"
                >
                  <option value="" disabled>Kategori seç…</option>
                  {sections.map((s) => (
                    <option key={s.id} value={s.id}>{s.title}</option>
                  ))}
                </select>
              </div>
            )}
            <button
              type="button"
              onClick={() => {
                if (confirm(`${selectedCount} ürünü kalıcı olarak silmek istediğinize emin misiniz? Bu işlem geri alınamaz.`)) {
                  onBulkDelete();
                }
                setBulkMenuOpen(false);
              }}
              className="block w-full rounded-lg px-3 py-2 text-left text-sm font-semibold text-red-600 hover:bg-red-50 cursor-pointer"
            >
              Kalıcı Olarak Sil
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
```

- [ ] **Step 2: Typecheck**

Run: `cd uygulamalar/web && pnpm run typecheck`
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add uygulamalar/web/app/sahip/menuler/'[menuId]'/duzenle/bilesenler/arac-cubugu.tsx
git commit -m "feat(web): menü düzenleyici — araç çubuğu bileşeni (arama/filtre/sıralama/toplu işlemler)"
```

---

### Task 7: Ürün Tablosu bileşeni (sürükle-bırak dahil)

**Files:**
- Create: `uygulamalar/web/app/sahip/menuler/[menuId]/duzenle/bilesenler/urun-tablosu.tsx`

Native HTML5 `draggable`/`onDragStart`/`onDragOver`/`onDrop` ile manuel sıralama. Sadece `sortMode === 'manual'` iken sürüklenebilir (Task 6'daki sıralama dropdown'ıyla tutarlı — `AracCubugu`'nun "Manuel Sıralama" seçeneği).

- [ ] **Step 1: Bileşeni yaz**

```tsx
'use client';

import Image from 'next/image';
import { useState } from 'react';
import { Item, Section, formatPrice, SortMode } from '../menu-duzenleyici-yardimcilari';

export function UrunTablosu({
  items,
  sections,
  sortMode,
  selectedIds,
  onToggleSelect,
  onToggleSelectAll,
  onReorder,
  onEdit,
  onDuplicate,
  onDelete,
}: {
  items: Item[];
  sections: Section[];
  sortMode: SortMode;
  selectedIds: Set<string>;
  onToggleSelect: (itemId: string) => void;
  onToggleSelectAll: () => void;
  onReorder: (itemId: string, newSortOrder: number) => void;
  onEdit: (itemId: string) => void;
  onDuplicate: (itemId: string) => void;
  onDelete: (itemId: string) => void;
}) {
  const [draggedId, setDraggedId] = useState<string | null>(null);
  const sectionTitle = (sectionId: string) => sections.find((s) => s.id === sectionId)?.title ?? '—';
  const allSelected = items.length > 0 && items.every((i) => selectedIds.has(i.id));
  const manual = sortMode === 'manual';

  function handleDrop(targetItem: Item) {
    if (!draggedId || draggedId === targetItem.id) { setDraggedId(null); return; }
    onReorder(draggedId, targetItem.sort_order);
    setDraggedId(null);
  }

  if (items.length === 0) {
    return (
      <div className="flex flex-col items-center gap-2 rounded-2xl border border-dashed border-border py-12 text-center">
        <p className="text-sm font-bold text-textStrong">Bu filtrelerle eşleşen ürün yok</p>
        <p className="text-xs text-muted">Filtreleri temizleyin veya yeni bir ürün ekleyin.</p>
      </div>
    );
  }

  return (
    <div className="overflow-x-auto rounded-2xl border border-border">
      <table className="w-full min-w-[720px] border-collapse text-sm">
        <thead>
          <tr className="border-b border-border bg-bg text-left text-xs font-bold uppercase tracking-wide text-muted">
            <th className="w-8 px-3 py-2"></th>
            <th className="w-8 px-3 py-2">
              <input type="checkbox" checked={allSelected} onChange={onToggleSelectAll} className="rounded" aria-label="Tümünü seç" />
            </th>
            <th className="w-14 px-3 py-2">Görsel</th>
            <th className="px-3 py-2">Ürün Adı</th>
            <th className="px-3 py-2">Kategori</th>
            <th className="px-3 py-2">Fiyat</th>
            <th className="px-3 py-2">Durum</th>
            <th className="px-3 py-2">Son Güncelleme</th>
            <th className="px-3 py-2">İşlemler</th>
          </tr>
        </thead>
        <tbody>
          {items.map((item) => (
            <tr
              key={item.id}
              draggable={manual}
              onDragStart={() => setDraggedId(item.id)}
              onDragOver={(e) => manual && e.preventDefault()}
              onDrop={() => manual && handleDrop(item)}
              className={`border-b border-border last:border-0 hover:bg-bg/60 ${draggedId === item.id ? 'opacity-40' : ''}`}
            >
              <td className="px-3 py-2 text-muted">
                {manual ? <span className="cursor-grab select-none" title="Sürükleyerek sırala">⠿</span> : null}
              </td>
              <td className="px-3 py-2">
                <input
                  type="checkbox"
                  checked={selectedIds.has(item.id)}
                  onChange={() => onToggleSelect(item.id)}
                  className="rounded"
                  aria-label={`${item.name} seç`}
                />
              </td>
              <td className="px-3 py-2">
                {item.image_url ? (
                  <Image src={item.image_url} alt={item.name} width={40} height={40} className="h-10 w-10 rounded-lg object-cover" unoptimized />
                ) : (
                  <div className="flex h-10 w-10 items-center justify-center rounded-lg border border-dashed border-border bg-bg text-[9px] font-bold text-muted">Yok</div>
                )}
              </td>
              <td className="px-3 py-2">
                <p className="font-bold text-textStrong">{item.name}</p>
                {item.description && <p className="max-w-[220px] truncate text-xs text-muted">{item.description}</p>}
              </td>
              <td className="px-3 py-2">
                <span className="rounded-full border border-border bg-bg px-2 py-0.5 text-[11px] font-bold text-muted">
                  {sectionTitle(item.section_id)}
                </span>
              </td>
              <td className="px-3 py-2 font-bold text-textStrong">{formatPrice(item.price_cents)}</td>
              <td className="px-3 py-2">
                <span className={`rounded-full px-2 py-0.5 text-[11px] font-extrabold ${item.is_available ? 'bg-green-50 text-green-700' : 'bg-zinc-100 text-zinc-500'}`}>
                  {item.is_available ? 'Aktif' : 'Pasif'}
                </span>
              </td>
              <td className="px-3 py-2 text-xs text-muted">
                {new Date(item.updated_at).toLocaleDateString('tr-TR', { day: '2-digit', month: 'short', year: 'numeric' })}
              </td>
              <td className="px-3 py-2">
                <div className="flex items-center gap-1">
                  <button type="button" onClick={() => onEdit(item.id)} title="Düzenle" className="rounded-lg border border-border p-1.5 text-muted hover:bg-bg cursor-pointer">
                    <EditIcon />
                  </button>
                  <button type="button" onClick={() => onDuplicate(item.id)} title="Kopyala" className="rounded-lg border border-border p-1.5 text-muted hover:bg-bg cursor-pointer">
                    <CopyIcon />
                  </button>
                  <button
                    type="button"
                    onClick={() => { if (confirm(`"${item.name}" ürününü kalıcı olarak sil?`)) onDelete(item.id); }}
                    title="Sil"
                    className="rounded-lg border border-red-200 p-1.5 text-red-600 hover:bg-red-50 cursor-pointer"
                  >
                    <TrashIcon />
                  </button>
                </div>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function EditIcon() {
  return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>;
}
function CopyIcon() {
  return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>;
}
function TrashIcon() {
  return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/><path d="M10 11v6M14 11v6"/></svg>;
}
```

- [ ] **Step 2: Typecheck**

Run: `cd uygulamalar/web && pnpm run typecheck`
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add uygulamalar/web/app/sahip/menuler/'[menuId]'/duzenle/bilesenler/urun-tablosu.tsx
git commit -m "feat(web): menü düzenleyici — sürükle-bırak sıralamalı ürün tablosu bileşeni"
```

---

### Task 8: Ürün Paneli bileşeni (mevcut ItemForm'un yan panele taşınması)

**Files:**
- Create: `uygulamalar/web/app/sahip/menuler/[menuId]/duzenle/bilesenler/urun-paneli.tsx`

Mevcut `menu-duzenleyici-istemcisi.tsx` içindeki `Input`, `ImageUrlField`, `ItemForm` fonksiyonları (satır 55-522) buraya taşınıyor, form içeriği DEĞİŞMİYOR — sadece bir slide-over panel konteynerine sarılıyor.

- [ ] **Step 1: Bileşeni yaz**

`uygulamalar/web/app/sahip/menuler/[menuId]/duzenle/bilesenler/urun-paneli.tsx` — mevcut dosyadan `ALLERGEN_LIST` sabiti ve `Input`/`ImageUrlField`/`ItemForm` fonksiyonlarını (bu plan dokümanının başındaki "Read before starting" bölümünde tam içerikleri okunmuş olan, satır 18-522 arası) birebir aynı mantıkla, sadece dış sarmalayıcı ekleyerek buraya taşı:

```tsx
'use client';

import Image from 'next/image';
import { useRef, useState, useTransition } from 'react';
import {
  upsertItem,
  upsertItemAllergens,
  upsertItemIngredients,
} from '../menu-islemleri';
import { aiIleAlerjenKaloriDoldur, aiIleGorselUret } from '../ai-doldurma-islemleri';

const ALLERGEN_LIST = [
  { code: 'gluten',         labelTr: 'Gluten'                      },
  { code: 'crustaceans',    labelTr: 'Kabuklu Deniz Ürünleri'      },
  { code: 'egg',            labelTr: 'Yumurta'                     },
  { code: 'fish',           labelTr: 'Balık'                       },
  { code: 'peanuts',        labelTr: 'Yer Fıstığı'                },
  { code: 'soy',            labelTr: 'Soya'                        },
  { code: 'milk',           labelTr: 'Süt'                         },
  { code: 'treenuts',       labelTr: 'Sert Kabuklu Yemişler'      },
  { code: 'celery',         labelTr: 'Kereviz'                     },
  { code: 'mustard',        labelTr: 'Hardal'                      },
  { code: 'sesame',         labelTr: 'Susam'                       },
  { code: 'sulfur_dioxide', labelTr: 'Kükürt Dioksit / Sülfitler'  },
  { code: 'lupin',          labelTr: 'Acı Bakla'                   },
  { code: 'molluscs',       labelTr: 'Yumuşakçalar'                },
] as const;

function Input({
  label, name, defaultValue = '', required = false, type = 'text', placeholder = '',
}: {
  label: string; name: string; defaultValue?: string; required?: boolean; type?: string; placeholder?: string;
}) {
  return (
    <div className="flex flex-col gap-1">
      <label className="text-xs font-bold text-muted">{label}</label>
      <input
        name={name} type={type} defaultValue={defaultValue} required={required} placeholder={placeholder}
        className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30"
      />
    </div>
  );
}

function ImageUrlField({
  businessId, label, initialUrl = null, itemNameRef,
}: {
  businessId: string; label: string; initialUrl?: string | null; itemNameRef: React.RefObject<HTMLFormElement | null>;
}) {
  const [url, setUrl] = useState(initialUrl ?? '');
  const [uploading, setUploading] = useState(false);
  const [uploadError, setUploadError] = useState<string | null>(null);
  const [aiGenerating, setAiGenerating] = useState(false);
  const isBusy = uploading || aiGenerating;

  async function upload(file: File | null) {
    if (!file || aiGenerating) return;
    setUploading(true);
    setUploadError(null);
    try {
      const formData = new FormData();
      formData.set('businessId', businessId);
      formData.set('type', 'item');
      formData.set('file', file);
      const response = await fetch('/sunucu/medya/yukleme', { method: 'POST', body: formData });
      const payload = (await response.json().catch(() => null)) as { data?: { url?: string } } | null;
      if (!response.ok || !payload?.data?.url) throw new Error('upload_failed');
      setUrl(payload.data.url);
    } catch {
      setUploadError('Görsel yüklenemedi.');
    } finally {
      setUploading(false);
    }
  }

  async function generateWithAi() {
    if (uploading) return;
    const nameInput = itemNameRef.current?.elements.namedItem('name') as HTMLInputElement | null;
    const name = nameInput?.value?.trim();
    if (!name) { setUploadError('Görsel oluşturmadan önce ürün adını girin.'); return; }
    setAiGenerating(true);
    setUploadError(null);
    try {
      const result = await aiIleGorselUret(businessId, name);
      if ('error' in result) { setUploadError(result.error); return; }
      setUrl(result.imageUrl);
    } catch {
      setUploadError('Görsel oluşturma başarısız oldu, tekrar deneyin.');
    } finally {
      setAiGenerating(false);
    }
  }

  return (
    <div className="grid gap-3 rounded-xl border border-border bg-bg p-3 sm:grid-cols-[96px_1fr]">
      <div className="relative flex h-24 w-24 items-center justify-center overflow-hidden rounded-xl border border-border bg-card text-[11px] font-extrabold text-muted">
        {url ? <Image src={url} alt="" fill sizes="96px" className="object-cover" unoptimized /> : 'Görsel yok'}
      </div>
      <div className="flex min-w-0 flex-col gap-2">
        <input type="hidden" name="imageUrl" value={url} />
        <label className="text-xs font-bold text-muted">{label}</label>
        <input
          type="url" value={url} onChange={(event) => setUrl(event.target.value)} placeholder="https://..."
          className="rounded-xl border border-border bg-card px-3 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30"
        />
        <div className="flex flex-wrap items-center gap-2">
          <button type="button" onClick={generateWithAi} disabled={isBusy} className="inline-flex min-h-10 items-center rounded-xl border border-primary/30 bg-primary/5 px-3 py-2 text-xs font-extrabold text-primary hover:bg-primary/10 disabled:opacity-60 cursor-pointer">
            {aiGenerating ? 'AI çalışıyor...' : '✨ AI ile görsel oluştur'}
          </button>
          <label className="inline-flex min-h-10 cursor-pointer items-center rounded-xl border border-border bg-card px-3 py-2 text-xs font-extrabold text-textStrong hover:bg-white">
            {uploading ? 'Yükleniyor...' : 'Bilgisayardan seç'}
            <input type="file" accept="image/png,image/jpeg,image/webp" disabled={isBusy} onChange={(event) => upload(event.target.files?.[0] ?? null)} className="sr-only" />
          </label>
          {url && (
            <button type="button" onClick={() => setUrl('')} disabled={isBusy} className="min-h-10 rounded-xl border border-border px-3 py-2 text-xs font-extrabold text-muted hover:bg-card disabled:opacity-60">
              Kaldır
            </button>
          )}
          {uploadError && <span className="text-xs font-bold text-red-600">{uploadError}</span>}
        </div>
      </div>
    </div>
  );
}

export function UrunPaneli({
  menuId, sectionId, businessId, itemId, initialValues, initialAllergens, initialIngredients, submitLabel, onSuccess, onCancel,
}: {
  menuId: string;
  sectionId: string;
  businessId: string;
  itemId?: string;
  initialValues?: {
    name: string; description: string | null; image_url: string | null; price_cents: number;
    is_available: boolean; calories_min: number | null; portion_size: number | null; portion_unit: string | null;
  };
  initialAllergens: string[];
  initialIngredients: string[];
  submitLabel: string;
  onSuccess: () => void;
  onCancel: () => void;
}) {
  const [isPending, startTransition] = useTransition();
  const [formError, setFormError] = useState<string | null>(null);
  const [selectedAllergens, setSelectedAllergens] = useState<Set<string>>(new Set(initialAllergens));
  const [ingredients, setIngredients] = useState<string[]>(initialIngredients);
  const [ingredientInput, setIngredientInput] = useState('');
  const [aiLoading, setAiLoading] = useState(false);
  const [calorieValue, setCalorieValue] = useState(initialValues?.calories_min ?? '');
  const formRef = useRef<HTMLFormElement>(null);

  async function aiIleDoldur() {
    const nameInput = formRef.current?.elements.namedItem('name') as HTMLInputElement | null;
    const descInput = formRef.current?.elements.namedItem('description') as HTMLInputElement | null;
    const name = nameInput?.value?.trim();
    if (!name) { setFormError('AI doldurmadan önce ürün adını girin.'); return; }
    setAiLoading(true);
    setFormError(null);
    try {
      const result = await aiIleAlerjenKaloriDoldur(businessId, name, descInput?.value ?? '');
      if ('error' in result) { setFormError(result.error); return; }
      setSelectedAllergens(new Set(result.allergens));
      if (result.calorieMin !== null) setCalorieValue(String(result.calorieMin));
    } catch {
      setFormError('AI çağrısı başarısız oldu, tekrar deneyin.');
    } finally {
      setAiLoading(false);
    }
  }

  function toggleAllergen(code: string) {
    setSelectedAllergens((prev) => {
      const next = new Set(prev);
      if (next.has(code)) next.delete(code); else next.add(code);
      return next;
    });
  }

  function addIngredient() {
    const trimmed = ingredientInput.trim();
    if (trimmed && !ingredients.includes(trimmed)) setIngredients((prev) => [...prev, trimmed]);
    setIngredientInput('');
  }

  function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const fd = new FormData(e.currentTarget);
    fd.append('menuId', menuId);
    fd.append('sectionId', sectionId);
    if (itemId) fd.append('itemId', itemId);
    setFormError(null);
    startTransition(async () => {
      const result = await upsertItem(fd);
      if ('error' in result) { setFormError(result.error); return; }
      const resolvedId = result.itemId;
      if (resolvedId) {
        const allergenResult = await upsertItemAllergens(resolvedId, menuId, [...selectedAllergens]);
        if (allergenResult?.error) { setFormError(allergenResult.error); return; }
        const ingredientResult = await upsertItemIngredients(resolvedId, menuId, ingredients);
        if (ingredientResult?.error) { setFormError(ingredientResult.error); return; }
      }
      onSuccess();
    });
  }

  return (
    <div className="fixed inset-0 z-50 flex justify-end">
      <div className="absolute inset-0 bg-black/30" onClick={onCancel} />
      <div className="relative z-10 h-full w-full max-w-md overflow-y-auto bg-card shadow-2xl">
        <div className="sticky top-0 flex items-center justify-between border-b border-border bg-card px-5 py-4">
          <h2 className="text-sm font-black text-textStrong">{itemId ? 'Ürünü Düzenle' : 'Yeni Ürün'}</h2>
          <button type="button" onClick={onCancel} className="rounded-lg p-1 text-muted hover:bg-bg cursor-pointer" aria-label="Kapat">✕</button>
        </div>
        <form ref={formRef} className="flex flex-col gap-3 p-5" onSubmit={handleSubmit}>
          <div className="grid grid-cols-2 gap-3">
            <Input label="Ürün Adı" name="name" defaultValue={initialValues?.name ?? ''} required placeholder="Ürün adı" />
            <Input label="Fiyat (₺)" name="price" type="number" defaultValue={initialValues ? String(initialValues.price_cents / 100) : ''} required placeholder="0.00" />
          </div>
          <Input label="Açıklama (opsiyonel)" name="description" defaultValue={initialValues?.description ?? ''} placeholder="Kısa açıklama" />
          <ImageUrlField businessId={businessId} label="Ürün görseli" initialUrl={initialValues?.image_url ?? null} itemNameRef={formRef} />
          <label className="flex items-center gap-2 text-sm text-textStrong cursor-pointer">
            <input type="checkbox" name="is_available" defaultChecked={initialValues?.is_available ?? true} className="rounded" />
            Satışta
          </label>

          <div className="flex flex-col gap-3 rounded-2xl border border-border bg-bg p-3">
            <p className="text-xs font-bold text-muted">Şeffaf Menü Bilgileri (İsteğe Bağlı)</p>
            <div className="flex flex-col gap-1">
              <label className="text-xs font-bold text-muted">Enerji Değeri (kcal)</label>
              <input name="calories" type="number" value={calorieValue} onChange={(e) => setCalorieValue(e.target.value)} min="0" max="9999" placeholder="örn: 450" className="rounded-xl border border-border bg-card px-3 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30" />
            </div>
            <div className="grid grid-cols-2 gap-2">
              <div className="flex flex-col gap-1">
                <label className="text-xs font-bold text-muted">Porsiyon Miktarı</label>
                <input name="portion_size" type="number" defaultValue={initialValues?.portion_size ?? ''} min="0" placeholder="örn: 350" className="rounded-xl border border-border bg-card px-3 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30" />
              </div>
              <div className="flex flex-col gap-1">
                <label className="text-xs font-bold text-muted">Birim</label>
                <select name="portion_unit" defaultValue={initialValues?.portion_unit ?? ''} className="rounded-xl border border-border bg-card px-3 py-2 text-sm text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30">
                  <option value="">Birim</option>
                  <option value="g">g</option>
                  <option value="ml">ml</option>
                  <option value="adet">adet</option>
                  <option value="dilim">dilim</option>
                </select>
              </div>
            </div>
            <div className="flex flex-col gap-2">
              <p className="text-xs font-bold text-muted">Malzemeler</p>
              <div className="flex gap-2">
                <input
                  type="text" value={ingredientInput} onChange={(e) => setIngredientInput(e.target.value)}
                  onKeyDown={(e) => { if (e.key === 'Enter') { e.preventDefault(); addIngredient(); } }}
                  placeholder="örn: domates"
                  className="flex-1 rounded-xl border border-border bg-card px-3 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30"
                />
                <button type="button" onClick={addIngredient} className="rounded-xl border border-border bg-card px-3 py-2 text-xs font-bold text-textStrong hover:bg-bg cursor-pointer">Ekle</button>
              </div>
              {ingredients.length > 0 && (
                <div className="flex flex-wrap gap-1.5">
                  {ingredients.map((ing, i) => (
                    <span key={i} className="flex items-center gap-1 rounded-full border border-border bg-card px-2.5 py-1 text-xs font-semibold text-textStrong">
                      {ing}
                      <button type="button" onClick={() => setIngredients((prev) => prev.filter((_, j) => j !== i))} className="ml-0.5 text-muted hover:text-textStrong cursor-pointer leading-none" aria-label={`${ing} malzemesini kaldır`}>×</button>
                    </span>
                  ))}
                </div>
              )}
            </div>
          </div>

          <button type="button" onClick={aiIleDoldur} disabled={aiLoading} className="self-start rounded-xl border border-primary/30 bg-primary/5 px-3 py-2 text-xs font-bold text-primary hover:bg-primary/10 disabled:opacity-60 cursor-pointer">
            {aiLoading ? 'AI çalışıyor...' : '✨ AI ile alerjen ve kaloriyi doldur'}
          </button>

          <div className="flex flex-col gap-2">
            <p className="text-xs font-bold text-muted">Alerjenler (Tarım Bakanlığı zorunlu)</p>
            <div className="grid grid-cols-2 gap-1.5">
              {ALLERGEN_LIST.map(({ code, labelTr }) => {
                const active = selectedAllergens.has(code);
                return (
                  <button key={code} type="button" onClick={() => toggleAllergen(code)} className={`flex items-center gap-2 rounded-xl border px-3 py-2 text-xs font-bold text-left cursor-pointer transition-colors ${active ? 'border-primary bg-primary/10 text-textStrong' : 'border-border bg-card text-muted hover:bg-bg'}`}>
                    {/* eslint-disable-next-line @next/next/no-img-element */}
                    <img src={`/allergens/allergen_${code}.svg`} alt="" width={16} height={16} className="shrink-0" />
                    <span>{labelTr}</span>
                  </button>
                );
              })}
            </div>
          </div>

          {formError && <p className="text-xs font-bold text-red-600">{formError}</p>}

          <div className="sticky bottom-0 flex gap-2 border-t border-border bg-card py-3">
            <button type="submit" disabled={isPending} className="rounded-xl bg-primary px-3 py-2 text-xs font-bold text-white disabled:opacity-60 cursor-pointer">
              {isPending ? 'Kaydediliyor...' : submitLabel}
            </button>
            <button type="button" onClick={onCancel} className="rounded-xl border border-border px-3 py-2 text-xs font-bold text-textStrong cursor-pointer">İptal</button>
          </div>
        </form>
      </div>
    </div>
  );
}
```

- [ ] **Step 2: Typecheck**

Run: `cd uygulamalar/web && pnpm run typecheck`
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add uygulamalar/web/app/sahip/menuler/'[menuId]'/duzenle/bilesenler/urun-paneli.tsx
git commit -m "feat(web): menü düzenleyici — mevcut ürün formu yan panel (slide-over) konteynerine taşındı"
```

---

### Task 9: Kategori Yönetimi widget'ı

**Files:**
- Create: `uygulamalar/web/app/sahip/menuler/[menuId]/duzenle/bilesenler/kategori-widgeti.tsx`

- [ ] **Step 1: Bileşeni yaz**

```tsx
'use client';

import { useState, useTransition } from 'react';
import Link from 'next/link';
import { Section } from '../menu-duzenleyici-yardimcilari';
import { createSection, updateSection, deleteSection } from '../menu-islemleri';

export function KategoriWidgeti({
  menuId,
  sections,
  itemCounts,
}: {
  menuId: string;
  sections: Section[];
  itemCounts: Record<string, number>;
}) {
  const [isPending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [showNew, setShowNew] = useState(false);

  function run(action: () => Promise<{ error: string } | null>) {
    setError(null);
    startTransition(async () => {
      const result = await action();
      if (result?.error) setError(result.error);
    });
  }

  return (
    <div className="rounded-2xl border border-border bg-card p-4">
      <h3 className="mb-3 text-sm font-black text-textStrong">Kategori Yönetimi</h3>
      {error && <p className="mb-2 text-xs font-bold text-red-600">{error}</p>}
      <div className="flex flex-col gap-1.5">
        {sections.map((section) => (
          <div key={section.id} className="flex items-center justify-between gap-2 rounded-xl border border-border px-3 py-2">
            {editingId === section.id ? (
              <form
                className="flex flex-1 items-center gap-1.5"
                onSubmit={(e) => {
                  e.preventDefault();
                  const fd = new FormData(e.currentTarget);
                  run(() => updateSection(section.id, menuId, String(fd.get('title') ?? '')));
                  setEditingId(null);
                }}
              >
                <input name="title" defaultValue={section.title} required autoFocus className="min-w-0 flex-1 rounded-lg border border-border bg-bg px-2 py-1 text-xs text-textStrong" />
                <button type="submit" className="rounded-lg bg-primary px-2 py-1 text-[11px] font-bold text-white cursor-pointer">Kaydet</button>
                <button type="button" onClick={() => setEditingId(null)} className="rounded-lg border border-border px-2 py-1 text-[11px] font-bold text-textStrong cursor-pointer">İptal</button>
              </form>
            ) : (
              <>
                <span className="truncate text-sm font-semibold text-textStrong">{section.title}</span>
                <div className="flex shrink-0 items-center gap-2">
                  <span className="text-xs font-bold text-muted">{itemCounts[section.id] ?? 0} ürün</span>
                  <button type="button" onClick={() => setEditingId(section.id)} className="text-xs font-bold text-primary hover:underline cursor-pointer">Düzenle</button>
                  <button
                    type="button"
                    onClick={() => { if (confirm(`"${section.title}" bölümünü sil?`)) run(() => deleteSection(section.id, menuId)); }}
                    className="text-xs font-bold text-red-600 hover:underline cursor-pointer"
                  >
                    Sil
                  </button>
                </div>
              </>
            )}
          </div>
        ))}
      </div>

      {showNew ? (
        <form
          className="mt-2 flex items-center gap-1.5"
          onSubmit={(e) => {
            e.preventDefault();
            const fd = new FormData(e.currentTarget);
            run(() => createSection(menuId, String(fd.get('title') ?? ''), sections.length));
            setShowNew(false);
          }}
        >
          <input name="title" required autoFocus placeholder="Kategori adı" className="min-w-0 flex-1 rounded-lg border border-border bg-bg px-2 py-1 text-xs text-textStrong" />
          <button type="submit" disabled={isPending} className="rounded-lg bg-primary px-2 py-1 text-[11px] font-bold text-white disabled:opacity-60 cursor-pointer">Ekle</button>
          <button type="button" onClick={() => setShowNew(false)} className="rounded-lg border border-border px-2 py-1 text-[11px] font-bold text-textStrong cursor-pointer">İptal</button>
        </form>
      ) : (
        <button type="button" onClick={() => setShowNew(true)} className="mt-2 text-xs font-bold text-primary hover:underline cursor-pointer">
          + Kategori Ekle
        </button>
      )}

      <Link href={`/sahip/menuler/${menuId}/kategoriler`} className="mt-3 block rounded-xl border border-border px-3 py-2 text-center text-xs font-bold text-textStrong hover:bg-bg">
        Tüm Kategorileri Yönet
      </Link>
    </div>
  );
}
```

- [ ] **Step 2: Typecheck**

Run: `cd uygulamalar/web && pnpm run typecheck`
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add uygulamalar/web/app/sahip/menuler/'[menuId]'/duzenle/bilesenler/kategori-widgeti.tsx
git commit -m "feat(web): menü düzenleyici — kategori yönetimi sidebar widget'ı"
```

---

### Task 10: Canlı Önizleme widget'ı

**Files:**
- Create: `uygulamalar/web/app/sahip/menuler/[menuId]/duzenle/bilesenler/canli-onizleme-widgeti.tsx`

- [ ] **Step 1: Bileşeni yaz**

```tsx
import Image from 'next/image';
import { Item, formatPrice } from '../menu-duzenleyici-yardimcilari';

export function CanliOnizlemeWidgeti({ item }: { item: Item | null }) {
  return (
    <div className="rounded-2xl border border-border bg-card p-4">
      <h3 className="mb-1 text-sm font-black text-textStrong">Canlı Önizleme</h3>
      <p className="mb-3 text-xs text-muted">Müşterileriniz ürünü bu şekilde görür.</p>
      {!item ? (
        <div className="flex flex-col items-center justify-center gap-1 rounded-xl border border-dashed border-border py-8 text-center">
          <p className="text-xs font-bold text-muted">Önizlemek için bir ürün seçin</p>
        </div>
      ) : (
        <div className="overflow-hidden rounded-xl border border-border">
          <div className="relative h-32 w-full bg-bg">
            {item.image_url ? (
              <Image src={item.image_url} alt={item.name} fill sizes="320px" className="object-cover" unoptimized />
            ) : (
              <div className="flex h-full items-center justify-center text-xs font-bold text-muted">Görsel yok</div>
            )}
            <span className={`absolute right-2 top-2 rounded-full px-2 py-0.5 text-[10px] font-extrabold ${item.is_available ? 'bg-green-600 text-white' : 'bg-zinc-500 text-white'}`}>
              {item.is_available ? 'Aktif' : 'Pasif'}
            </span>
          </div>
          <div className="p-3">
            <div className="flex items-start justify-between gap-2">
              <p className="font-black text-textStrong">{item.name}</p>
              <p className="shrink-0 font-black text-primary">{formatPrice(item.price_cents)}</p>
            </div>
            {item.description && <p className="mt-1 text-xs text-muted">{item.description}</p>}
            <div className="mt-2 flex flex-wrap gap-2 text-[11px] font-bold text-muted">
              {item.portion_size && item.portion_unit && (
                <span>⚖ {item.portion_size} {item.portion_unit}</span>
              )}
              {item.calories_min !== null && <span>🔥 {item.calories_min} kcal</span>}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
```

- [ ] **Step 2: Typecheck**

Run: `cd uygulamalar/web && pnpm run typecheck`
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add uygulamalar/web/app/sahip/menuler/'[menuId]'/duzenle/bilesenler/canli-onizleme-widgeti.tsx
git commit -m "feat(web): menü düzenleyici — canlı önizleme sidebar widget'ı"
```

---

### Task 11: Ana orkestratör — `menu-duzenleyici-istemcisi.tsx`'i yeniden yaz

**Files:**
- Modify: `uygulamalar/web/app/sahip/menuler/[menuId]/duzenle/menu-duzenleyici-istemcisi.tsx` (tamamen değiştirilecek)

Tüm bileşenleri birleştiren, state'i yöneten orkestratör. Menü başlığı/yayın kontrolleri (satır 570-643 mevcut dosyada) ve "Yeni Bölüm Ekle" (satır 824-866) davranışı korunuyor, sadece üste taşınıyor; ürün listesi artık `UrunTablosu` üzerinden render ediliyor.

- [ ] **Step 1: Dosyayı tamamen yeniden yaz**

`uygulamalar/web/app/sahip/menuler/[menuId]/duzenle/menu-duzenleyici-istemcisi.tsx`:

```tsx
'use client';

import { useMemo, useState, useTransition } from 'react';
import {
  updateMenuTitle,
  publishMenu,
  createSection,
  deleteItem,
  reorderItem,
  bulkSetAvailability,
  bulkMoveSection,
  bulkDeleteItems,
  duplicateItem,
} from './menu-islemleri';
import {
  type Section,
  type Item,
  type StatusFilter,
  type SortMode,
  computeStats,
  filterItems,
  sortItems,
} from './menu-duzenleyici-yardimcilari';
import { IstatistikKartlari } from './bilesenler/istatistik-kartlari';
import { KategoriSekmeleri } from './bilesenler/kategori-sekmeleri';
import { AracCubugu } from './bilesenler/arac-cubugu';
import { UrunTablosu } from './bilesenler/urun-tablosu';
import { UrunPaneli } from './bilesenler/urun-paneli';
import { KategoriWidgeti } from './bilesenler/kategori-widgeti';
import { CanliOnizlemeWidgeti } from './bilesenler/canli-onizleme-widgeti';

export function MenuEditorClient({
  menuId,
  businessId,
  initialTitle,
  initialStatus,
  sections: initSections,
  items: initItems,
  allergenMap,
  ingredientMap,
}: {
  menuId: string;
  businessId: string;
  initialTitle: string;
  initialStatus: 'draft' | 'published' | 'archived';
  sections: Section[];
  items: Item[];
  allergenMap: Record<string, string[]>;
  ingredientMap: Record<string, string[]>;
}) {
  const [isPending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);
  const [showTitleEdit, setShowTitleEdit] = useState(false);
  const [showNewSection, setShowNewSection] = useState(false);

  const sections = initSections;
  const items = initItems;

  const [activeSectionId, setActiveSectionId] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState<StatusFilter>('all');
  const [sortMode, setSortMode] = useState<SortMode>('manual');
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const [editingItemId, setEditingItemId] = useState<string | null>(null);
  const [addingSectionId, setAddingSectionId] = useState<string | null>(null);
  const [previewItemId, setPreviewItemId] = useState<string | null>(null);

  const stats = useMemo(() => computeStats(sections, items), [sections, items]);

  const itemCountsBySection = useMemo(() => {
    const counts: Record<string, number> = {};
    for (const item of items) counts[item.section_id] = (counts[item.section_id] ?? 0) + 1;
    return counts;
  }, [items]);

  const visibleItems = useMemo(() => {
    const filtered = filterItems(items, { search, sectionId: activeSectionId, status });
    return sortItems(filtered, sortMode);
  }, [items, search, activeSectionId, status, sortMode]);

  const editingItem = editingItemId ? items.find((i) => i.id === editingItemId) ?? null : null;
  const previewItem = previewItemId
    ? items.find((i) => i.id === previewItemId) ?? null
    : visibleItems[0] ?? null;

  function run(action: () => Promise<{ error: string } | null>) {
    setError(null);
    startTransition(async () => {
      const result = await action();
      if (result?.error) setError(result.error);
    });
  }

  function toggleSelect(itemId: string) {
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (next.has(itemId)) next.delete(itemId); else next.add(itemId);
      return next;
    });
  }

  function toggleSelectAll() {
    setSelectedIds((prev) => {
      const allSelected = visibleItems.length > 0 && visibleItems.every((i) => prev.has(i.id));
      if (allSelected) return new Set();
      return new Set(visibleItems.map((i) => i.id));
    });
  }

  async function handleDuplicate(itemId: string) {
    setError(null);
    startTransition(async () => {
      const result = await duplicateItem(itemId, menuId);
      if ('error' in result) setError(result.error);
    });
  }

  return (
    <div className="flex flex-col gap-6 lg:flex-row lg:items-start">
      <div className="flex min-w-0 flex-1 flex-col gap-4">
        {/* Menü başlığı + yayın kontrolleri */}
        <div className="flex flex-wrap items-center gap-3 rounded-2xl border border-border bg-card p-4">
          {showTitleEdit ? (
            <form
              className="flex flex-1 items-center gap-2"
              onSubmit={(e) => {
                e.preventDefault();
                const fd = new FormData(e.currentTarget);
                run(() => updateMenuTitle(menuId, String(fd.get('title') ?? '')));
                setShowTitleEdit(false);
              }}
            >
              <input name="title" defaultValue={initialTitle} required className="flex-1 rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30" />
              <button type="submit" className="rounded-xl bg-primary px-3 py-2 text-xs font-bold text-white cursor-pointer">Kaydet</button>
              <button type="button" onClick={() => setShowTitleEdit(false)} className="rounded-xl border border-border px-3 py-2 text-xs font-bold text-textStrong cursor-pointer">İptal</button>
            </form>
          ) : (
            <>
              <span className="flex-1 font-bold text-textStrong">{initialTitle}</span>
              <button onClick={() => setShowTitleEdit(true)} className="rounded-xl border border-border px-3 py-1.5 text-xs font-bold text-textStrong hover:bg-bg cursor-pointer">Başlığı Düzenle</button>
            </>
          )}
          <div className="flex items-center gap-2">
            {initialStatus !== 'published' && (
              <button onClick={() => run(() => publishMenu(menuId, 'published'))} disabled={isPending} className="rounded-xl bg-green-600 px-3 py-1.5 text-xs font-bold text-white disabled:opacity-60 cursor-pointer">Yayınla</button>
            )}
            {initialStatus === 'published' && (
              <button onClick={() => run(() => publishMenu(menuId, 'draft'))} disabled={isPending} className="rounded-xl border border-amber-300 bg-amber-50 px-3 py-1.5 text-xs font-bold text-amber-700 disabled:opacity-60 cursor-pointer">Taslağa Al</button>
            )}
            {initialStatus !== 'archived' && (
              <button onClick={() => run(() => publishMenu(menuId, 'archived'))} disabled={isPending} className="rounded-xl border border-border px-3 py-1.5 text-xs font-bold text-muted hover:bg-bg disabled:opacity-60 cursor-pointer">Arşivle</button>
            )}
          </div>
        </div>

        {/* Ekleme butonları */}
        <div className="flex justify-end gap-2">
          {showNewSection ? (
            <form
              className="flex flex-1 items-center gap-2 rounded-xl border border-dashed border-border bg-card p-2"
              onSubmit={(e) => {
                e.preventDefault();
                const fd = new FormData(e.currentTarget);
                run(() => createSection(menuId, String(fd.get('title') ?? ''), sections.length));
                setShowNewSection(false);
              }}
            >
              <input name="title" required autoFocus placeholder="Kategori adı" className="min-w-0 flex-1 rounded-lg border border-border bg-bg px-2 py-1.5 text-sm text-textStrong" />
              <button type="submit" className="rounded-lg bg-primary px-3 py-1.5 text-xs font-bold text-white cursor-pointer">Ekle</button>
              <button type="button" onClick={() => setShowNewSection(false)} className="rounded-lg border border-border px-3 py-1.5 text-xs font-bold text-textStrong cursor-pointer">İptal</button>
            </form>
          ) : (
            <button type="button" onClick={() => setShowNewSection(true)} className="rounded-xl border border-border bg-card px-3 py-2 text-sm font-bold text-textStrong hover:bg-bg cursor-pointer">
              + Kategori Ekle
            </button>
          )}
          <button
            type="button"
            disabled={sections.length === 0}
            onClick={() => setAddingSectionId(activeSectionId ?? sections[0]?.id ?? null)}
            className="rounded-xl bg-primary px-3 py-2 text-sm font-bold text-white disabled:cursor-not-allowed disabled:opacity-50 cursor-pointer"
          >
            + Yeni Ürün Ekle
          </button>
        </div>

        {error && <div className="rounded-xl bg-red-50 px-4 py-3 text-sm text-red-700">{error}</div>}

        <IstatistikKartlari stats={stats} />

        <KategoriSekmeleri
          sections={sections}
          itemCounts={itemCountsBySection}
          activeSectionId={activeSectionId}
          onChange={setActiveSectionId}
        />

        <AracCubugu
          search={search}
          onSearchChange={setSearch}
          sections={sections}
          sectionId={activeSectionId}
          onSectionChange={setActiveSectionId}
          status={status}
          onStatusChange={setStatus}
          sortMode={sortMode}
          onSortModeChange={setSortMode}
          selectedCount={selectedIds.size}
          onBulkSetAvailability={(isAvailable) => {
            run(() => bulkSetAvailability([...selectedIds], menuId, isAvailable));
            setSelectedIds(new Set());
          }}
          onBulkMoveSection={(sectionId) => {
            run(() => bulkMoveSection([...selectedIds], menuId, sectionId));
            setSelectedIds(new Set());
          }}
          onBulkDelete={() => {
            run(() => bulkDeleteItems([...selectedIds], menuId));
            setSelectedIds(new Set());
          }}
        />

        <UrunTablosu
          items={visibleItems}
          sections={sections}
          sortMode={sortMode}
          selectedIds={selectedIds}
          onToggleSelect={toggleSelect}
          onToggleSelectAll={toggleSelectAll}
          onReorder={(itemId, newSortOrder) => run(() => reorderItem(itemId, menuId, newSortOrder))}
          onEdit={(itemId) => { setPreviewItemId(itemId); setEditingItemId(itemId); }}
          onDuplicate={handleDuplicate}
          onDelete={(itemId) => run(() => deleteItem(itemId, menuId))}
        />
      </div>

      <div className="flex w-full flex-col gap-4 lg:w-80 lg:shrink-0">
        <KategoriWidgeti menuId={menuId} sections={sections} itemCounts={itemCountsBySection} />
        <CanliOnizlemeWidgeti item={previewItem} />
      </div>

      {(editingItem || addingSectionId) && (
        <UrunPaneli
          menuId={menuId}
          sectionId={editingItem?.section_id ?? addingSectionId ?? sections[0]?.id ?? ''}
          businessId={businessId}
          itemId={editingItem?.id}
          initialValues={editingItem ? {
            name: editingItem.name,
            description: editingItem.description,
            image_url: editingItem.image_url,
            price_cents: editingItem.price_cents,
            is_available: editingItem.is_available,
            calories_min: editingItem.calories_min,
            portion_size: editingItem.portion_size,
            portion_unit: editingItem.portion_unit,
          } : undefined}
          initialAllergens={editingItem ? allergenMap[editingItem.id] ?? [] : []}
          initialIngredients={editingItem ? ingredientMap[editingItem.id] ?? [] : []}
          submitLabel={editingItem ? 'Kaydet' : 'Ürün Ekle'}
          onSuccess={() => { setEditingItemId(null); setAddingSectionId(null); }}
          onCancel={() => { setEditingItemId(null); setAddingSectionId(null); }}
        />
      )}
    </div>
  );
}
```

- [ ] **Step 2: Typecheck + lint + testler**

Run: `cd uygulamalar/web && pnpm run typecheck && pnpm run lint && pnpm run test:unit`
Expected: Hepsi temiz — 0 hata, tüm testler geçmeli (Task 1-3'teki yeni testler dahil).

- [ ] **Step 3: Commit**

```bash
git add uygulamalar/web/app/sahip/menuler/'[menuId]'/duzenle/menu-duzenleyici-istemcisi.tsx
git commit -m "feat(web): menü düzenleyici — orkestratörü yeni bileşenlerle yeniden yaz"
```

---

### Task 12: Son doğrulama

**Files:** Yok (sadece doğrulama)

- [ ] **Step 1: Tam doğrulama paketini çalıştır**

Run: `cd uygulamalar/web && pnpm run typecheck && pnpm run lint && pnpm run test:unit`
Expected: 0 hata.

- [ ] **Step 2: Dev server ile manuel doğrulama (mümkünse)**

Eğer local Supabase + `.env.local` mevcutsa: `pnpm run dev` başlat, gerçek bir owner hesabıyla `/sahip/menuler/[menuId]/duzenle`'e git, şunları doğrula:
- İstatistik kartları doğru sayıları gösteriyor
- Kategori sekmeleri filtreleme yapıyor
- Arama/durum/sıralama filtreleri çalışıyor
- Sürükle-bırak (Manuel Sıralama modunda) sırayı gerçekten değiştiriyor ve sayfa yenilendiğinde kalıcı
- Toplu işlemler (aktif/pasif, kategori taşıma, silme) çalışıyor
- Satır tıklayınca yan panel açılıyor, mevcut TÜM alanlar (AI doldurma, AI görsel, alerjen, malzeme) çalışıyor
- Kategori Yönetimi widget'ından ekleme/düzenleme çalışıyor
- Canlı Önizleme seçili ürünü gösteriyor
- "Yeni Ürün Ekle" / "Kategori Ekle" butonları çalışıyor

Ortam bu testi desteklemiyorsa (`.env.local` yok), bunu raporda açıkça belirt — bu oturumda tekrarlanan, bilinen bir kısıt.

- [ ] **Step 3: Nihai commit (gerekirse temizlik)**

Doğrulama sırasında küçük düzeltmeler gerekirse, ayrı commit'ler halinde yap.

---

## Kapsam Dışı (bu planda yok)

- Menü listesi sayfası, Kategoriler sayfası (ayrı sayfalar, dokunulmuyor)
- Gerçek public sayfa embed'i (canlı önizleme sadece kart)
- 3 durumlu ürün statüsü
