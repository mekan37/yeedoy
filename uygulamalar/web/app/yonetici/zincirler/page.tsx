import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { PanelActionButton } from '@/src/ui/bilesenler/panel-eylem-dugmesi';
import { MetricCard } from '@/src/ui/bilesenler/olcum-karti';
import { DisaAktarButonu } from './disa-aktar-butonu';
import { ZincirOnayButonu } from './zincir-onay-butonu';
import { yuzdeDegisim, type ZincirSatiri } from './zincirler-yardimcilari';

export const metadata: Metadata = {
  title: 'Zincirler | Yonetici Paneli',
  robots: { index: false, follow: false },
};

type Props = {
  searchParams: Promise<{ q?: string; status?: string; category?: string; page?: string; selected?: string }>;
};

type StatusKey = '' | 'verified' | 'unverified';
const STATUS_OPTIONS: Array<{ value: StatusKey; label: string }> = [
  { value: '', label: 'Tümü' },
  { value: 'verified', label: 'Onaylı' },
  { value: 'unverified', label: 'Onaysız' },
];
const PAGE_SIZE = 10;

type RpcChainRow = {
  id: string; name: string; slug: string | null; category: string | null; logo_url: string | null;
  is_verified: boolean; template_business_id: string | null; template_business_name: string | null;
  branch_count: number; created_at: string;
};

export default async function AdminChainsPage({ searchParams }: Props) {
  const { q = '', status = '', category = '', page = '1', selected } = await searchParams;
  const statusKey = STATUS_OPTIONS.some((o) => o.value === status) ? (status as StatusKey) : '';
  const pageNum = Math.max(1, parseInt(page, 10) || 1);

  const supabase = await createSupabaseServerClient();
  const sb = supabase as any;

  const buAyBasi = new Date(new Date().setDate(1)).toISOString();
  const gecenAyBasi = new Date(new Date(new Date().setDate(1)).setMonth(new Date().getMonth() - 1)).toISOString();

  const [
    { data: allChainsRaw },
    totalChainsRes,
    verifiedChainsRes,
    totalBranchesRes,
    activeBranchesRes,
    buAyYeniRes,
    gecenAyYeniRes,
  ] = await Promise.all([
    sb.rpc('admin_list_chains_v1', { p_q: q.trim() || null, p_limit: 500, p_offset: 0 }),
    sb.from('chains').select('id', { count: 'exact', head: true }),
    sb.from('chains').select('id', { count: 'exact', head: true }).eq('is_verified', true),
    sb.from('businesses').select('id', { count: 'exact', head: true }).not('chain_id', 'is', null),
    sb.from('businesses').select('id', { count: 'exact', head: true }).not('chain_id', 'is', null).eq('is_active', true),
    sb.from('chains').select('id', { count: 'exact', head: true }).gte('created_at', buAyBasi),
    sb.from('chains').select('id', { count: 'exact', head: true }).gte('created_at', gecenAyBasi).lt('created_at', buAyBasi),
  ]);

  let sonGuncellemeler: Array<{ id: string; action: string; target_id: string; created_at: string }> = [];
  try {
    const { data, error } = await sb
      .from('admin_audit_log')
      .select('id, action, target_id, created_at')
      .eq('target_table', 'chains')
      .order('created_at', { ascending: false })
      .limit(5);
    if (!error) sonGuncellemeler = data ?? [];
  } catch {
    // admin_audit_log henüz mevcut değilse sessizce boş bırak
  }

  const allChains = (allChainsRaw ?? []) as RpcChainRow[];
  const categories = Array.from(new Set(allChains.map((c) => c.category).filter((c): c is string => Boolean(c)))).sort((a, b) => a.localeCompare(b, 'tr-TR'));

  const filtered = allChains.filter((c) => {
    if (statusKey === 'verified' && !c.is_verified) return false;
    if (statusKey === 'unverified' && c.is_verified) return false;
    if (category && c.category !== category) return false;
    return true;
  });

  const totalPages = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE));
  const pageChains = filtered.slice((pageNum - 1) * PAGE_SIZE, pageNum * PAGE_SIZE);

  const rows: ZincirSatiri[] = pageChains.map((c) => ({
    id: c.id, name: c.name, slug: c.slug, category: c.category, logoUrl: c.logo_url,
    isVerified: c.is_verified, templateBusinessName: c.template_business_name,
    activeBranchCount: Number(c.branch_count), createdAt: c.created_at,
  }));

  const selectedId = selected ?? pageChains[0]?.id ?? null;
  const selectedCreatedAt = allChains.find((c) => c.id === selectedId)?.created_at ?? new Date().toISOString();
  const selectedDetail = selectedId ? await getChainDetail(sb, selectedId, selectedCreatedAt) : null;

  const toplamZincir = totalChainsRes.count ?? 0;
  const onayliZincir = verifiedChainsRes.count ?? 0;
  const toplamSube = totalBranchesRes.count ?? 0;
  const aktifSube = activeBranchesRes.count ?? 0;
  const ortalamaSube = toplamZincir > 0 ? (toplamSube / toplamZincir).toFixed(1) : '0';

  const queryBase = buildQueryString({ q, status: statusKey, category });

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Yönetici"
        title="Zincirler"
        description="Zincir işletmelerini yönetin ve takip edin."
        actions={
          <div className="flex items-center gap-2">
            <DisaAktarButonu rows={rows} />
            <Link href="/yonetici/zincirler/yeni">
              <PanelActionButton variant="primary" icon={<PlusIcon />}>Yeni Zincir Ekle</PanelActionButton>
            </Link>
          </div>
        }
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-6">
          {/* Metrikler */}
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-5">
            <MetricCard title="Toplam Zincir" value={toplamZincir.toLocaleString('tr-TR')} subtitle={`${onayliZincir} onaylı`} tone="purple" icon={<LayersIcon />} />
            <MetricCard title="Toplam Şube" value={toplamSube.toLocaleString('tr-TR')} subtitle={`${aktifSube} aktif`} tone="blue" icon={<BuildingIcon />} />
            <MetricCard title="Aktif Şube" value={aktifSube.toLocaleString('tr-TR')} tone="green" icon={<CheckIcon />} />
            <MetricCard title="Ortalama Şube" value={ortalamaSube} subtitle="zincir başına" tone="orange" icon={<CalcIcon />} />
            <MetricCard title="Bu Ay Yeni" value={(buAyYeniRes.count ?? 0).toLocaleString('tr-TR')} tone="pink" icon={<PlusCircleIcon />}
              trend={{ value: yuzdeDegisim(buAyYeniRes.count ?? 0, gecenAyYeniRes.count ?? 0), label: 'geçen aya göre' }} />
          </div>

          {/* Filtreler */}
          <form method="get" className="grid gap-3 rounded-xl border border-border bg-card p-3 md:grid-cols-[minmax(200px,1.6fr)_repeat(2,minmax(140px,1fr))_auto]">
            <input name="page" value="1" type="hidden" />
            <input
              name="q"
              defaultValue={q}
              placeholder="Zincir ara..."
              className="min-h-11 rounded-xl border border-border bg-bg px-4 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30"
            />
            <select name="status" defaultValue={statusKey} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30">
              {STATUS_OPTIONS.map((o) => <option key={o.value} value={o.value}>Durum: {o.label}</option>)}
            </select>
            <select name="category" defaultValue={category} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30">
              <option value="">Kategori: Tümü</option>
              {categories.map((c) => <option key={c} value={c}>{c}</option>)}
            </select>
            <button type="submit" className="min-h-11 rounded-xl bg-primary px-4 text-sm font-extrabold text-white transition-opacity hover:opacity-90">
              Filtrele
            </button>
          </form>

          <div className="grid gap-6 lg:grid-cols-[1fr_340px]">
            <div className="flex min-w-0 flex-col gap-4">
              {rows.length === 0 ? (
                <PanelEmptyState icon={<LayersIcon />} title={q || category || statusKey ? 'Sonuç bulunamadı' : 'Zincir yok'} description="Henüz hiç zincir oluşturulmamış." />
              ) : (
                <PanelBolumKarti noPadding>
                  <div className="overflow-x-auto">
                    <table className="w-full text-sm">
                      <thead>
                        <tr className="border-b border-border text-left">
                          <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Zincir</th>
                          <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Kategori</th>
                          <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Aktif Şube</th>
                          <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Şablon</th>
                          <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Durum</th>
                          <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Oluşturulma</th>
                          <th className="px-5 py-3 text-right text-[11px] font-extrabold uppercase tracking-wide text-muted">İşlemler</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-border">
                        {rows.map((c) => (
                          <tr key={c.id} className={`hover:bg-black/2 ${c.id === selectedId ? 'bg-primary/5' : ''}`}>
                            <td className="px-5 py-3">
                              <Link href={`?${queryBase}&selected=${c.id}`} className="flex items-center gap-3">
                                <span className="flex h-9 w-9 shrink-0 items-center justify-center overflow-hidden rounded-lg bg-primary/10 text-xs font-black text-primary">
                                  {c.logoUrl ? (
                                    // eslint-disable-next-line @next/next/no-img-element
                                    <img src={c.logoUrl} alt={c.name} className="h-full w-full object-cover" />
                                  ) : (
                                    c.name.charAt(0).toUpperCase()
                                  )}
                                </span>
                                <div className="min-w-0">
                                  <p className="truncate font-bold text-textStrong">{c.name}</p>
                                  <p className="truncate text-xs text-muted">{c.slug ?? '—'}</p>
                                </div>
                              </Link>
                            </td>
                            <td className="px-5 py-3 text-muted">{c.category ?? '—'}</td>
                            <td className="px-5 py-3">
                              <span className="rounded-full bg-slate-100 px-2.5 py-0.5 text-[11px] font-extrabold text-slate-700">{c.activeBranchCount} şube</span>
                            </td>
                            <td className="px-5 py-3">
                              {c.templateBusinessName ? (
                                <span className="rounded-full bg-indigo-50 px-2 py-0.5 text-[11px] font-extrabold text-indigo-700">Var</span>
                              ) : (
                                <span className="text-xs text-muted">—</span>
                              )}
                            </td>
                            <td className="px-5 py-3">
                              {c.isVerified ? (
                                <span className="rounded-full bg-blue-50 px-2 py-0.5 text-[11px] font-extrabold text-blue-700">Onaylı</span>
                              ) : (
                                <span className="rounded-full bg-zinc-100 px-2 py-0.5 text-[11px] font-extrabold text-zinc-500">Onaysız</span>
                              )}
                            </td>
                            <td className="px-5 py-3 text-xs text-muted">{new Date(c.createdAt).toLocaleDateString('tr-TR')}</td>
                            <td className="px-5 py-3">
                              <div className="flex items-center justify-end gap-1.5">
                                <Link href={`/yonetici/zincirler/${c.id}`} title="Tam detay" className="flex h-8 w-8 items-center justify-center rounded-lg border border-border text-muted transition-colors hover:border-primary/30 hover:text-primary">
                                  <EyeIcon />
                                </Link>
                                <ZincirOnayButonu chainId={c.id} isVerified={c.isVerified} className="flex h-8 w-8 items-center justify-center rounded-lg border border-border text-muted transition-colors hover:border-blue-300 hover:text-blue-700" />
                              </div>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>

                  <div className="flex flex-wrap items-center justify-between gap-3 border-t border-border px-5 py-3">
                    <p className="text-xs font-bold text-muted">Toplam {filtered.length} zincir</p>
                    {totalPages > 1 && (
                      <div className="flex items-center gap-1">
                        {pageNum > 1 && <Link href={`?${queryBase}&page=${pageNum - 1}`} className="rounded-lg border border-border px-3 py-1.5 text-xs font-bold hover:bg-black/4">←</Link>}
                        <span className="px-2 text-xs font-bold text-muted">Sayfa {pageNum} / {totalPages}</span>
                        {pageNum < totalPages && <Link href={`?${queryBase}&page=${pageNum + 1}`} className="rounded-lg border border-border px-3 py-1.5 text-xs font-bold hover:bg-black/4">→</Link>}
                      </div>
                    )}
                  </div>
                </PanelBolumKarti>
              )}
            </div>

            {/* Detay paneli */}
            <div className="flex flex-col gap-4">
              {!selectedDetail ? (
                <PanelBolumKarti>
                  <PanelEmptyState icon={<LayersIcon />} title="Zincir seçilmedi" description="Detayları görmek için listeden bir zincir seçin." />
                </PanelBolumKarti>
              ) : (
                <>
                  <PanelBolumKarti>
                    <div className="flex items-start gap-3">
                      <span className="flex h-14 w-14 shrink-0 items-center justify-center overflow-hidden rounded-xl bg-primary/10 text-lg font-black text-primary">
                        {selectedDetail.logoUrl ? (
                          // eslint-disable-next-line @next/next/no-img-element
                          <img src={selectedDetail.logoUrl} alt={selectedDetail.name} className="h-full w-full object-cover" />
                        ) : (
                          selectedDetail.name.charAt(0).toUpperCase()
                        )}
                      </span>
                      <div className="min-w-0 flex-1">
                        <p className="truncate text-base font-black text-textStrong">{selectedDetail.name}</p>
                        {selectedDetail.isVerified ? (
                          <span className="mt-1 inline-flex items-center gap-1 rounded-full bg-blue-50 px-2 py-0.5 text-[10px] font-extrabold text-blue-700">Onaylı</span>
                        ) : (
                          <span className="mt-1 inline-flex items-center gap-1 rounded-full bg-zinc-100 px-2 py-0.5 text-[10px] font-extrabold text-zinc-500">Onaysız</span>
                        )}
                      </div>
                    </div>

                    <dl className="mt-4 grid grid-cols-2 gap-3 border-t border-border pt-4 text-xs">
                      <DetayAlan label="Slug" value={selectedDetail.slug ?? '—'} />
                      <DetayAlan label="Kategori" value={selectedDetail.category ?? '—'} />
                      <DetayAlan label="Oluşturulma" value={new Date(selectedDetail.createdAt).toLocaleDateString('tr-TR')} />
                      <DetayAlan label="Toplam Şube" value={String(selectedDetail.branches.length)} />
                    </dl>

                    {selectedDetail.description && (
                      <p className="mt-4 border-t border-border pt-4 text-xs leading-relaxed text-muted">{selectedDetail.description}</p>
                    )}
                  </PanelBolumKarti>

                  <PanelBolumKarti title="İstatistikler (Son 7 Gün)">
                    <div className="grid grid-cols-2 gap-3">
                      <MiniStat label="Ziyaret" value={selectedDetail.stats.visits} />
                      <MiniStat label="Yorum" value={selectedDetail.stats.reviews} />
                    </div>
                    <p className="mt-3 text-[10px] text-muted">Ziyaret: QR tarama + menü görüntülenme toplamı. Sipariş/gelir verisi platformda henüz izlenmiyor.</p>
                  </PanelBolumKarti>

                  <PanelBolumKarti title="Hızlı İşlemler">
                    <div className="grid grid-cols-1 gap-2">
                      <Link href={`/yonetici/zincirler/${selectedDetail.id}`} className="flex items-center justify-between rounded-xl border border-border px-3 py-2.5 text-xs font-extrabold text-textStrong transition-colors hover:border-primary/30 hover:text-primary">
                        Şube Listesini Görüntüle <ArrowIcon />
                      </Link>
                      <Link href={`/yonetici/isletmeler?q=${encodeURIComponent(selectedDetail.name)}`} className="flex items-center justify-between rounded-xl border border-border px-3 py-2.5 text-xs font-extrabold text-textStrong transition-colors hover:border-primary/30 hover:text-primary">
                        İşletmeleri Görüntüle <ArrowIcon />
                      </Link>
                      <ZincirOnayButonu
                        chainId={selectedDetail.id}
                        isVerified={selectedDetail.isVerified}
                        className="flex items-center justify-between rounded-xl border border-border px-3 py-2.5 text-xs font-extrabold text-textStrong transition-colors hover:border-red-300 hover:text-red-600"
                      />
                    </div>
                  </PanelBolumKarti>

                  <PanelBolumKarti title="Son Güncellemeler">
                    {sonGuncellemeler.length === 0 ? (
                      <p className="text-xs text-muted">Henüz kayıtlı güncelleme yok.</p>
                    ) : (
                      <div className="flex flex-col gap-3">
                        {sonGuncellemeler.map((g) => (
                          <div key={g.id} className="flex items-center justify-between gap-2">
                            <p className="text-xs font-bold text-textStrong">Zincir {ACTION_LABELS[g.action] ?? g.action}</p>
                            <span className="shrink-0 text-[11px] text-muted">{new Date(g.created_at).toLocaleDateString('tr-TR')}</span>
                          </div>
                        ))}
                      </div>
                    )}
                  </PanelBolumKarti>
                </>
              )}
            </div>
          </div>
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}

const ACTION_LABELS: Record<string, string> = {
  create: 'oluşturuldu', update: 'güncellendi', delete: 'silindi', approve: 'onaylandı', reject: 'reddedildi',
};

// ─── Veri erişimi ────────────────────────────────────────────────────────────

async function getChainDetail(sb: any, chainId: string, createdAt: string) {
  const { data, error } = await sb.rpc('admin_get_chain_detail_v1', { p_chain_id: chainId });
  if (error || !data || (data as any[]).length === 0) return null;

  const rows = data as Array<{
    chain_id: string; chain_name: string; chain_slug: string | null; chain_category: string | null;
    chain_description: string | null; chain_logo_url: string | null; chain_is_verified: boolean;
    business_id: string;
  }>;
  const first = rows[0];
  const branchIds = rows.map((r) => r.business_id);

  const since7g = new Date(Date.now() - 7 * 86400000).toISOString();
  const [visitsRes, reviewsRes] = await Promise.all([
    branchIds.length > 0
      ? sb.from('analytics_events').select('id', { count: 'exact', head: true }).in('event_name', ['qr_scanned', 'menu_view']).in('business_id', branchIds).gte('created_at', since7g)
      : Promise.resolve({ count: 0 }),
    branchIds.length > 0
      ? sb.from('reviews').select('id', { count: 'exact', head: true }).in('business_id', branchIds).gte('created_at', since7g)
      : Promise.resolve({ count: 0 }),
  ]);

  return {
    id: first.chain_id,
    name: first.chain_name,
    slug: first.chain_slug,
    category: first.chain_category,
    description: first.chain_description,
    logoUrl: first.chain_logo_url,
    isVerified: first.chain_is_verified,
    createdAt,
    branches: rows,
    stats: {
      visits: (visitsRes.count ?? 0).toLocaleString('tr-TR'),
      reviews: (reviewsRes.count ?? 0).toLocaleString('tr-TR'),
    },
  };
}

function buildQueryString(input: Record<string, string>) {
  const params = new URLSearchParams();
  Object.entries(input).forEach(([key, value]) => { if (value) params.set(key, value); });
  return params.toString();
}

// ─── Küçük UI parçaları ──────────────────────────────────────────────────────

function DetayAlan({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <dt className="text-[10px] font-extrabold uppercase tracking-wide text-muted">{label}</dt>
      <dd className="mt-0.5 font-bold text-textStrong">{value}</dd>
    </div>
  );
}

function MiniStat({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-xl border border-border p-3">
      <p className="text-lg font-black text-textStrong">{value}</p>
      <p className="text-[11px] text-muted">{label}</p>
    </div>
  );
}

function LayersIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polygon points="12 2 2 7 12 12 22 7 12 2" /><polyline points="2 17 12 22 22 17" /><polyline points="2 12 12 17 22 12" /></svg>; }
function BuildingIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="4" y="2" width="16" height="20" rx="2" ry="2" /><path d="M9 22V12h6v10" /></svg>; }
function CheckIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M20 6 9 17l-5-5" /></svg>; }
function CalcIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="4" y="2" width="16" height="20" rx="2" /><line x1="8" y1="7" x2="16" y2="7" /><line x1="8" y1="12" x2="8.01" y2="12" /><line x1="12" y1="12" x2="12.01" y2="12" /><line x1="16" y1="12" x2="16.01" y2="12" /></svg>; }
function PlusCircleIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="9" /><line x1="12" y1="8" x2="12" y2="16" /><line x1="8" y1="12" x2="16" y2="12" /></svg>; }
function PlusIcon() { return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><line x1="12" y1="5" x2="12" y2="19" /><line x1="5" y1="12" x2="19" y2="12" /></svg>; }
function EyeIcon() { return <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" /><circle cx="12" cy="12" r="3" /></svg>; }
function ArrowIcon() { return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="5" y1="12" x2="19" y2="12" /><polyline points="12 5 19 12 12 19" /></svg>; }
