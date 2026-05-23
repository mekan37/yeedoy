import { z } from 'zod';
import { NextResponse } from 'next/server';
import { revalidatePath } from 'next/cache';
import { appConfig } from '@/src/lib/ayarlar';

const slugPattern = /^[a-z0-9_-]{1,80}$/;

const bodySchema = z.object({
  secret: z.string().min(1),
  slug: z.string().min(1).regex(slugPattern).optional(),
  businessId: z.string().uuid().optional(),
});

/**
 * POST /sunucu/yeniden-dogrulama
 *
 * On-demand cache invalidation for public menu pages.
 * Called by deployment pipeline or Supabase webhook after menu data changes.
 *
 * Body: { secret: string, slug?: string, businessId?: uuid }
 * - slug       → revalidates /m/<slug>
 * - businessId → revalidates /m/<businessId> and /karekod/<businessId>
 * - neither    → revalidates all /m/* pages (broad sweep)
 *
 * Returns: { ok: true, invalidated: string[] }
 */
export async function POST(request: Request) {
  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: 'invalid_json' }, { status: 400 });
  }

  const parsed = bodySchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_payload' }, { status: 400 });
  }

  const expectedSecret = appConfig.revalidateSecret();
  if (!expectedSecret) {
    return NextResponse.json(
      { error: 'revalidation_not_configured' },
      { status: 503 },
    );
  }

  if (parsed.data.secret !== expectedSecret) {
    return NextResponse.json({ error: 'invalid_secret' }, { status: 401 });
  }

  const invalidated: string[] = [];

  if (parsed.data.slug) {
    revalidatePath(`/m/${parsed.data.slug}`);
    invalidated.push(`/m/${parsed.data.slug}`);
  }

  if (parsed.data.businessId) {
    revalidatePath(`/m/${parsed.data.businessId}`);
    revalidatePath(`/karekod/${parsed.data.businessId}`);
    invalidated.push(`/m/${parsed.data.businessId}`, `/karekod/${parsed.data.businessId}`);
  }

  if (invalidated.length === 0) {
    // Broad sweep: revalidate all public menu pages
    revalidatePath('/m/[slug]', 'page');
    invalidated.push('/m/[slug] (all)');
  }

  return NextResponse.json({ ok: true, invalidated });
}

