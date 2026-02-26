import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { redirect } from 'next/navigation';

export default async function AdminPage() {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect('/login');
  }

  const [adminRpc, adminRow] = await Promise.all([
    getIsAdmin(supabase),
    getAdminRow(supabase, user.id),
  ]);
  if (!adminRpc && !adminRow) {
    redirect('/');
  }

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-4xl px-4 py-10 sm:px-6">
        <h1 className="text-3xl font-black text-primary">Admin Paneli</h1>
        <p className="mt-3 text-sm text-muted">
          Admin araçları burada konumlanacak. Yetki kontrolü aktif.
        </p>
      </div>
    </main>
  );
}

async function getIsAdmin(supabase: Awaited<ReturnType<typeof createSupabaseServerClient>>) {
  try {
    const { data } = await supabase.rpc('is_admin');
    return Boolean(data);
  } catch {
    return false;
  }
}

async function getAdminRow(
  supabase: Awaited<ReturnType<typeof createSupabaseServerClient>>,
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
