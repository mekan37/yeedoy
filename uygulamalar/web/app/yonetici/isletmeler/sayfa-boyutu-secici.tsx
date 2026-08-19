'use client';

export function SayfaBoyutuSecici({ options, value }: { options: number[]; value: number }) {
  return (
    <select
      name="size"
      defaultValue={String(value)}
      onChange={(e) => e.currentTarget.form?.submit()}
      className="rounded-lg border border-border bg-bg px-2 py-1 text-xs font-bold text-textStrong"
    >
      {options.map((s) => (
        <option key={s} value={s}>{s}</option>
      ))}
    </select>
  );
}
