import { z } from 'zod';
import { NextResponse } from 'next/server';
import { createHash } from 'crypto';
import { getRequestIdentity, rateLimit, getClientIp } from '@/src/lib/oran-siniri';
import { createSupabasePublicClient } from '@/src/lib/taban/acik';

const schema = z.object({
  token: z.string().min(1),
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

  // Özellik tasarım gereği tamamen anonim ("Oylar anonim — hesap gerekmez") —
  // RLS token'ı JWT'de taşımadığı için satır bazlı ifade edilemiyor, token
  // doğrulaması + yazma SECURITY DEFINER RPC'de yapılıyor (bkz. migration
  // 20260915040000_collab_list_real_anonymous_voting.sql).
  const supabase = createSupabasePublicClient();
  const { data, error } = await supabase.rpc('upsert_collab_vote_anon_v1', {
    p_token: parsed.data.token,
    p_item_id: parsed.data.itemId,
    p_vote: parsed.data.vote,
    p_voter_key: voterKey,
  });

  if (error) return NextResponse.json({ error: 'db_error' }, { status: 500 });
  const result = data as { ok?: boolean; error?: string } | null;
  if (!result?.ok) {
    const status = result?.error === 'not_found' || result?.error === 'item_not_found' ? 404 : 400;
    return NextResponse.json({ error: result?.error ?? 'vote_failed' }, { status });
  }

  return NextResponse.json({ ok: true });
}
