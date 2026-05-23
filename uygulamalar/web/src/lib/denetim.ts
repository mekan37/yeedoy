import type { SupabaseClient } from '@supabase/supabase-js';

interface AuditParams {
  supabase: SupabaseClient;
  userId: string;
  action: string;
  resourceType?: string;
  resourceId?: string;
  oldData?: Record<string, unknown>;
  newData?: Record<string, unknown>;
  metadata?: Record<string, unknown>;
  request?: Request | { headers: { get(name: string): string | null } };
}

/**
 * Fire-and-forget audit log entry.
 * Uses the provided supabase client (service role from API routes).
 * Never throws — audit failure must not block the main operation.
 */
export function logAudit(params: AuditParams): void {
  const ip = params.request?.headers.get('cf-connecting-ip')
    ?? params.request?.headers.get('x-real-ip')
    ?? undefined;
  const userAgent = params.request?.headers.get('user-agent') ?? undefined;

  void (params.supabase as any).from('audit_logs').insert({
    user_id: params.userId,
    action: params.action,
    resource_type: params.resourceType,
    resource_id: params.resourceId,
    old_data: params.oldData,
    new_data: params.newData,
    metadata: params.metadata,
    ip_address: ip,
    user_agent: userAgent,
  }).then(() => {}).catch((err: unknown) => {
    console.error('[audit] failed to write audit log', { action: params.action, err });
  });
}

// ── Action constants ───────────────────────────────────────────────────────────
export const AUDIT = {
  MEDIA_UPLOAD:          'media_upload',
  BUSINESS_UPDATE:       'business_update',
  BUSINESS_CREATE:       'business_create',
  MENU_CREATE:           'menu_create',
  MENU_UPDATE:           'menu_update',
  MENU_DELETE:           'menu_delete',
  MENU_PUBLISH:          'menu_publish',
  MENU_ITEM_CREATE:      'menu_item_create',
  MENU_ITEM_UPDATE:      'menu_item_update',
  MENU_ITEM_DELETE:      'menu_item_delete',
  MENU_RESTORE:          'menu_restore',
  MODERATION_ACTION:     'moderation_action',
  CLAIM_APPROVE:         'claim_approve',
  CLAIM_REJECT:          'claim_reject',
  PRESENTATION_UPDATE:   'presentation_settings_update',
} as const;
