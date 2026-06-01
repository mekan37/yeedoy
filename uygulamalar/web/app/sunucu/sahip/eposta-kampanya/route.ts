import { NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { rateLimit } from '@/src/lib/oran-siniri';
import { hasOwnerBusiness } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { z } from 'zod';

const bodySchema = z.object({
  businessId: z.string().uuid(),
  subject: z.string().min(1).max(200),
  body: z.string().min(1).max(5000),
});

function stripHtml(input: string): string {
  return input
    .replace(/<[^>]*>/g, '')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'");
}

export async function POST(request: Request) {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ ok: false, error: 'Unauthorized' }, { status: 401 });

  const rl = rateLimit(`eposta:${user.id}`, 3, 3_600_000); // 3/hour per user
  if (!rl.ok) {
    return NextResponse.json({ ok: false, error: 'Çok fazla istek. Saatte en fazla 3 kampanya gönderilebilir.' }, { status: 429 });
  }

  const rawBody = await request.json().catch(() => null);
  const parsed = bodySchema.safeParse(rawBody);
  if (!parsed.success) {
    return NextResponse.json({ ok: false, error: 'invalid_input' }, { status: 400 });
  }

  const { businessId, subject, body } = parsed.data;
  const safeBody = stripHtml(body);

  const canManageBusiness = await hasOwnerBusiness(supabase as any, user.id, businessId);
  if (!canManageBusiness) {
    return NextResponse.json({ ok: false, error: 'İşletme bulunamadı' }, { status: 403 });
  }

  // Kampanya kaydı oluştur
  // email_campaigns is not in Database types yet — cast only the from() result
  const supabaseAny = supabase as unknown as { from: (t: string) => any };
  const { data: kampanya, error: kampanyaError } = await supabaseAny
    .from('email_campaigns')
    .insert({
      business_id: businessId,
      subject: subject.trim(),
      body: safeBody.trim(),
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
  // favorites is not in Database types yet — cast only the from() result
  const { data: takipciler } = await supabaseAny
    .from('favorites')
    .select('user_id, user_profiles:user_id(email, display_name)')
    .eq('business_id', businessId)
    .limit(1000);

  const truncated = (takipciler ?? []).length === 1000;

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

  await supabaseAny
    .from('email_campaigns')
    .update({
      status: sentTo > 0 ? 'sent' : 'no_recipients',
      sent_to: sentTo,
      sent_at: new Date().toISOString(),
    })
    .eq('id', kampanya.id);

  return NextResponse.json({ ok: true, sent_to: sentTo, truncated });
}
