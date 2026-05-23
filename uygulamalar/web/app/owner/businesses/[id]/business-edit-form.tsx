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
}

interface Props {
  business: BusinessFields;
}

export function BusinessEditForm({ business }: Props) {
  const [isPending, startTransition] = useTransition();
  const [saved, setSaved] = useState(false);
  const [error, setError] = useState<string | null>(null);

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
    <form onSubmit={handleSubmit} className="space-y-4">
      <Field label="İşletme Adı" name="name" defaultValue={business.name} required />
      <Field label="Kategori" name="category" defaultValue={business.category} required />
      <Field label="Açıklama" name="description" defaultValue={business.description ?? ''} multiline />
      <Field label="Telefon" name="phone" defaultValue={business.phone ?? ''} type="tel" />
      <Field label="Adres" name="address" defaultValue={business.address ?? ''} multiline />

      <div className="flex items-center gap-3 pt-2">
        <PanelActionButton type="submit" variant="primary" loading={isPending}>
          Kaydet
        </PanelActionButton>
        {saved && <p className="text-sm font-[700] text-green-600">Kaydedildi</p>}
        {error && <p className="text-sm font-[700] text-[color:var(--yd-color-danger)]">{error}</p>}
      </div>
    </form>
  );
}

function Field({
  label,
  name,
  defaultValue,
  required,
  multiline,
  type = 'text',
}: {
  label: string;
  name: string;
  defaultValue: string;
  required?: boolean;
  multiline?: boolean;
  type?: string;
}) {
  const base =
    'w-full rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong ' +
    'placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30 ' +
    'transition-shadow duration-150';

  return (
    <div>
      <label className="mb-1 block text-xs font-[700] uppercase tracking-wide text-muted">
        {label}
        {required && <span className="ml-1 text-[color:var(--yd-color-danger)]">*</span>}
      </label>
      {multiline ? (
        <textarea
          name={name}
          defaultValue={defaultValue}
          rows={3}
          className={`${base} resize-none`}
        />
      ) : (
        <input
          name={name}
          type={type}
          defaultValue={defaultValue}
          required={required}
          className={base}
        />
      )}
    </div>
  );
}
