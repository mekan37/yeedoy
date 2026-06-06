'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

const CANDIDATE_TABLES = ['notifications', 'user_notifications'] as const;

export async function hepsiniOkunduIsaretle(): Promise<{ ok: boolean; error?: string }> {
  const supabase = await createSupabaseServerClient();
  const { data: { user }, error: authError } = await supabase.auth.getUser();
  if (authError || !user) return { ok: false, error: 'Oturum gerekli' };

  let updated = false;

  for (const table of CANDIDATE_TABLES) {
    const { error } = await (supabase as any)
      .from(table)
      .update({ is_read: true })
      .eq('user_id', user.id)
      .eq('is_read', false) as { error: { code?: string } | null };

    if (!error) {
      // Başarılı — 0 row güncellenmiş olsa da bu success
      updated = true;
      break;
    }

    if (error.code === '42P01') {
      // Tablo yok, bir sonraki adaya geç
      continue;
    }

    // 42P01 dışı gerçek hata (RLS reddi, constraint, network vb.)
    console.warn('[inbox] mark-all-read error:', error.code);
    return { ok: false, error: 'Bir sorun oluştu' };
  }

  if (!updated) {
    // Hiç tablo bulunamadı (hepsi 42P01)
    console.warn('[inbox] mark-all-read: no candidate table found');
    return { ok: false, error: 'Bir sorun oluştu' };
  }

  revalidatePath('/gelen-kutusu');
  return { ok: true };
}

export async function bildirimiOkunduIsaretle(notifId: string): Promise<{ ok: boolean; error?: string }> {
  const supabase = await createSupabaseServerClient();
  const { data: { user }, error: authError } = await supabase.auth.getUser();
  if (authError || !user) return { ok: false, error: 'Oturum gerekli' };

  let updated = false;

  for (const table of CANDIDATE_TABLES) {
    const { error } = await (supabase as any)
      .from(table)
      .update({ is_read: true })
      .eq('id', notifId)
      .eq('user_id', user.id) as { error: { code?: string } | null };

    if (!error) {
      updated = true;
      break;
    }

    if (error.code === '42P01') {
      continue;
    }

    console.warn('[inbox] mark-read error:', error.code);
    return { ok: false, error: 'Bir sorun oluştu' };
  }

  if (!updated) {
    console.warn('[inbox] mark-read: no candidate table found');
    return { ok: false, error: 'Bir sorun oluştu' };
  }

  revalidatePath('/gelen-kutusu');
  return { ok: true };
}

export async function bildirimiSil(notifId: string): Promise<{ ok: boolean; error?: string }> {
  const supabase = await createSupabaseServerClient();
  const { data: { user }, error: authError } = await supabase.auth.getUser();
  if (authError || !user) return { ok: false, error: 'Oturum gerekli' };

  let deleted = false;

  for (const table of CANDIDATE_TABLES) {
    const { error } = await (supabase as any)
      .from(table)
      .delete()
      .eq('id', notifId)
      .eq('user_id', user.id) as { error: { code?: string } | null };

    if (!error) {
      deleted = true;
      break;
    }

    if (error.code === '42P01') {
      continue;
    }

    console.warn('[inbox] delete-notif error:', error.code);
    return { ok: false, error: 'Bir sorun oluştu' };
  }

  if (!deleted) {
    console.warn('[inbox] delete-notif: no candidate table found');
    return { ok: false, error: 'Bir sorun oluştu' };
  }

  revalidatePath('/gelen-kutusu');
  return { ok: true };
}

export async function eskiBildirimleriSil(): Promise<{ ok: boolean; error?: string }> {
  const supabase = await createSupabaseServerClient();
  const { data: { user }, error: authError } = await supabase.auth.getUser();
  if (authError || !user) return { ok: false, error: 'Oturum gerekli' };

  const otuzGunOnce = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();
  let deleted = false;

  for (const table of CANDIDATE_TABLES) {
    const { error } = await (supabase as any)
      .from(table)
      .delete()
      .eq('user_id', user.id)
      .eq('is_read', true)
      .lt('created_at', otuzGunOnce) as { error: { code?: string } | null };

    if (!error) {
      deleted = true;
      break;
    }

    if (error.code === '42P01') {
      continue;
    }

    console.warn('[inbox] delete-old error:', error.code);
    return { ok: false, error: 'Bir sorun oluştu' };
  }

  if (!deleted) {
    console.warn('[inbox] delete-old: no candidate table found');
    return { ok: false, error: 'Bir sorun oluştu' };
  }

  revalidatePath('/gelen-kutusu');
  return { ok: true };
}
