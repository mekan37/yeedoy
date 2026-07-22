import { Resend } from 'resend';
import { appConfig } from '@/src/lib/ayarlar';
import { logger } from '@/src/lib/kayitci';

let client: Resend | null | undefined;

function getClient(): Resend | null {
  if (client !== undefined) return client;
  const apiKey = appConfig.resendApiKey();
  client = apiKey ? new Resend(apiKey) : null;
  return client;
}

export async function sendEmail(params: { to: string; subject: string; html: string }): Promise<boolean> {
  const resend = getClient();
  if (!resend) {
    logger.warn('sendEmail: RESEND_API_KEY tanımlı değil, e-posta gönderilmedi', { to: params.to, subject: params.subject });
    return false;
  }

  try {
    const { error } = await resend.emails.send({
      from: appConfig.emailFrom(),
      to: params.to,
      subject: params.subject,
      html: params.html,
    });
    if (error) {
      logger.error('sendEmail: Resend hatası', { to: params.to, subject: params.subject, error });
      return false;
    }
    return true;
  } catch (error) {
    logger.error('sendEmail: beklenmeyen hata', { to: params.to, subject: params.subject, error });
    return false;
  }
}
