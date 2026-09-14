'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

async function logAudit(supabase: any, action: string, submissionId: string, note?: string | null) {
  await supabase
    .rpc('log_admin_action_v1', {
      p_action: action,
      p_target_table: 'business_submissions',
      p_target_id: submissionId,
      p_meta: note ? { note } : {},
    })
    .then(() => {})
    .catch(() => {});
}

export async function approveSubmission(submissionId: string) {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  const { data: isAdmin } = await (supabase).rpc('is_admin');
  if (!isAdmin || !user) return;

  const { data, error } = await (supabase).rpc('admin_approve_business_submission_v1', {
    p_submission_id: submissionId,
  }) as { data: { ok: boolean } | null; error: { message: string } | null };
  if (error || !data?.ok) {
    throw new Error('Başvuru onaylanamadı.');
  }
  await logAudit(supabase, 'approve', submissionId);
  revalidatePath('/yonetici/kuyruklar');
  revalidatePath('/yonetici/isletme-basvurulari');
}

export async function rejectSubmission(submissionId: string, note?: string | null) {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  const { data: isAdmin } = await (supabase).rpc('is_admin');
  if (!isAdmin || !user) return;

  const { data, error } = await (supabase).rpc('admin_reject_business_submission_v1', {
    p_submission_id: submissionId,
    p_note: note ?? undefined,
  }) as { data: { ok: boolean } | null; error: { message: string } | null };
  if (error || !data?.ok) {
    throw new Error('Başvuru reddedilemedi.');
  }
  await logAudit(supabase, 'reject', submissionId, note);
  revalidatePath('/yonetici/kuyruklar');
  revalidatePath('/yonetici/isletme-basvurulari');
}

export async function setSubmissionReview(submissionId: string, inReview: boolean) {
  const supabase = await createSupabaseServerClient();
  const { data: isAdmin } = await (supabase).rpc('is_admin');
  if (!isAdmin) return;

  const { data, error } = await (supabase).rpc('admin_set_submission_review_v1', {
    p_submission_id: submissionId,
    p_in_review: inReview,
  }) as { data: { ok: boolean } | null; error: { message: string } | null };
  if (error || !data?.ok) {
    throw new Error('İşlem gerçekleştirilemedi.');
  }
  revalidatePath('/yonetici/kuyruklar');
  revalidatePath('/yonetici/isletme-basvurulari');
}
