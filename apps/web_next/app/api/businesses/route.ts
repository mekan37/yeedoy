import { NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { businessSchema } from '@/src/shared/schemas/businessSchema';

export async function POST(request: Request) {
  const form = await request.formData();
  const raw = {
    name: String(form.get('name') ?? ''),
    city: String(form.get('city') ?? ''),
    district: String(form.get('district') ?? ''),
    category: String(form.get('category') ?? 'Restoran'),
    address: String(form.get('address') ?? ''),
    phone: String(form.get('phone') ?? ''),
    website: String(form.get('website') ?? ''),
  };

  const parsed = businessSchema.safeParse(raw);
  if (!parsed.success) {
    return NextResponse.json(
      { error: parsed.error.issues[0]?.message ?? 'Dogrulama basarisiz' },
      { status: 400 },
    );
  }

  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'Oturum bulunamadi' }, { status: 401 });

  const { data, error } = await supabase.rpc('owner_submit_new_business_v1', {
    p_name: parsed.data.name,
    p_city: parsed.data.city,
    p_district: parsed.data.district,
    p_category: parsed.data.category,
    p_address: parsed.data.address,
    p_phone: parsed.data.phone || null,
    p_website: parsed.data.website || null,
  });

  if (error) return NextResponse.json({ error: error.message }, { status: 400 });
  if (!data?.ok) {
    return NextResponse.json({ error: data?.error ?? 'Basvuru olusturulamadi' }, { status: 400 });
  }

  return NextResponse.json({ ok: true, request_id: data.request_id });
}
