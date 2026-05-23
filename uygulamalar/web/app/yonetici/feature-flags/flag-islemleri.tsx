'use client';

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';

async function toggleFlag(flagId: string, enabled: boolean): Promise<{ ok: boolean }> {
  const res = await fetch('/sunucu/yonetici/feature-flags', {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ id: flagId, enabled }),
  });
  return res.json();
}

async function createFlag(data: {
  key: string;
  description: string;
  rollout_percent: number;
  environment: string;
}): Promise<{ ok: boolean; error?: string }> {
  const res = await fetch('/sunucu/yonetici/feature-flags', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });
  return res.json();
}

export function FlagToggle({
  flagId,
  enabled,
  rolloutPct,
}: {
  flagId: string;
  enabled: boolean;
  rolloutPct: number;
}) {
  const router = useRouter();
  const [pending, startTransition] = useTransition();
  const [localEnabled, setLocalEnabled] = useState(enabled);

  function handleToggle() {
    const next = !localEnabled;
    setLocalEnabled(next);
    startTransition(async () => {
      const result = await toggleFlag(flagId, next);
      if (!result.ok) setLocalEnabled(localEnabled);
      router.refresh();
    });
  }

  return (
    <div className="flex items-center gap-3 shrink-0">
      <span className="text-xs text-muted">{rolloutPct}%</span>
      <button
        type="button"
        onClick={handleToggle}
        disabled={pending}
        aria-label={localEnabled ? 'Pasife al' : 'Aktife al'}
        className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors focus:outline-none disabled:opacity-60 ${
          localEnabled ? 'bg-success' : 'bg-border'
        }`}
      >
        <span
          className={`inline-block h-4 w-4 translate-x-1 rounded-full bg-white shadow transition-transform ${
            localEnabled ? 'translate-x-6' : ''
          }`}
        />
      </button>
    </div>
  );
}

export function YeniFlagForm() {
  const router = useRouter();
  const [pending, setPending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  const [key, setKey] = useState('');
  const [description, setDescription] = useState('');
  const [rollout, setRollout] = useState(100);
  const [env, setEnv] = useState('staging');

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!key.trim()) return;
    setPending(true);
    setError(null);
    try {
      const result = await createFlag({
        key: key.trim().toLowerCase().replace(/[^a-z0-9_]/g, '_'),
        description: description.trim(),
        rollout_percent: rollout,
        environment: env,
      });
      if (result.ok) {
        setSuccess(true);
        setKey('');
        setDescription('');
        setRollout(100);
        router.refresh();
        setTimeout(() => setSuccess(false), 3000);
      } else {
        setError(result.error ?? 'Hata oluştu');
      }
    } catch {
      setError('Bağlantı hatası');
    } finally {
      setPending(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} className="flex flex-col gap-4">
      <div className="grid gap-4 sm:grid-cols-2">
        <div className="flex flex-col gap-1.5">
          <label className="text-sm font-[700] text-textStrong">Flag Anahtarı</label>
          <input
            type="text"
            value={key}
            onChange={e => setKey(e.target.value)}
            placeholder="yeni_ozellik_aktif"
            pattern="[a-zA-Z0-9_]+"
            required
            className="input-yd rounded-xl px-3 py-2.5 text-sm"
          />
          <p className="text-[11px] text-muted">Sadece harf, rakam ve alt çizgi</p>
        </div>
        <div className="flex flex-col gap-1.5">
          <label className="text-sm font-[700] text-textStrong">Açıklama</label>
          <input
            type="text"
            value={description}
            onChange={e => setDescription(e.target.value)}
            placeholder="Bu flag ne yapar?"
            maxLength={200}
            className="input-yd rounded-xl px-3 py-2.5 text-sm"
          />
        </div>
        <div className="flex flex-col gap-1.5">
          <label className="text-sm font-[700] text-textStrong">Ortam</label>
          <select value={env} onChange={e => setEnv(e.target.value)} className="input-yd rounded-xl px-3 py-2.5 text-sm">
            <option value="staging">Staging</option>
            <option value="production">Production</option>
            <option value="all">Tüm Ortamlar</option>
          </select>
        </div>
        <div className="flex flex-col gap-1.5">
          <label className="text-sm font-[700] text-textStrong">Yayılım Oranı: %{rollout}</label>
          <input
            type="range"
            min={0}
            max={100}
            step={5}
            value={rollout}
            onChange={e => setRollout(Number(e.target.value))}
            className="w-full"
          />
        </div>
      </div>
      {error && <p className="text-sm font-[700] text-danger">{error}</p>}
      {success && <p className="text-sm font-[700] text-success">✓ Flag oluşturuldu</p>}
      <div className="flex justify-end">
        <button
          type="submit"
          disabled={pending}
          className="btn-primary rounded-xl px-4 py-2.5 text-sm font-[700] text-white disabled:opacity-50"
        >
          {pending ? 'Oluşturuluyor…' : 'Flag Oluştur'}
        </button>
      </div>
    </form>
  );
}
