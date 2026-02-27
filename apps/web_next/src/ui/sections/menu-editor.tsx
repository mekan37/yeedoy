'use client';

import { useEffect, useMemo, useState } from 'react';
import { useRouter } from 'next/navigation';
import Image from 'next/image';
import { Button } from '@/src/ui/components/button';
import { Card } from '@/src/ui/components/card';
import { Input } from '@/src/ui/components/input';
import { Textarea } from '@/src/ui/components/textarea';

type Category = { id: string; sort_order: number; is_active: boolean };
type Item = {
  id: string;
  category_id: string;
  name?: string | null;
  description?: string | null;
  price_cents: number;
  is_available: boolean;
  image_url: string | null;
  tags: string[] | null;
};
type Variant = {
  id: string;
  menu_item_id: string;
  label: string;
  price_cents: number;
  currency: string;
  is_default: boolean;
  is_available: boolean;
  sort_order: number;
};
type Translation = {
  entity_type: 'business' | 'category' | 'item';
  entity_id: string;
  locale: string;
  name: string;
  description: string | null;
};

type CatalogHit = {
  id: number;
  name: string;
  categoryId: string;
  categoryName: string;
  slug: string;
  tags: string[];
};

export function MenuEditorSection({
  businessId,
  menuId,
  menus,
  categories,
  items,
  variants,
  translations,
}: {
  businessId: string;
  menuId: string | null;
  menus: Array<{ id: string; title: string; status: string }>;
  categories: Category[];
  items: Item[];
  variants: Variant[];
  translations: Translation[];
}) {
  const router = useRouter();
  const [busy, setBusy] = useState(false);
  const [notice, setNotice] = useState<{ type: 'success' | 'error'; text: string } | null>(null);
  const [editingByCategory, setEditingByCategory] = useState<Record<string, string | null>>({});

  const getErrorText = (err: unknown) =>
    err instanceof Error ? err.message : 'Beklenmeyen bir hata olustu.';

  async function safeJson(res: Response) {
    const body = await res.json().catch(() => ({}));
    if (!res.ok) {
      throw new Error((body as { error?: string }).error ?? `Istek basarisiz (${res.status})`);
    }
    return body as Record<string, unknown>;
  }

  const catName = (categoryId: string, locale = 'tr') =>
    translations.find((t) => t.entity_type === 'category' && t.entity_id === categoryId && t.locale === locale)?.name ??
    'Kategori';

  const itemName = (itemId: string, locale = 'tr') =>
    translations.find((t) => t.entity_type === 'item' && t.entity_id === itemId && t.locale === locale)?.name ?? 'Urun';
  const itemDescription = (itemId: string, locale = 'tr') =>
    translations.find((t) => t.entity_type === 'item' && t.entity_id === itemId && t.locale === locale)?.description ?? '';

  const grouped = useMemo(
    () =>
      categories.map((c) => ({
        ...c,
        items: items.filter((i) => i.category_id === c.id).sort((a, b) => a.price_cents - b.price_cents),
      })),
    [categories, items],
  );
  const variantsByItem = useMemo(() => {
    const map: Record<string, Variant[]> = {};
    for (const v of variants) {
      if (!map[v.menu_item_id]) map[v.menu_item_id] = [];
      map[v.menu_item_id].push(v);
    }
    Object.values(map).forEach((arr) => arr.sort((a, b) => a.sort_order - b.sort_order));
    return map;
  }, [variants]);

  async function createCategory(fd: FormData) {
    try {
      setBusy(true);
      setNotice(null);
      const res = await fetch('/api/menu/category', { method: 'POST', body: fd });
      await safeJson(res);
      setNotice({ type: 'success', text: 'Kategori eklendi.' });
      router.refresh();
    } catch (err) {
      setNotice({ type: 'error', text: getErrorText(err) });
    } finally {
      setBusy(false);
    }
  }

  async function moveCategory(categoryId: string, direction: 'up' | 'down') {
    if (!menuId) return;
    try {
      setBusy(true);
      setNotice(null);
      const res = await fetch('/api/menu/category', {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ business_id: businessId, menu_id: menuId, category_id: categoryId, direction }),
      });
      await safeJson(res);
      setNotice({ type: 'success', text: 'Kategori sirasi guncellendi.' });
      router.refresh();
    } catch (err) {
      setNotice({ type: 'error', text: getErrorText(err) });
    } finally {
      setBusy(false);
    }
  }

  async function addItem(fd: FormData) {
    try {
      setBusy(true);
      setNotice(null);
      const res = await fetch('/api/menu/item', { method: 'POST', body: fd });
      await safeJson(res);
      setNotice({ type: 'success', text: 'Urun eklendi.' });
      router.refresh();
    } catch (err) {
      setNotice({ type: 'error', text: getErrorText(err) });
    } finally {
      setBusy(false);
    }
  }

  async function updateItem(fd: FormData) {
    try {
      setBusy(true);
      setNotice(null);
      const res = await fetch('/api/menu/item', { method: 'PUT', body: fd });
      await safeJson(res);
      const categoryId = String(fd.get('category_id') ?? '');
      if (categoryId) {
        setEditingByCategory((prev) => ({ ...prev, [categoryId]: null }));
      }
      setNotice({ type: 'success', text: 'Urun guncellendi.' });
      router.refresh();
    } catch (err) {
      setNotice({ type: 'error', text: getErrorText(err) });
    } finally {
      setBusy(false);
    }
  }

  async function toggleItem(itemId: string, isAvailable: boolean) {
    try {
      setBusy(true);
      setNotice(null);
      const res = await fetch('/api/menu/item', {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ business_id: businessId, item_id: itemId, is_available: isAvailable }),
      });
      await safeJson(res);
      setNotice({ type: 'success', text: isAvailable ? 'Urun aktif edildi.' : 'Urun pasife alindi.' });
      router.refresh();
    } catch (err) {
      setNotice({ type: 'error', text: getErrorText(err) });
    } finally {
      setBusy(false);
    }
  }

  async function deleteItem(itemId: string) {
    if (!confirm('Bu urunu silmek istediginize emin misiniz?')) return;
    try {
      setBusy(true);
      setNotice(null);
      const res = await fetch('/api/menu/item', {
        method: 'DELETE',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ business_id: businessId, item_id: itemId }),
      });
      await safeJson(res);
      setNotice({ type: 'success', text: 'Urun silindi.' });
      router.refresh();
    } catch (err) {
      setNotice({ type: 'error', text: getErrorText(err) });
    } finally {
      setBusy(false);
    }
  }

  async function deleteCategory(categoryId: string) {
    if (!menuId) return;
    if (!confirm('Bu kategori ve altindaki urunler silinecek. Devam edilsin mi?')) return;
    try {
      setBusy(true);
      setNotice(null);
      const res = await fetch('/api/menu/category', {
        method: 'DELETE',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ business_id: businessId, menu_id: menuId, category_id: categoryId }),
      });
      const data = await safeJson(res);
      const deletedItems = Number(data.deleted_items ?? 0);
      setNotice({
        type: 'success',
        text: deletedItems > 0 ? `Kategori silindi (${deletedItems} urun temizlendi).` : 'Kategori silindi.',
      });
      router.refresh();
    } catch (err) {
      setNotice({ type: 'error', text: getErrorText(err) });
    } finally {
      setBusy(false);
    }
  }

  async function uploadImage(file: File) {
    const fd = new FormData();
    fd.set('business_id', businessId);
    fd.set('kind', 'item');
    fd.set('file', file);
    const res = await fetch('/api/upload', { method: 'POST', body: fd });
    return safeJson(res);
  }

  async function importJson(file: File) {
    const raw = await file.text();
    try {
      setBusy(true);
      setNotice(null);
      const res = await fetch(`/api/menu/import/${businessId}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: raw,
      });
      const data = await safeJson(res);
      const c = Number(data.imported_categories ?? 0);
      const i = Number(data.imported_items ?? 0);
      setNotice({ type: 'success', text: `JSON ice aktarim tamamlandi: ${c} kategori, ${i} urun.` });
      router.refresh();
    } catch (err) {
      setNotice({ type: 'error', text: getErrorText(err) });
    } finally {
      setBusy(false);
    }
  }

  async function exportJson() {
    try {
      setNotice(null);
      const res = await fetch(`/api/menu/export/${businessId}`);
      const data = await safeJson(res);
      const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
      const href = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = href;
      a.download = `menu-${businessId}.json`;
      a.click();
      URL.revokeObjectURL(href);
      setNotice({ type: 'success', text: 'JSON disa aktarildi.' });
    } catch (err) {
      setNotice({ type: 'error', text: getErrorText(err) });
    }
  }

  async function toggleMenuActive(targetMenuId: string, currentStatus: string) {
    try {
      setBusy(true);
      setNotice(null);
      const isActiveNow = currentStatus === 'published';
      const res = await fetch('/api/menu/status', {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          business_id: businessId,
          menu_id: targetMenuId,
          active: !isActiveNow,
        }),
      });
      await safeJson(res);
      setNotice({
        type: 'success',
        text: isActiveNow ? 'Menu pasife alindi.' : 'Menu aktif edildi.',
      });
      router.refresh();
    } catch (err) {
      setNotice({ type: 'error', text: getErrorText(err) });
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="grid gap-4">
      <Card className="rounded-3xl">
        <div className="flex flex-wrap items-center gap-2">
          <span className="text-sm text-slate-500">Duzenlenen menu:</span>
          {menus.length === 0 ? (
            <span className="text-sm text-rose-700">Menu bulunamadi</span>
          ) : (
            menus.map((menu) => (
              <div key={menu.id} className="flex items-center gap-2 rounded-xl border border-slate-200 px-2 py-1">
                <Button
                  type="button"
                  className={menu.id === menuId ? '' : 'bg-slate-700'}
                  onClick={() => router.push(`?menu=${menu.id}`)}
                >
                  {menu.title}
                </Button>
                <Button
                  type="button"
                  className={menu.status === 'published' ? 'bg-emerald-700' : 'bg-slate-500'}
                  disabled={busy}
                  onClick={() => void toggleMenuActive(menu.id, menu.status)}
                >
                  {menu.status === 'published' ? 'Aktif' : 'Pasif'}
                </Button>
              </div>
            ))
          )}
        </div>
      </Card>
      <Card className="rounded-3xl">
        <div className="flex flex-wrap items-center gap-2">
          <form
            action={createCategory}
            className="flex w-full flex-wrap items-center gap-2 md:w-auto"
          >
            <input type="hidden" name="business_id" value={businessId} />
            <input type="hidden" name="menu_id" value={menuId ?? ''} />
            <Input name="name_tr" placeholder="Kategori adi (TR)" className="w-60" />
            <Input name="name_en" placeholder="Kategori adi (EN)" className="w-60" />
            <Button type="submit" disabled={busy || !menuId}>Kategori Ekle</Button>
          </form>
          <Button type="button" onClick={exportJson} className="bg-slate-700">JSON Disa Aktar</Button>
          <label className="cursor-pointer rounded-lg border border-slate-300 px-3 py-2 text-sm">
            JSON Ice Aktar
            <input
              type="file"
              accept="application/json"
              className="hidden"
              onChange={(e) => {
                const file = e.target.files?.[0];
                if (file) void importJson(file);
              }}
            />
          </label>
        </div>
        <div className="mt-3 flex items-center justify-between text-sm">
          <span className="text-slate-500">
            Toplam {categories.length} kategori, {items.length} urun
          </span>
          {notice ? (
            <span className={notice.type === 'success' ? 'text-emerald-700' : 'text-rose-700'}>
              {notice.text}
            </span>
          ) : null}
        </div>
      </Card>

      {grouped.map((category) => (
        <Card key={category.id} className="rounded-3xl">
          {(() => {
            const editingItemId = editingByCategory[category.id] ?? null;
            const editingItem = category.items.find((i) => i.id === editingItemId) ?? null;
            return (
              <>
          <div className="mb-3 flex items-center justify-between gap-2">
            <h3 className="text-lg font-bold">{catName(category.id)} ({category.items.length})</h3>
            <div className="flex gap-2">
              <Button type="button" className="bg-slate-700" onClick={() => moveCategory(category.id, 'up')}>Yukari</Button>
              <Button type="button" className="bg-slate-700" onClick={() => moveCategory(category.id, 'down')}>Asagi</Button>
              <Button type="button" className="bg-rose-700" onClick={() => deleteCategory(category.id)}>Sil</Button>
            </div>
          </div>
          <div className="grid gap-4 lg:grid-cols-2">
            <div className="space-y-2">
              {category.items.length === 0 ? (
                <div className="rounded-xl border border-dashed border-slate-300 p-4 text-sm text-slate-500">
                  Bu kategoride henuz urun yok.
                </div>
              ) : null}
              {category.items.map((item) => {
                const imageUrl = normalizeImageUrl(item.image_url);
                const selected = editingItem?.id === item.id;
                return (
                  <div
                    key={item.id}
                    role="button"
                    tabIndex={0}
                    onClick={() =>
                      setEditingByCategory((prev) => ({ ...prev, [category.id]: item.id }))
                    }
                    onKeyDown={(e) => {
                      if (e.key === 'Enter' || e.key === ' ') {
                        e.preventDefault();
                        setEditingByCategory((prev) => ({ ...prev, [category.id]: item.id }));
                      }
                    }}
                    className={`flex cursor-pointer items-center justify-between rounded-xl border p-3 transition ${
                      selected
                        ? 'border-slate-900 bg-slate-50'
                        : 'border-slate-200 hover:border-slate-300 hover:bg-slate-50'
                    }`}
                  >
                    <div className="flex min-w-0 items-center gap-3">
                      {imageUrl ? (
                        <Image
                          src={imageUrl}
                          alt={itemName(item.id) || item.name || 'Urun'}
                          width={56}
                          height={56}
                          unoptimized
                          className="h-14 w-14 shrink-0 rounded-xl border border-slate-200 object-cover"
                        />
                      ) : null}
                      <div className="min-w-0">
                        <p className="truncate font-semibold">{itemName(item.id) || item.name || 'Urun'}</p>
                        <p className="text-sm text-slate-500">{(item.price_cents / 100).toFixed(2)} TRY</p>
                      </div>
                    </div>
                    <div className="flex gap-2">
                      <Button
                        type="button"
                        className={item.is_available ? 'bg-emerald-700' : 'bg-slate-500'}
                        onClick={(e) => {
                          e.stopPropagation();
                          void toggleItem(item.id, !item.is_available);
                        }}
                      >
                        {item.is_available ? 'Aktif' : 'Pasif'}
                      </Button>
                      <Button
                        type="button"
                        className="bg-rose-700"
                        onClick={(e) => {
                          e.stopPropagation();
                          void deleteItem(item.id);
                        }}
                      >
                        Sil
                      </Button>
                    </div>
                  </div>
                );
              })}
            </div>

            <form
              action={async (fd) => {
                if (!menuId) return;
                const file = fd.get('image_file');
                if (file instanceof File && file.size > 0) {
                  const uploaded = await uploadImage(file);
                  const publicUrl = uploaded.publicUrl;
                  if (typeof publicUrl === 'string' && publicUrl.length > 0) {
                    fd.set('image_url', publicUrl);
                  }
                }
                if (editingItem) {
                  fd.set('item_id', editingItem.id);
                  await updateItem(fd);
                } else {
                  await addItem(fd);
                }
              }}
              key={`${category.id}-${editingItem?.id ?? 'new'}`}
              className="grid gap-2 rounded-xl border border-dashed border-slate-300 p-3"
            >
              <input type="hidden" name="business_id" value={businessId} />
              <input type="hidden" name="category_id" value={category.id} />
              <input type="hidden" name="menu_id" value={menuId ?? ''} />
              <CatalogNameInput
                name="name"
                placeholder="Urun adi"
                defaultValue={editingItem ? itemName(editingItem.id, 'tr') || editingItem.name || '' : ''}
              />
              <Input
                name="name_en"
                placeholder="Urun adi (EN opsiyonel)"
                defaultValue={editingItem ? itemName(editingItem.id, 'en') : ''}
              />
              <Textarea
                name="description"
                placeholder="Aciklama (TR)"
                defaultValue={editingItem ? itemDescription(editingItem.id, 'tr') || editingItem.description || '' : ''}
              />
              <Textarea
                name="description_en"
                placeholder="Aciklama (EN opsiyonel)"
                defaultValue={editingItem ? itemDescription(editingItem.id, 'en') : ''}
              />
              <div className="grid grid-cols-2 gap-2">
                <Input
                  name="price_cents"
                  type="number"
                  placeholder="Fiyat (kurus)"
                  defaultValue={editingItem ? String(editingItem.price_cents) : ''}
                />
                <Input
                  name="tags"
                  placeholder="Etiket: acili,vegan"
                  defaultValue={editingItem ? (editingItem.tags ?? []).join(',') : ''}
                />
              </div>
              <Input
                name="image_url"
                placeholder="Gorsel URL (opsiyonel)"
                defaultValue={editingItem?.image_url ?? ''}
              />
              <input name="image_file" type="file" accept="image/*" className="text-sm" />
              <label className="flex items-center gap-2 text-sm">
                <input
                  type="checkbox"
                  name="is_available"
                  value="true"
                  defaultChecked={editingItem ? editingItem.is_available : true}
                />
                Satista
              </label>
              <div className="flex gap-2">
                <Button type="submit" disabled={busy || !menuId}>
                  {editingItem ? 'Urunu Guncelle' : 'Urun Ekle'}
                </Button>
                {editingItem ? (
                  <Button
                    type="button"
                    className="bg-slate-700"
                    onClick={() =>
                      setEditingByCategory((prev) => ({ ...prev, [category.id]: null }))
                    }
                  >
                    Vazgec
                  </Button>
                ) : null}
              </div>
              {editingItem ? (
                <ItemVariantsEditor
                  businessId={businessId}
                  itemId={editingItem.id}
                  variants={variantsByItem[editingItem.id] ?? []}
                  onChanged={() => router.refresh()}
                />
              ) : null}
            </form>
          </div>
              </>
            );
          })()}
        </Card>
      ))}
    </div>
  );
}

function ItemVariantsEditor({
  businessId,
  itemId,
  variants,
  onChanged,
}: {
  businessId: string;
  itemId: string;
  variants: Variant[];
  onChanged: () => void;
}) {
  const [label, setLabel] = useState('');
  const [priceTl, setPriceTl] = useState('');
  const [busy, setBusy] = useState(false);

  const safeJson = async (res: Response) => {
    const body = await res.json().catch(() => ({}));
    if (!res.ok) throw new Error((body as { error?: string }).error ?? `Istek basarisiz (${res.status})`);
    return body as Record<string, unknown>;
  };

  const addVariant = async () => {
    const price = Number((Number(priceTl.replace(',', '.')) * 100).toFixed(0));
    if (!label.trim() || !Number.isFinite(price) || price < 0) return;
    try {
      setBusy(true);
      const res = await fetch('/api/menu/item-variant', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          business_id: businessId,
          item_id: itemId,
          label: label.trim(),
          price_cents: price,
          currency: 'TRY',
          is_default: variants.length === 0,
        }),
      });
      await safeJson(res);
      setLabel('');
      setPriceTl('');
      onChanged();
    } finally {
      setBusy(false);
    }
  };

  const setDefault = async (variantId: string) => {
    try {
      setBusy(true);
      const res = await fetch('/api/menu/item-variant', {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          business_id: businessId,
          item_id: itemId,
          variant_id: variantId,
          is_default: true,
        }),
      });
      await safeJson(res);
      onChanged();
    } finally {
      setBusy(false);
    }
  };

  const removeVariant = async (variantId: string) => {
    try {
      setBusy(true);
      const res = await fetch('/api/menu/item-variant', {
        method: 'DELETE',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ business_id: businessId, variant_id: variantId }),
      });
      await safeJson(res);
      onChanged();
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="mt-3 rounded-xl border border-slate-200 p-3">
      <p className="mb-2 text-sm font-semibold text-slate-700">Varyantlar (80gr / 120gr gibi)</p>
      <div className="space-y-1">
        {variants.map((v) => (
          <div key={v.id} className="flex items-center justify-between rounded-lg border border-slate-200 px-2 py-1 text-sm">
            <span>{v.label} - {(v.price_cents / 100).toFixed(2)} {v.currency}</span>
            <div className="flex items-center gap-2">
              {v.is_default ? <span className="text-emerald-700">Varsayilan</span> : null}
              {!v.is_default ? (
                <Button type="button" className="bg-slate-700" disabled={busy} onClick={() => void setDefault(v.id)}>
                  Varsayilan yap
                </Button>
              ) : null}
              <Button type="button" className="bg-rose-700" disabled={busy} onClick={() => void removeVariant(v.id)}>
                Sil
              </Button>
            </div>
          </div>
        ))}
      </div>
      <div className="mt-2 grid grid-cols-3 gap-2">
        <Input value={label} onChange={(e) => setLabel(e.target.value)} placeholder="Etiket (120gr)" />
        <Input value={priceTl} onChange={(e) => setPriceTl(e.target.value)} type="number" placeholder="Fiyat (TL)" />
        <Button type="button" disabled={busy} onClick={() => void addVariant()}>
          Varyant Ekle
        </Button>
      </div>
    </div>
  );
}

function CatalogNameInput({
  name,
  placeholder,
  defaultValue = '',
}: {
  name: string;
  placeholder: string;
  defaultValue?: string;
}) {
  const [value, setValue] = useState(defaultValue);
  const [hits, setHits] = useState<CatalogHit[]>([]);

  useEffect(() => {
    setValue(defaultValue);
  }, [defaultValue]);

  useEffect(() => {
    if (value.trim().length < 2) {
      setHits([]);
      return;
    }
    const t = setTimeout(async () => {
      try {
        const res = await fetch(`/api/menu/catalog-search?q=${encodeURIComponent(value)}&limit=6`);
        const data = await res.json();
        setHits((data.items ?? []) as CatalogHit[]);
      } catch {
        setHits([]);
      }
    }, 220);
    return () => clearTimeout(t);
  }, [value]);

  return (
    <div className="space-y-1">
      <Input
        name={name}
        placeholder={placeholder}
        value={value}
        onChange={(e) => setValue(e.target.value)}
      />
      {hits.length > 0 ? (
        <div className="rounded-lg border border-slate-200 bg-slate-50 px-2 py-1">
          <div className="text-[11px] font-medium text-slate-500">Katalog onerileri</div>
          <div className="mt-1 flex flex-wrap gap-1">
            {hits.map((hit) => (
              <button
                key={`${hit.id}-${hit.slug}`}
                type="button"
                className="rounded-full border border-slate-300 bg-white px-2 py-1 text-xs text-slate-700"
                onClick={() => setValue(hit.name)}
                title={hit.categoryName}
              >
                {hit.name}
              </button>
            ))}
          </div>
        </div>
      ) : null}
    </div>
  );
}

function normalizeImageUrl(url: string | null | undefined): string | null {
  const value = String(url ?? '').trim();
  if (!value) return null;
  try {
    const parsed = new URL(value);
    if (parsed.protocol !== 'http:' && parsed.protocol !== 'https:') return null;
    return parsed.toString();
  } catch {
    return null;
  }
}
