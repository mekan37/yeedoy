'use client';

import { useActionState } from 'react';
import { PanelActionButton } from '@/src/ui/bilesenler/panel-eylem-dugmesi';
import { submitNewBusiness } from './yeni-isletme-islemleri';

const CATEGORIES = [
  'Restoran', 'Kafe', 'Pastane', 'Fast Food', 'Dönerci', 'Pide / Lahmacun',
  'Pizza', 'Burger', 'Balık', 'Çorba', 'Tatlıcı', 'Kahvaltı', 'Diğer',
];

export function NewBusinessForm() {
  const [state, action, isPending] = useActionState(submitNewBusiness, null);

  return (
    <form action={action} className="space-y-4">
      <Field label="İşletme Adı" name="name" required />
      <div>
        <label className="mb-1 block text-xs font-[700] uppercase tracking-wide text-muted">
          Kategori <span className="text-[color:var(--yd-color-danger)]">*</span>
        </label>
        <select
          name="category"
          required
          className="w-full rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/30"
        >
          <option value="">Seçin...</option>
          {CATEGORIES.map((c) => (
            <option key={c} value={c}>{c}</option>
          ))}
        </select>
      </div>
      <div className="grid grid-cols-2 gap-4">
        <Field label="Şehir" name="city" required placeholder="İstanbul" />
        <Field label="İlçe" name="district" required placeholder="Kadıköy" />
      </div>
      <Field label="Adres" name="address" required multiline placeholder="Mahalle, sokak, bina no..." />
      <Field label="Telefon" name="phone" type="tel" placeholder="+90 555 000 00 00" />
      <Field label="Web Sitesi" name="website" type="url" placeholder="https://..." />

      <div className="rounded-xl border border-amber-200 bg-amber-50 p-4 text-sm text-amber-800">
        <p className="font-[700]">Bilgilendirme</p>
        <p className="mt-1">Başvurunuz ekibimiz tarafından incelenecek ve onaylandıktan sonra yayına alınacaktır. Bu süreç genellikle 1-3 iş günü sürer.</p>
      </div>

      <div className="flex items-center gap-3 pt-2">
        <PanelActionButton type="submit" variant="primary" loading={isPending}>
          Başvuru Gönder
        </PanelActionButton>
        {state?.error && (
          <p className="text-sm font-[700] text-[color:var(--yd-color-danger)]">{state.error}</p>
        )}
      </div>
    </form>
  );
}

function Field({
  label, name, required, multiline, type = 'text', placeholder,
}: {
  label: string; name: string; required?: boolean;
  multiline?: boolean; type?: string; placeholder?: string;
}) {
  const base =
    'w-full rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong ' +
    'placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30 transition-shadow duration-150';
  return (
    <div>
      <label className="mb-1 block text-xs font-[700] uppercase tracking-wide text-muted">
        {label}
        {required && <span className="ml-1 text-[color:var(--yd-color-danger)]">*</span>}
      </label>
      {multiline ? (
        <textarea name={name} rows={3} required={required} placeholder={placeholder}
          className={`${base} resize-none`} />
      ) : (
        <input name={name} type={type} required={required} placeholder={placeholder}
          className={base} />
      )}
    </div>
  );
}
