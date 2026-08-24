export const PLAN_FEATURE_KEYS = [
  'menu_item_count',
  'ocr_scans_per_month',
  'allergen_ai',
  'language_count',
  'ai_image_gen',
  'qr_watermark',
  'map_boost',
  'sadakat_programi',
  'team_seat_count',
  'campaign_count_per_month',
  'branch_count',
  'analytics_range_days',
] as const;

export type PlanFeatureKey = (typeof PLAN_FEATURE_KEYS)[number];

export const FEATURE_LABELS: Record<PlanFeatureKey, string> = {
  menu_item_count: 'Ürün sayısı',
  ocr_scans_per_month: 'OCR taraması (bu ay)',
  allergen_ai: 'AI alerjen/kalori otomasyonu',
  language_count: 'Dil sayısı',
  ai_image_gen: 'AI görsel üretme',
  qr_watermark: 'QR filigranı',
  map_boost: 'Harita önceliklendirme',
  sadakat_programi: 'Sadakat programı',
  team_seat_count: 'Ekip üyesi',
  campaign_count_per_month: 'CRM kampanyası (bu ay)',
  branch_count: 'Şube sayısı',
  analytics_range_days: 'Analitik aralığı',
};

export const TIER_LABELS: Record<'free' | 'starter' | 'standard' | 'pro', string> = {
  free: 'Ücretsiz',
  starter: 'Başlangıç',
  standard: 'Standart',
  pro: 'Pro (İşletme)',
};

/** Plan sayfasında "{used}/{limit}" yerine düz metin gösterilmesi gereken özellikler
 * (aylık sayaç ya da işgal edilen kaynak değil, bir tavan değeri). */
export const PLAN_CEILING_FEATURE_KEYS: readonly PlanFeatureKey[] = ['analytics_range_days'];
