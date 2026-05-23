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

  // Duplicate talep kontrolü
  const { data: existing } = await (supabase as any)
    .from('owner_claims')
    .select('id, status')
    .eq('user_id', user.id)
    .eq('business_id', businessId)
    .maybeSingle();

  if (existing) {
    if (existing.status === 'approved') redirect('/sahip/gosterge-panosu');
    redirect('/sahip/gosterge-panosu?bilgi=talep_bekliyor');
  }

  // Yeni talep oluştur
  const { error } = await (supabase as any)
    .from('owner_claims')
    .insert({
      business_id: businessId,
      user_id:     user.id,
      status:      'pending',
      full_name:   fullName,
      phone,
      note:        note || null,
      auto_moderated: false,
    });

  if (error) {
    redirect(`/sahiplen/talep?id=${businessId}&hata=kayit_hatasi`);
  }

  // Panele yönlendir — "onay bekleniyor" banner görünecek
  redirect('/sahip/gosterge-panosu?bilgi=talep_alindi');
}
