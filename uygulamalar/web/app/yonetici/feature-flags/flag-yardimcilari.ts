export interface FeatureFlag {
  key: string;
  enabled: boolean;
  rollout_percent: number;
  allowed_regions: string[];
  metadata: { description?: string; environment?: string; project?: string; type?: string; is_draft?: boolean } | null;
  updated_by: string | null;
  updated_at: string;
  updated_by_name?: string | null;
}

export type FlagDurum = 'active' | 'disabled' | 'draft';

export function flagDurum(f: Pick<FeatureFlag, 'enabled' | 'metadata'>): FlagDurum {
  if (f.metadata?.is_draft) return 'draft';
  return f.enabled ? 'active' : 'disabled';
}

export const DURUM_ETIKETLERI: Record<FlagDurum, string> = {
  active: 'Aktif',
  disabled: 'Kapalı',
  draft: 'Taslak',
};

export const DURUM_RENKLERI: Record<FlagDurum, string> = {
  active: 'bg-emerald-50 text-emerald-700',
  disabled: 'bg-zinc-100 text-zinc-600',
  draft: 'bg-amber-50 text-amber-700',
};

export const PROJE_SECENEKLERI = ['Mobil App', 'Web App', 'Web Admin', 'Tüm Platformlar'];

export const TUR_SECENEKLERI: Record<string, string> = {
  yeni_ozellik: 'Yeni Özellik',
  ui_ux: 'UI / UX',
  altyapi: 'Altyapı',
  ai_ml: 'AI / ML',
  deneysel: 'Deneysel',
};

export const ORTAM_ETIKETLERI: Record<string, string> = {
  production: 'Production',
  staging: 'Staging',
  development: 'Development',
  all: 'Tüm Ortamlar',
};

export function hedefKitleEtiket(regions: string[]): string {
  if (!regions || regions.length === 0) return 'Tüm Kullanıcılar';
  if (regions.length === 1 && regions[0] === 'TR') return 'Türkiye';
  return regions.join(', ');
}

export function trend(current: number, previous: number): { value: number; label?: string } | undefined {
  if (previous === 0) return current === 0 ? undefined : { value: 100, label: 'önceki 7 gün: 0' };
  const pct = Math.round(((current - previous) / previous) * 100);
  return { value: pct, label: `önceki 7 gün: ${previous}` };
}

export function flagCsvOlustur(rows: FeatureFlag[]): string {
  const header = ['Flag', 'Açıklama', 'Proje', 'Ortam', 'Tür', 'Durum', 'Rollout %', 'Hedef Kitle', 'Güncelleyen', 'Son Güncelleme'];
  const lines = rows.map((f) => [
    f.key,
    f.metadata?.description ?? '',
    f.metadata?.project ?? '',
    ORTAM_ETIKETLERI[f.metadata?.environment ?? ''] ?? f.metadata?.environment ?? '',
    f.metadata?.type ? (TUR_SECENEKLERI[f.metadata.type] ?? f.metadata.type) : '',
    DURUM_ETIKETLERI[flagDurum(f)],
    String(f.rollout_percent),
    hedefKitleEtiket(f.allowed_regions),
    f.updated_by_name ?? '',
    new Date(f.updated_at).toLocaleString('tr-TR'),
  ].map((v) => `"${String(v).replace(/"/g, '""')}"`).join(','));
  return [header.join(','), ...lines].join('\n');
}
