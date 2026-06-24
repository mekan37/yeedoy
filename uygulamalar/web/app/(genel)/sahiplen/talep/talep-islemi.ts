'use server';

import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

export async function submitOwnerClaim(formData: FormData) {
  const businessId = String(formData.get('businessId') ?? '').trim();
  const fullName   = String(formData.get('fullName')   ?? '').trim();
  const phone      = String(formData.get('phone')      ?? '').trim();
  const note       = String(formData.get('note')       ?? '').trim();

  if (!businessId || !fullName || !phone) {
    redirect(`/sahiplen/talep?id=${businessId}&hata=eksik_alan`);
  }

  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    redirect(`/giris?redirect=${encodeURIComponent(`/sahiplen/talep?id=${businessId}`)}`);
  }

  const { data, error } = await (supabase as any).rpc('submit_owner_claim_v1', {
    p_business_id: businessId,
    p_full_name: fullName,
    p_phone: phone,
    p_evidence_url: null,
    p_note: note || null,
  });

  if (error) {
    redirect(`/sahiplen/talep?id=${businessId}&hata=kayit_hatasi`);
  }

  const result = data as { ok?: boolean; error?: string } | null;
  if (!result?.ok) {
    const code = result?.error ?? 'kayit_hatasi';
    const safeCode =
      code === 'rate_limited_7d' || code === 'already_submitted'
        ? 'talep_bekliyor'
        : 'kayit_hatasi';
    redirect(`/sahiplen/talep?id=${businessId}&hata=${safeCode}`);
  }

  // Panele yönlendir — "onay bekleniyor" banner görünecek
  redirect('/sahip/gosterge-panosu?bilgi=talep_alindi');
}
