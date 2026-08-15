import { logger } from '@/src/lib/kayitci';

const RESEND_API_URL = 'https://api.resend.com/emails';
const BATCH_SIZE = 50;

export type EmailSendResult = {
  success_count: number;
  failure_count: number;
  provider_not_configured?: true;
};

/**
 * Kampanya e-postalarını Resend API üzerinden (SDK yok, fetch) gönderir.
 * RESEND_API_KEY tanımsızsa fail-safe döner. API key ve e-posta adresleri
 * hiçbir zaman loglanmaz.
 */
export async function sendEmailCampaign(
  recipients: Array<{ email: string; displayName: string; htmlBody: string }>,
  campaign: { subject: string; fromName: string; fromEmail: string },
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

  for (let i = 0; i < recipients.length; i += BATCH_SIZE) {
    const batch = recipients.slice(i, i + BATCH_SIZE);
    const { success, failure } = await sendBatch(batch, campaign.subject, from, apiKey);
    totalSuccess += success;
    totalFailure += failure;
  }

  logger.info('resend: campaign send complete', { success_count: totalSuccess, failure_count: totalFailure });
  return { success_count: totalSuccess, failure_count: totalFailure };
}

async function sendBatch(
  recipients: Array<{ email: string; displayName: string; htmlBody: string }>,
  subject: string,
  from: string,
  apiKey: string,
): Promise<{ success: number; failure: number }> {
  const results = await Promise.allSettled(
    recipients.map((r) => sendSingleEmail(r, subject, from, apiKey)),
  );

  let success = 0;
  let failure = 0;
  for (const result of results) {
    if (result.status === 'fulfilled' && result.value) success++;
    else failure++;
  }
  return { success, failure };
}

async function sendSingleEmail(
  recipient: { email: string; displayName: string; htmlBody: string },
  subject: string,
  from: string,
  apiKey: string,
): Promise<boolean> {
  try {
    const res = await fetch(RESEND_API_URL, {
      method: 'POST',
      headers: { Authorization: `Bearer ${apiKey}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ from, to: recipient.email, subject, html: recipient.htmlBody }),
    });

    if (res.status === 401 || res.status === 403) {
      logger.warn('resend: send auth failed', { status: res.status });
      return false;
    }
    if (res.status === 422 || res.status === 400) {
      logger.warn('resend: send rejected', { status: res.status });
      return false;
    }
    return res.ok;
  } catch {
    return false;
  }
}
