'use client';

import { useState, useTransition } from 'react';
import { inviteUser } from './davet-islemleri';

export function DavetEtModal() {
  const [open, setOpen] = useState(false);
  const [email, setEmail] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);
  const [pending, startTransition] = useTransition();

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    startTransition(async () => {
      const result = await inviteUser(email);
      if ('error' in result) { setError(result.error); return; }
      setSuccess(true);
      setEmail('');
    });
  }

  return (
    <>
      <button
        type="button"
        onClick={() => { setOpen(true); setSuccess(false); setError(null); }}
        className="flex items-center justify-between rounded-xl px-3 py-2.5 text-xs font-extrabold text-white transition-opacity hover:opacity-90"
        style={{ background: 'linear-gradient(135deg, #dc2626, #991b1b)' }}
      >
        <span>Kullanıcı Davet Et<span className="block text-[10px] font-bold text-white/70">Yeni kullanıcıları platforma davet edin</span></span>
        <ArrowIcon />
      </button>

      {open && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="absolute inset-0 bg-black/30" onClick={() => setOpen(false)} />
          <div className="relative z-10 w-full max-w-sm rounded-2xl bg-card p-5 shadow-2xl">
            <h2 className="mb-1 text-sm font-black text-textStrong">Kullanıcı Davet Et</h2>
            <p className="mb-4 text-xs text-muted">E-posta adresine kayıt daveti gönderilir.</p>

            {success ? (
              <div className="flex flex-col gap-3">
                <p className="rounded-xl bg-success/10 px-3 py-2.5 text-sm font-bold text-success">Davet gönderildi.</p>
                <button type="button" onClick={() => setOpen(false)} className="rounded-xl border border-border px-3 py-2 text-xs font-bold text-textStrong hover:bg-black/4">Kapat</button>
              </div>
            ) : (
              <form onSubmit={handleSubmit} className="flex flex-col gap-3">
                <input
                  type="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="ornek@eposta.com"
                  className="w-full rounded-xl border border-border bg-bg px-3 py-2.5 text-sm text-textStrong outline-hidden focus:border-primary focus:ring-2 focus:ring-primary/20"
                />
                {error && <p className="rounded-xl bg-danger/10 px-3 py-2 text-xs font-bold text-danger">{error}</p>}
                <div className="flex gap-2">
                  <button type="submit" disabled={pending} className="flex-1 rounded-xl bg-primary px-3 py-2 text-xs font-bold text-white disabled:opacity-50">
                    {pending ? 'Gönderiliyor…' : 'Davet Gönder'}
                  </button>
                  <button type="button" onClick={() => setOpen(false)} className="rounded-xl border border-border px-3 py-2 text-xs font-bold text-textStrong hover:bg-black/4">İptal</button>
                </div>
              </form>
            )}
          </div>
        </div>
      )}
    </>
  );
}

function ArrowIcon() {
  return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="5" y1="12" x2="19" y2="12" /><polyline points="12 5 19 12 12 19" /></svg>;
}
