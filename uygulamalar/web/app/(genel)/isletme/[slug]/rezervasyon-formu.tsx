'use client';

import { useActionState } from 'react';
import { submitReservation } from './rezervasyon-actions';

interface Props {
  businessId: string;
  businessName: string;
  minParty: number;
  maxParty: number;
  reservationNote: string | null;
  reservationPhone: string | null;
}

export function ReservasyonFormu({
  businessId,
  businessName,
  minParty,
  maxParty,
  reservationNote,
  reservationPhone,
}: Props) {
  const [state, action, pending] = useActionState(submitReservation, null);

  // Minimum date: tomorrow
  const minDate = new Date();
  minDate.setDate(minDate.getDate() + 1);
  const minDateStr = minDate.toISOString().split('T')[0];

  if (state?.success) {
    return (
      <div className="rounded-2xl border border-green-200 bg-green-50 p-6 text-center">
        <div className="mb-3 text-3xl text-green-600">&#10003;</div>
        <p className="text-base font-bold text-green-800">Rezervasyonunuz alındı!</p>
        <p className="mt-1 text-sm text-green-700">
          Rezervasyon No:{' '}
          <span className="font-mono font-black">{state.reservationNo}</span>
        </p>
        <p className="mt-2 text-xs text-green-600">
          {businessName} ekibi en kısa sürede onaylayacak.
          {reservationPhone && (
            <> Sorularınız için: <strong>{reservationPhone}</strong></>
          )}
        </p>
      </div>
    );
  }

  return (
    <form action={action} className="flex flex-col gap-4">
      <input type="hidden" name="business_id" value={businessId} />

      <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
        <div>
          <label className="mb-1 block text-xs font-bold text-textMuted">Ad Soyad *</label>
          <input
            name="guest_name"
            required
            minLength={2}
            maxLength={100}
            placeholder="Adınız Soyadınız"
            className="w-full rounded-xl border border-border bg-bgSubtle px-3 py-2.5 text-sm text-textStrong placeholder:text-textMuted focus:outline-none focus:ring-2 focus:ring-primary/20"
          />
        </div>
        <div>
          <label className="mb-1 block text-xs font-bold text-textMuted">Telefon *</label>
          <input
            name="guest_phone"
            type="tel"
            required
            minLength={10}
            maxLength={20}
            placeholder="05xx xxx xx xx"
            className="w-full rounded-xl border border-border bg-bgSubtle px-3 py-2.5 text-sm text-textStrong placeholder:text-textMuted focus:outline-none focus:ring-2 focus:ring-primary/20"
          />
        </div>
        <div>
          <label className="mb-1 block text-xs font-bold text-textMuted">Tarih *</label>
          <input
            name="reservation_date"
            type="date"
            required
            min={minDateStr}
            className="w-full rounded-xl border border-border bg-bgSubtle px-3 py-2.5 text-sm text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/20"
          />
        </div>
        <div>
          <label className="mb-1 block text-xs font-bold text-textMuted">Saat *</label>
          <input
            name="reservation_time"
            type="time"
            required
            className="w-full rounded-xl border border-border bg-bgSubtle px-3 py-2.5 text-sm text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/20"
          />
        </div>
        <div>
          <label className="mb-1 block text-xs font-bold text-textMuted">
            Kişi Sayısı * ({minParty}–{maxParty})
          </label>
          <input
            name="party_size"
            type="number"
            required
            min={minParty}
            max={maxParty}
            defaultValue={2}
            className="w-full rounded-xl border border-border bg-bgSubtle px-3 py-2.5 text-sm text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/20"
          />
        </div>
        <div>
          <label className="mb-1 block text-xs font-bold text-textMuted">E-posta</label>
          <input
            name="guest_email"
            type="email"
            placeholder="ornek@email.com"
            className="w-full rounded-xl border border-border bg-bgSubtle px-3 py-2.5 text-sm text-textStrong placeholder:text-textMuted focus:outline-none focus:ring-2 focus:ring-primary/20"
          />
        </div>
      </div>

      <div>
        <label className="mb-1 block text-xs font-bold text-textMuted">Özel İstek</label>
        <textarea
          name="special_request"
          rows={2}
          maxLength={500}
          placeholder="Allerji, masa tercihi, doğum günü vb..."
          className="w-full resize-none rounded-xl border border-border bg-bgSubtle px-3 py-2.5 text-sm text-textStrong placeholder:text-textMuted focus:outline-none focus:ring-2 focus:ring-primary/20"
        />
      </div>

      {reservationNote && (
        <p className="rounded-xl bg-amber-50 px-3 py-2 text-xs text-amber-700">
          {reservationNote}
        </p>
      )}

      {state?.error && (
        <p className="rounded-xl bg-red-50 px-3 py-2 text-sm font-bold text-red-600">
          {state.error}
        </p>
      )}

      <button
        type="submit"
        disabled={pending}
        className="w-full rounded-xl bg-primary py-3 text-sm font-black text-white transition hover:opacity-90 disabled:opacity-50"
      >
        {pending ? 'Gönderiliyor...' : 'Rezervasyon Yap'}
      </button>
    </form>
  );
}
