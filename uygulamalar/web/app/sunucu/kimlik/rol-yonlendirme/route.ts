import { NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

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
  supabase: { rpc: (fn: any) => PromiseLike<{ data: unknown }>; from: (t: any) => any },
  userId: string,
): Promise<string> {
  const { data: isAdmin } = await supabase.rpc('is_admin') as { data: boolean | null };
  if (isAdmin) return '/yonetici';

  const { data: claims } = await supabase
    .from('owner_claims')
    .select('business_id')
    .eq('user_id', userId)
    .eq('status', 'approved')
    .limit(1) as { data: Array<{ business_id: string }> | null };

  if (claims && claims.length > 0) {
    return '/sahip/gosterge-panosu';
  }

  return '/';
}
