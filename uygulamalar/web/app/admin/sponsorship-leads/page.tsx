import type { Metadata } from 'next';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';
import {
  listAdminSponsorLeads,
  LEAD_STATUS_LABELS,
  LEAD_STATUS_STYLES,
} from '@/src/lib/veri/admin/sponsorluk';
import { markLeadContactedAdmin, closeLeadAdmin } from './actions';

export const metadata: Metadata = {
  title: 'Sponsor Adayları | Admin Panel',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ status?: string }> };

/** PII maskeleme: telefon numarasının son iki hanesi hariç tümü gizlenir. */
function maskPhone(phone: string): string {
  const digits = phone.replace(/\D/g, '');
  if (digits.length < 4) return '****';
  const visible = digits.slice(-2);
  return phone.slice(0, 3) + ' *** *** **' + visible;
}

const SURFACE_LABELS: Record<string, string> = {
  discovery: 'Keşif',
  business_page: 'İşletme Sayfası',
  stories: 'Hikayeler',
  verified: 'Doğrulanmış',
  premium: 'Premium',
};

const STATUS_TABS = [
  { v: 'new', l: 'Yeni' },
  { v: 'contacted', l: 'İletişim Kuruldu' },
  { v: 'closed', l: 'Kapatıldı' },
  { v: 'all', l: 'Tümü' },
];

export default async function AdminSponsorshipLeadsPage({ searchParams }: Props) {
  const { status = 'new' } = await searchParams;

  const list = await listAdminSponsorLeads(status, 100);

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Admin"
        title="Sponsor Adayları"
        description={`${list.length.toLocaleString('tr-TR')} başvuru`}
      />
      <PanelContentSurface className="pt-6">
        {/* Durum filtresi */}
        <form method="get" className="mb-4 flex flex-wrap gap-2">
          {STATUS_TABS.map(({ v, l }) => (
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

        {list.length === 0 ? (
          <PanelEmptyState
            icon={<UserPlusIcon />}
            title="Aday bulunamadı"
            description="Seçili filtre için kayıt yok."
          />
        ) : (
          <PanelSectionCard noPadding>
            <div className="divide-y divide-border">
              {list.map((lead) => (
                <div key={lead.lead_id} className="flex items-start gap-4 px-5 py-4">
                  <div className="min-w-0 flex-1">
                    <div className="flex flex-wrap items-center gap-2">
                      <p className="truncate font-[800] text-textStrong">
                        {lead.business_name || '—'}
                      </p>
                      {lead.preferred_surface && (
                        <span className="shrink-0 rounded-md bg-primary/10 px-1.5 py-0.5 text-[10px] font-[800] text-primary">
                          {SURFACE_LABELS[lead.preferred_surface] ?? lead.preferred_surface}
                        </span>
                      )}
                    </div>
                    <p className="mt-0.5 text-xs text-muted">
                      {lead.city && <span className="mr-2">{lead.city}</span>}
                      {lead.district && <span className="mr-2">{lead.district}</span>}
                      {/* PII: telefon maskelendi */}
                      {lead.phone && (
                        <span className="font-[700]">{maskPhone(lead.phone)}</span>
                      )}
                    </p>
                    {lead.message && (
                      <p className="mt-1.5 line-clamp-2 text-sm text-muted">{lead.message}</p>
                    )}
                    <p className="mt-1 text-[11px] text-muted">
                      {new Date(lead.created_at).toLocaleDateString('tr-TR', {
                        day: 'numeric',
                        month: 'long',
                        year: 'numeric',
                      })}
                    </p>
                  </div>

                  {/* Durum + Eylemler */}
                  <div className="flex shrink-0 flex-wrap items-center justify-end gap-2">
                    <span
                      className={`rounded-full px-2.5 py-1 text-[10px] font-[800] ${
                        LEAD_STATUS_STYLES[lead.status] ?? 'bg-zinc-100 text-zinc-600'
                      }`}
                    >
                      {LEAD_STATUS_LABELS[lead.status] ?? lead.status}
                    </span>

                    {lead.status === 'new' && (
                      <form action={markLeadContactedAdmin}>
                        <input type="hidden" name="id" value={lead.lead_id} />
                        <input type="hidden" name="currentStatus" value={status} />
                        <button
                          type="submit"
                          className="rounded-lg border border-border px-3 py-1.5 text-xs font-[700] text-textStrong hover:bg-black/[0.04]"
                        >
                          İletişim Kuruldu
                        </button>
                      </form>
                    )}

                    {(lead.status === 'new' || lead.status === 'contacted') && (
                      <form action={closeLeadAdmin}>
                        <input type="hidden" name="id" value={lead.lead_id} />
                        <input type="hidden" name="currentStatus" value={status} />
                        <button
                          type="submit"
                          className="rounded-lg border border-border px-3 py-1.5 text-xs font-[700] text-muted transition-colors hover:border-red-200 hover:bg-red-50 hover:text-red-700"
                        >
                          Kapat
                        </button>
                      </form>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </PanelSectionCard>
        )}
      </PanelContentSurface>
    </div>
  );
}

function UserPlusIcon() {
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
      <path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
      <circle cx="8.5" cy="7" r="4" />
      <line x1="20" y1="8" x2="20" y2="14" />
      <line x1="23" y1="11" x2="17" y2="11" />
    </svg>
  );
}
