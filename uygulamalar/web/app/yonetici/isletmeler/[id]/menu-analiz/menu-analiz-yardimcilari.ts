export interface NormalizedExtractItem {
  category_name: string | null;
  name: string;
  description: string | null;
  price_cents: number | null;
  currency: string;
  confidence: number | null;
  requires_review: boolean;
  review_reasons: string[];
  warnings: string[];
  source_url: string | null;
  source_provider: string | null;
  selected_source: string | null;
  discovered_via: string | null;
}

export type DiscoveryOutcomeStatus =
  | 'SOURCE_FOUND_ITEMS_FOUND'
  | 'SOURCE_FOUND_PARTIAL_ITEMS'
  | 'SOURCE_FOUND_NO_ITEMS'
  | 'SOURCE_FOUND_NEEDS_OCR'
  | 'INVALID_SOURCE_CONTENT'
  | 'NO_SOURCE_FOUND'
  | 'FETCH_FAILED';

export interface DiscoveryOutcome {
  status: DiscoveryOutcomeStatus;
  message: string;
  totalItems: number;
  pricedItems: number;
  missingPriceItems: number;
  categoryCount: number;
  sourceUrl: string | null;
  sourceProvider: string | null;
  selectedSource: string | null;
  discoveredVia: string | null;
}

export const MENU_KAYNAK_KESFI_METINLERI = {
  tab: 'Web Sitesinden Bul',
  cardDescription: "Bir menü URL'si girin, dosya yükleyin veya işletmenin web sitesinden menüyü otomatik bulun. Analiz tamamlanınca çıkarılan kalemleri gözden geçirip onaylayacaksınız.",
  description: 'İşletmenin web sitesini girin. Yeedoy menü sayfasını, PDF menüyü veya desteklenen dijital menü sağlayıcısını otomatik olarak arar.',
  label: 'İşletme web sitesi',
  placeholder: 'https://ornek-restoran.com',
  action: 'Menüyü Bul ve Analiz Et',
  info: 'Yeedoy web sitesindeki menü sayfası, PDF menü ve desteklenen dijital menü kaynaklarını otomatik olarak arar.',
  noSourceHint: 'Diğer yöntemlerden birini deneyebilirsiniz.',
  partialHint: 'Ürün adları bulundu ancak bazı ürünlerde kaynak fiyat bilgisi yer almıyor.',
  allPricesMissingHint: 'Ürün adları bulundu ancak kaynakta fiyat bilgisi yer almıyor.',
  required: 'İşletme web sitesi zorunlu.',
  invalidUrl: 'Geçerli bir web sitesi URL’si girin.',
  unavailable: 'İşletmenin web sitesine otomatik olarak erişilemedi.',
  workingDescription: 'Menü sayfası, PDF menü ve desteklenen dijital menü kaynakları aranıyor. Kaynak bulunduğunda ürünler aynı analiz ve inceleme akışına alınacak.',
  foundTitle: 'Menü bulundu',
  resultTitle: 'Menü arama sonucu',
  viewSource: 'Kaynağı Gör',
  retry: 'Tekrar Dene',
  enterMenuLink: 'Menü Linki Gir',
  uploadFile: 'PDF/Görsel Yükle',
  progressSteps: [
    'Web sitesi inceleniyor',
    'Menü kaynağı aranıyor',
    'Menü kaynağı bulundu',
    'Ürünler okunuyor',
    'Analiz tamamlanıyor',
  ],
} as const;

const ITEM_ARRAY_KEYS = ['items', 'menu_items', 'menuItems', 'menu', 'products', 'dishes', 'entries', 'candidate_items'];
const RESULT_WRAPPER_KEYS = ['data', 'result', 'extraction_result'];

const OUTCOME_MESSAGES: Record<DiscoveryOutcomeStatus, string> = {
  SOURCE_FOUND_ITEMS_FOUND: 'Menü bulundu ve analiz edildi.',
  SOURCE_FOUND_PARTIAL_ITEMS: 'Menü bulundu. Bazı ürünlerin fiyat bilgisi eksik.',
  SOURCE_FOUND_NO_ITEMS: 'Menü kaynağı bulundu ancak ürünler otomatik olarak okunamadı.',
  SOURCE_FOUND_NEEDS_OCR: 'Menü bulundu ancak belge görüntü tabanlı olduğu için ek işleme gerekiyor.',
  INVALID_SOURCE_CONTENT: 'Bulunan menü bağlantısı artık geçerli görünmüyor.',
  NO_SOURCE_FOUND: 'İşletmenin web sitesinde otomatik olarak menü kaynağı bulunamadı.',
  FETCH_FAILED: 'İşletmenin web sitesine otomatik olarak erişilemedi.',
};

function asRecord(value: unknown): Record<string, unknown> | null {
  return value && typeof value === 'object' && !Array.isArray(value) ? value as Record<string, unknown> : null;
}

function locateResultRecord(result: unknown): Record<string, unknown> {
  const root = asRecord(result) ?? {};
  const data = asRecord(root.data);
  const nestedResult = asRecord(root.result);
  return { ...root, ...(nestedResult ?? {}), ...(data ?? {}) };
}

function locateItemsArray(result: unknown, inheritedCategory: string | null = null, depth = 0): unknown[] {
  if (depth > 5) return [];
  if (Array.isArray(result)) return result;
  const root = asRecord(result);
  if (!root) return [];
  for (const key of ITEM_ARRAY_KEYS) {
    if (Array.isArray(root[key])) {
      return (root[key] as unknown[]).map((item) => {
        const record = asRecord(item);
        return record && inheritedCategory && !coerceString(record.category_name ?? record.category)
          ? { ...record, category_name: inheritedCategory }
          : item;
      });
    }
  }

  if (Array.isArray(root.categories)) {
    const categoryItems = (root.categories as unknown[]).flatMap((category) => {
      const categoryRecord = asRecord(category);
      if (!categoryRecord) return [];
      const categoryName = coerceString(categoryRecord.name ?? categoryRecord.title ?? categoryRecord.category_name);
      return locateItemsArray(categoryRecord, categoryName, depth + 1);
    });
    if (categoryItems.length > 0) return categoryItems;
  }

  for (const key of RESULT_WRAPPER_KEYS) {
    const nestedItems = locateItemsArray(root[key], inheritedCategory, depth + 1);
    if (nestedItems.length > 0) return nestedItems;
  }
  return [];
}

function coerceString(value: unknown): string | null {
  return typeof value === 'string' && value.trim() ? value.trim() : null;
}

function coerceName(record: Record<string, unknown>): string | null {
  for (const candidate of [record.name, record.title, record.product_name, record.item_name, record.ad]) {
    const name = coerceString(candidate);
    if (name) return name;
  }
  return null;
}

function coerceBoolean(value: unknown): boolean | null {
  return typeof value === 'boolean' ? value : null;
}

function coerceStringArray(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value
    .map((item) => typeof item === 'string' ? item.trim() : typeof item === 'number' ? String(item) : null)
    .filter((item): item is string => Boolean(item));
}

function coerceConfidence(value: unknown): number | null {
  const number = typeof value === 'number' ? value : typeof value === 'string' ? Number.parseFloat(value) : Number.NaN;
  if (!Number.isFinite(number)) return null;
  if (number >= 0 && number <= 1) return number;
  if (number > 1 && number <= 100) return Math.round(number) / 100;
  return null;
}

function parsePriceToCents(value: unknown): number | null {
  if (typeof value === 'number' && Number.isFinite(value) && value >= 0) return Math.round(value * 100);
  if (typeof value !== 'string') return null;
  const cleaned = value.replace(/[^\d.,]/g, '').trim();
  if (!cleaned) return null;
  const lastComma = cleaned.lastIndexOf(',');
  const lastDot = cleaned.lastIndexOf('.');
  const normalized = lastComma > lastDot
    ? cleaned.replace(/\./g, '').replace(',', '.')
    : cleaned.replace(/,/g, '');
  const number = Number.parseFloat(normalized);
  return Number.isFinite(number) && number >= 0 ? Math.round(number * 100) : null;
}

function coercePriceCents(record: Record<string, unknown>): number | null {
  if (typeof record.price_cents === 'number' && Number.isFinite(record.price_cents) && record.price_cents >= 0) {
    return Math.round(record.price_cents);
  }
  for (const candidate of [record.price, record.fiyat, record.amount, record.unit_price]) {
    const cents = parsePriceToCents(candidate);
    if (cents !== null) return cents;
  }
  return null;
}

function sourceValue(item: Record<string, unknown>, result: Record<string, unknown>, key: string): string | null {
  return coerceString(item[key]) ?? coerceString(result[key]);
}

export function normalizeExtractResult(result: unknown): NormalizedExtractItem[] {
  const resultRecord = locateResultRecord(result);
  return locateItemsArray(result).flatMap((raw) => {
    const record = asRecord(raw);
    if (!record) return [];
    const name = coerceName(record);
    if (!name) return [];

    const priceCents = coercePriceCents(record);
    const priceMissing = coerceBoolean(record.price_missing) === true || priceCents === null;
    const completeness = coerceString(record.completeness)?.toLowerCase();
    const reviewReasons = coerceStringArray(record.review_reasons ?? record.reviewReasons ?? record.reasons);
    let requiresReview = coerceBoolean(record.requires_review ?? record.requiresReview) ?? false;
    if (priceMissing || completeness === 'partial') requiresReview = true;
    if (priceCents === null && !reviewReasons.includes('Fiyat eksik')) reviewReasons.push('Fiyat eksik');

    return [{
      category_name: coerceString(record.category_name ?? record.category ?? record.section ?? record.section_name ?? record.group),
      name,
      description: coerceString(record.description ?? record.desc),
      price_cents: priceCents,
      currency: coerceString(record.currency) ?? 'TRY',
      confidence: coerceConfidence(record.confidence),
      requires_review: requiresReview,
      review_reasons: reviewReasons,
      warnings: coerceStringArray(record.warnings),
      source_url: sourceValue(record, resultRecord, 'source_url') ?? sourceValue(record, resultRecord, 'selected_source'),
      source_provider: sourceValue(record, resultRecord, 'source_provider') ?? coerceString(resultRecord.selected_source_provider),
      selected_source: sourceValue(record, resultRecord, 'selected_source'),
      discovered_via: sourceValue(record, resultRecord, 'discovered_via'),
    }];
  });
}

function outcomeStatus(record: Record<string, unknown>): DiscoveryOutcomeStatus | null {
  const raw = coerceString(record.outcome_status ?? record.outcomeStatus ?? record.status);
  return raw && raw in OUTCOME_MESSAGES ? raw as DiscoveryOutcomeStatus : null;
}

export function discoveryOutcomeMessage(value: unknown): string | null {
  const status = coerceString(value);
  return status && status in OUTCOME_MESSAGES ? OUTCOME_MESSAGES[status as DiscoveryOutcomeStatus] : null;
}

export function parseDiscoveryOutcome(result: unknown): DiscoveryOutcome | null {
  const record = locateResultRecord(result);
  const status = outcomeStatus(record);
  if (!status) return null;
  const items = normalizeExtractResult(result);
  const categories = new Set(items.map((item) => item.category_name).filter((value): value is string => Boolean(value)));
  const pricedItems = items.filter((item) => item.price_cents !== null).length;
  return {
    status,
    message: OUTCOME_MESSAGES[status],
    totalItems: items.length,
    pricedItems,
    missingPriceItems: items.length - pricedItems,
    categoryCount: categories.size,
    sourceUrl: coerceString(record.source_url),
    sourceProvider: coerceString(record.source_provider ?? record.selected_source_provider),
    selectedSource: coerceString(record.selected_source),
    discoveredVia: coerceString(record.discovered_via),
  };
}
