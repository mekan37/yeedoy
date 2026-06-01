'use client';

import { useActionState } from 'react';
import { sponsorluguBasvur, type LeadFormState } from './sponsorluk-islemleri';

const initialState: LeadFormState = { ok: false };

type Props = {
  businesses: Array<{ id: string; name: string }>;
};

export function SponsorlukFormu({ businesses }: Props) {
  const [state, formAction, isPending] = useActionState(sponsorluguBasvur, initialState);

  if (state.ok) {
    return (
      <div className="rounded-xl bg-green-50 border border-green-200 p-6 text-center">
        <p className="text-lg font-[800] text-green-800">Başvuru Alındı!</p>
        <p className="mt-1 text-sm text-green-700">{state.message}</p>
      </div>
    );
  }

  return (
    <form action={formAction} className="flex flex-col gap-4">
      {/* İşletme seçimi */}
      <div>
        <label className="block text-sm font-[700] text-textStrong mb-1.5">İşletme *</label>
        <select
          name="business_id"
          required
          className="w-full rounded-xl border border-border bg-card px-3 py-2.5 text-sm text-textStrong focus:outline-none focus:ring-2 focus:ring-primary"
        >
          <option value="">İşletme seçin...</option>
          {businesses.map((b) => (
            <option key={b.id} value={b.id}>{b.name}</option>
          ))}
        </select>
      </div>

      {/* Telefon */}
      <div>
        <label className="block text-sm font-[700] text-textStrong mb-1.5">Telefon (opsiyonel)</label>
        <input
          type="tel"
          name="phone"
          placeholder="0532 xxx xx xx"
          className="w-full rounded-xl border border-border bg-card px-3 py-2.5 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary"
        />
      </div>

      {/* Mesaj */}
      <div>
        <label className="block text-sm font-[700] text-textStrong mb-1.5">Notunuz (opsiyonel)</label>
        <textarea
          name="message"
          rows={3}
          placeholder="Soru veya özel talebiniz varsa buraya yazabilirsiniz..."
          className="w-full rounded-xl border border-border bg-card px-3 py-2.5 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary resize-none"
        />
      </div>

      {/* Hata */}
      {state.error && (
        <p className="rounded-xl bg-red-50 border border-red-200 px-4 py-3 text-sm text-red-700">{state.error}</p>
      )}

      <button
        type="submit"
        disabled={isPending}
        className="w-full rounded-xl bg-primary px-4 py-3 text-sm font-[800] text-white disabled:opacity-60 hover:bg-primary/90 transition-colors"
      >
        {isPending ? 'Gönderiliyor...' : 'Vitrin Paketine Başvur — Ücretsiz Bilgi Al'}
      </button>

      <p className="text-center text-xs text-muted">
        Ödeme alınmaz. Yeedoy ekibi sizinle iletişime geçer.
      </p>
    </form>
  );
}
