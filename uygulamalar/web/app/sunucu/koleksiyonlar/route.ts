import { NextResponse } from 'next/server';
import { z } from 'zod';
import { createSupabaseServerClient } from '@/src/lib/taban/sunucu';
import { rateLimit } from '@/src/lib/oran-siniri';

const createCollectionSchema = z.object({
  name: z.string().min(1).max(80).transform((s) => s.trim()),
  description: z.string().max(300).nullable().optional().transform((s) => s?.trim() || null),
});

export async function POST(request: Request) {
  const supabase = await createSupabaseServerClient();
  const supabaseAny = supabase as unknown as { from: (t: string) => any; rpc: (fn: string, args?: any) => any; storage: any; auth: any };
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: 'unauthorized' }, { status: 401 });
  }

  const limit = rateLimit(`collections:create:${user.id}`, 10, 60_000);
  if (!limit.ok) {
    return NextResponse.json({ error: 'rate_limited' }, { status: 429 });
  }

  const rawBody = await request.json().catch(() => null);
  const parsed = createCollectionSchema.safeParse(rawBody);
  if (!parsed.success) {
    return NextResponse.json(
      { error: 'invalid_payload', issues: parsed.error.flatten().fieldErrors },
      { status: 400 },
    );
  }

  const { name, description } = parsed.data;

  const { data, error } = await supabaseAny.rpc('create_collection_v1', {
    p_name: name,
    p_description: description ?? null,
  });

  if (error) {
    // Fallback: direct insert if RPC not available
    const { data: inserted, error: insertError } = await supabaseAny
      .from('collections')
      .insert({ user_id: user.id, name, description: description ?? null })
      .select('id, name')
      .single();

    if (insertError) {
      return NextResponse.json({ error: 'insert_failed' }, { status: 500 });
    }

    return NextResponse.json({ ok: true, collection: inserted });
  }

  return NextResponse.json({ ok: true, collection: data });
}
