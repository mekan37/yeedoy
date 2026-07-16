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
  const [error, setError] = useState<string | null>(null);

  // Index weekly rows by day_of_week for O(1) lookup
  const byDow = new Map<number, WeeklyHourRow>(
    (hours ?? []).map((r) => [r.day_of_week, r]),
  );

  function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const fd = new FormData(e.currentTarget);
    setSaved(false);
    setError(null);
    startTransition(async () => {
      try {
        await saveHours(businessId, fd);
        setSaved(true);
        setTimeout(() => setSaved(false), 3000);
      } catch (saveError) {
        setError(
          saveError instanceof Error
            ? saveError.message
            : 'Çalışma saatleri kaydedilemedi. Lütfen tekrar deneyin.',
        );
      }
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
              <TimeInput
                id={`hours-${key}-open`}
                name={`${key}_open`}
                label={`${label} açılış saati`}
                defaultValue={openVal}
                placeholder="09:00"
              />
              <TimeInput
                id={`hours-${key}-close`}
                name={`${key}_close`}
                label={`${label} kapanış saati`}
                defaultValue={closeVal}
                placeholder="22:00"
              />
            </div>
          );
        })}
      </div>

      <div className="mt-5 flex flex-wrap items-center gap-3">
        <PanelActionButton type="submit" variant="primary" loading={isPending}>
          Kaydet
        </PanelActionButton>
        {error && (
          <p role="alert" className="text-sm font-[700] text-danger">
            {error}
          </p>
        )}
        {saved && (
          <p role="status" aria-live="polite" className="text-sm font-[700] text-green-600">
            Kaydedildi
          </p>
        )}
      </div>
    </form>
  );
}

function TimeInput({
  id,
  name,
  label,
  defaultValue,
  placeholder,
}: {
  id: string;
  name: string;
  label: string;
  defaultValue: string;
  placeholder: string;
}) {
  return (
    <div className="min-w-0">
      <label htmlFor={id} className="sr-only">
        {label}
      </label>
      <input
        id={id}
        type="time"
        name={name}
        defaultValue={defaultValue}
        placeholder={placeholder}
        className="w-full min-w-0 rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/30"
      />
    </div>
  );
}
