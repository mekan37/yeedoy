'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { createClient } from '@supabase/supabase-js';

export default function ResetPasswordPage() {
  const router = useRouter();
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [done, setDone] = useState(false);

  useEffect(() => {
    // Supabase hash fragment'ten session'ı al
    const supabase = createClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    );
    supabase.auth.onAuthStateChange((event) => {
      if (event === 'PASSWORD_RECOVERY') {
        // session hazır, form göster
      }
    });
  }, []);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (password !== confirm) { setError('Şifreler eşleşmiyor'); return; }
    if (password.length < 8) { setError('Şifre en az 8 karakter olmalı'); return; }
    setLoading(true);
    setError(null);
    try {
      const supabase = createClient(
        process.env.NEXT_PUBLIC_SUPABASE_URL!,
        process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
      );
      const { error: err } = await supabase.auth.updateUser({ password });
      if (err) throw err;
      setDone(true);
      setTimeout(() => router.push('/login'), 2000);
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Bir hata oluştu');
    } finally {
      setLoading(false);
    }
  }

  return (
    <main className="flex min-h-screen items-center justify-center bg-bg px-4">
      <div className="w-full max-w-md rounded-2xl border border-border bg-card p-8">
        <h1 className="mb-6 text-2xl font-[900] text-textStrong">Şifre Sıfırlama</h1>
        {done ? (
          <p className="text-sm text-green-700 rounded-xl bg-green-50 p-4">Şifreniz güncellendi. Giriş sayfasına yönlendiriliyorsunuz…</p>
        ) : (
          <form onSubmit={handleSubmit} className="flex flex-col gap-4">
            <input type="password" required minLength={8} value={password} onChange={e => setPassword(e.target.value)} placeholder="Yeni şifre (min 8 karakter)"
              className="rounded-xl border border-border bg-bg px-4 py-3 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30" />
            <input type="password" required value={confirm} onChange={e => setConfirm(e.target.value)} placeholder="Şifreyi tekrar girin"
              className="rounded-xl border border-border bg-bg px-4 py-3 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30" />
            {error && <p className="text-sm text-red-600">{error}</p>}
            <button type="submit" disabled={loading} className="rounded-xl bg-primary py-3 text-sm font-[700] text-white disabled:opacity-60 cursor-pointer">
              {loading ? 'Güncelleniyor…' : 'Şifreyi Güncelle'}
            </button>
          </form>
        )}
      </div>
    </main>
  );
}
