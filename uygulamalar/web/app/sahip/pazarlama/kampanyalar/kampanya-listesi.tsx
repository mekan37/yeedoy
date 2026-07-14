'use client';

import { useState, useTransition } from 'react';
import { KampanyaFormu } from './kampanya-formu';
import type { Kampanya, KampanyaTuru, KampanyaDurumu } from './kampanya-formu';
import { silKampanya } from './kampanya-eylemleri';

// ── Types ──────────────────────────────────────────────────────────────────

interface Stats {
  total_campaigns: number;
  active_campaigns: number;
  total_views: number;
  total_clicks: number;
  period_views: number;
  period_clicks: number;
}

interface Props {
  businessId: string;
  initialCampaigns: Kampanya[];
  initialTotal: number;
  stats: Stats;
}

// ── Constants ──────────────────────────────────────────────────────────────

const TYPE_LABELS: Record<KampanyaTuru, string> = {
  discount: 'İndirim', special_offer: 'Özel Teklif',
  loyalty: 'Sadakat', announcement: 'Duyuru',
};
const TYPE_COLORS: Record<KampanyaTuru, string> = {
  discount:      'bg-red-50 text-red-700',
  special_offer: 'bg-green-50 text-green-700',
  loyalty:       'bg-purple-50 text-purple-700',
  announcement:  'bg-amber-50 text-amber-700',
};
const STATUS_LABELS: Record<KampanyaDurumu, string> = {
  draft: 'Taslak', planned: 'Planlanan', active: 'Aktif', completed: 'Tamamlandı',
};
const STATUS_COLORS: Record<KampanyaDurumu, string> = {
  draft:     'bg-zinc-100 text-zinc-600',
  planned:   'bg-blue-50 text-blue-700',
  active:    'bg-green-50 text-green-700',
  completed: 'bg-zinc-100 text-zinc-500',
};
const TABS: { key: KampanyaDurumu | 'all'; label: string }[] = [
  { key: 'all',       label: 'Tümü'       },
  { key: 'active',    label: 'Aktif'      },
  { key: 'planned',   label: 'Planlanan'  },
  { key: 'completed', label: 'Tamamlanan' },
  { key: 'draft',     label: 'Taslak'     },
];
const TYPE_INFO = [
  { type: 'discount',      label: 'İndirim',     desc: 'Belirli ürün veya menülerde indirim sunun.',      icon: <TagIcon /> },
  { type: 'special_offer', label: 'Özel Teklif', desc: '2 al 1 öde, menü paketi gibi teklifler.',         icon: <GiftIcon /> },
  { type: 'loyalty',       label: 'Sadakat',     desc: 'Sadakat programları ve ödüller sunun.',            icon: <HeartIcon /> },
  { type: 'announcement',  label: 'Duyuru',      desc: 'Yeni ürün, etkinlik veya özel gün duyuruları.',   icon: <BellIcon /> },
];

// ── Component ──────────────────────────────────────────────────────────────

export function KampanyaListesi({ businessId, initialCampaigns, initialTotal, stats }: Props) {
  const [campaigns, setCampaigns] = useState<Kampanya[]>(initialCampaigns);
  const [total] = useState(initialTotal);
  const [activeTab, setActiveTab] = useState<KampanyaDurumu | 'all'>('all');
  const [search, setSearch] = useState('');
  const [formOpen, setFormOpen] = useState(false);
  const [editing, setEditing] = useState<Kampanya | null>(null);
  const [menuOpenId, setMenuOpenId] = useState<string | null>(null);
  const [, startTransition] = useTransition();

  // Client-side filter (full list loaded server-side up to 100)
  const visible = campaigns.filter((c) => {
    if (activeTab !== 'all' && c.status !== activeTab) return false;
    if (search && !c.title.toLowerCase().includes(search.toLowerCase())) return false;
    return true;
  });

  const tabCounts = TABS.reduce<Record<string, number>>((acc, tab) => {
    acc[tab.key] = tab.key === 'all'
      ? campaigns.length
      : campaigns.filter((c) => c.status === tab.key).length;
    return acc;
  }, {});

  function handleDelete(id: string) {
    if (!confirm('Bu kampanyayı silmek istediğinizden emin misiniz?')) return;
    startTransition(async () => {
      await silKampanya(id, businessId);
      setCampaigns((prev) => prev.filter((c) => c.id !== id));
    });
  }

  function openEdit(c: Kampanya) {
    setEditing(c);
    setFormOpen(true);
    setMenuOpenId(null);
  }

  function closeForm() {
    setFormOpen(false);
    setEditing(null);
  }

  return (
    <>
      {/* ── Toolbar ───────────────────────────────────────────────────── */}
      <div className="flex justify-end">
        <button
          onClick={() => { setEditing(null); setFormOpen(true); }}
          className="flex items-center gap-2 rounded-xl bg-primary px-5 py-2.5 text-sm font-[800] text-white shadow-sm transition hover:opacity-90"
        >
          <PlusIcon /> Yeni Kampanya Oluştur
        </button>
      </div>

      {/* ── Stats header ──────────────────────────────────────────────── */}
      <div className="grid grid-cols-2 gap-3 md:grid-cols-4">
        <StatCard icon={<CampaignIcon />} label="Toplam Kampanya"  value={stats.total_campaigns}  sub="Tüm zamanlar"    color="text-primary" />
        <StatCard icon={<CheckIcon />}    label="Aktif Kampanya"   value={stats.active_campaigns}  sub="Şu anda yayında" color="text-green-600" />
        <StatCard icon={<EyeIcon />}      label="Toplam Görüntüleme" value={stats.total_views.toLocaleString('tr-TR')} sub={`Son 7 gün: ${stats.period_views.toLocaleString('tr-TR')}`} color="text-amber-600" />
        <StatCard icon={<ClickIcon />}    label="Toplam Tıklama"   value={stats.total_clicks.toLocaleString('tr-TR')} sub={`Son 7 gün: ${stats.period_clicks.toLocaleString('tr-TR')}`} color="text-blue-600" />
      </div>

      {/* ── Main + sidebar ────────────────────────────────────────────── */}
      <div className="flex gap-5">

        {/* ── Left: list ────────────────────────────────────────────── */}
        <div className="min-w-0 flex-1">

          {/* Tabs */}
          <div className="mb-4 flex gap-1 border-b border-border">
            {TABS.map((tab) => (
              <button
                key={tab.key}
                onClick={() => setActiveTab(tab.key)}
                className={[
                  'flex items-center gap-1.5 border-b-2 px-4 py-2.5 text-sm font-[800] transition-colors',
                  activeTab === tab.key
                    ? 'border-primary text-primary'
                    : 'border-transparent text-muted hover:text-textStrong',
                ].join(' ')}
              >
                {tab.label}
                <span className={[
                  'rounded-full px-1.5 py-0.5 text-[11px] font-[700]',
                  activeTab === tab.key ? 'bg-primary/10 text-primary' : 'bg-bg text-muted',
                ].join(' ')}>
                  {tabCounts[tab.key] ?? 0}
                </span>
              </button>
            ))}
          </div>

          {/* Search bar */}
          <div className="mb-4 flex items-center gap-3">
            <div className="relative flex-1">
              <SearchIcon className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" />
              <input
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Kampanya adı ara..."
                className="w-full rounded-xl border border-border bg-bg py-2 pl-9 pr-4 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/20"
              />
            </div>
          </div>

          {/* Table */}
          {visible.length === 0 ? (
            <div className="flex flex-col items-center justify-center rounded-2xl border border-dashed border-border py-16 text-center">
              <p className="text-sm font-[700] text-textStrong">Kampanya bulunamadı</p>
              <p className="mt-1 text-xs text-muted">Yeni bir kampanya oluşturmak için yukarıdaki butonu kullanın.</p>
            </div>
          ) : (
            <div className="rounded-2xl border border-border bg-card overflow-hidden">
              {/* Table header */}
              <div className="grid grid-cols-[1fr_100px_130px_90px_110px_40px] border-b border-border px-4 py-2.5">
                {['Kampanya', 'Tür', 'Süre', 'Durum', 'Performans', ''].map((h, i) => (
                  <span key={i} className="text-[11px] font-[800] uppercase tracking-wide text-muted">{h}</span>
                ))}
              </div>

              {/* Rows */}
              {visible.map((c) => (
                <div key={c.id} className="grid grid-cols-[1fr_100px_130px_90px_110px_40px] items-center border-b border-border px-4 py-3 last:border-b-0 hover:bg-bg/50 transition-colors">
                  {/* Name */}
                  <div className="min-w-0 pr-3">
                    <div className="flex items-center gap-2">
                      {c.discount_percent && (
                        <span className="shrink-0 rounded-md bg-primary px-1.5 py-0.5 text-[10px] font-[900] text-white">
                          %{c.discount_percent}
                        </span>
                      )}
                      <p className="truncate text-sm font-[800] text-textStrong">{c.title}</p>
                    </div>
                    {c.description && (
                      <p className="mt-0.5 truncate text-xs text-muted">{c.description}</p>
                    )}
                  </div>
                  {/* Type */}
                  <span className={`w-fit rounded-full px-2.5 py-1 text-[11px] font-[800] ${TYPE_COLORS[c.type]}`}>
                    {TYPE_LABELS[c.type]}
                  </span>
                  {/* Date range */}
                  <div className="text-xs text-muted">
                    {c.starts_at ? (
                      <>
                        <div>{fmtDate(c.starts_at)}</div>
                        {c.ends_at && <div>– {fmtDate(c.ends_at)}</div>}
                      </>
                    ) : <span>—</span>}
                  </div>
                  {/* Status */}
                  <span className={`w-fit rounded-full px-2.5 py-1 text-[11px] font-[800] ${STATUS_COLORS[c.status]}`}>
                    {STATUS_LABELS[c.status]}
                  </span>
                  {/* Performance */}
                  <div className="text-xs text-muted">
                    <div className="flex items-center gap-1"><EyeIcon size={11} />{c.view_count.toLocaleString('tr-TR')}</div>
                    <div className="flex items-center gap-1 mt-0.5"><ClickIcon size={11} />{c.click_count.toLocaleString('tr-TR')}</div>
                  </div>
                  {/* Actions menu */}
                  <div className="relative flex justify-end">
                    <button
                      onClick={() => setMenuOpenId(menuOpenId === c.id ? null : c.id)}
                      className="flex h-7 w-7 items-center justify-center rounded-lg text-muted hover:bg-bg hover:text-textStrong transition"
                    >
                      <DotsIcon />
                    </button>
                    {menuOpenId === c.id && (
                      <div className="absolute right-0 top-8 z-20 w-36 rounded-xl border border-border bg-card shadow-yd2">
                        <button onClick={() => openEdit(c)}
                          className="flex w-full items-center gap-2 px-3 py-2 text-sm text-textStrong hover:bg-bg transition">
                          <EditIcon /> Düzenle
                        </button>
                        <button onClick={() => handleDelete(c.id)}
                          className="flex w-full items-center gap-2 px-3 py-2 text-sm text-danger hover:bg-red-50 transition">
                          <TrashIcon /> Sil
                        </button>
                      </div>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}

          <p className="mt-3 text-xs text-muted">Toplam {total} kampanya</p>
        </div>

        {/* ── Right sidebar ─────────────────────────────────────────── */}
        <div className="hidden w-64 shrink-0 space-y-4 xl:block">

          {/* Performans özeti */}
          <div className="rounded-2xl border border-border bg-card p-5">
            <h3 className="mb-3 text-sm font-[900] text-textStrong">Kampanya Performans Özeti</h3>
            <p className="mb-3 text-[11px] font-[700] uppercase tracking-wide text-muted">Son 7 Gün</p>
            <div className="space-y-2.5">
              <PerfRow icon={<EyeIcon size={13} />}   label="Görüntüleme"   value={stats.period_views.toLocaleString('tr-TR')}  />
              <PerfRow icon={<ClickIcon size={13} />}  label="Tıklama"       value={stats.period_clicks.toLocaleString('tr-TR')} />
              {stats.period_views > 0 && (
                <PerfRow
                  icon={<RatioIcon />}
                  label="Tıklama Oranı"
                  value={`%${((stats.period_clicks / stats.period_views) * 100).toFixed(1)}`}
                />
              )}
            </div>
          </div>

          {/* Kampanya tipleri */}
          <div className="rounded-2xl border border-border bg-card p-5">
            <h3 className="mb-3 text-sm font-[900] text-textStrong">Kampanya Türleri</h3>
            <div className="space-y-3">
              {TYPE_INFO.map((t) => (
                <div key={t.type} className="flex gap-2.5">
                  <span className="mt-0.5 shrink-0 text-primary">{t.icon}</span>
                  <div>
                    <p className="text-xs font-[800] text-textStrong">{t.label}</p>
                    <p className="text-[11px] text-muted">{t.desc}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* İpucu */}
          <div className="rounded-2xl border border-amber-200 bg-amber-50 p-4">
            <p className="text-[11px] font-[800] text-amber-700">💡 İpucu</p>
            <p className="mt-1 text-[11px] text-amber-700/80 leading-relaxed">
              Kampanyalarınızın daha fazla kişiye ulaşması için sosyal medya hesaplarınızda paylaşın!
            </p>
          </div>
        </div>
      </div>

      {/* ── Form modal ────────────────────────────────────────────────── */}
      {formOpen && (
        <KampanyaFormu
          businessId={businessId}
          campaign={editing}
          onClose={closeForm}
        />
      )}

      {/* Close menu on outside click */}
      {menuOpenId && (
        <div className="fixed inset-0 z-10" onClick={() => setMenuOpenId(null)} />
      )}
    </>
  );
}

// ── Sub-components ─────────────────────────────────────────────────────────

function StatCard({ icon, label, value, sub, color }: {
  icon: React.ReactNode; label: string; value: string | number; sub: string; color: string;
}) {
  return (
    <div className="rounded-2xl border border-border bg-card p-4">
      <div className="mb-2 flex items-center gap-2">
        <span className={`${color}`}>{icon}</span>
        <p className="text-xs font-[700] text-muted">{label}</p>
      </div>
      <p className={`text-2xl font-[900] ${color}`}>{value}</p>
      <p className="mt-1 text-[11px] text-muted">{sub}</p>
    </div>
  );
}

function PerfRow({ icon, label, value }: { icon: React.ReactNode; label: string; value: string }) {
  return (
    <div className="flex items-center justify-between text-sm">
      <span className="flex items-center gap-1.5 text-muted">
        {icon}{label}
      </span>
      <span className="font-[800] text-textStrong">{value}</span>
    </div>
  );
}

function fmtDate(iso: string) {
  return new Date(iso).toLocaleDateString('tr-TR', { day: 'numeric', month: 'short', year: 'numeric' });
}

// ── Icons ──────────────────────────────────────────────────────────────────

function CampaignIcon() { return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M22 12h-4l-3 9L9 3l-3 9H2"/></svg>; }
function CheckIcon()    { return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>; }
function EyeIcon({ size = 16 }: { size?: number }) { return <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>; }
function ClickIcon({ size = 16 }: { size?: number }) { return <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M9 9l11 11"/><path d="M9 2v7h7"/><path d="M17.8 14.5L22 18.7a1 1 0 0 1 0 1.4l-1.9 1.9a1 1 0 0 1-1.4 0L14.5 17.8"/></svg>; }
function RatioIcon()    { return <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10"/><path d="M8 12h8M12 8v8"/></svg>; }
function SearchIcon({ className = '' }: { className?: string }) { return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className={className}><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>; }
function DotsIcon()     { return <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><circle cx="12" cy="5" r="1.5"/><circle cx="12" cy="12" r="1.5"/><circle cx="12" cy="19" r="1.5"/></svg>; }
function EditIcon()     { return <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4z"/></svg>; }
function TrashIcon()    { return <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/><path d="M10 11v6M14 11v6"/><path d="M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2"/></svg>; }
function PlusIcon()     { return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>; }
function TagIcon()      { return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M20.59 13.41l-7.17 7.17a2 2 0 0 1-2.83 0L2 12V2h10l8.59 8.59a2 2 0 0 1 0 2.82z"/><line x1="7" y1="7" x2="7.01" y2="7"/></svg>; }
function GiftIcon()     { return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 12 20 22 4 22 4 12"/><rect x="2" y="7" width="20" height="5"/><line x1="12" y1="22" x2="12" y2="7"/><path d="M12 7H7.5a2.5 2.5 0 0 1 0-5C11 2 12 7 12 7z"/><path d="M12 7h4.5a2.5 2.5 0 0 0 0-5C13 2 12 7 12 7z"/></svg>; }
function HeartIcon()    { return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg>; }
function BellIcon()     { return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>; }
