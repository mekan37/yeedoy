import type { Metadata } from 'next';
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { ProfilAyarlariFormu, type ProfilAyarlariBaslangic } from './profil-ayarlari-formu';

export const metadata: Metadata = {
  // Root layout'un title.template'i ('%s | Yeedoy') zaten suffix ekliyor —
  // burada da eklenirse "Profil Düzenle | Yeedoy | Yeedoy" olur.
  title: 'Profil Düzenle',
  robots: { index: false, follow: false },
};

// Önceden bu sayfanın tamamı 'use client' idi ve profil verisini bir
// useEffect içinde mount'tan SONRA çekiyordu — sayfa her zaman boş bir
// formla açılıp, veri gelince dolduruluyordu (flash of empty content).
// (kimlik)/layout.tsx zaten oturumu kontrol edip yönlendiriyor, ama bu
// sayfanın kendi user/profil verisine ihtiyacı olduğu için auth.getUser()
// burada tekrar çağrılıyor — bu ekstra bir maliyet değil, zaten layout'un
// yaptığı işin aynısı (cookie'den JWT decode, network round-trip gerekmez).
export default async function ProfileSettingsPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    redirect('/giris?redirect=/profil/ayarlar');
  }

  const emailPrefix = (user.email ?? '').split('@')[0];
  let firstName = '';
  let lastName = '';
  let hakkinda = '';
  let phone = '';
  let avatarUrl: string | null = null;

  try {
    const { data: envelope } = await (supabase as unknown as {
      rpc: (fn: 'get_my_profile_private_v1') => Promise<{
        data: { ok: boolean; profile: Record<string, unknown> | null } | null;
      }>;
    }).rpc('get_my_profile_private_v1');

    const profile = envelope?.profile;
    if (profile) {
      if (profile.display_name) {
        const parts = (profile.display_name as string).trim().split(' ');
        firstName = parts[0] ?? '';
        lastName = parts.slice(1).join(' ');
      }
      if (profile.bio) hakkinda = profile.bio as string;
      if (profile.phone) phone = profile.phone as string;
      if (profile.avatar_url) avatarUrl = profile.avatar_url as string;
    }
  } catch {
    // Profil RPC'si başarısız olursa boş varsayılanlarla devam et — kullanıcı
    // yine de formu görüp doldurabilir, önceki client-fetch akışı da aynı
    // şekilde sessizce başarısız oluyordu (o zaman .then() hiç .catch() almıyordu).
  }

  const initial: ProfilAyarlariBaslangic = {
    userId: user.id,
    email: user.email ?? '',
    firstName,
    lastName,
    username: emailPrefix,
    phone,
    hakkinda,
    avatarUrl,
  };

  return <ProfilAyarlariFormu initial={initial} />;
}
