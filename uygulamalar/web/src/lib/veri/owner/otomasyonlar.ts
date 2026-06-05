import { logger } from '@/src/lib/kayitci';

export interface AutomationRow {
  id: string;
  business_id: string;
  template_id: string;
  is_enabled: boolean;
  created_at: string;
}

export async function getOwnerAutomations(
  supabase: any,
  businessIds: string[],
): Promise<{ automations: AutomationRow[]; fetchError: boolean }> {
  if (businessIds.length === 0) {
    return { automations: [], fetchError: false };
  }

  const { data, error } = await supabase
    .from('business_automations')
    .select('id, business_id, template_id, is_enabled, created_at')
    .in('business_id', businessIds);

  if (error) {
    logger.warn('getOwnerAutomations failed', { code: error.code });
    return { automations: [], fetchError: true };
  }

  return { automations: (data ?? []) as AutomationRow[], fetchError: false };
}
