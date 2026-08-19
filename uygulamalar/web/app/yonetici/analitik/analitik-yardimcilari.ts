export function yuzdeDegisim(bu: number, onceki: number): number {
  if (onceki === 0) return bu > 0 ? 100 : 0;
  return Math.round(((bu - onceki) / onceki) * 100);
}

export const KAYNAK_ETIKETLERI: Record<string, string> = {
  discover_list: 'Keşfet Listesi',
  discover: 'Keşfet',
  discover_search: 'Keşfet Arama',
  web_next_public: 'Web',
  menu_page: 'Menü Sayfası',
};

// analytics_events.source değerleri iki ayrı istemciden (mobil Flutter app ve Next.js web) geliyor;
// her iki taraf da kendi ekran/bileşen adını source olarak gönderiyor. Bu listeler
// uygulamalar/mobil/lib içindeki gerçek logEvent(source: ...) çağrılarından çıkarıldı
// (packages/shared_models üzerinden ortak RPC: log_event_v1). Gerçek bir cihaz/platform
// sütunu tutulmadığı için "Platform Dağılımı" bu bilinen source kümesinden türetiliyor —
// yeni, tanınmayan bir source değeri "Bilinmiyor" grubuna düşer (asla yanlış sınıflandırılmaz).
const MOBIL_KAYNAKLAR = new Set([
  'discover', 'discover_list', 'discover_search', 'discovery_home', 'discovery_category_chips',
  'discovery_search_bar', 'category_quick_filters', 'business_page', 'menu_item_page',
  'menu_item_price_suggestion', 'inbox_page', 'login_page_email', 'login_page_google',
  'onboarding_page', 'open_app', 'qr', 'review_create_page', 'smart_reco',
]);
const WEB_KAYNAKLAR = new Set(['web_next_public']);

export type Platform = 'mobil' | 'web' | 'bilinmiyor';

export function kaynaktanPlatformCikar(source: string | null): Platform {
  if (!source) return 'bilinmiyor';
  if (WEB_KAYNAKLAR.has(source)) return 'web';
  if (MOBIL_KAYNAKLAR.has(source)) return 'mobil';
  return 'bilinmiyor';
}

export const PLATFORM_ETIKETLERI: Record<Platform, string> = {
  mobil: 'Mobil Uygulama',
  web: 'Web',
  bilinmiyor: 'Bilinmiyor',
};

export const GUN_ETIKETLERI = ['Paz', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt'];

export function gunEtiketi(d: Date): string {
  return `${d.getDate().toString().padStart(2, '0')}/${(d.getMonth() + 1).toString().padStart(2, '0')}`;
}

export function csvOlustur(basliklar: string[], satirlar: string[][]): string {
  const kacis = (v: string) => `"${v.replace(/"/g, '""')}"`;
  return [basliklar, ...satirlar].map((satir) => satir.map(kacis).join(',')).join('\n');
}
