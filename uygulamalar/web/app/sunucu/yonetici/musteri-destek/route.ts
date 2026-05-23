import { NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { z } from 'zod';

const schema = z.object({
  ticketId: z.string().uuid(),
  status: z.enum(['open', 'in_progress', 'resolved', 'closed']),
});

const replySchema = z.object({
  ticketId: z.string().uuid(),
  message: z.string().min(1).max(4000),
  sender: z.literal('agent').default('agent'),
});

async function requireAdmin() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { supabase, user: null, response: NextResponse.json({ error: 'Unauthorized' }, { status: 401 }) };

  const { data: isAdmin } = await (supabase as any).rpc('is_admin');
  if (!isAdmin) return { supabase, user, response: NextResponse.json({ error: 'Forbidden' }, { status: 403 }) };

  return { supabase, user, response: null };
}

export async function GET(req: Request) {
  const { supabase, response } = await requireAdmin();
  if (response) return response;

  const ticketId = new URL(req.url).searchParams.get('ticketId');
  if (!ticketId) return NextResponse.json({ error: 'Missing ticketId' }, { status: 400 });

  const { data: messages, error } = await (supabase as any)
    .from('support_ticket_messages')
    .select('id, ticket_id, sender, message, created_at')
    .eq('ticket_id', ticketId)
    .order('created_at', { ascending: true });

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  return NextResponse.json({ messages: messages ?? [] });
}

export async function PATCH(req: Request) {
  const { supabase, user, response } = await requireAdmin();
  if (response) return response;

  const parsed = schema.safeParse(await req.json());
  if (!parsed.success) return NextResponse.json({ error: 'Invalid input' }, { status: 400 });

  const { ticketId, status } = parsed.data;

  const { error } = await (supabase as any)
    .from('support_tickets')
    .update({ status, updated_at: new Date().toISOString(), assigned_to: user?.id })
    .eq('id', ticketId);

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  return NextResponse.json({ ok: true });
}

export async function POST(req: Request) {
  const { supabase, user, response } = await requireAdmin();
  if (response) return response;

  const parsed = replySchema.safeParse(await req.json());
  if (!parsed.success) return NextResponse.json({ error: 'Invalid input' }, { status: 400 });

  const { ticketId, message, sender } = parsed.data;
  const { error } = await (supabase as any)
    .from('support_ticket_messages')
    .insert({
      ticket_id: ticketId,
      sender,
      message,
      created_by: user?.id,
    });

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  await (supabase as any)
    .from('support_tickets')
    .update({ status: 'in_progress', updated_at: new Date().toISOString(), assigned_to: user?.id })
    .eq('id', ticketId);

  return NextResponse.json({ ok: true });
}
