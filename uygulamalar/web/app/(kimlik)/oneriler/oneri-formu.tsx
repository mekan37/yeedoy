'use client';

import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';

import { useState, useTransition } from 'react';

const CATEGORIES = ['Restoran', 'Kafe', 'Fast Food', 'Dönerci', 'Pizza', 'Burger', 'Pide / Lahmacun', 'Pastane', 'Kahvaltı', 'Diğer'];

export function OneriFormu({ userEmail }: { userEmail: string }) {
  const [open, setOpen] = useState(false);
  const [name, setName] = useState('');
  const [city, setCity] = useState('');
  const [category, setCategory] = useState('');
  const [note, setNote] = useState('');
  const [pending, startTransition] = useTransition();
  const [done, setDone] = useState(false);
  const [error, setError] = useState<string | null>(null);

  function reset() {
    setName(''); setCity(''); setCategory(''); setNote('');
    setError(null); setDone(false); setOpen(false);
  }

  function submit(e: React.FormEvent) {
    e.preventDefault();
    if (!name.trim()) { setError('İşletme adı zorunludur'); return; }
    setError(null);
    startTransition(async () => {
      try {
        const supabase = createSupabaseBrowserClient();
        const { error: err } = await (supabase as any).from('business_suggestions').insert({
          name: name.trim(),
          city: city.trim() || null,
          category: category || null,
          notes: note.trim() || null,
          submitted_by_email: userEmail,
          status: 'pending',
        });
        if (err) throw new Error(err.message);
        setDone(true);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Bir hata oluştu');
      }
    });
  }

  if (done) {
    return (
      <div className="rounded-2xl border border-success/25 bg-success/8 px-5 py-5">
        <p className="font-black text-success">Öneriniz alındı!</p>
        <p className="mt-1 text-sm text-muted">Ekibimiz inceleyecek ve yakında değerlendirme iletecek.</p>
        <button type="button" onClick={reset} className="mt-3 text-sm font-bold text-primary hover:underline">
          Yeni öneri gönder
        </button>
      </div>
    );
  }

  if (!open) {
    return (
      <button
        type="button"
        onClick={() => setOpen(true)}
        className="inline-flex min-h-[44px] items-center gap-2 rounded-2xl px-5 text-sm font-black text-white"
        style={{ background: 'var(--yd-gradient-primary)' }}
      >
        + İşletme Öner
      </button>
    );
  }

  return (
    <form onSubmit={submit} className="rounded-2xl border border-border bg-card p-6">
      <div className="mb-4 flex items-center justify-between">
        <h2 className="text-base font-black text-textStrong">Yeni İşletme Öner</h2>
        <button type="button" onClick={() => setOpen(false)} className="text-sm text-muted hover:text-primary">İptal</button>
      </div>

      <div className="flex flex-col gap-4">
        <div>
          <label className="mb-1.5 block text-sm font-bold text-textStrong">İşletme Adı <span className="text-danger">*</span></label>
          <input
            value={name} onChange={(e) => setName(e.target.value)}
            placeholder="ör: Kebapçı Ahmet"
            className="w-full rounded-xl border border-border bg-bg px-4 py-2.5 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30"
          />
        </div>

        <div className="grid grid-cols-2 gap-3">
          <div>
            <label className="mb-1.5 block text-sm font-bold text-textStrong">Şehir</label>
            <input
              value={city} onChange={(e) => setCity(e.target.value)}
              placeholder="İstanbul"
              className="w-full rounded-xl border border-border bg-bg px-4 py-2.5 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30"
            />
          </div>
          <div>
            <label className="mb-1.5 block text-sm font-bold text-textStrong">Kategori</label>
            <select
              value={category} onChange={(e) => setCategory(e.target.value)}
              className="w-full rounded-xl border border-border bg-bg px-4 py-2.5 text-sm text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30"
            >
              <option value="">Seç…</option>
              {CATEGORIES.map((c) => <option key={c} value={c}>{c}</option>)}
            </select>
          </div>
        </div>

        <div>
          <label className="mb-1.5 block text-sm font-bold text-textStrong">Not (opsiyonel)</label>
          <textarea
            value={note} onChange={(e) => setNote(e.target.value)}
            rows={2} placeholder="Adres veya eklemek istediğiniz bilgi…"
            className="w-full resize-none rounded-xl border border-border bg-bg px-4 py-2.5 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30"
          />
        </div>

        {error && <p className="text-sm text-danger">{error}</p>}

        <button
          type="submit"
          disabled={pending || !name.trim()}
          className="min-h-[48px] rounded-xl text-sm font-black text-white disabled:opacity-50"
          style={{ background: 'var(--yd-gradient-primary)' }}
        >
          {pending ? 'Gönderiliyor…' : 'Öneriyi Gönder'}
        </button>
      </div>
    </form>
  );
}
