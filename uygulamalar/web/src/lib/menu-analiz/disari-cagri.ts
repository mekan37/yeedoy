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

export type MenuExtractorBaslatSonucu =
  | { ok: true; jobId: string }
  | { ok: false; error: string };

export async function menuExtractorStartUrlJob(url: string): Promise<MenuExtractorBaslatSonucu> {
  if (!MENU_EXTRACTOR_BASE_URL) {
    logger.error('menuExtractorStartUrlJob: MENU_EXTRACTOR_BASE_URL tanımsız');
    return { ok: false, error: 'Analiz servisi şu anda kullanılamıyor.' };
  }
  try {
    const resp = await fetch(`${MENU_EXTRACTOR_BASE_URL}/v1/jobs/url`, {
      method: 'POST',
      headers: extractorHeaders({ 'Content-Type': 'application/json' }),
      body: JSON.stringify({ url }),
    });
    if (!resp.ok) {
      logger.error('menuExtractorStartUrlJob: extractor hata döndürdü', { status: resp.status });
      return { ok: false, error: 'Analiz başlatılamadı, tekrar deneyin.' };
    }
    const data = (await resp.json().catch(() => null)) as { job_id?: string } | null;
    if (!data?.job_id) {
      logger.error('menuExtractorStartUrlJob: job_id eksik yanıt');
      return { ok: false, error: 'Analiz başlatılamadı, tekrar deneyin.' };
    }
    return { ok: true, jobId: data.job_id };
  } catch (err) {
    logger.error('menuExtractorStartUrlJob: istek hatası', { error: String(err) });
    return { ok: false, error: 'Analiz servisine ulaşılamadı.' };
  }
}

export async function menuExtractorStartUploadJob(file: Blob, fileName: string): Promise<MenuExtractorBaslatSonucu> {
  if (!MENU_EXTRACTOR_BASE_URL) {
    logger.error('menuExtractorStartUploadJob: MENU_EXTRACTOR_BASE_URL tanımsız');
    return { ok: false, error: 'Analiz servisi şu anda kullanılamıyor.' };
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
      return { ok: false, error: 'Analiz başlatılamadı, tekrar deneyin.' };
    }
    const data = (await resp.json().catch(() => null)) as { job_id?: string } | null;
    if (!data?.job_id) {
      logger.error('menuExtractorStartUploadJob: job_id eksik yanıt');
      return { ok: false, error: 'Analiz başlatılamadı, tekrar deneyin.' };
    }
    return { ok: true, jobId: data.job_id };
  } catch (err) {
    logger.error('menuExtractorStartUploadJob: istek hatası', { error: String(err) });
    return { ok: false, error: 'Analiz servisine ulaşılamadı.' };
  }
}

export type MenuExtractorPollSonucu =
  | { status: 'queued' | 'started' }
  | { status: 'finished'; result: unknown }
  | { status: 'failed'; error: string }
  | { status: 'error'; error: string }; // extractor'a ulaşılamadı / beklenmeyen yanıt

export async function menuExtractorPollJob(externalJobId: string): Promise<MenuExtractorPollSonucu> {
  if (!MENU_EXTRACTOR_BASE_URL) {
    return { status: 'error', error: 'Analiz servisi şu anda kullanılamıyor.' };
  }
  try {
    const resp = await fetch(`${MENU_EXTRACTOR_BASE_URL}/v1/jobs/${encodeURIComponent(externalJobId)}`, {
      method: 'GET',
      headers: extractorHeaders(),
      cache: 'no-store',
    });
    if (!resp.ok) {
      logger.error('menuExtractorPollJob: extractor hata döndürdü', { status: resp.status });
      return { status: 'error', error: 'Analiz durumu alınamadı.' };
    }
    const data = (await resp.json().catch(() => null)) as { status?: string; result?: unknown; error?: string } | null;
    if (!data?.status) return { status: 'error', error: 'Analiz durumu alınamadı.' };
    if (data.status === 'finished') return { status: 'finished', result: data.result };
    if (data.status === 'failed') return { status: 'failed', error: data.error ?? 'Analiz başarısız oldu.' };
    if (data.status === 'started') return { status: 'started' };
    return { status: 'queued' };
  } catch (err) {
    logger.error('menuExtractorPollJob: istek hatası', { error: String(err) });
    return { status: 'error', error: 'Analiz servisine ulaşılamadı.' };
  }
}
