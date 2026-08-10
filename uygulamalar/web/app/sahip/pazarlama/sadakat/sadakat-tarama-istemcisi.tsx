'use client';

import { useEffect, useRef, useState } from 'react';
import QrScanner from 'qr-scanner';
import { qrOkut, odulKullan, type QrOkutSonucu } from './sadakat-islemleri';

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

type BasariliSonuc = Extract<QrOkutSonucu, { ok: true }>;

export function SadakatTaramaIstemcisi({
  businessId,
  program,
}: {
  businessId: string;
  program: { is_active: boolean };
}) {
  const videoRef = useRef<HTMLVideoElement>(null);
  const busyRef = useRef(false);
  const [error, setError] = useState<string | null>(null);
  const [result, setResult] = useState<BasariliSonuc | null>(null);
  const [busy, setBusy] = useState(false);
  const [redeemDone, setRedeemDone] = useState(false);

  useEffect(() => {
    if (!program.is_active || !videoRef.current) return;

    const scanner = new QrScanner(
      videoRef.current,
      async (scanResult) => {
        const userId = scanResult.data.trim();
        if (!UUID_RE.test(userId) || busyRef.current) return;

        busyRef.current = true;
        setBusy(true);
        setError(null);
        setRedeemDone(false);

        const outcome = await qrOkut(businessId, userId);

        busyRef.current = false;
        setBusy(false);

        if ('error' in outcome) {
          setError(outcome.error);
          return;
        }
        setResult(outcome);
      },
      { returnDetailedScanResult: true, highlightScanRegion: true },
    );

    scanner.start().catch(() => setError('Kamera açılamadı. Tarayıcı izinlerini kontrol edin.'));

    return () => {
      scanner.stop();
      scanner.destroy();
    };
  }, [program.is_active, businessId]);

  if (!program.is_active) {
    return <p className="text-sm text-muted">QR taramak için önce programı aktive edin.</p>;
  }

  return (
    <div className="space-y-3">
      <div className="overflow-hidden rounded-xl border border-border bg-bg">
        <video ref={videoRef} className="h-56 w-full object-cover" muted />
      </div>
      {busy && <p className="text-xs text-muted">İşleniyor…</p>}
      {error && <p className="text-xs font-bold text-red-600">{error}</p>}
      {result && (
        <div className="space-y-2 rounded-xl border border-border bg-card p-3">
          <div className="h-2.5 overflow-hidden rounded-full bg-zinc-100">
            <div
              className="h-2.5 rounded-full bg-primary"
              style={{
                width: `${Math.min(100, Math.round((result.progress / result.reward_threshold) * 100))}%`,
              }}
            />
          </div>
          <p className="text-xs font-bold text-textStrong">
            {result.progress} / {result.reward_threshold}
          </p>
          <button
            type="button"
            disabled={!result.reward_ready || redeemDone}
            onClick={async () => {
              setBusy(true);
              const outcome = await odulKullan(result.member_id);
              setBusy(false);
              if ('error' in outcome) {
                setError(outcome.error);
                return;
              }
              setResult({ ...result, progress: outcome.progress, reward_ready: outcome.progress >= result.reward_threshold });
              setRedeemDone(true);
            }}
            className="w-full rounded-xl bg-primary px-3 py-2 text-sm font-bold text-white disabled:opacity-40"
          >
            {redeemDone ? 'Ödül Kullanıldı' : 'Ödülü Kullan'}
          </button>
        </div>
      )}
    </div>
  );
}
