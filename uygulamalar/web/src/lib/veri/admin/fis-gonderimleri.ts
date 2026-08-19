import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { logger } from '@/src/lib/kayitci';
import type { FisGonderim, FisGonderimDurumu, FisGonderimOzeti, FisGonderimSonucu } from './fis-gonderimleri-types';

export type { FisGonderim, FisGonderimDurumu, FisGonderimOzeti, FisGonderimSonucu } from './fis-gonderimleri-types';
export { REVIEW_STATUS_LABELS, REVIEW_STATUS_STYLES } from './fis-gonderimleri-types';

/** Yalnızca http/https scheme'e izin ver — javascript: ve diğer vektörleri engelle. */
function guvenliImageUrl(raw: string | null): string | null {
  if (!raw) return null;
  try {
    const url = new URL(raw);
    if (url.protocol !== 'https:' && url.protocol !== 'http:') return null;
    return raw;
  } catch {
    return null;
  }
}

// ─── Maskeleme ───────────────────────────────────────────────────────────────

/** user_id'yi maskeler — email/phone asla gösterilmez */
function maskeleKullanici(userId: string | null): string {
  if (!userId) return 'Anonim';
  return `Kullanıcı #${userId.slice(-6).toUpperCase()}`;
}

// ─── Veri Fonksiyonları ──────────────────────────────────────────────────────

/**
 * admin_list_receipt_submissions_v2 RPC'yi çağırır.
 * is_admin() kontrolü SQL içinde yapılır.
 *
 * p_limit değeri PAGE_SIZE + 1 olarak verilir: dönen dizinin uzunluğu
 * PAGE_SIZE'dan büyükse sonraki sayfa mevcuttur.
 */
export async function listAdminFisGonderimleri(params: {
  reviewStatus: FisGonderimDurumu;
  limit: number;
  offset: number;
}): Promise<FisGonderimSonucu> {
  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as { rpc: (fn: string, args: Record<string, unknown>) => any };

  const reviewStatusParam =
    params.reviewStatus === 'all' ? null : params.reviewStatus;

  try {
    const [listRes, summaryRes] = await Promise.all([
      sb.rpc('admin_list_receipt_submissions_v2', {
        p_query: null,
        p_review_status: reviewStatusParam,
        p_only_unmatched: false,
        p_limit: params.limit,
        p_offset: params.offset,
      }),
      sb.rpc('admin_get_receipt_submission_summary_v1', {
        p_query: null,
        p_review_status: reviewStatusParam,
        p_only_unmatched: false,
      }),
    ]);

    if (listRes.error) {
      logger.warn('listAdminFisGonderimleri: RPC hatası', { error: listRes.error });
      return { list: [], count: 0, hasNextPage: false, fetchError: true };
    }

    const rows = ((listRes.data ?? []) as Array<Record<string, unknown>>).map(
      (row): FisGonderim => ({
        receipt_id: String(row['receipt_id'] ?? ''),
        created_at: String(row['created_at'] ?? ''),
        submitter_display: maskeleKullanici(
          row['user_id'] != null ? String(row['user_id']) : null,
        ),
        business_id: row['business_id'] != null ? String(row['business_id']) : null,
        business_name: row['business_name'] != null ? String(row['business_name']) : null,
        city: row['city'] != null ? String(row['city']) : null,
        district: row['district'] != null ? String(row['district']) : null,
        chain_name: row['chain_name'] != null ? String(row['chain_name']) : null,
        image_url: guvenliImageUrl(row['image_url'] != null ? String(row['image_url']) : null),
        matches_count: Number(row['matches_count'] ?? 0),
        review_status: String(row['review_status'] ?? 'pending'),
        review_note: row['review_note'] != null ? String(row['review_note']) : null,
      }),
    );

    const summaryRow =
      Array.isArray(summaryRes.data) && summaryRes.data.length > 0
        ? (summaryRes.data[0] as Record<string, unknown>)
        : null;
    const totalCount =
      summaryRow?.['total_count'] != null ? Number(summaryRow['total_count']) : null;

    const pageSize = params.limit - 1;
    return {
      list: rows.slice(0, pageSize),
      count: totalCount,
      hasNextPage: rows.length > pageSize,
      fetchError: false,
    };
  } catch (err) {
    logger.warn('listAdminFisGonderimleri: istisna', { err });
    return { list: [], count: 0, hasNextPage: false, fetchError: true };
  }
}

/**
 * admin_get_receipt_submission_summary_v1 RPC'yi çağırır.
 * Filtre bağımsız genel özet için null parametrelerle kullanılır.
 */
export async function getAdminFisGonderimOzeti(): Promise<FisGonderimOzeti> {
  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as { rpc: (fn: string, args: Record<string, unknown>) => any };

  try {
    const { data, error } = await sb.rpc('admin_get_receipt_submission_summary_v1', {
      p_query: null,
      p_review_status: null,
      p_only_unmatched: false,
    });

    if (error) {
      logger.warn('getAdminFisGonderimOzeti: RPC hatası', { error });
      return bosOzet();
    }

    const row =
      Array.isArray(data) && data.length > 0
        ? (data[0] as Record<string, unknown>)
        : null;

    if (!row) return bosOzet();

    return {
      total_count: Number(row['total_count'] ?? 0),
      pending_count: Number(row['pending_count'] ?? 0),
      reviewed_count: Number(row['reviewed_count'] ?? 0),
      needs_followup_count: Number(row['needs_followup_count'] ?? 0),
      zero_match_count: Number(row['zero_match_count'] ?? 0),
      business_count: Number(row['business_count'] ?? 0),
      recent_24h_count: Number(row['recent_24h_count'] ?? 0),
    };
  } catch (err) {
    logger.warn('getAdminFisGonderimOzeti: istisna', { err });
    return bosOzet();
  }
}

function bosOzet(): FisGonderimOzeti {
  return {
    total_count: 0,
    pending_count: 0,
    reviewed_count: 0,
    needs_followup_count: 0,
    zero_match_count: 0,
    business_count: 0,
    recent_24h_count: 0,
  };
}
