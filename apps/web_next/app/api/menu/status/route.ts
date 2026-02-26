import { NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { createServiceRoleClient } from '@/src/lib/supabaseAdmin';
import { canManageBusiness } from '@/src/lib/ownership';

async function assertOwner(
  supabase: Awaited<ReturnType<typeof createSupabaseServerClient>>,
  businessId: string,
) {
  const { data: userData } = await supabase.auth.getUser();
  const user = userData.user;
  if (!user) throw new Error('Unauthorized');
  const allowed = await canManageBusiness(supabase, user.id, businessId);
  if (!allowed) throw new Error('Forbidden');
}

export async function PATCH(request: Request) {
  try {
    const body = await request.json();
    const business_id = String(body.business_id ?? '');
    const menu_id = String(body.menu_id ?? '');
    const active = body.active === true;

    if (!business_id || !menu_id) {
      return NextResponse.json({ error: 'Missing fields' }, { status: 400 });
    }

    const supabase = await createSupabaseServerClient();
    await assertOwner(supabase, business_id);
    const admin = createServiceRoleClient();

    const nextStatus = active ? 'published' : 'draft';
    const { error } = await admin
      .from('menus')
      .update({ status: nextStatus })
      .eq('id', menu_id)
      .eq('business_id', business_id);
    if (error) return NextResponse.json({ error: error.message }, { status: 400 });

    return NextResponse.json({ ok: true, status: nextStatus });
  } catch (e) {
    return NextResponse.json({ error: e instanceof Error ? e.message : 'Error' }, { status: 400 });
  }
}
