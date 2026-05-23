import { NextRequest, NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

export async function POST(request: NextRequest) {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: 'Giriş yapmanız gerekiyor.' }, { status: 401 });
  }

  let body: { businessId?: string; fullName?: string; phone?: string; note?: string; evidenceUrl?: string };
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: 'Geçersiz veri.' }, { status: 400 });
  }

  const { businessId, fullName, phone, note, evidenceUrl } = body;

  if (!businessId || !fullName?.trim() || !phone?.trim()) {
    return NextResponse.json({ error: 'Zorunlu alanlar eksik.' }, { status: 400 });
  }

  // İşletme var mı?
  const { data: biz } = await (supabase as any)
    .from('businesses')
    .select('id')
    .eq('id', businessId)
    .eq('is_active', true)
    .maybeSingle();

  if (!biz) {
    return NextResponse.json({ error: 'İşletme bulunamadı.' }, { status: 404 });
  }

  // Tekrar talep var mı?
  const { data: existing } = await (supabase as any)
    .from('owner_claims')
    .select('id, status')
    .eq('user_id', user.id)
    .eq('business_id', businessId)
    .maybeSingle();

  if (existing) {
    if (existing.status === 'approved') {
      return NextResponse.json({ redirect: '/sahip/gosterge-panosu' });
    }
    return NextResponse.json({ redirect: '/sahip/gosterge-panosu?bilgi=talep_bekliyor' });
  }

  const { error } = await (supabase as any)
    .from('owner_claims')
    .insert({
      business_id:    businessId,
      user_id:        user.id,
      status:         'pending',
      full_name:      fullName.trim(),
      phone:          phone.trim(),
      note:           note?.trim() || null,
      evidence_url:   evidenceUrl || null,
      auto_moderated: false,
    });

  if (error) {
    return NextResponse.json({ error: 'Talep kaydedilemedi.' }, { status: 500 });
  }

  return NextResponse.json({ ok: true });
}
