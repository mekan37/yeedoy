import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { checkAdminAccess } from '@/src/lib/auth/admin-guard';
import { logger } from '@/src/lib/kayitci';

// ─── Tipler ─────────────────────────────────────────────────────────────────

export type AppealStatus = 'pending' | 'approved' | 'rejected';

export const APPEAL_STATUS_LABELS: Record<AppealStatus | 'all', string> = {
  pending: 'Bekliyor',
  approved: 'Onaylandı',
  rejected: 'Reddedildi',
  all: 'Tümü',
};

export const APPEAL_STATUS_STYLES: Record<AppealStatus, string> = {
  pending: 'bg-amber-50 text-amber-700',
  approved: 'bg-green-50 text-green-700',
  rejected: 'bg-red-50 text-red-700',
};

export const SOURCE_TYPE_LABELS: Record<string, string> = {
  review: 'Yorum',
  business: 'İşletme',
  menu_item: 'Menü Öğesi',
  user: 'Kullanıcı',
};

export interface AppealRow {
  appeal_id: string;
  source_type: string;
  source_id: string;
  appellant_user_id: string;
  reason: string | null;
  details: string | null;
  status: string;
  decision_note: string | null;
  decided_at: string | null;
  created_at: string;
}

export interface ListItirazlarResult {
  list: AppealRow[];
  count: number | null;
  fetchError: boolean;
}

// ─── Maskeleme ───────────────────────────────────────────────────────────────

/** appellant_user_id'yi maskeler — ham UUID asla UI'a verilmez */
function maskeleKullanici(userId: string | null): string {
  if (!userId) return 'Anonim';
  return `Kullanıcı #${userId.slice(0, 6).toUpperCase()}`;
}

// ─── Veri Fonksiyonu ─────────────────────────────────────────────────────────

/**
 * admin_list_moderation_appeals_v1 RPC'yi çağırır.
 * İkinci katman guard: checkAdminAccess() ile korunur.
 * DB katmanında da is_admin_or_community_mod_v1() ile korunur.
 */
export async function listAdminItirazlar(opts: {
  status: AppealStatus | 'all';
  limit: number;
  offset: number;
}): Promise<ListItirazlarResult> {
  const guard = await checkAdminAccess();
  if (!guard.authorized) {
    return { list: [], count: null, fetchError: false };
  }

  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as {
    rpc: (fn: string, args: Record<string, unknown>) => Promise<{ data: unknown; error: unknown }>;
  };

  const statusParam = opts.status === 'all' ? null : opts.status;

  try {
    const { data, error } = await sb.rpc('admin_list_moderation_appeals_v1', {
      p_status: statusParam,
      p_limit: opts.limit,
      p_offset: opts.offset,
    });

    if (error) {
      logger.warn('listAdminItirazlar: RPC hatası', { error });
      return { list: [], count: null, fetchError: true };
    }

    const rows = ((data ?? []) as Array<Record<string, unknown>>).map(
      (row): AppealRow => ({
        appeal_id: String(row['appeal_id'] ?? ''),
        source_type: String(row['source_type'] ?? ''),
        source_id: String(row['source_id'] ?? ''),
        // PII maskeleme: appellant_user_id ham değeri asla döndürülmez
        appellant_user_id: maskeleKullanici(
          row['appellant_user_id'] != null ? String(row['appellant_user_id']) : null,
        ),
        reason: row['reason'] != null ? String(row['reason']) : null,
        details: row['details'] != null ? String(row['details']) : null,
        status: String(row['status'] ?? 'pending'),
        decision_note: row['decision_note'] != null ? String(row['decision_note']) : null,
        decided_at: row['decided_at'] != null ? String(row['decided_at']) : null,
        created_at: String(row['created_at'] ?? ''),
      }),
    );

    return { list: rows, count: rows.length < opts.limit ? opts.offset + rows.length : null, fetchError: false };
  } catch (err) {
    logger.warn('listAdminItirazlar: istisna', { err });
    return { list: [], count: null, fetchError: true };
  }
}
