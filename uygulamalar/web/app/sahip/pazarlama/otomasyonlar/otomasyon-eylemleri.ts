'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { withAuth } from '@/src/lib/sunucu-eylem-kimlik-dogrulama';
import { hasOwnerBusiness } from '@/src/lib/veri/owner/sahip-isletmeleri';

const GECERLI_SABLON_ID = new Set([
  'birthday_message',
  'post_visit_thankyou',
  'inactive_winback',
  'loyalty_milestone',
  'review_request',
  'new_menu_announcement',
]);

export async function toggleOtomasyon(
  businessId: string,
  templateId: string,
  enable: boolean,
): Promise<{ error?: string }> {
  if (!GECERLI_SABLON_ID.has(templateId)) {
    return { error: 'invalid_template' };
  }

  return withAuth(async (userId) => {
    const supabase = await createSupabaseServerClient();

    const owned = await hasOwnerBusiness(supabase as any, userId, businessId);
    if (!owned) {
      return { error: 'forbidden' };
    }

    if (enable) {
      const { error } = await (supabase as any)
        .from('business_automations')
        .upsert(
          { business_id: businessId, template_id: templateId, is_enabled: true },
          { onConflict: 'business_id,template_id' },
        );
      if (error) return { error: error.message };
    } else {
      const { error } = await (supabase as any)
        .from('business_automations')
        .update({ is_enabled: false })
        .eq('business_id', businessId)
        .eq('template_id', templateId);
      if (error) return { error: error.message };
    }

    revalidatePath('/sahip/pazarlama/otomasyonlar');
    return {};
  });
}
