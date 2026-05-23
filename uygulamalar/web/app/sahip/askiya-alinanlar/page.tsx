import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinesses } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';

export const metadata: Metadata = {
  title: 'Askıya Alınan Yemekler | Sahip Paneli',
  robots: { index: false, follow: false },
};

const CLAIM_STATUS: Record<string, { label: string; className: string }> = {
  pending: { label: 'Bekliyor', className: 'bg-amber-50 text-amber-700' },
  approved: { label: 'Onaylandı', className: 'bg-green-50 text-green-700' },
  rejected: { label: 'Reddedildi', className: 'bg-red-50 text-red-700' },
  used: { label: 'Kullanıldı', className: 'bg-blue-50 text-blue-700' },
};

function formatPrice(cents: number, currency: string) {
  return new Intl.NumberFormat('tr-TR', { style: 'currency', currency: currency || 'TRY', minimumFractionDigits: 2 }).format(cents / 100);
}

export default async function OwnerSuspendedPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const businesses = user
    ? await getOwnerBusinesses<{ id: string; name: string }>(supabase as any, user.id, 'id, name')
    : [];

  const businessIds = businesses.map((b: any) => b.id);
  const bizMap = Object.fromEntries(businesses.map((b: any) => [b.id, b.name]));

  const { data: meals } = businessIds.length > 0
    ? await (supabase as any)
        .from('suspended_meals')
        .select('id, business_id, amount_cents, currency, message, status, created_at, expires_at')
        .in('business_id', businessIds)
        .order('created_at', { ascending: false })
        .limit(100)
    : { data: [] };

  const mealIds = ((meals ?? []) as any[]).map((m) => m.id);

  const { data: claims } = mealIds.length > 0
    ? await (supabase as any)
        .from('suspended_meal_claims')
        .select('id, suspended_meal_id, status, created_at, user_profiles(display_name)')
        .in('suspended_meal_id', mealIds)
        .order('created_at', { ascending: false })
    : { data: [] };

  const claimsByMeal = ((claims ?? []) as any[]).reduce<Record<string, any[]>>((acc, c) => {
    if (!acc[c.suspended_meal_id]) acc[c.suspended_meal_id] = [];
    acc[c.suspended_meal_id].push(c);
    return acc;
  }, {});

  const list = (meals ?? []) as any[];

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Owner"
        title="Askıya Alınan Yemekler"
        description="İşletmelerinize bırakılan askıya alınan yemek bağışları"
      />
      <PanelIcerikYuzeyi className="pt-6">
        {list.length === 0 ? (
          <PanelEmptyState
            icon={<GiftIcon />}
            title="Askıya alınan yemek yok"
            description="İşletmelerinize henüz askıya alınan yemek bağışı yapılmamış."
          />
        ) : (
          <div className="flex flex-col gap-4">
            {list.map((meal: any) => {
              const mealClaims = claimsByMeal[meal.id] ?? [];
              const isExpired = new Date(meal.expires_at) < new Date();
              return (
                <PanelBolumKarti key={meal.id} noPadding>
                  <div className="border-b border-border px-5 py-3">
                    <div className="flex items-center justify-between gap-4">
                      <div>
                        <p className="text-sm font-[800] text-textStrong">
                          {formatPrice(meal.amount_cents, meal.currency)}
                        </p>
                        <p className="text-xs text-muted">
                          {bizMap[meal.business_id] ?? meal.business_id} ·{' '}
                          {new Date(meal.created_at).toLocaleDateString('tr-TR')}
                        </p>
                      </div>
                      <div className="flex items-center gap-2">
                        {isExpired && (
                          <span className="rounded-full bg-zinc-100 px-2 py-0.5 text-[10px] font-[700] text-zinc-500">
                            Süresi Doldu
                          </span>
                        )}
                        <span className={`rounded-full px-2.5 py-0.5 text-[11px] font-[800] ${
                          meal.status === 'active' ? 'bg-green-50 text-green-700' : 'bg-zinc-100 text-zinc-500'
                        }`}>
                          {meal.status === 'active' ? 'Aktif' : meal.status}
                        </span>
                      </div>
                    </div>
                    {meal.message && (
                      <p className="mt-1.5 text-xs text-muted italic">&ldquo;{meal.message}&rdquo;</p>
                    )}
                  </div>
                  {mealClaims.length > 0 && (
                    <ul className="divide-y divide-border">
                      {mealClaims.map((claim: any) => {
                        const claimInfo = CLAIM_STATUS[claim.status] ?? CLAIM_STATUS['pending'];
                        return (
                          <li key={claim.id} className="flex items-center justify-between px-5 py-2.5">
                            <span className="text-sm text-textStrong">
                              {claim.user_profiles?.display_name ?? 'Kullanıcı'}
                            </span>
                            <span className={`rounded-full px-2 py-0.5 text-[10px] font-[700] ${claimInfo.className}`}>
                              {claimInfo.label}
                            </span>
                          </li>
                        );
                      })}
                    </ul>
                  )}
                  {mealClaims.length === 0 && (
                    <p className="px-5 py-3 text-xs text-muted">Henüz talep yok</p>
                  )}
                </PanelBolumKarti>
              );
            })}
          </div>
        )}
      </PanelIcerikYuzeyi>
    </div>
  );
}

function GiftIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <polyline points="20 12 20 22 4 22 4 12" />
      <rect x="2" y="7" width="20" height="5" />
      <line x1="12" y1="22" x2="12" y2="7" />
      <path d="M12 7H7.5a2.5 2.5 0 0 1 0-5C11 2 12 7 12 7z" />
      <path d="M12 7h4.5a2.5 2.5 0 0 0 0-5C13 2 12 7 12 7z" />
    </svg>
  );
}

