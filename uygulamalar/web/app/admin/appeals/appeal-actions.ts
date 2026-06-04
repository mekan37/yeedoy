'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { checkAdminAccess } from '@/src/lib/auth/admin-guard';
import { logger } from '@/src/lib/kayitci';

const ALLOWED_DECISIONS = ['approved', 'rejected'] as const;
type Decision = (typeof ALLOWED_DECISIONS)[number];

function isAllowedDecision(value: string): value is Decision {
  return (ALLOWED_DECISIONS as readonly string[]).includes(value);
}

/**
 * İtiraz kararı sunucu aksiyonu.
 * Whitelist: sadece 'approved' veya 'rejected' kabul edilir.
 * Guard: checkAdminAccess() ikinci katman koruma.
 * DB katmanı: admin_decide_moderation_appeal_v1 içinde is_admin_or_community_mod_v1() kontrolü.
 */
export async function decideAppealAction(formData: FormData): Promise<void> {
  const guard = await checkAdminAccess();
  if (!guard.authorized) {
    logger.warn('decideAppealAction: yetkisiz erişim girişimi');
    return;
  }

  const appealId = formData.get('appeal_id');
  const decisionRaw = formData.get('decision');
  const note = formData.get('note');
  const statusParam = formData.get('status') ?? 'pending';

  if (!appealId || typeof appealId !== 'string') {
    logger.warn('decideAppealAction: geçersiz appeal_id');
    return;
  }

  if (!decisionRaw || typeof decisionRaw !== 'string' || !isAllowedDecision(decisionRaw)) {
    logger.warn('decideAppealAction: geçersiz karar değeri', { decision: decisionRaw });
    return;
  }

  const noteValue = note && typeof note === 'string' && note.trim().length > 0
    ? note.trim()
    : null;

  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as {
    rpc: (fn: string, args: Record<string, unknown>) => Promise<{ data: unknown; error: unknown }>;
  };

  try {
    const { error } = await sb.rpc('admin_decide_moderation_appeal_v1', {
      p_appeal_id: appealId,
      p_decision: decisionRaw,
      p_note: noteValue,
    });

    if (error) {
      logger.warn('decideAppealAction: RPC hatası', { error });
      return;
    }
  } catch (err) {
    logger.warn('decideAppealAction: istisna', { err });
    return;
  }

  revalidatePath(`/admin/appeals?status=${statusParam}`);
  revalidatePath('/admin/appeals');
}
