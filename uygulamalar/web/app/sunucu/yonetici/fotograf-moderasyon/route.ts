import { NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { z } from 'zod';

const schema = z.object({
  photoId: z.string().uuid(),
  action: z.enum(['approve', 'reject']),
});

export async function PATCH(req: Request) {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const { data: isAdmin } = await supabase.rpc('is_admin');
  if (!isAdmin) return NextResponse.json({ error: 'Forbidden' }, { status: 403 });

  const { data: yetkili } = await supabase.rpc('has_permission_v1', { p_permission: 'page:fotograf-moderasyon' });
  if (!yetkili) return NextResponse.json({ error: 'forbidden' }, { status: 403 });

  const parsed = schema.safeParse(await req.json());
  if (!parsed.success) return NextResponse.json({ error: 'Invalid input' }, { status: 400 });

  const { photoId, action } = parsed.data;
  const newStatus = action === 'approve' ? 'approved' : 'rejected';

  // business_media'da admin için UPDATE RLS policy'si yok — doğrudan tablo
  // yazması RLS tarafından sessizce 0 satır güncelliyordu (P0: reddedilen
  // fotoğraf yayında kalmaya devam ediyordu ama UI "başarılı" gösteriyordu).
  const { data: affected, error } = await supabase.rpc('admin_moderate_business_media_v1', {
    p_photo_id: photoId,
    p_status: newStatus,
    p_is_hidden: action === 'reject',
    p_moderation_note: action === 'reject' ? `Rejected by admin ${user.id}` : undefined,
  });

  if (error) return NextResponse.json({ error: 'internal_error' }, { status: 500 });
  if ((affected ?? 0) === 0) return NextResponse.json({ error: 'not_found' }, { status: 404 });
  return NextResponse.json({ ok: true });
}
