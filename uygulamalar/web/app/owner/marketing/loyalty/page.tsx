import type { Metadata } from 'next';
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinesses } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { getOwnerLoyaltyPrograms } from '@/src/lib/veri/owner/sadakat';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';
import { LoyaltyForm } from './loyalty-form';

export const metadata: Metadata = {
  title: 'Sadakat Programı | Owner Panel',
  robots: { index: false, follow: false },
};

interface PageProps {
  searchParams: Promise<{ business_id?: string }>;
}

export default async function OwnerLoyaltyPage({ searchParams }: PageProps) {
  const supabase = await createSupabaseServerClient();
  const supabaseAny = supabase as unknown as {
    auth: { getUser: () => Promise<{ data: { user: { id: string } | null } }> };
    from: (table: string) => any;
  };

  const {
    data: { user },
  } = await supabaseAny.auth.getUser();

  if (!user) {
    redirect('/login?redirect=/owner/marketing/loyalty');
  }

  type BusinessRow = { id: string; name: string };

  const businesses = await getOwnerBusinesses<BusinessRow>(
    supabase as any,
    user.id,
    'id, name',
  );

  if (businesses.length === 0) {
    return (
      <div className="flex flex-col">
        <PanelPageHeader
          eyebrow="Owner"
          title="Sadakat Programı"
          description="Müşterilerinizi ödüllendirin ve bağlılıklarını artırın"
        />
        <PanelContentSurface className="pt-6">
          <PanelEmptyState
            icon={<StarIcon />}
            title="Henüz bir işletmeniz yok"
            description="Sadakat programı oluşturabilmek için önce bir işletme sahiplenmeniz gerekiyor."
          />
        </PanelContentSurface>
      </div>
    );
  }

  const { business_id: qBusinessId } = await searchParams;
  const selectedId =
    qBusinessId && businesses.some((b) => b.id === qBusinessId)
      ? qBusinessId
      : businesses[0].id;

  const businessIds = businesses.map((b) => b.id);
  const { programs, fetchError } = await getOwnerLoyaltyPrograms(supabase as any, businessIds);

  const currentProgram = programs.find((p) => p.business_id === selectedId) ?? null;
  const selectedBusiness = businesses.find((b) => b.id === selectedId)!;

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Owner"
        title="Sadakat Programı"
        description="Müşterilerinizi ödüllendirin ve bağlılıklarını artırın"
      />

      <PanelContentSurface className="pt-6">
        {fetchError && (
          <div
            role="alert"
            className="mb-6 rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm font-[700] text-amber-800"
          >
            Program bilgileri yüklenirken hata oluştu. Sayfa varsayılan değerlerle gösteriliyor.
          </div>
        )}

        {/* Business selector — shown only when owner has multiple businesses */}
        {businesses.length > 1 && (
          <div className="mb-6">
            <BusinessSelector businesses={businesses} selectedId={selectedId} />
          </div>
        )}

        <div className="grid gap-6 lg:grid-cols-[1fr_320px]">
          {/* Main form column */}
          <div className="flex flex-col gap-6">
            {/* Current status summary */}
            <div className="flex items-center gap-3 rounded-xl border border-border bg-card px-5 py-3">
              <StatusDot active={currentProgram?.is_active ?? false} />
              <div>
                <p className="text-sm font-[800] text-textStrong">
                  {selectedBusiness.name}
                </p>
                <p className="text-xs text-muted">
                  {currentProgram
                    ? currentProgram.is_active
                      ? `Aktif — eşik: ${currentProgram.reward_threshold_pts} puan, ödül: ${currentProgram.reward_type === 'discount_pct' ? `%${currentProgram.reward_value} indirim` : 'bedava ürün'}`
                      : 'Pasif — program durdurulmuş'
                    : 'Henüz program tanımlanmamış'}
                </p>
              </div>
            </div>

            <LoyaltyForm businessId={selectedId} program={currentProgram} />
          </div>

          {/* Info sidebar */}
          <aside>
            <PanelSectionCard
              title="Nasıl Puan Kazanılır?"
              description="Müşteriye gösterilen özet"
            >
              <ul className="flex flex-col gap-3 text-sm">
                <InfoRow icon={<CheckinIcon />} label="İşletmeye check-in" />
                <InfoRow icon={<ReviewIcon />} label="Yorum yazmak" />
                <InfoRow icon={<PhotoIcon />} label="Fotoğraf yüklemek" />
                <InfoRow icon={<BirthdayIcon />} label="Doğum günü bonusu (pasif)" />
              </ul>
              <div className="mt-4 rounded-lg border border-border bg-bg p-3 text-xs text-muted">
                <strong className="font-[700] text-textStrong">İpucu:</strong> Eşik değeri yüksek
                tutulursa müşteriler daha uzun süre sadık kalır ama ödüle ulaşmaları
                zorlaşır. 300–800 puan arası dengeli bir başlangıçtır.
              </div>
            </PanelSectionCard>
          </aside>
        </div>
      </PanelContentSurface>
    </div>
  );
}

// ---- sub-components ----

function BusinessSelector({
  businesses,
  selectedId,
}: {
  businesses: Array<{ id: string; name: string }>;
  selectedId: string;
}) {
  return (
    <form method="GET" className="flex items-center gap-3">
      <label htmlFor="business_id" className="shrink-0 text-sm font-[700] text-textStrong">
        İşletme:
      </label>
      <select
        id="business_id"
        name="business_id"
        defaultValue={selectedId}
        className="h-10 rounded-lg border border-border bg-card px-3 text-sm text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/30"
      >
        {businesses.map((b) => (
          <option key={b.id} value={b.id}>
            {b.name}
          </option>
        ))}
      </select>
      <button
        type="submit"
        className="rounded-lg border border-border bg-card px-3 py-2 text-sm font-[700] text-textStrong hover:bg-black/[0.04]"
      >
        Seç
      </button>
    </form>
  );
}

function StatusDot({ active }: { active: boolean }) {
  return (
    <span
      className={`mt-0.5 h-2.5 w-2.5 shrink-0 rounded-full ${active ? 'bg-green-500' : 'bg-slate-300'}`}
      aria-hidden="true"
    />
  );
}

function InfoRow({ icon, label }: { icon: React.ReactNode; label: string }) {
  return (
    <li className="flex items-center gap-2.5 text-muted">
      <span className="flex h-5 w-5 shrink-0 items-center justify-center">{icon}</span>
      <span>{label}</span>
    </li>
  );
}

// ---- icons ----
function StarIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
    </svg>
  );
}

function CheckinIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z" />
      <circle cx="12" cy="10" r="3" />
    </svg>
  );
}

function ReviewIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
    </svg>
  );
}

function PhotoIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z" />
      <circle cx="12" cy="13" r="4" />
    </svg>
  );
}

function BirthdayIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
      <circle cx="12" cy="7" r="4" />
    </svg>
  );
}
