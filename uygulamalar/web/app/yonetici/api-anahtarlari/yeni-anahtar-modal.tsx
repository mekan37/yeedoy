'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { X } from 'lucide-react';

export function YeniAnahtarButonu({ variant = 'primary' }: { variant?: 'primary' | 'list' }) {
  const [open, setOpen] = useState(false);

  return (
    <>
      {variant === 'primary' ? (
        <button
          type="button"
          onClick={() => setOpen(true)}
          className="flex items-center gap-2 rounded-xl bg-primary px-4 py-2.5 text-sm font-extrabold text-white transition-opacity hover:opacity-90"
        >
          <PlusIcon /> Yeni API Anahtarı
        </button>
      ) : (
        <button
          type="button"
          onClick={() => setOpen(true)}
          className="flex items-center gap-3 rounded-xl border border-border px-3 py-2.5 text-left transition-colors hover:border-primary/30 hover:bg-black/2"
        >
          <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-(--yd-color-primary)"><PlusIcon /></div>
          <div className="min-w-0">
            <p className="text-xs font-extrabold text-textStrong">Yeni API Anahtarı Oluştur</p>
            <p className="truncate text-[10px] text-muted">Yeni bir entegrasyon anahtarı üretin</p>
          </div>
        </button>
      )}
      {open && <YeniAnahtarModal onClose={() => setOpen(false)} />}
    </>
  );
}

function YeniAnahtarModal({ onClose }: { onClose: () => void }) {
  const router = useRouter();
  const [pending, setPending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [yeniAnahtar, setYeniAnahtar] = useState<string | null>(null);

  const [name, setName] = useState('');
  const [scope, setScope] = useState('read');
  const [expiresDays, setExpiresDays] = useState(365);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!name.trim()) return;
    setPending(true);
    setError(null);
    try {
      const res = await fetch('/sunucu/yonetici/api-anahtarlari', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: name.trim(), scope, expiresDays }),
      });
      const json = await res.json() as { ok: boolean; key?: string; error?: string };
      if (json.ok && json.key) {
        setYeniAnahtar(json.key);
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

  return (
    <>
      <div className="fixed inset-0 z-40 bg-black/30" onClick={yeniAnahtar ? undefined : onClose} aria-hidden="true" />
      <div className="fixed left-1/2 top-1/2 z-50 w-full max-w-lg -translate-x-1/2 -translate-y-1/2 rounded-2xl border border-border bg-white p-6 shadow-2xl">
        <div className="mb-4 flex items-center justify-between">
          <h2 className="text-lg font-black text-textStrong">Yeni API Anahtarı</h2>
          <button onClick={onClose} className="rounded-lg p-1.5 text-muted hover:bg-black/4 hover:text-textStrong" aria-label="Kapat">
            <X className="h-4 w-4" />
          </button>
        </div>

        {yeniAnahtar ? (
          <div className="flex flex-col gap-3">
            <div className="rounded-xl border border-success/30 bg-success/6 p-4">
              <p className="mb-2 text-sm font-extrabold text-success">✓ API anahtarı oluşturuldu — tek seferlik gösterim!</p>
              <div className="flex items-center gap-2">
                <code className="flex-1 overflow-x-auto rounded-lg border border-border bg-card px-3 py-2 font-mono text-sm text-textStrong">
                  {yeniAnahtar}
                </code>
                <button
                  type="button"
                  onClick={() => navigator.clipboard.writeText(yeniAnahtar)}
                  className="rounded-lg border border-border bg-card px-3 py-2 text-xs font-bold text-textStrong hover:border-primary/30"
                >
                  Kopyala
                </button>
              </div>
              <p className="mt-2 text-xs text-muted">Bu anahtarı güvenli bir yere kaydedin. Bir daha gösterilmeyecek.</p>
            </div>
            <button type="button" onClick={onClose} className="self-end rounded-xl bg-primary px-4 py-2.5 text-sm font-bold text-white">Kapat</button>
          </div>
        ) : (
          <form onSubmit={handleSubmit} className="flex flex-col gap-4">
            <div className="flex flex-col gap-1.5">
              <label className="text-sm font-bold text-textStrong">Anahtar Adı</label>
              <input
                type="text"
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="ör. Mobil Uygulama"
                required
                maxLength={60}
                className="input-yd rounded-xl px-3 py-2.5 text-sm"
              />
            </div>
            <div className="grid gap-4 sm:grid-cols-2">
              <div className="flex flex-col gap-1.5">
                <label className="text-sm font-bold text-textStrong">İzin Kapsamı</label>
                <select value={scope} onChange={(e) => setScope(e.target.value)} className="input-yd rounded-xl px-3 py-2.5 text-sm">
                  <option value="read">Salt Okuma</option>
                  <option value="read:businesses">İşletme Okuma</option>
                  <option value="read:menus">Menü Okuma</option>
                  <option value="read_write">Okuma + Yazma</option>
                  <option value="admin">Admin (tam erişim)</option>
                </select>
              </div>
              <div className="flex flex-col gap-1.5">
                <label className="text-sm font-bold text-textStrong">Geçerlilik Süresi</label>
                <select value={expiresDays} onChange={(e) => setExpiresDays(Number(e.target.value))} className="input-yd rounded-xl px-3 py-2.5 text-sm">
                  <option value={30}>30 gün</option>
                  <option value={90}>90 gün</option>
                  <option value={365}>1 yıl</option>
                  <option value={0}>Sınırsız</option>
                </select>
              </div>
            </div>
            {error && <p className="text-sm font-bold text-danger">{error}</p>}
            <div className="flex justify-end gap-2">
              <button type="button" onClick={onClose} className="rounded-xl border border-border px-4 py-2.5 text-sm font-bold text-muted hover:text-textStrong">İptal</button>
              <button type="submit" disabled={pending} className="rounded-xl bg-primary px-4 py-2.5 text-sm font-bold text-white disabled:opacity-50">
                {pending ? 'Oluşturuluyor…' : 'Anahtar Oluştur'}
              </button>
            </div>
          </form>
        )}
      </div>
    </>
  );
}

function PlusIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="12" y1="5" x2="12" y2="19" /><line x1="5" y1="12" x2="19" y2="12" /></svg>;
}
