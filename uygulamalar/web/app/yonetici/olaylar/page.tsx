import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { createSupabaseServiceClient } from '@/src/lib/taban/hizmet';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';

export const metadata: Metadata = {
  title: 'Olay Merkezi | Yonetici Paneli',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ severity?: string; status?: string; page?: string; sort?: string; dir?: string }> };
const PAGE_SIZE = 40;
const SOURCE_LIMIT = 200;
const SORT_KEYS = ['incident_type', 'severity', 'status', 'description', 'source', 'created_at'] as const;

type Severity = 'low' | 'medium' | 'high' | 'critical';
type IncidentStatus = 'open' | 'investigating' | 'resolved' | 'closed';
type SortKey = (typeof SORT_KEYS)[number];
type SortDir = 'asc' | 'desc';

type IncidentRow = {
  id: string;
  incident_type: string;
  severity: Severity;
  status: IncidentStatus;
  description: string;
  created_at: string;
  source: string;
};

const SEVERITY_LABELS: Record<string, string> = {
  low: 'Düşük',
  medium: 'Orta',
  high: 'Yüksek',
  critical: 'Kritik',
};

const STATUS_LABELS: Record<string, string> = {
  open: 'Açık',
  investigating: 'İnceleniyor',
  resolved: 'Çözüldü',
  closed: 'Kapatıldı',
};

export default async function AdminIncidentsPage({ searchParams }: Props) {
  const { severity = 'all', status = 'all', page = '1', sort = 'created_at', dir = 'desc' } = await searchParams;
  const pageNum = Math.max(1, parseInt(page, 10));
  const offset = (pageNum - 1) * PAGE_SIZE;
  const sortKey = parseSortKey(sort);
  const sortDir = dir === 'asc' ? 'asc' : 'desc';

  const supabase = createSupabaseServiceClient() ?? (await createSupabaseServerClient());
  const { list, count } = await listIncidentRows(supabase, { severity, status, offset, sortKey, sortDir });
  const totalPages = Math.ceil(count / PAGE_SIZE);
  const createSortHref = (nextSort: SortKey) => {
    const nextDir: SortDir = sortKey === nextSort && sortDir === 'asc' ? 'desc' : 'asc';
    return `?severity=${encodeURIComponent(severity)}&status=${encodeURIComponent(status)}&sort=${nextSort}&dir=${nextDir}&page=1`;
  };
  const pageHref = (nextPage: number) =>
    `?severity=${encodeURIComponent(severity)}&status=${encodeURIComponent(status)}&sort=${sortKey}&dir=${sortDir}&page=${nextPage}`;

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Yönetici"
        title="Olay Merkezi"
        description={`${count.toLocaleString('tr-TR')} olay`}
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-4">
            {/* Filters */}
            <div className="flex flex-wrap gap-3">
              <form method="get" className="flex gap-2">
                <input type="hidden" name="severity" value={severity} />
                <input type="hidden" name="sort" value={sortKey} />
                <input type="hidden" name="dir" value={sortDir} />
                {[
                  { value: 'all', label: 'Tümü' },
                  { value: 'open', label: 'Açık' },
                  { value: 'investigating', label: 'İnceleniyor' },
                  { value: 'resolved', label: 'Çözüldü' },
                ].map(({ value, label }) => (
                  <button
                    key={value}
                    type="submit"
                    name="status"
                    value={value}
                    className={`rounded-lg px-3 py-1.5 text-xs font-bold transition-colors ${
                      status === value
                        ? 'bg-primary text-white'
                        : 'border border-border bg-card text-muted hover:text-textStrong'
                    }`}
                  >
                    {label}
                  </button>
                ))}
              </form>

              <form method="get" className="flex gap-2">
                <input type="hidden" name="status" value={status} />
                <input type="hidden" name="sort" value={sortKey} />
                <input type="hidden" name="dir" value={sortDir} />
                {[
                  { value: 'all', label: 'Tüm Ciddiyet' },
                  { value: 'critical', label: 'Kritik' },
                  { value: 'high', label: 'Yüksek' },
                  { value: 'medium', label: 'Orta' },
                  { value: 'low', label: 'Düşük' },
                ].map(({ value, label }) => (
                  <button
                    key={value}
                    type="submit"
                    name="severity"
                    value={value}
                    className={`rounded-lg px-3 py-1.5 text-xs font-bold transition-colors ${
                      severity === value
                        ? 'bg-primary text-white'
                        : 'border border-border bg-card text-muted hover:text-textStrong'
                    }`}
                  >
                    {label}
                  </button>
                ))}
              </form>
            </div>

            {list.length === 0 ? (
              <PanelEmptyState
                icon={<AlertIcon />}
                title="Olay yok"
                description="Seçilen filtreye uygun analitik olay, rate-limit kaydı, denetim kaydı veya açık rapor bulunamadı."
              />
            ) : (
              <PanelBolumKarti noPadding>
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b border-border text-left">
                      <SortableHeader label="Olay Tipi" sortKey="incident_type" currentSort={sortKey} currentDir={sortDir} href={createSortHref('incident_type')} />
                      <SortableHeader label="Ciddiyet" sortKey="severity" currentSort={sortKey} currentDir={sortDir} href={createSortHref('severity')} />
                      <SortableHeader label="Durum" sortKey="status" currentSort={sortKey} currentDir={sortDir} href={createSortHref('status')} />
                      <SortableHeader label="Açıklama" sortKey="description" currentSort={sortKey} currentDir={sortDir} href={createSortHref('description')} />
                      <SortableHeader label="Kaynak" sortKey="source" currentSort={sortKey} currentDir={sortDir} href={createSortHref('source')} />
                      <SortableHeader label="Oluşturma Tarihi" sortKey="created_at" currentSort={sortKey} currentDir={sortDir} href={createSortHref('created_at')} />
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-border">
                    {list.map((inc) => (
                      <tr key={inc.id} className="hover:bg-black/2">
                        <td className="px-5 py-3 font-bold text-textStrong">
                          {inc.incident_type}
                        </td>
                        <td className="px-5 py-3">
                          <span
                            className={`rounded-full px-2 py-0.5 text-[10px] font-extrabold ${
                              inc.severity === 'critical'
                                ? 'bg-red-100 text-red-700'
                                : inc.severity === 'high'
                                ? 'bg-orange-50 text-orange-700'
                                : inc.severity === 'medium'
                                ? 'bg-amber-50 text-amber-700'
                                : 'bg-zinc-100 text-zinc-500'
                            }`}
                          >
                            {SEVERITY_LABELS[inc.severity] ?? inc.severity}
                          </span>
                        </td>
                        <td className="px-5 py-3">
                          <span
                            className={`rounded-full px-2 py-0.5 text-[10px] font-extrabold ${
                              inc.status === 'resolved' || inc.status === 'closed'
                                ? 'bg-green-50 text-green-700'
                                : inc.status === 'investigating'
                                ? 'bg-blue-50 text-blue-700'
                                : 'bg-amber-50 text-amber-700'
                            }`}
                          >
                            {STATUS_LABELS[inc.status] ?? inc.status}
                          </span>
                        </td>
                        <td className="max-w-[300px] px-5 py-3 text-muted">
                          <p className="line-clamp-2">{inc.description}</p>
                        </td>
                        <td className="px-5 py-3 font-mono text-xs text-muted">
                          {inc.source}
                        </td>
                        <td className="px-5 py-3 text-xs text-muted">
                          {new Date(inc.created_at).toLocaleDateString('tr-TR')}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>

                {totalPages > 1 && (
                  <div className="flex items-center justify-between border-t border-border px-5 py-3">
                    <span className="text-xs text-muted">Sayfa {pageNum} / {totalPages}</span>
                    <div className="flex gap-2">
                      {pageNum > 1 && (
                        <a
                          href={pageHref(pageNum - 1)}
                          className="rounded-lg border border-border px-3 py-1 text-xs font-bold text-textStrong hover:bg-black/2"
                        >
                          ← Önceki
                        </a>
                      )}
                      {pageNum < totalPages && (
                        <a
                          href={pageHref(pageNum + 1)}
                          className="rounded-lg border border-border px-3 py-1 text-xs font-bold text-textStrong hover:bg-black/2"
                        >
                          Sonraki →
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

async function listIncidentRows(
  supabase: any,
  {
    severity,
    status,
    offset,
    sortKey,
    sortDir,
  }: { severity: string; status: string; offset: number; sortKey: SortKey; sortDir: SortDir },
) {
  const [analytics, rateLimits, auditLogs, reports] = await Promise.all([
    safeQuery(
      supabase
        .from('analytics_events')
        .select('id, event_name, created_at, business_id, source')
        .order('created_at', { ascending: false })
        .limit(SOURCE_LIMIT),
    ),
    safeQuery(
      supabase
        .from('edge_rate_limit_events')
        .select('id, action, user_id, ip_hash, scope, created_at')
        .order('created_at', { ascending: false })
        .limit(SOURCE_LIMIT),
    ),
    safeQuery(
      supabase
        .from('admin_audit_log')
        .select('id, action, target_table, target_id, meta, created_at')
        .order('created_at', { ascending: false })
        .limit(SOURCE_LIMIT),
    ),
    safeQuery(
      supabase
        .from('reports')
        .select('id, target_type, reason, details, status, created_at, business_id, review_id')
        .in('status', ['open', 'reviewing'])
        .order('created_at', { ascending: false })
        .limit(SOURCE_LIMIT),
    ),
  ]);

  const rows: IncidentRow[] = [
    ...analytics.map(mapAnalyticsEvent),
    ...rateLimits.map(mapRateLimitEvent),
    ...auditLogs.map(mapAuditLog),
    ...reports.map(mapReport),
  ]
    .filter((row) => status === 'all' || row.status === status)
    .filter((row) => severity === 'all' || row.severity === severity)
    .sort((a, b) => compareIncidentRows(a, b, sortKey, sortDir));

  return {
    list: rows.slice(offset, offset + PAGE_SIZE),
    count: rows.length,
  };
}

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
  return SORT_KEYS.includes(value as SortKey) ? (value as SortKey) : 'created_at';
}

function compareIncidentRows(a: IncidentRow, b: IncidentRow, sortKey: SortKey, sortDir: SortDir) {
  const direction = sortDir === 'asc' ? 1 : -1;
  let result = 0;

  if (sortKey === 'created_at') {
    result = new Date(a.created_at).getTime() - new Date(b.created_at).getTime();
  } else if (sortKey === 'severity') {
    result = severityRank(a.severity) - severityRank(b.severity);
  } else if (sortKey === 'status') {
    result = statusRank(a.status) - statusRank(b.status);
  } else {
    result = String(a[sortKey] ?? '').localeCompare(String(b[sortKey] ?? ''), 'tr');
  }

  if (result === 0) {
    result = new Date(b.created_at).getTime() - new Date(a.created_at).getTime();
  }

  return result * direction;
}

function severityRank(severity: Severity) {
  return { low: 1, medium: 2, high: 3, critical: 4 }[severity];
}

function statusRank(status: IncidentStatus) {
  return { open: 1, investigating: 2, resolved: 3, closed: 4 }[status];
}

async function safeQuery(query: PromiseLike<{ data: any[] | null; error: any }>) {
  try {
    const { data, error } = await query;
    return error ? [] : data ?? [];
  } catch {
    return [];
  }
}

function mapAnalyticsEvent(event: any): IncidentRow {
  const eventName = String(event.event_name ?? 'analytics_event');
  const parts = [
    `${eventName} olayı kaydedildi`,
    event.source ? `kaynak: ${event.source}` : null,
    event.business_id ? `işletme: ${shortId(event.business_id)}` : null,
  ].filter(Boolean);

  return {
    id: `analytics:${event.id ?? `${eventName}:${event.created_at}`}`,
    incident_type: eventName,
    severity: getAnalyticsSeverity(eventName),
    status: 'resolved',
    description: parts.join(' · '),
    created_at: event.created_at ?? new Date(0).toISOString(),
    source: 'analytics_events',
  };
}

function mapRateLimitEvent(event: any): IncidentRow {
  const action = String(event.action ?? 'rate_limit');
  const parts = [
    `${action} için rate limit tetiklendi`,
    event.scope ? `kapsam: ${event.scope}` : null,
    event.user_id ? `kullanıcı: ${shortId(event.user_id)}` : null,
    event.ip_hash ? `ip: ${shortId(event.ip_hash)}` : null,
  ].filter(Boolean);

  return {
    id: `rate-limit:${event.id ?? `${action}:${event.created_at}`}`,
    incident_type: 'rate_limit',
    severity: 'high',
    status: 'open',
    description: parts.join(' · '),
    created_at: event.created_at ?? new Date(0).toISOString(),
    source: 'edge_rate_limit_events',
  };
}

function mapAuditLog(entry: any): IncidentRow {
  const action = String(entry.action ?? 'audit');
  const target = [entry.target_table, entry.target_id ? shortId(entry.target_id) : null].filter(Boolean).join(' / ');

  return {
    id: `audit:${entry.id ?? `${action}:${entry.created_at}`}`,
    incident_type: action,
    severity: getAuditSeverity(action),
    status: 'resolved',
    description: `${action} işlemi${target ? ` · hedef: ${target}` : ''}`,
    created_at: entry.created_at ?? new Date(0).toISOString(),
    source: 'admin_audit_log',
  };
}

function mapReport(report: any): IncidentRow {
  const reportStatus = report.status === 'reviewing' ? 'investigating' : 'open';
  const details = String(report.details ?? '').trim();

  return {
    id: `report:${report.id}`,
    incident_type: `report_${report.target_type ?? 'item'}`,
    severity: report.status === 'reviewing' ? 'medium' : 'high',
    status: reportStatus,
    description: [report.reason ?? 'Rapor', details || null].filter(Boolean).join(' · '),
    created_at: report.created_at ?? new Date(0).toISOString(),
    source: 'reports',
  };
}

function getAnalyticsSeverity(eventName: string): Severity {
  const normalized = eventName.toLowerCase();
  if (normalized.includes('error') || normalized.includes('fail') || normalized.includes('denied')) return 'high';
  if (normalized.includes('rate') || normalized.includes('warning') || normalized.includes('blocked')) return 'medium';
  return 'low';
}

function getAuditSeverity(action: string): Severity {
  const normalized = action.toLowerCase();
  if (normalized.includes('delete') || normalized.includes('ban') || normalized.includes('suspend')) return 'high';
  if (normalized.includes('reject') || normalized.includes('remove') || normalized.includes('moderate')) return 'medium';
  return 'low';
}

function shortId(value: unknown) {
  const text = String(value);
  return text.length > 14 ? `${text.slice(0, 10)}…` : text;
}

function AlertIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z" />
      <line x1="12" y1="9" x2="12" y2="13" />
      <line x1="12" y1="17" x2="12.01" y2="17" />
    </svg>
  );
}

