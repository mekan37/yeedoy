import { NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { createServiceRoleClient } from '@/src/lib/supabaseAdmin';
import { canManageBusiness } from '@/src/lib/ownership';

export async function GET(_: Request, { params }: { params: Promise<{ businessId: string }> }) {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const { businessId } = await params;
  const allowed = await canManageBusiness(supabase, user.id, businessId);
  if (!allowed) {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
  }

  const admin = createServiceRoleClient();
  const { data: business } = await admin
    .from('businesses')
    .select('id,name,slug')
    .eq('id', businessId)
    .single();

  const [{ data: categories }, { data: items }, { data: translations }] = await Promise.all([
    admin.from('menu_categories').select('*').eq('business_id', businessId).order('sort_order'),
    admin
      .from('menu_items')
      .select('id,business_id,category_id,name,description,price_cents,currency,tags,image_url,is_available,sort_order,created_at,updated_at')
      .eq('business_id', businessId)
      .order('sort_order'),
    admin.from('menu_translations').select('*').in('entity_type', ['business', 'category', 'item']),
  ]);

  return NextResponse.json({ business, categories: categories ?? [], items: items ?? [], translations: translations ?? [] });
}
