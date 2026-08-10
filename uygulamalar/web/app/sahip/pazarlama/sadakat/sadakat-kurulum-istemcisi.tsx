'use client';

import { useActionState, useState } from 'react';
import { programOlustur, programAktiflikDegistir } from './sadakat-islemleri';

export type SadakatProgram = {
  id: string;
  mode: 'stamp' | 'points';
  name: string;
  reward_desc: string;
  reward_threshold: number;
  is_active: boolean;
};

export function SadakatKurulumIstemcisi({
  businessId,
  program,
}: {
  businessId: string;
  program: SadakatProgram | null;
}) {
  const [state, formAction, pending] = useActionState(programOlustur, null);
  const [mode, setMode] = useState<'stamp' | 'points'>('stamp');
  const [toggling, setToggling] = useState(false);
  const [toggleError, setToggleError] = useState<string | null>(null);

  if (program) {
    return (
      <div className="space-y-3">
        <div className="flex items-center justify-between gap-4">
          <div>
            <p className="text-sm font-black text-textStrong">{program.name}</p>
            <p className="text-xs text-muted">
              {program.reward_desc} — eşik: {program.reward_threshold}
            </p>
          </div>
          <button
            type="button"
            disabled={toggling}
            onClick={async () => {
              setToggling(true);
              setToggleError(null);
              const result = await programAktiflikDegistir(program.id, !program.is_active);
              if ('error' in result) setToggleError(result.error);
              setToggling(false);
            }}
            className={
              program.is_active
                ? 'rounded-full bg-emerald-50 px-3 py-1.5 text-xs font-bold text-emerald-700 disabled:opacity-50'
                : 'rounded-full bg-zinc-100 px-3 py-1.5 text-xs font-bold text-zinc-500 disabled:opacity-50'
            }
          >
            {program.is_active ? 'Aktif — kapat' : 'Pasif — aktive et'}
          </button>
        </div>
        {toggleError && <p className="text-xs font-bold text-red-600">{toggleError}</p>}
      </div>
    );
  }

  return (
    <form action={formAction} className="space-y-3">
      <input type="hidden" name="business_id" value={businessId} />
      <input type="hidden" name="mode" value={mode} />
      <div>
        <p className="mb-1.5 text-xs font-bold uppercase tracking-wide text-muted">Program Modu</p>
        <div className="flex gap-2">
          <button
            type="button"
            onClick={() => setMode('stamp')}
            className={
              mode === 'stamp'
                ? 'rounded-xl bg-primary px-3 py-2 text-sm font-bold text-white'
                : 'rounded-xl border border-border px-3 py-2 text-sm font-bold text-textStrong'
            }
          >
            Damga Kartı
          </button>
          <button
            type="button"
            onClick={() => setMode('points')}
            className={
              mode === 'points'
                ? 'rounded-xl bg-primary px-3 py-2 text-sm font-bold text-white'
                : 'rounded-xl border border-border px-3 py-2 text-sm font-bold text-textStrong'
            }
          >
            Puan Sistemi
          </button>
        </div>
      </div>
      <input
        name="name"
        placeholder="Program adı — örn. Kahve Sadakat"
        required
        maxLength={80}
        className="w-full rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong"
      />
      <input
        name="reward_desc"
        placeholder="Ödül açıklaması — örn. 1 bedava filtre kahve"
        required
        maxLength={200}
        className="w-full rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong"
      />
      <input
        name="reward_threshold"
        type="number"
        min={1}
        max={1000}
        placeholder={mode === 'stamp' ? 'Eşik — örn. 10 damga' : 'Eşik — örn. 500 puan'}
        required
        className="w-full rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong"
      />
      {state && 'error' in state && <p className="text-xs font-bold text-red-600">{state.error}</p>}
      <button
        type="submit"
        disabled={pending}
        className="rounded-xl bg-primary px-4 py-2 text-sm font-bold text-white hover:opacity-90 disabled:opacity-50"
      >
        {pending ? 'Oluşturuluyor…' : 'Programı Oluştur'}
      </button>
    </form>
  );
}
