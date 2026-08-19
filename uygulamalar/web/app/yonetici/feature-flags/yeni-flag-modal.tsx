'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { X } from 'lucide-react';
import { PROJE_SECENEKLERI, TUR_SECENEKLERI, ORTAM_ETIKETLERI } from './flag-yardimcilari';

async function createFlag(data: {
  key: string; description: string; rollout_percent: number; environment: string;
  project: string; type: string; is_draft: boolean; region: string;
}): Promise<{ ok: boolean; error?: string }> {
  const res = await fetch('/sunucu/yonetici/feature-flags', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });
  return res.json();
}

export function YeniFlagButonu({ variant = 'primary' }: { variant?: 'primary' | 'list' }) {
  const [open, setOpen] = useState(false);

  return (
    <>
      {variant === 'primary' ? (
        <button
          type="button"
          onClick={() => setOpen(true)}
          className="flex items-center gap-2 rounded-xl bg-primary px-4 py-2.5 text-sm font-extrabold text-white transition-opacity hover:opacity-90"
        >
          <PlusIcon /> Yeni Feature Flag
        </button>
      ) : (
        <button
          type="button"
          onClick={() => setOpen(true)}
          className="flex items-center gap-3 rounded-xl border border-border px-3 py-2.5 text-left transition-colors hover:border-primary/30 hover:bg-black/2"
        >
          <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-(--yd-color-primary)"><PlusIcon /></div>
          <div className="min-w-0">
            <p className="text-xs font-extrabold text-textStrong">Yeni Feature Flag Oluştur</p>
            <p className="truncate text-[10px] text-muted">Sıfırdan yeni bir feature flag oluşturun</p>
          </div>
        </button>
      )}
      {open && <YeniFlagModal onClose={() => setOpen(false)} />}
    </>
  );
}

function YeniFlagModal({ onClose }: { onClose: () => void }) {
  const router = useRouter();
  const [pending, setPending] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const [key, setKey] = useState('');
  const [description, setDescription] = useState('');
  const [rollout, setRollout] = useState(0);
  const [env, setEnv] = useState('staging');
  const [project, setProject] = useState(PROJE_SECENEKLERI[0]);
  const [type, setType] = useState(Object.keys(TUR_SECENEKLERI)[0]);
  const [isDraft, setIsDraft] = useState(true);
  const [region, setRegion] = useState('');

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
        project,
        type,
        is_draft: isDraft,
        region,
      });
      if (result.ok) {
        router.refresh();
        onClose();
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
    <>
      <div className="fixed inset-0 z-40 bg-black/30" onClick={onClose} aria-hidden="true" />
      <div className="fixed left-1/2 top-1/2 z-50 w-full max-w-lg -translate-x-1/2 -translate-y-1/2 rounded-2xl border border-border bg-white p-6 shadow-2xl">
        <div className="mb-4 flex items-center justify-between">
          <h2 className="text-lg font-black text-textStrong">Yeni Feature Flag</h2>
          <button onClick={onClose} className="rounded-lg p-1.5 text-muted hover:bg-black/4 hover:text-textStrong" aria-label="Kapat">
            <X className="h-4 w-4" />
          </button>
        </div>
        <form onSubmit={handleSubmit} className="flex max-h-[70vh] flex-col gap-4 overflow-y-auto">
          <div className="grid gap-4 sm:grid-cols-2">
            <div className="flex flex-col gap-1.5 sm:col-span-2">
              <label className="text-sm font-bold text-textStrong">Flag Anahtarı</label>
              <input type="text" value={key} onChange={(e) => setKey(e.target.value)} placeholder="yeni_ozellik_aktif" pattern="[a-zA-Z0-9_]+" required className="input-yd rounded-xl px-3 py-2.5 text-sm" />
              <p className="text-[11px] text-muted">Sadece harf, rakam ve alt çizgi</p>
            </div>
            <div className="flex flex-col gap-1.5 sm:col-span-2">
              <label className="text-sm font-bold text-textStrong">Açıklama</label>
              <input type="text" value={description} onChange={(e) => setDescription(e.target.value)} placeholder="Bu flag ne yapar?" maxLength={200} className="input-yd rounded-xl px-3 py-2.5 text-sm" />
            </div>
            <div className="flex flex-col gap-1.5">
              <label className="text-sm font-bold text-textStrong">Proje</label>
              <select value={project} onChange={(e) => setProject(e.target.value)} className="input-yd rounded-xl px-3 py-2.5 text-sm">
                {PROJE_SECENEKLERI.map((p) => <option key={p} value={p}>{p}</option>)}
              </select>
            </div>
            <div className="flex flex-col gap-1.5">
              <label className="text-sm font-bold text-textStrong">Ortam</label>
              <select value={env} onChange={(e) => setEnv(e.target.value)} className="input-yd rounded-xl px-3 py-2.5 text-sm">
                {Object.entries(ORTAM_ETIKETLERI).map(([v, l]) => <option key={v} value={v}>{l}</option>)}
              </select>
            </div>
            <div className="flex flex-col gap-1.5">
              <label className="text-sm font-bold text-textStrong">Tür</label>
              <select value={type} onChange={(e) => setType(e.target.value)} className="input-yd rounded-xl px-3 py-2.5 text-sm">
                {Object.entries(TUR_SECENEKLERI).map(([v, l]) => <option key={v} value={v}>{l}</option>)}
              </select>
            </div>
            <div className="flex flex-col gap-1.5">
              <label className="text-sm font-bold text-textStrong">Hedef Bölge</label>
              <select value={region} onChange={(e) => setRegion(e.target.value)} className="input-yd rounded-xl px-3 py-2.5 text-sm">
                <option value="">Tüm Kullanıcılar</option>
                <option value="TR">Türkiye</option>
              </select>
              <p className="text-[11px] text-muted">İstemci tarafında (mobil/web) uygulanır — get_runtime_feature_flags_v1 ile taşınır.</p>
            </div>
            <div className="flex flex-col gap-1.5 sm:col-span-2">
              <label className="text-sm font-bold text-textStrong">Yayılım Oranı: %{rollout}</label>
              <input type="range" min={0} max={100} step={5} value={rollout} onChange={(e) => setRollout(Number(e.target.value))} className="w-full" />
            </div>
            <label className="flex items-center gap-2 text-sm font-bold text-textStrong sm:col-span-2">
              <input type="checkbox" checked={isDraft} onChange={(e) => setIsDraft(e.target.checked)} className="h-4 w-4 rounded border-border" />
              Taslak olarak kaydet (henüz açılmasın)
            </label>
          </div>
          {error && <p className="text-sm font-bold text-danger">{error}</p>}
          <div className="flex justify-end gap-2">
            <button type="button" onClick={onClose} className="rounded-xl border border-border px-4 py-2.5 text-sm font-bold text-muted hover:text-textStrong">İptal</button>
            <button type="submit" disabled={pending} className="rounded-xl bg-primary px-4 py-2.5 text-sm font-bold text-white disabled:opacity-50">
              {pending ? 'Oluşturuluyor…' : 'Flag Oluştur'}
            </button>
          </div>
        </form>
      </div>
    </>
  );
}

function PlusIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="12" y1="5" x2="12" y2="19" /><line x1="5" y1="12" x2="19" y2="12" /></svg>;
}
