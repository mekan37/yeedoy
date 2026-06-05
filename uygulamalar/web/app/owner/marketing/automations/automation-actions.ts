'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { hasOwnerBusiness } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { logger } from '@/src/lib/kayitci';

export type AutomationActionResult = { ok: true } | { ok: false; error: string };

const VALID_TEMPLATE_IDS = new Set([
  'birthday_message',
  'post_visit_thankyou',
  'inactive_winback',
  'loyalty_milestone',
  'review_request',
  'new_menu_announcement',
]);

export async function toggleAutomationAction(
  _prevState: AutomationActionResult | null,
  formData: FormData,
): Promise<AutomationActionResult> {
  const supabase = await createSupabaseServerClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return { ok: false, error: 'unauthorized' };
  }

  const businessId = formData.get('business_id');
  const templateId = formData.get('template_id');
  const enableRaw = formData.get('enable');

  if (
    typeof businessId !== 'string' ||
    !businessId ||
    typeof templateId !== 'string' ||
    !templateId ||
    typeof enableRaw !== 'string'
  ) {
    return { ok: false, error: 'invalid_payload' };
  }

  if (!VALID_TEMPLATE_IDS.has(templateId)) {
    return { ok: false, error: 'invalid_template' };
  }

  const owned = await hasOwnerBusiness(supabase as any, user.id, businessId);
  if (!owned) {
    return { ok: false, error: 'forbidden' };
  }

  const enable = enableRaw === 'true';

  if (enable) {
    const { error } = await (supabase as any)
      .from('business_automations')
      .upsert(
        { business_id: businessId, template_id: templateId, is_enabled: true },
        { onConflict: 'business_id,template_id' },
      );
    if (error) {
      logger.warn('toggleAutomationAction upsert failed', { code: error.code });
      return { ok: false, error: 'internal_error' };
    }
  } else {
    const { error } = await (supabase as any)
      .from('business_automations')
      .update({ is_enabled: false })
      .eq('business_id', businessId)
      .eq('template_id', templateId);
    if (error) {
      logger.warn('toggleAutomationAction update failed', { code: error.code });
      return { ok: false, error: 'internal_error' };
    }
  }

  revalidatePath('/owner/marketing/automations');
  return { ok: true };
}
