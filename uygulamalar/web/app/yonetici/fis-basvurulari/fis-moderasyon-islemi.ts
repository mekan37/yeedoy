'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { logger } from '@/src/lib/kayitci';

type ReviewStatus = 'pending' | 'reviewed' | 'needs_followup';

const GECERLI_DURUMLAR: ReviewStatus[] = ['pending', 'reviewed', 'needs_followup'];

async function adminKontrol(): Promise<
  | { ok: true; supabase: Awaited<ReturnType<typeof createSupabaseServerClient>>; userId: string }
  | { ok: false; hata: string }
> {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) return { ok: false, hata: 'Oturum açmanız gerekiyor' };

  const { data: profil } = await (supabase as any)
    .from('user_profiles')
    .select('role')
    .eq('id', user.id)
    .single();

  const adminRoller = ['super_admin', 'admin', 'community_mod'];
  if (!profil || !adminRoller.includes(profil.role)) {
    return { ok: false, hata: 'Bu işlem için yetkiniz yok' };
  }

  return { ok: true, supabase, userId: user.id };
}

/**
 * Fiş başvurusunun inceleme durumunu günceller.
 * RPC: admin_update_receipt_submission_review_v1
 *
 * Form action olarak kullanıldığı için void döner.
 * Hatalar server log'a yazılır; UI revalidate ile güncellenir.
 */
export async function fisDurumGuncelle(formData: FormData): Promise<void> {
  const receiptId = String(formData.get('receipt_id') ?? '').trim();
  const yeniDurum = String(formData.get('review_status') ?? '').trim() as ReviewStatus;
  const not = String(formData.get('review_note') ?? '').trim() || null;

  if (!receiptId || !GECERLI_DURUMLAR.includes(yeniDurum)) {
    logger.warn('fisDurumGuncelle: Geçersiz parametre', { receiptId, yeniDurum });
    return;
  }

  const kontrol = await adminKontrol();
  if (!kontrol.ok) {
    logger.warn('fisDurumGuncelle: Admin kontrolü başarısız', { hata: kontrol.hata });
    return;
  }

  const { supabase, userId } = kontrol;
  const sb = supabase as unknown as { rpc: (fn: string, args: Record<string, unknown>) => any };

  try {
    const { data, error } = await sb.rpc('admin_update_receipt_submission_review_v1', {
      p_receipt_id: receiptId,
      p_review_status: yeniDurum,
      p_review_note: not,
      p_reviewed_by: userId,
    });

    if (error) {
      logger.warn('fisDurumGuncelle: RPC hatası', { error, receiptId });
      return;
    }

    if (data && typeof data === 'object' && 'ok' in data && !data.ok) {
      logger.warn('fisDurumGuncelle: RPC başarısız', {
        code: (data as Record<string, unknown>)['code'],
        receiptId,
      });
      return;
    }

    revalidatePath('/yonetici/fis-basvurulari');
  } catch (err) {
    logger.warn('fisDurumGuncelle: istisna', { err });
  }
}
