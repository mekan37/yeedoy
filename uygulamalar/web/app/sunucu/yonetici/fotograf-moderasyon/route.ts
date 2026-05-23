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

  const { data: isAdmin } = await (supabase as any).rpc('is_admin');
  if (!isAdmin) return NextResponse.json({ error: 'Forbidden' }, { status: 403 });

  const parsed = schema.safeParse(await req.json());
  if (!parsed.success) return NextResponse.json({ error: 'Invalid input' }, { status: 400 });

  const { photoId, action } = parsed.data;
  const newStatus = action === 'approve' ? 'approved' : 'rejected';

  const { error } = await (supabase as any)
    .from('business_media')
    .update({
      status: newStatus,
      is_hidden: action === 'reject',
      moderation_note: action === 'reject' ? `Rejected by admin ${user.id}` : null,
    })
    .eq('id', photoId);

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  return NextResponse.json({ ok: true });
}
