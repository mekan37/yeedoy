'use client';

import Image from 'next/image';
import { useMemo, useState, useTransition } from 'react';
import { clsx } from 'clsx';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import {
  restoreMenu, restoreItem, restorePhoto,
  permanentlyDeleteMenu, permanentlyDeleteItem, permanentlyDeletePhoto,
  emptyTrash,
} from './cop-kutusu-islemleri';

export type CopKutusuSatiri = {
  entityType: 'menu' | 'item' | 'photo';
  entityId: string;
  title: string;
  subtitle: string;
  occurredAt: string;
  photoUrl: string | null;
  businessId: string;
  businessName: string;
  itemCount: number | null;
};

const PAGE_SIZE = 8;
const SAKLAMA_GUNU = 30;

export function CopKutusuIstemcisi({ satirlar, coklu }: { satirlar: CopKutusuSatiri[]; coklu: boolean }) {
  const [liste, setListe] = useState(satirlar);
  const [sekme, setSekme] = useState<'menuler' | 'urunler'>('menuler');
  const [arama, setArama] = useState('');
  const [subeFiltre, setSubeFiltre] = useState('tumu');
  const [sort, setSort] = useState<'yeni' | 'eski'>('yeni');
  const [sayfa, setSayfa] = useState(1);
  const [isPending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);

  const menuler = liste.filter((s) => s.entityType === 'menu');
  const urunler = liste.filter((s) => s.entityType === 'item' || s.entityType === 'photo');

  const subeler = useMemo(() => Array.from(new Set(liste.map((s) => s.businessName))).sort(), [liste]);

  const aktifListe = sekme === 'menuler' ? menuler : urunler;

  const filtreliListe = useMemo(() => {
    let list = aktifListe;
    if (subeFiltre !== 'tumu') list = list.filter((s) => s.businessName === subeFiltre);
    const q = arama.trim().toLocaleLowerCase('tr-TR');
    if (q) list = list.filter((s) => s.title.toLocaleLowerCase('tr-TR').includes(q));
    const sorted = [...list].sort((a, b) =>
      sort === 'yeni' ? b.occurredAt.localeCompare(a.occurredAt) : a.occurredAt.localeCompare(b.occurredAt),
    );
    return sorted;
  }, [aktifListe, subeFiltre, arama, sort]);

  const sayfaSayisi = Math.max(1, Math.ceil(filtreliListe.length / PAGE_SIZE));
  const guvenliSayfa = Math.min(sayfa, sayfaSayisi);
  const sayfadakiListe = filtreliListe.slice((guvenliSayfa - 1) * PAGE_SIZE, guvenliSayfa * PAGE_SIZE);

  function kaldirSatir(entityId: string) {
    setListe((prev) => prev.filter((s) => s.entityId !== entityId));
  }

  function handleRestore(row: CopKutusuSatiri) {
    setError(null);
    startTransition(async () => {
      const fn = row.entityType === 'menu' ? restoreMenu : row.entityType === 'item' ? restoreItem : restorePhoto;
      const result = await fn(row.entityId);
      if (result.error) setError(result.error);
      else kaldirSatir(row.entityId);
    });
  }

  function handleDelete(row: CopKutusuSatiri) {
    if (!confirm(`"${row.title}" kalıcı olarak silinecek. Bu işlem geri alınamaz. Onaylıyor musunuz?`)) return;
    setError(null);
    startTransition(async () => {
      const fn = row.entityType === 'menu' ? permanentlyDeleteMenu : row.entityType === 'item' ? permanentlyDeleteItem : permanentlyDeletePhoto;
      const result = await fn(row.entityId);
      if (result.error) setError(result.error);
      else kaldirSatir(row.entityId);
    });
  }

  function handleDeleteAllInTab() {
    if (filtreliListe.length === 0) return;
    if (!confirm(`Görüntülenen ${filtreliListe.length} öğe kalıcı olarak silinecek. Bu işlem geri alınamaz. Onaylıyor musunuz?`)) return;
    setError(null);
    startTransition(async () => {
      for (const row of filtreliListe) {
        const fn = row.entityType === 'menu' ? permanentlyDeleteMenu : row.entityType === 'item' ? permanentlyDeleteItem : permanentlyDeletePhoto;
        const result = await fn(row.entityId);
        if (result.error) { setError(result.error); return; }
        kaldirSatir(row.entityId);
      }
    });
  }

  function handleEmptyTrash() {
    if (liste.length === 0) return;
    if (!confirm(`Çöp kutusundaki tüm ${liste.length} öğe kalıcı olarak silinecek. Bu işlem geri alınamaz. Onaylıyor musunuz?`)) return;
    setError(null);
    startTransition(async () => {
      const businessIds = Array.from(new Set(liste.map((s) => s.businessId)));
      for (const businessId of businessIds) {
        const result = await emptyTrash(businessId);
        if (result.error) { setError(result.error); return; }
      }
      setListe([]);
    });
  }

  if (satirlar.length === 0) {
    return (
      <div className="flex flex-col gap-6">
        <Baslik />
        <PanelEmptyState icon={<TrashIcon />} title="Çöp kutusu boş" description="Silinen menüler ve ürünler burada listelenecek." />
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <Baslik />
        <div className="flex shrink-0 items-center gap-2">
          <button
            type="button"
            onClick={handleDeleteAllInTab}
            disabled={isPending || filtreliListe.length === 0}
            className="inline-flex items-center gap-1.5 rounded-xl border border-border bg-card px-3.5 py-2.5 text-sm font-extrabold text-textStrong hover:bg-black/4 disabled:cursor-not-allowed disabled:opacity-50"
          >
            <TrashIcon small /> Tümünü Kalıcı Sil
          </button>
          <button
            type="button"
            onClick={handleEmptyTrash}
            disabled={isPending}
            className="inline-flex items-center gap-1.5 rounded-xl border border-danger/30 px-3.5 py-2.5 text-sm font-extrabold text-danger hover:bg-red-50 disabled:cursor-not-allowed disabled:opacity-50"
          >
            <TrashIcon small /> Çöp Kutusunu Boşalt
          </button>
        </div>
      </div>

      {error && <p className="text-xs font-bold text-danger">{error}</p>}

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-[minmax(0,1fr)_300px]">
        <div className="flex min-w-0 flex-col gap-4">
          <div className="flex gap-1 border-b border-border">
            <TabButon active={sekme === 'menuler'} onClick={() => { setSekme('menuler'); setSayfa(1); }}>
              Menüler ({menuler.length})
            </TabButon>
            <TabButon active={sekme === 'urunler'} onClick={() => { setSekme('urunler'); setSayfa(1); }}>
              Ürünler ({urunler.length})
            </TabButon>
          </div>

          <div className="flex flex-wrap items-center gap-2">
            <div className="relative min-w-[200px] flex-1">
              <SearchIcon className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted" />
              <input
                value={arama}
                onChange={(e) => { setArama(e.target.value); setSayfa(1); }}
                placeholder={sekme === 'menuler' ? 'Menü ara...' : 'Ürün ara...'}
                className="w-full rounded-xl border border-border bg-bg py-2 pl-9 pr-3 text-sm text-textStrong outline-hidden focus:border-primary focus:ring-2 focus:ring-primary/20"
              />
            </div>
            {coklu && subeler.length > 0 && (
              <select
                value={subeFiltre}
                onChange={(e) => { setSubeFiltre(e.target.value); setSayfa(1); }}
                className="rounded-xl border border-border bg-bg px-3 py-2 text-sm font-semibold text-textStrong outline-hidden focus:border-primary"
              >
                <option value="tumu">Tüm Şubeler</option>
                {subeler.map((s) => (<option key={s} value={s}>{s}</option>))}
              </select>
            )}
            <select
              value={sort}
              onChange={(e) => setSort(e.target.value as 'yeni' | 'eski')}
              className="rounded-xl border border-border bg-bg px-3 py-2 text-sm font-semibold text-textStrong outline-hidden focus:border-primary"
            >
              <option value="yeni">Silinme Tarihi (Yeni → Eski)</option>
              <option value="eski">Silinme Tarihi (Eski → Yeni)</option>
            </select>
          </div>

          <div className="overflow-x-auto rounded-2xl border border-border bg-card">
            <table className="w-full min-w-[640px] border-collapse text-sm">
              <thead>
                <tr className="border-b border-border bg-black/2 text-left text-xs font-extrabold uppercase tracking-wide text-muted">
                  <th className="px-4 py-3">{sekme === 'menuler' ? 'Menü Adı' : 'Ürün Adı'}</th>
                  {coklu && <th className="px-4 py-3">Şube</th>}
                  <th className="px-4 py-3">Silinme Tarihi</th>
                  {sekme === 'menuler' && <th className="px-4 py-3">Silinen Ürün Sayısı</th>}
                  <th className="px-4 py-3 text-right">İşlemler</th>
                </tr>
              </thead>
              <tbody>
                {sayfadakiListe.map((row) => (
                  <tr key={row.entityId} className="border-b border-border last:border-0 hover:bg-black/2">
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-3">
                        <div className="relative h-10 w-10 shrink-0 overflow-hidden rounded-xl border border-border bg-bg">
                          {row.photoUrl ? (
                            <Image src={row.photoUrl} alt={row.title} fill className="object-cover" sizes="40px" />
                          ) : (
                            <div className="flex h-full w-full items-center justify-center text-muted"><EntityIcon type={row.entityType} /></div>
                          )}
                        </div>
                        <div className="min-w-0">
                          <p className="truncate font-bold text-textStrong">{row.title}</p>
                          <p className="truncate text-xs text-muted">{row.subtitle}</p>
                        </div>
                      </div>
                    </td>
                    {coklu && (
                      <td className="px-4 py-3">
                        <span className="rounded-full border border-border bg-bg px-2 py-0.5 text-[11px] font-bold text-muted">{row.businessName}</span>
                      </td>
                    )}
                    <td className="px-4 py-3 text-xs text-muted">
                      {new Date(row.occurredAt).toLocaleDateString('tr-TR')}{' '}
                      {new Date(row.occurredAt).toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' })}
                    </td>
                    {sekme === 'menuler' && (
                      <td className="px-4 py-3 text-textStrong">{row.itemCount ?? 0} ürün</td>
                    )}
                    <td className="px-4 py-3">
                      <div className="flex items-center justify-end gap-1.5">
                        <button
                          type="button"
                          disabled={isPending}
                          onClick={() => handleRestore(row)}
                          className="inline-flex items-center gap-1 rounded-lg border border-border px-2.5 py-1.5 text-xs font-extrabold text-textStrong hover:bg-black/4 disabled:opacity-50"
                        >
                          <RestoreIcon /> Geri Yükle
                        </button>
                        <button
                          type="button"
                          disabled={isPending}
                          onClick={() => handleDelete(row)}
                          aria-label={`${row.title} kalıcı sil`}
                          className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg border border-danger/30 text-danger hover:bg-red-50 disabled:opacity-50"
                        >
                          <TrashIcon small />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
                {sayfadakiListe.length === 0 && (
                  <tr>
                    <td colSpan={coklu ? 5 : 4} className="px-4 py-10 text-center text-sm text-muted">
                      Bu filtrelerle eşleşen öğe yok.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>

          {sayfaSayisi > 1 ? (
            <div className="flex items-center justify-between text-sm">
              <p className="text-muted">Toplam {filtreliListe.length} {sekme === 'menuler' ? 'menü' : 'ürün'}</p>
              <div className="flex items-center gap-1.5">
                <button type="button" disabled={guvenliSayfa === 1} onClick={() => setSayfa((p) => Math.max(1, p - 1))} className="rounded-lg border border-border px-3 py-1.5 font-semibold text-textStrong disabled:cursor-not-allowed disabled:opacity-40 hover:bg-black/4">Önceki</button>
                {Array.from({ length: sayfaSayisi }, (_, i) => i + 1).map((n) => (
                  <button key={n} type="button" onClick={() => setSayfa(n)} className={clsx('h-8 w-8 rounded-lg font-bold', n === guvenliSayfa ? 'text-white' : 'border border-border text-textStrong hover:bg-black/4')} style={n === guvenliSayfa ? { background: 'linear-gradient(135deg, #7f1d1d, #dc2626)' } : undefined}>{n}</button>
                ))}
                <button type="button" disabled={guvenliSayfa === sayfaSayisi} onClick={() => setSayfa((p) => Math.min(sayfaSayisi, p + 1))} className="rounded-lg border border-border px-3 py-1.5 font-semibold text-textStrong disabled:cursor-not-allowed disabled:opacity-40 hover:bg-black/4">Sonraki</button>
              </div>
            </div>
          ) : (
            <p className="text-sm text-muted">Toplam {filtreliListe.length} {sekme === 'menuler' ? 'menü' : 'ürün'}</p>
          )}
        </div>

        <div className="flex flex-col gap-4">
          <div className="rounded-2xl border border-border bg-card p-4">
            <h3 className="mb-3 text-sm font-black text-textStrong">Çöp Kutusu Özeti</h3>
            <div className="mb-3 flex items-center gap-3 rounded-xl border border-border p-3">
              <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-red-50 text-danger"><TrashIcon small /></span>
              <div>
                <p className="text-lg font-black text-textStrong">{liste.length} Öğe</p>
                <p className="text-[11px] text-muted">Toplam Silinen</p>
              </div>
            </div>
            <div className="flex flex-col gap-1.5 text-sm">
              <div className="flex items-center justify-between"><span className="text-muted">Menüler</span><span className="font-bold text-textStrong">{menuler.length}</span></div>
              <div className="flex items-center justify-between"><span className="text-muted">Ürünler</span><span className="font-bold text-textStrong">{urunler.length}</span></div>
            </div>
            <p className="mt-3 text-[11px] leading-relaxed text-muted">
              Öğeler {SAKLAMA_GUNU} gün boyunca saklanır. Süre dolduğunda otomatik olarak kalıcı silinmez — dilediğiniz zaman
              kendiniz kalıcı olarak silebilir veya geri yükleyebilirsiniz.
            </p>
          </div>

          <div className="rounded-2xl border border-border bg-card p-4">
            <h3 className="mb-3 text-sm font-black text-textStrong">Bilgilendirme</h3>
            <div className="flex flex-col gap-3">
              <BilgiSatiri icon={<RestoreIcon />} title="Geri Yükle" description="Seçtiğiniz menü veya ürünü orijinal yerine geri yükler." />
              <BilgiSatiri icon={<TrashIcon small />} title="Kalıcı Sil" description="Seçtiğiniz menü veya ürünü geri döndürülemez şekilde siler." />
            </div>
          </div>

          <div className="rounded-2xl border border-amber-200 bg-amber-50 p-4">
            <p className="mb-1 text-xs font-extrabold text-amber-700">Dikkat</p>
            <p className="text-[11px] leading-relaxed text-amber-700/80">Kalıcı olarak silinen öğeler geri getirilemez.</p>
          </div>
        </div>
      </div>
    </div>
  );
}

function Baslik() {
  return (
    <div>
      <h1 className="text-2xl font-black tracking-tight text-textStrong">Çöp Kutusu</h1>
      <p className="mt-1 text-sm text-muted">Silinen menüler ve ürünler burada listelenir. Dilerseniz geri yükleyebilir veya kalıcı olarak silebilirsiniz.</p>
    </div>
  );
}

function TabButon({ active, onClick, children }: { active: boolean; onClick: () => void; children: React.ReactNode }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={clsx(
        'border-b-2 px-3 py-2.5 text-sm font-extrabold transition-colors',
        active ? 'border-primary text-primary' : 'border-transparent text-muted hover:text-textStrong',
      )}
    >
      {children}
    </button>
  );
}

function BilgiSatiri({ icon, title, description }: { icon: React.ReactNode; title: string; description: string }) {
  return (
    <div className="flex items-start gap-2.5">
      <span className="mt-0.5 shrink-0 text-primary">{icon}</span>
      <div>
        <p className="text-xs font-extrabold text-textStrong">{title}</p>
        <p className="text-[11px] text-muted">{description}</p>
      </div>
    </div>
  );
}

function SearchIcon({ className }: { className?: string }) {
  return <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" className={className}><circle cx="11" cy="11" r="7" /><path d="m21 21-4.35-4.35" /></svg>;
}
function RestoreIcon() {
  return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="1 4 1 10 7 10" /><path d="M3.51 15a9 9 0 1 0 2.13-9.36L1 10" /></svg>;
}
function TrashIcon({ small }: { small?: boolean }) {
  const size = small ? 14 : 20;
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <polyline points="3 6 5 6 21 6" />
      <path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6" />
      <path d="M10 11v6" /><path d="M14 11v6" />
      <path d="M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2" />
    </svg>
  );
}
function EntityIcon({ type }: { type: 'menu' | 'item' | 'photo' }) {
  if (type === 'menu') return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="3" y1="6" x2="21" y2="6" /><line x1="3" y1="12" x2="21" y2="12" /><line x1="3" y1="18" x2="15" y2="18" /></svg>
  );
  if (type === 'photo') return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="3" width="18" height="18" rx="2" /><circle cx="8.5" cy="8.5" r="1.5" /><polyline points="21 15 16 10 5 21" /></svg>
  );
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 2L2 7l10 5 10-5-10-5z" /><path d="M2 17l10 5 10-5" /><path d="M2 12l10 5 10-5" /></svg>
  );
}
