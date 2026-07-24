'use client';

import Image from 'next/image';
import { useState, useTransition } from 'react';
import {
  createSection,
  updateSection,
  deleteSection,
  upsertItem,
  deleteItem,
  publishMenu,
  updateMenuTitle,
  upsertItemAllergens,
  upsertItemIngredients,
} from './menu-islemleri';

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

type Section = { id: string; title: string; sort_order: number };
type Item = {
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
};

function formatPrice(cents: number) {
  return (cents / 100).toLocaleString('tr-TR', { minimumFractionDigits: 2 }) + ' ₺';
}

function Input({
  label,
  name,
  defaultValue = '',
  required = false,
  type = 'text',
  placeholder = '',
}: {
  label: string;
  name: string;
  defaultValue?: string;
  required?: boolean;
  type?: string;
  placeholder?: string;
}) {
  return (
    <div className="flex flex-col gap-1">
      <label className="text-xs font-bold text-muted">{label}</label>
      <input
        name={name}
        type={type}
        defaultValue={defaultValue}
        required={required}
        placeholder={placeholder}
        className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30"
      />
    </div>
  );
}

function ImageUrlField({
  businessId,
  label,
  initialUrl = null,
}: {
  businessId: string;
  label: string;
  initialUrl?: string | null;
}) {
  const [url, setUrl] = useState(initialUrl ?? '');
  const [uploading, setUploading] = useState(false);
  const [uploadError, setUploadError] = useState<string | null>(null);

  async function upload(file: File | null) {
    if (!file) return;
    setUploading(true);
    setUploadError(null);

    try {
      const formData = new FormData();
      formData.set('businessId', businessId);
      formData.set('type', 'item');
      formData.set('file', file);

      const response = await fetch('/sunucu/medya/yukleme', {
        method: 'POST',
        body: formData,
      });
      const payload = (await response.json().catch(() => null)) as {
        data?: { url?: string };
      } | null;

      if (!response.ok || !payload?.data?.url) {
        throw new Error('upload_failed');
      }

      setUrl(payload.data.url);
    } catch {
      setUploadError('Görsel yüklenemedi.');
    } finally {
      setUploading(false);
    }
  }

  return (
    <div className="grid gap-3 rounded-xl border border-border bg-bg p-3 sm:grid-cols-[96px_1fr]">
      <div className="relative flex h-24 w-24 items-center justify-center overflow-hidden rounded-xl border border-border bg-card text-[11px] font-extrabold text-muted">
        {url ? (
          <Image src={url} alt="" fill sizes="96px" className="object-cover" unoptimized />
        ) : (
          'Görsel yok'
        )}
      </div>
      <div className="flex min-w-0 flex-col gap-2">
        <input type="hidden" name="imageUrl" value={url} />
        <label className="text-xs font-bold text-muted">{label}</label>
        <input
          type="url"
          value={url}
          onChange={(event) => setUrl(event.target.value)}
          placeholder="https://..."
          className="rounded-xl border border-border bg-card px-3 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30"
        />
        <div className="flex flex-wrap items-center gap-2">
          <label className="inline-flex min-h-10 cursor-pointer items-center rounded-xl border border-border bg-card px-3 py-2 text-xs font-extrabold text-textStrong hover:bg-white">
            {uploading ? 'Yükleniyor...' : 'Bilgisayardan seç'}
            <input
              type="file"
              accept="image/png,image/jpeg,image/webp"
              disabled={uploading}
              onChange={(event) => upload(event.target.files?.[0] ?? null)}
              className="sr-only"
            />
          </label>
          {url && (
            <button
              type="button"
              onClick={() => setUrl('')}
              className="min-h-10 rounded-xl border border-border px-3 py-2 text-xs font-extrabold text-muted hover:bg-card"
            >
              Kaldır
            </button>
          )}
          {uploadError && <span className="text-xs font-bold text-red-600">{uploadError}</span>}
        </div>
      </div>
    </div>
  );
}

function ItemForm({
  menuId,
  sectionId,
  businessId,
  itemId,
  initialValues,
  initialAllergens,
  initialIngredients,
  submitLabel,
  onSuccess,
  onCancel,
}: {
  menuId: string;
  sectionId: string;
  businessId: string;
  itemId?: string;
  initialValues?: {
    name: string;
    description: string | null;
    image_url: string | null;
    price_cents: number;
    is_available: boolean;
    calories_min: number | null;
    portion_size: number | null;
    portion_unit: string | null;
  };
  initialAllergens: string[];
  initialIngredients: string[];
  submitLabel: string;
  onSuccess: () => void;
  onCancel: () => void;
}) {
  const [isPending, startTransition] = useTransition();
  const [formError, setFormError] = useState<string | null>(null);
  const [selectedAllergens, setSelectedAllergens] = useState<Set<string>>(
    new Set(initialAllergens),
  );
  const [ingredients, setIngredients] = useState<string[]>(initialIngredients);
  const [ingredientInput, setIngredientInput] = useState('');

  function toggleAllergen(code: string) {
    setSelectedAllergens((prev) => {
      const next = new Set(prev);
      if (next.has(code)) next.delete(code);
      else next.add(code);
      return next;
    });
  }

  function addIngredient() {
    const trimmed = ingredientInput.trim();
    if (trimmed && !ingredients.includes(trimmed)) {
      setIngredients((prev) => [...prev, trimmed]);
    }
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
      if ('error' in result) {
        setFormError(result.error);
        return;
      }
      const resolvedId = result.itemId;
      if (resolvedId) {
        const allergenResult = await upsertItemAllergens(resolvedId, menuId, [
          ...selectedAllergens,
        ]);
        if (allergenResult?.error) {
          setFormError(allergenResult.error);
          return;
        }
        const ingredientResult = await upsertItemIngredients(resolvedId, menuId, ingredients);
        if (ingredientResult?.error) {
          setFormError(ingredientResult.error);
          return;
        }
      }
      onSuccess();
    });
  }

  return (
    <form className="p-4 flex flex-col gap-3" onSubmit={handleSubmit}>
      <div className="grid grid-cols-2 gap-3">
        <Input
          label="Ürün Adı"
          name="name"
          defaultValue={initialValues?.name ?? ''}
          required
          placeholder="Ürün adı"
        />
        <Input
          label="Fiyat (₺)"
          name="price"
          type="number"
          defaultValue={initialValues ? String(initialValues.price_cents / 100) : ''}
          required
          placeholder="0.00"
        />
      </div>
      <Input
        label="Açıklama (opsiyonel)"
        name="description"
        defaultValue={initialValues?.description ?? ''}
        placeholder="Kısa açıklama"
      />
      <ImageUrlField
        businessId={businessId}
        label="Ürün görseli"
        initialUrl={initialValues?.image_url ?? null}
      />
      <label className="flex items-center gap-2 text-sm text-textStrong cursor-pointer">
        <input
          type="checkbox"
          name="is_available"
          defaultChecked={initialValues?.is_available ?? true}
          className="rounded"
        />
        Satışta
      </label>

      {/* Şeffaf Menü Bilgileri */}
      <div className="flex flex-col gap-3 rounded-2xl border border-border bg-bg p-3">
        <p className="text-xs font-bold text-muted">Şeffaf Menü Bilgileri (İsteğe Bağlı)</p>

        {/* Kalori */}
        <div className="flex flex-col gap-1">
          <label className="text-xs font-bold text-muted">Enerji Değeri (kcal)</label>
          <input
            name="calories"
            type="number"
            defaultValue={initialValues?.calories_min ?? ''}
            min="0"
            max="9999"
            placeholder="örn: 450"
            className="rounded-xl border border-border bg-card px-3 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30"
          />
        </div>

        {/* Porsiyon */}
        <div className="grid grid-cols-2 gap-2">
          <div className="flex flex-col gap-1">
            <label className="text-xs font-bold text-muted">Porsiyon Miktarı</label>
            <input
              name="portion_size"
              type="number"
              defaultValue={initialValues?.portion_size ?? ''}
              min="0"
              placeholder="örn: 350"
              className="rounded-xl border border-border bg-card px-3 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30"
            />
          </div>
          <div className="flex flex-col gap-1">
            <label className="text-xs font-bold text-muted">Birim</label>
            <select
              name="portion_unit"
              defaultValue={initialValues?.portion_unit ?? ''}
              className="rounded-xl border border-border bg-card px-3 py-2 text-sm text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30"
            >
              <option value="">Birim</option>
              <option value="g">g</option>
              <option value="ml">ml</option>
              <option value="adet">adet</option>
              <option value="dilim">dilim</option>
            </select>
          </div>
        </div>

        {/* Malzemeler — tag-style input */}
        <div className="flex flex-col gap-2">
          <p className="text-xs font-bold text-muted">Malzemeler</p>
          <div className="flex gap-2">
            <input
              type="text"
              value={ingredientInput}
              onChange={(e) => setIngredientInput(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter') {
                  e.preventDefault();
                  addIngredient();
                }
              }}
              placeholder="örn: domates"
              className="flex-1 rounded-xl border border-border bg-card px-3 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30"
            />
            <button
              type="button"
              onClick={addIngredient}
              className="rounded-xl border border-border bg-card px-3 py-2 text-xs font-bold text-textStrong hover:bg-bg cursor-pointer"
            >
              Ekle
            </button>
          </div>
          {ingredients.length > 0 && (
            <div className="flex flex-wrap gap-1.5">
              {ingredients.map((ing, i) => (
                <span
                  key={i}
                  className="flex items-center gap-1 rounded-full border border-border bg-card px-2.5 py-1 text-xs font-semibold text-textStrong"
                >
                  {ing}
                  <button
                    type="button"
                    onClick={() => setIngredients((prev) => prev.filter((_, j) => j !== i))}
                    className="ml-0.5 text-muted hover:text-textStrong cursor-pointer leading-none"
                    aria-label={`${ing} malzemesini kaldır`}
                  >
                    ×
                  </button>
                </span>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Allerjen seçici */}
      <div className="flex flex-col gap-2">
        <p className="text-xs font-bold text-muted">Alerjenler (Tarım Bakanlığı zorunlu)</p>
        <div className="grid grid-cols-2 gap-1.5">
          {ALLERGEN_LIST.map(({ code, labelTr }) => {
            const active = selectedAllergens.has(code);
            return (
              <button
                key={code}
                type="button"
                onClick={() => toggleAllergen(code)}
                className={`flex items-center gap-2 rounded-xl border px-3 py-2 text-xs font-bold text-left cursor-pointer transition-colors ${
                  active
                    ? 'border-primary bg-primary/10 text-textStrong'
                    : 'border-border bg-card text-muted hover:bg-bg'
                }`}
              >
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src={`/allergens/allergen_${code}.svg`} alt="" width={16} height={16} className="shrink-0" />
                <span>{labelTr}</span>
              </button>
            );
          })}
        </div>
      </div>

      {formError && <p className="text-xs font-bold text-red-600">{formError}</p>}

      <div className="flex gap-2">
        <button
          type="submit"
          disabled={isPending}
          className="rounded-xl bg-primary px-3 py-2 text-xs font-bold text-white disabled:opacity-60 cursor-pointer"
        >
          {isPending ? 'Kaydediliyor...' : submitLabel}
        </button>
        <button
          type="button"
          onClick={onCancel}
          className="rounded-xl border border-border px-3 py-2 text-xs font-bold text-textStrong cursor-pointer"
        >
          İptal
        </button>
      </div>
    </form>
  );
}

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
  const [editingSectionId, setEditingSectionId] = useState<string | null>(null);
  const [addItemSectionId, setAddItemSectionId] = useState<string | null>(null);
  const [editingItemId, setEditingItemId] = useState<string | null>(null);
  const [showNewSection, setShowNewSection] = useState(false);
  const [showTitleEdit, setShowTitleEdit] = useState(false);

  const sections = initSections;
  const items = initItems;

  function itemsFor(sectionId: string) {
    return items
      .filter((i) => i.section_id === sectionId)
      .sort((a, b) => a.sort_order - b.sort_order);
  }

  async function run(action: () => Promise<{ error: string } | null>) {
    setError(null);
    startTransition(async () => {
      const result = await action();
      if (result?.error) setError(result.error);
    });
  }

  return (
    <div className="flex flex-col gap-6">
      {/* Menü başlığı + yayın kontrolleri */}
      <div className="flex flex-wrap items-center gap-3 rounded-2xl border border-border bg-card p-4">
        {showTitleEdit ? (
          <form
            className="flex items-center gap-2 flex-1"
            onSubmit={(e) => {
              e.preventDefault();
              const fd = new FormData(e.currentTarget);
              const title = String(fd.get('title') ?? '');
              run(() => updateMenuTitle(menuId, title));
              setShowTitleEdit(false);
            }}
          >
            <input
              name="title"
              defaultValue={initialTitle}
              required
              className="flex-1 rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30"
            />
            <button
              type="submit"
              className="rounded-xl bg-primary px-3 py-2 text-xs font-bold text-white cursor-pointer"
            >
              Kaydet
            </button>
            <button
              type="button"
              onClick={() => setShowTitleEdit(false)}
              className="rounded-xl border border-border px-3 py-2 text-xs font-bold text-textStrong cursor-pointer"
            >
              İptal
            </button>
          </form>
        ) : (
          <>
            <span className="font-bold text-textStrong flex-1">{initialTitle}</span>
            <button
              onClick={() => setShowTitleEdit(true)}
              className="rounded-xl border border-border px-3 py-1.5 text-xs font-bold text-textStrong hover:bg-bg cursor-pointer"
            >
              Başlığı Düzenle
            </button>
          </>
        )}
        <div className="flex items-center gap-2">
          {initialStatus !== 'published' && (
            <button
              onClick={() => run(() => publishMenu(menuId, 'published'))}
              disabled={isPending}
              className="rounded-xl bg-green-600 px-3 py-1.5 text-xs font-bold text-white disabled:opacity-60 cursor-pointer"
            >
              Yayınla
            </button>
          )}
          {initialStatus === 'published' && (
            <button
              onClick={() => run(() => publishMenu(menuId, 'draft'))}
              disabled={isPending}
              className="rounded-xl border border-amber-300 bg-amber-50 px-3 py-1.5 text-xs font-bold text-amber-700 disabled:opacity-60 cursor-pointer"
            >
              Taslağa Al
            </button>
          )}
          {initialStatus !== 'archived' && (
            <button
              onClick={() => run(() => publishMenu(menuId, 'archived'))}
              disabled={isPending}
              className="rounded-xl border border-border px-3 py-1.5 text-xs font-bold text-muted hover:bg-bg disabled:opacity-60 cursor-pointer"
            >
              Arşivle
            </button>
          )}
        </div>
      </div>

      {error && (
        <div className="rounded-xl bg-red-50 px-4 py-3 text-sm text-red-700">{error}</div>
      )}

      {/* Bölümler */}
      {sections.map((section) => (
        <div key={section.id} className="rounded-2xl border border-border bg-card">
          {/* Bölüm başlığı */}
          <div className="flex items-center justify-between border-b border-border px-5 py-3">
            {editingSectionId === section.id ? (
              <form
                className="flex flex-1 items-center gap-2"
                onSubmit={(e) => {
                  e.preventDefault();
                  const fd = new FormData(e.currentTarget);
                  const title = String(fd.get('title') ?? '');
                  run(() => updateSection(section.id, menuId, title));
                  setEditingSectionId(null);
                }}
              >
                <input
                  name="title"
                  defaultValue={section.title}
                  required
                  className="flex-1 rounded-xl border border-border bg-bg px-3 py-1.5 text-sm text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30"
                />
                <button
                  type="submit"
                  className="rounded-xl bg-primary px-3 py-1.5 text-xs font-bold text-white cursor-pointer"
                >
                  Kaydet
                </button>
                <button
                  type="button"
                  onClick={() => setEditingSectionId(null)}
                  className="rounded-xl border border-border px-3 py-1.5 text-xs font-bold text-textStrong cursor-pointer"
                >
                  İptal
                </button>
              </form>
            ) : (
              <>
                <span className="font-extrabold text-textStrong">{section.title}</span>
                <div className="flex items-center gap-1.5">
                  <button
                    onClick={() => setEditingSectionId(section.id)}
                    className="rounded-lg border border-border px-2.5 py-1 text-[11px] font-bold text-muted hover:bg-bg cursor-pointer"
                  >
                    Düzenle
                  </button>
                  <button
                    onClick={() => {
                      if (confirm(`"${section.title}" bölümünü sil?`))
                        run(() => deleteSection(section.id, menuId));
                    }}
                    className="rounded-lg border border-red-200 px-2.5 py-1 text-[11px] font-bold text-red-600 hover:bg-red-50 cursor-pointer"
                  >
                    Sil
                  </button>
                </div>
              </>
            )}
          </div>

          {/* Ürünler */}
          <div className="divide-y divide-border">
            {itemsFor(section.id).map((item) => (
              <div key={item.id}>
                {editingItemId === item.id ? (
                  <ItemForm
                    menuId={menuId}
                    sectionId={section.id}
                    businessId={businessId}
                    itemId={item.id}
                    initialValues={{
                      name: item.name,
                      description: item.description,
                      image_url: item.image_url,
                      price_cents: item.price_cents,
                      is_available: item.is_available,
                      calories_min: item.calories_min,
                      portion_size: item.portion_size,
                      portion_unit: item.portion_unit,
                    }}
                    initialAllergens={allergenMap[item.id] ?? []}
                    initialIngredients={ingredientMap[item.id] ?? []}
                    submitLabel="Kaydet"
                    onSuccess={() => setEditingItemId(null)}
                    onCancel={() => setEditingItemId(null)}
                  />
                ) : (
                  <div className="flex items-center gap-4 px-5 py-3">
                    {item.image_url ? (
                      <Image
                        src={item.image_url}
                        alt={item.name}
                        width={48}
                        height={48}
                        className="h-12 w-12 shrink-0 rounded-xl object-cover"
                        unoptimized
                      />
                    ) : (
                      <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl border border-dashed border-border bg-bg text-[10px] font-extrabold text-muted">
                        Görsel
                      </div>
                    )}
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2">
                        <span className="font-semibold text-textStrong">{item.name}</span>
                        {!item.is_available && (
                          <span className="rounded-full bg-zinc-100 px-1.5 py-0.5 text-[10px] font-bold text-zinc-500">
                            Stok Dışı
                          </span>
                        )}
                        {(allergenMap[item.id]?.length ?? 0) > 0 && (
                          <span className="rounded-full border border-border bg-bg px-1.5 py-0.5 text-[10px] font-bold text-muted">
                            {allergenMap[item.id].length} alerjen
                          </span>
                        )}
                      </div>
                      {item.description && (
                        <p className="mt-0.5 text-[12px] text-muted truncate max-w-xs">
                          {item.description}
                        </p>
                      )}
                    </div>
                    <span className="shrink-0 font-bold text-textStrong">
                      {formatPrice(item.price_cents)}
                    </span>
                    <div className="flex items-center gap-1.5 shrink-0">
                      <button
                        onClick={() => setEditingItemId(item.id)}
                        className="rounded-lg border border-border px-2.5 py-1 text-[11px] font-bold text-muted hover:bg-bg cursor-pointer"
                      >
                        Düzenle
                      </button>
                      <button
                        onClick={() => {
                          if (confirm(`"${item.name}" ürününü sil?`))
                            run(() => deleteItem(item.id, menuId));
                        }}
                        className="rounded-lg border border-red-200 px-2.5 py-1 text-[11px] font-bold text-red-600 hover:bg-red-50 cursor-pointer"
                      >
                        Sil
                      </button>
                    </div>
                  </div>
                )}
              </div>
            ))}
          </div>

          {/* Ürün ekle */}
          {addItemSectionId === section.id ? (
            <div className="border-t border-border">
              <ItemForm
                menuId={menuId}
                sectionId={section.id}
                businessId={businessId}
                initialAllergens={[]}
                initialIngredients={[]}
                submitLabel="Ürün Ekle"
                onSuccess={() => setAddItemSectionId(null)}
                onCancel={() => setAddItemSectionId(null)}
              />
            </div>
          ) : (
            <div className="border-t border-border px-5 py-3">
              <button
                onClick={() => setAddItemSectionId(section.id)}
                className="text-sm font-bold text-primary hover:underline cursor-pointer"
              >
                + Ürün Ekle
              </button>
            </div>
          )}
        </div>
      ))}

      {/* Yeni bölüm formu */}
      {showNewSection ? (
        <form
          className="rounded-2xl border border-dashed border-border bg-card p-5 flex flex-col gap-3"
          onSubmit={(e) => {
            e.preventDefault();
            const fd = new FormData(e.currentTarget);
            const title = String(fd.get('title') ?? '');
            run(() => createSection(menuId, title, sections.length));
            setShowNewSection(false);
          }}
        >
          <Input
            label="Bölüm Adı"
            name="title"
            required
            placeholder="Ör: Başlangıçlar, Ana Yemekler…"
          />
          <div className="flex gap-2">
            <button
              type="submit"
              disabled={isPending}
              className="rounded-xl bg-primary px-3 py-2 text-sm font-bold text-white disabled:opacity-60 cursor-pointer"
            >
              Bölüm Oluştur
            </button>
            <button
              type="button"
              onClick={() => setShowNewSection(false)}
              className="rounded-xl border border-border px-3 py-2 text-sm font-bold text-textStrong cursor-pointer"
            >
              İptal
            </button>
          </div>
        </form>
      ) : (
        <button
          onClick={() => setShowNewSection(true)}
          className="flex items-center justify-center gap-2 rounded-2xl border border-dashed border-border bg-card px-5 py-4 text-sm font-bold text-muted hover:border-primary/40 hover:text-primary transition-colors cursor-pointer"
        >
          <span className="text-lg">+</span> Yeni Bölüm Ekle
        </button>
      )}
    </div>
  );
}
