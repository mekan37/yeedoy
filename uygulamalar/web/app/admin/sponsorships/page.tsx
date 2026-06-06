import type { Metadata } from 'next';
import Link from 'next/link';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';
import {
  getAdminSponsorshipSummary,
  listAdminSponsorships,
  SPONSORSHIP_STATUS_LABELS,
  SPONSORSHIP_STATUS_STYLES,
} from '@/src/lib/veri/admin/sponsorluk';

export const metadata: Metadata = {
  title: 'Sponsorluklar | Admin Panel',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ status?: string; surface?: string }> };

const SURFACE_LABELS: Record<string, string> = {
  discovery: 'Keşif',
  business_page: 'İşletme Sayfası',
  stories: 'Hikayeler',
  verified: 'Doğrulanmış',
  premium: 'Premium',
};

export default async function AdminSponsorshipsPage({ searchParams }: Props) {
  const { status = 'all', surface = 'all' } = await searchParams;

  const [summary, list] = await Promise.all([
    getAdminSponsorshipSummary(),
    listAdminSponsorships(status, surface, 100),
  ]);

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Admin"
        title="Sponsorluklar"
        description={`${list.length.toLocaleString('tr-TR')} sponsorluk anlaşması`}
      />
      <PanelContentSurface className="pt-6">
        {/* KPI özet kartları */}
        <div className="mb-5 grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-6">
          {[
            { label: 'Aktif', value: summary.active_sponsorships, cls: 'text-green-700 bg-green-50' },
            { label: 'Bekleyen', value: summary.pending_sponsorships, cls: 'text-amber-700 bg-amber-50' },
            { label: 'Açık Aday', value: summary.open_leads, cls: 'text-primary bg-primary/10' },
            {
              label: 'Gösterim (30g)',
              value: summary.impressions_30d.toLocaleString('tr-TR'),
              cls: 'text-blue-700 bg-blue-50',
            },
            {
              label: 'Tekil Kullanıcı',
              value: summary.unique_users_30d.toLocaleString('tr-TR'),
              cls: 'text-purple-700 bg-purple-50',
            },
            {
              label: 'Est. Gelir',
              value:
                summary.estimated_active_revenue_cents > 0
                  ? new Intl.NumberFormat('tr-TR', {
                      style: 'currency',
                      currency: 'TRY',
                      minimumFractionDigits: 0,
                    }).format(summary.estimated_active_revenue_cents / 100)
                  : '—',
              cls: 'text-green-800 bg-green-50',
            },
          ].map(({ label, value, cls }) => (
            <div key={label} className="rounded-xl border border-border bg-card p-4">
              <p className="text-xs font-[800] text-muted">{label}</p>
              <p className={`mt-1 inline-block rounded-lg px-2 py-0.5 text-lg font-[900] ${cls}`}>
                {value}
              </p>
            </div>
          ))}
        </div>

        {/* Hızlı erişim */}
        <div className="mb-5 flex flex-wrap gap-2">
          <Link
            href="/admin/sponsorship-leads"
            className="rounded-lg border border-border bg-card px-4 py-2 text-sm font-[700] text-textStrong transition-colors hover:border-primary/30 hover:bg-black/[0.02]"
          >
            Adaylar ({summary.open_leads} açık) →
          </Link>
          <Link
            href="/admin/sponsorship-packages"
            className="rounded-lg border border-border bg-card px-4 py-2 text-sm font-[700] text-textStrong transition-colors hover:border-primary/30 hover:bg-black/[0.02]"
          >
            Paketleri Yön. →
          </Link>
        </div>

        {/* Durum filtresi */}
        <div className="mb-4 flex flex-wrap gap-3">
          <form method="get" className="flex flex-wrap gap-2">
            <input type="hidden" name="surface" value={surface} />
            {[
              { v: 'all', l: 'Tümü' },
              { v: 'active', l: 'Aktif' },
              { v: 'pending', l: 'Bekleyen' },
              { v: 'paused', l: 'Duraklatıldı' },
              { v: 'ended', l: 'Sona Erdi' },
            ].map(({ v, l }) => (
              <button
                key={v}
                type="submit"
                name="status"
                value={v}
                className={`rounded-lg px-3 py-1.5 text-xs font-[700] transition-colors ${
                  status === v
                    ? 'bg-primary text-white'
                    : 'border border-border bg-card text-muted hover:text-textStrong'
                }`}
              >
                {l}
              </button>
            ))}
          </form>

          {/* Yüzey filtresi */}
          <form method="get" className="flex flex-wrap gap-2">
            <input type="hidden" name="status" value={status} />
            {[
              { v: 'all', l: 'Tüm Yüzeyler' },
              { v: 'discovery', l: 'Keşif' },
              { v: 'business_page', l: 'İşletme' },
              { v: 'stories', l: 'Hikayeler' },
              { v: 'verified', l: 'Doğrulanmış' },
              { v: 'premium', l: 'Premium' },
            ].map(({ v, l }) => (
              <button
                key={v}
                type="submit"
                name="surface"
                value={v}
                className={`rounded-lg px-3 py-1.5 text-xs font-[700] transition-colors ${
                  surface === v
                    ? 'bg-zinc-700 text-white'
                    : 'border border-border bg-card text-muted hover:text-textStrong'
                }`}
              >
                {l}
              </button>
            ))}
          </form>
        </div>

        {list.length === 0 ? (
          <PanelEmptyState
            icon={<StarIcon />}
            title="Sponsorluk bulunamadı"
            description="Seçili filtre için kayıt yok."
          />
        ) : (
          <PanelSectionCard noPadding>
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-border text-left">
                    {['İşletme', 'Paket', 'Yüzey', 'Başlangıç', 'Bitiş', 'Günlük Kap', 'Durum'].map(
                      (h) => (
                        <th
                          key={h}
                          className="whitespace-nowrap px-4 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted"
                        >
                          {h}
                        </th>
                      ),
                    )}
                  </tr>
                </thead>
                <tbody className="divide-y divide-border">
                  {list.map((s) => (
                    <tr key={s.sponsorship_id} className="hover:bg-black/[0.01]">
                      <td className="px-4 py-3">
                        <p className="font-[700] text-textStrong">{s.business_name || '—'}</p>
                        <p className="text-xs text-muted">{s.city || ''}</p>
                      </td>
                      <td className="px-4 py-3 text-sm text-muted">
                        {s.package_id ? s.package_id.slice(0, 8) + '…' : '—'}
                      </td>
                      <td className="px-4 py-3">
                        <span className="rounded-full bg-border/40 px-2 py-0.5 text-[10px] font-[700] capitalize text-muted">
                          {SURFACE_LABELS[s.surface] ?? s.surface}
                        </span>
                      </td>
                      <td className="whitespace-nowrap px-4 py-3 text-xs text-muted">
                        {s.starts_at ? new Date(s.starts_at).toLocaleDateString('tr-TR') : '—'}
                      </td>
                      <td className="whitespace-nowrap px-4 py-3 text-xs text-muted">
                        {s.ends_at ? new Date(s.ends_at).toLocaleDateString('tr-TR') : '—'}
                      </td>
                      <td className="px-4 py-3 text-xs text-muted">{s.daily_cap ?? '∞'}</td>
                      <td className="px-4 py-3">
                        <span
                          className={`rounded-full px-2 py-0.5 text-[10px] font-[800] ${
                            SPONSORSHIP_STATUS_STYLES[s.status] ?? 'bg-zinc-100 text-zinc-600'
                          }`}
                        >
                          {SPONSORSHIP_STATUS_LABELS[s.status] ?? s.status}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </PanelSectionCard>
        )}
      </PanelContentSurface>
    </div>
  );
}

function StarIcon() {
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
      <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
    </svg>
  );
}
