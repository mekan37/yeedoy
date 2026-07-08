import { createClient } from '@supabase/supabase-js';
import { logger } from '@/src/lib/kayitci';
import { sendEmailCampaign } from './resend-client';

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL!;

/**
 * Sends a transactional e-mail to the claimant after an admin approves or
 * rejects their owner_claims row. Fails silently (logs only) so a missing
 * RESEND_API_KEY/SUPABASE_SERVICE_ROLE_KEY never blocks the actual
 * approve/reject decision — the claim status write already happened by the
 * time this runs.
 */
export async function sendClaimDecisionEmail(params: {
  userId: string;
  businessName: string;
  decision: 'approved' | 'rejected';
  note?: string | null;
}): Promise<void> {
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY?.trim();
  if (!serviceRoleKey) {
    logger.warn('send-claim-decision-email: service role key not configured');
    return;
  }

  try {
    const client = createClient(SUPABASE_URL, serviceRoleKey);
    const { data, error } = await client.auth.admin.getUserById(params.userId);
    const email = data?.user?.email;
    if (error || !email) {
      logger.warn('send-claim-decision-email: user email not found');
      return;
    }

    const subject = params.decision === 'approved'
      ? `${params.businessName} sahiplik talebiniz onaylandı`
      : `${params.businessName} sahiplik talebiniz değerlendirildi`;

    const bodyHtml = params.decision === 'approved'
      ? `<p>Merhaba,</p>
         <p><strong>${escapeHtml(params.businessName)}</strong> işletmesi için yaptığınız sahiplik talebi onaylandı.
         İşletme panelinize giriş yaparak menü, fotoğraf ve işletme bilgilerinizi yönetebilirsiniz.</p>`
      : `<p>Merhaba,</p>
         <p><strong>${escapeHtml(params.businessName)}</strong> işletmesi için yaptığınız sahiplik talebi değerlendirildi
         ve şu an için onaylanmadı.</p>
         ${params.note ? `<p><strong>Not:</strong> ${escapeHtml(params.note)}</p>` : ''}
         <p>Talebinizin gerçek sahiplik bilgisini doğru yansıttığından eminseniz destek ekibimizle iletişime geçebilirsiniz.</p>`;

    const html = `
      <div style="font-family:system-ui,-apple-system,sans-serif;max-width:480px;margin:0 auto;color:#111827;">
        <h2 style="color:#7F1D1D;margin-bottom:16px;">Yeedoy</h2>
        ${bodyHtml}
      </div>
    `;

    const result = await sendEmailCampaign(
      [{ email, displayName: '' }],
      {
        subject,
        htmlBody: html,
        fromName: 'Yeedoy',
        fromEmail: process.env.RESEND_FROM_EMAIL ?? 'noreply@yeedoy.com',
      },
    );

    if (result.provider_not_configured) {
      logger.warn('send-claim-decision-email: RESEND_API_KEY not configured');
    } else if (result.failure_count > 0) {
      logger.warn('send-claim-decision-email: send failed');
    }
  } catch (err) {
    logger.warn('send-claim-decision-email: unexpected error', {
      message: err instanceof Error ? err.message : 'unknown',
    });
  }
}

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}
