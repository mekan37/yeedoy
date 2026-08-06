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
