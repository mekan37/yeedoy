'use client';

import { useState } from 'react';
import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';
import { toast } from '@/src/lib/toast-deposu';

type Phase = 'idle' | 'loading' | 'enroll' | 'verify' | 'done' | 'unenrolling';

export function IkiFactorAyar({ isEnabled, factorId: initialFactorId }: { isEnabled: boolean; factorId?: string | null }) {
  const [phase, setPhase] = useState<Phase>('idle');
  const [qrCode, setQrCode] = useState<string | null>(null);
  const [secret, setSecret] = useState<string | null>(null);
  const [factorId, setFactorId] = useState<string | null>(initialFactorId ?? null);
  const [code, setCode] = useState('');
  const [error, setError] = useState<string | null>(null);

  async function startEnroll() {
    setPhase('loading');
    setError(null);
    try {
      const supabase = createSupabaseBrowserClient();
      const { data, error: err } = await supabase.auth.mfa.enroll({ factorType: 'totp', issuer: 'Yeedoy', friendlyName: 'Yeedoy 2FA' });
      if (err) throw err;
      setQrCode(data.totp.qr_code);
      setSecret(data.totp.secret);
      setFactorId(data.id);
      setPhase('enroll');
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Hata oluştu');
      setPhase('idle');
    }
  }

  async function verifyCode() {
    if (!factorId || code.length < 6) return;
    setPhase('loading');
    setError(null);
    try {
      const supabase = createSupabaseBrowserClient();
      const { data: challenge } = await supabase.auth.mfa.challenge({ factorId });
      if (!challenge) throw new Error('Challenge alınamadı');
      const { error: verifyErr } = await supabase.auth.mfa.verify({ factorId, challengeId: challenge.id, code });
      if (verifyErr) throw verifyErr;
      toast('İki faktörlü doğrulama aktif edildi', 'success');
      setPhase('done');
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Kod hatalı');
      setPhase('enroll');
    }
  }

  async function unenroll() {
    if (!factorId) return;
    setPhase('unenrolling');
    try {
      const supabase = createSupabaseBrowserClient();
      const { error: err } = await supabase.auth.mfa.unenroll({ factorId });
      if (err) throw err;
      toast('İki faktörlü doğrulama kaldırıldı', 'info');
      setPhase('idle');
      setFactorId(null);
      setQrCode(null);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Kaldırma başarısız');
      setPhase('idle');
    }
  }

  if (phase === 'done' || (isEnabled && phase === 'idle' && initialFactorId)) {
    return (
      <div className="flex flex-col gap-3">
        <div className="flex items-center gap-2 rounded-xl border border-success/25 bg-success/[0.08] px-4 py-3">
          <span className="text-success">✓</span>
          <p className="text-sm font-[700] text-success">İki faktörlü doğrulama aktif</p>
        </div>
        <button
          type="button"
          onClick={unenroll}
          disabled={(phase as string) === 'unenrolling'}
          className="inline-flex min-h-10 items-center rounded-xl border border-danger/30 bg-danger/[0.08] px-4 text-sm font-[800] text-danger hover:bg-danger/[0.14] disabled:opacity-50"
        >
          {(phase as string) === 'unenrolling' ? 'Kaldırılıyor…' : '2FA\'yı Kapat'}
        </button>
      </div>
    );
  }

  if (phase === 'enroll' || phase === 'loading') {
    return (
      <div className="flex flex-col gap-4">
        <p className="text-sm text-muted">
          Google Authenticator veya Authy ile QR kodu tarayın, ardından 6 haneli kodu girin.
        </p>
        {qrCode && (
          <div className="flex justify-center rounded-2xl border border-border bg-white p-4">
            {/* QR code as SVG data URL */}
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img src={qrCode} alt="2FA QR Kodu" className="h-40 w-40" />
          </div>
        )}
        {secret && (
          <p className="rounded-xl border border-border bg-bg px-3 py-2 text-center font-mono text-xs text-muted">
            Manuel kod: {secret}
          </p>
        )}
        <div>
          <label className="mb-1.5 block text-sm font-[900] text-textStrong">Doğrulama Kodu</label>
          <input
            type="text"
            inputMode="numeric"
            value={code}
            onChange={(e) => setCode(e.target.value.replace(/\D/g, '').slice(0, 6))}
            placeholder="123456"
            maxLength={6}
            className="w-full rounded-2xl border border-border bg-bg px-4 py-3 text-center text-lg font-[900] tracking-[0.5em] text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/30"
          />
        </div>
        {error && <p className="text-sm font-[700] text-danger">{error}</p>}
        <div className="flex gap-2">
          <button
            type="button"
            onClick={verifyCode}
            disabled={code.length < 6 || phase === 'loading'}
            className="flex-1 inline-flex min-h-11 items-center justify-center rounded-2xl text-sm font-[900] text-white disabled:opacity-60"
            style={{ background: 'var(--yd-gradient-primary)' }}
          >
            {phase === 'loading' ? 'Doğrulanıyor…' : 'Doğrula ve Aktif Et'}
          </button>
          <button
            type="button"
            onClick={() => setPhase('idle')}
            className="rounded-2xl border border-border px-4 text-sm font-[700] text-muted hover:bg-cardAlt"
          >
            İptal
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-3">
      {error && <p className="text-sm font-[700] text-danger">{error}</p>}
      <button
        type="button"
        onClick={startEnroll}
        className="inline-flex min-h-11 items-center gap-2 rounded-2xl border border-border bg-bg px-4 text-sm font-[800] text-textStrong hover:border-primary/30"
      >
        <svg viewBox="0 0 24 24" className="h-4 w-4 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
          <rect x="3" y="11" width="18" height="11" rx="2" ry="2" />
          <path d="M7 11V7a5 5 0 0 1 10 0v4" />
        </svg>
        2FA Kurulumunu Başlat
      </button>
    </div>
  );
}
