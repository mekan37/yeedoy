import { z } from 'zod';
import { NextResponse } from 'next/server';
import { createHash } from 'crypto';
import { getRequestIdentity, rateLimit, getClientIp } from '@/src/lib/oran-siniri';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

const schema = z.object({
  listId: z.string().uuid(),
  itemId: z.string().uuid(),
  vote: z.union([z.literal(1), z.literal(-1), z.literal(0)]),
});

export async function POST(request: Request) {
  const identity = getRequestIdentity({
    ip: getClientIp(request.headers),
    userAgent: request.headers.get('user-agent'),
  });
  const limit = rateLimit(`collab-vote:${identity}`, 30, 60_000);
  if (!limit.ok) return NextResponse.json({ error: 'rate_limited' }, { status: 429 });

  const body = await request.json().catch(() => null);
  const parsed = schema.safeParse(body);
  if (!parsed.success) return NextResponse.json({ error: 'invalid_payload' }, { status: 400 });

  // Hash the identity string (IP:UA) before storing — avoids plain-text PII in DB
  const voterKey = createHash('sha256').update(identity).digest('hex');

  const supabase = await createSupabaseServerClient();
  const supabaseAny = supabase as unknown as { from: (t: string) => any; rpc: (fn: string, args?: any) => any; storage: any; auth: any };

  if (parsed.data.vote === 0) {
    // Oyu kaldır
    await supabaseAny
      .from('collab_list_votes')
      .delete()
      .eq('list_id', parsed.data.listId)
      .eq('item_id', parsed.data.itemId)
      .eq('voter_ip', voterKey);
  } else {
    // Oy upsert — aynı IP aynı item'a bir oy
    await supabaseAny
      .from('collab_list_votes')
      .upsert({
        list_id: parsed.data.listId,
        item_id: parsed.data.itemId,
        vote: parsed.data.vote,
        voter_ip: voterKey,
      }, { onConflict: 'list_id,item_id,voter_ip' });
  }

  return NextResponse.json({ ok: true });
}
