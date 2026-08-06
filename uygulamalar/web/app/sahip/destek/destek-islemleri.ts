'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { rateLimit } from '@/src/lib/oran-siniri';

export type DestekTicket = {
  id: string;
  subject: string;
  status: string;
  category: string;
  business_id: string | null;
  created_at: string;
  updated_at: string;
};

export type DestekMesaj = {
  id: string;
  sender: 'user' | 'agent';
  message: string;
  created_at: string;
};

async function requireUser() {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { ok: false as const, error: 'Oturum bulunamadı' };
  return { ok: true as const, supabase, user };
}

export async function destekTalebiOlustur(
  businessId: string | null,
  category: string,
  subject: string,
  message: string,
): Promise<{ error: string } | { ticketId: string }> {
  const context = await requireUser();
  if (!context.ok) return { error: context.error };
  const { supabase, user } = context;

  const rl = rateLimit(`owner-destek-olustur:${user.id}`, 10, 3_600_000); // 10/saat
  if (!rl.ok) return { error: 'Çok fazla istek gönderildi. Lütfen bir süre sonra tekrar deneyin.' };

  const trimmedSubject = subject.trim();
  const trimmedMessage = message.trim();
  if (!trimmedSubject || !trimmedMessage) {
    return { error: 'Konu ve mesaj boş olamaz' };
  }

  const { data: ticketId, error: rpcError } = (await (supabase as any).rpc('create_support_ticket_v1', {
    p_business_id: businessId,
    p_category: category,
    p_subject: trimmedSubject,
    p_message: trimmedMessage,
  })) as { data: string | null; error: { message: string } | null };

  if (rpcError) return { error: rpcError.message };

  revalidatePath('/sahip/destek');
  return { ticketId: ticketId ?? '' };
}

export async function destekTalebiListele(): Promise<{ error: string } | { tickets: DestekTicket[] }> {
  const context = await requireUser();
  if (!context.ok) return { error: context.error };
  const { supabase, user } = context;

  const { data, error } = (await (supabase as any)
    .from('support_tickets')
    .select('id, subject, status, category, business_id, created_at, updated_at')
    .eq('user_id', user.id)
    .order('updated_at', { ascending: false })) as {
    data: DestekTicket[] | null;
    error: { message: string } | null;
  };

  if (error) return { error: error.message };
  return { tickets: data ?? [] };
}

export async function destekTalebiDetay(
  ticketId: string,
): Promise<{ error: string } | { ticket: DestekTicket; messages: DestekMesaj[] }> {
  const context = await requireUser();
  if (!context.ok) return { error: context.error };
  const { supabase, user } = context;

  const { data: ticket, error: ticketError } = (await (supabase as any)
    .from('support_tickets')
    .select('id, subject, status, category, business_id, created_at, updated_at')
    .eq('id', ticketId)
    .eq('user_id', user.id)
    .maybeSingle()) as { data: DestekTicket | null; error: { message: string } | null };

  if (ticketError) return { error: ticketError.message };
  if (!ticket) return { error: 'Talep bulunamadı' };

  const { data: messages, error: messagesError } = (await (supabase as any)
    .from('support_ticket_messages')
    .select('id, sender, message, created_at')
    .eq('ticket_id', ticketId)
    .order('created_at', { ascending: true })) as {
    data: DestekMesaj[] | null;
    error: { message: string } | null;
  };

  if (messagesError) return { error: messagesError.message };
  return { ticket, messages: messages ?? [] };
}

export async function destekMesajGonder(ticketId: string, message: string): Promise<{ error: string } | null> {
  const context = await requireUser();
  if (!context.ok) return { error: context.error };
  const { supabase, user } = context;

  const rl = rateLimit(`owner-destek-mesaj:${user.id}`, 30, 3_600_000); // 30/saat
  if (!rl.ok) return { error: 'Çok fazla istek gönderildi. Lütfen bir süre sonra tekrar deneyin.' };

  const trimmedMessage = message.trim();
  if (!trimmedMessage) return { error: 'Mesaj boş olamaz' };

  const { data: ticket, error: ticketError } = (await (supabase as any)
    .from('support_tickets')
    .select('id')
    .eq('id', ticketId)
    .eq('user_id', user.id)
    .maybeSingle()) as { data: { id: string } | null; error: { message: string } | null };

  if (ticketError) return { error: ticketError.message };
  if (!ticket) return { error: 'Talep bulunamadı' };

  const { error: messageError } = (await (supabase as any).from('support_ticket_messages').insert({
    ticket_id: ticketId,
    sender: 'user',
    message: trimmedMessage,
    created_by: user.id,
  })) as { error: { message: string } | null };

  if (messageError) return { error: messageError.message };

  // best-effort — mesaj zaten kaydedildi, updated_at güncellemesi kritik değil
  await (supabase as any).rpc('touch_support_ticket_v1', { p_ticket_id: ticketId });

  revalidatePath('/sahip/destek');
  return null;
}
