'use client';

import Image from 'next/image';
import { useState, useTransition } from 'react';
import { buildMenuImageUrl } from '@/src/lib/media-url';
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
  type AllergenEntry,
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

const DIETARY_FLAGS = [
  { key: 'diet_vegan',       label: 'Vegan',      icon: '🌱', detectedTags: ['vegan'] },
  { key: 'diet_vegetarian',  label: 'Vejetaryen', icon: '🥗', detectedTags: ['vegetarian', 'vejetaryen'] },
  { key: 'diet_glutenfree',  label: 'Glutensiz',  icon: '🌾', detectedTags: ['glutensiz', 'gluten_free'] },
  { key: 'diet_lactosefree', label: 'Laktossuz',  icon: '🥛', detectedTags: ['laktossuz', 'lactose_free'] },
  { key: 'diet_halal',       label: 'Helal',      icon: '☪️', detectedTags: ['halal'] },
];

const DIETARY_TAG_VALUES = new Set(DIETARY_FLAGS.flatMap((f) => f.detectedTags));

function getDietaryFromTags(tags: string[] | null): Record<string, boolean> {
  const set = new Set((tags ?? []).map((t) => t.toLowerCase()));
  return Object.fromEntries(
    DIETARY_FLAGS.map((f) => [f.key, f.detectedTags.some((t) => set.has(t))]),
  );
}

function getCustomTags(tags: string[] | null) {
  return (tags ?? []).filter((t) => !DIETARY_TAG_VALUES.has(t.toLowerCase())).join(', ');
}

function getDietaryBadges(tags: string[] | null) {
  const d = getDietaryFromTags(tags);
  return DIETARY_FLAGS.filter((f) => d[f.key]);
}

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
  tags: string[] | null;
  calories_min: number | null;
  calories_max: number | null;
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
      <label className="text-xs font-[700] text-muted">{label}</label>
      <input
        name={name}
        type={type}
        defaultValue={defaultValue}
        required={required}
        placeholder={placeholder}
        className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30"
      />
    </div>
  );
}

function SectionLabel({ children }: { children: React.ReactNode }) {
  return <p className="mb-3 text-[10px] font-[800] uppercase tracking-wider text-muted">{children}</p>;
}

function SectionDivider() {
  return <hr className="border-border" />;
}

function ItemFormModal({
  title,
  onClose,
  children,
}: {
  title: string;
  onClose: () => void;
  children: React.ReactNode;
}) {
  return (
    <>
      <div className="fixed inset-0 z-40 bg-black/50 backdrop-blur-[2px]" onClick={onClose} />
      <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
        <div className="flex max-h-[90vh] w-full max-w-2xl flex-col rounded-2xl bg-card shadow-lg">
          <div className="flex shrink-0 items-center justify-between rounded-t-2xl border-b border-border px-6 py-4">
            <h2 className="text-base font-[900] text-textStrong">{title}</h2>
            <button
              type="button"
              onClick={onClose}
              className="flex h-8 w-8 cursor-pointer items-center justify-center rounded-xl border border-border text-muted hover:bg-bg"
            >
              <XIcon />
            </button>
          </div>
          {children}
        </div>
      </div>
    </>
  );
}

function XIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
      <path d="M18 6 6 18M6 6l12 12" />
    </svg>
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
  const [isDragOver, setIsDragOver] = useState(false);

  async function upload(file: File | null) {
    if (!file) return;
    if (!file.type.startsWith('image/')) {
      setUploadError('Sadece görsel dosyası yükleyebilirsiniz.');
      return;
    }
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

  // Önizleme Supabase transform kullanır: yeniden boyutlandırma + kalite + otomatik WebP
  const previewSrc = buildMenuImageUrl(url, { width: 400, quality: 80 }) ?? url;

  return (
    <div
      onDragOver={(e) => { e.preventDefault(); setIsDragOver(true); }}
      onDragLeave={() => setIsDragOver(false)}
      onDrop={(e) => {
        e.preventDefault();
        setIsDragOver(false);
        const file = e.dataTransfer.files[0];
        if (file) upload(file);
      }}
      className={`grid gap-3 rounded-xl border p-3 sm:grid-cols-[96px_1fr] transition-colors ${
        isDragOver ? 'border-primary bg-primary/5' : 'border-border bg-bg'
      }`}
    >
      <div className="relative flex h-24 w-24 items-center justify-center overflow-hidden rounded-xl border border-border bg-card text-[11px] font-[800] text-muted">
        {url ? (
          <Image src={previewSrc} alt="" fill sizes="96px" className="object-cover" unoptimized />
        ) : (
          'Görsel yok'
        )}
      </div>
      <div className="flex min-w-0 flex-col gap-2">
        <input type="hidden" name="imageUrl" value={url} />
        <label className="text-xs font-[700] text-muted">{label}</label>
        <input
          type="url"
          value={url}
          onChange={(event) => setUrl(event.target.value)}
          placeholder="https://... veya görseli sürükleyip bırakın"
          className="rounded-xl border border-border bg-card px-3 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30"
        />
        <div className="flex flex-wrap items-center gap-2">
          <label className="inline-flex min-h-10 cursor-pointer items-center rounded-xl border border-border bg-card px-3 py-2 text-xs font-[800] text-textStrong hover:bg-white">
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
              className="min-h-10 rounded-xl border border-border px-3 py-2 text-xs font-[800] text-muted hover:bg-card"
            >
              Kaldır
            </button>
          )}
          {uploadError && <span className="text-xs font-[700] text-red-600">{uploadError}</span>}
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
    currency: string;
    is_available: boolean;
    tags: string[] | null;
    calories_min: number | null;
    calories_max: number | null;
    portion_size: number | null;
    portion_unit: string | null;
  };
  initialAllergens: AllergenEntry[];
  initialIngredients: string[];
  submitLabel: string;
  onSuccess: () => void;
  onCancel: () => void;
}) {
  const [isPending, startTransition] = useTransition();
  const [formError, setFormError] = useState<string | null>(null);
  const [dietaryState, setDietaryState] = useState<Record<string, boolean>>(
    getDietaryFromTags(initialValues?.tags ?? null),
  );
  const [allergenState, setAllergenState] = useState<Record<string, 'contains' | 'may_contain' | null>>(
    Object.fromEntries(initialAllergens.map((a) => [a.allergen, a.risk_level])),
  );
  const [ingredients, setIngredients] = useState<string[]>(initialIngredients);
  const [ingredientInput, setIngredientInput] = useState('');

  function toggleAllergen(code: string) {
    setAllergenState((prev) => {
      const cur = prev[code] ?? null;
      const next: 'contains' | 'may_contain' | null =
        cur === null ? 'contains' : cur === 'contains' ? 'may_contain' : null;
      return { ...prev, [code]: next };
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
        const allergenEntries: AllergenEntry[] = Object.entries(allergenState)
          .filter(([, level]) => level !== null)
          .map(([allergen, level]) => ({ allergen, risk_level: level as 'contains' | 'may_contain' }));

        const allergenResult = await upsertItemAllergens(resolvedId, menuId, allergenEntries);
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
    <form className="flex flex-1 flex-col overflow-hidden" onSubmit={handleSubmit}>
      <div className="flex flex-1 flex-col gap-6 overflow-y-auto px-6 py-5">

        {/* Temel Bilgiler */}
        <section>
          <SectionLabel>Temel Bilgiler</SectionLabel>
          <div className="flex flex-col gap-3">
            <Input
              label="Ürün Adı"
              name="name"
              defaultValue={initialValues?.name ?? ''}
              required
              placeholder="Ürün adı"
            />
            <div className="grid grid-cols-2 gap-3">
              <Input
                label="Fiyat (₺)"
                name="price"
                type="number"
                defaultValue={initialValues ? String(initialValues.price_cents / 100) : ''}
                required
                placeholder="0.00"
              />
              <div className="flex flex-col gap-1">
                <label className="text-xs font-[700] text-muted">Para Birimi</label>
                <select
                  name="currency"
                  defaultValue={initialValues?.currency ?? 'TRY'}
                  className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/30"
                >
                  <option value="TRY">TRY (₺)</option>
                  <option value="USD">USD ($)</option>
                  <option value="EUR">EUR (€)</option>
                </select>
              </div>
            </div>
            <div className="flex flex-col gap-1">
              <label className="text-xs font-[700] text-muted">Açıklama (opsiyonel)</label>
              <textarea
                name="description"
                defaultValue={initialValues?.description ?? ''}
                placeholder="Kısa açıklama"
                rows={2}
                className="resize-y rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30"
              />
            </div>
            <label className="flex cursor-pointer items-center gap-2.5 rounded-xl border border-border px-3 py-2">
              <input
                type="checkbox"
                name="is_available"
                defaultChecked={initialValues?.is_available ?? true}
                className="h-4 w-4 rounded accent-primary"
              />
              <span className="text-sm font-[700] text-textStrong">Satışta (aktif)</span>
            </label>
          </div>
        </section>

        <SectionDivider />

        {/* Görsel */}
        <section>
          <SectionLabel>Görsel</SectionLabel>
          <ImageUrlField
            businessId={businessId}
            label="Ürün görseli"
            initialUrl={initialValues?.image_url ?? null}
          />
        </section>

        <SectionDivider />

        {/* Diyet & Etiketler */}
        <section>
          <SectionLabel>Diyet & Etiketler</SectionLabel>
          {DIETARY_FLAGS.map((flag) => (
            <input
              key={flag.key}
              type="checkbox"
              name={flag.key}
              checked={dietaryState[flag.key] ?? false}
              onChange={() => {}}
              className="hidden"
            />
          ))}
          <div className="flex flex-wrap gap-2">
            {DIETARY_FLAGS.map((flag) => (
              <button
                key={flag.key}
                type="button"
                onClick={() => setDietaryState((p) => ({ ...p, [flag.key]: !p[flag.key] }))}
                className={`flex cursor-pointer items-center gap-1.5 rounded-full border px-3 py-1.5 text-[12px] font-[700] transition-colors ${
                  dietaryState[flag.key]
                    ? 'border-primary bg-primary/10 text-textStrong'
                    : 'border-border bg-card text-muted hover:bg-bg'
                }`}
              >
                <span>{flag.icon}</span>{flag.label}
              </button>
            ))}
          </div>
          <div className="mt-3">
            <Input
              label="Ek Etiketler (virgülle ayırın)"
              name="custom_tags"
              defaultValue={getCustomTags(initialValues?.tags ?? null)}
              placeholder="organik, ev yapımı, spesyalite…"
            />
          </div>
        </section>

        <SectionDivider />

        {/* Alerjenler */}
        <section>
          <SectionLabel>Alerjenler — AB Zorunlu 14</SectionLabel>
          <p className="mb-3 text-[11px] text-muted">
            Dokunarak döngü: <span className="font-[700] text-primary">İçerir</span>
            {' → '}<span className="font-[700] text-orange-500">İz İçerebilir</span>{' → '}Yok
          </p>
          <div className="grid grid-cols-2 gap-1.5">
            {ALLERGEN_LIST.map(({ code, labelTr }) => {
              const state = allergenState[code] ?? null;
              return (
                <button
                  key={code}
                  type="button"
                  onClick={() => toggleAllergen(code)}
                  className={`flex cursor-pointer items-center gap-2 rounded-xl border px-3 py-2 text-left text-xs font-[700] transition-colors ${
                    state === 'contains'
                      ? 'border-primary bg-primary/10 text-textStrong'
                      : state === 'may_contain'
                        ? 'border-orange-400 bg-orange-50 text-orange-700'
                        : 'border-border bg-card text-muted hover:bg-bg'
                  }`}
                >
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img src={`/allergens/allergen_${code}.svg`} alt="" width={16} height={16} className="shrink-0" />
                  <span className="flex-1">{labelTr}</span>
                  {state === 'contains' && <span className="text-[9px] font-[900]">✓</span>}
                  {state === 'may_contain' && <span className="text-[9px] font-[900]">~</span>}
                </button>
              );
            })}
          </div>
        </section>

        <SectionDivider />

        {/* Kalori, Porsiyon & Malzemeler */}
        <section>
          <SectionLabel>Kalori, Porsiyon & Malzemeler</SectionLabel>
          <div className="grid grid-cols-2 gap-3">
            <div className="flex flex-col gap-1">
              <label className="text-xs font-[700] text-muted">Min Kalori (kcal)</label>
              <input
                name="calories_min"
                type="number"
                defaultValue={initialValues?.calories_min ?? ''}
                min="0"
                max="9999"
                placeholder="örn: 320"
                className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30"
              />
            </div>
            <div className="flex flex-col gap-1">
              <label className="text-xs font-[700] text-muted">Max Kalori (kcal)</label>
              <input
                name="calories_max"
                type="number"
                defaultValue={initialValues?.calories_max ?? ''}
                min="0"
                max="9999"
                placeholder="örn: 420"
                className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30"
              />
            </div>
          </div>
          <div className="mt-3 grid grid-cols-2 gap-3">
            <div className="flex flex-col gap-1">
              <label className="text-xs font-[700] text-muted">Porsiyon Miktarı</label>
              <input
                name="portion_size"
                type="number"
                defaultValue={initialValues?.portion_size ?? ''}
                min="0"
                placeholder="örn: 350"
                className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30"
              />
            </div>
            <div className="flex flex-col gap-1">
              <label className="text-xs font-[700] text-muted">Birim</label>
              <select
                name="portion_unit"
                defaultValue={initialValues?.portion_unit ?? ''}
                className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/30"
              >
                <option value="">Birim</option>
                <option value="g">g</option>
                <option value="ml">ml</option>
                <option value="adet">adet</option>
                <option value="dilim">dilim</option>
              </select>
            </div>
          </div>

          {/* Malzemeler — tag-style input (sahip'e özgü) */}
          <div className="mt-3 flex flex-col gap-2">
            <label className="text-xs font-[700] text-muted">Malzemeler</label>
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
                className="flex-1 rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30"
              />
              <button
                type="button"
                onClick={addIngredient}
                className="cursor-pointer rounded-xl border border-border bg-bg px-3 py-2 text-xs font-[700] text-textStrong hover:bg-card"
              >
                Ekle
              </button>
            </div>
            {ingredients.length > 0 && (
              <div className="flex flex-wrap gap-1.5">
                {ingredients.map((ing, i) => (
                  <span
                    key={i}
                    className="flex items-center gap-1 rounded-full border border-border bg-card px-2.5 py-1 text-xs font-[600] text-textStrong"
                  >
                    {ing}
                    <button
                      type="button"
                      onClick={() => setIngredients((prev) => prev.filter((_, j) => j !== i))}
                      className="ml-0.5 cursor-pointer leading-none text-muted hover:text-textStrong"
                      aria-label={`${ing} malzemesini kaldır`}
                    >
                      ×
                    </button>
                  </span>
                ))}
              </div>
            )}
          </div>
        </section>
      </div>

      {/* Sabit alt buton çubuğu */}
      <div className="shrink-0 rounded-b-2xl border-t border-border bg-card px-6 py-4">
        {formError && (
          <p className="mb-3 rounded-xl bg-red-50 px-3 py-2 text-xs font-[700] text-red-700">{formError}</p>
        )}
        <div className="flex items-center justify-end gap-3">
          <button
            type="button"
            onClick={onCancel}
            className="cursor-pointer rounded-xl border border-border px-4 py-2 text-sm font-[700] text-textStrong hover:bg-bg"
          >
            İptal
          </button>
          <button
            type="submit"
            disabled={isPending}
            className="btn-primary cursor-pointer rounded-xl px-5 py-2 text-sm font-[700] text-white shadow-sm transition hover:opacity-90 disabled:opacity-60"
          >
            {isPending ? 'Kaydediliyor…' : submitLabel}
          </button>
        </div>
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
  allergenMap: Record<string, AllergenEntry[]>;
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
              className="flex-1 rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/30"
            />
            <button
              type="submit"
              className="rounded-xl bg-primary px-3 py-2 text-xs font-[700] text-white cursor-pointer"
            >
              Kaydet
            </button>
            <button
              type="button"
              onClick={() => setShowTitleEdit(false)}
              className="rounded-xl border border-border px-3 py-2 text-xs font-[700] text-textStrong cursor-pointer"
            >
              İptal
            </button>
          </form>
        ) : (
          <>
            <span className="font-[700] text-textStrong flex-1">{initialTitle}</span>
            <button
              onClick={() => setShowTitleEdit(true)}
              className="rounded-xl border border-border px-3 py-1.5 text-xs font-[700] text-textStrong hover:bg-bg cursor-pointer"
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
              className="rounded-xl bg-green-600 px-3 py-1.5 text-xs font-[700] text-white disabled:opacity-60 cursor-pointer"
            >
              Yayınla
            </button>
          )}
          {initialStatus === 'published' && (
            <button
              onClick={() => run(() => publishMenu(menuId, 'draft'))}
              disabled={isPending}
              className="rounded-xl border border-amber-300 bg-amber-50 px-3 py-1.5 text-xs font-[700] text-amber-700 disabled:opacity-60 cursor-pointer"
            >
              Taslağa Al
            </button>
          )}
          {initialStatus !== 'archived' && (
            <button
              onClick={() => run(() => publishMenu(menuId, 'archived'))}
              disabled={isPending}
              className="rounded-xl border border-border px-3 py-1.5 text-xs font-[700] text-muted hover:bg-bg disabled:opacity-60 cursor-pointer"
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
                  className="flex-1 rounded-xl border border-border bg-bg px-3 py-1.5 text-sm text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/30"
                />
                <button
                  type="submit"
                  className="rounded-xl bg-primary px-3 py-1.5 text-xs font-[700] text-white cursor-pointer"
                >
                  Kaydet
                </button>
                <button
                  type="button"
                  onClick={() => setEditingSectionId(null)}
                  className="rounded-xl border border-border px-3 py-1.5 text-xs font-[700] text-textStrong cursor-pointer"
                >
                  İptal
                </button>
              </form>
            ) : (
              <>
                <span className="font-[800] text-textStrong">{section.title}</span>
                <div className="flex items-center gap-1.5">
                  <button
                    onClick={() => setEditingSectionId(section.id)}
                    className="rounded-lg border border-border px-2.5 py-1 text-[11px] font-[700] text-muted hover:bg-bg cursor-pointer"
                  >
                    Düzenle
                  </button>
                  <button
                    onClick={() => {
                      if (confirm(`"${section.title}" bölümünü sil?`))
                        run(() => deleteSection(section.id, menuId));
                    }}
                    className="rounded-lg border border-red-200 px-2.5 py-1 text-[11px] font-[700] text-red-600 hover:bg-red-50 cursor-pointer"
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
                  <ItemFormModal title="Ürünü Düzenle" onClose={() => setEditingItemId(null)}>
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
                        currency: item.currency,
                        is_available: item.is_available,
                        tags: item.tags,
                        calories_min: item.calories_min,
                        calories_max: item.calories_max,
                        portion_size: item.portion_size,
                        portion_unit: item.portion_unit,
                      }}
                      initialAllergens={allergenMap[item.id] ?? []}
                      initialIngredients={ingredientMap[item.id] ?? []}
                      submitLabel="Kaydet"
                      onSuccess={() => setEditingItemId(null)}
                      onCancel={() => setEditingItemId(null)}
                    />
                  </ItemFormModal>
                ) : null}
                {(
                  <div className="flex items-center gap-4 px-5 py-3">
                    {item.image_url ? (
                      <Image
                        src={buildMenuImageUrl(item.image_url, { width: 96, quality: 70 }) ?? item.image_url}
                        alt={item.name}
                        width={48}
                        height={48}
                        className="h-12 w-12 shrink-0 rounded-xl object-cover"
                        unoptimized
                      />
                    ) : (
                      <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl border border-dashed border-border bg-bg text-[10px] font-[800] text-muted">
                        Görsel
                      </div>
                    )}
                    <div className="flex-1 min-w-0">
                      <div className="flex flex-wrap items-center gap-1.5">
                        <span className="font-[600] text-textStrong">{item.name}</span>
                        {!item.is_available && (
                          <span className="rounded-full bg-zinc-100 px-1.5 py-0.5 text-[10px] font-[700] text-zinc-500">
                            Stok Dışı
                          </span>
                        )}
                        {getDietaryBadges(item.tags).map((d) => (
                          <span key={d.key} title={d.label} className="text-[13px] leading-none">{d.icon}</span>
                        ))}
                        {(allergenMap[item.id]?.length ?? 0) > 0 && (
                          <span className="rounded-full border border-border bg-bg px-1.5 py-0.5 text-[10px] font-[700] text-muted">
                            {allergenMap[item.id].length} alerjen
                          </span>
                        )}
                      </div>
                      {item.description && (
                        <p className="mt-0.5 text-[12px] text-muted truncate max-w-xs">
                          {item.description}
                        </p>
                      )}
                      {(item.calories_min || item.calories_max) && (
                        <p className="mt-0.5 text-[11px] text-muted">
                          {item.calories_min && item.calories_max && item.calories_min !== item.calories_max
                            ? `${item.calories_min}–${item.calories_max} kcal`
                            : `${item.calories_min ?? item.calories_max} kcal`}
                        </p>
                      )}
                    </div>
                    <span className="shrink-0 font-[700] text-textStrong">
                      {formatPrice(item.price_cents)}
                    </span>
                    <div className="flex items-center gap-1.5 shrink-0">
                      <button
                        onClick={() => setEditingItemId(item.id)}
                        className="rounded-lg border border-border px-2.5 py-1 text-[11px] font-[700] text-muted hover:bg-bg cursor-pointer"
                      >
                        Düzenle
                      </button>
                      <button
                        onClick={() => {
                          if (confirm(`"${item.name}" ürününü sil?`))
                            run(() => deleteItem(item.id, menuId));
                        }}
                        className="rounded-lg border border-red-200 px-2.5 py-1 text-[11px] font-[700] text-red-600 hover:bg-red-50 cursor-pointer"
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
          {addItemSectionId === section.id && (
            <ItemFormModal title="Yeni Ürün Ekle" onClose={() => setAddItemSectionId(null)}>
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
            </ItemFormModal>
          )}
          <div className="border-t border-border px-5 py-3">
            <button
              onClick={() => setAddItemSectionId(section.id)}
              className="text-sm font-[700] text-primary hover:underline cursor-pointer"
            >
              + Ürün Ekle
            </button>
          </div>
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
              className="rounded-xl bg-primary px-3 py-2 text-sm font-[700] text-white disabled:opacity-60 cursor-pointer"
            >
              Bölüm Oluştur
            </button>
            <button
              type="button"
              onClick={() => setShowNewSection(false)}
              className="rounded-xl border border-border px-3 py-2 text-sm font-[700] text-textStrong cursor-pointer"
            >
              İptal
            </button>
          </div>
        </form>
      ) : (
        <button
          onClick={() => setShowNewSection(true)}
          className="flex items-center justify-center gap-2 rounded-2xl border border-dashed border-border bg-card px-5 py-4 text-sm font-[700] text-muted hover:border-primary/40 hover:text-primary transition-colors cursor-pointer"
        >
          <span className="text-lg">+</span> Yeni Bölüm Ekle
        </button>
      )}
    </div>
  );
}
