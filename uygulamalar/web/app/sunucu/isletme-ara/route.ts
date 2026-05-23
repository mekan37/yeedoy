'use server';

import { NextRequest, NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

// GET /sunucu/isletme-ara?q=adana&city=Adana&district=Seyhan&limit=10
export async function GET(request: NextRequest) {
  const { searchParams } = request.nextUrl;
  const q        = searchParams.get('q')?.trim() ?? '';
  const city     = searchParams.get('city')?.trim() ?? '';
  const district = searchParams.get('district')?.trim() ?? '';
  const limit    = Math.min(parseInt(searchParams.get('limit') ?? '10'), 30);

  if (!q && !city && !district) {
    return NextResponse.json({ results: [] });
  }

  const supabase = await createSupabaseServerClient();

  let query = (supabase as any)
    .from('businesses')
    .select('id, name, category, city, district, address, slug')
    .eq('is_active', true)
    .limit(limit);

  if (q) {
    query = query.ilike('name', `%${q}%`);
  }
  if (city) {
    query = query.ilike('city', `%${city}%`);
  }
  if (district) {
    query = query.ilike('district', `%${district}%`);
  }

  const { data, error } = await query.order('name');

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json({ results: data ?? [] });
}
