'use client';

import { useActionState, useEffect, useRef } from 'react';
import { kaydetKampanya } from './kampanya-eylemleri';

export type KampanyaTuru = 'discount' | 'special_offer' | 'loyalty' | 'announcement';
export type KampanyaDurumu = 'draft' | 'planned' | 'active' | 'completed';

export interface Kampanya {
  id: string;
  title: string;
  description: string | null;
  type: KampanyaTuru;
  status: KampanyaDurumu;
  discount_percent: number | null;
  starts_at: string | null;
  ends_at: string | null;
  view_count: number;
  click_count: number;
  created_at: string;
}

interface Props {
  businessId: string;
  campaign?: Kampanya | null;
  onClose: () => void;
}

const TYPE_LABELS: Record<KampanyaTuru, string> = {
  discount:      'İndirim',
  special_offer: 'Özel Teklif',
  loyalty:       'Sadakat',
  announcement:  'Duyuru',
};

const STATUS_LABELS: Record<KampanyaDurumu, string> = {
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
  const [state, action, pending] = useActionState(kaydetKampanya, null);
  const formRef = useRef<HTMLFormElement>(null);
  const hasSubmitted = useRef(false);
  const isEdit = !!campaign;

  useEffect(() => {
    if (hasSubmitted.current && state === null && !pending) {
      onClose();
    }
  }, [state, pending, onClose]);

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center sm:items-center">
      {/* Backdrop */}
      <div className="absolute inset-0 bg-black/40 backdrop-blur-sm" onClick={onClose} />

      {/* Sheet */}
      <div className="relative z-10 w-full max-w-lg rounded-t-2xl bg-card sm:rounded-2xl shadow-2xl border border-border">
        {/* Header */}
        <div className="flex items-center justify-between border-b border-border px-6 py-4">
          <h2 className="text-base font-[900] text-textStrong">
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

          {/* Tip + Durum */}
          <div className="grid grid-cols-2 gap-4">
            <Field label="Kampanya Tipi" required>
              <select name="type" defaultValue={campaign?.type ?? 'discount'} className={inputCls} required>
                {(Object.entries(TYPE_LABELS) as [KampanyaTuru, string][]).map(([v, l]) => (
                  <option key={v} value={v}>{l}</option>
                ))}
              </select>
            </Field>
            <Field label="Durum" required>
              <select name="status" defaultValue={campaign?.status ?? 'draft'} className={inputCls} required>
                {(Object.entries(STATUS_LABELS) as [KampanyaDurumu, string][]).map(([v, l]) => (
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
            <p className="rounded-xl bg-red-50 px-4 py-3 text-sm font-[700] text-red-600">
              {state.error}
            </p>
          )}

          {/* Footer */}
          <div className="flex items-center justify-end gap-3 border-t border-border pt-4">
            <button
              type="button"
              onClick={onClose}
              className="h-9 rounded-xl border border-border px-4 text-sm font-[800] text-textStrong transition hover:bg-bg"
            >
              İptal
            </button>
            <button
              type="submit"
              disabled={pending}
              className="flex h-9 items-center gap-2 rounded-xl bg-primary px-5 text-sm font-[800] text-white transition hover:opacity-90 disabled:opacity-50"
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
  'placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/20 transition-shadow';

function Field({ label, required, hint, children }: {
  label: string; required?: boolean; hint?: string; children: React.ReactNode;
}) {
  return (
    <div>
      <label className="mb-1.5 block text-xs font-[700] text-muted">
        {label}
        {required && <span className="ml-1 text-danger">*</span>}
        {hint && <span className="ml-1.5 font-[500] text-muted/70">{hint}</span>}
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
