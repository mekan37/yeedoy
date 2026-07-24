'use client';

import { useActionState } from 'react';
import { submitNewBusiness } from '@/app/sahip/isletmeler/yeni/yeni-isletme-islemleri';

const CATEGORIES = [
  'Restoran', 'Kafe', 'Pastane', 'Fast Food', 'Dönerci', 'Pide / Lahmacun',
  'Pizza', 'Burger', 'Balık', 'Çorba', 'Tatlıcı', 'Kahvaltı', 'Diğer',
];

const INPUT_CLS = 'min-h-11 w-full rounded-xl border border-border bg-bg px-3 text-sm font-bold text-textStrong outline-hidden focus:ring-2 focus:ring-primary/30';

export function YeniIsletmeFormu() {
  const [state, action, isPending] = useActionState(submitNewBusiness, null);

  return (
    <div className="overflow-hidden rounded-2xl border border-border bg-bg">
      <form action={action} className="space-y-4 p-5">

        <div className="flex flex-col gap-1.5">
          <label className="text-xs font-extrabold text-muted">İşletme Adı *</label>
          <input name="name" required placeholder="Restoran / kafe adı" className={INPUT_CLS} />
        </div>

        <div className="flex flex-col gap-1.5">
          <label className="text-xs font-extrabold text-muted">Kategori *</label>
          <select name="category" required className={INPUT_CLS}>
            <option value="">Seçin…</option>
            {CATEGORIES.map((c) => <option key={c} value={c}>{c}</option>)}
          </select>
        </div>

        <div className="grid grid-cols-2 gap-3">
          <div className="flex flex-col gap-1.5">
            <label className="text-xs font-extrabold text-muted">Şehir *</label>
            <input name="city" required placeholder="Ankara" className={INPUT_CLS} />
          </div>
          <div className="flex flex-col gap-1.5">
            <label className="text-xs font-extrabold text-muted">İlçe *</label>
            <input name="district" required placeholder="Yenimahalle" className={INPUT_CLS} />
          </div>
        </div>

        <div className="flex flex-col gap-1.5">
          <label className="text-xs font-extrabold text-muted">Adres *</label>
          <textarea
            name="address"
            required
            rows={2}
            placeholder="Mahalle, sokak, bina no…"
            className="rounded-xl border border-border bg-bg px-3 py-2.5 text-sm font-bold text-textStrong outline-hidden focus:ring-2 focus:ring-primary/30"
          />
        </div>

        <div className="grid grid-cols-2 gap-3">
          <div className="flex flex-col gap-1.5">
            <label className="text-xs font-extrabold text-muted">Telefon</label>
            <input name="phone" type="tel" placeholder="05XX XXX XX XX" className={INPUT_CLS} />
          </div>
          <div className="flex flex-col gap-1.5">
            <label className="text-xs font-extrabold text-muted">Web Sitesi</label>
            <input name="website" type="url" placeholder="https://…" className={INPUT_CLS} />
          </div>
        </div>

        <div className="rounded-xl border border-blue-100 bg-blue-50 px-4 py-3 text-xs text-blue-800">
          <p className="font-extrabold">Başvuru süreci</p>
          <p className="mt-0.5">Bilgileriniz 1–3 iş günü içinde incelenir. Onay sonrası işletmeniz platforma eklenir ve sizi e-posta ile bilgilendiririz.</p>
        </div>

        {state?.error && (
          <div className="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm font-bold text-red-700">
            {state.error}
          </div>
        )}

        <button
          type="submit"
          disabled={isPending}
          className="w-full rounded-xl bg-primary py-3.5 text-sm font-black text-white transition-opacity hover:opacity-90 disabled:opacity-60"
        >
          {isPending ? 'Gönderiliyor…' : 'Başvuruyu Gönder →'}
        </button>
      </form>
    </div>
  );
}
