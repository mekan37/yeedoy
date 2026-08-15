import { NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { rateLimit } from '@/src/lib/oran-siniri';
import { generateUnsubscribeToken } from '@/src/lib/email/unsubscribe-token';
import { sendEmailCampaign } from '@/src/lib/email/resend-client';
import { logger } from '@/src/lib/kayitci';
import { epostaKampanyaGovdesi } from './sema';
import { stripHtml, escapeHtml } from './metin-temizle';

export async function POST(request: Request) {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) {
    return NextResponse.json({ error: 'unauthorized' }, { status: 401 });
  }

  const limitResult = rateLimit(`eposta-kampanya:${user.id}`, 3, 3_600_000);
  if (!limitResult.ok) {
    return NextResponse.json(
      { error: 'rate_limited', issues: { general: ['Saatte en fazla 3 kampanya gönderilebilir.'] } },
      { status: 429 },
    );
  }

  const rawBody = await request.json().catch(() => null);
  const parsed = epostaKampanyaGovdesi.safeParse(rawBody);
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_payload', issues: parsed.error.flatten().fieldErrors }, { status: 400 });
  }

  const { businessId, subject, body, targetSegment } = parsed.data;
  const safeBody = stripHtml(body).trim();

  if (!process.env.UNSUBSCRIBE_HMAC_SECRET?.trim()) {
    logger.warn('eposta-kampanya: UNSUBSCRIBE_HMAC_SECRET yapılandırılmamış — kampanya iptal (6563 md.9/3)');
    return NextResponse.json(
      { error: 'internal_error', issues: { general: ['unsubscribe_secret_not_configured'] } },
      { status: 500 },
    );
  }

  const supabaseAny = supabase as unknown as { rpc: (fn: string, args?: unknown) => any };

  const { data: campaignId, error: createError } = await supabaseAny.rpc('create_email_campaign_v1', {
    p_business_id: businessId,
    p_subject: subject.trim(),
    p_html_body: `<p>${escapeHtml(safeBody)}</p>`,
    p_target_segment: targetSegment,
  }) as { data: string | null; error: { message: string } | null };

  if (createError || !campaignId) {
    logger.warn('eposta-kampanya: create_email_campaign_v1 başarısız', { message: createError?.message });
    return NextResponse.json({ error: 'forbidden' }, { status: 403 });
  }

  const { data: recipients, error: recipientsError } = await supabaseAny.rpc(
    'get_email_campaign_recipients_v1',
    { p_business_id: businessId, p_target_segment: targetSegment },
  ) as { data: Array<{ user_id: string; email: string; display_name: string }> | null; error: { message: string } | null };

  if (recipientsError) {
    logger.warn('eposta-kampanya: get_email_campaign_recipients_v1 başarısız', { message: recipientsError.message });
    return NextResponse.json({ error: 'internal_error' }, { status: 500 });
  }

  const baseRecipients = recipients ?? [];

  const siteUrl = process.env.NEXT_PUBLIC_SITE_URL?.trim() || 'https://yeedoy.com';
  const emailRecipients: Array<{ email: string; displayName: string; htmlBody: string }> = [];
  for (const r of baseRecipients) {
    try {
      const token = generateUnsubscribeToken(r.user_id, businessId, 'biz');
      const unsubscribeUrl = `${siteUrl}/abonelik-iptal?token=${encodeURIComponent(token)}`;
      emailRecipients.push({
        email: r.email,
        displayName: r.display_name,
        htmlBody: `<p>${escapeHtml(safeBody)}</p><p style="margin-top:24px;font-size:12px;color:#888"><a href="${unsubscribeUrl}">Abonelikten çık</a></p>`,
      });
    } catch (err) {
      logger.warn('eposta-kampanya: token üretimi başarısız — kampanya iptal edildi', {
        message: err instanceof Error ? err.message : 'unknown',
      });
      return NextResponse.json({ error: 'internal_error' }, { status: 500 });
    }
  }

  const emailResult = await sendEmailCampaign(emailRecipients, {
    subject,
    fromName: 'Yeedoy',
    fromEmail: process.env.EMAIL_FROM?.trim() || 'noreply@yeedoy.com',
  });

  const { error: updateError } = await (supabase as any)
    .from('email_campaigns')
    .update({
      sent_count: emailResult.success_count,
      sent_at: new Date().toISOString(),
    })
    .eq('id', campaignId);

  if (updateError) {
    logger.warn('eposta-kampanya: sent_count/sent_at güncellemesi başarısız', { message: updateError.message });
  }

  return NextResponse.json({
    data: {
      campaignId,
      sentCount: emailResult.success_count,
      providerNotConfigured: emailResult.provider_not_configured ?? false,
    },
  });
}
