'use client';

import Image from 'next/image';
import Link from 'next/link';
import { useMemo, useState } from 'react';
import { clsx } from 'clsx';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';
import {
  MUSTERI_TURU_ETIKETI, filtrelenmisMusteriler, musteriTuruBelirle, toplamEtkilesim, type MusteriTuru,
} from './musteriler-yardimcilari';

export type MusteriOzet = {
  user_id: string;
  display_name: string;
  avatar_url: string | null;
  last_interaction_at: string;
  first_interaction_at: string;
  review_count: number;
  reservation_count: number;
  loyalty_progress: number | null;
  loyalty_reward_threshold: number | null;
  loyalty_event_count: number;
  is_following: boolean;
  is_email_subscribed: boolean;
  tags: { id: string; tag: string }[];
};

type EtkilesimGunu = { tarih: string; etiket: string; ziyaret: number; rezervasyon: number; sadakat: number };

const TONE_CLASSES: Record<MusteriTuru, string> = {
  sadik: 'bg-red-50 text-red-700',
  tekrar: 'bg-blue-50 text-blue-700',
  yeni: 'bg-emerald-50 text-emerald-700',
  tek_seferlik: 'bg-amber-50 text-amber-700',
};
const DONUT_RENKLERI: Record<MusteriTuru, string> = {
  sadik: '#dc2626', tekrar: '#2563eb', yeni: '#059669', tek_seferlik: '#d97706',
};

const PAGE_SIZE = 8;
const GUN_ADLARI = ['Pazar', 'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi'];

export function MusterilerIstemcisi({
  musteriler,
  altBaslik,
  etkilesimSerisi,
  saatDagilimi,
  gunAdiDagilimi,
}: {
  musteriler: MusteriOzet[];
  altBaslik: string;
  etkilesimSerisi: EtkilesimGunu[];
  saatDagilimi: Record<number, number>;
  gunAdiDagilimi: Record<number, number>;
}) {
  const siniflandirilmis = useMemo(
    () => musteriler.map((m) => ({ ...m, tur: musteriTuruBelirle(m), toplam: toplamEtkilesim(m) })),
    [musteriler],
  );

  const [sekme, setSekme] = useState<'tumu' | MusteriTuru>('tumu');
  const [grafikSekme, setGrafikSekme] = useState<'genel' | 'ziyaret' | 'rezervasyon' | 'sadakat'>('genel');
  const [arama, setArama] = useState('');
  const [sayfa, setSayfa] = useState(1);

  const toplamMusteri = siniflandirilmis.length;
  const yeniMusteri = siniflandirilmis.filter((m) => m.tur === 'yeni').length;
  const tekrarEden = siniflandirilmis.filter((m) => m.tur === 'tekrar' || m.tur === 'sadik').length;
  const ortalamaEtkilesim = toplamMusteri > 0
    ? Math.round((siniflandirilmis.reduce((s, m) => s + m.toplam, 0) / toplamMusteri) * 10) / 10
    : 0;

  const donutVerisi = (['sadik', 'tekrar', 'yeni', 'tek_seferlik'] as MusteriTuru[]).map((tur) => ({
    tur, label: MUSTERI_TURU_ETIKETI[tur], count: siniflandirilmis.filter((m) => m.tur === tur).length,
  }));

  const enAktifler = useMemo(
    () => [...siniflandirilmis].sort((a, b) => b.toplam - a.toplam).slice(0, 5),
    [siniflandirilmis],
  );

  const sekmeSecenekleri: { key: 'tumu' | MusteriTuru; label: string; count: number }[] = [
    { key: 'tumu', label: 'Tüm Müşteriler', count: toplamMusteri },
    { key: 'sadik', label: 'Sadık Müşteriler', count: donutVerisi.find((d) => d.tur === 'sadik')?.count ?? 0 },
    { key: 'yeni', label: 'Yeni Müşteriler', count: yeniMusteri },
  ];

  const filtreliListe = useMemo(() => {
    let list = siniflandirilmis;
    if (sekme !== 'tumu') list = list.filter((m) => m.tur === sekme);
    list = filtrelenmisMusteriler(list, arama);
    return [...list].sort((a, b) => b.last_interaction_at.localeCompare(a.last_interaction_at));
  }, [siniflandirilmis, sekme, arama]);

  const sayfaSayisi = Math.max(1, Math.ceil(filtreliListe.length / PAGE_SIZE));
  const guvenliSayfa = Math.min(sayfa, sayfaSayisi);
  const sayfadakiListe = filtreliListe.slice((guvenliSayfa - 1) * PAGE_SIZE, guvenliSayfa * PAGE_SIZE);

  const emailAbone = siniflandirilmis.filter((m) => m.is_email_subscribed).length;

  const enAktifGunIndex = Object.entries(gunAdiDagilimi).sort((a, b) => b[1] - a[1])[0]?.[0];
  const enAktifGun = enAktifGunIndex !== undefined ? GUN_ADLARI[Number(enAktifGunIndex)] : '—';
  const enYogunSaatIndex = Object.entries(saatDagilimi).sort((a, b) => b[1] - a[1])[0]?.[0];
  const enYogunSaat = enYogunSaatIndex !== undefined ? `${enYogunSaatIndex}:00 – ${(Number(enYogunSaatIndex) + 1) % 24}:00` : '—';
  const tekrarEtkilesimOrani = toplamMusteri > 0 ? Math.round((tekrarEden / toplamMusteri) * 1000) / 10 : 0;

  function csvIndir() {
    const basliklar = ['Müşteri', 'Tür', 'Son Etkileşim', 'Toplam Etkileşim', 'Yorum', 'Rezervasyon'];
    const satirlar = filtreliListe.map((m) => [
      m.display_name, MUSTERI_TURU_ETIKETI[m.tur], new Date(m.last_interaction_at).toLocaleDateString('tr-TR'),
      String(m.toplam), String(m.review_count), String(m.reservation_count),
    ]);
    const csv = [basliklar, ...satirlar].map((row) => row.map((v) => `"${String(v).replace(/"/g, '""')}"`).join(',')).join('\n');
    const blob = new Blob([`﻿${csv}`], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'musteriler.csv';
    a.click();
    URL.revokeObjectURL(url);
  }

  const grafikAnahtar = grafikSekme === 'genel' ? null : grafikSekme;
  const grafikVeri = etkilesimSerisi.map((g) => ({
    etiket: g.etiket,
    deger: grafikAnahtar ? g[grafikAnahtar] : g.ziyaret + g.rezervasyon + g.sadakat,
  }));

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <h1 className="text-2xl font-black tracking-tight text-textStrong">Müşteriler</h1>
          <p className="mt-1 text-sm text-muted">{altBaslik}</p>
        </div>
        <div className="flex shrink-0 items-center gap-2">
          <button
            type="button"
            onClick={csvIndir}
            className="inline-flex items-center gap-1.5 rounded-xl border border-border bg-card px-3.5 py-2.5 text-sm font-extrabold text-textStrong hover:bg-black/4"
          >
            <DownloadIcon /> Dışa Aktar
          </button>
          <Link
            href="/sahip/pazarlama/kampanyalar"
            className="inline-flex items-center gap-1.5 rounded-xl px-3.5 py-2.5 text-sm font-extrabold text-white shadow-[0_4px_16px_rgba(127,29,29,0.28)] transition-all hover:-translate-y-px"
            style={{ background: 'linear-gradient(135deg, #7f1d1d, #dc2626)' }}
          >
            <SendIcon /> Kampanya Oluştur
          </Link>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
        <StatKart tone="red" icon={<UsersIcon />} label="Toplam Müşteri" value={String(toplamMusteri)} />
        <StatKart tone="purple" icon={<UserPlusIcon />} label="Yeni Müşteriler" value={String(yeniMusteri)} subtitle="Son 30 gün" />
        <StatKart tone="blue" icon={<RefreshIcon />} label="Tekrar Eden Müşteriler" value={String(tekrarEden)} />
        <StatKart tone="orange" icon={<ActivityIcon />} label="Ortalama Etkileşim" value={ortalamaEtkilesim.toLocaleString('tr-TR')} />
      </div>

      <div className="grid grid-cols-1 gap-4 lg:grid-cols-[minmax(0,1fr)_320px]">
        <div className="rounded-2xl border border-border bg-card p-4">
          <div className="mb-3 flex flex-wrap items-center justify-between gap-2">
            <h3 className="text-sm font-black text-textStrong">Müşteri Etkileşimi</h3>
            <div className="flex gap-1 rounded-xl border border-border bg-bg p-1">
              {([
                { key: 'genel', label: 'Genel Bakış' },
                { key: 'ziyaret', label: 'Ziyaret' },
                { key: 'rezervasyon', label: 'Rezervasyon' },
                { key: 'sadakat', label: 'Sadakat' },
              ] as const).map((t) => (
                <button
                  key={t.key}
                  type="button"
                  onClick={() => setGrafikSekme(t.key)}
                  className={clsx(
                    'rounded-lg px-2.5 py-1 text-xs font-bold transition-colors',
                    grafikSekme === t.key ? 'bg-card text-primary shadow-xs' : 'text-muted hover:text-textStrong',
                  )}
                >
                  {t.label}
                </button>
              ))}
            </div>
          </div>
          <div className="h-[220px] w-full">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={grafikVeri} margin={{ top: 8, right: 8, left: -16, bottom: 0 }}>
                <defs>
                  <linearGradient id="musteriGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="var(--yd-color-primary-strong)" stopOpacity={0.28} />
                    <stop offset="100%" stopColor="var(--yd-color-primary-strong)" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid vertical={false} strokeDasharray="3 3" stroke="var(--yd-color-border)" />
                <XAxis dataKey="etiket" axisLine={false} tickLine={false} tick={{ fontSize: 11, fill: 'var(--yd-color-muted)', fontWeight: 600 }} />
                <YAxis axisLine={false} tickLine={false} width={28} tick={{ fontSize: 11, fill: 'var(--yd-color-muted)', fontWeight: 600 }} />
                <Tooltip content={<GrafikTooltip />} />
                <Area type="monotone" dataKey="deger" stroke="var(--yd-color-primary-strong)" strokeWidth={2.5} fill="url(#musteriGrad)" dot={{ r: 3, fill: 'var(--yd-color-primary-strong)', strokeWidth: 0 }} activeDot={{ r: 5, fill: 'var(--yd-color-primary-strong)', strokeWidth: 0 }} />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-1">
          <div className="rounded-2xl border border-border bg-card p-4">
            <h3 className="mb-3 text-sm font-black text-textStrong">Müşteri Türlerine Göre Dağılım</h3>
            <div className="relative mx-auto h-28 w-28">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie data={donutVerisi} dataKey="count" nameKey="label" innerRadius={34} outerRadius={50} paddingAngle={2} stroke="none">
                    {donutVerisi.map((d) => (<Cell key={d.tur} fill={DONUT_RENKLERI[d.tur]} />))}
                  </Pie>
                </PieChart>
              </ResponsiveContainer>
              <div className="pointer-events-none absolute inset-0 flex flex-col items-center justify-center">
                <span className="text-lg font-black text-textStrong">{toplamMusteri}</span>
                <span className="text-[9px] font-bold text-muted">Toplam</span>
              </div>
            </div>
            <div className="mt-3 flex flex-col gap-1">
              {donutVerisi.map((d) => (
                <div key={d.tur} className="flex items-center justify-between gap-2 text-xs">
                  <span className="flex items-center gap-1.5 text-textStrong">
                    <span className="h-2 w-2 shrink-0 rounded-full" style={{ background: DONUT_RENKLERI[d.tur] }} />
                    {d.label}
                  </span>
                  <span className="font-bold text-muted">{d.count}</span>
                </div>
              ))}
            </div>
          </div>

          <div className="rounded-2xl border border-border bg-card p-4">
            <h3 className="mb-3 text-sm font-black text-textStrong">En Aktif Müşteriler</h3>
            <div className="flex flex-col gap-2.5">
              {enAktifler.map((m, i) => (
                <Link key={m.user_id} href={`/sahip/musteriler/${m.user_id}`} className="flex items-center gap-2.5 rounded-lg transition-colors hover:bg-black/4">
                  <span className="flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-primary/10 text-[10px] font-black text-primary">{i + 1}</span>
                  <MusteriAvatar avatarUrl={m.avatar_url} displayName={m.display_name} boyut={7} />
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-xs font-bold text-textStrong">{m.display_name}</p>
                    <p className="text-[11px] text-muted">{m.toplam} etkileşim</p>
                  </div>
                </Link>
              ))}
            </div>
          </div>
        </div>
      </div>

      <div className="flex flex-col gap-4">
        <div className="flex flex-wrap items-center justify-between gap-2 border-b border-border">
          <div className="flex flex-wrap gap-1">
            {sekmeSecenekleri.map((s) => (
              <button
                key={s.key}
                type="button"
                onClick={() => { setSekme(s.key); setSayfa(1); }}
                className={clsx(
                  'flex items-center gap-1.5 border-b-2 px-3 py-2.5 text-sm font-extrabold transition-colors',
                  sekme === s.key ? 'border-primary text-primary' : 'border-transparent text-muted hover:text-textStrong',
                )}
              >
                {s.label} <span className="text-xs font-semibold text-muted">({s.count})</span>
              </button>
            ))}
          </div>
        </div>

        <div className="relative max-w-sm">
          <SearchIcon className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted" />
          <input
            value={arama}
            onChange={(e) => { setArama(e.target.value); setSayfa(1); }}
            placeholder="Müşteri adı ara..."
            className="w-full rounded-xl border border-border bg-bg py-2 pl-9 pr-3 text-sm text-textStrong outline-hidden focus:border-primary focus:ring-2 focus:ring-primary/20"
          />
        </div>

        <div className="overflow-x-auto rounded-2xl border border-border bg-card">
          <table className="w-full min-w-[760px] border-collapse text-sm">
            <thead>
              <tr className="border-b border-border bg-black/2 text-left text-xs font-extrabold uppercase tracking-wide text-muted">
                <th className="px-4 py-3">Müşteri</th>
                <th className="px-4 py-3">Tür</th>
                <th className="px-4 py-3">Son Etkileşim</th>
                <th className="px-4 py-3 text-right">Toplam Etkileşim</th>
                <th className="px-4 py-3 text-right">İşlem</th>
              </tr>
            </thead>
            <tbody>
              {sayfadakiListe.map((m) => (
                <tr key={m.user_id} className="border-b border-border last:border-0 hover:bg-black/2">
                  <td className="px-4 py-3">
                    <Link href={`/sahip/musteriler/${m.user_id}`} className="flex items-center gap-3">
                      <MusteriAvatar avatarUrl={m.avatar_url} displayName={m.display_name} boyut={9} />
                      <span className="font-bold text-textStrong hover:underline">{m.display_name}</span>
                    </Link>
                  </td>
                  <td className="px-4 py-3">
                    <span className={clsx('rounded-full px-2.5 py-1 text-[11px] font-extrabold', TONE_CLASSES[m.tur])}>{MUSTERI_TURU_ETIKETI[m.tur]}</span>
                  </td>
                  <td className="px-4 py-3 text-xs text-muted">{new Date(m.last_interaction_at).toLocaleDateString('tr-TR')}</td>
                  <td className="px-4 py-3 text-right font-bold text-textStrong">{m.toplam}</td>
                  <td className="px-4 py-3 text-right">
                    <Link href={`/sahip/musteriler/${m.user_id}`} className="rounded-lg border border-border px-3 py-1.5 text-xs font-extrabold text-textStrong hover:bg-black/4">
                      Profili Gör
                    </Link>
                  </td>
                </tr>
              ))}
              {sayfadakiListe.length === 0 && (
                <tr><td colSpan={5} className="px-4 py-10 text-center text-sm text-muted">Bu filtrelerle eşleşen müşteri yok.</td></tr>
              )}
            </tbody>
          </table>
        </div>

        {sayfaSayisi > 1 && (
          <div className="flex items-center justify-between text-sm">
            <p className="text-muted">Toplam {filtreliListe.length} müşteri</p>
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

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div className="rounded-2xl border border-border bg-card p-4">
          <h3 className="mb-3 text-sm font-black text-textStrong">Pazarlama İzinleri</h3>
          <div className="flex items-center justify-between gap-2 rounded-xl border border-border px-3 py-2.5">
            <span className="flex items-center gap-2 text-sm font-bold text-textStrong"><MailIcon /> E-posta Aboneleri</span>
            <span className="text-sm font-black text-textStrong">{emailAbone} <span className="font-bold text-muted">({toplamMusteri > 0 ? Math.round((emailAbone / toplamMusteri) * 100) : 0}%)</span></span>
          </div>
        </div>

        <div className="rounded-2xl border border-border bg-card p-4">
          <h3 className="mb-3 text-sm font-black text-textStrong">Müşteri Davranış Özeti</h3>
          <div className="flex flex-col gap-2 text-sm">
            <DavranisSatiri label="Haftanın en aktif günü" value={enAktifGun} />
            <DavranisSatiri label="En yoğun saat" value={enYogunSaat} />
            <DavranisSatiri label="Tekrar etkileşim oranı" value={`%${tekrarEtkilesimOrani.toLocaleString('tr-TR')}`} />
          </div>
        </div>
      </div>
    </div>
  );
}

function DavranisSatiri({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-center justify-between gap-3 border-b border-border py-1.5 last:border-0">
      <span className="text-xs font-bold text-muted">{label}</span>
      <span className="text-xs font-black text-textStrong">{value}</span>
    </div>
  );
}

function MusteriAvatar({ avatarUrl, displayName, boyut }: { avatarUrl: string | null; displayName: string; boyut: number }) {
  const px = boyut * 4;
  if (avatarUrl) {
    return (
      <span className="relative shrink-0 overflow-hidden rounded-full border border-border" style={{ width: px, height: px }}>
        <Image src={avatarUrl} alt={displayName} fill className="object-cover" sizes={`${px}px`} />
      </span>
    );
  }
  return (
    <span className="flex shrink-0 items-center justify-center rounded-full bg-primary/10 text-[11px] font-black text-primary" style={{ width: px, height: px }}>
      {displayName.charAt(0).toUpperCase()}
    </span>
  );
}

function GrafikTooltip({ active, payload, label }: { active?: boolean; payload?: Array<{ value: number }>; label?: string }) {
  if (!active || !payload?.length) return null;
  return (
    <div className="rounded-xl border border-border bg-card px-3 py-2 text-xs font-bold text-textStrong shadow-yd2">
      <p className="text-muted">{label}</p>
      <p className="mt-0.5 text-sm font-black text-(--yd-color-primary-strong)">{payload[0].value.toLocaleString('tr-TR')} etkileşim</p>
    </div>
  );
}

function StatKart({ tone, icon, label, value, subtitle }: { tone: 'red' | 'purple' | 'blue' | 'orange'; icon: React.ReactNode; label: string; value: string; subtitle?: string }) {
  const TONE_CLASSES2: Record<string, string> = {
    red: 'bg-red-50 text-red-600', purple: 'bg-violet-50 text-violet-600', blue: 'bg-blue-50 text-blue-600', orange: 'bg-orange-50 text-orange-600',
  };
  return (
    <div className="rounded-2xl border border-border bg-card p-4 shadow-xs">
      <div className={`mb-2 flex h-9 w-9 items-center justify-center rounded-xl ${TONE_CLASSES2[tone]}`}>{icon}</div>
      <p className="text-2xl font-black text-textStrong">{value}</p>
      <p className="text-[11px] font-bold uppercase tracking-wide text-muted">{label}</p>
      {subtitle && <p className="mt-0.5 text-[11px] text-muted">{subtitle}</p>}
    </div>
  );
}

function SearchIcon({ className }: { className?: string }) {
  return <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" className={className}><circle cx="11" cy="11" r="7" /><path d="m21 21-4.35-4.35" /></svg>;
}
function DownloadIcon() {
  return <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" /><polyline points="7 10 12 15 17 10" /><line x1="12" y1="15" x2="12" y2="3" /></svg>;
}
function SendIcon() {
  return <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="m22 2-7 20-4-9-9-4Z" /><path d="M22 2 11 13" /></svg>;
}
function UsersIcon() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /><path d="M23 21v-2a4 4 0 0 0-3-3.87" /><path d="M16 3.13a4 4 0 0 1 0 7.75" /></svg>;
}
function UserPlusIcon() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="8.5" cy="7" r="4" /><line x1="20" y1="8" x2="20" y2="14" /><line x1="23" y1="11" x2="17" y2="11" /></svg>;
}
function RefreshIcon() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="23 4 23 10 17 10" /><polyline points="1 20 1 14 7 14" /><path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15" /></svg>;
}
function ActivityIcon() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="22 12 18 12 15 21 9 3 6 12 2 12" /></svg>;
}
function MailIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="5" width="18" height="14" rx="2" /><path d="m3 7 9 6 9-6" /></svg>;
}
