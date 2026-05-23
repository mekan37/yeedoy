'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { withAuth } from '@/src/lib/sunucu-eylem-kimlik-dogrulama';

export async function toggleOtomasyon(
  businessId: string,
  templateId: string,
  enable: boolean,
): Promise<{ error?: string }> {
  return withAuth(async () => {
    const supabase = await createSupabaseServerClient();

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
