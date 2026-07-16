import type { Metadata } from 'next';
import Link from 'next/link';
import Image from 'next/image';
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinesses } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { buildMenuImageUrl } from '@/src/lib/medya-adresi';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';

export const metadata: Metadata = {
  title: 'QR Tasarım Kiti | Sahip Paneli',
  robots: { index: false, follow: false },
};

type BizRow = {
  id: string;
  name: string;
  slug: string | null;
  category: string | null;
  logo_url: string | null;
  cover_url: string | null;
};

export default async function OwnerQrPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const list = await getOwnerBusinesses<BizRow>(
    supabase as any,
    user!.id,
    'id, name, slug, category, logo_url, cover_url',
  );

  // Tek işletmesi olan sahipler için işletme seçim adımını atla — owner'da olduğu gibi
  // doğrudan QR Studio'ya iniyor. Birden fazla işletmesi olanlar seçim listesini görür.
  if (list.length === 1) {
    redirect(`/sahip/karekod/${list[0].id}`);
  }

  // Her işletme için aktif QR kod sayısı
  const qrCounts: Record<string, number> = {};
  if (list.length > 0) {
    const { data: qrRows } = await (supabase as any)
      .from('business_qr_codes')
      .select('business_id, is_active')
      .in('business_id', list.map((b) => b.id));
    for (const row of (qrRows ?? []) as Array<{ business_id: string; is_active: boolean }>) {
      if (row.is_active) qrCounts[row.business_id] = (qrCounts[row.business_id] ?? 0) + 1;
    }
  }

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Owner"
        title="QR Tasarım Kiti"
        description="İşletmeleriniz için QR kodu oluşturun, indirin ve masalara yerleştirin"
      />
      <PanelIcerikYuzeyi className="pt-6">
        {list.length === 0 ? (
          <PanelEmptyState
            icon={<QrIcon />}
            title="İşletme bulunamadı"
            description="QR kodu oluşturmak için önce bir işletme ekleyin."
          />
        ) : (
          <>
            <p className="mb-4 text-sm text-muted">
              Açmak istediğiniz işletmenin QR Studio&apos;sunu seçin.
            </p>
            <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
              {list.map((b) => {
                const coverUrl = b.cover_url ? buildMenuImageUrl(b.cover_url, { width: 600, quality: 75 }) : null;
                const logoUrl = b.logo_url ? buildMenuImageUrl(b.logo_url, { width: 80, quality: 80 }) : null;
                const activeQrCount = qrCounts[b.id] ?? 0;

                return (
                  <PanelBolumKarti key={b.id} noPadding className="overflow-hidden">
                    {/* Kapak */}
                    <div className="relative h-[100px] bg-gradient-to-br from-primary/80 to-primary">
                      {coverUrl && (
                        <Image src={coverUrl} alt={b.name} fill sizes="(max-width:640px) 100vw, (max-width:1280px) 50vw, 33vw" className="object-cover" />
                      )}
                      <div className="absolute bottom-0 left-5 translate-y-1/2">
                        <div className="h-12 w-12 overflow-hidden rounded-2xl border-[3px] border-card bg-card shadow-md">
                          {logoUrl ? (
                            <Image src={logoUrl} alt={b.name} width={48} height={48} className="h-full w-full object-cover" />
                          ) : (
                            <div className="flex h-full w-full items-center justify-center bg-bg text-lg font-[900] text-primary">
                              {b.name.charAt(0).toUpperCase()}
                            </div>
                          )}
                        </div>
                      </div>
                    </div>

                    {/* Gövde */}
                    <div className="px-5 pb-5 pt-8">
                      <p className="truncate text-[15px] font-[900] text-textStrong">{b.name}</p>
                      {b.category && (
                        <p className="mt-0.5 truncate text-xs font-[600] text-muted">{b.category}</p>
                      )}
                      <div className="mt-3 flex items-center gap-2">
                        <span className={`inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-[11px] font-[800] ${
                          activeQrCount > 0 ? 'bg-primary/8 text-primary' : 'bg-bg text-muted'
                        }`}>
                          <QrIcon size={12} />
                          {activeQrCount > 0 ? `${activeQrCount} aktif QR kod` : 'Henüz QR kod yok'}
                        </span>
                      </div>
                      <Link
                        href={`/sahip/karekod/${b.id}`}
                        className="btn-primary mt-4 flex items-center justify-center gap-1.5 rounded-xl py-2.5 text-xs font-[800] text-white transition-opacity hover:opacity-90"
                      >
                        <QrIcon size={14} />
                        QR Studio&apos;yu Aç
                      </Link>
                    </div>
                  </PanelBolumKarti>
                );
              })}
            </div>
          </>
        )}
      </PanelIcerikYuzeyi>
    </div>
  );
}

function QrIcon({ size = 20 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="3" width="7" height="7" />
      <rect x="14" y="3" width="7" height="7" />
      <rect x="3" y="14" width="7" height="7" />
      <path d="M14 14h.01M14 17h.01M17 14h.01M17 17h.01M20 14h.01M20 17h.01M20 20h.01" />
    </svg>
  );
}
