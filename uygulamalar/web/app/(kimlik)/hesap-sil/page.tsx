'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';

type Phase = 'idle' | 'deleting' | 'done' | 'error';

export default function HesapSilPage() {
  const router = useRouter();
  const [confirmed, setConfirmed] = useState(false);
  const [phase, setPhase] = useState<Phase>('idle');
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  async function handleDelete() {
    if (!confirmed) return;
    setPhase('deleting');
    setErrorMsg(null);

    try {
      const res = await fetch('/sunucu/hesap/sil', { method: 'POST' });
      const json = (await res.json()) as { ok?: boolean; error?: string };

      if (!res.ok || !json.ok) {
        throw new Error(json.error ?? 'Hesap silinemedi');
      }

      setPhase('done');

      const supabase = createSupabaseBrowserClient();
      await supabase.auth.signOut();

      setTimeout(() => router.push('/'), 2000);
    } catch (err: unknown) {
      setErrorMsg(err instanceof Error ? err.message : 'Bir hata oluştu');
      setPhase('error');
    }
  }

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-lg px-4 py-12">
        {/* Geri */}
        <Link
          href="/profil/settings"
          className="mb-8 inline-flex items-center gap-1.5 text-sm text-muted hover:text-primary"
        >
          <svg
            viewBox="0 0 24 24"
            className="h-3.5 w-3.5 fill-none stroke-current"
            strokeWidth="2.5"
            strokeLinecap="round"
            strokeLinejoin="round"
            aria-hidden="true"
          >
            <polyline points="15 18 9 12 15 6" />
          </svg>
          Ayarlara Dön
        </Link>

        {/* Başarılı durum */}
        {phase === 'done' && (
          <div className="rounded-[24px] border border-green-200 bg-green-50 p-8 text-center">
            <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-full border-2 border-green-300 bg-green-100">
              <svg
                viewBox="0 0 24 24"
                className="h-7 w-7 fill-none stroke-current text-green-600"
                strokeWidth="2.5"
                strokeLinecap="round"
                strokeLinejoin="round"
                aria-hidden="true"
              >
                <polyline points="20 6 9 17 4 12" />
              </svg>
            </div>
            <h1 className="text-xl font-[900] text-green-700">Hesabınız silindi</h1>
            <p className="mt-2 text-sm text-green-600">Ana sayfaya yönlendiriliyorsunuz…</p>
          </div>
        )}

        {/* Normal akış */}
        {phase !== 'done' && (
          <>
            <h1 className="mb-2 text-2xl font-[900] text-textStrong">Hesabı Sil</h1>
            <p className="mb-8 text-sm leading-relaxed text-muted">
              Hesabınızı ve tüm verilerinizi kalıcı olarak silmek için aşağıdaki adımları tamamlayın.
            </p>

            {/* Adım 1 — Uyarı */}
            <section className="mb-6 rounded-[24px] border border-danger/25 bg-danger/[0.05] p-6">
              <div className="mb-3 flex items-center gap-3">
                <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-danger/10">
                  <svg
                    viewBox="0 0 24 24"
                    className="h-5 w-5 fill-current text-danger"
                    aria-hidden="true"
                  >
                    <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-2h2v2zm0-4h-2V7h2v6z" />
                  </svg>
                </div>
                <h2 className="text-base font-[900] text-danger">Bu işlem geri alınamaz</h2>
              </div>
              <ul className="space-y-2 text-sm text-textStrong">
                {[
                  'Tüm verileriniz kalıcı olarak silinecek.',
                  'Yorumlarınız, favorileriniz ve katkılarınız kaldırılacak.',
                  'İşletme sahipliği başvurularınız iptal edilecek.',
                  'Tekrar erişim sağlayamazsınız.',
                ].map((item) => (
                  <li key={item} className="flex items-start gap-2">
                    <svg
                      viewBox="0 0 24 24"
                      className="mt-0.5 h-4 w-4 shrink-0 fill-none stroke-current text-danger"
                      strokeWidth="2.5"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      aria-hidden="true"
                    >
                      <line x1="18" y1="6" x2="6" y2="18" />
                      <line x1="6" y1="6" x2="18" y2="18" />
                    </svg>
                    {item}
                  </li>
                ))}
              </ul>
            </section>

            {/* Adım 2 — Onay checkbox */}
            <section className="mb-6 rounded-[24px] border border-border bg-card p-6">
              <h2 className="mb-4 text-sm font-[900] text-textStrong">Onaylayın</h2>
              <label className="flex cursor-pointer items-start gap-3">
                <div className="relative mt-0.5 flex-shrink-0">
                  <input
                    type="checkbox"
                    checked={confirmed}
                    onChange={(e) => setConfirmed(e.target.checked)}
                    className="sr-only"
                    aria-label="Hesap silme onayı"
                  />
                  <div
                    className={`flex h-5 w-5 items-center justify-center rounded border-2 transition-colors ${
                      confirmed
                        ? 'border-danger bg-danger'
                        : 'border-border bg-bg hover:border-danger/50'
                    }`}
                    aria-hidden="true"
                  >
                    {confirmed && (
                      <svg
                        viewBox="0 0 24 24"
                        className="h-3 w-3 fill-none stroke-white"
                        strokeWidth="3.5"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                      >
                        <polyline points="20 6 9 17 4 12" />
                      </svg>
                    )}
                  </div>
                </div>
                <span className="text-sm leading-relaxed text-textStrong">
                  Hesabımın ve tüm verilerimin{' '}
                  <strong className="font-[900]">kalıcı olarak silineceğini</strong> anlıyorum.
                </span>
              </label>
            </section>

            {/* Hata mesajı */}
            {phase === 'error' && errorMsg && (
              <div className="mb-5 rounded-2xl border border-danger/25 bg-danger/[0.08] px-5 py-3.5 text-sm font-[700] text-danger">
                {errorMsg}
              </div>
            )}

            {/* Adım 3 — Silme butonu */}
            <button
              type="button"
              onClick={handleDelete}
              disabled={!confirmed || phase === 'deleting'}
              className="flex w-full min-h-[52px] items-center justify-center rounded-2xl bg-danger text-sm font-[900] text-white transition-all hover:brightness-95 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-danger/40 disabled:cursor-not-allowed disabled:opacity-40"
            >
              {phase === 'deleting' ? (
                <span className="flex items-center gap-2">
                  <span className="h-4 w-4 animate-spin rounded-full border-2 border-white/30 border-t-white" />
                  Siliniyor…
                </span>
              ) : (
                'SİLİNECEK'
              )}
            </button>

            <p className="mt-4 text-center text-xs text-muted">
              Vazgeçmek isterseniz{' '}
              <Link href="/profil/settings" className="font-[700] text-primary hover:underline">
                Ayarlara Dön
              </Link>
            </p>
          </>
        )}
      </div>
    </main>
  );
}
