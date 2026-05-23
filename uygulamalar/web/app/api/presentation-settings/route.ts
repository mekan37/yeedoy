import { revalidatePath, revalidateTag } from 'next/cache';
import { NextResponse } from 'next/server';
import { buildMenuHref } from '@/src/lib/menu-links';
import { createSupabaseServerClient } from '@/src/lib/supabase/server';
import { canManageBusiness } from '@/src/lib/qr-access';
import { logger } from '@/src/lib/logger';
import { getRequestIdentity, rateLimit } from '@/src/lib/rate-limit';
import { presentationSavePayloadSchema } from '@/src/lib/presentation-settings';
import type { Database } from '@/src/lib/supabase/database.types';

type PresentationInsert = Database['public']['Tables']['business_menu_presentation_settings']['Insert'];
type PresentationRow = Database['public']['Tables']['business_menu_presentation_settings']['Row'];
type BusinessPathRow = Pick<Database['public']['Tables']['businesses']['Row'], 'id' | 'slug' | 'public_slug'>;

export async function POST(request: Request) {
  const identity = getRequestIdentity({
    ip: request.headers.get('x-forwarded-for'),
    userAgent: request.headers.get('user-agent'),
  });
  const limit = rateLimit(`presentation-settings:${identity}`, 20, 60_000);
  if (!limit.ok) {
    return NextResponse.json({ error: 'rate_limited' }, { status: 429 });
  }

  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: 'unauthorized' }, { status: 401 });
  }

  const rawBody = await request.json().catch(() => null);
  const parsed = presentationSavePayloadSchema.safeParse(rawBody);
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_payload' }, { status: 400 });
  }

  const canManage = await canManageBusiness(parsed.data.businessId);
  if (!canManage) {
    return NextResponse.json({ error: 'forbidden' }, { status: 403 });
  }

  const payload: PresentationInsert = {
    business_id: parsed.data.businessId,
    default_lang: parsed.data.defaultLang,
    template_key: parsed.data.templateKey,
    settings: parsed.data.settings,
    logo_url: parsed.data.logoUrl,
    cover_url: parsed.data.coverUrl,
    background_url: parsed.data.backgroundUrl,
  };

  const presentationTable = supabase.from('business_menu_presentation_settings') as unknown as {
    upsert: (
      values: PresentationInsert,
      options: { onConflict: string },
    ) => {
      select: (columns: string) => {
        single: () => Promise<{ data: PresentationRow | null; error: unknown }>;
      };
    };
  };

  const { data, error } = await presentationTable
    .upsert(payload, { onConflict: 'business_id' })
    .select('*')
    .single();

  if (error) {
    logger.warn('Failed to save business presentation settings', {
      businessId: parsed.data.businessId,
      error,
    });
    return NextResponse.json({ error: 'save_failed' }, { status: 500 });
  }

  const businessPathTable = supabase.from('businesses') as unknown as {
    select: (columns: string) => {
      eq: (column: 'id', value: string) => {
        maybeSingle: () => Promise<{ data: BusinessPathRow | null; error: unknown }>;
      };
    };
  };
  const { data: businessPath } = await businessPathTable
    .select('id,slug,public_slug')
    .eq('id', parsed.data.businessId)
    .maybeSingle()
    .catch(() => ({ data: null, error: null }));
  const menuPaths = new Set<string>([
    buildMenuHref({ businessId: parsed.data.businessId }),
  ]);
  if (businessPath) {
    menuPaths.add(
      buildMenuHref({
        businessId: businessPath.id,
        businessSlug: businessPath.slug,
        businessPublicSlug: businessPath.public_slug,
      }),
    );
  }

  revalidateTag('business-menu-presentation-settings');
  for (const path of menuPaths) {
    revalidatePath(path);
  }
  revalidatePath(`/qr/${parsed.data.businessId}`);

  return NextResponse.json({ ok: true, data });
}
