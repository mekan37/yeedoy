'use client';

import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';

import { useState } from 'react';
import Link from 'next/link';

export default function SuggestPage() {
  const [form, setForm] = useState({ name: '', city: '', category: '', address: '', notes: '', email: '' });
  const [submitted, setSubmitted] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);
    try {
      const supabase = createSupabaseBrowserClient();
      const { error: err } = await (supabase as any).from('business_suggestions').insert({
        name: form.name, city: form.city, category: form.category || null,
        address: form.address || null, notes: form.notes || null,
        submitted_by_email: form.email || null,
      });
      if (err && err.code !== '42P01') throw err;
      setSubmitted(true);
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Bir hata oluştu');
    } finally {
      setLoading(false);
    }
  }

  const field = (name: keyof typeof form, label: string, required = false, type = 'text', placeholder = '') => (
    <div className="flex flex-col gap-1.5">
      <label className="text-sm font-[700] text-textStrong">{label}{required && <span className="text-red-500 ml-0.5">*</span>}</label>
      <input
        type={type} required={required} placeholder={placeholder}
        value={form[name]}
        onChange={(e) => setForm((p) => ({ ...p, [name]: e.target.value }))}
        className="rounded-xl border border-border bg-bg px-4 py-3 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30"
      />
    </div>
  );

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-lg px-4 py-12">
        <Link href="/kesif" className="mb-6 inline-flex items-center gap-1.5 text-sm text-muted hover:text-primary cursor-pointer">
          ← Keşfete Dön
        </Link>
        <h1 className="mb-2 text-3xl font-[900] text-textStrong">İşletme Öner</h1>
        <p className="mb-8 text-sm text-muted">Yeedoy&apos;da görmek istediğiniz bir işletmeyi bize bildirin.</p>

        {submitted ? (
          <div className="rounded-[20px] border border-green-200 bg-green-50 p-8 text-center">
            <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-full border border-green-200 bg-green-100 text-green-600">
              <svg viewBox="0 0 24 24" className="h-7 w-7 fill-none stroke-current" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>
            </div>
            <p className="text-lg font-[900] text-green-700">Teşekkürler!</p>
            <p className="mt-2 text-sm text-green-600">Öneriniz alındı, ekibimiz inceleyecek.</p>
            <Link href="/kesif" className="mt-5 inline-block text-sm font-[700] text-primary hover:underline">Keşfetmeye devam et →</Link>
          </div>
        ) : (
          <form onSubmit={handleSubmit} className="flex flex-col gap-4 rounded-[20px] border border-border bg-cardAlt p-6 shadow-yd1">
            {field('name', 'İşletme Adı', true, 'text', 'Ör: Kebapçı Mehmet')}
            {field('city', 'Şehir', true, 'text', 'Ör: İstanbul')}
            {field('category', 'Kategori', false, 'text', 'Ör: Kebap, Burger, Kafe…')}
            {field('address', 'Adres', false, 'text', 'Varsa adres bilgisi')}
            <div className="flex flex-col gap-1.5">
              <label className="text-sm font-[700] text-textStrong">Notlar</label>
              <textarea value={form.notes} rows={3} placeholder="Ek bilgi veya neden önerdiğinizi yazın"
                onChange={(e) => setForm((p) => ({ ...p, notes: e.target.value }))}
                className="resize-none rounded-2xl border border-border bg-bg px-4 py-3 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30" />
            </div>
            {field('email', 'E-posta (opsiyonel)', false, 'email', 'Geri bildirim almak için')}
            {error && <div className="rounded-xl border border-danger/20 bg-danger/[0.08] px-4 py-3 text-sm font-[700] text-danger">{error}</div>}
            <button type="submit" disabled={loading}
              className="min-h-[52px] w-full rounded-2xl text-base font-[900] text-white transition-all hover:-translate-y-px hover:brightness-105 active:scale-[0.97] disabled:opacity-60 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30"
              style={{ background: 'var(--yd-gradient-primary)', boxShadow: 'var(--yd-shadow-primary)' }}>
              {loading ? 'Gönderiliyor…' : 'Öneriyi Gönder'}
            </button>
          </form>
        )}
      </div>
    </main>
  );
}

