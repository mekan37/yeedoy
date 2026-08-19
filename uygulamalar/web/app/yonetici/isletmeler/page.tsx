import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { createSupabaseServiceClient } from '@/src/lib/taban/hizmet';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { PanelActionButton } from '@/src/ui/bilesenler/panel-eylem-dugmesi';
import { MetricCard } from '@/src/ui/bilesenler/olcum-karti';
import { IsletmelerTablosu } from './isletmeler-tablosu';
import { DisaAktarButonu } from './disa-aktar-butonu';
import { SayfaBoyutuSecici } from './sayfa-boyutu-secici';
import { yuzdeDegisim, type IsletmeSatiri } from './isletmeler-yardimcilari';

export const metadata: Metadata = {
  title: 'İşletmeler | Yonetici Paneli',
  robots: { index: false, follow: false },
};

type Props = {
  searchParams: Promise<{
    q?: string;
    city?: string;
    district?: string;
    category?: string;
    status?: string;
    verified?: string;
    sort?: string;
    page?: string;
    size?: string;
  }>;
};

type SortKey = 'newest' | 'name' | 'rating' | 'reviews';
type StatusKey = '' | 'active' | 'inactive';
type VerifiedKey = '' | 'verified' | 'unverified';

const SORT_OPTIONS: Array<{ value: SortKey; label: string }> = [
  { value: 'newest', label: 'En Yeni' },
  { value: 'name', label: 'Ada Göre' },
  { value: 'rating', label: 'En Çok Puan' },
  { value: 'reviews', label: 'En Çok Yorum' },
];
const STATUS_OPTIONS: Array<{ value: StatusKey; label: string }> = [
  { value: '', label: 'Tüm Durumlar' },
  { value: 'active', label: 'Aktif' },
  { value: 'inactive', label: 'Pasif' },
];
const VERIFIED_OPTIONS: Array<{ value: VerifiedKey; label: string }> = [
  { value: '', label: 'Tümü' },
  { value: 'verified', label: 'Doğrulandı' },
  { value: 'unverified', label: 'Doğrulanmadı' },
];
const PAGE_SIZE_OPTIONS = [8, 20, 40, 100];

export default async function AdminBusinessesPage({ searchParams }: Props) {
  const {
    q = '',
    city = '',
    district = '',
    category = '',
    status = '',
    verified = '',
    sort = 'newest',
    page = '1',
    size = '40',
  } = await searchParams;

  const sortKey = normalizeOption(SORT_OPTIONS, sort, 'newest');
  const statusKey = normalizeOption(STATUS_OPTIONS, status, '');
  const verifiedKey = normalizeOption(VERIFIED_OPTIONS, verified, '');
  const pageSize = PAGE_SIZE_OPTIONS.includes(Number(size)) ? Number(size) : 40;
  const pageNum = Math.max(1, parseInt(page, 10) || 1);
  const offset = (pageNum - 1) * pageSize;

  const supabase = await createSupabaseServerClient();
  const searchClient = (createSupabaseServiceClient() ?? supabase) as any;

  const now = Date.now();
  const bugunBasi = new Date(new Date().setHours(0, 0, 0, 0)).toISOString();
  const buHaftaBasi = new Date(now - 7 * 86400000).toISOString();
  const oncekiHaftaBasi = new Date(now - 14 * 86400000).toISOString();

  const [
    { data: businesses, count },
    totalRes,
    activeRes,
    inactiveRes,
    verifiedActiveRes,
    todayRes,
    thisWeekRes,
    lastWeekRes,
    pendingSubmissionsRes,
    cityLookup,
    categoryLookup,
    districtLookup,
  ] = await Promise.all([
    fetchBusinesses(searchClient, { q: q.trim(), city: city.trim(), district: district.trim(), category: category.trim(), status: statusKey, verified: verifiedKey, sort: sortKey, offset, pageSize }),
    searchClient.from('businesses').select('id', { count: 'exact', head: true }),
    searchClient.from('businesses').select('id', { count: 'exact', head: true }).eq('is_active', true),
    searchClient.from('businesses').select('id', { count: 'exact', head: true }).eq('is_active', false),
    searchClient.from('businesses').select('id', { count: 'exact', head: true }).eq('is_active', true).eq('is_verified', true),
    searchClient.from('businesses').select('id', { count: 'exact', head: true }).gte('created_at', bugunBasi),
    searchClient.from('businesses').select('id', { count: 'exact', head: true }).gte('created_at', buHaftaBasi),
    searchClient.from('businesses').select('id', { count: 'exact', head: true }).gte('created_at', oncekiHaftaBasi).lt('created_at', buHaftaBasi),
    searchClient.from('business_submissions').select('id, name, city, district, created_at', { count: 'exact' }).eq('status', 'new').order('created_at', { ascending: false }).limit(5),
    (supabase as any).rpc('get_business_cities_v1', { p_limit: 150 }),
    (supabase as any).rpc('get_business_categories_v1'),
    (supabase as any).rpc('get_business_districts_v1', { p_city: city.trim() || null }),
  ]);

  const list = businesses;
  const totalPages = Math.ceil((count ?? 0) / pageSize);

  // Sahip bilgisi — owner_claims (approved) + user_profiles birleştirme
  const businessIds = list.map((b: any) => b.id);
  const ownerNames = new Map<string, string>();
  if (businessIds.length > 0) {
    const { data: claims } = await searchClient
      .from('owner_claims')
      .select('business_id, user_id')
      .eq('status', 'approved')
      .in('business_id', businessIds);
    const userIds = Array.from(new Set((claims ?? []).map((c: any) => c.user_id)));
    if (userIds.length > 0) {
      const { data: profiles } = await searchClient
        .from('user_profiles')
        .select('user_id, display_name')
        .in('user_id', userIds);
      const nameByUser = new Map<string, string>(
        (profiles ?? []).map((p: any) => [p.user_id as string, (p.display_name as string) ?? '—']),
      );
      for (const c of (claims ?? []) as Array<{ business_id: string; user_id: string }>) {
        if (!ownerNames.has(c.business_id)) {
          ownerNames.set(c.business_id, nameByUser.get(c.user_id) ?? '—');
        }
      }
    }
  }

  const rows: IsletmeSatiri[] = list.map((b: any) => ({
    id: b.id,
    name: b.name,
    slug: b.slug,
    public_slug: b.public_slug,
    category: b.category,
    city: b.city,
    district: b.district,
    phone: b.phone,
    logoUrl: b.logo_url,
    is_active: b.is_active,
    is_verified: b.is_verified,
    created_at: b.created_at,
    ownerName: ownerNames.get(b.id) ?? null,
  }));

  const cities = ((cityLookup.data ?? []) as Array<{ city: string; business_count: number }>).map((r) => r.city);
  const categories = ((categoryLookup.data ?? []) as Array<{ category: string; business_count: number }>).map((r) => r.category);
  const districts = ((districtLookup.data ?? []) as Array<{ district: string; business_count: number }>).map((r) => r.district);

  const toplam = totalRes.count ?? 0;
  const aktif = activeRes.count ?? 0;
  const pasif = inactiveRes.count ?? 0;
  const dogrulanmisAktif = verifiedActiveRes.count ?? 0;
  const dogrulanmamisAktif = Math.max(0, aktif - dogrulanmisAktif);

  const donutVerisi: Array<[string, number]> = [
    ['Aktif · Doğrulanmış', dogrulanmisAktif],
    ['Aktif · Doğrulanmamış', dogrulanmamisAktif],
    ['Pasif', pasif],
  ].filter(([, n]) => n > 0) as Array<[string, number]>;

  const queryBase = buildQueryString({ q, city, district, category, status: statusKey, verified: verifiedKey, sort: sortKey, size: String(pageSize) });

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Yönetici"
        title="İşletmeler"
        description="İşletmeleri inceleyin, arayın, filtreleyin, onaylayın ve yönetin."
        actions={
          <Link href="/yonetici/isletmeler/yeni">
            <PanelActionButton variant="primary" icon={<PlusIcon />}>
              Yeni İşletme Ekle
            </PanelActionButton>
          </Link>
        }
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-6">
          {/* Metrikler */}
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-5">
            <MetricCard title="Toplam İşletme" value={toplam.toLocaleString('tr-TR')} tone="pink" icon={<BuildingIcon />}
              trend={{ value: yuzdeDegisim(thisWeekRes.count ?? 0, lastWeekRes.count ?? 0), label: 'yeni kayıt, önceki haftaya göre' }} />
            <MetricCard title="Onay Bekleyen" value={(pendingSubmissionsRes.count ?? 0).toLocaleString('tr-TR')} subtitle="yeni işletme başvurusu" tone="orange" icon={<ClockIcon />} />
            <MetricCard title="Aktif İşletme" value={aktif.toLocaleString('tr-TR')} subtitle={toplam > 0 ? `toplamın %${Math.round((aktif / toplam) * 100)}'i` : undefined} tone="green" icon={<CheckIcon />} />
            <MetricCard title="Pasif İşletme" value={pasif.toLocaleString('tr-TR')} subtitle={toplam > 0 ? `toplamın %${Math.round((pasif / toplam) * 100)}'i` : undefined} tone="purple" icon={<PauseCircleIcon />} />
            <MetricCard title="Bugün Eklenen" value={(todayRes.count ?? 0).toLocaleString('tr-TR')} subtitle="son 24 saat" tone="blue" icon={<PlusCircleIcon />} />
          </div>

          <div className="grid gap-6 lg:grid-cols-[1fr_300px]">
            <div className="flex min-w-0 flex-col gap-4">
              {/* Filtreler */}
              <form method="get" className="grid gap-3 rounded-xl border border-border bg-card p-3 md:grid-cols-2 lg:grid-cols-4">
                <input name="page" value="1" type="hidden" />
                <input name="size" value={String(pageSize)} type="hidden" />
                <input
                  name="q"
                  defaultValue={q}
                  placeholder="İşletme ara..."
                  className="min-h-11 rounded-xl border border-border bg-bg px-4 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30 lg:col-span-2"
                />
                <select name="city" defaultValue={city} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30">
                  <option value="">Tüm Şehirler</option>
                  {cities.map((c) => <option key={c} value={c}>{c}</option>)}
                </select>
                <select name="district" defaultValue={district} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30">
                  <option value="">Tüm İlçeler</option>
                  {districts.map((d) => <option key={d} value={d}>{d}</option>)}
                </select>
                <select name="category" defaultValue={category} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30">
                  <option value="">Tüm Kategoriler</option>
                  {categories.map((c) => <option key={c} value={c}>{c}</option>)}
                </select>
                <select name="status" defaultValue={statusKey} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30">
                  {STATUS_OPTIONS.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
                </select>
                <select name="verified" defaultValue={verifiedKey} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30">
                  {VERIFIED_OPTIONS.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
                </select>
                <button type="submit" className="min-h-11 rounded-xl bg-primary px-4 text-sm font-extrabold text-white transition-opacity hover:opacity-90">
                  Uygula
                </button>
              </form>

              <div className="flex items-center justify-between">
                <p className="text-xs font-bold text-muted">
                  {(count ?? 0).toLocaleString('tr-TR')} sonuçtan {list.length === 0 ? 0 : offset + 1}-{offset + list.length} arası gösteriliyor
                </p>
                <DisaAktarButonu rows={rows} />
              </div>

              {rows.length === 0 ? (
                <PanelEmptyState icon={<BuildingIcon />} title={q ? 'Sonuç bulunamadı' : 'İşletme yok'} />
              ) : (
                <PanelBolumKarti noPadding>
                  <IsletmelerTablosu rows={rows} />

                  <div className="flex flex-wrap items-center justify-between gap-3 border-t border-border px-5 py-3">
                    <div className="flex items-center gap-2 text-xs font-bold text-muted">
                      <span>Sayfa başına:</span>
                      <form method="get" className="inline">
                        {Object.entries({ q, city, district, category, status: statusKey, verified: verifiedKey, sort: sortKey }).map(([k, v]) => v && (
                          <input key={k} type="hidden" name={k} value={v} />
                        ))}
                        <SayfaBoyutuSecici options={PAGE_SIZE_OPTIONS} value={pageSize} />
                      </form>
                    </div>
                    {totalPages > 1 && (
                      <div className="flex items-center gap-1">
                        {pageNum > 1 && (
                          <Link href={`?${queryBase}&page=${pageNum - 1}`} className="rounded-lg border border-border px-3 py-1.5 text-xs font-bold hover:bg-black/4">←</Link>
                        )}
                        <span className="px-2 text-xs font-bold text-muted">Sayfa {pageNum} / {totalPages}</span>
                        {pageNum < totalPages && (
                          <Link href={`?${queryBase}&page=${pageNum + 1}`} className="rounded-lg border border-border px-3 py-1.5 text-xs font-bold hover:bg-black/4">→</Link>
                        )}
                      </div>
                    )}
                  </div>
                </PanelBolumKarti>
              )}
            </div>

            {/* Sağ sidebar */}
            <div className="flex flex-col gap-4">
              <PanelBolumKarti title="İşletme Durumu Dağılımı">
                {donutVerisi.length === 0 ? <p className="text-xs text-muted">Veri yok.</p> : <StatusDonut veriler={donutVerisi} toplam={toplam} />}
              </PanelBolumKarti>

              <PanelBolumKarti title="Son Başvurular" actions={<Link href="/yonetici/isletme-basvurulari" className="text-xs font-extrabold text-primary hover:underline">Tümünü Gör</Link>}>
                {(pendingSubmissionsRes.data ?? []).length === 0 ? (
                  <PanelEmptyState icon={<InboxIcon />} title="Bekleyen başvuru yok" />
                ) : (
                  <div className="flex flex-col gap-3">
                    {(pendingSubmissionsRes.data as Array<{ id: string; name: string; city: string | null; district: string | null; created_at: string }>).map((s) => (
                      <div key={s.id} className="flex items-center justify-between gap-2">
                        <div className="min-w-0">
                          <p className="truncate text-xs font-extrabold text-textStrong">{s.name}</p>
                          <p className="truncate text-[11px] text-muted">{[s.district, s.city].filter(Boolean).join(', ') || '—'}</p>
                        </div>
                        <span className="shrink-0 rounded-full bg-amber-50 px-2 py-0.5 text-[10px] font-extrabold text-amber-700">Onay Bekliyor</span>
                      </div>
                    ))}
                  </div>
                )}
              </PanelBolumKarti>

              <PanelBolumKarti title="Hızlı İşlemler">
                <div className="grid grid-cols-2 gap-2">
                  <HizliIslem href="#toplu-islemler" label="Toplu İşlemler" tone="green" icon={<CheckIcon />} />
                  <HizliIslem href="/yonetici/isletme-basvurulari" label="İşletme Talepleri" tone="orange" icon={<InboxIcon />} />
                  <HizliIslem href="/yonetici/zincirler" label="Zincirler" tone="purple" icon={<LayersIcon />} />
                  <HizliIslem href="/yonetici/raporlar" label="Rapor Oluştur" tone="blue" icon={<FileTextIcon />} />
                </div>
              </PanelBolumKarti>
            </div>
          </div>

          <div className="flex items-start gap-3 rounded-2xl border border-blue-200 bg-blue-50 p-4">
            <span className="mt-0.5 shrink-0 text-blue-600"><InfoIcon /></span>
            <div>
              <p className="text-sm font-black text-blue-900">Yönetici Notu</p>
              <p className="mt-0.5 text-xs text-blue-800">
                İşletme bilgilerinin doğruluğunu düzenli olarak kontrol edin ve onay süreçlerini aksatmadan yönetin. Doğru ve güncel bilgiler platform kalitesini artırır.
              </p>
            </div>
          </div>
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}

// ─── Veri erişimi ────────────────────────────────────────────────────────────

async function fetchBusinesses(
  supabase: any,
  input: { q: string; city: string; district: string; category: string; status: StatusKey; verified: VerifiedKey; sort: SortKey; offset: number; pageSize: number },
): Promise<{ data: any[]; count: number | null }> {
  const preferred = await runBusinessQuery(supabase, 'id, name, slug, public_slug, category, city, district, phone, logo_url, is_active, is_verified, created_at, avg_rating, average_rating, review_count', input);
  if (!preferred.error) return { data: preferred.data ?? [], count: preferred.count ?? null };
  const fallback = await runBusinessQuery(supabase, 'id, name, slug, public_slug, category, city, district, phone, logo_url, is_active, is_verified, created_at', input);
  return { data: fallback.data ?? [], count: fallback.count ?? null };
}

async function runBusinessQuery(
  supabase: any,
  select: string,
  input: { q: string; city: string; district: string; category: string; status: StatusKey; verified: VerifiedKey; sort: SortKey; offset: number; pageSize: number },
) {
  let query = supabase.from('businesses').select(select, { count: 'exact' });
  if (input.q) {
    const pattern = `%${input.q.replace(/[%,_]/g, ' ').trim()}%`;
    query = query.or(`name.ilike.${pattern},slug.ilike.${pattern},public_slug.ilike.${pattern},city.ilike.${pattern},district.ilike.${pattern},category.ilike.${pattern},address.ilike.${pattern}`);
  }
  if (input.city) query = query.eq('city', input.city);
  if (input.district) query = query.eq('district', input.district);
  if (input.category) query = query.eq('category', input.category);
  if (input.status === 'active') query = query.eq('is_active', true);
  if (input.status === 'inactive') query = query.eq('is_active', false);
  if (input.verified === 'verified') query = query.eq('is_verified', true);
  if (input.verified === 'unverified') query = query.eq('is_verified', false);

  if (input.sort === 'name') query = query.order('name', { ascending: true });
  else if (input.sort === 'rating') query = query.order(select.includes('avg_rating') ? 'avg_rating' : 'created_at', { ascending: false, nullsFirst: false });
  else if (input.sort === 'reviews') query = query.order(select.includes('review_count') ? 'review_count' : 'created_at', { ascending: false, nullsFirst: false });
  else query = query.order('created_at', { ascending: false });

  return await query.range(input.offset, input.offset + input.pageSize - 1);
}

function normalizeOption<T extends string>(options: Array<{ value: T }>, value: string, fallback: T): T {
  return options.some((o) => o.value === value) ? (value as T) : fallback;
}

function buildQueryString(input: Record<string, string>) {
  const params = new URLSearchParams();
  Object.entries(input).forEach(([key, value]) => { if (value) params.set(key, value); });
  return params.toString();
}

// ─── Küçük UI parçaları ──────────────────────────────────────────────────────

function HizliIslem({ href, label, icon, tone }: { href: string; label: string; icon: React.ReactNode; tone: string }) {
  const TONE: Record<string, string> = {
    primary: 'bg-primary/10 text-(--yd-color-primary)', blue: 'bg-blue-50 text-blue-600', pink: 'bg-rose-50 text-rose-600',
    purple: 'bg-violet-50 text-violet-600', green: 'bg-emerald-50 text-emerald-600', orange: 'bg-amber-50 text-amber-600',
  };
  return (
    <Link href={href} className="flex flex-col items-start gap-2 rounded-xl border border-border p-3 transition-all hover:-translate-y-0.5 hover:border-primary/30 hover:shadow-sm">
      <span className={`flex h-8 w-8 items-center justify-center rounded-lg ${TONE[tone]}`}>{icon}</span>
      <span className="text-xs font-extrabold text-textStrong">{label}</span>
    </Link>
  );
}

const DONUT_RENKLERI = ['#059669', '#d97706', '#94a3b8'];

function StatusDonut({ veriler, toplam }: { veriler: Array<[string, number]>; toplam: number }) {
  const R = 60, CX = 70, CY = 70, STROKE = 22;
  const CIRCUM = 2 * Math.PI * R;
  const uzunluklar = veriler.map(([, n]) => (n / toplam) * CIRCUM);
  const offsetler = uzunluklar.reduce<number[]>((acc, u, i) => { acc.push(i === 0 ? 0 : acc[i - 1] + uzunluklar[i - 1]); return acc; }, []);

  return (
    <div className="flex flex-col items-center gap-4">
      <svg viewBox="0 0 140 140" width="140" height="140">
        <g transform={`rotate(-90 ${CX} ${CY})`}>
          {veriler.map(([label], i) => (
            <circle key={label} cx={CX} cy={CY} r={R} fill="none" stroke={DONUT_RENKLERI[i % DONUT_RENKLERI.length]} strokeWidth={STROKE}
              strokeDasharray={`${uzunluklar[i]} ${CIRCUM - uzunluklar[i]}`} strokeDashoffset={-offsetler[i]} />
          ))}
        </g>
        <text x={CX} y={CY - 4} textAnchor="middle" fontSize="18" fontWeight="900" fill="var(--yd-color-text-strong)" fontFamily="inherit">{toplam.toLocaleString('tr-TR')}</text>
        <text x={CX} y={CY + 14} textAnchor="middle" fontSize="9" fill="var(--yd-color-muted)" fontFamily="inherit">Toplam</text>
      </svg>
      <div className="flex w-full flex-col gap-1.5">
        {veriler.map(([label, n], i) => (
          <div key={label} className="flex items-center justify-between gap-2 text-[11px]">
            <span className="flex min-w-0 items-center gap-1.5 font-bold text-textStrong">
              <span className="h-2 w-2 shrink-0 rounded-full" style={{ background: DONUT_RENKLERI[i % DONUT_RENKLERI.length] }} />
              <span className="truncate">{label}</span>
            </span>
            <span className="shrink-0 font-extrabold text-muted">{n.toLocaleString('tr-TR')} · %{Math.round((n / toplam) * 100)}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

function BuildingIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="4" y="2" width="16" height="20" rx="2" ry="2" /><path d="M9 22V12h6v10" /></svg>; }
function PlusIcon() { return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><line x1="12" y1="5" x2="12" y2="19" /><line x1="5" y1="12" x2="19" y2="12" /></svg>; }
function ClockIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="9" /><path d="M12 7v5l3 3" /></svg>; }
function CheckIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M20 6 9 17l-5-5" /></svg>; }
function PauseCircleIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="9" /><line x1="10" y1="9" x2="10" y2="15" /><line x1="14" y1="9" x2="14" y2="15" /></svg>; }
function PlusCircleIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="9" /><line x1="12" y1="8" x2="12" y2="16" /><line x1="8" y1="12" x2="16" y2="12" /></svg>; }
function InboxIcon() { return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="22 12 16 12 14 15 10 15 8 12 2 12" /><path d="M5.45 5.11L2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z" /></svg>; }
function LayersIcon() { return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polygon points="12 2 2 7 12 12 22 7 12 2" /><polyline points="2 17 12 22 22 17" /><polyline points="2 12 12 17 22 12" /></svg>; }
function FileTextIcon() { return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" /><polyline points="14 2 14 8 20 8" /></svg>; }
function InfoIcon() { return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10" /><line x1="12" y1="16" x2="12" y2="12" /><line x1="12" y1="8" x2="12.01" y2="8" /></svg>; }
