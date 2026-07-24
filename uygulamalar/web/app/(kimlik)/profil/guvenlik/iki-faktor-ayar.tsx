'use client';

import { useState } from 'react';
import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';
import { toast } from '@/src/lib/toast-deposu';

// 'disable-confirm' → kullanıcı TOTP kodunu giriyor (factor silinmedi)
// 'disable-verifying' → challenge+verify+unenroll devam ediyor
type Phase = 'idle' | 'loading' | 'enroll' | 'verify' | 'done' | 'disable-confirm' | 'disable-verifying';

export function IkiFactorAyar({ isEnabled, factorId: initialFactorId }: { isEnabled: boolean; factorId?: string | null }) {
  const [phase, setPhase] = useState<Phase>('idle');
  const [qrCode, setQrCode] = useState<string | null>(null);
  const [secret, setSecret] = useState<string | null>(null);
  const [factorId, setFactorId] = useState<string | null>(initialFactorId ?? null);
  const [code, setCode] = useState('');
  const [error, setError] = useState<string | null>(null);

  // Kodu sıfırlayan yardımcı — her akış geçişinde ortak temizlik
  function resetDisableFlow() {
    setPhase('idle');
    setCode('');
    setError(null);
  }

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
    } catch {
      setError('Kurulum başlatılamadı, lütfen tekrar deneyin.');
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
      if (!challenge) throw new Error('challenge_failed');
      const { error: verifyErr } = await supabase.auth.mfa.verify({ factorId, challengeId: challenge.id, code });
      if (verifyErr) throw new Error('verify_failed');
      toast('İki faktörlü doğrulama aktif edildi', 'success');
      setPhase('done');
    } catch {
      setError('Kod hatalı veya süresi dolmuş. Lütfen tekrar deneyin.');
      setPhase('enroll');
    }
  }

  /**
   * GÜVENLİ UNENROLL AKIŞI
   *
   * 1. listFactors() → factor'ın bu kullanıcıya ait olduğunu doğrula
   * 2. challenge() → TOTP challenge oluştur
   * 3. verify(code) → kullanıcının girdiği kod doğru mu?
   * 4. Sadece verify başarılıysa → unenroll(factorId)
   *
   * Herhangi bir adımda başarısız olursa unenroll ÇAĞRILMAZ.
   * Ham Supabase hata mesajları UI'a yansıtılmaz.
   */
  async function verifyAndUnenroll() {
    if (!factorId || code.length < 6) return;

    setPhase('disable-verifying');
    setError(null);

    try {
      const supabase = createSupabaseBrowserClient();

      // 1. Oturum kontrolü
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        setError('Oturum bulunamadı. Lütfen tekrar giriş yapın.');
        setPhase('disable-confirm');
        return;
      }

      // 2. Factor ownership doğrulama — client'tan gelen factorId'nin
      //    gerçekten bu kullanıcıya ait olduğunu güvence altına alır.
      const { data: factorsData } = await supabase.auth.mfa.listFactors();
      const ownedFactor = factorsData?.totp?.find((f) => f.id === factorId);
      if (!ownedFactor) {
        setError('Geçersiz işlem.');
        setPhase('disable-confirm');
        return;
      }

      // 3. Challenge oluştur
      const { data: challenge, error: challengeErr } = await supabase.auth.mfa.challenge({ factorId });
      if (challengeErr || !challenge) {
        setError('Bir sorun oluştu, lütfen tekrar deneyin.');
        setPhase('disable-confirm');
        return;
      }

      // 4. Kodu doğrula
      const { error: verifyErr } = await supabase.auth.mfa.verify({
        factorId,
        challengeId: challenge.id,
        code,
      });
      if (verifyErr) {
        // Ham verifyErr.message UI'a yansıtılmaz
        setError('Kod hatalı veya süresi dolmuş.');
        setPhase('disable-confirm');
        return;
      }

      // 5. Sadece verify başarılıysa unenroll çağrılır
      const { error: unenrollErr } = await supabase.auth.mfa.unenroll({ factorId });
      if (unenrollErr) {
        // Ham unenrollErr.message UI'a yansıtılmaz
        setError('Bir sorun oluştu, lütfen tekrar deneyin.');
        setPhase('disable-confirm');
        return;
      }

      toast('İki faktörlü doğrulama kaldırıldı', 'info');
      setFactorId(null);
      setQrCode(null);
      resetDisableFlow();
    } catch {
      setError('Bir sorun oluştu, lütfen tekrar deneyin.');
      setPhase('disable-confirm');
    }
  }

  // ─── Aktif 2FA görünümü ───────────────────────────────────────────────────
  if (phase === 'done' || (isEnabled && (phase === 'idle' || phase === 'disable-confirm' || phase === 'disable-verifying') && initialFactorId)) {
    // "Devre dışı bırak" doğrulama adımı
    if (phase === 'disable-confirm' || phase === 'disable-verifying') {
      return (
        <div className="flex flex-col gap-4">
          <div className="flex items-center gap-2 rounded-xl border border-success/25 bg-success/8 px-4 py-3">
            <span className="text-success">✓</span>
            <p className="text-sm font-bold text-success">İki faktörlü doğrulama aktif</p>
          </div>
          <div className="rounded-xl border border-danger/20 bg-danger/4 p-4">
            <p className="mb-3 text-sm font-bold text-textStrong">
              2FA&apos;yı devre dışı bırakmak için kimlik doğrulayıcı uygulamanızdaki 6 haneli kodu girin.
            </p>
            <div className="mb-3">
              <label htmlFor="disable-totp-code" className="mb-1.5 block text-sm font-black text-textStrong">
                Doğrulama Kodu
              </label>
              <input
                id="disable-totp-code"
                type="text"
                inputMode="numeric"
                value={code}
                onChange={(e) => setCode(e.target.value.replace(/\D/g, '').slice(0, 6))}
                placeholder="123456"
                maxLength={6}
                disabled={phase === 'disable-verifying'}
                className="w-full rounded-2xl border border-border bg-bg px-4 py-3 text-center text-lg font-black tracking-[0.5em] text-textStrong focus:outline-hidden focus:ring-2 focus:ring-danger/30 disabled:opacity-60"
              />
            </div>
            {error && <p className="mb-3 text-sm font-bold text-danger">{error}</p>}
            <div className="flex gap-2">
              <button
                type="button"
                onClick={verifyAndUnenroll}
                disabled={code.length < 6 || phase === 'disable-verifying'}
                className="flex-1 inline-flex min-h-10 items-center justify-center rounded-xl border border-danger/30 bg-danger/8 text-sm font-extrabold text-danger hover:bg-danger/[0.14] disabled:opacity-50"
              >
                {phase === 'disable-verifying' ? 'Doğrulanıyor…' : 'Doğrula ve Devre Dışı Bırak'}
              </button>
              <button
                type="button"
                onClick={resetDisableFlow}
                disabled={phase === 'disable-verifying'}
                className="rounded-xl border border-border px-4 text-sm font-bold text-muted hover:bg-cardAlt disabled:opacity-50"
              >
                İptal
              </button>
            </div>
          </div>
        </div>
      );
    }

    // Varsayılan: 2FA aktif, "2FA'yı Kapat" butonu
    return (
      <div className="flex flex-col gap-3">
        <div className="flex items-center gap-2 rounded-xl border border-success/25 bg-success/8 px-4 py-3">
          <span className="text-success">✓</span>
          <p className="text-sm font-bold text-success">İki faktörlü doğrulama aktif</p>
        </div>
        <button
          type="button"
          onClick={() => { setError(null); setCode(''); setPhase('disable-confirm'); }}
          className="inline-flex min-h-10 items-center rounded-xl border border-danger/30 bg-danger/8 px-4 text-sm font-extrabold text-danger hover:bg-danger/[0.14]"
        >
          2FA&apos;yı Kapat
        </button>
      </div>
    );
  }

  // ─── Enroll akışı ─────────────────────────────────────────────────────────
  if (phase === 'enroll' || phase === 'loading') {
    return (
      <div className="flex flex-col gap-4">
        <p className="text-sm text-muted">
          Google Authenticator veya Authy ile QR kodu tarayın, ardından 6 haneli kodu girin.
        </p>
        {qrCode && (
          <div className="flex justify-center rounded-2xl border border-border bg-white p-4">
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
          <label className="mb-1.5 block text-sm font-black text-textStrong">Doğrulama Kodu</label>
          <input
            type="text"
            inputMode="numeric"
            value={code}
            onChange={(e) => setCode(e.target.value.replace(/\D/g, '').slice(0, 6))}
            placeholder="123456"
            maxLength={6}
            className="w-full rounded-2xl border border-border bg-bg px-4 py-3 text-center text-lg font-black tracking-[0.5em] text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30"
          />
        </div>
        {error && <p className="text-sm font-bold text-danger">{error}</p>}
        <div className="flex gap-2">
          <button
            type="button"
            onClick={verifyCode}
            disabled={code.length < 6 || phase === 'loading'}
            className="flex-1 inline-flex min-h-11 items-center justify-center rounded-2xl text-sm font-black text-white disabled:opacity-60"
            style={{ background: 'var(--yd-gradient-primary)' }}
          >
            {phase === 'loading' ? 'Doğrulanıyor…' : 'Doğrula ve Aktif Et'}
          </button>
          <button
            type="button"
            onClick={() => setPhase('idle')}
            className="rounded-2xl border border-border px-4 text-sm font-bold text-muted hover:bg-cardAlt"
          >
            İptal
          </button>
        </div>
      </div>
    );
  }

  // ─── Varsayılan: 2FA pasif, kurulum başlatma ──────────────────────────────
  return (
    <div className="flex flex-col gap-3">
      {error && <p className="text-sm font-bold text-danger">{error}</p>}
      <button
        type="button"
        onClick={startEnroll}
        className="inline-flex min-h-11 items-center gap-2 rounded-2xl border border-border bg-bg px-4 text-sm font-extrabold text-textStrong hover:border-primary/30"
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
