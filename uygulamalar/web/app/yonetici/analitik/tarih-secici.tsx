'use client';

const TARIH_SECENEKLERI = [
  { value: 'all', label: 'Tüm Zamanlar' },
  { value: '7d', label: 'Son 7 Gün' },
  { value: '30d', label: 'Son 30 Gün' },
  { value: '90d', label: 'Son 90 Gün' },
];

export function TarihSecici({ value }: { value: string }) {
  return (
    <select
      name="tarih"
      defaultValue={value}
      onChange={(e) => e.currentTarget.form?.submit()}
      className="min-h-11 rounded-xl border border-border bg-card px-3 py-2 text-sm font-bold text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30"
    >
      {TARIH_SECENEKLERI.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
    </select>
  );
}
