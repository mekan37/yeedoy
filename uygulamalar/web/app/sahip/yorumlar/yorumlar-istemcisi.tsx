'use client';

import Link from 'next/link';
import { useMemo, useState } from 'react';
import { clsx } from 'clsx';
import { PieChart, Pie, Cell, ResponsiveContainer } from 'recharts';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { YorumSatiri, type YorumDurumu } from './yorum-satiri';

export type YorumSatiriVerisi = {
  id: string;
  businessId: string;
  businessName: string;
  rating: number;
  content: string | null;
  displayName: string | null;
  avatarUrl: string | null;
  createdAt: string;
  status: YorumDurumu;
  ownerReply: string | null;
  ownerRepliedAt: string | null;
};

interface Stats {
  avgRating: number;
  avgRatingTrend: number | null;
  total: number;
  totalTrend: number;
  approvedCount: number;
  approvedPct: number;
  awaitingReplyCount: number;
  awaitingReplyPct: number;
  rejectedCount: number;
  rejectedPct: number;
}

type Sekme = 'tumu' | 'bekleyen' | 'yanitlanan' | 'reddedilen';
type SortMode = 'yeni' | 'eski' | 'puanYuksek' | 'puanDusuk';

const PAGE_SIZE = 8;
const PUAN_RENKLERI = ['#059669', '#2563eb', '#d97706', '#ea580c', '#dc2626'];

export function YorumlarIstemcisi({
  satirlar,
  stats,
  ratingDagilimi,
  coklu,
}: {
  satirlar: YorumSatiriVerisi[];
  stats: Stats;
  ratingDagilimi: Array<{ star: number; count: number; pct: number }>;
  coklu: boolean;
}) {
  const [sekme, setSekme] = useState<Sekme>('tumu');
  const [arama, setArama] = useState('');
  const [puanFiltre, setPuanFiltre] = useState<'tumu' | number>('tumu');
  const [subeFiltre, setSubeFiltre] = useState<'tumu' | string>('tumu');
  const [sort, setSort] = useState<SortMode>('yeni');
  const [sayfa, setSayfa] = useState(1);

  const subeler = useMemo(() => {
    const map = new Map<string, string>();
    for (const s of satirlar) if (s.businessId) map.set(s.businessId, s.businessName);
    return Array.from(map.entries());
  }, [satirlar]);

  const bekleyenSayisi = stats.awaitingReplyCount;
  const yanitlananSayisi = satirlar.filter((s) => s.ownerReply).length;

  const sekmeSecenekleri: { key: Sekme; label: string; count: number }[] = [
    { key: 'tumu', label: 'Tümü', count: satirlar.length },
    { key: 'bekleyen', label: 'Yanıt Bekleyen', count: bekleyenSayisi },
    { key: 'yanitlanan', label: 'Yanıtlanan', count: yanitlananSayisi },
    { key: 'reddedilen', label: 'Reddedilen', count: stats.rejectedCount },
  ];

  const filtreliListe = useMemo(() => {
    let list = satirlar;
    if (sekme === 'bekleyen') list = list.filter((s) => s.status === 'approved' && !s.ownerReply);
    if (sekme === 'yanitlanan') list = list.filter((s) => Boolean(s.ownerReply));
    if (sekme === 'reddedilen') list = list.filter((s) => s.status === 'rejected');
    if (puanFiltre !== 'tumu') list = list.filter((s) => s.rating === puanFiltre);
    if (subeFiltre !== 'tumu') list = list.filter((s) => s.businessId === subeFiltre);
    const q = arama.trim().toLocaleLowerCase('tr-TR');
    if (q) {
      list = list.filter(
        (s) =>
          (s.content ?? '').toLocaleLowerCase('tr-TR').includes(q) ||
          (s.displayName ?? '').toLocaleLowerCase('tr-TR').includes(q),
      );
    }

    const sorted = [...list];
    if (sort === 'yeni') sorted.sort((a, b) => b.createdAt.localeCompare(a.createdAt));
    else if (sort === 'eski') sorted.sort((a, b) => a.createdAt.localeCompare(b.createdAt));
    else if (sort === 'puanYuksek') sorted.sort((a, b) => b.rating - a.rating);
    else sorted.sort((a, b) => a.rating - b.rating);
    return sorted;
  }, [satirlar, sekme, puanFiltre, subeFiltre, arama, sort]);

  const sayfaSayisi = Math.max(1, Math.ceil(filtreliListe.length / PAGE_SIZE));
  const guvenliSayfa = Math.min(sayfa, sayfaSayisi);
  const sayfadakiListe = filtreliListe.slice((guvenliSayfa - 1) * PAGE_SIZE, guvenliSayfa * PAGE_SIZE);

  function tumYorumlariYanitlaTikla() {
    setSekme('bekleyen');
    setSayfa(1);
    setTimeout(() => document.getElementById('yorum-listesi')?.scrollIntoView({ behavior: 'smooth', block: 'start' }), 50);
  }

  if (satirlar.length === 0) {
    return (
      <div className="flex flex-col gap-6">
        <Baslik />
        <PanelEmptyState
          icon={<StarIcon />}
          title="Henüz yorum yok"
          description="İşletmenize yapılan yorumlar burada görünür."
        />
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-6">
      <Baslik />

      <div className="grid grid-cols-2 gap-3 lg:grid-cols-5">
        <StatKart tone="amber" icon={<StarIcon />} label="Ortalama Puan" value={stats.avgRating.toLocaleString('tr-TR', { minimumFractionDigits: 1, maximumFractionDigits: 1 })} trend={stats.avgRatingTrend} trendSuffix="" />
        <StatKart tone="blue" icon={<ChatIcon />} label="Toplam Yorum" value={String(stats.total)} trend={stats.totalTrend} trendSuffix="% bu ay" />
        <StatKart tone="green" icon={<SmileIcon />} label="Yayınlanan" value={String(stats.approvedCount)} subtitle={`%${stats.approvedPct.toLocaleString('tr-TR')}`} />
        <StatKart tone="orange" icon={<ClockIcon />} label="Yanıt Bekleyen" value={String(stats.awaitingReplyCount)} subtitle={`%${stats.awaitingReplyPct.toLocaleString('tr-TR')}`} />
        <StatKart tone="red" icon={<BanIcon />} label="Reddedilen" value={String(stats.rejectedCount)} subtitle={`%${stats.rejectedPct.toLocaleString('tr-TR')}`} />
      </div>

      <div className="flex flex-col gap-6 lg:flex-row lg:items-start">
        <div className="flex min-w-0 flex-1 flex-col gap-4">
          <div className="flex flex-wrap items-center gap-2">
            <div className="relative min-w-[200px] flex-1">
              <SearchIcon className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted" />
              <input
                value={arama}
                onChange={(e) => { setArama(e.target.value); setSayfa(1); }}
                placeholder="Yorumlarda ara..."
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
                {subeler.map(([id, name]) => (
                  <option key={id} value={id}>{name}</option>
                ))}
              </select>
            )}
            <select
              value={puanFiltre === 'tumu' ? 'tumu' : String(puanFiltre)}
              onChange={(e) => { setPuanFiltre(e.target.value === 'tumu' ? 'tumu' : Number(e.target.value)); setSayfa(1); }}
              className="rounded-xl border border-border bg-bg px-3 py-2 text-sm font-semibold text-textStrong outline-hidden focus:border-primary"
            >
              <option value="tumu">Tüm Puanlar</option>
              {[5, 4, 3, 2, 1].map((n) => (
                <option key={n} value={n}>{n} Yıldız</option>
              ))}
            </select>
          </div>

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
            <select
              value={sort}
              onChange={(e) => setSort(e.target.value as SortMode)}
              className="mb-1 rounded-xl border border-border bg-bg px-3 py-1.5 text-xs font-bold text-textStrong outline-hidden focus:border-primary"
            >
              <option value="yeni">En Yeni</option>
              <option value="eski">En Eski</option>
              <option value="puanYuksek">Puan: Yüksek → Düşük</option>
              <option value="puanDusuk">Puan: Düşük → Yüksek</option>
            </select>
          </div>

          <div id="yorum-listesi" className="overflow-hidden rounded-2xl border border-border bg-card">
            {sayfadakiListe.length === 0 ? (
              <div className="flex flex-col items-center gap-2 py-12 text-center">
                <p className="text-sm font-bold text-textStrong">Bu filtrelerle eşleşen yorum yok</p>
              </div>
            ) : (
              <ul className="divide-y divide-border">
                {sayfadakiListe.map((s) => (
                  <YorumSatiri
                    key={s.id}
                    reviewId={s.id}
                    businessName={s.businessName}
                    showBranchBadge={coklu}
                    rating={s.rating}
                    content={s.content}
                    displayName={s.displayName}
                    avatarUrl={s.avatarUrl}
                    createdAt={s.createdAt}
                    status={s.status}
                    ownerReply={s.ownerReply}
                    ownerRepliedAt={s.ownerRepliedAt}
                  />
                ))}
              </ul>
            )}
          </div>

          {sayfaSayisi > 1 && (
            <div className="flex items-center justify-between text-sm">
              <p className="text-muted">Toplam {filtreliListe.length} yorum</p>
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

          {bekleyenSayisi > 0 && (
            <div
              className="flex flex-col items-center gap-3 rounded-2xl border border-border p-6 text-center sm:flex-row sm:justify-between sm:text-left"
              style={{ background: 'linear-gradient(135deg, rgba(127,29,29,0.06), rgba(220,38,38,0.03))' }}
            >
              <div>
                <p className="font-black text-textStrong">Olumlu yorumlara yanıt vererek müşterilerinize değer verdiğinizi gösterin.</p>
                <p className="text-sm text-muted">Yanıtlanan yorumlar, müşteri memnuniyetini artırır ve işletmenizin güvenilirliğini yükseltir.</p>
              </div>
              <button
                type="button"
                onClick={tumYorumlariYanitlaTikla}
                className="inline-flex shrink-0 items-center gap-2 rounded-xl px-4 py-2.5 text-sm font-extrabold text-white shadow-[0_4px_16px_rgba(127,29,29,0.28)] transition-all hover:-translate-y-px"
                style={{ background: 'linear-gradient(135deg, #7f1d1d, #dc2626)' }}
              >
                Yanıt Bekleyenleri Gör
              </button>
            </div>
          )}
        </div>

        <div className="flex w-full flex-col gap-4 lg:w-80 lg:shrink-0">
          <div className="rounded-2xl border border-border bg-card p-4">
            <h3 className="mb-3 text-sm font-black text-textStrong">Puan Dağılımı</h3>
            <div className="relative mx-auto h-32 w-32">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie data={ratingDagilimi} dataKey="count" nameKey="star" innerRadius={40} outerRadius={58} paddingAngle={2} stroke="none">
                    {ratingDagilimi.map((entry, i) => (
                      <Cell key={entry.star} fill={PUAN_RENKLERI[i % PUAN_RENKLERI.length]} />
                    ))}
                  </Pie>
                </PieChart>
              </ResponsiveContainer>
              <div className="pointer-events-none absolute inset-0 flex flex-col items-center justify-center">
                <span className="text-xl font-black text-textStrong">{stats.total}</span>
                <span className="text-[10px] font-bold text-muted">Toplam</span>
              </div>
            </div>
            <div className="mt-4 flex flex-col gap-1.5">
              {ratingDagilimi.map((item, i) => (
                <div key={item.star} className="flex items-center justify-between gap-2 text-sm">
                  <span className="flex items-center gap-1.5 text-textStrong">
                    <span className="h-2.5 w-2.5 shrink-0 rounded-full" style={{ background: PUAN_RENKLERI[i % PUAN_RENKLERI.length] }} />
                    {item.star} Yıldız
                  </span>
                  <span className="text-xs font-bold text-muted">{item.count} (%{item.pct.toLocaleString('tr-TR')})</span>
                </div>
              ))}
            </div>
          </div>

          <div className="rounded-2xl border border-border bg-card p-4">
            <h3 className="mb-3 text-sm font-black text-textStrong">Hızlı İşlemler</h3>
            <div className="flex flex-col gap-1">
              {bekleyenSayisi > 0 && (
                <button
                  type="button"
                  onClick={tumYorumlariYanitlaTikla}
                  className="flex items-center justify-between gap-2 rounded-xl px-2.5 py-2 text-left transition-colors hover:bg-black/4"
                >
                  <span className="text-xs font-extrabold text-textStrong">Yanıt Bekleyenleri Gör</span>
                  <ChevronRightIcon />
                </button>
              )}
              <Link href="/sahip/analitik" className="flex items-center justify-between gap-2 rounded-xl px-2.5 py-2 transition-colors hover:bg-black/4">
                <span className="text-xs font-extrabold text-textStrong">İstatistikleri Görüntüle</span>
                <ChevronRightIcon />
              </Link>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function Baslik() {
  return (
    <div>
      <h1 className="text-2xl font-black tracking-tight text-textStrong">Yorumlar</h1>
      <p className="mt-1 text-sm text-muted">İşletmenizle ilgili yapılan yorumları görüntüleyin, yanıtlayın ve yönetin.</p>
    </div>
  );
}

function StatKart({
  tone, icon, label, value, subtitle, trend, trendSuffix,
}: {
  tone: 'amber' | 'blue' | 'green' | 'orange' | 'red';
  icon: React.ReactNode;
  label: string;
  value: string;
  subtitle?: string;
  trend?: number | null;
  trendSuffix?: string;
}) {
  const TONE_CLASSES: Record<string, string> = {
    amber: 'bg-amber-50 text-amber-600',
    blue: 'bg-blue-50 text-blue-600',
    green: 'bg-emerald-50 text-emerald-600',
    orange: 'bg-orange-50 text-orange-600',
    red: 'bg-red-50 text-red-600',
  };
  return (
    <div className="rounded-2xl border border-border bg-card p-4 shadow-xs">
      <div className={`mb-2 flex h-9 w-9 items-center justify-center rounded-xl ${TONE_CLASSES[tone]}`}>{icon}</div>
      <p className="text-2xl font-black text-textStrong">{value}</p>
      <p className="text-[11px] font-bold uppercase tracking-wide text-muted">{label}</p>
      {trend !== undefined && trend !== null && (
        <p className={clsx('mt-0.5 text-[11px] font-extrabold', trend >= 0 ? 'text-emerald-600' : 'text-danger')}>
          {trend >= 0 ? '↑' : '↓'} {Math.abs(trend)}{trendSuffix}
        </p>
      )}
      {subtitle && <p className="mt-0.5 text-[11px] text-muted">{subtitle}</p>}
    </div>
  );
}

function SearchIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" className={className}>
      <circle cx="11" cy="11" r="7" /><path d="m21 21-4.35-4.35" />
    </svg>
  );
}
function StarIcon() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" /></svg>;
}
function ChatIcon() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z" /></svg>;
}
function SmileIcon() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10" /><path d="M8 14s1.5 2 4 2 4-2 4-2" /><line x1="9" y1="9" x2="9.01" y2="9" /><line x1="15" y1="9" x2="15.01" y2="9" /></svg>;
}
function ClockIcon() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="9" /><path d="M12 7v5l3 3" /></svg>;
}
function BanIcon() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10" /><line x1="4.9" y1="4.9" x2="19.1" y2="19.1" /></svg>;
}
function ChevronRightIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-muted"><path d="m9 18 6-6-6-6" /></svg>;
}
