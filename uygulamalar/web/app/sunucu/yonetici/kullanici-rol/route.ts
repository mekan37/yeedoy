import { NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { createSupabaseServiceClient } from '@/src/lib/taban/hizmet';
import { z } from 'zod';

const schema = z.object({
  userId: z.string().uuid(),
  role: z.enum(['user', 'community_mod', 'admin']),
});

export async function PATCH(req: Request) {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const { data: isAdmin } = await supabase.rpc('is_admin');
  if (!isAdmin) {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
  }

  const parsed = schema.safeParse(await req.json());
  if (!parsed.success) return NextResponse.json({ error: 'Invalid input' }, { status: 400 });

  const { userId, role } = parsed.data;
  const serviceClient = createSupabaseServiceClient();
  if (!serviceClient) return NextResponse.json({ error: 'Service unavailable' }, { status: 503 });

  // Prevent editing super_admin
  const { data: target, error: targetError } = await serviceClient.auth.admin.getUserById(userId);
  if (targetError || !target.user) {
    return NextResponse.json({ error: 'User not found' }, { status: 404 });
  }

  const currentRole = String(
    target.user.app_metadata?.role ?? target.user.user_metadata?.role ?? 'user',
  ).toLocaleLowerCase('tr-TR');

  if (currentRole === 'super_admin') {
    return NextResponse.json({ error: 'Cannot modify super_admin' }, { status: 403 });
  }

  const { error } = await serviceClient.auth.admin.updateUserById(userId, {
    app_metadata: {
      ...target.user.app_metadata,
      role,
    },
  });

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  return NextResponse.json({ ok: true });
}
