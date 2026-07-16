import type { Metadata } from 'next';
import Link from 'next/link';
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinesses } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';

export const metadata: Metadata = {
  title: 'QR Tasarım Kiti | Sahip Paneli',
  robots: { index: false, follow: false },
};

export default async function OwnerQrPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const list = await getOwnerBusinesses<{ id: string; name: string; slug: string | null }>(
    supabase as any,
    user!.id,
    'id, name, slug',
  );

  // Tek işletmesi olan sahipler için işletme seçim adımını atla — owner'da olduğu gibi
  // doğrudan QR Studio'ya iniyor. Birden fazla işletmesi olanlar seçim listesini görür.
  if (list.length === 1) {
    redirect(`/sahip/karekod/${list[0].id}`);
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
          <PanelBolumKarti title="İşletmeleriniz" description="Açmak istediğiniz işletmenin QR Studio'sunu seçin">
            <ul className="divide-y divide-border -mx-5 -mb-5">
              {list.map((b) => (
                <li key={b.id} className="flex items-center justify-between gap-4 px-5 py-4">
                  <div>
                    <p className="text-sm font-[800] text-textStrong">{b.name}</p>
                    {b.slug && (
                      <p className="text-xs text-muted">yeedoy.com/m/{b.slug}</p>
                    )}
                  </div>
                  <Link
                    href={`/sahip/karekod/${b.id}`}
                    className="inline-flex items-center gap-1.5 rounded-xl bg-primary px-4 py-2 text-xs font-[800] text-white transition-opacity hover:opacity-90"
                  >
                    <QrIcon />
                    QR Studio
                  </Link>
                </li>
              ))}
            </ul>
          </PanelBolumKarti>
        )}
      </PanelIcerikYuzeyi>
    </div>
  );
}

function QrIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="3" width="7" height="7" />
      <rect x="14" y="3" width="7" height="7" />
      <rect x="3" y="14" width="7" height="7" />
      <path d="M14 14h.01M14 17h.01M17 14h.01M17 17h.01M20 14h.01M20 17h.01M20 20h.01" />
    </svg>
  );
}

