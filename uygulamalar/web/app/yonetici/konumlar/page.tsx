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
import {
  adminKonumlariGetir,
  adminKonumOzetiniGetir,
  type KonumIsletme,
} from '@/src/lib/veri/admin/konumlar';
import { TurkiyeHaritasi } from './turkiye-haritasi';
import { DisaAktarButonu } from './disa-aktar-butonu';
import { SayfaBoyutuSecici } from './sayfa-boyutu-secici';
import { REGION_BY_PROVINCE, BOLGELER } from './bolgeler';
import { aktiflikOrani, type IlSatiri, type IlceSatiri } from './konumlar-yardimcilari';

export const metadata: Metadata = {
  title: 'Konumlar | Yonetici Paneli',
  robots: { index: false, follow: false },
};

const KALITE_PAGE_SIZE = 40;
const PAGE_SIZE_OPTIONS = [10, 25, 50, 100];

type ViewKey = 'cities' | 'districts' | 'kalite';
type SortDir = 'asc' | 'desc';

type Props = {
  searchParams: Promise<{
    q?: string;
    view?: string;
    page?: string;
    sort?: string;
    dir?: string;
    eksik?: string;
    bolge?: string;
    size?: string;
  }>;
};

export default async function AdminLocationsPage({ searchParams }: Props) {
  const yetkili = await hasPermission('page:konumlar');
  if (!yetkili) {
    return (
      <div className="flex flex-col">
        <PanelSayfaBasligi eyebrow="Yönetici" title="Konumlar" description="Bu sayfayı görüntüleme yetkiniz yok." />
        <PanelIcerikYuzeyi className="pt-6"><YetkisizErisim sayfaAdi="Konumlar" /></PanelIcerikYuzeyi>
      </div>
    );
  }

  const {
    q = '',
    view = 'cities',
    page = '1',
    sort = 'business_count',
    dir = 'desc',
    eksik = '',
    bolge = '',
    size = '10',
  } = await searchParams;

  const viewKey: ViewKey = view === 'districts' ? 'districts' : view === 'kalite' ? 'kalite' : 'cities';
  const sortDir: SortDir = dir === 'asc' ? 'asc' : 'desc';
  const pageNum = Math.max(1, parseInt(page, 10) || 1);
  const pageSize = PAGE_SIZE_OPTIONS.includes(parseInt(size, 10)) ? parseInt(size, 10) : 10;
  const offset = (pageNum - 1) * pageSize;

  // ── Veri Kalitesi görünümü (değişmedi — gerçek koordinat/slug/il-ilçe eksikliği taraması) ──
  if (viewKey === 'kalite') {
    const eksikKoordinat = eksik === 'koordinat';
    const eksikKonum = eksik === 'konum';
    const eksikSlugFilter = eksik === 'slug';

    const [ozet, kaliteResult] = await Promise.all([
      adminKonumOzetiniGetir(),
      adminKonumlariGetir({
        city: q.trim() || undefined,
        eksikKoordinat: eksikKoordinat || undefined,
        eksikKonum: eksikKonum || undefined,
        eksikSlug: eksikSlugFilter || undefined,
        limit: KALITE_PAGE_SIZE,
        offset,
      }),
    ]);

    const totalPages = Math.ceil(kaliteResult.total / KALITE_PAGE_SIZE);
    const kalitePageHref = (nextPage: number) => `?view=kalite&q=${encodeURIComponent(q)}&eksik=${eksik}&page=${nextPage}`;

    return (
      <div className="flex flex-col">
        <PanelSayfaBasligi eyebrow="Yönetici" title="Konumlar" description={`${ozet.toplam.toLocaleString('tr-TR')} işletme · veri kalitesi görünümü`} />
        <PanelIcerikYuzeyi className="pt-6">
          <div className="flex flex-col gap-6">
            <ViewToggle viewKey={viewKey} q={q} />

            <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-5">
              <MetrikKarti label="Toplam" deger={ozet.toplam} renk="neutral" href="?view=kalite" aktif={eksik === ''} />
              <MetrikKarti label="Koordinatsız" deger={ozet.koordinatsiz} renk={ozet.koordinatsiz > 0 ? 'kirmizi' : 'yesil'} href="?view=kalite&eksik=koordinat" aktif={eksik === 'koordinat'} />
              <MetrikKarti label="Şehirsiz" deger={ozet.sehirsiz} renk={ozet.sehirsiz > 0 ? 'kirmizi' : 'yesil'} href="?view=kalite&eksik=konum" aktif={eksik === 'konum'} />
              <MetrikKarti label="İlçesiz" deger={ozet.ilcesiz} renk={ozet.ilcesiz > 0 ? 'sari' : 'yesil'} href="?view=kalite&eksik=konum" aktif={false} />
              <MetrikKarti label="Slugsuz" deger={ozet.slugsuz} renk={ozet.slugsuz > 0 ? 'sari' : 'yesil'} href="?view=kalite&eksik=slug" aktif={eksik === 'slug'} />
            </div>

            <div className="flex flex-wrap items-center gap-3">
              <form method="get" className="flex gap-2">
                <input type="hidden" name="view" value="kalite" />
                <input type="hidden" name="eksik" value={eksik} />
                <input type="hidden" name="page" value="1" />
                <input name="q" defaultValue={q} placeholder="Şehir ara..." className="w-64 rounded-xl border border-border bg-card px-4 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30" />
              </form>

              <div className="flex gap-2">
                {[
                  { value: '', label: 'Tümü' },
                  { value: 'koordinat', label: 'Koordinatsız' },
                  { value: 'konum', label: 'Şehirsiz' },
                  { value: 'slug', label: 'Slugsuz' },
                ].map(({ value, label }) => (
                  <a key={value} href={`?view=kalite&eksik=${value}&q=${encodeURIComponent(q)}&page=1`} className={`rounded-lg px-3 py-1.5 text-xs font-bold transition-colors ${eksik === value ? 'bg-primary text-white' : 'border border-border bg-card text-muted hover:text-textStrong'}`}>
                    {label}
                  </a>
                ))}
              </div>
            </div>

            {kaliteResult.fetchError ? (
              <PanelEmptyState icon={<MapPinIcon />} title="Veri yüklenemedi" description="businesses tablosuna erişimde hata oluştu." />
            ) : kaliteResult.items.length === 0 ? (
              <PanelEmptyState icon={<MapPinIcon />} title="Sonuç bulunamadı" description="Seçili filtreye uygun işletme yok." />
            ) : (
              <PanelBolumKarti noPadding description={`${kaliteResult.total.toLocaleString('tr-TR')} sonuç`}>
                <div className="overflow-x-auto">
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="border-b border-border text-left">
                        <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">İşletme</th>
                        <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Şehir / İlçe</th>
                        <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Koordinat</th>
                        <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Slug</th>
                        <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Durum</th>
                        <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">İşlem</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-border">
                      {kaliteResult.items.map((item) => <KonumSatiri key={item.id} item={item} />)}
                    </tbody>
                  </table>
                </div>

                {totalPages > 1 && (
                  <div className="flex items-center justify-between border-t border-border px-5 py-3">
                    <span className="text-xs text-muted">Sayfa {pageNum} / {totalPages}</span>
                    <div className="flex gap-2">
                      {pageNum > 1 && <a href={kalitePageHref(pageNum - 1)} className="rounded-lg border border-border px-3 py-1 text-xs font-bold text-textStrong hover:bg-black/2">Önceki</a>}
                      {pageNum < totalPages && <a href={kalitePageHref(pageNum + 1)} className="rounded-lg border border-border px-3 py-1 text-xs font-bold text-textStrong hover:bg-black/2">Sonraki</a>}
                    </div>
                  </div>
                )}
              </PanelBolumKarti>
            )}
          </div>
        </PanelIcerikYuzeyi>
      </div>
    );
  }

  // ── İl / İlçe görünümü — gerçek SQL GROUP BY (tam tablo, örneklem değil) ──
  // Not: get_business_*_v1 RPC'leri auth.uid() kontrolü yaptığı için servis rolü istemcisiyle
  // (session'sız) çağrılamaz — service_role bağlantısında auth.uid() her zaman NULL döner ve
  // RPC "unauthorized" ile başarısız olur. Bu yüzden RPC çağrıları gerçek oturum istemcisini kullanır.
  const userClient = await createSupabaseServerClient();
  const supabase = createSupabaseServiceClient() ?? userClient;
  const sb = supabase as any;
  const usb = userClient as any;

  const [totalRes, activeRes, verifiedRes, konumsuzRes, districtTotalRes, provinceMapRes] = await Promise.all([
    sb.from('businesses').select('id', { count: 'exact', head: true }),
    sb.from('businesses').select('id', { count: 'exact', head: true }).eq('is_active', true),
    sb.from('businesses').select('id', { count: 'exact', head: true }).eq('is_verified', true),
    sb.from('businesses').select('id', { count: 'exact', head: true }).is('city', null),
    sb.from('osm_admin_boundaries').select('id', { count: 'exact', head: true }).eq('admin_level', 6),
    usb.rpc('get_business_province_map_v1'),
  ]);

  const provinceRows = (provinceMapRes.data ?? []) as Array<{
    province_name: string; business_count: number; active_count: number; verified_count: number; district_count: number; geojson: string;
  }>;

  let ilRows: IlSatiri[] = provinceRows.map((r) => ({
    name: r.province_name,
    businessCount: r.business_count,
    activeCount: r.active_count,
    verifiedCount: r.verified_count,
    districtCount: r.district_count,
  }));

  let ilceRows: IlceSatiri[] = [];
  if (viewKey === 'districts') {
    const { data: districtData } = await usb.rpc('get_business_location_district_stats_v1');
    ilceRows = ((districtData ?? []) as Array<{ city: string; district: string; business_count: number; active_count: number; verified_count: number }>).map((r) => ({
      city: r.city,
      district: r.district,
      businessCount: r.business_count,
      activeCount: r.active_count,
      verifiedCount: r.verified_count,
    }));
  }

  // ── Bölge filtresi ──
  if (bolge) {
    ilRows = ilRows.filter((r) => REGION_BY_PROVINCE[r.name] === bolge);
    ilceRows = ilceRows.filter((r) => REGION_BY_PROVINCE[r.city] === bolge);
  }

  // ── Arama ──
  const query = q.trim().toLocaleLowerCase('tr-TR');
  if (query) {
    ilRows = ilRows.filter((r) => r.name.toLocaleLowerCase('tr-TR').includes(query));
    ilceRows = ilceRows.filter((r) => [r.district, r.city].join(' ').toLocaleLowerCase('tr-TR').includes(query));
  }

  // ── Sıralama ──
  const dirMul = sortDir === 'asc' ? 1 : -1;
  ilRows.sort((a, b) => {
    let res = 0;
    if (sort === 'name') res = a.name.localeCompare(b.name, 'tr');
    else if (sort === 'active_count') res = a.activeCount - b.activeCount;
    else if (sort === 'aktiflik') res = aktiflikOrani(a.businessCount, a.activeCount) - aktiflikOrani(b.businessCount, b.activeCount);
    else if (sort === 'district_count') res = a.districtCount - b.districtCount;
    else res = a.businessCount - b.businessCount;
    if (res === 0) res = a.name.localeCompare(b.name, 'tr');
    return res * dirMul;
  });
  ilceRows.sort((a, b) => {
    let res = 0;
    if (sort === 'name') res = a.district.localeCompare(b.district, 'tr');
    else if (sort === 'active_count') res = a.activeCount - b.activeCount;
    else if (sort === 'aktiflik') res = aktiflikOrani(a.businessCount, a.activeCount) - aktiflikOrani(b.businessCount, b.activeCount);
    else res = a.businessCount - b.businessCount;
    if (res === 0) res = a.district.localeCompare(b.district, 'tr');
    return res * dirMul;
  });

  const activeRows = viewKey === 'districts' ? ilceRows : ilRows;
  const totalPages = Math.max(1, Math.ceil(activeRows.length / pageSize));
  const pageIlRows = viewKey === 'cities' ? ilRows.slice(offset, offset + pageSize) : [];
  const pageIlceRows = viewKey === 'districts' ? ilceRows.slice(offset, offset + pageSize) : [];

  // ── Üst metrik kartları ──
  const toplamIsletme = totalRes.count ?? 0;
  const aktifIsletme = activeRes.count ?? 0;
  const pasifIsletme = toplamIsletme - aktifIsletme;
  const dogrulanmisIsletme = verifiedRes.count ?? 0;
  const konumsuzIsletme = konumsuzRes.count ?? 0;
  const eslenenToplam = provinceRows.reduce((s, r) => s + r.business_count, 0);
  const eslesmeyenIsletme = Math.max(0, toplamIsletme - konumsuzIsletme - eslenenToplam);
  const ilSayisi = provinceRows.length;
  const ilceSayisi = districtTotalRes.count ?? 0;

  // ── Hızlı istatistikler ──
  const anlamli = ilRows.filter((r) => r.businessCount >= 10);
  const enCok = [...ilRows].sort((a, b) => b.businessCount - a.businessCount)[0];
  const enYuksekOran = anlamli.length > 0 ? [...anlamli].sort((a, b) => aktiflikOrani(b.businessCount, b.activeCount) - aktiflikOrani(a.businessCount, a.activeCount))[0] : null;
  const enDusukOran = anlamli.length > 0 ? [...anlamli].sort((a, b) => aktiflikOrani(a.businessCount, a.activeCount) - aktiflikOrani(b.businessCount, b.activeCount))[0] : null;

  const donutHam: Array<[string, number, string]> = [
    ['Aktif', aktifIsletme, '#059669'],
    ['Pasif', pasifIsletme, '#94a3b8'],
  ];
  const donutVerisi = donutHam.filter(([, n]) => n > 0);
  const donutToplam = donutVerisi.reduce((s, [, n]) => s + n, 0);

  const top10 = [...ilRows].sort((a, b) => b.businessCount - a.businessCount).slice(0, 10);

  const queryBase = buildQueryString({ q, bolge, size: String(pageSize) });
  const createSortHref = (nextSort: string) => {
    const nextDir: SortDir = sort === nextSort && sortDir === 'asc' ? 'desc' : 'asc';
    return `?view=${viewKey}&${queryBase}&sort=${nextSort}&dir=${nextDir}&page=1`;
  };
  const pageHref = (nextPage: number) => `?view=${viewKey}&${queryBase}&sort=${sort}&dir=${sortDir}&page=${nextPage}`;

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi eyebrow="Yönetim" title="Konumlar" description="İllere ve ilçelere göre işletme dağılımını görüntüleyin." />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-6">
          <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-6">
            <MetricCard title="Toplam İşletme" value={toplamIsletme.toLocaleString('tr-TR')} tone="blue" icon={<BuildingIcon />} />
            <MetricCard title="Aktif İşletme" value={aktifIsletme.toLocaleString('tr-TR')} subtitle={toplamIsletme > 0 ? `%${Math.round((aktifIsletme / toplamIsletme) * 100)}` : undefined} tone="green" icon={<CheckIcon />} />
            <MetricCard title="Pasif İşletme" value={pasifIsletme.toLocaleString('tr-TR')} subtitle={toplamIsletme > 0 ? `%${Math.round((pasifIsletme / toplamIsletme) * 100)}` : undefined} tone="orange" icon={<PauseIcon />} />
            <MetricCard title="Doğrulanmış" value={dogrulanmisIsletme.toLocaleString('tr-TR')} subtitle={toplamIsletme > 0 ? `%${Math.round((dogrulanmisIsletme / toplamIsletme) * 100)}` : undefined} tone="purple" icon={<ShieldIcon />} />
            <MetricCard title="İl Sayısı" value={ilSayisi.toLocaleString('tr-TR')} subtitle="Tüm Türkiye" tone="pink" icon={<MapIcon />} />
            <MetricCard title="İlçe Sayısı" value={ilceSayisi.toLocaleString('tr-TR')} subtitle="Toplam ilçe" tone="primary" icon={<PinIcon />} />
          </div>

          <div className="grid gap-6 lg:grid-cols-[1fr_300px]">
            <div className="flex min-w-0 flex-col gap-4">
              <div className="flex flex-wrap items-center justify-between gap-3">
                <ViewToggle viewKey={viewKey} q={q} />
                <DisaAktarButonu view={viewKey === 'districts' ? 'districts' : 'cities'} ilRows={ilRows} ilceRows={ilceRows} />
              </div>

              <form method="get" className="grid gap-3 rounded-xl border border-border bg-card p-3 md:grid-cols-3">
                <input type="hidden" name="view" value={viewKey} />
                <input type="hidden" name="sort" value={sort} />
                <input type="hidden" name="dir" value={sortDir} />
                <input type="hidden" name="page" value="1" />
                <input
                  name="q"
                  defaultValue={q}
                  placeholder={viewKey === 'districts' ? 'İlçe veya il ara...' : 'İl ara...'}
                  className="min-h-11 rounded-xl border border-border bg-bg px-4 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30 md:col-span-2"
                />
                <select name="bolge" defaultValue={bolge} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30">
                  <option value="">Tüm Bölgeler</option>
                  {BOLGELER.map((b) => <option key={b} value={b}>{b}</option>)}
                </select>
                <div className="flex gap-2 md:col-span-3">
                  <button type="submit" className="min-h-11 rounded-xl bg-primary px-4 text-sm font-extrabold text-white transition-opacity hover:opacity-90">Filtrele</button>
                  <Link href="/yonetici/konumlar" className="flex min-h-11 items-center rounded-xl border border-border px-4 text-sm font-bold text-muted hover:bg-black/4">Temizle</Link>
                </div>
              </form>

              {activeRows.length === 0 ? (
                <PanelEmptyState icon={<MapPinIcon />} title={q || bolge ? 'Sonuç bulunamadı' : `${viewKey === 'districts' ? 'İlçe' : 'İl'} yok`} description="Konum listesi mevcut işletme kayıtlarındaki şehir ve ilçe bilgilerinden, gerçek il sınırı verisiyle eşleştirilerek oluşturulur." />
              ) : (
                <PanelBolumKarti noPadding>
                  <div className="overflow-x-auto">
                    <table className="w-full text-sm">
                      <thead>
                        <tr className="border-b border-border text-left">
                          <SortableHeader label={viewKey === 'districts' ? 'İlçe' : 'İl'} sortKey="name" currentSort={sort} currentDir={sortDir} href={createSortHref('name')} />
                          {viewKey === 'districts' && <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">İl</th>}
                          <SortableHeader label="Toplam İşletme" sortKey="business_count" currentSort={sort} currentDir={sortDir} href={createSortHref('business_count')} />
                          <SortableHeader label="Aktif" sortKey="active_count" currentSort={sort} currentDir={sortDir} href={createSortHref('active_count')} />
                          <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Pasif</th>
                          <SortableHeader label="Aktiflik Oranı" sortKey="aktiflik" currentSort={sort} currentDir={sortDir} href={createSortHref('aktiflik')} />
                          {viewKey === 'cities' && <SortableHeader label="İlçe Sayısı" sortKey="district_count" currentSort={sort} currentDir={sortDir} href={createSortHref('district_count')} />}
                          <th className="px-5 py-3 text-right text-[11px] font-extrabold uppercase tracking-wide text-muted">İşlemler</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-border">
                        {viewKey === 'cities' ? pageIlRows.map((r) => (
                          <tr key={r.name} className="hover:bg-black/2">
                            <td className="px-5 py-3 font-bold text-textStrong">{r.name}</td>
                            <td className="px-5 py-3 font-extrabold text-textStrong">{r.businessCount.toLocaleString('tr-TR')}</td>
                            <td className="px-5 py-3 text-emerald-700">{r.activeCount.toLocaleString('tr-TR')}</td>
                            <td className="px-5 py-3 text-muted">{(r.businessCount - r.activeCount).toLocaleString('tr-TR')}</td>
                            <td className="px-5 py-3"><OranBar oran={aktiflikOrani(r.businessCount, r.activeCount)} /></td>
                            <td className="px-5 py-3 text-muted">{r.districtCount.toLocaleString('tr-TR')}</td>
                            <td className="px-5 py-3 text-right">
                              <Link href={`/yonetici/isletmeler?city=${encodeURIComponent(r.name)}`} className="text-xs font-bold text-primary hover:underline">İşletmeler</Link>
                            </td>
                          </tr>
                        )) : pageIlceRows.map((r) => (
                          <tr key={`${r.city}:${r.district}`} className="hover:bg-black/2">
                            <td className="px-5 py-3 font-bold text-textStrong">{r.district}</td>
                            <td className="px-5 py-3 text-muted">{r.city}</td>
                            <td className="px-5 py-3 font-extrabold text-textStrong">{r.businessCount.toLocaleString('tr-TR')}</td>
                            <td className="px-5 py-3 text-emerald-700">{r.activeCount.toLocaleString('tr-TR')}</td>
                            <td className="px-5 py-3 text-muted">{(r.businessCount - r.activeCount).toLocaleString('tr-TR')}</td>
                            <td className="px-5 py-3"><OranBar oran={aktiflikOrani(r.businessCount, r.activeCount)} /></td>
                            <td className="px-5 py-3 text-right">
                              <Link href={`/yonetici/isletmeler?city=${encodeURIComponent(r.city)}&district=${encodeURIComponent(r.district)}`} className="text-xs font-bold text-primary hover:underline">İşletmeler</Link>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>

                  <div className="flex flex-wrap items-center justify-between gap-3 border-t border-border px-5 py-3">
                    <span className="text-xs text-muted">Toplam {activeRows.length.toLocaleString('tr-TR')} {viewKey === 'districts' ? 'ilçe' : 'il'}</span>
                    <div className="flex items-center gap-3">
                      {totalPages > 1 && (
                        <div className="flex items-center gap-1">
                          {pageNum > 1 && <a href={pageHref(pageNum - 1)} className="rounded-lg border border-border px-3 py-1.5 text-xs font-bold hover:bg-black/4">←</a>}
                          <span className="px-2 text-xs font-bold text-muted">Sayfa {pageNum} / {totalPages}</span>
                          {pageNum < totalPages && <a href={pageHref(pageNum + 1)} className="rounded-lg border border-border px-3 py-1.5 text-xs font-bold hover:bg-black/4">→</a>}
                        </div>
                      )}
                      <form method="get">
                        <input type="hidden" name="view" value={viewKey} />
                        <input type="hidden" name="q" value={q} />
                        <input type="hidden" name="bolge" value={bolge} />
                        <input type="hidden" name="sort" value={sort} />
                        <input type="hidden" name="dir" value={sortDir} />
                        <input type="hidden" name="page" value="1" />
                        <SayfaBoyutuSecici options={PAGE_SIZE_OPTIONS} value={pageSize} />
                      </form>
                    </div>
                  </div>
                </PanelBolumKarti>
              )}

              {viewKey === 'cities' && (
                <PanelBolumKarti title="İl Dağılımı (İlk 10)">
                  <IlDagilimiBarChart rows={top10} />
                </PanelBolumKarti>
              )}
            </div>

            <div className="flex flex-col gap-4">
              <PanelBolumKarti title="Türkiye Genel Dağılımı">
                <TurkiyeHaritasi rows={provinceRows} />
              </PanelBolumKarti>

              <PanelBolumKarti title="Duruma Göre Dağılım">
                {donutToplam === 0 ? <p className="text-xs text-muted">Veri yok.</p> : <DurumDonut veriler={donutVerisi} toplam={donutToplam} />}
              </PanelBolumKarti>

              <PanelBolumKarti title="Hızlı İstatistikler">
                <div className="flex flex-col gap-3">
                  {enCok && (
                    <HizliIstatistik label="En Çok İşletme" isim={enCok.name} deger={enCok.businessCount.toLocaleString('tr-TR')} tone="blue" />
                  )}
                  {enYuksekOran && (
                    <HizliIstatistik label="En Yüksek Aktiflik Oranı" isim={enYuksekOran.name} deger={`%${aktiflikOrani(enYuksekOran.businessCount, enYuksekOran.activeCount)}`} tone="green" />
                  )}
                  {enDusukOran && (
                    <HizliIstatistik label="En Düşük Aktiflik Oranı" isim={enDusukOran.name} deger={`%${aktiflikOrani(enDusukOran.businessCount, enDusukOran.activeCount)}`} tone="orange" />
                  )}
                  <HizliIstatistik label="Konumsuz İşletme" isim="Şehir bilgisi eksik" deger={konumsuzIsletme.toLocaleString('tr-TR')} tone="pink" />
                </div>
              </PanelBolumKarti>

              <PanelBolumKarti title="Bilgilendirme">
                <ul className="flex flex-col gap-2 text-xs text-muted">
                  <li>• İl eşleştirmesi işletmenin serbest metin şehir alanı ile gerçek il sınırlarının normalize edilmiş adı karşılaştırılarak yapılır.</li>
                  <li>• {eslesmeyenIsletme.toLocaleString('tr-TR')} işletmenin şehir alanı dolu ama hiçbir ile eşleşmedi (çoğunlukla il yerine ilçe/kasaba adı girilmiş) — bunlar harita ve il tablosuna dahil değildir.</li>
                  <li>• Konumsuz {konumsuzIsletme.toLocaleString('tr-TR')} işletmenin şehir alanı tamamen boş.</li>
                </ul>
              </PanelBolumKarti>
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

// ─── Bileşenler ───────────────────────────────────────────────────────────────

function ViewToggle({ viewKey, q }: { viewKey: ViewKey; q: string }) {
  const tabs = [
    { value: 'cities', label: 'İl Bazında' },
    { value: 'districts', label: 'İlçe Bazında' },
    { value: 'kalite', label: 'Veri Kalitesi' },
  ] as const;

  return (
    <div className="flex gap-2">
      {tabs.map(({ value, label }) => (
        <a
          key={value}
          href={`?view=${value}&q=${encodeURIComponent(q)}&page=1`}
          className={`rounded-lg px-3 py-1.5 text-xs font-bold transition-colors ${viewKey === value ? 'bg-primary text-white' : 'border border-border bg-card text-muted hover:text-textStrong'}`}
        >
          {label}
        </a>
      ))}
    </div>
  );
}

type MetrikRenk = 'yesil' | 'sari' | 'kirmizi' | 'neutral';

function MetrikKarti({ label, deger, renk, href, aktif }: { label: string; deger: number; renk: MetrikRenk; href: string; aktif: boolean }) {
  const renkSinifi: Record<MetrikRenk, string> = { yesil: 'text-emerald-700', sari: 'text-amber-600', kirmizi: 'text-rose-600', neutral: 'text-textStrong' };
  const bgSinifi: Record<MetrikRenk, string> = { yesil: 'bg-emerald-50', sari: 'bg-amber-50', kirmizi: 'bg-rose-50', neutral: 'bg-card' };

  return (
    <a href={href} className={`flex flex-col gap-1 rounded-2xl border px-4 py-4 transition-shadow hover:shadow-xs ${aktif ? 'border-primary ring-1 ring-primary/30' : 'border-border'} ${bgSinifi[renk]}`}>
      <span className="text-xs font-bold text-muted">{label}</span>
      <span className={`text-2xl font-black ${renkSinifi[renk]}`}>{deger.toLocaleString('tr-TR')}</span>
    </a>
  );
}

function KonumDurumBadge({ value, label }: { value: boolean; label: string }) {
  return (
    <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-[10px] font-extrabold ${value ? 'bg-emerald-50 text-emerald-700' : 'bg-rose-50 text-rose-700'}`}>
      {value ? label : `${label} eksik`}
    </span>
  );
}

function KonumSatiri({ item }: { item: KonumIsletme }) {
  return (
    <tr className="hover:bg-black/2">
      <td className="px-5 py-3">
        <span className="font-bold text-textStrong">{item.name}</span>
        {item.category && <span className="ml-2 text-xs text-muted">{item.category}</span>}
      </td>
      <td className="px-5 py-3">
        <div className="flex flex-wrap gap-1">
          <KonumDurumBadge value={item.has_city} label={item.city ?? 'Şehir'} />
          <KonumDurumBadge value={item.has_district} label={item.district ?? 'İlçe'} />
        </div>
      </td>
      <td className="px-5 py-3">
        {item.has_coords ? (
          <span className="font-mono text-xs text-muted">{item.lat?.toFixed(4)}, {item.lng?.toFixed(4)}</span>
        ) : (
          <span className="rounded-full bg-rose-50 px-2 py-0.5 text-[10px] font-extrabold text-rose-700">Koordinat eksik</span>
        )}
      </td>
      <td className="px-5 py-3">
        <div className="flex flex-wrap gap-1">
          {item.has_slugs ? (
            <span className="rounded-full bg-emerald-50 px-2 py-0.5 text-[10px] font-extrabold text-emerald-700">Tam</span>
          ) : (
            <>
              {!item.city_slug && <span className="rounded-full bg-amber-50 px-2 py-0.5 text-[10px] font-extrabold text-amber-700">city_slug eksik</span>}
              {!item.district_slug && <span className="rounded-full bg-amber-50 px-2 py-0.5 text-[10px] font-extrabold text-amber-700">district_slug eksik</span>}
              {!item.category_slug && <span className="rounded-full bg-amber-50 px-2 py-0.5 text-[10px] font-extrabold text-amber-700">category_slug eksik</span>}
            </>
          )}
        </div>
      </td>
      <td className="px-5 py-3">
        <div className="flex flex-wrap gap-1">
          <span className={`rounded-full px-2 py-0.5 text-[10px] font-extrabold ${item.is_active ? 'bg-emerald-50 text-emerald-700' : 'bg-slate-100 text-slate-500'}`}>
            {item.is_active ? 'Aktif' : 'Pasif'}
          </span>
          {item.is_verified && <span className="rounded-full bg-blue-50 px-2 py-0.5 text-[10px] font-extrabold text-blue-700">Onaylı</span>}
        </div>
      </td>
      <td className="px-5 py-3">
        <a href={`/yonetici/isletmeler?q=${encodeURIComponent(item.name)}`} className="text-xs font-bold text-primary hover:underline">Detay</a>
      </td>
    </tr>
  );
}

function SortableHeader({ label, sortKey, currentSort, currentDir, href }: { label: string; sortKey: string; currentSort: string; currentDir: SortDir; href: string }) {
  const active = currentSort === sortKey;
  const marker = active ? (currentDir === 'asc' ? '↑' : '↓') : '↕';
  return (
    <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">
      <a href={href} className="inline-flex items-center gap-1.5 hover:text-textStrong">
        <span>{label}</span>
        <span aria-hidden="true" className={active ? 'text-primary' : 'text-muted'}>{marker}</span>
      </a>
    </th>
  );
}

function OranBar({ oran }: { oran: number }) {
  return (
    <div className="flex items-center gap-2">
      <span className="w-9 text-xs font-extrabold text-textStrong">%{oran}</span>
      <div className="h-1.5 w-16 overflow-hidden rounded-full bg-black/8">
        <div className="h-full rounded-full bg-emerald-500" style={{ width: `${oran}%` }} />
      </div>
    </div>
  );
}

function HizliIstatistik({ label, isim, deger, tone }: { label: string; isim: string; deger: string; tone: 'blue' | 'green' | 'orange' | 'pink' }) {
  const toneClasses: Record<string, string> = { blue: 'bg-blue-50 text-blue-600', green: 'bg-emerald-50 text-emerald-600', orange: 'bg-amber-50 text-amber-600', pink: 'bg-rose-50 text-rose-600' };
  return (
    <div className="flex items-center gap-3">
      <div className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-xl ${toneClasses[tone]}`}>
        <DotIcon />
      </div>
      <div className="min-w-0">
        <p className="text-[11px] font-bold text-muted">{label}</p>
        <p className="truncate text-sm font-extrabold text-textStrong">{isim}</p>
        <p className="text-xs font-bold text-muted">{deger}</p>
      </div>
    </div>
  );
}

function IlDagilimiBarChart({ rows }: { rows: IlSatiri[] }) {
  const maxVal = Math.max(...rows.map((r) => r.businessCount), 1);
  const H = 160;
  return (
    <div className="flex items-end gap-3 overflow-x-auto pb-1" style={{ height: H + 32 }}>
      {rows.map((r) => {
        const aktifH = (r.activeCount / maxVal) * H;
        const pasifH = ((r.businessCount - r.activeCount) / maxVal) * H;
        return (
          <div key={r.name} className="flex shrink-0 flex-col items-center gap-1.5" style={{ width: 46 }}>
            <div className="flex flex-col justify-end" style={{ height: H }}>
              <div className="w-6 rounded-t-sm bg-amber-400" style={{ height: pasifH }} title={`Pasif: ${(r.businessCount - r.activeCount).toLocaleString('tr-TR')}`} />
              <div className="w-6 bg-emerald-500" style={{ height: aktifH }} title={`Aktif: ${r.activeCount.toLocaleString('tr-TR')}`} />
            </div>
            <span className="max-w-[46px] truncate text-[10px] font-bold text-muted" title={r.name}>{r.name}</span>
          </div>
        );
      })}
    </div>
  );
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
            <circle key={label} cx={CX} cy={CY} r={R} fill="none" stroke={renk} strokeWidth={STROKE} strokeDasharray={`${uzunluklar[i]} ${CIRCUM - uzunluklar[i]}`} strokeDashoffset={-offsetler[i]} />
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

function MapPinIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z" /><circle cx="12" cy="10" r="3" /></svg>;
}
function BuildingIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="4" y="2" width="16" height="20" rx="1" /><line x1="9" y1="6" x2="9" y2="6.01" /><line x1="15" y1="6" x2="15" y2="6.01" /><line x1="9" y1="10" x2="9" y2="10.01" /><line x1="15" y1="10" x2="15" y2="10.01" /><line x1="9" y1="14" x2="9" y2="14.01" /><line x1="15" y1="14" x2="15" y2="14.01" /></svg>; }
function CheckIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="9" /><path d="m8 12 3 3 5-6" /></svg>; }
function PauseIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="9" /><line x1="10" y1="9" x2="10" y2="15" /><line x1="14" y1="9" x2="14" y2="15" /></svg>; }
function ShieldIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" /></svg>; }
function MapIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polygon points="1 6 1 22 8 18 16 22 23 18 23 2 16 6 8 2 1 6" /><line x1="8" y1="2" x2="8" y2="18" /><line x1="16" y1="6" x2="16" y2="22" /></svg>; }
function PinIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10" /><circle cx="12" cy="12" r="3" /></svg>; }
function DotIcon() { return <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><circle cx="12" cy="12" r="6" /></svg>; }
