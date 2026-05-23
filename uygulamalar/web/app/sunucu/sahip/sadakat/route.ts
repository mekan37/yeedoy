import { z } from 'zod';
import { NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

const schema = z.object({
  businessId: z.string().uuid(),
  name: z.string().min(2).max(60).transform((s) => s.trim()),
  stampsNeeded: z.number().int().min(3).max(20),
  rewardDesc: z.string().min(3).max(100).transform((s) => s.trim()),
});

export async function POST(request: Request) {
  const body = await request.json().catch(() => null);
  const parsed = schema.safeParse(body);
  if (!parsed.success) return NextResponse.json({ error: 'invalid_payload' }, { status: 400 });

  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'unauthorized' }, { status: 401 });

  const { data, error } = await (supabase as any).rpc('create_loyalty_program_v1', {
    p_business_id: parsed.data.businessId,
    p_name: parsed.data.name,
    p_stamps_needed: parsed.data.stampsNeeded,
    p_reward_desc: parsed.data.rewardDesc,
  });

  if (error) return NextResponse.json({ error: 'internal_error' }, { status: 500 });
  if (!data?.ok) return NextResponse.json({ error: data?.error }, { status: 403 });

  return NextResponse.json({ ok: true, programId: data.program_id });
}
