'use server';

import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

export async function hepsiniOkunduIsaretle(): Promise<{ ok: boolean; error?: string }> {
  try {
    const supabase = await createSupabaseServerClient();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return { ok: false, error: 'Oturum bulunamadı' };

    for (const table of ['notifications', 'user_notifications']) {
      const { error } = await (supabase as any)
        .from(table)
        .update({ is_read: true })
        .eq('user_id', user.id)
        .eq('is_read', false) as { error: { code?: string } | null };
      if (!error || error.code !== '42P01') break;
    }
    return { ok: true };
  } catch (err) {
    return { ok: false, error: err instanceof Error ? err.message : 'Bir hata oluştu' };
  }
}

export async function bildirimiOkunduIsaretle(notifId: string): Promise<{ ok: boolean; error?: string }> {
  try {
    const supabase = await createSupabaseServerClient();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return { ok: false, error: 'Oturum bulunamadı' };

    for (const table of ['notifications', 'user_notifications']) {
      const { error } = await (supabase as any)
        .from(table)
        .update({ is_read: true })
        .eq('id', notifId)
        .eq('user_id', user.id) as { error: { code?: string } | null };
      if (!error || error.code !== '42P01') break;
    }
    return { ok: true };
  } catch (err) {
    return { ok: false, error: err instanceof Error ? err.message : 'Bir hata oluştu' };
  }
}

export async function bildirimiSil(notifId: string): Promise<{ ok: boolean; error?: string }> {
  try {
    const supabase = await createSupabaseServerClient();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return { ok: false, error: 'Oturum bulunamadı' };

    for (const table of ['notifications', 'user_notifications']) {
      const { error } = await (supabase as any)
        .from(table)
        .delete()
        .eq('id', notifId)
        .eq('user_id', user.id) as { error: { code?: string } | null };
      if (!error || error.code !== '42P01') break;
    }
    return { ok: true };
  } catch (err) {
    return { ok: false, error: err instanceof Error ? err.message : 'Bir hata oluştu' };
  }
}

export async function eskiBildirimleriSil(): Promise<{ ok: boolean; error?: string }> {
  try {
    const supabase = await createSupabaseServerClient();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return { ok: false, error: 'Oturum bulunamadı' };

    const otuzGunOnce = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();

    for (const table of ['notifications', 'user_notifications']) {
      const { error } = await (supabase as any)
        .from(table)
        .delete()
        .eq('user_id', user.id)
        .eq('is_read', true)
        .lt('created_at', otuzGunOnce) as { error: { code?: string } | null };
      if (!error || error.code !== '42P01') break;
    }
    return { ok: true };
  } catch (err) {
    return { ok: false, error: err instanceof Error ? err.message : 'Bir hata oluştu' };
  }
}
