'use server';

import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { createSupabaseServiceClient } from '@/src/lib/taban/hizmet';
import { rateLimit } from '@/src/lib/oran-siniri';

export async function inviteUser(email: string): Promise<{ error: string } | { success: true }> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Oturum açmanız gerekiyor.' };

  const { data: isAdmin } = await (supabase).rpc('is_admin');
  if (!isAdmin) return { error: 'Yetkiniz yok.' };

  const rl = await rateLimit(`kullanici-davet:${user.id}`, 20, 3_600_000);
  if (!rl.ok) return { error: 'Çok fazla davet gönderildi. Lütfen bir süre sonra tekrar deneyin.' };

  const trimmed = email.trim().toLowerCase();
  if (!trimmed || !trimmed.includes('@')) return { error: 'Geçerli bir e-posta girin.' };

  const serviceClient = createSupabaseServiceClient();
  if (!serviceClient) return { error: 'Davet servisi şu anda kullanılamıyor.' };

  const { error } = await serviceClient.auth.admin.inviteUserByEmail(trimmed);
  if (error) return { error: 'Davet gönderilemedi. E-posta zaten kayıtlı olabilir.' };

  // Kullanıcı daveti hiçbir depoya loglanmıyordu — "kim bu e-postayı davet
  // etti" sorusu cevaplanamıyordu.
  await (supabase as any).rpc('log_admin_action_v1', {
    p_action: 'user.invite',
    p_target_table: 'auth.users',
    p_target_id: null,
    p_meta: { email: trimmed },
  });

  return { success: true };
}
