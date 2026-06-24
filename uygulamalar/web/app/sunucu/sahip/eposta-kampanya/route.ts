import { NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { rateLimit } from '@/src/lib/oran-siniri';
import { hasOwnerBusiness } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { getOptedInEmails } from '@/src/lib/email/get-opted-in-emails';
import { sendEmailCampaign } from '@/src/lib/email/resend-client';
import { generateUnsubscribeToken } from '@/src/lib/email/unsubscribe-token';
import { logger } from '@/src/lib/kayitci';
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

  // Opted-in recipients only — çift filtre: is_subscribed_email + marketing_email_opt_in (T18)
  const baseRecipients = await getOptedInEmails(businessId);

  // UNSUBSCRIBE_HMAC_SECRET zorunlu kontrolü — fail-closed (6563 md.9/3).
  // Her ticari e-postada çalışan abonelik iptal mekanizması zorunludur.
  // Secret eksikse kampanya linksiz gönderilemez; burada durdurulur.
  if (!process.env.UNSUBSCRIBE_HMAC_SECRET?.trim()) {
    logger.warn('eposta-kampanya: UNSUBSCRIBE_HMAC_SECRET yapılandırılmamış — kampanya iptal (6563 md.9/3)');
    await supabaseAny
      .from('email_campaigns')
      .update({ status: 'failed', sent_count: 0, sent_at: new Date().toISOString() })
      .eq('id', kampanya.id);
    return NextResponse.json(
      { error: 'internal_error', detail: 'unsubscribe_secret_not_configured' },
      { status: 500 },
    );
  }

  // Her alıcı için işletme bazlı "biz" token üret (6563 md.9/3 — kişiye özgü iptal linki).
  // Token üretimi başarısız olursa kampanya fail-closed olarak durdurulur.
  const siteUrl = process.env.NEXT_PUBLIC_SITE_URL?.trim() || 'https://yeedoy.com';
  const recipients: Array<{ email: string; displayName: string; userId: string; unsubscribeUrl: string }> = [];
  for (const r of baseRecipients) {
    try {
      const token = generateUnsubscribeToken(r.userId, businessId, 'biz');
      recipients.push({ ...r, unsubscribeUrl: `${siteUrl}/abonelik-iptal?token=${encodeURIComponent(token)}` });
    } catch (err) {
      logger.warn('eposta-kampanya: token üretimi başarısız — kampanya iptal edildi', {
        message: err instanceof Error ? err.message : 'unknown',
      });
      await supabaseAny
        .from('email_campaigns')
        .update({ status: 'failed', sent_count: 0, sent_at: new Date().toISOString() })
        .eq('id', kampanya.id);
      return NextResponse.json({ error: 'internal_error' }, { status: 500 });
    }
  }

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
