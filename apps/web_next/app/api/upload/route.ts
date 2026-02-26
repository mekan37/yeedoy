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

  const form = await request.formData();
  const file = form.get('file') as File | null;
  const businessId = String(form.get('business_id') ?? '');
  const kind = String(form.get('kind') ?? 'item');

  if (!file || !businessId) {
    return NextResponse.json({ error: 'Missing file/business_id' }, { status: 400 });
  }

  const allowed = await canManageBusiness(supabase, user.id, businessId);
  if (!allowed) {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
  }

  const ext = file.name.split('.').pop() ?? 'jpg';
  const path = `business/${businessId}/${kind}/${Date.now()}.${ext}`;
  const bytes = new Uint8Array(await file.arrayBuffer());

  const admin = createServiceRoleClient();
  const { error } = await admin.storage.from('menu-assets').upload(path, bytes, {
    upsert: true,
    contentType: file.type || 'application/octet-stream',
  });
  if (error) return NextResponse.json({ error: error.message }, { status: 400 });

  const { data } = admin.storage.from('menu-assets').getPublicUrl(path);
  return NextResponse.json({ ok: true, path, publicUrl: data.publicUrl });
}
