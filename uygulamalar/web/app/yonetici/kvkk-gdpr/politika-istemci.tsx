'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';

interface LegalDocument {
  id: string;
  slug: string;
  title: string;
  description: string | null;
  content: string;
  is_published: boolean;
  sort_order: number;
  updated_at: string;
}

type FormState = {
  id: string | null;
  slug: string;
  title: string;
  description: string;
  content: string;
  is_published: boolean;
  sort_order: number;
};

const EMPTY_FORM: FormState = { id: null, slug: '', title: '', description: '', content: '', is_published: false, sort_order: 0 };

async function apiPost(body: Record<string, unknown>) {
  return fetch('/sunucu/yonetici/kvkk-gdpr', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
}

export function PolitikaYonetimi({ documents }: { documents: LegalDocument[] }) {
  const router = useRouter();
  const [pending, setPending] = useState<string | null>(null);
  const [form, setForm] = useState<FormState | null>(null);
  const [error, setError] = useState<string | null>(null);

  function openEdit(doc: LegalDocument) {
    setForm({ id: doc.id, slug: doc.slug, title: doc.title, description: doc.description ?? '', content: doc.content, is_published: doc.is_published, sort_order: doc.sort_order });
    setError(null);
  }

  function openNew() {
    setForm({ ...EMPTY_FORM, sort_order: documents.length });
    setError(null);
  }

  async function save(e: React.FormEvent) {
    e.preventDefault();
    if (!form) return;
    setPending('save');
    setError(null);
    try {
      const res = await apiPost({
        id: form.id, slug: form.slug.trim(), title: form.title.trim(),
        description: form.description.trim() || null, content: form.content,
        isPublished: form.is_published, sortOrder: form.sort_order,
      });
      if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        setError(body.error ?? 'Kaydedilemedi');
        return;
      }
      setForm(null);
      router.refresh();
    } finally {
      setPending(null);
    }
  }

  async function remove(doc: LegalDocument) {
    if (!confirm(`"${doc.title}" belgesi silinecek. Devam et?`)) return;
    setPending(doc.id);
    try {
      await fetch('/sunucu/yonetici/kvkk-gdpr', {
        method: 'DELETE',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id: doc.id }),
      });
      router.refresh();
    } finally {
      setPending(null);
    }
  }

  return (
    <div className="flex flex-col gap-4">
      <div className="overflow-hidden rounded-xl border border-border">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-border bg-zinc-50 text-left">
              <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Belge</th>
              <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Slug</th>
              <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Durum</th>
              <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Güncellendi</th>
              <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted" />
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {documents.length === 0 && (
              <tr><td colSpan={5} className="px-4 py-6 text-center text-xs text-muted">Henüz belge yok.</td></tr>
            )}
            {documents.map((doc) => (
              <tr key={doc.id} className="hover:bg-black/2">
                <td className="px-4 py-3">
                  <p className="font-bold text-textStrong">{doc.title}</p>
                  {doc.description && <p className="text-[10px] text-muted">{doc.description}</p>}
                </td>
                <td className="px-4 py-3">
                  <code className="text-xs text-muted">/yasal/{doc.slug}</code>
                </td>
                <td className="px-4 py-3">
                  <span className={`inline-flex rounded-full px-2 py-0.5 text-[10px] font-bold ${doc.is_published ? 'bg-emerald-50 text-emerald-700' : 'bg-zinc-100 text-zinc-500'}`}>
                    {doc.is_published ? 'Yayında' : 'Taslak'}
                  </span>
                </td>
                <td className="px-4 py-3 text-xs text-muted">{new Date(doc.updated_at).toLocaleDateString('tr-TR')}</td>
                <td className="px-4 py-3 text-right">
                  <button type="button" onClick={() => openEdit(doc)} className="mr-3 text-xs font-bold text-primary hover:underline">Düzenle</button>
                  <button type="button" onClick={() => remove(doc)} disabled={pending === doc.id} className="text-xs font-bold text-danger hover:underline disabled:opacity-50">Sil</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {form ? (
        <form onSubmit={save} className="flex flex-col gap-3 rounded-xl border border-border p-4">
          <div className="grid gap-3 sm:grid-cols-2">
            <div className="flex flex-col gap-1">
              <label className="text-[11px] font-bold text-muted">Başlık</label>
              <input value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} required maxLength={120} className="input-yd rounded-lg px-2.5 py-1.5 text-sm" />
            </div>
            <div className="flex flex-col gap-1">
              <label className="text-[11px] font-bold text-muted">Slug (/yasal/...)</label>
              <input value={form.slug} onChange={(e) => setForm({ ...form, slug: e.target.value })} required pattern="[a-z0-9]+(-[a-z0-9]+)*" className="input-yd rounded-lg px-2.5 py-1.5 text-sm font-mono" placeholder="ornek-belge" />
            </div>
          </div>
          <div className="flex flex-col gap-1">
            <label className="text-[11px] font-bold text-muted">Kısa Açıklama</label>
            <input value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} maxLength={200} className="input-yd rounded-lg px-2.5 py-1.5 text-sm" />
          </div>
          <div className="flex flex-col gap-1">
            <label className="text-[11px] font-bold text-muted">İçerik (Markdown — ## başlık, **kalın**)</label>
            <textarea value={form.content} onChange={(e) => setForm({ ...form, content: e.target.value })} required rows={12} className="input-yd rounded-lg px-2.5 py-2 text-xs font-mono leading-6" />
          </div>
          <div className="flex flex-wrap items-center gap-4">
            <label className="flex items-center gap-2 text-sm font-bold text-textStrong">
              <input type="checkbox" checked={form.is_published} onChange={(e) => setForm({ ...form, is_published: e.target.checked })} />
              Yayında
            </label>
            <div className="flex items-center gap-2">
              <label className="text-[11px] font-bold text-muted">Sıra</label>
              <input type="number" value={form.sort_order} onChange={(e) => setForm({ ...form, sort_order: parseInt(e.target.value, 10) || 0 })} className="input-yd w-20 rounded-lg px-2.5 py-1.5 text-xs" />
            </div>
          </div>
          {error && <p className="text-xs font-bold text-danger">{error}</p>}
          <div className="flex gap-2">
            <button type="submit" disabled={pending === 'save'} className="rounded-xl bg-primary px-4 py-2 text-sm font-extrabold text-white disabled:opacity-50">
              {pending === 'save' ? 'Kaydediliyor…' : 'Kaydet'}
            </button>
            <button type="button" onClick={() => setForm(null)} className="rounded-xl border border-border px-4 py-2 text-sm font-bold text-muted hover:text-textStrong">İptal</button>
          </div>
        </form>
      ) : (
        <button type="button" onClick={openNew} className="self-start rounded-xl border border-border px-4 py-2 text-sm font-extrabold text-textStrong hover:border-primary/30 hover:text-primary">
          + Yeni Belge
        </button>
      )}
    </div>
  );
}
