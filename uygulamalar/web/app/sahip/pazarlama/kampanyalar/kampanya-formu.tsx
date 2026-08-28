'use client';

import { useActionState, useEffect, useRef, useState } from 'react';
import { kampanyaKaydet } from './kampanya-islemleri';
import { compressToWebP } from '@/src/lib/gorsel-sikistir';

export type KampanyaTipi = 'discount' | 'special_offer' | 'loyalty' | 'announcement';
export type KampanyaDurumu = 'draft' | 'planned' | 'active' | 'completed';

export interface Kampanya {
  id: string;
  title: string;
  description: string | null;
  type: KampanyaTipi;
  status: KampanyaDurumu;
  discount_percent: number | null;
  starts_at: string | null;
  ends_at: string | null;
  image_url: string | null;
  view_count: number;
  click_count: number;
  created_at: string;
}

interface Props {
  businessId: string;
  campaign?: Kampanya | null;
  onClose: () => void;
}

const TIP_ETIKETLERI: Record<KampanyaTipi, string> = {
  discount:      'İndirim',
  special_offer: 'Özel Teklif',
  loyalty:       'Sadakat',
  announcement:  'Duyuru',
};

const DURUM_ETIKETLERI: Record<KampanyaDurumu, string> = {
  draft:     'Taslak',
  planned:   'Planlanan',
  active:    'Aktif',
  completed: 'Tamamlandı',
};

function toDatetimeLocal(iso: string | null | undefined): string {
  if (!iso) return '';
  return iso.slice(0, 16);
}

export function KampanyaFormu({ businessId, campaign, onClose }: Props) {
  const [state, action, pending] = useActionState(kampanyaKaydet, null);
  const formRef = useRef<HTMLFormElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const hasSubmitted = useRef(false);
  const isEdit = !!campaign;

  const [imageUrl, setImageUrl] = useState<string | null>(campaign?.image_url ?? null);
  const [uploading, setUploading] = useState(false);
  const [uploadError, setUploadError] = useState<string | null>(null);

  async function handleImageUpload(file: File) {
    setUploadError(null);
    setUploading(true);
    try {
      const compressed = await compressToWebP(file, 1600);
      const fd = new FormData();
      fd.append('businessId', businessId);
      fd.append('type', 'campaign');
      fd.append('file', compressed);

      const response = await fetch('/sunucu/medya/yukleme', { method: 'POST', body: fd });
      const result = await response.json().catch(() => null) as { data?: { url?: string }; error?: string } | null;

      if (!response.ok) {
        setUploadError(
          result?.error === 'rate_limited' ? 'Çok fazla istek, bekleyin.' :
          result?.error === 'file_too_large' ? 'Dosya çok büyük.' :
          result?.error === 'invalid_mime_type' ? 'Desteklenmeyen dosya türü.' :
          result?.error === 'forbidden' ? 'Bu işletmeyi düzenleme yetkiniz yok.' : 'Yükleme başarısız.',
        );
        return;
      }

      const url = result?.data?.url;
      if (!url) throw new Error('invalid_upload_response');
      setImageUrl(url);
    } catch {
      setUploadError('Yükleme sırasında bir bağlantı hatası oluştu. Lütfen tekrar deneyin.');
    } finally {
      setUploading(false);
    }
  }

  function onFileChange(e: React.ChangeEvent<HTMLInputElement>) {
    const f = e.target.files?.[0];
    if (f) handleImageUpload(f);
    e.target.value = '';
  }

  useEffect(() => {
    if (hasSubmitted.current && state === null && !pending) {
      onClose();
    }
  }, [state, pending, onClose]);

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center sm:items-center">
      {/* Backdrop */}
      <div className="absolute inset-0 bg-black/40 backdrop-blur-xs" onClick={onClose} />

      {/* Sheet */}
      <div className="relative z-10 w-full max-w-lg rounded-t-2xl bg-card sm:rounded-2xl shadow-2xl border border-border">
        {/* Header */}
        <div className="flex items-center justify-between border-b border-border px-6 py-4">
          <h2 className="text-base font-black text-textStrong">
            {isEdit ? 'Kampanyayı Düzenle' : 'Yeni Kampanya'}
          </h2>
          <button
            type="button"
            onClick={onClose}
            className="flex h-8 w-8 items-center justify-center rounded-xl text-muted hover:bg-bg transition"
          >
            <CloseIcon />
          </button>
        </div>

        {/* Form */}
        <form ref={formRef} action={action} onSubmit={() => { hasSubmitted.current = true; }} className="max-h-[80vh] overflow-y-auto px-6 py-5 space-y-4">
          <input type="hidden" name="business_id" value={businessId} />
          {campaign && <input type="hidden" name="id" value={campaign.id} />}

          {/* Başlık */}
          <Field label="Kampanya Başlığı" required>
            <input
              name="title"
              defaultValue={campaign?.title ?? ''}
              placeholder="Örn: Kahvaltıda %20 İndirim"
              maxLength={120}
              required
              className={inputCls}
            />
          </Field>

          {/* Açıklama */}
          <Field label="Açıklama">
            <textarea
              name="description"
              defaultValue={campaign?.description ?? ''}
              placeholder="Kampanya detaylarını açıklayın..."
              maxLength={500}
              rows={3}
              className={`${inputCls} resize-none`}
            />
          </Field>

          {/* Görsel */}
          <Field label="Kampanya Görseli" hint="Opsiyonel — broşür/afiş görseli">
            <input type="hidden" name="image_url" value={imageUrl ?? ''} />
            {imageUrl ? (
              <div className="relative overflow-hidden rounded-xl border border-border" style={{ aspectRatio: '16/9' }}>
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src={imageUrl} alt="Kampanya görseli" className="h-full w-full object-cover" />
                <button
                  type="button"
                  onClick={() => setImageUrl(null)}
                  aria-label="Görseli kaldır"
                  className="absolute right-2 top-2 flex h-8 w-8 items-center justify-center rounded-full bg-black/50 text-white transition hover:bg-black/70"
                >
                  <CloseIcon />
                </button>
              </div>
            ) : (
              <button
                type="button"
                onClick={() => fileInputRef.current?.click()}
                disabled={uploading}
                className="flex h-24 w-full items-center justify-center gap-2 rounded-xl border border-dashed border-border text-sm font-bold text-muted transition hover:border-primary/40 hover:text-primary disabled:opacity-60"
              >
                {uploading ? <SpinIcon /> : null}
                {uploading ? 'Yükleniyor...' : 'Görsel Yükle'}
              </button>
            )}
            <input
              ref={fileInputRef}
              type="file"
              accept="image/jpeg,image/png,image/webp"
              className="hidden"
              onChange={onFileChange}
            />
            {uploadError && <p className="mt-1.5 text-xs font-bold text-danger">{uploadError}</p>}
          </Field>

          {/* Tip + Durum */}
          <div className="grid grid-cols-2 gap-4">
            <Field label="Kampanya Tipi" required>
              <select name="type" defaultValue={campaign?.type ?? 'discount'} className={inputCls} required>
                {(Object.entries(TIP_ETIKETLERI) as [KampanyaTipi, string][]).map(([v, l]) => (
                  <option key={v} value={v}>{l}</option>
                ))}
              </select>
            </Field>
            <Field label="Durum" required>
              <select name="status" defaultValue={campaign?.status ?? 'draft'} className={inputCls} required>
                {(Object.entries(DURUM_ETIKETLERI) as [KampanyaDurumu, string][]).map(([v, l]) => (
                  <option key={v} value={v}>{l}</option>
                ))}
              </select>
            </Field>
          </div>

          {/* İndirim Oranı */}
          <Field label="İndirim Oranı (%)" hint="Sadece indirim kampanyaları için">
            <input
              name="discount_percent"
              type="number"
              min={1}
              max={100}
              defaultValue={campaign?.discount_percent ?? ''}
              placeholder="Örn: 20"
              className={inputCls}
            />
          </Field>

          {/* Tarihler */}
          <div className="grid grid-cols-2 gap-4">
            <Field label="Başlangıç">
              <input
                name="starts_at"
                type="datetime-local"
                defaultValue={toDatetimeLocal(campaign?.starts_at)}
                className={inputCls}
              />
            </Field>
            <Field label="Bitiş">
              <input
                name="ends_at"
                type="datetime-local"
                defaultValue={toDatetimeLocal(campaign?.ends_at)}
                className={inputCls}
              />
            </Field>
          </div>

          {/* Hata */}
          {state?.error && (
            <p className="rounded-xl bg-red-50 px-4 py-3 text-sm font-bold text-red-600">
              {state.error}
            </p>
          )}

          {/* Footer */}
          <div className="flex items-center justify-end gap-3 border-t border-border pt-4">
            <button
              type="button"
              onClick={onClose}
              className="h-9 rounded-xl border border-border px-4 text-sm font-extrabold text-textStrong transition hover:bg-bg"
            >
              İptal
            </button>
            <button
              type="submit"
              disabled={pending}
              className="flex h-9 items-center gap-2 rounded-xl bg-primary px-5 text-sm font-extrabold text-white transition hover:opacity-90 disabled:opacity-50"
            >
              {pending ? <SpinIcon /> : null}
              {isEdit ? 'Kaydet' : 'Oluştur'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

// ── Helpers ────────────────────────────────────────────────────────────────

const inputCls =
  'w-full rounded-xl border border-border bg-bg px-3 py-2.5 text-sm text-textStrong ' +
  'placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/20 transition-shadow';

function Field({ label, required, hint, children }: {
  label: string; required?: boolean; hint?: string; children: React.ReactNode;
}) {
  return (
    <div>
      <label className="mb-1.5 block text-xs font-bold text-muted">
        {label}
        {required && <span className="ml-1 text-danger">*</span>}
        {hint && <span className="ml-1.5 font-medium text-muted/70">{hint}</span>}
      </label>
      {children}
    </div>
  );
}

function CloseIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>;
}
function SpinIcon() {
  return <svg className="animate-spin" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg>;
}
