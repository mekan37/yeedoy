import { NextResponse } from 'next/server';
import type { SupabaseClient } from '@supabase/supabase-js';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import type { Database } from '@/src/lib/taban/veri-tanimlari';

export async function GET() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ redirectTo: '/giris' });
  }

  const redirectTo = await resolveRoleBasedRedirect(supabase, user.id);
  return NextResponse.json({ redirectTo });
}

export async function resolveRoleBasedRedirect(
  supabase: SupabaseClient<Database>,
  userId: string,
): Promise<string> {
  const { data: isAdmin } = await supabase.rpc('is_admin');
  if (isAdmin) return '/yonetici';

  const { data: claims } = await supabase
    .from('owner_claims')
    .select('business_id')
    .eq('user_id', userId)
    .eq('status', 'approved')
    .limit(1);

  if (claims && claims.length > 0) {
    return '/sahip/gosterge-panosu';
  }

  return '/';
}
