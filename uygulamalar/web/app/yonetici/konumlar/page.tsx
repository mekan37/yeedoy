import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { createSupabaseServiceClient } from '@/src/lib/taban/hizmet';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import {
  adminKonumlariGetir,
  adminKonumOzetiniGetir,
  type KonumIsletme,
} from '@/src/lib/veri/admin/konumlar';

export const metadata: Metadata = {
  title: 'Konumlar | Yonetici Paneli',
  robots: { index: false, follow: false },
};

// ─── Sabitler ─────────────────────────────────────────────────────────────────

const PAGE_SIZE = 40;
const BUSINESS_LIMIT = 5000;
const SORT_KEYS = ['name', 'city', 'business_count', 'active_count', 'verified_count', 'district_count'] as const;

type ViewKey = 'cities' | 'districts' | 'kalite';
type SortKey = (typeof SORT_KEYS)[number];
type SortDir = 'asc' | 'desc';

type BusinessLocationRow = {
  city: string | null;
  district: string | null;
  is_active: boolean | null;
  is_verified: boolean | null;
};

type LocationSummaryRow = {
  id: string;
  name: string;
  city: string | null;
  business_count: number;
  active_count: number;
  verified_count: number;
  district_count: number;
};

// ─── Sayfa Props ──────────────────────────────────────────────────────────────

type Props = {
  searchParams: Promise<{
    q?: string;
    view?: string;
    page?: string;
    sort?: string;
    dir?: string;
    eksik?: string;
  }>;
};

// ─── Page ─────────────────────────────────────────────────────────────────────

export default async function AdminLocationsPage({ searchParams }: Props) {
  const {
    q = '',
    view = 'cities',
    page = '1',
    sort = 'business_count',
    dir = 'desc',
    eksik = '',
  } = await searchParams;

  const viewKey: ViewKey =
    view === 'districts' ? 'districts' : view === 'kalite' ? 'kalite' : 'cities';
  const sortKey = parseSortKey(sort);
  const sortDir: SortDir = dir === 'asc' ? 'asc' : 'desc';
  const pageNum = Math.max(1, parseInt(page, 10));
  const offset = (pageNum - 1) * PAGE_SIZE;

  // ── Veri Kalitesi görünümü ────────────────────────────────────────────────
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
        limit: PAGE_SIZE,
        offset,
      }),
    ]);

    const totalPages = Math.ceil(kaliteResult.total / PAGE_SIZE);
    const kalitePageHref = (nextPage: number) =>
      `?view=kalite&q=${encodeURIComponent(q)}&eksik=${eksik}&page=${nextPage}`;

    return (
      <div className="flex flex-col">
        <PanelSayfaBasligi
          eyebrow="Yönetici"
          title="Konumlar"
          description={`${ozet.toplam.toLocaleString('tr-TR')} işletme · veri kalitesi görünümü`}
        />
        <PanelIcerikYuzeyi className="pt-6">
          <div className="flex flex-col gap-6">
            {/* Görünüm seçici */}
            <ViewToggle viewKey={viewKey} q={q} />

            {/* Özet metrik kartları */}
            <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-5">
              <MetrikKarti
                label="Toplam"
                deger={ozet.toplam}
                renk="neutral"
                href="?view=kalite"
                aktif={eksik === ''}
              />
              <MetrikKarti
                label="Koordinatsız"
                deger={ozet.koordinatsiz}
                renk={ozet.koordinatsiz > 0 ? 'kirmizi' : 'yesil'}
                href="?view=kalite&eksik=koordinat"
                aktif={eksik === 'koordinat'}
              />
              <MetrikKarti
                label="Şehirsiz"
                deger={ozet.sehirsiz}
                renk={ozet.sehirsiz > 0 ? 'kirmizi' : 'yesil'}
                href="?view=kalite&eksik=konum"
                aktif={eksik === 'konum'}
              />
              <MetrikKarti
                label="İlçesiz"
                deger={ozet.ilcesiz}
                renk={ozet.ilcesiz > 0 ? 'sari' : 'yesil'}
                href="?view=kalite&eksik=konum"
                aktif={false}
              />
              <MetrikKarti
                label="Slugsuz"
                deger={ozet.slugsuz}
                renk={ozet.slugsuz > 0 ? 'sari' : 'yesil'}
                href="?view=kalite&eksik=slug"
                aktif={eksik === 'slug'}
              />
            </div>

            {/* Filtre araması */}
            <div className="flex flex-wrap items-center gap-3">
              <form method="get" className="flex gap-2">
                <input type="hidden" name="view" value="kalite" />
                <input type="hidden" name="eksik" value={eksik} />
                <input type="hidden" name="page" value="1" />
                <input
                  name="q"
                  defaultValue={q}
                  placeholder="Şehir ara..."
                  className="w-64 rounded-xl border border-border bg-card px-4 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30"
                />
              </form>

              {/* Eksik filtre sekmeleri */}
              <div className="flex gap-2">
                {[
                  { value: '', label: 'Tümü' },
                  { value: 'koordinat', label: 'Koordinatsız' },
                  { value: 'konum', label: 'Şehirsiz' },
                  { value: 'slug', label: 'Slugsuz' },
                ].map(({ value, label }) => (
                  <a
                    key={value}
                    href={`?view=kalite&eksik=${value}&q=${encodeURIComponent(q)}&page=1`}
                    className={`rounded-lg px-3 py-1.5 text-xs font-bold transition-colors ${
                      eksik === value
                        ? 'bg-primary text-white'
                        : 'border border-border bg-card text-muted hover:text-textStrong'
                    }`}
                  >
                    {label}
                  </a>
                ))}
              </div>
            </div>

            {/* Tablo */}
            {kaliteResult.fetchError ? (
              <PanelEmptyState
                icon={<MapPinIcon />}
                title="Veri yüklenemedi"
                description="businesses tablosuna erişimde hata oluştu."
              />
            ) : kaliteResult.items.length === 0 ? (
              <PanelEmptyState
                icon={<MapPinIcon />}
                title="Sonuç bulunamadı"
                description="Seçili filtreye uygun işletme yok."
              />
            ) : (
              <PanelBolumKarti
                noPadding
                description={`${kaliteResult.total.toLocaleString('tr-TR')} sonuç`}
              >
                <div className="overflow-x-auto">
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="border-b border-border text-left">
                        <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">
                          İşletme
                        </th>
                        <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">
                          Şehir / İlçe
                        </th>
                        <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">
                          Koordinat
                        </th>
                        <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">
                          Slug
                        </th>
                        <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">
                          Durum
                        </th>
                        <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">
                          İşlem
                        </th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-border">
                      {kaliteResult.items.map((item) => (
                        <KonumSatiri key={item.id} item={item} />
                      ))}
                    </tbody>
                  </table>
                </div>

                {totalPages > 1 && (
                  <div className="flex items-center justify-between border-t border-border px-5 py-3">
                    <span className="text-xs text-muted">
                      Sayfa {pageNum} / {totalPages}
                    </span>
                    <div className="flex gap-2">
                      {pageNum > 1 && (
                        <a
                          href={kalitePageHref(pageNum - 1)}
                          className="rounded-lg border border-border px-3 py-1 text-xs font-bold text-textStrong hover:bg-black/2"
                        >
                          Önceki
                        </a>
                      )}
                      {pageNum < totalPages && (
                        <a
                          href={kalitePageHref(pageNum + 1)}
                          className="rounded-lg border border-border px-3 py-1 text-xs font-bold text-textStrong hover:bg-black/2"
                        >
                          Sonraki
                        </a>
                      )}
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

  // ── İl / İlçe özeti görünümü (mevcut) ────────────────────────────────────
  const supabase =
    createSupabaseServiceClient() ?? (await createSupabaseServerClient());
  const { list, count, sourceCount } = await listLocations(supabase as any, {
    q: q.trim(),
    view: viewKey as 'cities' | 'districts',
    sortKey,
    sortDir,
    offset,
  });
  const totalPages = Math.ceil(count / PAGE_SIZE);
  const createSortHref = (nextSort: SortKey) => {
    const nextDir: SortDir = sortKey === nextSort && sortDir === 'asc' ? 'desc' : 'asc';
    return `?view=${viewKey}&q=${encodeURIComponent(q)}&sort=${nextSort}&dir=${nextDir}&page=1`;
  };
  const pageHref = (nextPage: number) =>
    `?view=${viewKey}&q=${encodeURIComponent(q)}&sort=${sortKey}&dir=${sortDir}&page=${nextPage}`;

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Yönetici"
        title="Konumlar"
        description={`${count.toLocaleString('tr-TR')} kayıt · ${sourceCount.toLocaleString('tr-TR')} işletmeden üretildi`}
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-4">
          <div className="flex flex-wrap items-center gap-3">
            <ViewToggle viewKey={viewKey} q={q} />

            <form method="get" className="flex-1">
              <input type="hidden" name="view" value={viewKey} />
              <input type="hidden" name="sort" value={sortKey} />
              <input type="hidden" name="dir" value={sortDir} />
              <input type="hidden" name="page" value="1" />
              <input
                name="q"
                defaultValue={q}
                placeholder={viewKey === 'districts' ? 'İlçe veya il ara...' : 'İl ara...'}
                className="w-full max-w-sm rounded-xl border border-border bg-card px-4 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30"
              />
            </form>
          </div>

          {list.length === 0 ? (
            <PanelEmptyState
              icon={<MapPinIcon />}
              title={q ? 'Sonuç bulunamadı' : `${viewKey === 'districts' ? 'İlçe' : 'İl'} yok`}
              description="Konum listesi mevcut işletme kayıtlarındaki şehir ve ilçe bilgilerinden oluşturulur."
            />
          ) : (
            <PanelBolumKarti noPadding>
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-border text-left">
                    <SortableHeader
                      label={viewKey === 'districts' ? 'İlçe Adı' : 'İl Adı'}
                      sortKey="name"
                      currentSort={sortKey}
                      currentDir={sortDir}
                      href={createSortHref('name')}
                    />
                    {viewKey === 'districts' && (
                      <SortableHeader
                        label="İl"
                        sortKey="city"
                        currentSort={sortKey}
                        currentDir={sortDir}
                        href={createSortHref('city')}
                      />
                    )}
                    <SortableHeader
                      label="İşletme"
                      sortKey="business_count"
                      currentSort={sortKey}
                      currentDir={sortDir}
                      href={createSortHref('business_count')}
                    />
                    <SortableHeader
                      label="Aktif"
                      sortKey="active_count"
                      currentSort={sortKey}
                      currentDir={sortDir}
                      href={createSortHref('active_count')}
                    />
                    <SortableHeader
                      label="Doğrulanmış"
                      sortKey="verified_count"
                      currentSort={sortKey}
                      currentDir={sortDir}
                      href={createSortHref('verified_count')}
                    />
                    {viewKey === 'cities' && (
                      <SortableHeader
                        label="İlçe Sayısı"
                        sortKey="district_count"
                        currentSort={sortKey}
                        currentDir={sortDir}
                        href={createSortHref('district_count')}
                      />
                    )}
                  </tr>
                </thead>
                <tbody className="divide-y divide-border">
                  {list.map((loc) => (
                    <tr key={loc.id} className="hover:bg-black/2">
                      <td className="px-5 py-3 font-bold text-textStrong">{loc.name}</td>
                      {viewKey === 'districts' && (
                        <td className="px-5 py-3 text-muted">{loc.city ?? '—'}</td>
                      )}
                      <td className="px-5 py-3 font-extrabold text-textStrong">
                        {loc.business_count.toLocaleString('tr-TR')}
                      </td>
                      <td className="px-5 py-3 text-muted">
                        {loc.active_count.toLocaleString('tr-TR')}
                      </td>
                      <td className="px-5 py-3 text-muted">
                        {loc.verified_count.toLocaleString('tr-TR')}
                      </td>
                      {viewKey === 'cities' && (
                        <td className="px-5 py-3 text-muted">
                          {loc.district_count.toLocaleString('tr-TR')}
                        </td>
                      )}
                    </tr>
                  ))}
                </tbody>
              </table>

              {totalPages > 1 && (
                <div className="flex items-center justify-between border-t border-border px-5 py-3">
                  <span className="text-xs text-muted">
                    Sayfa {pageNum} / {totalPages}
                  </span>
                  <div className="flex gap-2">
                    {pageNum > 1 && (
                      <a
                        href={pageHref(pageNum - 1)}
                        className="rounded-lg border border-border px-3 py-1 text-xs font-bold text-textStrong hover:bg-black/2"
                      >
                        Önceki
                      </a>
                    )}
                    {pageNum < totalPages && (
                      <a
                        href={pageHref(pageNum + 1)}
                        className="rounded-lg border border-border px-3 py-1 text-xs font-bold text-textStrong hover:bg-black/2"
                      >
                        Sonraki
                      </a>
                    )}
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

// ─── Bileşenler ───────────────────────────────────────────────────────────────

function ViewToggle({ viewKey, q }: { viewKey: ViewKey; q: string }) {
  const tabs = [
    { value: 'cities', label: 'İller' },
    { value: 'districts', label: 'İlçeler' },
    { value: 'kalite', label: 'Veri Kalitesi' },
  ] as const;

  return (
    <div className="flex gap-2">
      {tabs.map(({ value, label }) => (
        <a
          key={value}
          href={`?view=${value}&q=${encodeURIComponent(q)}&page=1`}
          className={`rounded-lg px-3 py-1.5 text-xs font-bold transition-colors ${
            viewKey === value
              ? 'bg-primary text-white'
              : 'border border-border bg-card text-muted hover:text-textStrong'
          }`}
        >
          {label}
        </a>
      ))}
    </div>
  );
}

type MetrikRenk = 'yesil' | 'sari' | 'kirmizi' | 'neutral';

function MetrikKarti({
  label,
  deger,
  renk,
  href,
  aktif,
}: {
  label: string;
  deger: number;
  renk: MetrikRenk;
  href: string;
  aktif: boolean;
}) {
  const renkSinifi: Record<MetrikRenk, string> = {
    yesil: 'text-emerald-700',
    sari: 'text-amber-600',
    kirmizi: 'text-rose-600',
    neutral: 'text-textStrong',
  };

  const bgSinifi: Record<MetrikRenk, string> = {
    yesil: 'bg-emerald-50',
    sari: 'bg-amber-50',
    kirmizi: 'bg-rose-50',
    neutral: 'bg-card',
  };

  return (
    <a
      href={href}
      className={`flex flex-col gap-1 rounded-2xl border px-4 py-4 transition-shadow hover:shadow-xs ${
        aktif ? 'border-primary ring-1 ring-primary/30' : 'border-border'
      } ${bgSinifi[renk]}`}
    >
      <span className="text-xs font-bold text-muted">{label}</span>
      <span className={`text-2xl font-black ${renkSinifi[renk]}`}>
        {deger.toLocaleString('tr-TR')}
      </span>
    </a>
  );
}

function KonumDurumBadge({ value, label }: { value: boolean; label: string }) {
  return (
    <span
      className={`inline-flex items-center rounded-full px-2 py-0.5 text-[10px] font-extrabold ${
        value
          ? 'bg-emerald-50 text-emerald-700'
          : 'bg-rose-50 text-rose-700'
      }`}
    >
      {value ? label : `${label} eksik`}
    </span>
  );
}

function KonumSatiri({ item }: { item: KonumIsletme }) {
  return (
    <tr className="hover:bg-black/2">
      {/* İşletme adı */}
      <td className="px-5 py-3">
        <span className="font-bold text-textStrong">{item.name}</span>
        {item.category && (
          <span className="ml-2 text-xs text-muted">{item.category}</span>
        )}
      </td>

      {/* Şehir / İlçe */}
      <td className="px-5 py-3">
        <div className="flex flex-wrap gap-1">
          <KonumDurumBadge value={item.has_city} label={item.city ?? 'Şehir'} />
          <KonumDurumBadge value={item.has_district} label={item.district ?? 'İlçe'} />
        </div>
      </td>

      {/* Koordinat */}
      <td className="px-5 py-3">
        {item.has_coords ? (
          <span className="font-mono text-xs text-muted">
            {item.lat?.toFixed(4)}, {item.lng?.toFixed(4)}
          </span>
        ) : (
          <span className="rounded-full bg-rose-50 px-2 py-0.5 text-[10px] font-extrabold text-rose-700">
            Koordinat eksik
          </span>
        )}
      </td>

      {/* Slug durumu */}
      <td className="px-5 py-3">
        <div className="flex flex-wrap gap-1">
          {item.has_slugs ? (
            <span className="rounded-full bg-emerald-50 px-2 py-0.5 text-[10px] font-extrabold text-emerald-700">
              Tam
            </span>
          ) : (
            <>
              {!item.city_slug && (
                <span className="rounded-full bg-amber-50 px-2 py-0.5 text-[10px] font-extrabold text-amber-700">
                  city_slug eksik
                </span>
              )}
              {!item.district_slug && (
                <span className="rounded-full bg-amber-50 px-2 py-0.5 text-[10px] font-extrabold text-amber-700">
                  district_slug eksik
                </span>
              )}
              {!item.category_slug && (
                <span className="rounded-full bg-amber-50 px-2 py-0.5 text-[10px] font-extrabold text-amber-700">
                  category_slug eksik
                </span>
              )}
            </>
          )}
        </div>
      </td>

      {/* Aktif / Doğrulanmış */}
      <td className="px-5 py-3">
        <div className="flex flex-wrap gap-1">
          <span
            className={`rounded-full px-2 py-0.5 text-[10px] font-extrabold ${
              item.is_active
                ? 'bg-emerald-50 text-emerald-700'
                : 'bg-slate-100 text-slate-500'
            }`}
          >
            {item.is_active ? 'Aktif' : 'Pasif'}
          </span>
          {item.is_verified && (
            <span className="rounded-full bg-blue-50 px-2 py-0.5 text-[10px] font-extrabold text-blue-700">
              Onaylı
            </span>
          )}
        </div>
      </td>

      {/* Düzenle linki */}
      <td className="px-5 py-3">
        <a
          href={`/yonetici/isletmeler?q=${encodeURIComponent(item.name)}`}
          className="text-xs font-bold text-primary hover:underline"
        >
          Detay
        </a>
      </td>
    </tr>
  );
}

// ─── İl/İlçe özetleme mantığı (orijinal) ─────────────────────────────────────

async function listLocations(
  supabase: any,
  {
    q,
    view,
    sortKey,
    sortDir,
    offset,
  }: { q: string; view: 'cities' | 'districts'; sortKey: SortKey; sortDir: SortDir; offset: number },
) {
  const { data } = await supabase
    .from('businesses')
    .select('city, district, is_active, is_verified')
    .range(0, BUSINESS_LIMIT - 1);

  const rows = ((data ?? []) as BusinessLocationRow[]).filter((row) => normalizeText(row.city));
  const summaries = view === 'districts' ? summarizeDistricts(rows) : summarizeCities(rows);
  const query = normalizeSearch(q);
  const filtered = summaries
    .filter((row) => {
      if (!query) return true;
      return normalizeSearch([row.name, row.city].filter(Boolean).join(' ')).includes(query);
    })
    .sort((a, b) => compareLocations(a, b, sortKey, sortDir));

  return {
    list: filtered.slice(offset, offset + PAGE_SIZE),
    count: filtered.length,
    sourceCount: rows.length,
  };
}

function summarizeCities(rows: BusinessLocationRow[]) {
  const map = new Map<string, LocationSummaryRow & { districts: Set<string> }>();

  rows.forEach((row) => {
    const city = normalizeText(row.city);
    if (!city) return;

    const current = map.get(city) ?? {
      id: city,
      name: city,
      city: null,
      business_count: 0,
      active_count: 0,
      verified_count: 0,
      district_count: 0,
      districts: new Set<string>(),
    };

    current.business_count += 1;
    if (row.is_active) current.active_count += 1;
    if (row.is_verified) current.verified_count += 1;
    const district = normalizeText(row.district);
    if (district) current.districts.add(district);
    current.district_count = current.districts.size;
    map.set(city, current);
  });

  return Array.from(map.values()).map(({ districts: _districts, ...row }) => row);
}

function summarizeDistricts(rows: BusinessLocationRow[]) {
  const map = new Map<string, LocationSummaryRow>();

  rows.forEach((row) => {
    const city = normalizeText(row.city);
    const district = normalizeText(row.district);
    if (!city || !district) return;

    const id = `${city}:${district}`;
    const current = map.get(id) ?? {
      id,
      name: district,
      city,
      business_count: 0,
      active_count: 0,
      verified_count: 0,
      district_count: 0,
    };

    current.business_count += 1;
    if (row.is_active) current.active_count += 1;
    if (row.is_verified) current.verified_count += 1;
    map.set(id, current);
  });

  return Array.from(map.values());
}

// ─── Sıralama ─────────────────────────────────────────────────────────────────

function SortableHeader({
  label,
  sortKey,
  currentSort,
  currentDir,
  href,
}: {
  label: string;
  sortKey: SortKey;
  currentSort: SortKey;
  currentDir: SortDir;
  href: string;
}) {
  const active = currentSort === sortKey;
  const marker = active ? (currentDir === 'asc' ? '↑' : '↓') : '↕';

  return (
    <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">
      <a href={href} className="inline-flex items-center gap-1.5 hover:text-textStrong">
        <span>{label}</span>
        <span aria-hidden="true" className={active ? 'text-primary' : 'text-muted'}>
          {marker}
        </span>
      </a>
    </th>
  );
}

function parseSortKey(value: string): SortKey {
  return SORT_KEYS.includes(value as SortKey) ? (value as SortKey) : 'business_count';
}

function compareLocations(
  a: LocationSummaryRow,
  b: LocationSummaryRow,
  sortKey: SortKey,
  sortDir: SortDir,
) {
  const direction = sortDir === 'asc' ? 1 : -1;
  let result = 0;

  if (sortKey === 'name' || sortKey === 'city') {
    result = String(a[sortKey] ?? '').localeCompare(String(b[sortKey] ?? ''), 'tr');
  } else {
    result = a[sortKey] - b[sortKey];
  }

  if (result === 0) {
    result = a.name.localeCompare(b.name, 'tr');
  }

  return result * direction;
}

// ─── Yardımcı ─────────────────────────────────────────────────────────────────

function normalizeText(value: string | null | undefined) {
  return String(value ?? '').trim();
}

function normalizeSearch(value: string) {
  return value.trim().toLocaleLowerCase('tr-TR');
}

function MapPinIcon() {
  return (
    <svg
      width="20"
      height="20"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z" />
      <circle cx="12" cy="10" r="3" />
    </svg>
  );
}
