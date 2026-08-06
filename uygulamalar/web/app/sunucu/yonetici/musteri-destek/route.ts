import { NextResponse } from 'next/server';
import { rateLimit } from '@/src/lib/oran-siniri';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { z } from 'zod';
import { sendEmail } from '@/src/lib/eposta';
import { appConfig } from '@/src/lib/ayarlar';

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
  const supabaseAny = supabase as unknown as { from: (t: string) => any; rpc: (fn: string, args?: any) => any; storage: any; auth: any };
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { supabase, supabaseAny, user: null, response: NextResponse.json({ error: 'Unauthorized' }, { status: 401 }) };

  const { data: isAdmin } = await supabaseAny.rpc('is_admin');
  if (!isAdmin) return { supabase, supabaseAny, user, response: NextResponse.json({ error: 'Forbidden' }, { status: 403 }) };

  return { supabase, supabaseAny, user, response: null };
}

export async function GET(req: Request) {
  const { supabaseAny, user, response } = await requireAdmin();
  if (response) return response;

  const rl = rateLimit(`destek:${user!.id}`, 60, 60_000); // 60/min
  if (!rl.ok) return NextResponse.json({ error: 'rate_limited' }, { status: 429 });

  const ticketId = new URL(req.url).searchParams.get('ticketId');
  if (!ticketId) return NextResponse.json({ error: 'Missing ticketId' }, { status: 400 });

  const { data: messages, error } = await supabaseAny
    .from('support_ticket_messages')
    .select('id, ticket_id, sender, message, created_at')
    .eq('ticket_id', ticketId)
    .order('created_at', { ascending: true });

  if (error) return NextResponse.json({ error: 'internal_error' }, { status: 500 });
  return NextResponse.json({ messages: messages ?? [] });
}

export async function PATCH(req: Request) {
  const { supabaseAny, user, response } = await requireAdmin();
  if (response) return response;

  const rl = rateLimit(`destek:${user!.id}`, 60, 60_000); // 60/min
  if (!rl.ok) return NextResponse.json({ error: 'rate_limited' }, { status: 429 });

  const parsed = schema.safeParse(await req.json());
  if (!parsed.success) return NextResponse.json({ error: 'Invalid input' }, { status: 400 });

  const { ticketId, status } = parsed.data;

  const { error } = await supabaseAny
    .from('support_tickets')
    .update({ status, updated_at: new Date().toISOString(), assigned_to: user?.id })
    .eq('id', ticketId);

  if (error) return NextResponse.json({ error: 'internal_error' }, { status: 500 });
  return NextResponse.json({ ok: true });
}

export async function POST(req: Request) {
  const { supabaseAny, user, response } = await requireAdmin();
  if (response) return response;

  const rl = rateLimit(`destek:${user!.id}`, 60, 60_000); // 60/min
  if (!rl.ok) return NextResponse.json({ error: 'rate_limited' }, { status: 429 });

  const parsed = replySchema.safeParse(await req.json());
  if (!parsed.success) return NextResponse.json({ error: 'Invalid input' }, { status: 400 });

  const { ticketId, message, sender } = parsed.data;
  const { error } = await supabaseAny
    .from('support_ticket_messages')
    .insert({
      ticket_id: ticketId,
      sender,
      message,
      created_by: user?.id,
    });

  if (error) return NextResponse.json({ error: 'internal_error' }, { status: 500 });
  await supabaseAny
    .from('support_tickets')
    .update({ status: 'in_progress', updated_at: new Date().toISOString(), assigned_to: user?.id })
    .eq('id', ticketId);

  // best-effort — e-posta gönderimi başarısız olsa da yanıt akışını engellemez
  const { data: ticketRow } = await supabaseAny
    .from('support_tickets')
    .select('subject, requester_email')
    .eq('id', ticketId)
    .maybeSingle();
  if (ticketRow?.requester_email) {
    await sendEmail({
      to: ticketRow.requester_email,
      subject: `Destek talebinize yanıt geldi: ${ticketRow.subject}`,
      html: `<p>Merhaba,</p><p>"${ticketRow.subject}" konulu destek talebinize yeni bir yanıt geldi.</p><p><a href="${appConfig.siteUrl()}/sahip/destek">Talebi görüntülemek için tıklayın</a>.</p>`,
    });
  }

  return NextResponse.json({ ok: true });
}
