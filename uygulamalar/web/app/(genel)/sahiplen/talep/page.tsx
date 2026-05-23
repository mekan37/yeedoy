import type { Metadata } from 'next';
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PublicShell } from '@/src/ui/acik/yerlesim';
import { TalepFormu } from './talep-formu';

export const metadata: Metadata = {
  title: 'Sahiplenme Talebi | Yeedoy',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ id?: string }> };

export default async function SahiplenTalepPage({ searchParams }: Props) {
  const { id: businessId } = await searchParams;
  if (!businessId) redirect('/sahiplen/ara');

  // İşletme detayını çek
  const supabase = await createSupabaseServerClient();

  const { data: business } = await (supabase as any)
    .from('businesses')
    .select('id, name, category, city, district, address')
    .eq('id', businessId)
    .eq('is_active', true)
    .maybeSingle();

  if (!business) redirect('/sahiplen/ara');

  // Giriş yapmış mı?
  const { data: { user } } = await supabase.auth.getUser();

  // Giriş yoksa login'e yönlendir
  if (!user) {
    redirect(`/giris?redirect=${encodeURIComponent(`/sahiplen/talep?id=${businessId}`)}`);
  }

  // Daha önce talep var mı?
  const { data: existingClaim } = await (supabase as any)
    .from('owner_claims')
    .select('id, status')
    .eq('user_id', user.id)
    .eq('business_id', businessId)
    .maybeSingle();

  if (existingClaim?.status === 'approved') {
    redirect('/sahip/gosterge-panosu');
  }
  if (existingClaim?.status === 'pending') {
    redirect('/sahip/gosterge-panosu?bilgi=talep_bekliyor');
  }

  return (
    <PublicShell variant="owner">
      <main className="mx-auto max-w-xl px-4 py-10 sm:px-6">
        <div className="mb-8 text-center">
          <p className="text-xs font-[800] uppercase tracking-[0.2em] text-primary">
            Adım 2 / 2
          </p>
          <h1 className="mt-2 text-3xl font-[900] text-textStrong">
            Sahiplenme Talebi
          </h1>
        </div>

        {/* İşletme kartı */}
        <div className="mb-6 overflow-hidden rounded-2xl border border-border bg-bg">
          <div className="flex items-center gap-3 border-b border-border bg-primary/5 px-4 py-3">
            <span className="text-2xl">🏪</span>
            <div className="min-w-0">
              <p className="truncate font-[900] text-textStrong">{business.name}</p>
              <p className="text-xs text-muted">
                {[business.category, business.district, business.city].filter(Boolean).join(' · ')}
              </p>
            </div>
          </div>
          <div className="px-4 py-3 text-xs text-muted">
            {business.address && <p>{business.address}</p>}
            <p className="mt-0.5">ID: {businessId.slice(0, 8)}…</p>
          </div>
        </div>

        {/* Talep formu — dosya yükleme Client Component */}
        <TalepFormu businessId={businessId} />
      </main>
    </PublicShell>
  );
}
