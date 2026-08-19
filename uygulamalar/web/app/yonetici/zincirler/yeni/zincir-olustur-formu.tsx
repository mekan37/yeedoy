'use client';

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';

export function ZincirOlusturFormu() {
  const router = useRouter();
  const [pending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);

  function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setError(null);
    const fd = new FormData(e.currentTarget);
    const name = String(fd.get('name') ?? '').trim();
    if (!name) {
      setError('Zincir adı zorunludur.');
      return;
    }
    startTransition(async () => {
      const supabase = createSupabaseBrowserClient();
      const { data, error: rpcError } = await (supabase as any).rpc('admin_create_chain_v1', {
        p_name: name,
        p_slug: String(fd.get('slug') ?? '').trim() || null,
        p_category: String(fd.get('category') ?? '').trim() || null,
        p_description: String(fd.get('description') ?? '').trim() || null,
        p_website: String(fd.get('website') ?? '').trim() || null,
      });
      if (rpcError || !data?.ok) {
        setError('Zincir oluşturulamadı. Lütfen tekrar deneyin.');
        return;
      }
      router.push(`/yonetici/zincirler/${data.chain_id}`);
      router.refresh();
    });
  }

  return (
    <form onSubmit={handleSubmit} className="flex flex-col gap-4 rounded-2xl border border-border bg-card p-5">
      <Alan label="Zincir Adı" htmlFor="name" required>
        <input id="name" name="name" required maxLength={120} placeholder="ör. Starbucks Türkiye" className={INPUT_CLASS} />
      </Alan>
      <Alan label="Slug" htmlFor="slug">
        <input id="slug" name="slug" maxLength={80} placeholder="ör. starbucks-turkiye" className={INPUT_CLASS} />
      </Alan>
      <Alan label="Kategori" htmlFor="category">
        <input id="category" name="category" maxLength={60} placeholder="ör. Kafe" className={INPUT_CLASS} />
      </Alan>
      <Alan label="Website" htmlFor="website">
        <input id="website" name="website" type="url" maxLength={200} placeholder="https://..." className={INPUT_CLASS} />
      </Alan>
      <Alan label="Açıklama" htmlFor="description">
        <textarea id="description" name="description" rows={3} maxLength={500} className={INPUT_CLASS} />
      </Alan>

      {error && <p className="rounded-xl bg-danger/10 px-3 py-2.5 text-sm font-bold text-danger">{error}</p>}

      <button
        type="submit"
        disabled={pending}
        className="flex min-h-11 items-center justify-center rounded-xl bg-primary px-4 text-sm font-extrabold text-white transition-opacity hover:opacity-90 disabled:opacity-50"
      >
        {pending ? 'Oluşturuluyor…' : 'Zinciri Oluştur'}
      </button>
    </form>
  );
}

const INPUT_CLASS = 'w-full rounded-xl border border-border bg-bg px-3 py-2.5 text-sm text-textStrong outline-hidden focus:border-primary focus:ring-2 focus:ring-primary/20';

function Alan({ label, htmlFor, required, children }: { label: string; htmlFor: string; required?: boolean; children: React.ReactNode }) {
  return (
    <div>
      <label htmlFor={htmlFor} className="mb-1.5 block text-xs font-bold text-muted">
        {label}{required && <span className="text-danger"> *</span>}
      </label>
      {children}
    </div>
  );
}
