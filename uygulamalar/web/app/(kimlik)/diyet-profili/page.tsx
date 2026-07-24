import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { DiyetProfilFormu } from './diyet-profil-formu';

export const metadata: Metadata = {
  title: 'Diyet Tercihlerim | Yeedoy',
  robots: { index: false, follow: false },
};

type DietProfile = {
  is_vegan: boolean;
  is_vegetarian: boolean;
  is_gluten_free: boolean;
  is_dairy_free: boolean;
} | null;

export default async function DiyetProfiliPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const { data } = await supabase
    .from('user_diet_profiles')
    .select('is_vegan, is_vegetarian, is_gluten_free, is_lactose_free')
    .eq('user_id', user!.id)
    .maybeSingle();

  const dietProfile: DietProfile = data
    ? {
        is_vegan: data.is_vegan,
        is_vegetarian: data.is_vegetarian,
        is_gluten_free: data.is_gluten_free,
        is_dairy_free: data.is_lactose_free,
      }
    : null;

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-lg px-4 py-12">
        <Link
          href="/profil"
          className="mb-6 inline-flex items-center gap-1.5 text-sm text-muted hover:text-primary"
        >
          ← Profilime Dön
        </Link>
        <h1 className="mb-2 text-2xl font-black text-textStrong">Diyet Tercihlerim</h1>
        <p className="mb-8 text-sm leading-relaxed text-muted">
          Tercihlerinizi kaydedin; size özel öneriler daha isabetli olsun.
        </p>
        <DiyetProfilFormu dietProfile={dietProfile} />
      </div>
    </main>
  );
}
