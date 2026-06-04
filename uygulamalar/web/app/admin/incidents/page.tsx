import type { Metadata } from 'next';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';
import { listAdminOlaylar, type Olay, type OlaySeverity } from '@/src/lib/veri/admin/olaylar';

export const metadata: Metadata = {
  title: 'Olay Merkezi | Admin Panel',
  robots: { index: false, follow: false },
};

// ─── Sabitler ────────────────────────────────────────────────────────────────

const PAGE_SIZE = 40;

const SEVERITY_LABELS: Record<OlaySeverity, string> = {
  low: 'Düşük',
  medium: 'Orta',
  high: 'Yüksek',
  critical: 'Kritik',
};

const SEVERITY_STYLES: Record<OlaySeverity, string> = {
  critical: 'bg-red-100 text-red-700',
  high: 'bg-orange-50 text-orange-700',
  medium: 'bg-amber-50 text-amber-700',
  low: 'bg-zinc-100 text-zinc-500',
};

/** Aksiyon kodunu okunabilir Türkçe etikete çevir */
function aksiyonEtiketi(action: string): string {
  const MAP: Record<string, string> = {
    'user.safety_action': 'Güvenlik Aksiyonu',
    'admin.impersonation.start': 'Hesap Taklit Başladı',
    'admin.impersonation.stop': 'Hesap Taklit Bitti',
    'user.anonymized': 'Kullanıcı Anonimleştirildi',
    'achievement.reset': 'Rozet Sıfırlandı',
    'business.verification_changed': 'Doğrulama Değişti',
    'admin.ban': 'Kullanıcı Banlandı',
    'admin.unban': 'Ban Kaldırıldı',
    'admin.shadow_ban': 'Gizli Ban',
    'admin.feature_flag': 'Özellik Bayrağı',
    'admin.bulk_action': 'Toplu Aksiyon',
    'admin.data_export': 'Veri Dışa Aktarım',
  };
  return MAP[action] ?? action;
}

// ─── Sayfa ───────────────────────────────────────────────────────────────────

type Props = {
  searchParams: Promise<{ severity?: string; page?: string; q?: string }>;
};

export default async function AdminIncidentsPage({ searchParams }: Props) {
  const {
    severity = 'all',
    page = '1',
    q = '',
  } = await searchParams;

  const pageNum = Math.max(1, parseInt(page, 10));
  const offset = (pageNum - 1) * PAGE_SIZE;

  const validSeverity = ['low', 'medium', 'high', 'critical', 'all'].includes(severity)
    ? (severity as OlaySeverity | 'all')
    : 'all';

  const { list, hasNextPage, fetchError } = await listAdminOlaylar({
    severity: validSeverity,
    limit: PAGE_SIZE + 1,
    offset,
    search: q || undefined,
  });

  const toplamGorunen = list.length + offset;

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Admin"
        title="Olay Merkezi"
        description={
          fetchError
            ? 'Veriye erişilemiyor'
            : `${toplamGorunen > 0 ? `${toplamGorunen}+ olay` : 'Olay yok'}`
        }
      />

      <PanelContentSurface className="pt-6">
        {fetchError ? (
          <PanelEmptyState
            icon={<AlertIcon />}
            title="Veriye erişilemiyor"
            description="Oturum süresi dolmuş olabilir veya yetki hatası oluştu."
          />
        ) : (
          <div className="flex flex-col gap-4">
            {/* Filtreler */}
            <div className="flex flex-wrap items-center gap-3">
              {/* Severity filtresi */}
              <form method="get" className="flex gap-2">
                {q && <input type="hidden" name="q" value={q} />}
                {(
                  [
                    { value: 'all', label: 'Tüm Ciddiyet' },
                    { value: 'critical', label: 'Kritik' },
                    { value: 'high', label: 'Yüksek' },
                    { value: 'medium', label: 'Orta' },
                    { value: 'low', label: 'Düşük' },
                  ] as const
                ).map(({ value, label }) => (
                  <button
                    key={value}
                    type="submit"
                    name="severity"
                    value={value}
                    className={`rounded-lg px-3 py-1.5 text-xs font-[700] transition-colors ${
                      validSeverity === value
                        ? 'bg-primary text-white'
                        : 'border border-border bg-card text-muted hover:text-textStrong'
                    }`}
                  >
                    {label}
                  </button>
                ))}
              </form>

              {/* Arama */}
              <form method="get" className="flex gap-2">
                <input type="hidden" name="severity" value={validSeverity} />
                <input
                  type="search"
                  name="q"
                  defaultValue={q}
                  placeholder="Aksiyon veya hedef ara…"
                  className="rounded-lg border border-border bg-card px-3 py-1.5 text-xs text-textStrong placeholder:text-muted focus:outline-none focus:ring-1 focus:ring-primary"
                />
                <button
                  type="submit"
                  className="rounded-lg border border-border bg-card px-3 py-1.5 text-xs font-[700] text-muted hover:text-textStrong"
                >
                  Ara
                </button>
              </form>
            </div>

            {/* Liste */}
            {list.length === 0 ? (
              <PanelEmptyState
                icon={<AlertIcon />}
                title="Olay bulunamadı"
                description="Bu filtre kombinasyonuyla kayıt yok."
              />
            ) : (
              <PanelSectionCard noPadding>
                <div className="overflow-x-auto">
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="border-b border-border text-left">
                        <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">
                          Aksiyon
                        </th>
                        <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">
                          Ciddiyet
                        </th>
                        <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">
                          Hedef Tipi
                        </th>
                        <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">
                          Admin
                        </th>
                        <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">
                          Tarih
                        </th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-border">
                      {list.map((olay: Olay) => (
                        <OlaySatiri key={olay.id} olay={olay} />
                      ))}
                    </tbody>
                  </table>
                </div>

                {/* Sayfalama */}
                <div className="flex items-center justify-between border-t border-border px-5 py-3">
                  <span className="text-xs text-muted">Sayfa {pageNum}</span>
                  <div className="flex gap-2">
                    {pageNum > 1 && (
                      <a
                        href={`?severity=${validSeverity}&page=${pageNum - 1}${q ? `&q=${encodeURIComponent(q)}` : ''}`}
                        className="rounded-lg border border-border px-3 py-1 text-xs font-[700] text-textStrong hover:bg-black/[0.02]"
                      >
                        Onceki
                      </a>
                    )}
                    {hasNextPage && (
                      <a
                        href={`?severity=${validSeverity}&page=${pageNum + 1}${q ? `&q=${encodeURIComponent(q)}` : ''}`}
                        className="rounded-lg border border-border px-3 py-1 text-xs font-[700] text-textStrong hover:bg-black/[0.02]"
                      >
                        Sonraki
                      </a>
                    )}
                  </div>
                </div>
              </PanelSectionCard>
            )}
          </div>
        )}
      </PanelContentSurface>
    </div>
  );
}

// ─── Alt Bileşenler ───────────────────────────────────────────────────────────

function OlaySatiri({ olay }: { olay: Olay }) {
  return (
    <tr className="hover:bg-black/[0.02]">
      <td className="px-5 py-3">
        <span className="font-[700] text-textStrong">{aksiyonEtiketi(olay.action)}</span>
        <span className="ml-2 text-[10px] text-muted">{olay.action}</span>
      </td>
      <td className="px-5 py-3">
        <span
          className={`rounded-full px-2 py-0.5 text-[10px] font-[800] ${SEVERITY_STYLES[olay.severity]}`}
        >
          {SEVERITY_LABELS[olay.severity]}
        </span>
      </td>
      <td className="px-5 py-3 text-xs text-muted">{olay.target_type ?? '—'}</td>
      <td className="px-5 py-3 text-xs text-muted">
        {olay.actor_display}
        {olay.actor_role && (
          <span className="ml-1 text-[10px] text-muted/70">({olay.actor_role})</span>
        )}
      </td>
      <td className="px-5 py-3 text-xs text-muted">
        {new Date(olay.created_at).toLocaleString('tr-TR', {
          day: '2-digit',
          month: '2-digit',
          year: 'numeric',
          hour: '2-digit',
          minute: '2-digit',
        })}
      </td>
    </tr>
  );
}

function AlertIcon() {
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
      aria-hidden="true"
    >
      <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z" />
      <line x1="12" y1="9" x2="12" y2="13" />
      <line x1="12" y1="17" x2="12.01" y2="17" />
    </svg>
  );
}
