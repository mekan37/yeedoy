'use client';

import { useState, useTransition } from 'react';
import { PanelActionButton } from '@/src/ui/bilesenler/panel-eylem-dugmesi';
import { saveHours } from './saat-islemleri';

// day_of_week: 0=Pazar, 1=Paz, ..., 6=Cumartesi (matches business_weekly_hours)
export type WeeklyHourRow = {
  day_of_week: number;
  open_time: string;
  close_time: string;
  is_closed: boolean;
};

const DAYS = [
  { key: 'mon', label: 'Pazartesi', dow: 1 },
  { key: 'tue', label: 'Salı', dow: 2 },
  { key: 'wed', label: 'Çarşamba', dow: 3 },
  { key: 'thu', label: 'Perşembe', dow: 4 },
  { key: 'fri', label: 'Cuma', dow: 5 },
  { key: 'sat', label: 'Cumartesi', dow: 6 },
  { key: 'sun', label: 'Pazar', dow: 0 },
] as const;

export function HoursForm({
  businessId,
  hours,
}: {
  businessId: string;
  hours: WeeklyHourRow[] | null;
}) {
  const [isPending, startTransition] = useTransition();
  const [saved, setSaved] = useState(false);

  // Index weekly rows by day_of_week for O(1) lookup
  const byDow = new Map<number, WeeklyHourRow>(
    (hours ?? []).map((r) => [r.day_of_week, r]),
  );

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
        {DAYS.map(({ key, label, dow }) => {
          const row = byDow.get(dow);
          const openVal = row && !row.is_closed ? row.open_time.slice(0, 5) : '';
          const closeVal = row && !row.is_closed ? row.close_time.slice(0, 5) : '';
          return (
            <div key={key} className="grid grid-cols-[120px_1fr_1fr] items-center gap-3">
              <span className="text-sm font-[700] text-textStrong">{label}</span>
              <TimeInput name={`${key}_open`} defaultValue={openVal} placeholder="09:00" />
              <TimeInput name={`${key}_close`} defaultValue={closeVal} placeholder="22:00" />
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
