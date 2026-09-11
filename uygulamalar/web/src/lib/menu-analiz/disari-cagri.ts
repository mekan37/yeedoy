// Harici Menu Extractor servisiyle (process.env.MENU_EXTRACTOR_BASE_URL) tüm
// iletişim buradan geçer. X-API-Key / CF-Access-Client-Id / CF-Access-Client-Secret
// değerleri SADECE burada okunur ve dışarı (istemciye, response body'sine,
// hata mesajlarına) asla sızdırılmaz — çağıran taraflar sadece genel Türkçe
// hata metinleri alır, ayrıntı `logger` ile sunucu tarafında loglanır.
//
// Kullanan yerler:
//   app/yonetici/isletmeler/[id]/menu-analiz/menu-analiz-islemleri.ts (URL job + polling)
//   app/sunucu/yonetici/menu-analiz/baslat/route.ts (dosya yükleme job'ı — 30MB body
//   limiti Server Action'ların varsayılan limitini aştığı için route.ts kullanılıyor)

import { logger } from '@/src/lib/kayitci';

const MENU_EXTRACTOR_BASE_URL = process.env.MENU_EXTRACTOR_BASE_URL;

export const MENU_EXTRACTOR_MAX_UPLOAD_BYTES = 30 * 1024 * 1024; // 30 MB

function extractorHeaders(extra?: Record<string, string>): Record<string, string> {
  const headers: Record<string, string> = { ...extra };
  const apiKey = process.env.MENU_EXTRACTOR_API_KEY;
  const clientId = process.env.CF_ACCESS_CLIENT_ID;
  const clientSecret = process.env.CF_ACCESS_CLIENT_SECRET;
  if (apiKey) headers['X-API-Key'] = apiKey;
  if (clientId) headers['CF-Access-Client-Id'] = clientId;
  if (clientSecret) headers['CF-Access-Client-Secret'] = clientSecret;
  return headers;
}

function menuAnalysisDebug(meta: Record<string, unknown>) {
  if (process.env.NODE_ENV === 'development') logger.info('[menu-analysis]', meta);
}

export type MenuExtractorErrorCode = 'AUTH_ERROR' | 'EXTRACTOR_UNAVAILABLE' | 'JOB_FAILED';

export type MenuExtractorBaslatSonucu =
  | { ok: true; jobId: string }
  | { ok: false; code: MenuExtractorErrorCode; error: string };

function startError(status: number): Extract<MenuExtractorBaslatSonucu, { ok: false }> {
  if (status === 401 || status === 403) {
    return { ok: false, code: 'AUTH_ERROR', error: 'Menü analiz servisi kimlik doğrulaması başarısız oldu.' };
  }
  return { ok: false, code: 'EXTRACTOR_UNAVAILABLE', error: 'Analiz servisine ulaşılamadı.' };
}

export async function menuExtractorStartSourceDiscoveryJob(websiteUrl: string): Promise<MenuExtractorBaslatSonucu> {
  if (!MENU_EXTRACTOR_BASE_URL) {
    logger.error('menuExtractorStartSourceDiscoveryJob: MENU_EXTRACTOR_BASE_URL tanımsız');
    return { ok: false, code: 'EXTRACTOR_UNAVAILABLE', error: 'Analiz servisi şu anda kullanılamıyor.' };
  }
  try {
    const resp = await fetch(`${MENU_EXTRACTOR_BASE_URL}/v1/jobs/source-discovery`, {
      method: 'POST',
      headers: extractorHeaders({ 'Content-Type': 'application/json' }),
      body: JSON.stringify({ website_url: websiteUrl, auto_extract: true }),
    });
    menuAnalysisDebug({
      input_url: websiteUrl,
      extractor_endpoint: `${MENU_EXTRACTOR_BASE_URL}/v1/jobs/source-discovery`,
      http_status: resp.status,
    });
    if (!resp.ok) {
      logger.error('menuExtractorStartSourceDiscoveryJob: extractor hata döndürdü', { status: resp.status });
      return startError(resp.status);
    }
    const data = (await resp.json().catch(() => null)) as { job_id?: string } | null;
    if (!data?.job_id) {
      logger.error('menuExtractorStartSourceDiscoveryJob: job_id eksik yanıt');
      return { ok: false, code: 'JOB_FAILED', error: 'Menü araması başlatılamadı, tekrar deneyin.' };
    }
    menuAnalysisDebug({
      input_url: websiteUrl,
      extractor_endpoint: `${MENU_EXTRACTOR_BASE_URL}/v1/jobs/source-discovery`,
      http_status: resp.status,
      job_id: data.job_id,
    });
    return { ok: true, jobId: data.job_id };
  } catch (err) {
    logger.error('menuExtractorStartSourceDiscoveryJob: istek hatası', { error: String(err) });
    return { ok: false, code: 'EXTRACTOR_UNAVAILABLE', error: 'İşletmenin web sitesine otomatik olarak erişilemedi.' };
  }
}

export async function menuExtractorStartUploadJob(file: Blob, fileName: string): Promise<MenuExtractorBaslatSonucu> {
  if (!MENU_EXTRACTOR_BASE_URL) {
    logger.error('menuExtractorStartUploadJob: MENU_EXTRACTOR_BASE_URL tanımsız');
    return { ok: false, code: 'EXTRACTOR_UNAVAILABLE', error: 'Analiz servisi şu anda kullanılamıyor.' };
  }
  try {
    const formData = new FormData();
    formData.append('file', file, fileName);
    const resp = await fetch(`${MENU_EXTRACTOR_BASE_URL}/v1/jobs/upload`, {
      method: 'POST',
      headers: extractorHeaders(),
      body: formData,
    });
    if (!resp.ok) {
      logger.error('menuExtractorStartUploadJob: extractor hata döndürdü', { status: resp.status });
      return startError(resp.status);
    }
    const data = (await resp.json().catch(() => null)) as { job_id?: string } | null;
    if (!data?.job_id) {
      logger.error('menuExtractorStartUploadJob: job_id eksik yanıt');
      return { ok: false, code: 'JOB_FAILED', error: 'Analiz işi başlatılamadı, tekrar deneyin.' };
    }
    return { ok: true, jobId: data.job_id };
  } catch (err) {
    logger.error('menuExtractorStartUploadJob: istek hatası', { error: String(err) });
    return { ok: false, code: 'EXTRACTOR_UNAVAILABLE', error: 'Analiz servisine ulaşılamadı.' };
  }
}

export type MenuExtractorPollSonucu =
  | { status: 'queued' | 'started' }
  | { status: 'finished'; result: unknown }
  | { status: 'failed'; error: string }
  | { status: 'error'; code: 'AUTH_ERROR' | 'EXTRACTOR_UNAVAILABLE'; error: string }; // extractor'a ulaşılamadı / beklenmeyen yanıt

export async function menuExtractorPollJob(externalJobId: string): Promise<MenuExtractorPollSonucu> {
  if (!MENU_EXTRACTOR_BASE_URL) {
    return { status: 'error', code: 'EXTRACTOR_UNAVAILABLE', error: 'Analiz servisi şu anda kullanılamıyor.' };
  }
  try {
    const resp = await fetch(`${MENU_EXTRACTOR_BASE_URL}/v1/jobs/${encodeURIComponent(externalJobId)}`, {
      method: 'GET',
      headers: extractorHeaders(),
      cache: 'no-store',
    });
    if (!resp.ok) {
      logger.error('menuExtractorPollJob: extractor hata döndürdü', { status: resp.status });
      if (resp.status === 401 || resp.status === 403) {
        return { status: 'error', code: 'AUTH_ERROR', error: 'Menü analiz servisi kimlik doğrulaması başarısız oldu.' };
      }
      return { status: 'error', code: 'EXTRACTOR_UNAVAILABLE', error: 'Analiz durumu alınamadı.' };
    }
    const data = (await resp.json().catch(() => null)) as { status?: string; result?: unknown; error?: string } | null;
    if (!data?.status) return { status: 'error', code: 'EXTRACTOR_UNAVAILABLE', error: 'Analiz durumu alınamadı.' };
    const discovery = data.result && typeof data.result === 'object' && !Array.isArray(data.result)
      ? data.result as Record<string, unknown>
      : null;
    menuAnalysisDebug({
      extractor_endpoint: `${MENU_EXTRACTOR_BASE_URL}/v1/jobs/${encodeURIComponent(externalJobId)}`,
      http_status: resp.status,
      job_id: externalJobId,
      job_status: data.status,
      discovery_status: discovery?.outcome_status ?? discovery?.status ?? null,
      selected_source: discovery?.selected_source ?? null,
      extraction_started: discovery?.extraction_started ?? null,
      extraction_finished: discovery?.extraction_finished ?? null,
      extracted_item_count: discovery?.extracted_item_count ?? null,
    });
    if (data.status === 'finished') {
      if (discovery?.extraction_started === true && discovery.extraction_finished !== true) return { status: 'started' };
      return { status: 'finished', result: data.result };
    }
    if (data.status === 'failed') return { status: 'failed', error: data.error ?? 'Analiz başarısız oldu.' };
    if (data.status === 'started') return { status: 'started' };
    return { status: 'queued' };
  } catch (err) {
    logger.error('menuExtractorPollJob: istek hatası', { error: String(err) });
    return { status: 'error', code: 'EXTRACTOR_UNAVAILABLE', error: 'Analiz servisine ulaşılamadı.' };
  }
}
