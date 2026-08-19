'use client';

import Link from 'next/link';
import Image from 'next/image';
import { useMemo, useState } from 'react';
import { clsx } from 'clsx';
import { MetricCard } from '@/src/ui/bilesenler/olcum-karti';
import { PanelActionButton } from '@/src/ui/bilesenler/panel-eylem-dugmesi';

export type IsletmelerimSatiri = {
  id: string;
  name: string;
  slug: string | null;
  category: string;
  city: string | null;
  district: string | null;
  isActive: boolean;
  isPrimary: boolean;
  photoUrl: string | null;
  avgRating: number | null;
  reviewsCount: number | null;
  viewTrendPct: number;
  isOpenNow: boolean | null;
  closeTime: string | null;
};

type SortKey = 'yeni' | 'isim' | 'puan';

const PAGE_SIZE = 6;

export function IsletmelerimIstemcisi({
  satirlar,
  pendingCount,
}: {
  satirlar: IsletmelerimSatiri[];
  pendingCount: number;
}) {
  const [arama, setArama] = useState('');
  const [durumFiltre, setDurumFiltre] = useState<'hepsi' | 'aktif' | 'pasif'>('hepsi');
  const [siralama, setSiralama] = useState<SortKey>('yeni');
  const [sayfa, setSayfa] = useState(1);

  const toplam = satirlar.length;
  const aktif = satirlar.filter((s) => s.isActive).length;
  const pasif = toplam - aktif;

  const filtreliListe = useMemo(() => {
    let list = satirlar;
    const q = arama.trim().toLocaleLowerCase('tr-TR');
    if (q) {
      list = list.filter(
        (s) =>
          s.name.toLocaleLowerCase('tr-TR').includes(q) ||
          s.category.toLocaleLowerCase('tr-TR').includes(q) ||
          (s.city ?? '').toLocaleLowerCase('tr-TR').includes(q),
      );
    }
    if (durumFiltre === 'aktif') list = list.filter((s) => s.isActive);
    if (durumFiltre === 'pasif') list = list.filter((s) => !s.isActive);

    const sorted = [...list];
    if (siralama === 'isim') sorted.sort((a, b) => a.name.localeCompare(b.name, 'tr-TR'));
    else if (siralama === 'puan') sorted.sort((a, b) => (b.avgRating ?? 0) - (a.avgRating ?? 0));
    return sorted;
  }, [satirlar, arama, durumFiltre, siralama]);

  const sayfaSayisi = Math.max(1, Math.ceil(filtreliListe.length / PAGE_SIZE));
  const guvenliSayfa = Math.min(sayfa, sayfaSayisi);
  const sayfadakiListe = filtreliListe.slice((guvenliSayfa - 1) * PAGE_SIZE, guvenliSayfa * PAGE_SIZE);

  return (
    <div className="flex flex-col gap-6 p-4 md:p-6">
      <div className="flex flex-col gap-1 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-xl font-black text-textStrong">İşletmelerim</h1>
          <p className="text-sm text-muted">Tüm işletmelerinizi tek yerden yönetin.</p>
        </div>
        <Link href="/sahip/isletmeler/yeni">
          <PanelActionButton variant="primary" icon={<PlusIcon />}>
            Yeni İşletme Ekle
          </PanelActionButton>
        </Link>
      </div>

      <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
        <MetricCard title="Toplam İşletme" value={toplam} tone="primary" icon={<BuildingIcon />} />
        <MetricCard title="Aktif İşletme" value={aktif} tone="green" icon={<CheckIcon />} />
        <Link href="/sahip/isletmeler/basvurular" className="contents">
          <MetricCard title="Onay Bekleyen" value={pendingCount} tone="orange" icon={<ClockIcon />} className="cursor-pointer" />
        </Link>
        <MetricCard title="Pasif İşletme" value={pasif} tone="purple" icon={<PauseIcon />} />
      </div>

      <div className="flex flex-col gap-3 rounded-2xl border border-border bg-card p-4 shadow-xs sm:flex-row sm:items-center sm:justify-between">
        <div className="relative w-full sm:max-w-xs">
          <SearchIcon className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted" />
          <input
            value={arama}
            onChange={(e) => {
              setArama(e.target.value);
              setSayfa(1);
            }}
            placeholder="İşletme, kategori veya şehir ara..."
            className="w-full rounded-xl border border-border bg-bg py-2 pl-9 pr-3 text-sm text-textStrong outline-hidden focus:border-(--yd-color-primary) focus:ring-2 focus:ring-primary/20"
          />
        </div>

        <div className="flex flex-wrap items-center gap-2">
          <select
            value={durumFiltre}
            onChange={(e) => {
              setDurumFiltre(e.target.value as typeof durumFiltre);
              setSayfa(1);
            }}
            className="rounded-xl border border-border bg-bg px-3 py-2 text-sm font-semibold text-textStrong outline-hidden focus:border-(--yd-color-primary)"
          >
            <option value="hepsi">Tüm Durumlar</option>
            <option value="aktif">Aktif</option>
            <option value="pasif">Pasif</option>
          </select>

          <select
            value={siralama}
            onChange={(e) => setSiralama(e.target.value as SortKey)}
            className="rounded-xl border border-border bg-bg px-3 py-2 text-sm font-semibold text-textStrong outline-hidden focus:border-(--yd-color-primary)"
          >
            <option value="yeni">En Yeni</option>
            <option value="isim">İsme Göre</option>
            <option value="puan">Puana Göre</option>
          </select>
        </div>
      </div>

      <div className="overflow-x-auto rounded-2xl border border-border bg-card shadow-xs">
        <table className="w-full min-w-[760px] border-collapse text-sm">
          <thead>
            <tr className="border-b border-border bg-black/2 text-left text-xs font-extrabold uppercase tracking-wide text-muted">
              <th className="px-4 py-3">İşletme</th>
              <th className="px-4 py-3">Konum</th>
              <th className="px-4 py-3">Durum</th>
              <th className="px-4 py-3">Puan</th>
              <th className="px-4 py-3">Görüntülenme</th>
              <th className="px-4 py-3 text-right">Aksiyon</th>
            </tr>
          </thead>
          <tbody>
            {sayfadakiListe.map((s) => (
              <tr key={s.id} className="border-b border-border last:border-0 hover:bg-black/2">
                <td className="px-4 py-3">
                  <div className="flex items-center gap-3">
                    <div className="relative h-10 w-10 shrink-0 overflow-hidden rounded-xl border border-border bg-black/4">
                      {s.photoUrl ? (
                        <Image src={s.photoUrl} alt={s.name} fill className="object-cover" sizes="40px" />
                      ) : (
                        <div className="flex h-full w-full items-center justify-center text-muted">
                          <BuildingIcon />
                        </div>
                      )}
                    </div>
                    <div className="min-w-0">
                      <div className="flex items-center gap-1.5">
                        <p className="truncate font-bold text-textStrong">{s.name}</p>
                        {s.isPrimary && (
                          <span className="shrink-0 rounded-full bg-primary/10 px-1.5 py-0.5 text-[10px] font-extrabold text-(--yd-color-primary)">
                            Ana
                          </span>
                        )}
                      </div>
                      <p className="truncate text-xs text-muted">{s.category}</p>
                    </div>
                  </div>
                </td>
                <td className="px-4 py-3 text-textStrong">
                  {s.city ? `${s.district ? `${s.district}, ` : ''}${s.city}` : '—'}
                </td>
                <td className="px-4 py-3">
                  <div className="flex flex-col gap-1">
                    <span
                      className={clsx(
                        'inline-flex w-fit items-center gap-1 rounded-full px-2 py-0.5 text-[11px] font-extrabold',
                        s.isActive ? 'bg-emerald-50 text-emerald-600' : 'bg-black/5 text-muted',
                      )}
                    >
                      <span className={clsx('h-1.5 w-1.5 rounded-full', s.isActive ? 'bg-emerald-500' : 'bg-muted')} />
                      {s.isActive ? 'Aktif' : 'Pasif'}
                    </span>
                    {s.isActive && s.isOpenNow !== null && (
                      <span className="text-[11px] text-muted">
                        {s.isOpenNow ? `Açık${s.closeTime ? ` · ${s.closeTime.slice(0, 5)}'e kadar` : ''}` : 'Kapalı'}
                      </span>
                    )}
                  </div>
                </td>
                <td className="px-4 py-3">
                  {s.avgRating ? (
                    <div className="flex items-center gap-1 font-bold text-textStrong">
                      <StarIcon />
                      {s.avgRating.toFixed(1)}
                      <span className="font-normal text-muted">({s.reviewsCount ?? 0})</span>
                    </div>
                  ) : (
                    <span className="text-muted">—</span>
                  )}
                </td>
                <td className="px-4 py-3">
                  <span
                    className={clsx(
                      'inline-flex items-center gap-0.5 font-extrabold',
                      s.viewTrendPct >= 0 ? 'text-emerald-600' : 'text-(--yd-color-danger)',
                    )}
                  >
                    {s.viewTrendPct >= 0 ? '↑' : '↓'} %{Math.abs(s.viewTrendPct)}
                  </span>
                  <span className="ml-1 text-xs text-muted">7 gün</span>
                </td>
                <td className="px-4 py-3 text-right">
                  <Link
                    href={`/sahip/isletmeler/${s.id}`}
                    className="inline-flex items-center gap-1 rounded-lg border border-border px-3 py-1.5 text-xs font-extrabold text-textStrong hover:bg-black/4 hover:border-borderStrong"
                  >
                    Görüntüle
                  </Link>
                </td>
              </tr>
            ))}

            {sayfadakiListe.length === 0 && (
              <tr>
                <td colSpan={6} className="px-4 py-10 text-center text-sm text-muted">
                  {toplam === 0 ? 'Henüz işletmeniz yok.' : 'Aramanızla eşleşen işletme bulunamadı.'}
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {sayfaSayisi > 1 && (
        <div className="flex items-center justify-between text-sm">
          <p className="text-muted">
            {filtreliListe.length} işletmeden {(guvenliSayfa - 1) * PAGE_SIZE + 1}-
            {Math.min(guvenliSayfa * PAGE_SIZE, filtreliListe.length)} arası gösteriliyor
          </p>
          <div className="flex items-center gap-1.5">
            <button
              type="button"
              disabled={guvenliSayfa === 1}
              onClick={() => setSayfa((p) => Math.max(1, p - 1))}
              className="rounded-lg border border-border px-3 py-1.5 font-semibold text-textStrong disabled:cursor-not-allowed disabled:opacity-40 hover:bg-black/4"
            >
              Önceki
            </button>
            {Array.from({ length: sayfaSayisi }, (_, i) => i + 1).map((n) => (
              <button
                key={n}
                type="button"
                onClick={() => setSayfa(n)}
                className={clsx(
                  'h-8 w-8 rounded-lg font-bold',
                  n === guvenliSayfa ? 'text-white' : 'border border-border text-textStrong hover:bg-black/4',
                )}
                style={n === guvenliSayfa ? { background: 'linear-gradient(135deg, #7f1d1d, #dc2626)' } : undefined}
              >
                {n}
              </button>
            ))}
            <button
              type="button"
              disabled={guvenliSayfa === sayfaSayisi}
              onClick={() => setSayfa((p) => Math.min(sayfaSayisi, p + 1))}
              className="rounded-lg border border-border px-3 py-1.5 font-semibold text-textStrong disabled:cursor-not-allowed disabled:opacity-40 hover:bg-black/4"
            >
              Sonraki
            </button>
          </div>
        </div>
      )}

      <div className="flex flex-col items-center gap-3 rounded-2xl border border-border p-6 text-center sm:flex-row sm:justify-between sm:text-left" style={{ background: 'linear-gradient(135deg, rgba(127,29,29,0.06), rgba(220,38,38,0.03))' }}>
        <div>
          <p className="font-black text-textStrong">Yeni bir şubeniz mi var?</p>
          <p className="text-sm text-muted">İşletmenizi ekleyin, dakikalar içinde müşterilerinize ulaşın.</p>
        </div>
        <Link href="/sahip/isletmeler/yeni">
          <PanelActionButton variant="primary" icon={<PlusIcon />}>
            Yeni İşletme Ekle
          </PanelActionButton>
        </Link>
      </div>
    </div>
  );
}

function PlusIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
      <path d="M12 5v14M5 12h14" />
    </svg>
  );
}

function BuildingIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M4 21V5a1 1 0 0 1 1-1h6a1 1 0 0 1 1 1v16" />
      <path d="M14 21V10a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v11" />
      <path d="M9 8h.01M9 12h.01M9 16h.01" />
    </svg>
  );
}

function CheckIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
      <path d="M20 6 9 17l-5-5" />
    </svg>
  );
}

function ClockIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="9" />
      <path d="M12 7v5l3 3" />
    </svg>
  );
}

function PauseIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
      <path d="M8 5v14M16 5v14" />
    </svg>
  );
}

function SearchIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" className={className}>
      <circle cx="11" cy="11" r="7" />
      <path d="m21 21-4.35-4.35" />
    </svg>
  );
}

function StarIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor" className="h-3.5 w-3.5 text-amber-400">
      <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01z" />
    </svg>
  );
}
