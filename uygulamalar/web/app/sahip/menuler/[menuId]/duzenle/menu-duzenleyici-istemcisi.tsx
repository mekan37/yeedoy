'use client';

import Image from 'next/image';
import Link from 'next/link';
import { useState, useTransition } from 'react';
import { buildMenuImageUrl } from '@/src/lib/media-url';
import {
  createSection,
  upsertItem,
  deleteItem,
  publishMenu,
  updateMenuTitle,
  upsertItemAllergens,
  upsertItemIngredients,
  type AllergenEntry,
} from '../menu-islemleri';

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
  updated_at: string;
};

export const CATEGORY_BADGE_COLORS = [
  'bg-blue-50 text-blue-700',
  'bg-green-50 text-green-700',
  'bg-purple-50 text-purple-700',
  'bg-orange-50 text-orange-700',
  'bg-pink-50 text-pink-700',
  'bg-teal-50 text-teal-700',
];

export function categoryBadgeColor(sectionIndex: number) {
  return CATEGORY_BADGE_COLORS[sectionIndex % CATEGORY_BADGE_COLORS.length];
}

function formatPrice(cents: number) {
  return (cents / 100).toLocaleString('tr-TR', { minimumFractionDigits: 2 }) + ' ₺';
}

function formatDateTr(iso: string) {
  return new Date(iso).toLocaleString('tr-TR', { day: 'numeric', month: 'long', year: 'numeric', hour: '2-digit', minute: '2-digit' });
}

function formatDateShortTr(iso: string) {
  return new Date(iso).toLocaleDateString('tr-TR', { day: 'numeric', month: 'short', year: 'numeric' });
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
  sections,
  initialSectionId,
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
  sections: Section[];
  initialSectionId: string;
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
            <div className="flex flex-col gap-1">
              <label className="text-xs font-[700] text-muted">Kategori</label>
              <select
                name="sectionId"
                defaultValue={initialSectionId}
                required
                className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/30"
              >
                {sections.map((section) => (
                  <option key={section.id} value={section.id}>{section.title}</option>
                ))}
              </select>
            </div>
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

function StatCard({
  icon,
  iconBg,
  label,
  value,
  subtitle,
}: {
  icon: React.ReactNode;
  iconBg: string;
  label: string;
  value: string;
  subtitle?: string;
}) {
  return (
    <div className="flex items-center gap-3 rounded-2xl border border-border bg-card p-4">
      <span className={`flex h-11 w-11 shrink-0 items-center justify-center rounded-xl ${iconBg}`}>{icon}</span>
      <div className="min-w-0">
        <p className="text-[11px] font-[700] uppercase tracking-wide text-muted">{label}</p>
        <p className="mt-0.5 truncate text-lg font-[900] text-textStrong">{value}</p>
        {subtitle && <p className="text-[11px] text-muted">{subtitle}</p>}
      </div>
    </div>
  );
}

function GridIcon() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="3" width="7" height="7" /><rect x="14" y="3" width="7" height="7" /><rect x="3" y="14" width="7" height="7" /><rect x="14" y="14" width="7" height="7" /></svg>;
}
function BoxIcon() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 8v13H3V8" /><path d="M1 3h22v5H1z" /><path d="M10 12h4" /></svg>;
}
function CheckCircleIcon() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" /><polyline points="22 4 12 14.01 9 11.01" /></svg>;
}
function PauseCircleIcon() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10" /><line x1="10" y1="9" x2="10" y2="15" /><line x1="14" y1="9" x2="14" y2="15" /></svg>;
}
function ClockIcon() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10" /><polyline points="12 6 12 12 16 14" /></svg>;
}
function SearchIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="11" cy="11" r="8" /><line x1="21" y1="21" x2="16.65" y2="16.65" /></svg>;
}
export function PencilIcon() {
  return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z" /></svg>;
}
export function TrashIcon() {
  return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="3 6 5 6 21 6" /><path d="M19 6l-1 14H6L5 6m5 0V4h4v2" /></svg>;
}
export function TagIcon() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M20.59 13.41 11 3.83A2 2 0 0 0 9.59 3.24L4 3v5.59a2 2 0 0 0 .59 1.41l9.58 9.59a2 2 0 0 0 2.82 0l3.6-3.6a2 2 0 0 0 0-2.82Z" /><circle cx="8.5" cy="8.5" r="1.5" /></svg>;
}
export function ChevronRightIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="9 18 15 12 9 6" /></svg>;
}

type SortKey = 'name_asc' | 'price_asc' | 'price_desc' | 'updated_desc';
type StatusFilter = 'all' | 'active' | 'inactive';

export function MenuEditorClient({
  menuId,
  businessId,
  initialTitle,
  initialStatus,
  sections: initSections,
  items: initItems,
  allergenMap,
  ingredientMap,
  menuUpdatedAt,
}: {
  menuId: string;
  businessId: string;
  initialTitle: string;
  initialStatus: 'draft' | 'published' | 'archived';
  sections: Section[];
  items: Item[];
  allergenMap: Record<string, AllergenEntry[]>;
  ingredientMap: Record<string, string[]>;
  menuUpdatedAt: string;
}) {
  const [isPending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);
  const [addItemOpen, setAddItemOpen] = useState(false);
  const [editingItemId, setEditingItemId] = useState<string | null>(null);
  const [showNewSection, setShowNewSection] = useState(false);
  const [showTitleEdit, setShowTitleEdit] = useState(false);
  const [activeTab, setActiveTab] = useState<string>('all');
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<StatusFilter>('all');
  const [sortBy, setSortBy] = useState<SortKey>('name_asc');

  const sections = initSections;
  const items = initItems;

  const sectionIndexMap = new Map(sections.map((s, i) => [s.id, i]));
  const sectionTitleMap = new Map(sections.map((s) => [s.id, s.title]));
  const effectiveActiveTab = activeTab !== 'all' && !sectionIndexMap.has(activeTab) ? 'all' : activeTab;

  const totalItems = items.length;
  const activeCount = items.filter((i) => i.is_available).length;
  const inactiveCount = totalItems - activeCount;
  const activePct = totalItems > 0 ? Math.round((activeCount / totalItems) * 100) : 0;
  const inactivePct = totalItems > 0 ? 100 - activePct : 0;
  const lastUpdatedIso = items.reduce((max, i) => (i.updated_at > max ? i.updated_at : max), menuUpdatedAt);

  const filteredItems = items
    .filter((i) => effectiveActiveTab === 'all' || i.section_id === effectiveActiveTab)
    .filter((i) => statusFilter === 'all' || (statusFilter === 'active' ? i.is_available : !i.is_available))
    .filter((i) => {
      const q = search.trim().toLowerCase();
      if (!q) return true;
      return i.name.toLowerCase().includes(q) || (i.description ?? '').toLowerCase().includes(q);
    })
    .sort((a, b) => {
      switch (sortBy) {
        case 'price_asc': return a.price_cents - b.price_cents;
        case 'price_desc': return b.price_cents - a.price_cents;
        case 'updated_desc': return b.updated_at.localeCompare(a.updated_at);
        default: return a.name.localeCompare(b.name, 'tr');
      }
    });

  const addItemDefaultSectionId = (effectiveActiveTab !== 'all' ? effectiveActiveTab : sections[0]?.id) ?? '';
  const previewItem = filteredItems[0] ?? items[0] ?? null;

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

      {/* İstatistikler */}
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-5">
        <StatCard icon={<GridIcon />} iconBg="bg-blue-50 text-blue-600" label="Toplam Bölüm" value={String(sections.length)} />
        <StatCard icon={<BoxIcon />} iconBg="bg-purple-50 text-purple-600" label="Toplam Ürün" value={String(totalItems)} />
        <StatCard
          icon={<CheckCircleIcon />}
          iconBg="bg-green-50 text-green-600"
          label="Aktif Ürün"
          value={String(activeCount)}
          subtitle={totalItems > 0 ? `%${activePct} aktif` : undefined}
        />
        <StatCard
          icon={<PauseCircleIcon />}
          iconBg="bg-orange-50 text-orange-600"
          label="Stok Dışı"
          value={String(inactiveCount)}
          subtitle={totalItems > 0 ? `%${inactivePct}` : undefined}
        />
        <StatCard icon={<ClockIcon />} iconBg="bg-zinc-100 text-zinc-600" label="Son Güncelleme" value={formatDateShortTr(lastUpdatedIso)} />
      </div>

      {sections.length === 0 ? (
        <div className="flex flex-col items-center justify-center gap-3 rounded-2xl border border-dashed border-border bg-card px-6 py-14 text-center">
          <p className="text-sm font-[700] text-textStrong">Henüz bölüm yok</p>
          <p className="max-w-sm text-xs text-muted">
            Ürün ekleyebilmek için önce en az bir bölüm (ör. Başlangıçlar, Ana Yemekler) oluşturun.
          </p>
          {showNewSection ? (
            <form
              className="flex w-full max-w-xs flex-col gap-2"
              onSubmit={(e) => {
                e.preventDefault();
                const fd = new FormData(e.currentTarget);
                const title = String(fd.get('title') ?? '');
                run(() => createSection(menuId, title, sections.length));
                setShowNewSection(false);
              }}
            >
              <input
                name="title"
                required
                autoFocus
                placeholder="Ör: Başlangıçlar"
                className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30"
              />
              <div className="flex gap-2">
                <button type="submit" disabled={isPending} className="flex-1 cursor-pointer rounded-xl bg-primary px-3 py-2 text-sm font-[700] text-white disabled:opacity-60">
                  Bölüm Oluştur
                </button>
                <button type="button" onClick={() => setShowNewSection(false)} className="cursor-pointer rounded-xl border border-border px-3 py-2 text-sm font-[700] text-textStrong">
                  İptal
                </button>
              </div>
            </form>
          ) : (
            <button onClick={() => setShowNewSection(true)} className="cursor-pointer rounded-xl bg-primary px-4 py-2 text-sm font-[700] text-white">
              + Yeni Bölüm Ekle
            </button>
          )}
        </div>
      ) : (
        <div className="grid gap-6 lg:grid-cols-[1fr_300px]">
          {/* Sol: sekmeler + araç çubuğu + ürün tablosu */}
          <div className="flex min-w-0 flex-col gap-4">
            {/* Kategori sekmeleri */}
            <div className="flex items-center gap-1 overflow-x-auto border-b border-border">
              <button
                onClick={() => setActiveTab('all')}
                className={`shrink-0 cursor-pointer border-b-2 px-3 py-2.5 text-sm font-[700] transition-colors ${
                  effectiveActiveTab === 'all' ? 'border-primary text-primary' : 'border-transparent text-muted hover:text-textStrong'
                }`}
              >
                Tümü <span className="text-muted">({totalItems})</span>
              </button>
              {sections.map((section) => (
                <button
                  key={section.id}
                  onClick={() => setActiveTab(section.id)}
                  className={`shrink-0 cursor-pointer border-b-2 px-3 py-2.5 text-sm font-[700] transition-colors ${
                    effectiveActiveTab === section.id ? 'border-primary text-primary' : 'border-transparent text-muted hover:text-textStrong'
                  }`}
                >
                  {section.title} <span className="text-muted">({items.filter((i) => i.section_id === section.id).length})</span>
                </button>
              ))}
            </div>

            {/* Araç çubuğu */}
            <div className="flex flex-wrap items-center gap-2">
              <div className="relative min-w-[180px] flex-1">
                <span className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-muted"><SearchIcon /></span>
                <input
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  placeholder="Ürün ara…"
                  className="w-full rounded-xl border border-border bg-card py-2 pl-9 pr-3 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30"
                />
              </div>
              <select
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value as StatusFilter)}
                className="rounded-xl border border-border bg-card px-3 py-2 text-sm text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/30"
              >
                <option value="all">Tüm Durumlar</option>
                <option value="active">Aktif</option>
                <option value="inactive">Stok Dışı</option>
              </select>
              <select
                value={sortBy}
                onChange={(e) => setSortBy(e.target.value as SortKey)}
                className="rounded-xl border border-border bg-card px-3 py-2 text-sm text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/30"
              >
                <option value="name_asc">İsme göre (A-Z)</option>
                <option value="price_asc">Fiyat (Artan)</option>
                <option value="price_desc">Fiyat (Azalan)</option>
                <option value="updated_desc">Son güncellenen</option>
              </select>
              <button
                onClick={() => setAddItemOpen(true)}
                className="btn-primary ml-auto cursor-pointer rounded-xl px-4 py-2 text-sm font-[700] text-white shadow-sm transition hover:opacity-90"
              >
                + Yeni Ürün Ekle
              </button>
            </div>

            {/* Ürün tablosu */}
            {filteredItems.length === 0 ? (
              <div className="flex flex-col items-center justify-center gap-2 rounded-2xl border border-dashed border-border bg-card px-6 py-14 text-center">
                <p className="text-sm font-[700] text-textStrong">
                  {totalItems === 0 ? 'Henüz ürün eklenmedi' : 'Filtrelere uyan ürün yok'}
                </p>
                <p className="max-w-sm text-xs text-muted">
                  {totalItems === 0
                    ? 'İlk ürününüzü ekleyerek menünüzü oluşturmaya başlayın.'
                    : 'Arama veya filtreleri değiştirmeyi deneyin.'}
                </p>
              </div>
            ) : (
              <div className="overflow-hidden rounded-2xl border border-border bg-card">
                <div className="overflow-x-auto">
                  <table className="w-full text-left text-sm">
                    <thead>
                      <tr className="border-b border-border bg-bg text-[11px] font-[800] uppercase tracking-wide text-muted">
                        <th className="px-4 py-3">Ürün</th>
                        <th className="px-4 py-3">Kategori</th>
                        <th className="px-4 py-3">Fiyat</th>
                        <th className="px-4 py-3">Durum</th>
                        <th className="px-4 py-3">Son Güncelleme</th>
                        <th className="px-4 py-3 text-right">İşlemler</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-border">
                      {filteredItems.map((item) => (
                        <tr key={item.id} className="align-middle hover:bg-bg/60">
                          <td className="px-4 py-3">
                            <div className="flex items-center gap-3">
                              {item.image_url ? (
                                <Image
                                  src={buildMenuImageUrl(item.image_url, { width: 96, quality: 70 }) ?? item.image_url}
                                  alt={item.name}
                                  width={40}
                                  height={40}
                                  className="h-10 w-10 shrink-0 rounded-lg object-cover"
                                  unoptimized
                                />
                              ) : (
                                <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg border border-dashed border-border bg-bg text-[9px] font-[800] text-muted">
                                  Görsel
                                </div>
                              )}
                              <div className="min-w-0">
                                <div className="flex flex-wrap items-center gap-1.5">
                                  <span className="font-[700] text-textStrong">{item.name}</span>
                                  {getDietaryBadges(item.tags).map((d) => (
                                    <span key={d.key} title={d.label} className="text-[12px] leading-none">{d.icon}</span>
                                  ))}
                                  {(allergenMap[item.id]?.length ?? 0) > 0 && (
                                    <span className="rounded-full border border-border bg-bg px-1.5 py-0.5 text-[9px] font-[700] text-muted">
                                      {allergenMap[item.id].length} alerjen
                                    </span>
                                  )}
                                </div>
                                {item.description && (
                                  <p className="max-w-xs truncate text-[12px] text-muted">{item.description}</p>
                                )}
                              </div>
                            </div>
                          </td>
                          <td className="px-4 py-3">
                            <span className={`rounded-full px-2.5 py-1 text-[11px] font-[700] ${categoryBadgeColor(sectionIndexMap.get(item.section_id) ?? 0)}`}>
                              {sectionTitleMap.get(item.section_id) ?? '—'}
                            </span>
                          </td>
                          <td className="px-4 py-3 font-[700] text-textStrong">{formatPrice(item.price_cents)}</td>
                          <td className="px-4 py-3">
                            <span
                              className={`rounded-full px-2.5 py-1 text-[11px] font-[700] ${
                                item.is_available ? 'bg-green-50 text-green-700' : 'bg-zinc-100 text-zinc-500'
                              }`}
                            >
                              {item.is_available ? 'Aktif' : 'Stok Dışı'}
                            </span>
                          </td>
                          <td className="px-4 py-3 text-[12px] text-muted">{formatDateShortTr(item.updated_at)}</td>
                          <td className="px-4 py-3">
                            <div className="flex items-center justify-end gap-1.5">
                              <button
                                onClick={() => setEditingItemId(item.id)}
                                className="flex h-8 w-8 cursor-pointer items-center justify-center rounded-lg border border-border text-muted hover:bg-bg"
                                aria-label={`${item.name} düzenle`}
                              >
                                <PencilIcon />
                              </button>
                              <button
                                onClick={() => {
                                  if (confirm(`"${item.name}" ürününü sil?`)) run(() => deleteItem(item.id, menuId));
                                }}
                                className="flex h-8 w-8 cursor-pointer items-center justify-center rounded-lg border border-red-200 text-red-600 hover:bg-red-50"
                                aria-label={`${item.name} sil`}
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
              </div>
            )}
          </div>

          {/* Sağ: kategori yönetimi + canlı önizleme */}
          <div className="flex flex-col gap-4">
            <div className="rounded-2xl border border-border bg-card p-4">
              <p className="mb-3 text-sm font-[800] text-textStrong">Kategori Yönetimi</p>
              <div className="flex flex-col gap-1">
                {sections.map((section, i) => {
                  const count = items.filter((it) => it.section_id === section.id).length;
                  const isActive = effectiveActiveTab === section.id;
                  return (
                    <button
                      key={section.id}
                      onClick={() => setActiveTab(section.id)}
                      className={`flex cursor-pointer items-center gap-3 rounded-xl px-2 py-2 text-left transition-colors hover:bg-bg ${isActive ? 'bg-bg' : ''}`}
                    >
                      <span className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-lg ${categoryBadgeColor(i)}`}>
                        <TagIcon />
                      </span>
                      <span className="min-w-0 flex-1">
                        <span className="block truncate text-sm font-[700] text-textStrong">{section.title}</span>
                        <span className="text-[11px] text-muted">{count} ürün</span>
                      </span>
                      <span className="shrink-0 text-muted"><ChevronRightIcon /></span>
                    </button>
                  );
                })}
                {sections.length === 0 && (
                  <p className="px-2 py-1 text-xs text-muted">Henüz kategori yok.</p>
                )}
              </div>

              <Link
                href={`/sahip/menuler/${menuId}/kategoriler`}
                className="mt-3 flex w-full cursor-pointer items-center justify-center rounded-xl border border-border bg-bg px-3 py-2 text-xs font-[700] text-textStrong transition-colors hover:bg-card"
              >
                Tüm Kategorileri Yönet
              </Link>
            </div>

            {previewItem && (
              <div className="rounded-2xl border border-border bg-card p-4">
                <p className="text-sm font-[800] text-textStrong">Canlı Önizleme</p>
                <p className="mb-3 text-[11px] text-muted">Müşterileriniz ürünü bu şekilde görür.</p>
                <div className="overflow-hidden rounded-xl border border-border">
                  <div className="relative h-32 w-full bg-bg">
                    {previewItem.image_url ? (
                      <Image
                        src={buildMenuImageUrl(previewItem.image_url, { width: 400, quality: 75 }) ?? previewItem.image_url}
                        alt={previewItem.name}
                        fill
                        sizes="300px"
                        className="object-cover"
                        unoptimized
                      />
                    ) : (
                      <div className="flex h-full items-center justify-center text-[11px] font-[700] text-muted">Görsel yok</div>
                    )}
                    <span
                      className={`absolute right-2 top-2 rounded-full px-2 py-0.5 text-[10px] font-[800] text-white ${
                        previewItem.is_available ? 'bg-green-600' : 'bg-zinc-500'
                      }`}
                    >
                      {previewItem.is_available ? 'Aktif' : 'Stok Dışı'}
                    </span>
                  </div>
                  <div className="flex items-start justify-between gap-2 p-3">
                    <div className="min-w-0">
                      <p className="truncate text-sm font-[700] text-textStrong">{previewItem.name}</p>
                      {previewItem.description && (
                        <p className="truncate text-[11px] text-muted">{previewItem.description}</p>
                      )}
                    </div>
                    <span className="shrink-0 text-sm font-[800] text-textStrong">{formatPrice(previewItem.price_cents)}</span>
                  </div>
                </div>
                <Link
                  href={`/sahip/menuler/${menuId}`}
                  className="mt-3 flex w-full cursor-pointer items-center justify-center rounded-xl border border-border bg-bg px-3 py-2 text-xs font-[700] text-textStrong transition-colors hover:bg-card"
                >
                  Önizlemeyi Görüntüle
                </Link>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Ürün ekle modalı */}
      {addItemOpen && sections.length > 0 && (
        <ItemFormModal title="Yeni Ürün Ekle" onClose={() => setAddItemOpen(false)}>
          <ItemForm
            menuId={menuId}
            sections={sections}
            initialSectionId={addItemDefaultSectionId}
            businessId={businessId}
            initialAllergens={[]}
            initialIngredients={[]}
            submitLabel="Ürün Ekle"
            onSuccess={() => setAddItemOpen(false)}
            onCancel={() => setAddItemOpen(false)}
          />
        </ItemFormModal>
      )}

      {/* Ürün düzenleme modalı */}
      {editingItemId && (() => {
        const item = items.find((i) => i.id === editingItemId);
        if (!item) return null;
        return (
          <ItemFormModal title="Ürünü Düzenle" onClose={() => setEditingItemId(null)}>
            <ItemForm
              menuId={menuId}
              sections={sections}
              initialSectionId={item.section_id}
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
        );
      })()}
    </div>
  );
}
