'use client';

import { useState, useTransition } from 'react';
import { PanelActionButton } from '@/src/ui/bilesenler/panel-eylem-dugmesi';
import { saveHours } from './saat-islemleri';

type Hours = {
  mon_open: string | null; mon_close: string | null;
  tue_open: string | null; tue_close: string | null;
  wed_open: string | null; wed_close: string | null;
  thu_open: string | null; thu_close: string | null;
  fri_open: string | null; fri_close: string | null;
  sat_open: string | null; sat_close: string | null;
  sun_open: string | null; sun_close: string | null;
} | null;

const DAYS = [
  { key: 'mon', label: 'Pazartesi' },
  { key: 'tue', label: 'Salı' },
  { key: 'wed', label: 'Çarşamba' },
  { key: 'thu', label: 'Perşembe' },
  { key: 'fri', label: 'Cuma' },
  { key: 'sat', label: 'Cumartesi' },
  { key: 'sun', label: 'Pazar' },
] as const;

export function HoursForm({ businessId, hours }: { businessId: string; hours: Hours }) {
  const [isPending, startTransition] = useTransition();
  const [saved, setSaved] = useState(false);

  function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const fd = new FormData(e.currentTarget);
    setSaved(false);
    startTransition(async () => {
      await saveHours(businessId, fd);
      setSaved(true);
      setTimeout(() => setSaved(false), 3000);
    });
  }

  return (
    <form onSubmit={handleSubmit}>
      <div className="space-y-3">
        {DAYS.map(({ key, label }) => {
          const openVal = hours?.[`${key}_open` as keyof Hours] ?? '';
          const closeVal = hours?.[`${key}_close` as keyof Hours] ?? '';
          return (
            <div key={key} className="grid grid-cols-[120px_1fr_1fr] items-center gap-3">
              <span className="text-sm font-[700] text-textStrong">{label}</span>
              <TimeInput name={`${key}_open`} defaultValue={openVal as string} placeholder="09:00" />
              <TimeInput name={`${key}_close`} defaultValue={closeVal as string} placeholder="22:00" />
            </div>
          );
        })}
      </div>

      <div className="mt-5 flex items-center gap-3">
        <PanelActionButton type="submit" variant="primary" loading={isPending}>
          Kaydet
        </PanelActionButton>
        {saved && <p className="text-sm font-[700] text-green-600">Kaydedildi</p>}
      </div>
    </form>
  );
}

function TimeInput({
  name,
  defaultValue,
  placeholder,
}: {
  name: string;
  defaultValue: string;
  placeholder: string;
}) {
  return (
    <input
      type="time"
      name={name}
      defaultValue={defaultValue}
      placeholder={placeholder}
      className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/30"
    />
  );
}
