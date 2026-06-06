import { NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { rateLimit } from '@/src/lib/oran-siniri';
import { hasOwnerBusiness } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { getOptedInEmails } from '@/src/lib/email/get-opted-in-emails';
import { sendEmailCampaign } from '@/src/lib/email/resend-client';
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

  // Opted-in recipients only (is_subscribed_email consent filter via service role)
  const recipients = await getOptedInEmails(businessId);

  // Attempt Resend delivery (fail-safe — returns provider_not_configured: true if key missing)
  const emailResult = await sendEmailCampaign(recipients, {
    subject,
    htmlBody: `<p>${safeBody}</p>`,
    fromName: 'Yeedoy',
    fromEmail: process.env.RESEND_FROM_EMAIL ?? 'noreply@yeedoy.com',
  });

  // Update campaign record with actual sent_count (email_campaigns schema: sent_count, sent_at)
  await supabaseAny
    .from('email_campaigns')
    .update({
      sent_count: emailResult.success_count,
      sent_at: new Date().toISOString(),
    })
    .eq('id', kampanya.id);

  return NextResponse.json({
    ok: true,
    sent_to: emailResult.success_count,
    provider_not_configured: emailResult.provider_not_configured ?? false,
    truncated: false,
  });
}
