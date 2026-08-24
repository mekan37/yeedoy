import { FEATURE_LABELS } from '@/src/lib/plan/plan-sabitleri';

export type PlanTierId = 'free' | 'starter' | 'standard' | 'pro';

export interface PlanTanimi {
  id: PlanTierId;
  label: string;
  monthlyPrice: number;
  yearlyPrice: number;
  tagline: string;
  highlight?: boolean;
}

export const PLAN_TANIMLARI: PlanTanimi[] = [
  { id: 'free', label: 'Ücretsiz', monthlyPrice: 0, yearlyPrice: 0, tagline: 'Başlamak için' },
  { id: 'starter', label: 'Başlangıç', monthlyPrice: 99, yearlyPrice: 950, tagline: 'QR menüye tam geçiş' },
  { id: 'standard', label: 'Standart', monthlyPrice: 349, yearlyPrice: 3350, tagline: 'Büyüyen işletmeler için', highlight: true },
  { id: 'pro', label: 'Pro', monthlyPrice: 699, yearlyPrice: 6710, tagline: 'Çok şubeli / ileri düzey' },
];

export interface PlanOzellik {
  key: string;
  label: string;
  values: Record<PlanTierId, string>;
}

export const PLAN_OZELLIKLERI: PlanOzellik[] = [
  {
    key: 'menu_item_count',
    label: 'Menü ürün limiti',
    values: { free: '30 ürün', starter: 'Sınırsız', standard: 'Sınırsız', pro: 'Sınırsız' },
  },
  {
    key: 'ocr_scans_per_month',
    label: 'Fotoğraftan menü tarama (OCR)',
    values: { free: 'Ayda 1', starter: 'Ayda 5', standard: 'Sınırsız', pro: 'Sınırsız' },
  },
  {
    key: 'allergen_ai',
    label: 'AI alerjen/kalori otomasyonu',
    values: { free: '—', starter: '—', standard: 'Var', pro: 'Var' },
  },
  {
    key: 'language_count',
    label: 'Menü dili',
    values: { free: '1 dil', starter: '1 dil', standard: '2 dil', pro: 'Sınırsız' },
  },
  {
    key: 'ai_image_gen',
    label: 'AI ürün görseli üretme',
    values: { free: '—', starter: '—', standard: '—', pro: 'Var' },
  },
  {
    key: 'qr_watermark',
    label: 'QR kodda Yeedoy filigranı',
    values: { free: 'Var', starter: 'Yok', standard: 'Yok', pro: 'Yok' },
  },
  {
    key: 'map_boost',
    label: 'Haritada/keşifte öne çıkarma',
    values: { free: '—', starter: '—', standard: 'Var', pro: 'Var' },
  },
  {
    key: 'sadakat_programi',
    label: 'Sadakat programı (damga/puan)',
    values: { free: '—', starter: '—', standard: 'Var', pro: 'Var' },
  },
  {
    key: 'team_seat_count',
    label: FEATURE_LABELS.team_seat_count,
    values: { free: '1 (sadece sahip)', starter: '3', standard: '10', pro: 'Sınırsız' },
  },
  {
    key: 'campaign_count_per_month',
    label: FEATURE_LABELS.campaign_count_per_month,
    values: { free: '—', starter: 'Ayda 1', standard: 'Ayda 5', pro: 'Sınırsız' },
  },
  {
    key: 'branch_count',
    label: FEATURE_LABELS.branch_count,
    values: { free: '1 (çoklu şube kapalı)', starter: '1 (kapalı)', standard: '3 şube', pro: 'Sınırsız' },
  },
  {
    key: 'analytics_range_days',
    label: FEATURE_LABELS.analytics_range_days,
    values: { free: 'Son 7 gün', starter: 'Son 30 gün', standard: 'Son 90 gün', pro: 'Son 90 gün' },
  },
];
