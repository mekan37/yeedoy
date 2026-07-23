import { z } from 'zod';

export const rpcAnalyticsEventSchema = z.enum([
  'menu_shared',
  'qr_scanned',
  'menu_link_opened',
  'app_install_from_menu',
  'business_reservation_click',
  'business_phone_click',
  'business_whatsapp_click',
  'business_order_click',
  'business_directions_click',
  'business_page_view',
  'menu_view',
  'discovery_impression',
  'discovery_business_click',
  'business_impression',
  'price_suggestion_submitted',
]);

export const trackEventSchema = z.object({
  eventName: z.enum(['page_view', 'category_view', 'item_view', 'item_click', 'qr_scanned', 'business_page_view', 'directions_click', 'phone_click', 'whatsapp_click']),
  businessId: z.string().uuid(),
  menuId: z.string().uuid().nullable().optional(),
  source: z.string().trim().min(1).max(64).default('web_next_public'),
  clientId: z.string().trim().max(128).nullish(),
  meta: z.record(z.string(), z.unknown()).default({}),
});

export type TrackEventInput = z.infer<typeof trackEventSchema>;
export type RpcAnalyticsEventName = z.infer<typeof rpcAnalyticsEventSchema>;

const rpcTrackResultSchema = z.object({
  ok: z.boolean(),
  code: z.string().optional(),
});

export function mapTrackEventToRpc(input: TrackEventInput) {
  const normalizedMeta = normalizeTrackMeta(input);

  switch (input.eventName) {
    case 'page_view':
      return {
        eventName: 'menu_link_opened' as const,
        meta: {
          ...normalizedMeta,
          event_alias: 'page_view',
        },
      };
    case 'category_view':
      return {
        eventName: 'menu_view' as const,
        meta: {
          ...normalizedMeta,
          event_alias: 'category_view',
        },
      };
    case 'item_view':
      return {
        eventName: 'menu_view' as const,
        meta: {
          ...normalizedMeta,
          event_alias: 'item_view',
        },
      };
    case 'item_click':
      return {
        eventName: 'menu_view' as const,
        meta: {
          ...normalizedMeta,
          event_alias: 'item_click',
        },
      };
    case 'qr_scanned':
      return {
        eventName: 'qr_scanned' as const,
        meta: normalizedMeta,
      };
    case 'business_page_view':
      return {
        eventName: 'business_page_view' as const,
        meta: { ...normalizedMeta, event_alias: 'business_page_view' },
      };
    case 'directions_click':
      return {
        eventName: 'business_directions_click' as const,
        meta: normalizedMeta,
      };
    case 'phone_click':
      return {
        eventName: 'business_phone_click' as const,
        meta: normalizedMeta,
      };
    case 'whatsapp_click':
      return {
        eventName: 'business_whatsapp_click' as const,
        meta: normalizedMeta,
      };
  }
}

export function parseRpcTrackResult(data: unknown) {
  const parsed = rpcTrackResultSchema.safeParse(data);
  if (!parsed.success) {
    return {
      ok: false,
      code: 'invalid_rpc_response',
    } as const;
  }

  return parsed.data;
}

function normalizeTrackMeta(input: TrackEventInput) {
  const meta = { ...input.meta };
  const itemId =
    typeof meta.menu_item_id === 'string'
      ? meta.menu_item_id
      : typeof meta.item_id === 'string'
        ? meta.item_id
        : null;

  if (itemId && !meta.menu_item_id) {
    meta.menu_item_id = itemId;
  }

  return meta;
}
