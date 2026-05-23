import { unstable_cache } from 'next/cache';
import { createSupabasePublicClient } from '@/src/lib/supabase/public';
import { logger } from '@/src/lib/logger';
import type { Database } from '@/src/lib/supabase/database.types';
import {
  DEFAULT_PRESENTATION_RECORD,
  resolvePresentationRecord,
  type ResolvedPresentationRecord,
} from '@/src/lib/presentation-settings';

type PresentationRow = Database['public']['Tables']['business_menu_presentation_settings']['Row'];

const getPresentationSettingsCached = unstable_cache(
  async (businessId: string) => {
    const supabase = createSupabasePublicClient();
    const { data, error } = await supabase
      .from('business_menu_presentation_settings')
      .select('*')
      .eq('business_id', businessId)
      .maybeSingle();

    if (error) {
      logger.warn('Failed to fetch business presentation settings', { businessId, error });
      return null;
    }

    return (data ?? null) as PresentationRow | null;
  },
  ['business-menu-presentation-settings'],
  {
    revalidate: 120,
    tags: ['business-menu-presentation-settings'],
  },
);

export async function getBusinessPresentationSettings(businessId: string) {
  return getPresentationSettingsCached(businessId);
}

export async function getResolvedBusinessPresentationSettings(
  businessId: string,
): Promise<ResolvedPresentationRecord> {
  const row = await getBusinessPresentationSettings(businessId);
  return (
    resolvePresentationRecord(
      row
        ? {
            businessId: row.business_id,
            defaultLang: row.default_lang,
            templateKey: row.template_key,
            settings: row.settings,
            logoUrl: row.logo_url,
            coverUrl: row.cover_url,
            backgroundUrl: row.background_url,
            updatedAt: row.updated_at,
          }
        : {
            ...DEFAULT_PRESENTATION_RECORD,
            businessId,
          },
    ) ?? {
      ...DEFAULT_PRESENTATION_RECORD,
      businessId,
    }
  );
}
