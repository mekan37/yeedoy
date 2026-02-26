import type { NextRequest } from 'next/server';
import { NextResponse } from 'next/server';
import { createServerClient } from '@supabase/ssr';

export async function middleware(request: NextRequest) {
  let response = NextResponse.next({ request });

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll();
        },
        setAll(
          cookiesToSet: Array<{ name: string; value: string; options?: Record<string, unknown> }>,
        ) {
          cookiesToSet.forEach(({ name, value, options }) => {
            request.cookies.set(name, value);
            response.cookies.set(name, value, options);
          });
        },
      },
    },
  );

  const {
    data: { user },
  } = await supabase.auth.getUser();

  const protectedPrefixes = ['/dashboard', '/owner', '/admin', '/menu-builder'];
  const isProtected = protectedPrefixes.some((prefix) =>
    request.nextUrl.pathname.startsWith(prefix),
  );

  if (isProtected && !user) {
    return NextResponse.redirect(new URL('/login', request.url));
  }

  if (request.nextUrl.pathname.startsWith('/admin') && user) {
    const [adminRpc, adminRow] = await Promise.all([
      getIsAdmin(supabase),
      getAdminRow(supabase, user.id),
    ]);
    const isAdmin = Boolean(adminRpc) || Boolean(adminRow?.user_id);
    if (!isAdmin) {
      return NextResponse.redirect(new URL('/', request.url));
    }
  }

  return response;
}

async function getIsAdmin(supabase: ReturnType<typeof createServerClient>) {
  try {
    const { data } = await supabase.rpc('is_admin');
    return Boolean(data);
  } catch {
    return false;
  }
}

async function getAdminRow(
  supabase: ReturnType<typeof createServerClient>,
  userId: string,
) {
  try {
    const { data } = await supabase
      .from('admin_users')
      .select('user_id')
      .eq('user_id', userId)
      .maybeSingle();
    return data;
  } catch {
    return null;
  }
}

export const config = {
  matcher: ['/dashboard/:path*', '/owner/:path*', '/admin/:path*', '/menu-builder/:path*'],
};
