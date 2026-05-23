'use client';

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';

export function YeniAnahtarForm() {
  const router = useRouter();
  const [pending, setPending] = useState(false);
  const [yeniAnahtar, setYeniAnahtar] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const [name, setName] = useState('');
  const [scope, setScope] = useState('read');
  const [expiresDays, setExpiresDays] = useState(365);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!name.trim()) return;
    setPending(true);
    setError(null);
    setYeniAnahtar(null);
    try {
      const res = await fetch('/sunucu/yonetici/api-anahtarlari', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: name.trim(), scope, expiresDays }),
      });
      const json = await res.json() as { ok: boolean; key?: string; error?: string };
      if (json.ok && json.key) {
        setYeniAnahtar(json.key);
        setName('');
        router.refresh();
      } else {
        setError(json.error ?? 'Hata oluştu');
      }
    } catch {
      setError('Bağlantı hatası');
    } finally {
      setPending(false);
    }
  }

  if (yeniAnahtar) {
    return (
      <div className="flex flex-col gap-3">
        <div className="rounded-xl border border-success/30 bg-success/[0.06] p-4">
          <p className="mb-2 text-sm font-[800] text-success">✓ API anahtarı oluşturuldu — tek seferlik gösterim!</p>
          <div className="flex items-center gap-2">
            <code className="flex-1 overflow-x-auto rounded-lg bg-card px-3 py-2 font-mono text-sm text-textStrong border border-border">
              {yeniAnahtar}
            </code>
            <button
              type="button"
              onClick={() => navigator.clipboard.writeText(yeniAnahtar)}
              className="rounded-lg border border-border bg-card px-3 py-2 text-xs font-[700] text-textStrong hover:border-primary/30"
            >
              Kopyala
            </button>
          </div>
          <p className="mt-2 text-xs text-muted">Bu anahtarı güvenli bir yere kaydedin. Bir daha gösterilmeyecek.</p>
        </div>
        <button
          type="button"
          onClick={() => setYeniAnahtar(null)}
          className="self-start text-sm font-[700] text-primary hover:underline"
        >
          Yeni Anahtar Oluştur
        </button>
      </div>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="flex flex-col gap-4">
      <div className="grid gap-4 sm:grid-cols-3">
        <div className="flex flex-col gap-1.5">
          <label className="text-sm font-[700] text-textStrong">Anahtar Adı</label>
          <input
            type="text"
            value={name}
            onChange={e => setName(e.target.value)}
            placeholder="ör. Mobil Uygulama"
            required
            maxLength={60}
            className="input-yd rounded-xl px-3 py-2.5 text-sm"
          />
        </div>
        <div className="flex flex-col gap-1.5">
          <label className="text-sm font-[700] text-textStrong">İzin Kapsamı</label>
          <select value={scope} onChange={e => setScope(e.target.value)} className="input-yd rounded-xl px-3 py-2.5 text-sm">
            <option value="read">Sadece Okuma</option>
            <option value="read:businesses">İşletme Okuma</option>
            <option value="read:menus">Menü Okuma</option>
            <option value="read_write">Okuma + Yazma</option>
            <option value="admin">Admin (tam erişim)</option>
          </select>
        </div>
        <div className="flex flex-col gap-1.5">
          <label className="text-sm font-[700] text-textStrong">Geçerlilik Süresi</label>
          <select value={expiresDays} onChange={e => setExpiresDays(Number(e.target.value))} className="input-yd rounded-xl px-3 py-2.5 text-sm">
            <option value={30}>30 gün</option>
            <option value={90}>90 gün</option>
            <option value={365}>1 yıl</option>
            <option value={0}>Sınırsız</option>
          </select>
        </div>
      </div>
      {error && <p className="text-sm font-[700] text-danger">{error}</p>}
      <div className="flex justify-end">
        <button
          type="submit"
          disabled={pending}
          className="btn-primary rounded-xl px-4 py-2.5 text-sm font-[700] text-white disabled:opacity-50"
        >
          {pending ? 'Oluşturuluyor…' : 'Anahtar Oluştur'}
        </button>
      </div>
    </form>
  );
}

export function AnahtarSilButonu({ keyId }: { keyId: string }) {
  const router = useRouter();
  const [pending, startTransition] = useTransition();

  function handleRevoke() {
    if (!confirm('Bu API anahtarı iptal edilecek. Devam et?')) return;
    startTransition(async () => {
      await fetch('/sunucu/yonetici/api-anahtarlari', {
        method: 'DELETE',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id: keyId }),
      });
      router.refresh();
    });
  }

  return (
    <button
      type="button"
      onClick={handleRevoke}
      disabled={pending}
      className="shrink-0 rounded-lg border border-danger/30 px-3 py-1.5 text-xs font-[700] text-danger hover:bg-danger/[0.06] disabled:opacity-50 transition-colors"
    >
      {pending ? '…' : 'İptal Et'}
    </button>
  );
}
