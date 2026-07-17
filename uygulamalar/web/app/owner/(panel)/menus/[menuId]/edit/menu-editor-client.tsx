'use client';

import { useState, useEffect, useRef, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { createSupabaseBrowserClient } from '@/src/lib/supabase/client';
import { buildMenuImageUrl } from '@/src/lib/media-url';
import {
  createSection, updateSection, deleteSection,
  upsertItem, upsertItemAllergens, getItemAllergens,
  deleteItem, publishMenu, updateMenuTitle,
} from './actions';

// ── Types ──────────────────────────────────────────────────────────────────────

type AllergenEntry = { allergen: string; risk_level: 'contains' | 'may_contain' };

type Item = {
  id: string; name: string; description: string | null;
  price_cents: number; currency: string; is_available: boolean;
  section_id: string; sort_order: number;
  image_url: string | null; tags: string[] | null;
  calories_min: number | null; calories_max: number | null;
  portion_size: string | null; portion_unit: string | null;
};

type Section = { id: string; title: string; sort_order: number };

type EditorState = { mode: 'add' | 'edit'; sectionId: string; item: Item | null };

// ── Constants ─────────────────────────────────────────────────────────────────

const ALLERGENS = [
  { key: 'gluten', tr: 'Gluten' }, { key: 'milk', tr: 'Süt' },
  { key: 'eggs', tr: 'Yumurta' }, { key: 'nuts', tr: 'Ağaç Fıstığı' },
  { key: 'peanuts', tr: 'Yer Fıstığı' }, { key: 'soy', tr: 'Soya' },
  { key: 'fish', tr: 'Balık' }, { key: 'shellfish', tr: 'Kabuklu Deniz' },
  { key: 'sesame', tr: 'Susam' }, { key: 'mustard', tr: 'Hardal' },
  { key: 'celery', tr: 'Kereviz' }, { key: 'lupin', tr: 'Lupine' },
  { key: 'molluscs', tr: 'Yumuşakça' }, { key: 'sulphites', tr: 'Sülfit' },
];

const DIETARY_FLAGS = [
  { key: 'diet_vegan',       label: 'Vegan',      icon: '🌱', detectedTags: ['vegan'] },
  { key: 'diet_vegetarian',  label: 'Vejetaryen', icon: '🥗', detectedTags: ['vegetarian', 'vejetaryen'] },
  { key: 'diet_glutenfree',  label: 'Glutensiz',  icon: '🌾', detectedTags: ['glutensiz', 'gluten_free'] },
  { key: 'diet_lactosefree', label: 'Laktossuz',  icon: '🥛', detectedTags: ['laktossuz', 'lactose_free'] },
  { key: 'diet_halal',       label: 'Helal',      icon: '☪️', detectedTags: ['halal'] },
];

const DIETARY_TAG_VALUES = new Set(DIETARY_FLAGS.flatMap((f) => f.detectedTags));
const BUCKET = 'menu-media';

// ── Helpers ───────────────────────────────────────────────────────────────────

function fmtPrice(cents: number) {
  return (cents / 100).toLocaleString('tr-TR', { minimumFractionDigits: 2 }) + ' ₺';
}

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

// ── Main component ─────────────────────────────────────────────────────────────

export function MenuEditorClient({
  menuId, businessId, initialTitle, initialStatus, sections, items,
}: {
  menuId: string;
  businessId: string;
  initialTitle: string;
  initialStatus: 'draft' | 'published' | 'archived';
  sections: Section[];
  items: Item[];
}) {
  const router = useRouter();
  const [isPending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);
  const [editingSectionId, setEditingSectionId] = useState<string | null>(null);
  const [showNewSection, setShowNewSection] = useState(false);
  const [showTitleEdit, setShowTitleEdit] = useState(false);
  const [editor, setEditor] = useState<EditorState | null>(null);

  function itemsFor(sectionId: string) {
    return items.filter((i) => i.section_id === sectionId).sort((a, b) => a.sort_order - b.sort_order);
  }

  function runAction(action: () => Promise<{ error: string } | null>) {
    setError(null);
    startTransition(async () => {
      const r = await action();
      if (r?.error) setError(r.error);
    });
  }

  return (
    <div className="flex flex-col gap-6">
      {/* Title + status controls */}
      <div className="flex flex-wrap items-center gap-3 rounded-2xl border border-border bg-card p-4">
        {showTitleEdit ? (
          <form className="flex flex-1 items-center gap-2" onSubmit={(e) => {
            e.preventDefault();
            const fd = new FormData(e.currentTarget);
            runAction(() => updateMenuTitle(menuId, String(fd.get('title') ?? '')));
            setShowTitleEdit(false);
          }}>
            <input name="title" defaultValue={initialTitle} required autoFocus
              className="flex-1 rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong focus:outline-none focus:ring-2 focus:ring-[#dc2626]/25 focus:border-[#dc2626]" />
            <button type="submit" className="rounded-xl bg-[#dc2626] px-3 py-2 text-xs font-[700] text-white cursor-pointer">Kaydet</button>
            <button type="button" onClick={() => setShowTitleEdit(false)} className="rounded-xl border border-border px-3 py-2 text-xs font-[700] text-muted cursor-pointer">İptal</button>
          </form>
        ) : (
          <span className="flex-1 font-[800] text-textStrong">{initialTitle}</span>
        )}
        {!showTitleEdit && (
          <button onClick={() => setShowTitleEdit(true)}
            className="rounded-xl border border-border px-3 py-1.5 text-[11px] font-[700] text-muted hover:bg-bg cursor-pointer">
            Başlığı Düzenle
          </button>
        )}
        <div className="flex items-center gap-2">
          {initialStatus !== 'published' && (
            <button onClick={() => runAction(() => publishMenu(menuId, 'published'))} disabled={isPending}
              className="rounded-xl bg-green-600 px-3 py-1.5 text-[11px] font-[700] text-white disabled:opacity-60 cursor-pointer">
              Yayınla
            </button>
          )}
          {initialStatus === 'published' && (
            <button onClick={() => runAction(() => publishMenu(menuId, 'draft'))} disabled={isPending}
              className="rounded-xl border border-amber-300 bg-amber-50 px-3 py-1.5 text-[11px] font-[700] text-amber-700 disabled:opacity-60 cursor-pointer">
              Taslağa Al
            </button>
          )}
          {initialStatus !== 'archived' && (
            <button onClick={() => runAction(() => publishMenu(menuId, 'archived'))} disabled={isPending}
              className="rounded-xl border border-border px-3 py-1.5 text-[11px] font-[700] text-muted hover:bg-bg disabled:opacity-60 cursor-pointer">
              Arşivle
            </button>
          )}
        </div>
      </div>

      {error && <div className="rounded-xl bg-red-50 px-4 py-3 text-sm text-[#dc2626]">{error}</div>}

      {/* Sections */}
      {sections.map((section) => (
        <div key={section.id} className="overflow-hidden rounded-2xl border border-border bg-card">
          {/* Section header */}
          <div className="flex items-center justify-between border-b border-border bg-[#fafafa] px-5 py-3">
            {editingSectionId === section.id ? (
              <form className="flex flex-1 items-center gap-2" onSubmit={(e) => {
                e.preventDefault();
                const fd = new FormData(e.currentTarget);
                runAction(() => updateSection(section.id, menuId, String(fd.get('title') ?? '')));
                setEditingSectionId(null);
              }}>
                <input name="title" defaultValue={section.title} required autoFocus
                  className="flex-1 rounded-xl border border-border bg-white px-3 py-1.5 text-sm text-textStrong focus:outline-none focus:ring-2 focus:ring-[#dc2626]/25" />
                <button type="submit" className="rounded-xl bg-[#dc2626] px-3 py-1.5 text-[11px] font-[700] text-white cursor-pointer">Kaydet</button>
                <button type="button" onClick={() => setEditingSectionId(null)} className="rounded-xl border border-border px-3 py-1.5 text-[11px] font-[700] text-muted cursor-pointer">İptal</button>
              </form>
            ) : (
              <>
                <span className="font-[900] text-[#1a1a2e]">{section.title}</span>
                <div className="flex items-center gap-1.5">
                  <button onClick={() => setEditingSectionId(section.id)}
                    className="rounded-lg border border-border px-2.5 py-1 text-[11px] font-[700] text-muted hover:bg-bg cursor-pointer">Düzenle</button>
                  <button onClick={() => { if (confirm(`"${section.title}" bölümünü sil?`)) runAction(() => deleteSection(section.id, menuId)); }}
                    className="rounded-lg border border-red-200 px-2.5 py-1 text-[11px] font-[700] text-red-600 hover:bg-red-50 cursor-pointer">Sil</button>
                </div>
              </>
            )}
          </div>

          {/* Items */}
          <div className="divide-y divide-border">
            {itemsFor(section.id).map((item) => {
              const badges = getDietaryBadges(item.tags);
              const thumbSrc = buildMenuImageUrl(item.image_url, { width: 96, quality: 70 });
              return (
                <div key={item.id} className="flex items-center gap-3 px-5 py-3">
                  {/* Thumbnail — optimized via Supabase transform */}
                  {thumbSrc ? (
                    /* eslint-disable-next-line @next/next/no-img-element */
                    <img src={thumbSrc} alt={item.name}
                      className="h-12 w-12 shrink-0 rounded-xl object-cover" />
                  ) : (
                    <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-[#f3f4f6] text-[#c8cfd8]">
                      <ImgIcon />
                    </div>
                  )}
                  <div className="min-w-0 flex-1">
                    <div className="flex flex-wrap items-center gap-1.5">
                      <span className="text-sm font-[800] text-[#1a1a2e]">{item.name}</span>
                      {!item.is_available && (
                        <span className="rounded-full bg-zinc-100 px-1.5 py-0.5 text-[10px] font-[700] text-zinc-500">Stok Dışı</span>
                      )}
                      {badges.map((d) => (
                        <span key={d.key} title={d.label} className="text-[13px] leading-none">{d.icon}</span>
                      ))}
                    </div>
                    {item.description && <p className="mt-0.5 line-clamp-1 text-[12px] text-muted">{item.description}</p>}
                    {(item.calories_min || item.calories_max) && (
                      <p className="mt-0.5 text-[11px] text-[#94a3b8]">
                        {item.calories_min && item.calories_max
                          ? `${item.calories_min}–${item.calories_max} kcal`
                          : `${item.calories_min ?? item.calories_max} kcal`}
                      </p>
                    )}
                  </div>
                  <span className="shrink-0 text-sm font-[900] text-[#1a1a2e]">{fmtPrice(item.price_cents)}</span>
                  <div className="flex shrink-0 items-center gap-1.5">
                    <button onClick={() => setEditor({ mode: 'edit', sectionId: section.id, item })}
                      className="rounded-lg border border-border px-2.5 py-1 text-[11px] font-[700] text-muted hover:bg-bg cursor-pointer">Düzenle</button>
                    <button onClick={() => { if (confirm(`"${item.name}" ürününü sil?`)) runAction(() => deleteItem(item.id, menuId)); }}
                      className="rounded-lg border border-red-200 px-2.5 py-1 text-[11px] font-[700] text-red-600 hover:bg-red-50 cursor-pointer">Sil</button>
                  </div>
                </div>
              );
            })}
          </div>

          <div className="border-t border-border px-5 py-3">
            <button onClick={() => setEditor({ mode: 'add', sectionId: section.id, item: null })}
              className="flex items-center gap-1.5 text-[12px] font-[700] text-[#dc2626] hover:underline cursor-pointer">
              <span className="text-base leading-none">+</span> Ürün Ekle
            </button>
          </div>
        </div>
      ))}

      {/* New section */}
      {showNewSection ? (
        <form className="flex flex-col gap-3 rounded-2xl border border-dashed border-border bg-card p-5"
          onSubmit={(e) => {
            e.preventDefault();
            const fd = new FormData(e.currentTarget);
            runAction(() => createSection(menuId, String(fd.get('title') ?? ''), sections.length));
            setShowNewSection(false);
          }}>
          <FL label="Bölüm Adı">
            <PI name="title" required autoFocus placeholder="Ör: Başlangıçlar, Ana Yemekler…" />
          </FL>
          <div className="flex gap-2">
            <button type="submit" disabled={isPending}
              className="rounded-xl bg-[#dc2626] px-4 py-2 text-sm font-[700] text-white disabled:opacity-60 cursor-pointer">Bölüm Oluştur</button>
            <button type="button" onClick={() => setShowNewSection(false)}
              className="rounded-xl border border-border px-4 py-2 text-sm font-[700] text-muted cursor-pointer">İptal</button>
          </div>
        </form>
      ) : (
        <button onClick={() => setShowNewSection(true)}
          className="flex items-center justify-center gap-2 rounded-2xl border border-dashed border-border bg-card px-5 py-4 text-sm font-[700] text-muted hover:border-[#dc2626]/40 hover:text-[#dc2626] transition-colors cursor-pointer">
          <span className="text-lg leading-none">+</span> Yeni Bölüm Ekle
        </button>
      )}

      {/* Item editor modal */}
      {editor && (
        <ItemEditorModal
          key={editor.item?.id ?? `new-${editor.sectionId}`}
          menuId={menuId}
          businessId={businessId}
          editor={editor}
          onClose={(refresh) => {
            setEditor(null);
            if (refresh) router.refresh();
          }}
        />
      )}
    </div>
  );
}

// ── Image Upload Zone ─────────────────────────────────────────────────────────

function ImageUploadZone({
  businessId,
  imageUrl,
  onChange,
}: {
  businessId: string;
  imageUrl: string;
  onChange: (url: string) => void;
}) {
  const fileRef = useRef<HTMLInputElement>(null);
  const [uploading, setUploading] = useState(false);
  const [uploadError, setUploadError] = useState<string | null>(null);
  const [isDragOver, setIsDragOver] = useState(false);
  const [showUrlInput, setShowUrlInput] = useState(false);

  async function uploadFile(file: File) {
    if (!file.type.startsWith('image/')) {
      setUploadError('Sadece görsel dosyası yükleyebilirsiniz.');
      return;
    }
    if (file.size > 5 * 1024 * 1024) {
      setUploadError('Dosya boyutu 5 MB\'ı geçemez.');
      return;
    }
    setUploading(true);
    setUploadError(null);

    const ext = file.name.split('.').pop()?.toLowerCase() ?? 'jpg';
    const path = `${businessId}/${Date.now()}_${Math.random().toString(36).slice(2, 8)}.${ext}`;

    const supabase = createSupabaseBrowserClient();
    const { data, error } = await supabase.storage
      .from(BUCKET)
      .upload(path, file, { contentType: file.type });

    if (error) {
      setUploadError(error.message);
      setUploading(false);
      return;
    }

    const { data: { publicUrl } } = supabase.storage.from(BUCKET).getPublicUrl(data.path);
    onChange(publicUrl);
    setUploading(false);
  }

  // Preview uses Supabase transform: resize + quality + auto-WebP
  const previewSrc = buildMenuImageUrl(imageUrl, { width: 800, quality: 85 });

  return (
    <div className="flex flex-col gap-2">
      {/* Hidden form value */}
      <input type="hidden" name="image_url" value={imageUrl} />

      {imageUrl ? (
        /* Uploaded / existing image */
        <div className="relative overflow-hidden rounded-2xl border border-[#e5e7eb]">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src={previewSrc ?? imageUrl} alt="Ürün görseli"
            className="h-44 w-full object-cover" />
          <div className="absolute inset-0 flex items-end bg-gradient-to-t from-black/60 to-transparent p-3">
            <div className="flex gap-2">
              <button type="button" onClick={() => fileRef.current?.click()}
                className="rounded-xl bg-white/90 px-3 py-1.5 text-[11px] font-[700] text-[#1a1a2e] backdrop-blur-sm hover:bg-white cursor-pointer">
                Değiştir
              </button>
              <button type="button" onClick={() => onChange('')}
                className="rounded-xl bg-white/20 px-3 py-1.5 text-[11px] font-[700] text-white backdrop-blur-sm hover:bg-white/30 cursor-pointer">
                Kaldır
              </button>
            </div>
            <div className="ml-auto flex items-center gap-1 rounded-full bg-black/40 px-2 py-1 text-[10px] font-[700] text-white backdrop-blur-sm">
              <WebpIcon />
              WebP optimize
            </div>
          </div>
        </div>
      ) : (
        /* Drop zone */
        <div
          onDragOver={(e) => { e.preventDefault(); setIsDragOver(true); }}
          onDragLeave={() => setIsDragOver(false)}
          onDrop={(e) => {
            e.preventDefault();
            setIsDragOver(false);
            const file = e.dataTransfer.files[0];
            if (file) uploadFile(file);
          }}
          onClick={() => !uploading && fileRef.current?.click()}
          className={`flex h-40 cursor-pointer flex-col items-center justify-center gap-3 rounded-2xl border-2 border-dashed transition-colors ${
            isDragOver
              ? 'border-[#dc2626] bg-[#fff5f5]'
              : 'border-[#e5e7eb] bg-[#fafafa] hover:border-[#dc2626]/50 hover:bg-[#fff8f8]'
          }`}
        >
          {uploading ? (
            <>
              <div className="flex h-10 w-10 items-center justify-center rounded-full bg-[#dc2626]/10">
                <svg className="animate-spin text-[#dc2626]" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                  <path d="M21 12a9 9 0 1 1-6.219-8.56" />
                </svg>
              </div>
              <p className="text-[12px] font-[700] text-[#dc2626]">Yükleniyor…</p>
            </>
          ) : (
            <>
              <div className="flex h-10 w-10 items-center justify-center rounded-full bg-[#f3f4f6]">
                <UploadIcon />
              </div>
              <div className="text-center">
                <p className="text-[13px] font-[700] text-[#475569]">
                  Görsel sürükle veya <span className="text-[#dc2626]">seç</span>
                </p>
                <p className="mt-0.5 text-[11px] text-[#94a3b8]">JPG, PNG, WebP · Maks 5 MB</p>
                <p className="mt-0.5 text-[10px] text-[#c8cfd8]">Supabase otomatik WebP&apos;ye dönüştürür</p>
              </div>
            </>
          )}
        </div>
      )}

      {/* Hidden file input */}
      <input ref={fileRef} type="file" accept="image/*" className="hidden"
        onChange={(e) => { const f = e.target.files?.[0]; if (f) uploadFile(f); }} />

      {uploadError && (
        <p className="text-[11px] font-[600] text-[#dc2626]">{uploadError}</p>
      )}

      {/* URL fallback toggle */}
      <button type="button" onClick={() => setShowUrlInput((v) => !v)}
        className="flex items-center gap-1 self-start text-[11px] font-[600] text-[#94a3b8] hover:text-[#475569] cursor-pointer">
        <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"
          style={{ transform: showUrlInput ? 'rotate(90deg)' : 'rotate(0deg)', transition: 'transform 0.15s' }}>
          <path d="m9 18 6-6-6-6" />
        </svg>
        veya URL ile ekle
      </button>

      {showUrlInput && (
        <div className="flex gap-2">
          <input type="url" placeholder="https://…"
            defaultValue={imageUrl}
            onBlur={(e) => onChange(e.target.value.trim())}
            className="flex-1 rounded-xl border border-[#e5e7eb] px-3 py-2 text-sm text-[#1a1a2e] placeholder:text-[#94a3b8] focus:outline-none focus:ring-2 focus:ring-[#dc2626]/25 focus:border-[#dc2626]" />
        </div>
      )}
    </div>
  );
}

// ── Item Editor Modal ─────────────────────────────────────────────────────────

function ItemEditorModal({
  menuId, businessId, editor, onClose,
}: {
  menuId: string;
  businessId: string;
  editor: EditorState;
  onClose: (refresh: boolean) => void;
}) {
  const { item } = editor;
  const initDietary = getDietaryFromTags(item?.tags ?? null);

  const [imageUrl, setImageUrl] = useState(item?.image_url ?? '');
  const [dietaryState, setDietaryState] = useState<Record<string, boolean>>(initDietary);
  const [allergenState, setAllergenState] = useState<Record<string, 'contains' | 'may_contain' | null>>({});
  const [allergenLoading, setAllergenLoading] = useState(!!item);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!item) return;
    getItemAllergens(item.id).then((entries) => {
      const state: Record<string, 'contains' | 'may_contain' | null> = {};
      for (const e of entries) state[e.allergen] = e.risk_level;
      setAllergenState(state);
      setAllergenLoading(false);
    });
  // key prop guarantees one mount per item
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  function toggleAllergen(key: string) {
    setAllergenState((prev) => {
      const cur = prev[key] ?? null;
      const next: 'contains' | 'may_contain' | null =
        cur === null ? 'contains' : cur === 'contains' ? 'may_contain' : null;
      return { ...prev, [key]: next };
    });
  }

  async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setSubmitting(true);
    setError(null);

    const fd = new FormData(e.currentTarget);
    fd.set('menuId', menuId);
    fd.set('sectionId', editor.sectionId);
    if (item) fd.set('itemId', item.id);

    const result = await upsertItem(fd);
    if ('error' in result) { setError(result.error); setSubmitting(false); return; }

    const allergenEntries: AllergenEntry[] = Object.entries(allergenState)
      .filter(([, v]) => v !== null)
      .map(([k, v]) => ({ allergen: k, risk_level: v as 'contains' | 'may_contain' }));

    const allergenErr = await upsertItemAllergens(result.itemId, allergenEntries);
    if (allergenErr?.error) { setError(allergenErr.error); setSubmitting(false); return; }

    setSubmitting(false);
    onClose(true);
  }

  return (
    <>
      <div className="fixed inset-0 z-40 bg-black/50 backdrop-blur-[2px]" onClick={() => onClose(false)} />
      <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
        <div className="flex w-full max-w-2xl flex-col rounded-2xl bg-white shadow-[0_24px_64px_rgba(0,0,0,0.18)] max-h-[90vh]">

          {/* Header */}
          <div className="flex shrink-0 items-center justify-between rounded-t-2xl border-b border-[#f0f0f0] px-6 py-4">
            <h2 className="text-base font-[900] text-[#1a1a2e]">
              {editor.mode === 'add' ? 'Yeni Ürün Ekle' : 'Ürünü Düzenle'}
            </h2>
            <button type="button" onClick={() => onClose(false)}
              className="flex h-8 w-8 items-center justify-center rounded-xl border border-[#e5e7eb] text-[#94a3b8] hover:bg-[#f3f4f6] cursor-pointer">
              <XIcon />
            </button>
          </div>

          {/* Scrollable body */}
          <form onSubmit={handleSubmit} className="flex flex-1 flex-col overflow-hidden">
            <div className="flex flex-1 flex-col gap-6 overflow-y-auto px-6 py-5">

              {/* ─ 1. Temel Bilgiler ─ */}
              <section>
                <SL>Temel Bilgiler</SL>
                <div className="flex flex-col gap-3">
                  <FL label="Ürün Adı *">
                    <PI name="name" defaultValue={item?.name ?? ''} required placeholder="Ürün adı" />
                  </FL>
                  <div className="grid grid-cols-2 gap-3">
                    <FL label="Fiyat (₺) *">
                      <PI name="price" type="number" step="0.01" min="0"
                        defaultValue={item ? String(item.price_cents / 100) : ''} required placeholder="0.00" />
                    </FL>
                    <FL label="Para Birimi">
                      <select name="currency" defaultValue={item?.currency ?? 'TRY'}
                        className="w-full rounded-xl border border-[#e5e7eb] px-3 py-2 text-sm text-[#1a1a2e] focus:outline-none focus:ring-2 focus:ring-[#dc2626]/25 focus:border-[#dc2626]">
                        <option value="TRY">TRY (₺)</option>
                        <option value="USD">USD ($)</option>
                        <option value="EUR">EUR (€)</option>
                      </select>
                    </FL>
                  </div>
                  <FL label="Açıklama">
                    <textarea name="description" defaultValue={item?.description ?? ''} rows={2}
                      placeholder="Kısa açıklama (opsiyonel)"
                      className="w-full resize-none rounded-xl border border-[#e5e7eb] px-3 py-2 text-sm text-[#1a1a2e] placeholder:text-[#94a3b8] focus:outline-none focus:ring-2 focus:ring-[#dc2626]/25 focus:border-[#dc2626]" />
                  </FL>
                  <label className="flex cursor-pointer items-center gap-2.5 rounded-xl border border-[#e5e7eb] px-3 py-2">
                    <input type="checkbox" name="is_available" defaultChecked={item?.is_available ?? true}
                      className="h-4 w-4 rounded accent-[#dc2626]" />
                    <span className="text-sm font-[700] text-[#1a1a2e]">Satışta (aktif)</span>
                  </label>
                </div>
              </section>

              <Div />

              {/* ─ 2. Görsel ─ */}
              <section>
                <SL>Görsel</SL>
                <ImageUploadZone
                  businessId={businessId}
                  imageUrl={imageUrl}
                  onChange={setImageUrl}
                />
              </section>

              <Div />

              {/* ─ 3. Diyet & Etiketler ─ */}
              <section>
                <SL>Diyet & Etiketler</SL>
                {/* Hidden checkboxes carry dietary state into FormData */}
                {DIETARY_FLAGS.map((flag) => (
                  <input key={flag.key} type="checkbox" name={flag.key}
                    checked={dietaryState[flag.key] ?? false} onChange={() => {}} className="hidden" />
                ))}
                <div className="flex flex-wrap gap-2">
                  {DIETARY_FLAGS.map((flag) => (
                    <button key={flag.key} type="button"
                      onClick={() => setDietaryState((p) => ({ ...p, [flag.key]: !p[flag.key] }))}
                      className={`flex cursor-pointer items-center gap-1.5 rounded-full border px-3 py-1.5 text-[12px] font-[700] transition-colors ${
                        dietaryState[flag.key]
                          ? 'border-[#dc2626] bg-[#fef2f2] text-[#dc2626]'
                          : 'border-[#e5e7eb] bg-white text-[#475569] hover:border-[#dc2626]/30 hover:bg-[#fff8f8]'
                      }`}>
                      <span>{flag.icon}</span>{flag.label}
                      {dietaryState[flag.key] && (
                        <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round">
                          <polyline points="20 6 9 17 4 12" />
                        </svg>
                      )}
                    </button>
                  ))}
                </div>
                <div className="mt-3">
                  <FL label="Ek Etiketler (virgülle ayırın)">
                    <PI name="custom_tags" defaultValue={getCustomTags(item?.tags ?? null)}
                      placeholder="organik, ev yapımı, spesyalite…" />
                  </FL>
                </div>
              </section>

              <Div />

              {/* ─ 4. Alerjenler ─ */}
              <section>
                <SL>Alerjenler — AB Zorunlu 14</SL>
                <p className="mb-3 text-[11px] text-[#94a3b8]">
                  Dokunarak döngü: <span className="font-[700] text-[#dc2626]">İçerir</span>
                  {' → '}<span className="font-[700] text-orange-500">İz İçerebilir</span>{' → '}Yok
                </p>
                {allergenLoading ? (
                  <div className="flex items-center gap-2 py-2 text-[12px] text-[#94a3b8]">
                    <svg className="animate-spin" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                      <path d="M21 12a9 9 0 1 1-6.219-8.56" />
                    </svg>
                    Yükleniyor…
                  </div>
                ) : (
                  <div className="flex flex-wrap gap-2">
                    {ALLERGENS.map((a) => {
                      const s = allergenState[a.key] ?? null;
                      return (
                        <button key={a.key} type="button" onClick={() => toggleAllergen(a.key)}
                          className={`flex cursor-pointer items-center gap-1 rounded-full border px-3 py-1 text-[12px] font-[700] transition-colors ${
                            s === 'contains'
                              ? 'border-[#dc2626] bg-[#fef2f2] text-[#dc2626]'
                              : s === 'may_contain'
                                ? 'border-orange-400 bg-orange-50 text-orange-600'
                                : 'border-[#e5e7eb] bg-white text-[#475569] hover:border-[#94a3b8]'
                          }`}>
                          {a.tr}
                          {s === 'contains' && <span className="text-[9px] font-[900]">✓</span>}
                          {s === 'may_contain' && <span className="text-[9px] font-[900]">~</span>}
                        </button>
                      );
                    })}
                  </div>
                )}
                <div className="mt-2 flex items-center gap-5 text-[11px] text-[#94a3b8]">
                  <span className="flex items-center gap-1.5"><span className="h-2 w-2 rounded-full bg-[#dc2626]" />İçerir</span>
                  <span className="flex items-center gap-1.5"><span className="h-2 w-2 rounded-full bg-orange-400" />İz İçerebilir</span>
                </div>
              </section>

              <Div />

              {/* ─ 5. Kalori & Porsiyon ─ */}
              <section>
                <SL>Kalori & Porsiyon</SL>
                <div className="grid grid-cols-2 gap-3">
                  <FL label="Min Kalori (kcal)">
                    <PI name="calories_min" type="number" min="0"
                      defaultValue={item?.calories_min?.toString() ?? ''} placeholder="ör: 320" />
                  </FL>
                  <FL label="Max Kalori (kcal)">
                    <PI name="calories_max" type="number" min="0"
                      defaultValue={item?.calories_max?.toString() ?? ''} placeholder="ör: 420" />
                  </FL>
                </div>
                <div className="mt-3 grid grid-cols-2 gap-3">
                  <FL label="Porsiyon Miktarı">
                    <PI name="portion_size" defaultValue={item?.portion_size ?? ''} placeholder="ör: 250" />
                  </FL>
                  <FL label="Porsiyon Birimi">
                    <select name="portion_unit" defaultValue={item?.portion_unit ?? ''}
                      className="w-full rounded-xl border border-[#e5e7eb] px-3 py-2 text-sm text-[#1a1a2e] focus:outline-none focus:ring-2 focus:ring-[#dc2626]/25 focus:border-[#dc2626]">
                      <option value="">— Seç —</option>
                      <option value="g">g (gram)</option>
                      <option value="ml">ml (mililitre)</option>
                      <option value="adet">adet</option>
                      <option value="dilim">dilim</option>
                      <option value="porsiyon">porsiyon</option>
                    </select>
                  </FL>
                </div>
              </section>

            </div>

            {/* Footer */}
            <div className="shrink-0 rounded-b-2xl border-t border-[#f0f0f0] bg-white px-6 py-4">
              {error && (
                <p className="mb-3 rounded-xl bg-red-50 px-3 py-2 text-[12px] font-[600] text-[#dc2626]">{error}</p>
              )}
              <div className="flex items-center justify-end gap-3">
                <button type="button" onClick={() => onClose(false)}
                  className="rounded-xl border border-[#e5e7eb] px-4 py-2 text-sm font-[700] text-[#475569] hover:bg-[#f8fafc] cursor-pointer">
                  İptal
                </button>
                <button type="submit" disabled={submitting}
                  className="rounded-xl bg-[#dc2626] px-5 py-2 text-sm font-[700] text-white shadow-[0_2px_6px_rgba(220,38,38,0.25)] transition hover:bg-[#b91c1c] disabled:opacity-60 cursor-pointer">
                  {submitting ? 'Kaydediliyor…' : editor.mode === 'add' ? 'Ürün Ekle' : 'Kaydet'}
                </button>
              </div>
            </div>
          </form>
        </div>
      </div>
    </>
  );
}

// ── Micro helpers ─────────────────────────────────────────────────────────────

function SL({ children }: { children: React.ReactNode }) {
  return <p className="mb-3 text-[10px] font-[800] uppercase tracking-wider text-[#94a3b8]">{children}</p>;
}

function FL({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div className="flex flex-col gap-1">
      <label className="text-[11px] font-[700] text-[#475569]">{label}</label>
      {children}
    </div>
  );
}

function PI(props: React.InputHTMLAttributes<HTMLInputElement>) {
  return (
    <input {...props}
      className="w-full rounded-xl border border-[#e5e7eb] px-3 py-2 text-sm text-[#1a1a2e] placeholder:text-[#94a3b8] focus:outline-none focus:ring-2 focus:ring-[#dc2626]/25 focus:border-[#dc2626]" />
  );
}

function Div() { return <hr className="border-[#f0f0f0]" />; }

function XIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
      <path d="M18 6 6 18M6 6l12 12" />
    </svg>
  );
}

function ImgIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="3" width="18" height="18" rx="2" />
      <circle cx="8.5" cy="8.5" r="1.5" />
      <path d="m21 15-5-5L5 21" />
    </svg>
  );
}

function UploadIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
      <polyline points="17 8 12 3 7 8" />
      <line x1="12" y1="3" x2="12" y2="15" />
    </svg>
  );
}

function WebpIcon() {
  return (
    <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
      <path d="M13 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z" />
      <polyline points="13 2 13 9 20 9" />
    </svg>
  );
}
