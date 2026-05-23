import { NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinessIds, hasOwnerBusiness } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { z } from 'zod';

const createSchema = z.object({
  bizId: z.string().uuid(),
  title: z.string().min(1).max(200),
  description: z.string().max(1000).optional(),
  eventDate: z.string().datetime().or(z.string().min(1)),
  capacity: z.number().int().min(1).nullable().optional(),
  ticketPrice: z.number().min(0).nullable().optional(),
});

const patchSchema = z.object({
  id: z.string().uuid(),
  status: z.enum(['active', 'cancelled', 'completed']),
});

export async function POST(req: Request) {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const parsed = createSchema.safeParse(await req.json());
  if (!parsed.success) return NextResponse.json({ error: 'Invalid input' }, { status: 400 });

  const { bizId, title, description, eventDate, capacity, ticketPrice } = parsed.data;

  const canManageBusiness = await hasOwnerBusiness(supabase as any, user.id, bizId);
  if (!canManageBusiness) return NextResponse.json({ error: 'Forbidden' }, { status: 403 });

  const { error } = await (supabase as any)
    .from('business_events')
    .insert({
      business_id: bizId,
      title,
      description: description ?? null,
      event_date: new Date(eventDate).toISOString(),
      capacity: capacity ?? null,
      ticket_price: ticketPrice ?? null,
      tickets_sold: 0,
      status: 'active',
    });

  if (error) return NextResponse.json({ error: 'internal_error' }, { status: 500 });
  return NextResponse.json({ ok: true });
}

export async function PATCH(req: Request) {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const parsed = patchSchema.safeParse(await req.json());
  if (!parsed.success) return NextResponse.json({ error: 'Invalid input' }, { status: 400 });

  const { id, status } = parsed.data;

  const businessIds = await getOwnerBusinessIds(supabase as any, user.id);
  if (businessIds.length === 0) return NextResponse.json({ error: 'Forbidden' }, { status: 403 });

  const { data: event } = await (supabase as any)
    .from('business_events')
    .select('id')
    .eq('id', id)
    .in('business_id', businessIds)
    .maybeSingle();

  if (!event) return NextResponse.json({ error: 'Forbidden' }, { status: 403 });

  const { error } = await (supabase as any)
    .from('business_events')
    .update({ status, updated_at: new Date().toISOString() })
    .eq('id', id);

  if (error) return NextResponse.json({ error: 'internal_error' }, { status: 500 });
  return NextResponse.json({ ok: true });
}
