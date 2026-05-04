'use client';

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
      const { createClient } = await import('@supabase/supabase-js');
      const supabase = createClient(
        process.env.NEXT_PUBLIC_SUPABASE_URL!,
        process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
      );
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
        <Link href="/discover" className="mb-6 inline-flex items-center gap-1.5 text-sm text-muted hover:text-primary cursor-pointer">
          ← Keşfete Dön
        </Link>
        <h1 className="mb-2 text-3xl font-[900] text-textStrong">İşletme Öner</h1>
        <p className="mb-8 text-sm text-muted">Yeedoy&apos;da görmek istediğiniz bir işletmeyi bize bildirin.</p>

        {submitted ? (
          <div className="rounded-2xl bg-green-50 p-6 text-center">
            <p className="text-lg font-[700] text-green-700">Teşekkürler!</p>
            <p className="mt-2 text-sm text-green-600">Öneriniz alındı, inceleyeceğiz.</p>
          </div>
        ) : (
          <form onSubmit={handleSubmit} className="flex flex-col gap-4 rounded-2xl border border-border bg-card p-6">
            {field('name', 'İşletme Adı', true, 'text', 'Ör: Kebapçı Mehmet')}
            {field('city', 'Şehir', true, 'text', 'Ör: İstanbul')}
            {field('category', 'Kategori', false, 'text', 'Ör: Kebap, Burger, Cafe…')}
            {field('address', 'Adres', false, 'text', 'Varsa adres bilgisi')}
            <div className="flex flex-col gap-1.5">
              <label className="text-sm font-[700] text-textStrong">Notlar</label>
              <textarea
                value={form.notes} rows={3} placeholder="Ek bilgi veya neden önerdığinizi yazın"
                onChange={(e) => setForm((p) => ({ ...p, notes: e.target.value }))}
                className="rounded-xl border border-border bg-bg px-4 py-3 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30 resize-none"
              />
            </div>
            {field('email', 'E-posta (opsiyonel)', false, 'email', 'Geri bildirim almak için')}
            {error && <p className="text-sm text-red-600">{error}</p>}
            <button type="submit" disabled={loading} className="mt-2 rounded-xl bg-primary px-4 py-3 text-sm font-[700] text-white disabled:opacity-60 cursor-pointer">
              {loading ? 'Gönderiliyor…' : 'Öneriyi Gönder'}
            </button>
          </form>
        )}
      </div>
    </main>
  );
}
