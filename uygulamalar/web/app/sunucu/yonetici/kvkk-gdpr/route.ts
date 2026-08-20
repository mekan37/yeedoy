import { NextResponse } from 'next/server';
import { rateLimit } from '@/src/lib/oran-siniri';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { z } from 'zod';

const slugSchema = z.string().min(1).max(120).regex(/^[a-z0-9]+(-[a-z0-9]+)*$/);

const upsertSchema = z.object({
  id: z.string().uuid().nullable().optional(),
  slug: slugSchema,
  title: z.string().min(1).max(120),
  description: z.string().max(200).nullable().optional(),
  content: z.string().min(1),
  isPublished: z.boolean(),
  sortOrder: z.number().int().min(0),
});
const deleteSchema = z.object({ id: z.string().uuid() });

type SupabaseAny = { rpc: (fn: string, args?: Record<string, unknown>) => Promise<{ data: unknown; error: { message?: string } | null }> };

async function guard(sb: SupabaseAny, userId: string): Promise<NextResponse | null> {
  const { data: yetkili } = await sb.rpc('has_permission_v1', { p_permission: 'page:kvkk-gdpr' });
  if (!yetkili) return NextResponse.json({ error: 'forbidden' }, { status: 403 });

  const rl = rateLimit(`kvkk-belge:${userId}`, 30, 3_600_000);
  if (!rl.ok) return NextResponse.json({ error: 'rate_limited' }, { status: 429 });

  return null;
}

function mapPgError(error: { message?: string } | null): { status: number; error: string } {
  const msg = error?.message ?? '';
  if (msg.includes('unauthorized')) return { status: 403, error: 'forbidden' };
  if (msg.includes('not_found')) return { status: 404, error: 'not_found' };
  if (msg.includes('validation_error')) return { status: 422, error: msg.replace('validation_error: ', '') };
  if (msg.includes('duplicate key')) return { status: 409, error: 'slug_conflict' };
  return { status: 500, error: 'internal_error' };
}

export async function POST(request: Request) {
  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as SupabaseAny;
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'unauthorized' }, { status: 401 });

  const guardRes = await guard(sb, user.id);
  if (guardRes) return guardRes;

  const parsed = upsertSchema.safeParse(await request.json().catch(() => null));
  if (!parsed.success) return NextResponse.json({ error: 'invalid_payload', issues: parsed.error.flatten().fieldErrors }, { status: 400 });

  const { data, error } = await sb.rpc('admin_upsert_legal_document_v1', {
    p_id: parsed.data.id ?? null,
    p_slug: parsed.data.slug,
    p_title: parsed.data.title,
    p_description: parsed.data.description ?? null,
    p_content: parsed.data.content,
    p_is_published: parsed.data.isPublished,
    p_sort_order: parsed.data.sortOrder,
  });
  if (error) {
    const m = mapPgError(error);
    return NextResponse.json({ error: m.error }, { status: m.status });
  }
  return NextResponse.json({ data: { id: data } }, { status: 200 });
}

export async function DELETE(request: Request) {
  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as SupabaseAny;
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'unauthorized' }, { status: 401 });

  const guardRes = await guard(sb, user.id);
  if (guardRes) return guardRes;

  const parsed = deleteSchema.safeParse(await request.json().catch(() => null));
  if (!parsed.success) return NextResponse.json({ error: 'invalid_payload' }, { status: 400 });

  const { error } = await sb.rpc('admin_delete_legal_document_v1', { p_id: parsed.data.id });
  if (error) {
    const m = mapPgError(error);
    return NextResponse.json({ error: m.error }, { status: m.status });
  }
  return NextResponse.json({ data: { ok: true } }, { status: 200 });
}
