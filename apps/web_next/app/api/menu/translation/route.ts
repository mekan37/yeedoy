import { NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { createServiceRoleClient } from '@/src/lib/supabaseAdmin';
import { canManageBusiness } from '@/src/lib/ownership';

export async function POST(request: Request) {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const body = await request.json();
  const { business_id, entity_type, entity_id, locale, name, description } = body as {
    business_id: string;
    entity_type: 'business' | 'category' | 'item';
    entity_id: string;
    locale: string;
    name: string;
    description?: string;
  };

  const allowed = await canManageBusiness(supabase, user.id, business_id);
  if (!allowed) {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
  }

  const admin = createServiceRoleClient();
  const { error } = await admin
    .from('menu_translations')
    .upsert(
      {
        entity_type,
        entity_id,
        locale,
        name,
        description: description ?? null,
      },
      { onConflict: 'entity_type,entity_id,locale' },
    );

  if (error) return NextResponse.json({ error: error.message }, { status: 400 });
  return NextResponse.json({ ok: true });
}
