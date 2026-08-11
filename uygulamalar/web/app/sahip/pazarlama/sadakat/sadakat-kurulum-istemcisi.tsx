'use client';

import { useActionState, useState } from 'react';
import { programOlustur, programAktiflikDegistir, programGuncelle, programSil } from './sadakat-islemleri';

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
  const [editing, setEditing] = useState(false);
  const [editPending, setEditPending] = useState(false);
  const [editError, setEditError] = useState<string | null>(null);
  const [deleting, setDeleting] = useState(false);
  const [deleteError, setDeleteError] = useState<string | null>(null);

  if (program) {
    if (editing) {
      return (
        <form
          onSubmit={async (e) => {
            e.preventDefault();
            const formData = new FormData(e.currentTarget);
            setEditPending(true);
            setEditError(null);
            const result = await programGuncelle(
              program.id,
              String(formData.get('name') ?? ''),
              String(formData.get('reward_desc') ?? ''),
              Number(formData.get('reward_threshold')),
            );
            setEditPending(false);
            if ('error' in result) {
              setEditError(result.error);
              return;
            }
            setEditing(false);
          }}
          className="space-y-3"
        >
          <input
            name="name"
            defaultValue={program.name}
            required
            maxLength={80}
            className="w-full rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong"
          />
          <input
            name="reward_desc"
            defaultValue={program.reward_desc}
            required
            maxLength={200}
            className="w-full rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong"
          />
          <input
            name="reward_threshold"
            type="number"
            min={1}
            max={1000}
            defaultValue={program.reward_threshold}
            required
            className="w-full rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong"
          />
          {editError && <p className="text-xs font-bold text-red-600">{editError}</p>}
          <div className="flex gap-2">
            <button
              type="submit"
              disabled={editPending}
              className="rounded-xl bg-primary px-4 py-2 text-sm font-bold text-white hover:opacity-90 disabled:opacity-50"
            >
              {editPending ? 'Kaydediliyor…' : 'Kaydet'}
            </button>
            <button
              type="button"
              onClick={() => setEditing(false)}
              className="rounded-xl border border-border px-4 py-2 text-sm font-bold text-textStrong"
            >
              Vazgeç
            </button>
          </div>
        </form>
      );
    }

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
        <div className="flex gap-2 border-t border-border pt-3">
          <button
            type="button"
            onClick={() => setEditing(true)}
            className="rounded-xl border border-border px-3 py-1.5 text-xs font-bold text-textStrong"
          >
            Düzenle
          </button>
          <button
            type="button"
            disabled={deleting}
            onClick={async () => {
              if (
                !confirm(
                  `"${program.name}" programı ve tüm üye/tarama geçmişi kalıcı olarak silinecek. Onaylıyor musunuz?`,
                )
              )
                return;
              setDeleting(true);
              setDeleteError(null);
              const result = await programSil(program.id);
              if ('error' in result) setDeleteError(result.error);
              setDeleting(false);
            }}
            className="rounded-xl border border-red-200 px-3 py-1.5 text-xs font-bold text-red-600 disabled:opacity-50"
          >
            {deleting ? 'Siliniyor…' : 'Programı Sil'}
          </button>
        </div>
        {deleteError && <p className="text-xs font-bold text-red-600">{deleteError}</p>}
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
