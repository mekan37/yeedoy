import { NextResponse } from 'next/server';
import { z } from 'zod';
import { createSupabaseServerClient } from '@/src/lib/taban/sunucu';
import { getRequestIdentity, rateLimit } from '@/src/lib/oran-siniri';

const dietSchema = z.object({
  is_vegan: z.boolean(),
  is_vegetarian: z.boolean(),
  is_gluten_free: z.boolean(),
  is_dairy_free: z.boolean(),
});

export async function POST(request: Request) {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: 'unauthorized' }, { status: 401 });
  }

  const identity = getRequestIdentity({
    ip: request.headers.get('x-forwarded-for'),
    userAgent: request.headers.get('user-agent'),
  });
  const limit = rateLimit(`diet-profile:${user.id}:${identity}`, 20, 60_000);
  if (!limit.ok) {
    return NextResponse.json({ error: 'rate_limited' }, { status: 429 });
  }

  const rawBody = await request.json().catch(() => null);
  const parsed = dietSchema.safeParse(rawBody);

  if (!parsed.success) {
    return NextResponse.json(
      { error: 'invalid_payload', issues: parsed.error.flatten().fieldErrors },
      { status: 400 },
    );
  }

  const { is_vegan, is_vegetarian, is_gluten_free, is_dairy_free } = parsed.data;

  // @ts-expect-error user_diet_profiles may not be in generated types yet
  const { error } = await supabase.from('user_diet_profiles').upsert(
    {
      user_id: user.id,
      is_vegan,
      is_vegetarian,
      is_gluten_free,
      is_dairy_free,
      detected_by: 'manual',
      updated_at: new Date().toISOString(),
    },
    { onConflict: 'user_id' },
  );

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json({ ok: true });
}
