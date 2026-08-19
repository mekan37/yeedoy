'use client';

import Link from 'next/link';
import { useMemo, useState } from 'react';
import { clsx } from 'clsx';
import { PieChart, Pie, Cell, ResponsiveContainer } from 'recharts';

export type FiyatSatiri = {
  menu_item_id: string;
  item_name: string;
  category: string | null;
  business_price_cents: number;
  city_avg_cents: number;
  city_min_cents: number;
  city_max_cents: number;
  district_avg_cents: number;
  city_sample_count: number;
  diff_pct: number;
};

export type RakipIsletme = {
  business_id: string;
  city: string | null;
  district: string | null;
  category: string | null;
  matched_items: number;
};

const PAGE_SIZE = 8;
const DAGILIM_RENKLERI = ['#dc2626', '#059669', '#2563eb'];

function fmtTL(cents: number) {
  return `₺${(cents / 100).toLocaleString('tr-TR', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
}

function durum(pct: number): { text: string; className: string } {
  if (pct > 5) return { text: 'Pahalı', className: 'bg-red-50 text-red-700' };
  if (pct < -5) return { text: 'Düşük', className: 'bg-blue-50 text-blue-700' };
  return { text: 'Rekabetçi', className: 'bg-emerald-50 text-emerald-700' };
}

export function FiyatRaporuIstemcisi({
  businessLabel,
  rows,
  rakipler,
  hasPricedItems,
}: {
  businessLabel: string;
  rows: FiyatSatiri[];
  rakipler: RakipIsletme[];
  hasPricedItems: boolean;
}) {
  const [arama, setArama] = useState('');
  const [kategoriFiltre, setKategoriFiltre] = useState('tumu');
  const [sayfa, setSayfa] = useState(1);

  const kategoriler = useMemo(
    () => Array.from(new Set(rows.map((r) => r.category).filter((c): c is string => Boolean(c)))).sort(),
    [rows],
  );

  const filtreliListe = useMemo(() => {
    let list = rows;
    if (kategoriFiltre !== 'tumu') list = list.filter((r) => r.category === kategoriFiltre);
    const q = arama.trim().toLocaleLowerCase('tr-TR');
    if (q) list = list.filter((r) => r.item_name.toLocaleLowerCase('tr-TR').includes(q));
    return [...list].sort((a, b) => Math.abs(b.diff_pct) - Math.abs(a.diff_pct));
  }, [rows, kategoriFiltre, arama]);

  const sayfaSayisi = Math.max(1, Math.ceil(filtreliListe.length / PAGE_SIZE));
  const guvenliSayfa = Math.min(sayfa, sayfaSayisi);
  const sayfadakiListe = filtreliListe.slice((guvenliSayfa - 1) * PAGE_SIZE, guvenliSayfa * PAGE_SIZE);

  const stats = useMemo(() => {
    const takipEdilen = rows.length;
    const rakipSayisi = rakipler.length;
    const ortalamaFark = rows.length > 0
      ? Math.round((rows.reduce((s, r) => s + Math.abs(r.diff_pct), 0) / rows.length) * 10) / 10
      : 0;
    const dikkatGerektiren = rows.filter((r) => Math.abs(r.diff_pct) > 15).length;
    const enRekabetci = rows.filter((r) => r.city_sample_count > 0).sort((a, b) => a.diff_pct - b.diff_pct)[0] ?? null;
    return { takipEdilen, rakipSayisi, ortalamaFark, dikkatGerektiren, enRekabetci };
  }, [rows, rakipler]);

  const dagilim = useMemo(() => {
    const ustu = rows.filter((r) => r.diff_pct > 5).length;
    const seviyesinde = rows.filter((r) => r.diff_pct >= -5 && r.diff_pct <= 5).length;
    const altinda = rows.filter((r) => r.diff_pct < -5).length;
    return [
      { key: 'ustu', label: 'Piyasa Üstü', count: ustu },
      { key: 'seviyesinde', label: 'Piyasa Seviyesinde', count: seviyesinde },
      { key: 'altinda', label: 'Piyasa Altı', count: altinda },
    ];
  }, [rows]);

  const enCokKarsilastirilan = useMemo(
    () => [...rows].filter((r) => r.city_sample_count > 0).sort((a, b) => b.city_sample_count - a.city_sample_count).slice(0, 5),
    [rows],
  );

  const oneriler = useMemo(() => {
    const list: string[] = [];
    const enPahali = [...rows].sort((a, b) => b.diff_pct - a.diff_pct)[0];
    if (enPahali && enPahali.diff_pct > 10) {
      list.push(`${enPahali.item_name} fiyatınız piyasa ortalamasının %${enPahali.diff_pct.toFixed(0)} üzerinde.`);
    }
    if (stats.enRekabetci && stats.enRekabetci.diff_pct < -10) {
      list.push(`${stats.enRekabetci.item_name} fiyatınız bölgedeki en rekabetçi fiyatlar arasında.`);
    }
    if (rows.length > 0 && rows.length < 10) {
      list.push('Menünüze daha fazla fiyatlı ürün ekleyerek raporu genişletebilirsiniz.');
    }
    return list.slice(0, 3);
  }, [rows, stats.enRekabetci]);

  function csvIndir() {
    const basliklar = ['Ürün', 'Kategori', 'Sizin Fiyatınız', 'Piyasa Ortalaması', 'En Düşük', 'En Yüksek', 'Rakip Sayısı', 'Fark %'];
    const satirlar = filtreliListe.map((r) => [
      r.item_name, r.category ?? '', (r.business_price_cents / 100).toFixed(2), (r.city_avg_cents / 100).toFixed(2),
      (r.city_min_cents / 100).toFixed(2), (r.city_max_cents / 100).toFixed(2), String(r.city_sample_count), r.diff_pct.toFixed(1),
    ]);
    const csv = [basliklar, ...satirlar].map((row) => row.map((v) => `"${String(v).replace(/"/g, '""')}"`).join(',')).join('\n');
    const blob = new Blob([`﻿${csv}`], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'fiyat-raporu.csv';
    a.click();
    URL.revokeObjectURL(url);
  }

  if (rows.length === 0) {
    return (
      <div className="flex flex-col gap-6">
        <Baslik businessLabel={businessLabel} />
        <div className="rounded-2xl border border-dashed border-border px-5 py-10 text-center">
          {hasPricedItems ? (
            <p className="mx-auto max-w-md text-sm text-muted">
              Ürünleriniz için fiyat girdiniz ama bölgenizde henüz yeterli karşılaştırma verisi yok.
              Yakın çevrenizdeki diğer işletmeler menülerini Yeedoy&apos;a ekledikçe bu rapor otomatik olarak güncellenecek.
            </p>
          ) : (
            <>
              <p className="mx-auto max-w-md text-sm text-muted">
                Karşılaştırma yapabilmek için önce menünüze fiyatlı ürünler ekleyip yayınlamanız gerekiyor.
              </p>
              <Link href="/sahip/menu-yonetimi" className="mt-2 inline-block text-xs font-extrabold text-primary hover:underline">
                Menü Yönetimi&apos;ne git →
              </Link>
            </>
          )}
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-6">
      <Baslik businessLabel={businessLabel} />

      <div className="grid grid-cols-2 gap-3 lg:grid-cols-5">
        <StatKart tone="blue" icon={<ListIcon />} label="Takip Edilen Ürün" value={String(stats.takipEdilen)} />
        <StatKart tone="green" icon={<UsersIcon />} label="Rakip İşletme" value={String(stats.rakipSayisi)} />
        <StatKart tone="purple" icon={<PercentIcon />} label="Ortalama Fiyat Farkı" value={`%${stats.ortalamaFark.toLocaleString('tr-TR')}`} />
        <StatKart tone="orange" icon={<AlertIcon />} label="Dikkat Gerektiren" value={String(stats.dikkatGerektiren)} />
        <StatKart tone="red" icon={<TrophyIcon />} label="En Rekabetçi Ürün" value={stats.enRekabetci?.item_name ?? '—'} subtitle={stats.enRekabetci ? `%${Math.abs(stats.enRekabetci.diff_pct).toLocaleString('tr-TR')} fiyat farkı` : undefined} />
      </div>

      <div className="flex flex-col gap-6 lg:flex-row lg:items-start">
        <div className="flex min-w-0 flex-1 flex-col gap-4">
          <div className="flex flex-wrap items-center gap-2">
            <div className="relative min-w-[200px] flex-1">
              <SearchIcon className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted" />
              <input
                value={arama}
                onChange={(e) => { setArama(e.target.value); setSayfa(1); }}
                placeholder="Ürün ara..."
                className="w-full rounded-xl border border-border bg-bg py-2 pl-9 pr-3 text-sm text-textStrong outline-hidden focus:border-primary focus:ring-2 focus:ring-primary/20"
              />
            </div>
            {kategoriler.length > 0 && (
              <select
                value={kategoriFiltre}
                onChange={(e) => { setKategoriFiltre(e.target.value); setSayfa(1); }}
                className="rounded-xl border border-border bg-bg px-3 py-2 text-sm font-semibold text-textStrong outline-hidden focus:border-primary"
              >
                <option value="tumu">Tüm Kategoriler</option>
                {kategoriler.map((k) => (
                  <option key={k} value={k}>{k}</option>
                ))}
              </select>
            )}
            <button
              type="button"
              onClick={csvIndir}
              className="inline-flex items-center gap-1.5 rounded-xl border border-primary/30 px-3 py-2 text-sm font-extrabold text-primary hover:bg-primary/5"
            >
              <DownloadIcon /> Raporu Dışa Aktar
            </button>
          </div>

          <div>
            <h2 className="mb-3 text-sm font-black text-textStrong">Ürün Bazlı Fiyat Karşılaştırması</h2>
            <div className="overflow-x-auto rounded-2xl border border-border bg-card">
              <table className="w-full min-w-[820px] border-collapse text-sm">
                <thead>
                  <tr className="border-b border-border bg-black/2 text-left text-xs font-extrabold uppercase tracking-wide text-muted">
                    <th className="px-4 py-3">Ürün</th>
                    <th className="px-4 py-3 text-right">Sizin Fiyatınız</th>
                    <th className="px-4 py-3 text-right">Piyasa Ort.</th>
                    <th className="px-4 py-3 text-right">En Düşük</th>
                    <th className="px-4 py-3 text-right">En Yüksek</th>
                    <th className="px-4 py-3 text-right">Rakip Sayısı</th>
                    <th className="px-4 py-3 text-right">Fark</th>
                    <th className="px-4 py-3 text-center">Durum</th>
                  </tr>
                </thead>
                <tbody>
                  {sayfadakiListe.map((r) => {
                    const d = durum(r.diff_pct);
                    return (
                      <tr key={r.menu_item_id} className="border-b border-border last:border-0 hover:bg-black/2">
                        <td className="px-4 py-3">
                          <p className="font-bold text-textStrong">{r.item_name}</p>
                          {r.category && <p className="text-xs text-muted">{r.category}</p>}
                        </td>
                        <td className="px-4 py-3 text-right font-black text-textStrong">{fmtTL(r.business_price_cents)}</td>
                        <td className="px-4 py-3 text-right text-muted">{r.city_avg_cents > 0 ? fmtTL(r.city_avg_cents) : '—'}</td>
                        <td className="px-4 py-3 text-right text-muted">{r.city_min_cents > 0 ? fmtTL(r.city_min_cents) : '—'}</td>
                        <td className="px-4 py-3 text-right text-muted">{r.city_max_cents > 0 ? fmtTL(r.city_max_cents) : '—'}</td>
                        <td className="px-4 py-3 text-right text-muted">{r.city_sample_count}</td>
                        <td className={clsx('px-4 py-3 text-right font-extrabold', r.diff_pct > 0 ? 'text-red-600' : r.diff_pct < 0 ? 'text-blue-600' : 'text-muted')}>
                          {r.diff_pct > 0 ? '+' : ''}{r.diff_pct.toLocaleString('tr-TR')}%
                        </td>
                        <td className="px-4 py-3 text-center">
                          <span className={clsx('inline-flex rounded-full px-2.5 py-0.5 text-[11px] font-extrabold', d.className)}>{d.text}</span>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>

            {sayfaSayisi > 1 && (
              <div className="mt-3 flex items-center justify-between text-sm">
                <p className="text-muted">{(guvenliSayfa - 1) * PAGE_SIZE + 1}-{Math.min(guvenliSayfa * PAGE_SIZE, filtreliListe.length)} / {filtreliListe.length} ürün gösteriliyor</p>
                <div className="flex items-center gap-1.5">
                  <button type="button" disabled={guvenliSayfa === 1} onClick={() => setSayfa((p) => Math.max(1, p - 1))} className="rounded-lg border border-border px-3 py-1.5 font-semibold text-textStrong disabled:cursor-not-allowed disabled:opacity-40 hover:bg-black/4">Önceki</button>
                  {Array.from({ length: sayfaSayisi }, (_, i) => i + 1).map((n) => (
                    <button key={n} type="button" onClick={() => setSayfa(n)} className={clsx('h-8 w-8 rounded-lg font-bold', n === guvenliSayfa ? 'text-white' : 'border border-border text-textStrong hover:bg-black/4')} style={n === guvenliSayfa ? { background: 'linear-gradient(135deg, #7f1d1d, #dc2626)' } : undefined}>{n}</button>
                  ))}
                  <button type="button" disabled={guvenliSayfa === sayfaSayisi} onClick={() => setSayfa((p) => Math.min(sayfaSayisi, p + 1))} className="rounded-lg border border-border px-3 py-1.5 font-semibold text-textStrong disabled:cursor-not-allowed disabled:opacity-40 hover:bg-black/4">Sonraki</button>
                </div>
              </div>
            )}
          </div>

          {rakipler.length > 0 && (
            <div>
              <h2 className="mb-3 text-sm font-black text-textStrong">Karşılaştırılan İşletmeler</h2>
              <div className="overflow-x-auto rounded-2xl border border-border bg-card">
                <table className="w-full min-w-[480px] border-collapse text-sm">
                  <thead>
                    <tr className="border-b border-border bg-black/2 text-left text-xs font-extrabold uppercase tracking-wide text-muted">
                      <th className="px-4 py-2.5">İşletme</th>
                      <th className="px-4 py-2.5">Konum</th>
                      <th className="px-4 py-2.5">Kategori</th>
                      <th className="px-4 py-2.5 text-right">Eşleşen Ürün</th>
                    </tr>
                  </thead>
                  <tbody>
                    {rakipler.slice(0, 6).map((r, i) => (
                      <tr key={r.business_id} className="border-b border-border last:border-0">
                        <td className="px-4 py-2.5 font-bold text-textStrong">Rakip {String.fromCharCode(65 + i)}</td>
                        <td className="px-4 py-2.5 text-muted">{r.district ?? r.city ?? '—'}</td>
                        <td className="px-4 py-2.5 text-muted">{r.category ?? '—'}</td>
                        <td className="px-4 py-2.5 text-right font-bold text-textStrong">{r.matched_items}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          <div
            className="flex flex-col items-center gap-3 rounded-2xl border border-border p-6 text-center sm:flex-row sm:justify-between sm:text-left"
            style={{ background: 'linear-gradient(135deg, rgba(127,29,29,0.06), rgba(220,38,38,0.03))' }}
          >
            <div>
              <p className="font-black text-textStrong">Doğru fiyatlama daha fazla sipariş ve daha iyi kârlılık sağlar.</p>
              <p className="text-sm text-muted">Rakiplerinizi takip ederek fiyatlarınızı optimize edin, müşteri memnuniyetinizi artırın.</p>
            </div>
            <Link
              href="/sahip/destek"
              className="inline-flex shrink-0 items-center gap-2 rounded-xl px-4 py-2.5 text-sm font-extrabold text-white shadow-[0_4px_16px_rgba(127,29,29,0.28)] transition-all hover:-translate-y-px"
              style={{ background: 'linear-gradient(135deg, #7f1d1d, #dc2626)' }}
            >
              Yardım Al →
            </Link>
          </div>
        </div>

        <div className="flex w-full flex-col gap-4 lg:w-80 lg:shrink-0">
          <div className="rounded-2xl border border-border bg-card p-4">
            <h3 className="mb-3 text-sm font-black text-textStrong">Fiyat Dağılımı</h3>
            <div className="relative mx-auto h-32 w-32">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie data={dagilim} dataKey="count" nameKey="label" innerRadius={40} outerRadius={58} paddingAngle={2} stroke="none">
                    {dagilim.map((entry, i) => (
                      <Cell key={entry.key} fill={DAGILIM_RENKLERI[i % DAGILIM_RENKLERI.length]} />
                    ))}
                  </Pie>
                </PieChart>
              </ResponsiveContainer>
              <div className="pointer-events-none absolute inset-0 flex flex-col items-center justify-center">
                <span className="text-xl font-black text-textStrong">{rows.length}</span>
                <span className="text-[10px] font-bold text-muted">Ürün</span>
              </div>
            </div>
            <div className="mt-4 flex flex-col gap-1.5">
              {dagilim.map((item, i) => (
                <div key={item.key} className="flex items-center justify-between gap-2 text-sm">
                  <span className="flex items-center gap-1.5 text-textStrong">
                    <span className="h-2.5 w-2.5 shrink-0 rounded-full" style={{ background: DAGILIM_RENKLERI[i % DAGILIM_RENKLERI.length] }} />
                    {item.label}
                  </span>
                  <span className="text-xs font-bold text-muted">{item.count}</span>
                </div>
              ))}
            </div>
          </div>

          {enCokKarsilastirilan.length > 0 && (
            <div className="rounded-2xl border border-border bg-card p-4">
              <h3 className="mb-3 text-sm font-black text-textStrong">En Çok Karşılaştırılan Ürünler</h3>
              <div className="flex flex-col gap-2.5">
                {enCokKarsilastirilan.map((r) => (
                  <div key={r.menu_item_id} className="flex items-center justify-between gap-2">
                    <div className="min-w-0">
                      <p className="truncate text-xs font-bold text-textStrong">{r.item_name}</p>
                      <p className="text-[11px] text-muted">{r.city_sample_count} rakip · %{r.diff_pct > 0 ? '+' : ''}{r.diff_pct.toLocaleString('tr-TR')}</p>
                    </div>
                    <span className="shrink-0 text-xs font-black text-textStrong">{fmtTL(r.business_price_cents)}</span>
                  </div>
                ))}
              </div>
            </div>
          )}

          {oneriler.length > 0 && (
            <div className="rounded-2xl border border-border bg-card p-4">
              <h3 className="mb-3 text-sm font-black text-textStrong">Öneriler</h3>
              <div className="flex flex-col gap-2.5">
                {oneriler.map((o, i) => (
                  <p key={i} className="flex items-start gap-2 text-xs leading-relaxed text-muted">
                    <span className="mt-0.5 shrink-0 text-primary"><BulbIcon /></span>
                    {o}
                  </p>
                ))}
              </div>
            </div>
          )}

          <div className="rounded-2xl border border-border bg-card p-4">
            <h3 className="mb-3 text-sm font-black text-textStrong">Hızlı İşlemler</h3>
            <div className="flex flex-col gap-1">
              <button type="button" onClick={csvIndir} className="flex items-center justify-between gap-2 rounded-xl px-2.5 py-2 text-left transition-colors hover:bg-black/4">
                <span className="text-xs font-extrabold text-textStrong">CSV İndir</span>
                <DownloadIcon />
              </button>
              <Link href="/sahip/menu-yonetimi" className="flex items-center justify-between gap-2 rounded-xl px-2.5 py-2 transition-colors hover:bg-black/4">
                <span className="text-xs font-extrabold text-textStrong">Menü Yönetimine Git</span>
                <ChevronRightIcon />
              </Link>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function Baslik({ businessLabel }: { businessLabel: string }) {
  return (
    <div>
      <h1 className="text-2xl font-black tracking-tight text-textStrong">Fiyat Raporu</h1>
      <p className="mt-1 text-sm text-muted">{businessLabel} — menünüzdeki ürünleri diğer işletmelerin benzer ürün fiyatlarıyla karşılaştırın.</p>
    </div>
  );
}

function StatKart({ tone, icon, label, value, subtitle }: { tone: 'blue' | 'green' | 'purple' | 'orange' | 'red'; icon: React.ReactNode; label: string; value: string; subtitle?: string }) {
  const TONE_CLASSES: Record<string, string> = {
    blue: 'bg-blue-50 text-blue-600',
    green: 'bg-emerald-50 text-emerald-600',
    purple: 'bg-violet-50 text-violet-600',
    orange: 'bg-orange-50 text-orange-600',
    red: 'bg-red-50 text-red-600',
  };
  return (
    <div className="rounded-2xl border border-border bg-card p-4 shadow-xs">
      <div className={`mb-2 flex h-9 w-9 items-center justify-center rounded-xl ${TONE_CLASSES[tone]}`}>{icon}</div>
      <p className="truncate text-lg font-black text-textStrong" title={value}>{value}</p>
      <p className="text-[11px] font-bold uppercase tracking-wide text-muted">{label}</p>
      {subtitle && <p className="mt-0.5 truncate text-[11px] text-muted">{subtitle}</p>}
    </div>
  );
}

function SearchIcon({ className }: { className?: string }) {
  return <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" className={className}><circle cx="11" cy="11" r="7" /><path d="m21 21-4.35-4.35" /></svg>;
}
function ListIcon() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="8" y1="6" x2="21" y2="6" /><line x1="8" y1="12" x2="21" y2="12" /><line x1="8" y1="18" x2="21" y2="18" /><line x1="3" y1="6" x2="3.01" y2="6" /><line x1="3" y1="12" x2="3.01" y2="12" /><line x1="3" y1="18" x2="3.01" y2="18" /></svg>;
}
function UsersIcon() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /><path d="M23 21v-2a4 4 0 0 0-3-3.87" /><path d="M16 3.13a4 4 0 0 1 0 7.75" /></svg>;
}
function PercentIcon() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="19" y1="5" x2="5" y2="19" /><circle cx="6.5" cy="6.5" r="2.5" /><circle cx="17.5" cy="17.5" r="2.5" /></svg>;
}
function AlertIcon() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z" /><line x1="12" y1="9" x2="12" y2="13" /><line x1="12" y1="17" x2="12.01" y2="17" /></svg>;
}
function TrophyIcon() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M8 21h8M12 17v4M7 4h10v5a5 5 0 0 1-10 0V4z" /><path d="M17 5h3a2 2 0 0 1 2 2 4 4 0 0 1-4 4M7 5H4a2 2 0 0 0-2 2 4 4 0 0 0 4 4" /></svg>;
}
function DownloadIcon() {
  return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" /><polyline points="7 10 12 15 17 10" /><line x1="12" y1="15" x2="12" y2="3" /></svg>;
}
function ChevronRightIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-muted"><path d="m9 18 6-6-6-6" /></svg>;
}
function BulbIcon() {
  return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M9 18h6M10 22h4M12 2a6 6 0 0 0-4 10.5c.5.5.8 1 1 1.5.2.5.2 1 .2 1.5V16h5.6v-1c0-.5 0-1 .2-1.5.2-.5.5-1 1-1.5A6 6 0 0 0 12 2Z" /></svg>;
}
