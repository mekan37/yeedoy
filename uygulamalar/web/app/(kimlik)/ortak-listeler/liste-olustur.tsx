'use client';

import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';

export function ListeOlusturButonu() {
  const [open, setOpen] = useState(false);
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [pending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);
  const router = useRouter();

  function reset() { setTitle(''); setDescription(''); setError(null); setOpen(false); }

  function submit(e: React.FormEvent) {
    e.preventDefault();
    if (!title.trim()) { setError('Liste adı zorunludur'); return; }
    setError(null);
    startTransition(async () => {
      try {
        const supabase = createSupabaseBrowserClient();
        const { data: { user } } = await supabase.auth.getUser();
        if (!user) throw new Error('Oturum bulunamadı');

        const token = Math.random().toString(36).slice(2, 10);
        const { data: list, error: err } = await (supabase as any)
          .from('collab_lists')
          .insert({ title: title.trim(), description: description.trim() || null, owner_id: user.id, invite_token: token })
          .select('id')
          .single() as { data: { id: string } | null; error: any };
        if (err) throw new Error(err.message);

        // Auto-join as owner member
        await (supabase as any).from('collab_list_members').insert({ list_id: list!.id, user_id: user.id, role: 'owner' });

        reset();
        router.push(`/ortak-listeler/${list!.id}`);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Bir hata oluştu');
      }
    });
  }

  if (!open) {
    return (
      <button
        type="button"
        onClick={() => setOpen(true)}
        className="inline-flex min-h-[40px] items-center gap-2 rounded-xl px-4 text-sm font-[900] text-white"
        style={{ background: 'var(--yd-gradient-primary)' }}
      >
        + Yeni Liste
      </button>
    );
  }

  return (
    <form onSubmit={submit} className="mb-6 rounded-2xl border border-border bg-card p-5">
      <div className="mb-4 flex items-center justify-between">
        <h2 className="text-base font-[900] text-textStrong">Yeni Liste Oluştur</h2>
        <button type="button" onClick={reset} className="text-sm text-muted hover:text-primary">İptal</button>
      </div>
      <div className="flex flex-col gap-3">
        <input
          value={title} onChange={(e) => setTitle(e.target.value)}
          placeholder="Liste adı *"
          className="w-full rounded-xl border border-border bg-bg px-4 py-2.5 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30"
        />
        <textarea
          value={description} onChange={(e) => setDescription(e.target.value)}
          placeholder="Açıklama (opsiyonel)"
          rows={2}
          className="w-full resize-none rounded-xl border border-border bg-bg px-4 py-2.5 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30"
        />
        {error && <p className="text-sm text-danger">{error}</p>}
        <button
          type="submit"
          disabled={pending || !title.trim()}
          className="min-h-[44px] rounded-xl text-sm font-[900] text-white disabled:opacity-50"
          style={{ background: 'var(--yd-gradient-primary)' }}
        >
          {pending ? 'Oluşturuluyor…' : 'Oluştur'}
        </button>
      </div>
    </form>
  );
}
