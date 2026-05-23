import { z } from 'zod';
import { NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getRequestIdentity, rateLimit } from '@/src/lib/oran-siniri';
import { hasOwnerBusiness } from '@/src/lib/veri/owner/sahip-isletmeleri';

const schema = z.object({
  businessId: z.string().uuid(),
  title: z.string().min(3).max(60).transform((s) => s.trim()),
  message: z.string().min(5).max(160).transform((s) => s.trim()),
});

export async function POST(request: Request) {
  const identity = getRequestIdentity({
    ip: request.headers.get('x-forwarded-for'),
    userAgent: request.headers.get('user-agent'),
  });
  // Günde max 3 kampanya bildirimi aynı işletme için
  const limit = rateLimit(`owner-notify:${identity}`, 3, 86_400_000);
  if (!limit.ok) return NextResponse.json({ error: 'rate_limited_daily' }, { status: 429 });

  const body = await request.json().catch(() => null);
  const parsed = schema.safeParse(body);
  if (!parsed.success) return NextResponse.json({ error: 'invalid_payload', details: parsed.error.flatten() }, { status: 400 });

  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'unauthorized' }, { status: 401 });

  const canManageBusiness = await hasOwnerBusiness(supabase as any, user.id, parsed.data.businessId);
  if (!canManageBusiness) return NextResponse.json({ error: 'forbidden' }, { status: 403 });

  const { data: biz } = await (supabase as any)
    .from('businesses')
    .select('id, name')
    .eq('id', parsed.data.businessId)
    .single();

  if (!biz) return NextResponse.json({ error: 'forbidden' }, { status: 403 });

  // Tüm favorileyen kullanıcılara notifications satırı ekle
  const { data: favorites } = await (supabase as any)
    .from('favorites')
    .select('user_id')
    .eq('business_id', parsed.data.businessId);

  if (!favorites || favorites.length === 0) {
    return NextResponse.json({ ok: true, sent: 0, message: 'Henüz takipçi yok.' });
  }

  const rows = (favorites as Array<{ user_id: string }>).map((f) => ({
    user_id: f.user_id,
    type: 'owner_campaign',
    title: parsed.data.title,
    message: parsed.data.message,
    target_path: `/isletme/${parsed.data.businessId}`,
    meta: { business_id: parsed.data.businessId, business_name: biz.name },
  }));

  const { error: insertError } = await (supabase as any)
    .from('notifications')
    .insert(rows);

  if (insertError) return NextResponse.json({ error: insertError.message }, { status: 500 });

  return NextResponse.json({ ok: true, sent: rows.length });
}
