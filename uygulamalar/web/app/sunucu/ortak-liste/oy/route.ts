import { z } from 'zod';
import { NextResponse } from 'next/server';
import { createHash } from 'crypto';
import { getRequestIdentity, rateLimit, getClientIp } from '@/src/lib/oran-siniri';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

const schema = z.object({
  listId: z.string().uuid(),
  itemId: z.string().uuid(),
  vote: z.union([z.literal(1), z.literal(-1), z.literal(0)]),
  // Tarayıcı başına bir kere üretilip localStorage'da saklanan rastgele kimlik
  // (bkz. oy-verme-yuzeyi.tsx). Eskiden dedup anahtarı IP+User-Agent'tı —
  // User-Agent istemci kontrolünde olduğu için tek karakter değiştirmek yeni
  // bir "seçmen" açıyordu (oy şişirme); ayrıca aynı Wi-Fi'daki (aynı IP)
  // birden fazla gerçek kişinin oyu da birbirini eziyordu.
  voterId: z.string().uuid(),
});

export async function POST(request: Request) {
  const identity = getRequestIdentity({
    ip: getClientIp(request.headers),
    userAgent: request.headers.get('user-agent'),
  });
  const limit = await rateLimit(`collab-vote:${identity}`, 30, 60_000);
  if (!limit.ok) return NextResponse.json({ error: 'rate_limited' }, { status: 429 });

  const body = await request.json().catch(() => null);
  const parsed = schema.safeParse(body);
  if (!parsed.success) return NextResponse.json({ error: 'invalid_payload' }, { status: 400 });

  const voterKey = createHash('sha256').update(parsed.data.voterId).digest('hex');

  const supabase = await createSupabaseServerClient();
  const supabaseAny = supabase as unknown as { from: (t: string) => any; rpc: (fn: string, args?: any) => any; storage: any; auth: any };

  if (parsed.data.vote === 0) {
    // Oyu kaldır
    const { error } = await supabaseAny
      .from('collab_list_votes')
      .delete()
      .eq('list_id', parsed.data.listId)
      .eq('item_id', parsed.data.itemId)
      .eq('voter_ip', voterKey);
    if (error) return NextResponse.json({ error: 'db_error' }, { status: 500 });
  } else {
    // Oy upsert — aynı tarayıcı kimliği aynı item'a bir oy
    const { error } = await supabaseAny
      .from('collab_list_votes')
      .upsert({
        list_id: parsed.data.listId,
        item_id: parsed.data.itemId,
        vote: parsed.data.vote,
        voter_ip: voterKey,
      }, { onConflict: 'list_id,item_id,voter_ip' });
    if (error) return NextResponse.json({ error: 'db_error' }, { status: 500 });
  }

  return NextResponse.json({ ok: true });
}
