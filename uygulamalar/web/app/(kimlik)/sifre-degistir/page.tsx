'use client';

import { useState } from 'react';
import Link from 'next/link';
import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';
import { toast } from '@/src/lib/toast-deposu';

const MIN_LENGTH = 8;

export default function SifreDegistirPage() {
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  const passwordsMatch = newPassword === confirmPassword;
  const newPasswordValid = newPassword.length >= MIN_LENGTH;
  const canSubmit = newPasswordValid && passwordsMatch && !saving;

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);

    if (!newPasswordValid) {
      setError(`Şifre en az ${MIN_LENGTH} karakter olmalıdır.`);
      return;
    }
    if (!passwordsMatch) {
      setError('Şifreler eşleşmiyor.');
      return;
    }

    setSaving(true);
    try {
      const supabase = createSupabaseBrowserClient();
      const { error: updateError } = await supabase.auth.updateUser({
        password: newPassword,
      });
      if (updateError) throw updateError;
      setSuccess(true);
      setNewPassword('');
      setConfirmPassword('');
      toast('Şifreniz başarıyla güncellendi', 'success');
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Şifre güncellenemedi';
      setError(msg);
      toast(msg, 'danger');
    } finally {
      setSaving(false);
    }
  }

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto flex max-w-xl flex-col gap-6 px-4 py-8">
        <div>
          <Link
            href="/profil"
            className="mb-4 inline-flex items-center gap-1.5 text-sm text-muted hover:text-primary"
          >
            ← Profilime Dön
          </Link>
          <h1 className="text-xl font-black text-textStrong">Şifre Değiştir</h1>
          <p className="mt-1 text-sm text-muted">Hesabınız için yeni bir şifre belirleyin.</p>
        </div>

        {success ? (
          <div className="rounded-2xl border border-success/25 bg-success/8 px-5 py-8 text-center">
            <svg
              viewBox="0 0 24 24"
              className="mx-auto mb-3 h-10 w-10 fill-none stroke-current text-success"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
              aria-hidden="true"
            >
              <circle cx="12" cy="12" r="10" />
              <polyline points="20 6 9 17 4 12" />
            </svg>
            <p className="font-black text-success">Şifreniz başarıyla güncellendi</p>
            <p className="mt-1 text-sm text-muted">Artık yeni şifrenizle giriş yapabilirsiniz.</p>
            <button
              type="button"
              onClick={() => setSuccess(false)}
              className="mt-5 text-sm font-extrabold text-primary underline-offset-2 hover:underline"
            >
              Tekrar değiştir
            </button>
          </div>
        ) : (
          <form onSubmit={handleSubmit} className="flex flex-col gap-4">
            <div className="flex flex-col gap-4 rounded-2xl border border-border bg-card p-5">
              {/* Info note */}
              <div className="rounded-xl border border-border bg-bg px-4 py-3">
                <p className="text-xs font-bold text-muted">
                  Mevcut şifrenizi girmeniz gerekmez; Supabase oturumunuzu doğrulayarak şifreyi
                  güvenle günceller.
                </p>
              </div>

              {/* New password */}
              <div>
                <label
                  htmlFor="new-password"
                  className="mb-1.5 block text-sm font-black text-textStrong"
                >
                  Yeni Şifre
                </label>
                <input
                  id="new-password"
                  type="password"
                  value={newPassword}
                  onChange={(e) => setNewPassword(e.target.value)}
                  placeholder={`En az ${MIN_LENGTH} karakter`}
                  autoComplete="new-password"
                  className="w-full rounded-2xl border border-border bg-bg px-4 py-3 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30"
                />
                {newPassword.length > 0 && !newPasswordValid && (
                  <p className="mt-1 text-xs text-warningText">
                    En az {MIN_LENGTH} karakter gerekli ({newPassword.length}/{MIN_LENGTH})
                  </p>
                )}
              </div>

              {/* Confirm password */}
              <div>
                <label
                  htmlFor="confirm-password"
                  className="mb-1.5 block text-sm font-black text-textStrong"
                >
                  Yeni Şifre Tekrar
                </label>
                <input
                  id="confirm-password"
                  type="password"
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  placeholder="Şifrenizi tekrar girin"
                  autoComplete="new-password"
                  className="w-full rounded-2xl border border-border bg-bg px-4 py-3 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30"
                />
                {confirmPassword.length > 0 && !passwordsMatch && (
                  <p className="mt-1 text-xs text-danger">Şifreler eşleşmiyor</p>
                )}
              </div>

              {error && (
                <div className="rounded-2xl border border-danger/25 bg-danger/8 px-4 py-3 text-sm font-bold text-danger">
                  {error}
                </div>
              )}
            </div>

            <button
              type="submit"
              disabled={!canSubmit}
              className="inline-flex min-h-[52px] items-center justify-center rounded-2xl text-sm font-black text-white disabled:opacity-60"
              style={{ background: 'var(--yd-gradient-primary)' }}
            >
              {saving ? 'Güncelleniyor…' : 'Şifreyi Güncelle'}
            </button>
          </form>
        )}

        <div className="rounded-2xl border border-border bg-card px-5 py-4">
          <p className="text-xs leading-relaxed text-muted">
            Şifrenizi unuttuysanız{' '}
            <Link
              href="/sifremi-unuttum"
              className="font-bold text-primary underline-offset-2 hover:underline"
            >
              şifre sıfırlama
            </Link>{' '}
            sayfasını kullanabilirsiniz.
          </p>
        </div>
      </div>
    </main>
  );
}
