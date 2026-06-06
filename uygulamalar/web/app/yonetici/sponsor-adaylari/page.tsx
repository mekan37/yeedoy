import type { Metadata } from 'next';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { markLeadContacted } from './sponsor-aday-islemleri';
import { closeLeadAction } from './sponsor-aday-kapat-islemi';
import {
  listAdminSponsorLeads,
  LEAD_STATUS_LABELS,
  LEAD_STATUS_STYLES,
} from '@/src/lib/veri/admin/sponsorluk';
import { maskPhone, maskMessage } from '@/src/lib/gizlilik/pii-mask';

export const metadata: Metadata = {
  title: 'Sponsor Adaylari | Yonetici Paneli',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ status?: string }> };

const SURFACE_LABELS: Record<string, string> = {
  discovery: 'Kesif',
  business_page: 'Isletme Sayfasi',
  stories: 'Hikayeler',
  verified: 'Dogrulanmis',
  premium: 'Premium',
};

const STATUS_TABS = [
  { v: 'new', l: 'Yeni' },
  { v: 'contacted', l: 'Iletisim Kuruldu' },
  { v: 'closed', l: 'Kapatildi' },
  { v: 'all', l: 'Tumu' },
];

export default async function AdminSponsorLeadsPage({ searchParams }: Props) {
  const { status = 'new' } = await searchParams;

  const list = await listAdminSponsorLeads(status, 100);

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Admin"
        title="Sponsor Adaylari"
        description={`${list.length.toLocaleString('tr-TR')} basvuru`}
      />
      <PanelIcerikYuzeyi className="pt-6">
        {/* Durum filtresi */}
        <form method="get" className="mb-4 flex flex-wrap gap-2">
          {STATUS_TABS.map(({ v, l }) => (
            <button
              key={v}
              type="submit"
              name="status"
              value={v}
              className={`rounded-lg px-3 py-1.5 text-xs font-[700] transition-colors ${
                status === v ? 'bg-primary text-white' : 'border border-border bg-card text-muted hover:text-textStrong'
              }`}
            >
              {l}
            </button>
          ))}
        </form>

        {list.length === 0 ? (
          <PanelEmptyState
            icon={<UserPlusIcon />}
            title="Aday bulunamadi"
            description="Secili filtre icin kayit yok."
          />
        ) : (
          <PanelBolumKarti noPadding>
            <div className="divide-y divide-border">
              {list.map((l) => (
                <div key={l.lead_id} className="flex items-start gap-4 px-5 py-4">
                  {/* Icerik */}
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 flex-wrap">
                      <p className="font-[800] text-textStrong truncate">{l.business_name || '—'}</p>
                      {l.preferred_surface && (
                        <span className="shrink-0 rounded-md bg-primary/8 px-1.5 py-0.5 text-[10px] font-[800] text-primary">
                          {SURFACE_LABELS[l.preferred_surface] ?? l.preferred_surface}
                        </span>
                      )}
                    </div>
                    <p className="mt-0.5 text-xs text-muted">
                      {l.city && <span className="mr-2">{l.city}</span>}
                      {l.district && <span className="mr-2">{l.district}</span>}
                      {l.phone && <span className="font-[700]">{maskPhone(l.phone)}</span>}
                    </p>
                    {l.message && (
                      <p className="mt-1.5 text-sm text-muted line-clamp-2">{maskMessage(l.message)}</p>
                    )}
                    <p className="mt-1 text-[11px] text-muted">
                      {new Date(l.created_at).toLocaleDateString('tr-TR', {
                        day: 'numeric',
                        month: 'long',
                        year: 'numeric',
                      })}
                    </p>
                  </div>

                  {/* Durum + Eylemler */}
                  <div className="flex shrink-0 items-center gap-2 flex-wrap justify-end">
                    <span
                      className={`rounded-full px-2.5 py-1 text-[10px] font-[800] ${
                        LEAD_STATUS_STYLES[l.status] ?? 'bg-zinc-100 text-zinc-600'
                      }`}
                    >
                      {LEAD_STATUS_LABELS[l.status] ?? l.status}
                    </span>

                    {l.status === 'new' && (
                      <form action={markLeadContacted}>
                        <input type="hidden" name="id" value={l.lead_id} />
                        <input type="hidden" name="currentStatus" value={status} />
                        <button
                          type="submit"
                          className="rounded-lg border border-border px-3 py-1.5 text-xs font-[700] text-textStrong hover:bg-black/[0.04]"
                        >
                          Iletisim Kuruldu
                        </button>
                      </form>
                    )}

                    {(l.status === 'new' || l.status === 'contacted') && (
                      <form action={closeLeadAction}>
                        <input type="hidden" name="id" value={l.lead_id} />
                        <input type="hidden" name="currentStatus" value={status} />
                        <button
                          type="submit"
                          className="rounded-lg border border-border px-3 py-1.5 text-xs font-[700] text-muted hover:bg-red-50 hover:text-red-700 hover:border-red-200 transition-colors"
                        >
                          Kapat
                        </button>
                      </form>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </PanelBolumKarti>
        )}
      </PanelIcerikYuzeyi>
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
      <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" />
      <circle cx="9" cy="7" r="4" />
      <line x1="19" y1="8" x2="19" y2="14" />
      <line x1="22" y1="11" x2="16" y2="11" />
    </svg>
  );
}
