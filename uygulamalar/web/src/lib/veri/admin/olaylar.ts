import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { logger } from '@/src/lib/kayitci';

// ─── Sabitler ────────────────────────────────────────────────────────────────

/**
 * Olay Merkezi'nde gösterilecek aksiyon kalıpları.
 * list_audit_timeline_v2 RPC'si bu action değerlerini döndürür.
 * Tümünü çekmek için null geçilir; sayfa tarafında severity derive edilir.
 */
export const OLAY_AKSIYON_KALIPLARI = [
  'user.safety_action',
  'admin.impersonation.start',
  'admin.impersonation.stop',
  'user.anonymized',
  'achievement.reset',
  'business.verification_changed',
  'admin.ban',
  'admin.unban',
  'admin.shadow_ban',
  'admin.feature_flag',
  'admin.bulk_action',
  'admin.data_export',
] as const;

/** Aksiyon → severity haritası */
const SEVERITY_MAP: Record<string, OlaySeverity> = {
  'user.safety_action': 'high',
  'admin.impersonation.start': 'critical',
  'admin.impersonation.stop': 'medium',
  'user.anonymized': 'high',
  'achievement.reset': 'medium',
  'business.verification_changed': 'medium',
  'admin.ban': 'high',
  'admin.unban': 'low',
  'admin.shadow_ban': 'high',
  'admin.feature_flag': 'low',
  'admin.bulk_action': 'medium',
  'admin.data_export': 'medium',
};

// ─── Tipler ──────────────────────────────────────────────────────────────────

export type OlaySeverity = 'low' | 'medium' | 'high' | 'critical';

export type Olay = {
  id: string;
  created_at: string;
  /** Aksiyon kodu — action adı (örn. user.safety_action) */
  action: string;
  /** Türetilmiş hedef tipi */
  target_type: string | null;
  /** PII maskelenmez; sadece UUID — ham kullanıcı kimliği gösterilmez */
  actor_display: string;
  actor_role: string | null;
  severity: OlaySeverity;
  /** meta alanı — hassas alanlar maskelenir */
  meta: Record<string, unknown>;
};

export type OlayListeSonucu = {
  list: Olay[];
  hasNextPage: boolean;
  fetchError: boolean;
};

// ─── PII Maskeleme ────────────────────────────────────────────────────────────

const PII_ALANLARI = [
  'email',
  'phone',
  'ip_address',
  'token',
  'password',
  'secret',
  'api_key',
  'refresh_token',
  'access_token',
] as const;

function maskePII(meta: Record<string, unknown>): Record<string, unknown> {
  const sonuc = { ...meta };
  for (const alan of PII_ALANLARI) {
    if (alan in sonuc) {
      sonuc[alan] = '[maskelendi]';
    }
  }
  return sonuc;
}

/** actor_id UUID'sini maskeli gösterime dönüştür — ham UUID asla UI'da görünmez */
function maskeleAktor(actorId: string | null): string {
  if (!actorId) return 'Sistem';
  return `Admin #${actorId.slice(-6).toUpperCase()}`;
}

/** action string'inden severity türet */
function actiondenSeverity(action: string): OlaySeverity {
  return SEVERITY_MAP[action] ?? 'low';
}

// ─── Veri Fonksiyonları ───────────────────────────────────────────────────────

/**
 * Admin olay listesini döndürür.
 * list_audit_timeline_v2 RPC'sini kullanır — is_admin() kontrolü SQL içinde yapılır.
 *
 * p_limit, PAGE_SIZE + 1 olarak verilir: dönen dizinin uzunluğu PAGE_SIZE'dan büyükse
 * sonraki sayfa mevcuttur (cursor-based hasNextPage pattern).
 */
export async function listAdminOlaylar(params: {
  severity?: OlaySeverity | 'all';
  limit: number;
  offset: number;
  search?: string;
}): Promise<OlayListeSonucu> {
  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as {
    rpc: (fn: string, args: Record<string, unknown>) => Promise<{ data: unknown; error: unknown }>;
  };

  try {
    const { data, error } = await sb.rpc('list_audit_timeline_v2', {
      p_limit: params.limit,
      p_offset: params.offset,
      p_action: null,
      p_target_type: null,
      p_target_id: null,
      p_actor_id: null,
      p_business_id: null,
      p_from: null,
      p_to: null,
      p_q: params.search && params.search.trim().length > 0 ? params.search.trim() : null,
    });

    if (error) {
      logger.warn('listAdminOlaylar: RPC hatası', { error });
      return { list: [], hasNextPage: false, fetchError: true };
    }

    const rows = (Array.isArray(data) ? data : []) as Array<Record<string, unknown>>;

    // Sadece olay aksiyonlarını göster — diğer audit kayıtlarını filtrele
    const olaySatirlari = rows.filter((r) => {
      const action = String(r['action'] ?? '');
      // Tanımlı kalıpları veya güvenlik/admin prefix'li aksiyonları kabul et
      return (
        OLAY_AKSIYON_KALIPLARI.includes(action as (typeof OLAY_AKSIYON_KALIPLARI)[number]) ||
        action.startsWith('admin.') ||
        action.startsWith('user.safety') ||
        action.startsWith('user.anon')
      );
    });

    // Severity filtresi (uygulama katmanında — RPC severity kavramı bilmiyor)
    const filtrelenmis =
      !params.severity || params.severity === 'all'
        ? olaySatirlari
        : olaySatirlari.filter(
            (r) => actiondenSeverity(String(r['action'] ?? '')) === params.severity,
          );

    const pageSize = params.limit - 1;
    const hasNextPage = filtrelenmis.length > pageSize;
    const sayfaSatirlar = filtrelenmis.slice(0, pageSize);

    const list: Olay[] = sayfaSatirlar.map((r): Olay => {
      const rawMeta =
        r['meta'] != null && typeof r['meta'] === 'object'
          ? (r['meta'] as Record<string, unknown>)
          : {};
      const action = String(r['action'] ?? '');

      return {
        id: String(r['id'] ?? ''),
        created_at: String(r['created_at'] ?? ''),
        action,
        target_type: r['target_type'] != null ? String(r['target_type']) : null,
        actor_display: maskeleAktor(r['actor_id'] != null ? String(r['actor_id']) : null),
        actor_role: r['actor_role'] != null ? String(r['actor_role']) : null,
        severity: actiondenSeverity(action),
        meta: maskePII(rawMeta),
      };
    });

    return { list, hasNextPage, fetchError: false };
  } catch (err) {
    logger.warn('listAdminOlaylar: istisna', { err });
    return { list: [], hasNextPage: false, fetchError: true };
  }
}
