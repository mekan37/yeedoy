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
  detected_by: string | null;
} | null;

export default async function DiyetProfiliPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  let dietProfile: DietProfile = null;
  try {
    const { data } = await (supabase as any)
      .from('user_diet_profiles')
      .select('is_vegan, is_vegetarian, is_gluten_free, is_dairy_free, detected_by')
      .eq('user_id', user!.id)
      .maybeSingle();
    dietProfile = (data as DietProfile) ?? null;
  } catch {
    // Table may not exist yet; render form with empty defaults
  }

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-lg px-4 py-12">
        <Link
          href="/profil"
          className="mb-6 inline-flex items-center gap-1.5 text-sm text-muted hover:text-primary"
        >
          ← Profilime Dön
        </Link>
        <h1 className="mb-2 text-2xl font-[900] text-textStrong">Diyet Tercihlerim</h1>
        <p className="mb-8 text-sm leading-relaxed text-muted">
          Tercihlerinizi kaydedin; size özel öneriler daha isabetli olsun.
        </p>
        <DiyetProfilFormu dietProfile={dietProfile} />
      </div>
    </main>
  );
}
