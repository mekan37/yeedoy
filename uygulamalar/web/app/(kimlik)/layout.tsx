import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import type { ReactNode } from 'react';
import { PublicShell } from '@/src/ui/acik/yerlesim';

export default async function AuthLayout({ children }: { children: ReactNode }) {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect('/giris?redirect=/profil');
  return <PublicShell>{children}</PublicShell>;
}

