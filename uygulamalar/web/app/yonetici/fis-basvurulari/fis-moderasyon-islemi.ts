'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { checkAdminAccess } from '@/src/lib/auth/admin-guard';
import { logger } from '@/src/lib/kayitci';

type ReviewStatus = 'pending' | 'reviewed' | 'needs_followup';

const GECERLI_DURUMLAR: ReviewStatus[] = ['pending', 'reviewed', 'needs_followup'];

/**
 * Fiş başvurusunun inceleme durumunu günceller.
 * RPC: admin_update_receipt_submission_review_v1
 */
export async function updateFisDurum(receiptId: string, yeniDurum: ReviewStatus, not?: string | null): Promise<void> {
  if (!receiptId || !GECERLI_DURUMLAR.includes(yeniDurum)) {
    logger.warn('updateFisDurum: Geçersiz parametre', { receiptId, yeniDurum });
    return;
  }

  const guard = await checkAdminAccess();
  if (!guard.authorized) {
    logger.warn('updateFisDurum: Admin guard başarısız', { status: guard.status });
    return;
  }

  const supabase = await createSupabaseServerClient();
  const { userId } = guard;
  const sb = supabase as unknown as { rpc: (fn: string, args: Record<string, unknown>) => any };

  try {
    const { data, error } = await sb.rpc('admin_update_receipt_submission_review_v1', {
      p_receipt_id: receiptId,
      p_review_status: yeniDurum,
      p_review_note: not ?? null,
      p_reviewed_by: userId,
    });

    if (error) {
      logger.warn('updateFisDurum: RPC hatası', { error, receiptId });
      return;
    }

    if (data && typeof data === 'object' && 'ok' in data && !data.ok) {
      logger.warn('updateFisDurum: RPC başarısız', {
        code: (data as Record<string, unknown>)['code'],
        receiptId,
      });
      return;
    }

    revalidatePath('/yonetici/fis-basvurulari');
  } catch (err) {
    logger.warn('updateFisDurum: istisna', { err });
  }
}
