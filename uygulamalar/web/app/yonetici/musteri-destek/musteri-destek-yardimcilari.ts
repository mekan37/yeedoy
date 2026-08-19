export interface DestekTalebi {
  id: string;
  subject: string;
  status: string;
  priority: string;
  category: string;
  created_at: string;
  updated_at: string;
  requester_name: string | null;
  requester_email: string | null;
  first_response_at: string | null;
}

export const STATUS_MAP: Record<string, { label: string; color: string }> = {
  open: { label: 'Açık', color: 'bg-blue-50 text-blue-700' },
  in_progress: { label: 'İşlemde', color: 'bg-yellow-50 text-yellow-700' },
  resolved: { label: 'Çözüldü', color: 'bg-green-50 text-green-700' },
  closed: { label: 'Kapatıldı', color: 'bg-zinc-100 text-zinc-500' },
};

export const PRIORITY_MAP: Record<string, { label: string; color: string }> = {
  low: { label: 'Düşük', color: 'bg-zinc-50 text-zinc-500' },
  medium: { label: 'Orta', color: 'bg-blue-50 text-blue-700' },
  high: { label: 'Yüksek', color: 'bg-orange-50 text-orange-700' },
  urgent: { label: 'Acil', color: 'bg-red-50 text-red-700' },
};

export const TABS = [
  { value: 'all', label: 'Tümü' },
  { value: 'open', label: 'Açık' },
  { value: 'in_progress', label: 'İşlemde' },
  { value: 'resolved', label: 'Çözüldü' },
  { value: 'closed', label: 'Kapatıldı' },
] as const;

export function slaBadge(createdAt: string): { label: string; color: string } {
  const hours = (Date.now() - new Date(createdAt).getTime()) / 3_600_000;
  if (hours < 4) return { label: `${Math.max(1, Math.round(hours * 60))}dk`, color: 'text-green-600 bg-green-50' };
  if (hours < 24) return { label: `${Math.round(hours)}sa`, color: 'text-yellow-600 bg-yellow-50' };
  const days = Math.floor(hours / 24);
  return { label: `${days}g`, color: 'text-red-600 bg-red-50' };
}

export function formatSure(hours: number): string {
  if (hours < 1) return `${Math.round(hours * 60)}dk`;
  if (hours < 24) {
    const h = Math.floor(hours);
    const m = Math.round((hours - h) * 60);
    return m > 0 ? `${h}sa ${m}dk` : `${h}sa`;
  }
  return `${Math.round(hours / 24)}g`;
}

export function trend(current: number, previous: number): { value: number; label?: string } | undefined {
  if (previous === 0) return current === 0 ? undefined : { value: 100, label: 'önceki 7 gün: 0' };
  const pct = Math.round(((current - previous) / previous) * 100);
  return { value: pct, label: `önceki 7 gün: ${previous}` };
}

export function destekCsvOlustur(rows: DestekTalebi[]): string {
  const header = ['ID', 'Konu', 'Durum', 'Öncelik', 'Kategori', 'Kullanıcı', 'E-posta', 'Oluşturulma', 'Güncellenme'];
  const lines = rows.map((t) => [
    t.id,
    t.subject,
    STATUS_MAP[t.status]?.label ?? t.status,
    PRIORITY_MAP[t.priority]?.label ?? t.priority,
    t.category,
    t.requester_name ?? '',
    t.requester_email ?? '',
    new Date(t.created_at).toLocaleString('tr-TR'),
    new Date(t.updated_at).toLocaleString('tr-TR'),
  ].map((v) => `"${String(v).replace(/"/g, '""')}"`).join(','));
  return [header.join(','), ...lines].join('\n');
}
