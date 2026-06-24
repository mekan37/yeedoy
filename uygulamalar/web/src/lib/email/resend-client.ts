import { logger } from '@/src/lib/kayitci';

const RESEND_API_URL = 'https://api.resend.com/emails';
const BATCH_SIZE = 50;

export type EmailSendResult = {
  success_count: number;
  failure_count: number;
  provider_not_configured?: true;
};

/**
 * Sends marketing emails via Resend API using fetch (no SDK).
 * Fails safely when RESEND_API_KEY is not configured.
 * API key and recipient email addresses are never logged.
 */
export async function sendEmailCampaign(
  recipients: Array<{ email: string; displayName: string; unsubscribeUrl?: string }>,
  campaign: {
    subject: string;
    htmlBody: string;
    fromName: string;
    fromEmail: string;
    /** Her alıcı için ayrı URL üretilmişse recipients[].unsubscribeUrl kullanılır.
     *  Tek global URL verilmişse tüm alıcılara bu URL eklenir.
     *  İkisi de yoksa footer eklenmez. */
    unsubscribeUrl?: string;
  },
): Promise<EmailSendResult> {
  const apiKey = process.env.RESEND_API_KEY?.trim();

  if (!apiKey) {
    logger.warn('resend: provider not configured — RESEND_API_KEY missing');
    return { success_count: 0, failure_count: 0, provider_not_configured: true };
  }

  if (recipients.length === 0) {
    logger.info('resend: no recipients to send to');
    return { success_count: 0, failure_count: 0 };
  }

  const from = `${campaign.fromName} <${campaign.fromEmail}>`;
  let totalSuccess = 0;
  let totalFailure = 0;

  // Send in batches of BATCH_SIZE (50) using Resend single-email endpoint sequentially
  for (let i = 0; i < recipients.length; i += BATCH_SIZE) {
    const batch = recipients.slice(i, i + BATCH_SIZE);
    const { success, failure } = await sendBatch(batch, campaign.subject, campaign.htmlBody, from, apiKey, campaign.unsubscribeUrl);
    totalSuccess += success;
    totalFailure += failure;
  }

  logger.info('resend: campaign send complete', {
    success_count: totalSuccess,
    failure_count: totalFailure,
  });

  return { success_count: totalSuccess, failure_count: totalFailure };
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

async function sendBatch(
  recipients: Array<{ email: string; displayName: string; unsubscribeUrl?: string }>,
  subject: string,
  htmlBody: string,
  from: string,
  apiKey: string,
  globalUnsubscribeUrl?: string,
): Promise<{ success: number; failure: number }> {
  const results = await Promise.allSettled(
    recipients.map((r) =>
      sendSingleEmail(r, subject, htmlBody, from, apiKey, r.unsubscribeUrl ?? globalUnsubscribeUrl),
    ),
  );

  let success = 0;
  let failure = 0;

  for (const result of results) {
    if (result.status === 'fulfilled' && result.value) {
      success++;
    } else {
      failure++;
    }
  }

  return { success, failure };
}

async function sendSingleEmail(
  recipient: { email: string; displayName: string },
  subject: string,
  htmlBody: string,
  from: string,
  apiKey: string,
  unsubscribeUrl?: string,
): Promise<boolean> {
  // Unsubscribe footer (her e-postada bulunması 6563 md.9/3 gereği)
  const footer = unsubscribeUrl
    ? `<p style="margin-top:32px;font-size:11px;color:#888;text-align:center;line-height:1.6;">` +
      `Bu e-postayı almak istemiyorsanız, ` +
      `<a href="${unsubscribeUrl}" style="color:#7F1D1D;">aboneliğinizi iptal edebilirsiniz</a>.` +
      `</p>`
    : '';

  const fullHtml = htmlBody + footer;

  try {
    const res = await fetch(RESEND_API_URL, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from,
        to: recipient.email,
        subject,
        html: fullHtml,
      }),
    });

    if (res.status === 401 || res.status === 403) {
      // Auth failure — never expose API key details
      logger.warn('resend: send auth failed', { status: res.status });
      return false;
    }

    if (res.status === 422 || res.status === 400) {
      // Invalid payload (e.g. bad email address) — log status only
      logger.warn('resend: send rejected', { status: res.status });
      return false;
    }

    return res.ok;
  } catch {
    // Network or parse error — never surface email address in log
    return false;
  }
}
