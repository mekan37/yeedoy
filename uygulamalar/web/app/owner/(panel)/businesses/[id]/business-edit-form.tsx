'use client';

import { useState, useTransition } from 'react';
import { PanelActionButton } from '@/src/ui/components/panel-action-button';
import { updateBusiness } from './actions';

interface BusinessFields {
  id: string;
  name: string;
  category: string;
  description: string | null;
  phone: string | null;
  address: string | null;
  reservation_url: string | null;
  order_yemeksepeti_url: string | null;
  order_trendyolgo_url: string | null;
  order_getir_url: string | null;
}

interface Props {
  business: BusinessFields;
}

export function BusinessEditForm({ business }: Props) {
  const [isPending, startTransition] = useTransition();
  const [saved, setSaved]   = useState(false);
  const [error, setError]   = useState<string | null>(null);

  function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const fd = new FormData(e.currentTarget);
    setError(null);
    setSaved(false);
    startTransition(async () => {
      const result = await updateBusiness(business.id, fd);
      if (result?.error) {
        setError(result.error);
      } else {
        setSaved(true);
        setTimeout(() => setSaved(false), 3000);
      }
    });
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      {/* Temel bilgiler */}
      <div className="space-y-4">
        <SectionLabel>Temel Bilgiler</SectionLabel>
        <div className="grid gap-4 sm:grid-cols-2">
          <Field label="İşletme Adı" name="name" defaultValue={business.name} required />
          <Field label="Kategori" name="category" defaultValue={business.category} required />
        </div>
        <Field label="Açıklama" name="description" defaultValue={business.description ?? ''} multiline />
        <div className="grid gap-4 sm:grid-cols-2">
          <Field label="Telefon" name="phone" defaultValue={business.phone ?? ''} type="tel" />
          <Field label="Adres" name="address" defaultValue={business.address ?? ''} />
        </div>
      </div>

      <Divider />

      {/* Sipariş & Rezervasyon */}
      <div className="space-y-4">
        <SectionLabel hint="Boş bırakılan linkler işletme sayfasında gösterilmez">
          Sipariş & Rezervasyon Linkleri
        </SectionLabel>
        <div className="grid gap-4 sm:grid-cols-2">
          <Field label="Yemeksepeti" name="order_yemeksepeti_url"
                 defaultValue={business.order_yemeksepeti_url ?? ''} type="url"
                 placeholder="https://yemeksepeti.com/..." />
          <Field label="Trendyol GO" name="order_trendyolgo_url"
                 defaultValue={business.order_trendyolgo_url ?? ''} type="url"
                 placeholder="https://trendyol.com/..." />
          <Field label="Getir" name="order_getir_url"
                 defaultValue={business.order_getir_url ?? ''} type="url"
                 placeholder="https://getir.com/..." />
          <Field label="Rezervasyon Linki" name="reservation_url"
                 defaultValue={business.reservation_url ?? ''} type="url"
                 placeholder="https://..." />
        </div>
      </div>

      {/* Footer */}
      <div className="flex items-center gap-3 border-t border-border pt-4">
        <PanelActionButton type="submit" variant="primary" loading={isPending}>
          Değişiklikleri Kaydet
        </PanelActionButton>
        {saved && (
          <span className="flex items-center gap-1.5 text-sm font-[700] text-green-600">
            <CheckIcon />
            Kaydedildi
          </span>
        )}
        {error && (
          <span className="text-sm font-[700] text-[color:var(--yd-color-danger)]">{error}</span>
        )}
      </div>
    </form>
  );
}

// ── Sub-components ─────────────────────────────────────────────────────────

function SectionLabel({ children, hint }: { children: React.ReactNode; hint?: string }) {
  return (
    <div>
      <p className="text-[11px] font-[800] uppercase tracking-wider text-muted">{children}</p>
      {hint && <p className="mt-0.5 text-xs text-muted">{hint}</p>}
    </div>
  );
}

function Divider() {
  return <div className="border-t border-border" />;
}

function Field({
  label,
  name,
  defaultValue,
  required,
  multiline,
  type = 'text',
  placeholder,
}: {
  label: string;
  name: string;
  defaultValue: string;
  required?: boolean;
  multiline?: boolean;
  type?: string;
  placeholder?: string;
}) {
  const base =
    'w-full rounded-xl border border-border bg-bg px-3 py-2.5 text-sm text-textStrong ' +
    'placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-[#7f1d1d]/20 ' +
    'transition-shadow duration-150';

  return (
    <div>
      <label className="mb-1.5 block text-xs font-[700] text-muted">
        {label}
        {required && <span className="ml-1 text-[color:var(--yd-color-danger)]">*</span>}
      </label>
      {multiline ? (
        <textarea
          name={name}
          defaultValue={defaultValue}
          rows={3}
          placeholder={placeholder}
          className={`${base} resize-none`}
        />
      ) : (
        <input
          name={name}
          type={type}
          defaultValue={defaultValue}
          required={required}
          placeholder={placeholder}
          className={base}
        />
      )}
    </div>
  );
}

function CheckIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
      <polyline points="20 6 9 17 4 12" />
    </svg>
  );
}
