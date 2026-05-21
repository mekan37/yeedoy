'use client';

import { useState } from 'react';
import Link from 'next/link';
import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';
import { YeedoyLogo } from '@/src/ui/marka/yeedoy-logo';
import { toast } from '@/src/lib/toast-deposu';

export default function ForgotPasswordPage() {
  const [email, setEmail] = useState('');
  const [sent, setSent] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);
    try {
      const supabase = createSupabaseBrowserClient();
      const { error: err } = await supabase.auth.resetPasswordForEmail(email, {
        redirectTo: `${window.location.origin}/sifre-sifirlama`,
      });
      if (err) throw err;
      setSent(true);
      toast('Sıfırlama bağlantısı gönderildi', 'success');
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Bir hata oluştu';
      setError(msg);
      toast(msg, 'danger');
    } finally {
      setLoading(false);
    }
  }

  return (
    <main className="flex min-h-screen items-center justify-center bg-bg px-4 py-12">
      <div className="w-full max-w-md">
        <div className="mb-8 flex flex-col items-center gap-3">
          <YeedoyLogo size={40} />
          <h1 className="text-2xl font-[900] text-textStrong">Şifremi Unuttum</h1>
          <p className="text-center text-sm text-muted">
            E-posta adresinize şifre sıfırlama bağlantısı göndereceğiz.
          </p>
        </div>

        <div className="rounded-[24px] border border-border bg-card p-8 shadow-yd2">
          {sent ? (
            <div className="rounded-2xl border border-success/25 bg-success/[0.10] p-5 text-center">
              <p className="text-sm font-[800] text-success">E-posta gönderildi</p>
              <p className="mt-1 text-xs text-muted">Gelen kutunuzu kontrol edin.</p>
            </div>
          ) : (
            <form onSubmit={handleSubmit} className="flex flex-col gap-4">
              <div>
                <label htmlFor="email" className="mb-1.5 block text-sm font-[900] text-textStrong">
                  E-posta
                </label>
                <input
                  id="email"
                  type="email"
                  required
                  autoFocus
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="ornek@email.com"
                  className="w-full rounded-2xl border border-border bg-bg px-4 py-3 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30"
                />
              </div>

              {error && (
                <div className="rounded-2xl border border-danger/25 bg-danger/[0.08] px-4 py-3 text-sm font-[700] text-danger">
                  {error}
                </div>
              )}

              <button
                type="submit"
                disabled={loading}
                className="mt-1 inline-flex min-h-[52px] w-full items-center justify-center rounded-2xl text-sm font-[900] text-white disabled:opacity-60"
                style={{ background: 'var(--yd-gradient-primary)' }}
              >
                {loading ? 'Gönderiliyor…' : 'Sıfırlama Bağlantısı Gönder'}
              </button>
            </form>
          )}

          <p className="mt-6 text-center text-sm text-muted">
            <Link href="/giris" className="font-[800] text-primary hover:underline">
              ← Giriş sayfasına dön
            </Link>
          </p>
        </div>
      </div>
    </main>
  );
}
