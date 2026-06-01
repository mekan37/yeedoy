import { NextRequest, NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { z } from 'zod';

const schema = z.object({
  businessId: z.string().uuid(),
  fullName: z.string().min(1).max(200).transform((s) => s.trim()),
  phone: z.string().min(1).max(30).transform((s) => s.trim()),
  note: z.string().max(1000).optional(),
  evidenceUrl: z.string().url().optional(),
});

export async function POST(request: NextRequest) {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: 'Giriş yapmanız gerekiyor.' }, { status: 401 });
  }

  const rawBody = await request.json().catch(() => null);
  const parsed = schema.safeParse(rawBody);
  if (!parsed.success) {
    return NextResponse.json({ error: 'Geçersiz veri.' }, { status: 400 });
  }

  const { businessId, fullName, phone, note, evidenceUrl } = parsed.data;

  const supabaseAny = supabase as unknown as { from: (t: string) => any; rpc: (fn: string, args?: any) => any; storage: any; auth: any };

  // İşletme var mı?
  const { data: biz } = await supabase
    .from('businesses')
    .select('id')
    .eq('id', businessId)
    .eq('is_active', true)
    .maybeSingle();

  if (!biz) {
    return NextResponse.json({ error: 'İşletme bulunamadı.' }, { status: 404 });
  }

  // Tekrar talep var mı?
  const { data: existing } = await supabaseAny
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

  const { error } = await supabaseAny
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
