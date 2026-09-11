import type { Metadata } from 'next';
import { redirect } from 'next/navigation';
import { headers } from 'next/headers';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import type { ReactNode } from 'react';
import { PublicShell } from '@/src/ui/acik/yerlesim';

export const metadata: Metadata = {
  robots: { index: false, follow: false },
};

export default async function AuthLayout({ children }: { children: ReactNode }) {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    // proxy.ts'in her isteğe eklediği x-pathname header'ı — bu layout Server
    // Component olduğu için request.nextUrl.pathname'e doğrudan erişemiyor.
    // Önceden her zaman /profil'e sabit yönlendiriyordu; (kimlik) altında
    // 30+ sayfa var (favoriler, gelen-kutusu, ayarlar vb.) — kullanıcı
    // giriş yaptıktan sonra gerçekte gitmek istediği sayfaya değil, her
    // zaman /profil'e düşüyordu.
    const headersList = await headers();
    const currentPath = headersList.get('x-pathname') || '/profil';
    redirect(`/giris?redirect=${encodeURIComponent(currentPath)}`);
  }
  return <PublicShell>{children}</PublicShell>;
}

