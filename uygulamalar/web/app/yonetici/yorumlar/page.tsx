import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { createSupabaseServiceClient } from '@/src/lib/taban/hizmet';
import { hasPermission } from '@/src/lib/yetki-kontrol';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { MetricCard } from '@/src/ui/bilesenler/olcum-karti';
import { YetkisizErisim } from '@/src/ui/bilesenler/yetkisiz-erisim';
import { YorumlarTablosu } from './yorumlar-tablosu';
import { DisaAktarButonu } from './disa-aktar-butonu';
import { yuzdeDegisim, type YorumSatiri } from './yorumlar-yardimcilari';

export const metadata: Metadata = {
  title: 'Yorumlar | Yonetici Paneli',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ q?: string; status?: string; rating?: string; category?: string; page?: string }> };

const STATUS_OPTIONS = [
  { value: '', label: 'Durum: Tümü' },
  { value: 'approved', label: 'Onaylanmış' },
  { value: 'pending', label: 'Beklemede' },
  { value: 'rejected', label: 'Reddedilmiş' },
];
const PAGE_SIZE = 20;

export default async function AdminReviewsPage({ searchParams }: Props) {
  const yetkili = await hasPermission('page:yorumlar');
  if (!yetkili) {
    return (
      <div className="flex flex-col">
        <PanelSayfaBasligi eyebrow="Yönetici" title="Yorumlar" description="Bu sayfayı görüntüleme yetkiniz yok." />
        <PanelIcerikYuzeyi className="pt-6"><YetkisizErisim sayfaAdi="Yorumlar" /></PanelIcerikYuzeyi>
      </div>
    );
  }

  const { q = '', status = '', rating = '', category = '', page = '1' } = await searchParams;
  const pageNum = Math.max(1, parseInt(page, 10) || 1);
  const offset = (pageNum - 1) * PAGE_SIZE;

  const supabase = await createSupabaseServerClient();
  const sb = (createSupabaseServiceClient() ?? supabase) as any;

  let query = sb.from('reviews').select('id, business_id, user_id, rating, title, content, status, helpful_count, owner_reply, created_at', { count: 'exact' });
  if (q.trim()) query = query.ilike('content', `%${q.trim()}%`);
  if (status) query = query.eq('status', status);
  if (rating) query = query.eq('rating', Number(rating));
  query = query.order('created_at', { ascending: false }).range(offset, offset + PAGE_SIZE - 1);

  const [
    { data: reviewsRaw, count },
    totalRes,
    approvedRes,
    pendingRes,
    rejectedRes,
    ratingSampleRes,
    categoriesRes,
  ] = await Promise.all([
    query,
    sb.from('reviews').select('id', { count: 'exact', head: true }),
    sb.from('reviews').select('id', { count: 'exact', head: true }).eq('status', 'approved'),
    sb.from('reviews').select('id', { count: 'exact', head: true }).eq('status', 'pending'),
    sb.from('reviews').select('id', { count: 'exact', head: true }).eq('status', 'rejected'),
    sb.from('reviews').select('rating').limit(5000),
    (supabase as any).rpc('get_business_categories_v1'),
  ]);

  const reviews = (reviewsRaw ?? []) as any[];

  const businessIds = Array.from(new Set(reviews.map((r) => r.business_id).filter(Boolean)));
  const userIds = Array.from(new Set(reviews.map((r) => r.user_id).filter(Boolean)));
  const reviewIds = reviews.map((r) => r.id);

  const [{ data: businessRows }, { data: profileRows }, { data: reportRows }] = await Promise.all([
    businessIds.length > 0 ? sb.from('businesses').select('id, name, slug, public_slug, category').in('id', businessIds) : Promise.resolve({ data: [] }),
    userIds.length > 0 ? sb.from('user_profiles').select('user_id, display_name').in('user_id', userIds) : Promise.resolve({ data: [] }),
    reviewIds.length > 0 ? sb.from('reports').select('review_id').eq('target_type', 'review').in('status', ['open', 'reviewing']).in('review_id', reviewIds) : Promise.resolve({ data: [] }),
  ]);

  const businessById = new Map<string, { name: string; slug: string | null; category: string | null }>(
    (businessRows ?? []).map((b: any) => [b.id as string, { name: b.name, slug: b.public_slug ?? b.slug, category: b.category }]),
  );
  const nameByUser = new Map<string, string>((profileRows ?? []).map((p: any) => [p.user_id as string, p.display_name]));
  const reportCountByReview = new Map<string, number>();
  for (const r of (reportRows ?? []) as any[]) {
    if (r.review_id) reportCountByReview.set(r.review_id, (reportCountByReview.get(r.review_id) ?? 0) + 1);
  }

  let rows: YorumSatiri[] = reviews.map((r) => {
    const biz = businessById.get(r.business_id);
    return {
      id: r.id, title: r.title, content: r.content, rating: r.rating, status: r.status, createdAt: r.created_at,
      businessId: r.business_id, businessName: biz?.name ?? null, businessSlug: biz?.slug ?? null, businessCategory: biz?.category ?? null,
      userName: r.user_id ? nameByUser.get(r.user_id) ?? null : null,
      helpfulCount: r.helpful_count ?? 0, hasOwnerReply: Boolean(r.owner_reply), reportCount: reportCountByReview.get(r.id) ?? 0,
    };
  });
  if (category) rows = rows.filter((r) => r.businessCategory === category);

  const totalPages = Math.max(1, Math.ceil((count ?? 0) / PAGE_SIZE));

  const raporlanmisRes = await sb.from('reports').select('review_id', { count: 'exact' }).eq('target_type', 'review').in('status', ['open', 'reviewing']);
  const raporlanmisBenzersiz = new Set(((raporlanmisRes.data ?? []) as any[]).map((r) => r.review_id)).size;

  const ratingDagilimi: Record<number, number> = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
  for (const r of (ratingSampleRes.data ?? []) as Array<{ rating: number }>) {
    if (r.rating >= 1 && r.rating <= 5) ratingDagilimi[r.rating] += 1;
  }
  const ratingToplam = Object.values(ratingDagilimi).reduce((a, b) => a + b, 0);

  const toplam = totalRes.count ?? 0;
  const onaylanmis = approvedRes.count ?? 0;
  const beklemede = pendingRes.count ?? 0;
  const reddedilmis = rejectedRes.count ?? 0;

  const donutHam: Array<[string, number, string]> = [
    ['Onaylanmış', onaylanmis, '#059669'],
    ['Beklemede', beklemede, '#d97706'],
    ['Reddedilmiş', reddedilmis, '#dc2626'],
  ];
  const donutVerisi = donutHam.filter(([, n]) => n > 0);
  const donutToplam = donutVerisi.reduce((s, [, n]) => s + n, 0);

  const categories = ((categoriesRes.data ?? []) as Array<{ category: string }>).map((c) => c.category);
  const queryBase = buildQueryString({ q, status, rating, category });

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Yönetim"
        title="Yorumlar"
        description="Platformdaki tüm yorumları inceleyin, filtreleyin ve yönetin."
        actions={<DisaAktarButonu rows={rows} />}
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-6">
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-5">
            <MetricCard title="Tümü" value={toplam.toLocaleString('tr-TR')} subtitle="tüm yorumlar" tone="blue" icon={<UsersIcon />} />
            <MetricCard title="Onaylanmış" value={onaylanmis.toLocaleString('tr-TR')} subtitle={toplam > 0 ? `%${Math.round((onaylanmis / toplam) * 100)}` : undefined} tone="green" icon={<CheckIcon />} />
            <MetricCard title="Beklemede" value={beklemede.toLocaleString('tr-TR')} subtitle={toplam > 0 ? `%${Math.round((beklemede / toplam) * 100)}` : undefined} tone="orange" icon={<ClockIcon />} />
            <MetricCard title="Reddedilmiş" value={reddedilmis.toLocaleString('tr-TR')} subtitle={toplam > 0 ? `%${Math.round((reddedilmis / toplam) * 100)}` : undefined} tone="pink" icon={<XIcon />} />
            <MetricCard title="Raporlanmış" value={raporlanmisBenzersiz.toLocaleString('tr-TR')} subtitle="açık raporu olan" tone="purple" icon={<FlagIcon />} />
          </div>

          <div className="grid gap-6 lg:grid-cols-[1fr_300px]">
            <div className="flex min-w-0 flex-col gap-4">
              <form method="get" className="grid gap-3 rounded-xl border border-border bg-card p-3 md:grid-cols-2 lg:grid-cols-4">
                <input name="page" value="1" type="hidden" />
                <input
                  name="q"
                  defaultValue={q}
                  placeholder="Yorum içeriğinde ara..."
                  className="min-h-11 rounded-xl border border-border bg-bg px-4 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30 lg:col-span-2"
                />
                <select name="status" defaultValue={status} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30">
                  {STATUS_OPTIONS.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
                </select>
                <select name="rating" defaultValue={rating} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30">
                  <option value="">Puan: Tümü</option>
                  {[5, 4, 3, 2, 1].map((n) => <option key={n} value={n}>{n} Yıldız</option>)}
                </select>
                <select name="category" defaultValue={category} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30">
                  <option value="">İşletme Kategorisi: Tümü</option>
                  {categories.map((c) => <option key={c} value={c}>{c}</option>)}
                </select>
                <div className="flex gap-2 lg:col-span-4">
                  <button type="submit" className="min-h-11 rounded-xl bg-primary px-4 text-sm font-extrabold text-white transition-opacity hover:opacity-90">Filtrele</button>
                  <Link href="/yonetici/yorumlar" className="flex min-h-11 items-center rounded-xl border border-border px-4 text-sm font-bold text-muted hover:bg-black/4">Temizle</Link>
                </div>
              </form>

              {rows.length === 0 ? (
                <PanelEmptyState icon={<StarIcon />} title="Yorum bulunamadı" description={q || status || rating || category ? 'Bu filtrelerle eşleşen yorum yok.' : 'Henüz yorum yok.'} />
              ) : (
                <PanelBolumKarti noPadding>
                  <YorumlarTablosu rows={rows} />
                  <div className="flex flex-wrap items-center justify-between gap-3 border-t border-border px-5 py-3">
                    <p className="text-xs font-bold text-muted">Toplam {(count ?? 0).toLocaleString('tr-TR')} yorum</p>
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

            <div className="flex flex-col gap-4">
              <PanelBolumKarti title="Yorum Özeti">
                {donutToplam === 0 ? <p className="text-xs text-muted">Veri yok.</p> : <DurumDonut veriler={donutVerisi} toplam={donutToplam} />}
              </PanelBolumKarti>

              <PanelBolumKarti title="Puan Dağılımı">
                {ratingToplam === 0 ? (
                  <p className="text-xs text-muted">Veri yok.</p>
                ) : (
                  <div className="flex flex-col gap-2">
                    {[5, 4, 3, 2, 1].map((n) => {
                      const adet = ratingDagilimi[n];
                      const yuzde = ratingToplam > 0 ? Math.round((adet / ratingToplam) * 100) : 0;
                      return (
                        <div key={n} className="flex items-center gap-2 text-xs">
                          <span className="w-8 shrink-0 font-bold text-textStrong">{n} ★</span>
                          <div className="h-2 flex-1 overflow-hidden rounded-full bg-zinc-100">
                            <div className="h-full rounded-full bg-amber-400" style={{ width: `${yuzde}%` }} />
                          </div>
                          <span className="w-20 shrink-0 text-right text-muted">{adet.toLocaleString('tr-TR')} (%{yuzde})</span>
                        </div>
                      );
                    })}
                  </div>
                )}
              </PanelBolumKarti>

              <PanelBolumKarti title="Hızlı İşlemler">
                <div className="grid grid-cols-1 gap-2">
                  <Link href="#toplu-islemler" className="flex items-center justify-between rounded-xl border border-border px-3 py-2.5 text-xs font-extrabold text-textStrong transition-colors hover:border-primary/30 hover:text-primary">
                    <span>Toplu İşlemler<span className="block text-[10px] font-bold text-muted">Seçili yorumlar için toplu işlem</span></span>
                    <ArrowIcon />
                  </Link>
                  <Link href="/yonetici/raporlar?hedef=review" className="flex items-center justify-between rounded-xl border border-border px-3 py-2.5 text-xs font-extrabold text-textStrong transition-colors hover:border-primary/30 hover:text-primary">
                    <span>Raporlanmış Yorumlar<span className="block text-[10px] font-bold text-muted">Raporlanan yorumları görüntüle</span></span>
                    <ArrowIcon />
                  </Link>
                </div>
              </PanelBolumKarti>

              <div className="rounded-2xl border border-blue-200 bg-blue-50 p-4">
                <p className="mb-2 text-sm font-black text-blue-900">Notlar</p>
                <ul className="flex flex-col gap-1.5 text-xs text-blue-800">
                  <li>Reddedilen yorumlar kullanıcıya gösterilmez.</li>
                  <li>Raporlanmış yorumlar Raporlar sayfasından incelenebilir.</li>
                </ul>
              </div>
            </div>
          </div>
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}

function buildQueryString(input: Record<string, string>) {
  const params = new URLSearchParams();
  Object.entries(input).forEach(([key, value]) => { if (value) params.set(key, value); });
  return params.toString();
}

function DurumDonut({ veriler, toplam }: { veriler: Array<[string, number, string]>; toplam: number }) {
  const R = 60, CX = 70, CY = 70, STROKE = 22;
  const CIRCUM = 2 * Math.PI * R;
  const uzunluklar = veriler.map(([, n]) => (n / toplam) * CIRCUM);
  const offsetler = uzunluklar.reduce<number[]>((acc, u, i) => { acc.push(i === 0 ? 0 : acc[i - 1] + uzunluklar[i - 1]); return acc; }, []);

  return (
    <div className="flex flex-col items-center gap-4">
      <svg viewBox="0 0 140 140" width="140" height="140">
        <g transform={`rotate(-90 ${CX} ${CY})`}>
          {veriler.map(([label, , renk], i) => (
            <circle key={label} cx={CX} cy={CY} r={R} fill="none" stroke={renk} strokeWidth={STROKE}
              strokeDasharray={`${uzunluklar[i]} ${CIRCUM - uzunluklar[i]}`} strokeDashoffset={-offsetler[i]} />
          ))}
        </g>
        <text x={CX} y={CY - 4} textAnchor="middle" fontSize="18" fontWeight="900" fill="var(--yd-color-text-strong)" fontFamily="inherit">{toplam.toLocaleString('tr-TR')}</text>
        <text x={CX} y={CY + 14} textAnchor="middle" fontSize="9" fill="var(--yd-color-muted)" fontFamily="inherit">Toplam</text>
      </svg>
      <div className="flex w-full flex-col gap-1.5">
        {veriler.map(([label, n, renk]) => (
          <div key={label} className="flex items-center justify-between gap-2 text-[11px]">
            <span className="flex min-w-0 items-center gap-1.5 font-bold text-textStrong">
              <span className="h-2 w-2 shrink-0 rounded-full" style={{ background: renk }} />
              <span className="truncate">{label}</span>
            </span>
            <span className="shrink-0 font-extrabold text-muted">{n.toLocaleString('tr-TR')} · %{Math.round((n / toplam) * 100)}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

function UsersIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /><path d="M23 21v-2a4 4 0 0 0-3-3.87" /><path d="M16 3.13a4 4 0 0 1 0 7.75" /></svg>; }
function CheckIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="9" /><path d="m8 12 3 3 5-6" /></svg>; }
function ClockIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="9" /><path d="M12 7v5l3 3" /></svg>; }
function XIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="9" /><line x1="15" y1="9" x2="9" y2="15" /><line x1="9" y1="9" x2="15" y2="15" /></svg>; }
function FlagIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1z" /><line x1="4" y1="22" x2="4" y2="15" /></svg>; }
function StarIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" /></svg>; }
function ArrowIcon() { return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="5" y1="12" x2="19" y2="12" /><polyline points="12 5 19 12 12 19" /></svg>; }
