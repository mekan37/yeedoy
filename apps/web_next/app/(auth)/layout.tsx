import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import type { ReactNode } from 'react';

export default async function AuthLayout({ children }: { children: ReactNode }) {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect('/login?redirect=/profile');
  return <>{children}</>;
}
