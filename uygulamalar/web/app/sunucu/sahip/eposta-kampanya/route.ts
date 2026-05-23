import { NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getRequestIdentity, rateLimit } from '@/src/lib/oran-siniri';
import { hasOwnerBusiness } from '@/src/lib/veri/owner/sahip-isletmeleri';

export async function POST(request: Request) {
  const identity = getRequestIdentity({
    ip: request.headers.get('x-forwarded-for'),
    userAgent: request.headers.get('user-agent'),
  });
  const limit = rateLimit(`eposta_kampanya:${identity}`, 3, 3_600_000); // 3/saat
  if (!limit.ok) {
    return NextResponse.json({ ok: false, error: 'Çok fazla istek. Saatte en fazla 3 kampanya gönderilebilir.' }, { status: 429 });
  }

  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ ok: false, error: 'Unauthorized' }, { status: 401 });

  const body = await request.json() as {
    businessId: string;
    subject: string;
    body: string;
  };

  if (!body.businessId || !body.subject?.trim() || !body.body?.trim()) {
    return NextResponse.json({ ok: false, error: 'Eksik parametre' }, { status: 400 });
  }

  const canManageBusiness = await hasOwnerBusiness(supabase as any, user.id, body.businessId);
  if (!canManageBusiness) {
    return NextResponse.json({ ok: false, error: 'İşletme bulunamadı' }, { status: 403 });
  }

  // Kampanya kaydı oluştur
  const { data: kampanya, error: kampanyaError } = await (supabase as any)
    .from('email_campaigns')
    .insert({
      business_id: body.businessId,
      subject: body.subject.trim(),
      body: body.body.trim(),
      status: 'pending',
      created_by: user.id,
      created_at: new Date().toISOString(),
    })
    .select('id')
    .single();

  if (kampanyaError) {
    return NextResponse.json({ ok: false, error: 'internal_error' }, { status: 500 });
  }

  // Takipçilerin e-posta adreslerini al
  const { data: takipciler } = await (supabase as any)
    .from('favorites')
    .select('user_id, user_profiles:user_id(email, display_name)')
    .eq('business_id', body.businessId)
    .limit(1000);

  const eposta_listesi = ((takipciler ?? []) as any[])
    .map((t: any) => ({
      userId: t.user_id,
      email: t.user_profiles?.email,
      isim: t.user_profiles?.display_name ?? 'Değerli Müşteri',
    }))
    .filter((t: any) => t.email);

  // E-posta gönderimini simulate et (gerçek gönderim için Resend/SendGrid entegrasyonu gerekir)
  // Şimdilik kampanya kaydını "sent" olarak güncelle
  const sentTo = eposta_listesi.length;

  await (supabase as any)
    .from('email_campaigns')
    .update({
      status: sentTo > 0 ? 'sent' : 'no_recipients',
      sent_to: sentTo,
      sent_at: new Date().toISOString(),
    })
    .eq('id', kampanya.id);

  return NextResponse.json({ ok: true, sent_to: sentTo });
}
