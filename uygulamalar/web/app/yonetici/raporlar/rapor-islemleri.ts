'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

export async function updateReportStatus(reportId: string, status: 'reviewing' | 'closed', note?: string | null) {
  const supabase = await createSupabaseServerClient();
  const { data: isAdmin } = await (supabase as any).rpc('is_admin');
  if (!isAdmin) return;

  const { error } = await (supabase as any).rpc('admin_update_report_v2', {
    p_report_id: reportId,
    p_status: status,
    p_admin_note: note ?? null,
  });
  if (error) throw new Error('Rapor güncellenemedi.');
  revalidatePath('/yonetici/raporlar');
}

export async function bulkUpdateReportStatus(reportIds: string[], status: 'reviewing' | 'closed', note?: string | null) {
  const supabase = await createSupabaseServerClient();
  const { data: isAdmin } = await (supabase as any).rpc('is_admin');
  if (!isAdmin) return;

  const { data, error } = await (supabase as any).rpc('admin_bulk_update_reports_status_v2', {
    p_report_ids: reportIds,
    p_status: status,
    p_admin_note: note ?? null,
  });
  if (error || !data?.ok) throw new Error('Raporlar güncellenemedi.');
  revalidatePath('/yonetici/raporlar');
}
