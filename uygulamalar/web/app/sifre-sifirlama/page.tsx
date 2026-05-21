'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';
import { YeedoyLogo } from '@/src/ui/marka/yeedoy-logo';
import { toast } from '@/src/lib/toast-deposu';

const CRITERIA = [
  { label: 'En az 8 karakter', test: (v: string) => v.length >= 8 },
  { label: 'Büyük harf (A-Z)', test: (v: string) => /[A-Z]/.test(v) },
  { label: 'Küçük harf (a-z)', test: (v: string) => /[a-z]/.test(v) },
  { label: 'Rakam (0-9)',      test: (v: string) => /\d/.test(v) },
  { label: 'Özel karakter',   test: (v: string) => /[^A-Za-z0-9]/.test(v) },
];

function strengthOf(password: string) {
  return CRITERIA.filter((c) => c.test(password)).length;
}

const STRENGTH_LABEL = ['', 'Çok Zayıf', 'Zayıf', 'Orta', 'İyi', 'Güçlü'];
const STRENGTH_COLOR = ['', 'bg-danger', 'bg-warning', 'bg-warning', 'bg-info', 'bg-success'];
const STRENGTH_TEXT  = ['', 'text-danger', 'text-warning', 'text-warning', 'text-info', 'text-success'];

export default function ResetPasswordPage() {
  const router = useRouter();
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [showPass, setShowPass] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [done, setDone] = useState(false);
  const [ready, setReady] = useState(false);

  const strength = strengthOf(password);

  useEffect(() => {
    const supabase = createSupabaseBrowserClient();
    const { data: { subscription } } = supabase.auth.onAuthStateChange((event) => {
      if (event === 'PASSWORD_RECOVERY') setReady(true);
    });
    return () => subscription.unsubscribe();
  }, []);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (password !== confirm) { setError('Şifreler eşleşmiyor'); return; }
    if (strength < 3) { setError('Daha güçlü bir şifre seçin'); return; }
    setLoading(true);
    setError(null);
    try {
      const supabase = createSupabaseBrowserClient();
      const { error: err } = await supabase.auth.updateUser({ password });
      if (err) throw err;
      setDone(true);
      toast('Şifreniz güncellendi', 'success');
      setTimeout(() => router.push('/giris'), 2500);
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
          <h1 className="text-2xl font-[900] text-textStrong">Yeni Şifre Belirle</h1>
        </div>

        <div className="rounded-[24px] border border-border bg-card p-8 shadow-yd2">
          {done ? (
            <div className="rounded-2xl border border-success/25 bg-success/[0.10] p-5 text-center">
              <p className="text-sm font-[800] text-success">Şifreniz güncellendi</p>
              <p className="mt-1 text-xs text-muted">Giriş sayfasına yönlendiriliyorsunuz…</p>
            </div>
          ) : !ready ? (
            <div className="rounded-2xl border border-warning/25 bg-warning/[0.10] p-5 text-center">
              <p className="text-sm font-[800] text-warning">Bağlantı bekleniyor</p>
              <p className="mt-1 text-xs text-muted">
                Lütfen e-postanızdaki sıfırlama bağlantısına tıklayın.
              </p>
            </div>
          ) : (
            <form onSubmit={handleSubmit} className="flex flex-col gap-4">
              {/* Yeni şifre */}
              <div>
                <label htmlFor="password" className="mb-1.5 block text-sm font-[900] text-textStrong">
                  Yeni Şifre
                </label>
                <div className="relative">
                  <input
                    id="password"
                    type={showPass ? 'text' : 'password'}
                    required
                    autoFocus
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="En az 8 karakter"
                    className="w-full rounded-2xl border border-border bg-bg py-3 pl-4 pr-11 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30"
                  />
                  <button
                    type="button"
                    aria-label={showPass ? 'Şifreyi gizle' : 'Şifreyi göster'}
                    onClick={() => setShowPass((v) => !v)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-muted hover:text-textStrong"
                  >
                    {showPass ? (
                      <svg viewBox="0 0 24 24" className="h-4 w-4 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
                    ) : (
                      <svg viewBox="0 0 24 24" className="h-4 w-4 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                    )}
                  </button>
                </div>

                {/* Güç çubuğu */}
                {password.length > 0 && (
                  <div className="mt-2">
                    <div className="flex gap-1">
                      {CRITERIA.map((_, i) => (
                        <div
                          key={i}
                          className={`h-1 flex-1 rounded-full transition-all ${i < strength ? STRENGTH_COLOR[strength] : 'bg-border'}`}
                        />
                      ))}
                    </div>
                    <p className={`mt-1 text-xs font-[700] ${STRENGTH_TEXT[strength]}`}>
                      {STRENGTH_LABEL[strength]}
                    </p>
                  </div>
                )}
              </div>

              {/* Şifre tekrar */}
              <div>
                <label htmlFor="confirm" className="mb-1.5 block text-sm font-[900] text-textStrong">
                  Şifre Tekrar
                </label>
                <input
                  id="confirm"
                  type={showPass ? 'text' : 'password'}
                  required
                  value={confirm}
                  onChange={(e) => setConfirm(e.target.value)}
                  placeholder="Şifrenizi tekrar girin"
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
                disabled={loading || strength < 3}
                className="mt-1 inline-flex min-h-[52px] w-full items-center justify-center rounded-2xl text-sm font-[900] text-white disabled:opacity-60"
                style={{ background: 'var(--yd-gradient-primary)' }}
              >
                {loading ? 'Güncelleniyor…' : 'Şifreyi Güncelle'}
              </button>
            </form>
          )}
        </div>
      </div>
    </main>
  );
}
