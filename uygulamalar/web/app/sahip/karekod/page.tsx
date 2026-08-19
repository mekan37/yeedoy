import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinesses } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { PremiumKilitRozeti } from '@/src/ui/bilesenler/premium-kilit-rozeti';

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

  const watermarkDurumu: Array<readonly [string, boolean]> = await Promise.all(
    list.map((b) =>
      (supabase as any)
        .rpc('get_my_plan_v1', { p_business_id: b.id })
        .then((r: { data: { features: Array<{ feature_key: string; enabled: boolean }> } | null }) => [
          b.id,
          r?.data?.features.find((f) => f.feature_key === 'qr_watermark')?.enabled ?? true,
        ] as const)
        .catch(() => [b.id, true] as const),
    ),
  );
  const filigranAcikMi = new Map(watermarkDurumu);
  const filigranliIsletmeVar = watermarkDurumu.some(([, acik]) => acik);

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Sahip"
        title="QR Tasarım Kiti"
        description="İşletmeleriniz için QR kodu oluşturun, indirin ve masalara yerleştirin"
      />
      <PanelIcerikYuzeyi className="pt-6">
        {filigranliIsletmeVar && (
          <div className="mb-5 flex flex-wrap items-center justify-between gap-3 rounded-2xl border border-amber-200 bg-amber-50 px-4 py-3">
            <p className="text-xs font-bold text-amber-800">
              Ücretsiz kademede QR kodlarınızda Yeedoy filigranı görünür.
            </p>
            <PremiumKilitRozeti label="Filigranı kaldır" />
          </div>
        )}
        {list.length === 0 ? (
          <PanelEmptyState
            icon={<QrIcon />}
            title="İşletme bulunamadı"
            description="QR kodu oluşturmak için önce bir işletme ekleyin."
          />
        ) : (
          <PanelBolumKarti title="İşletmeleriniz" description="Açmak istediğiniz işletmenin QR Stüdyosu'nu seçin">
            <ul className="divide-y divide-border -mx-5 -mb-5">
              {list.map((b) => (
                <li key={b.id} className="flex items-center justify-between gap-4 px-5 py-4">
                  <div>
                    <div className="flex items-center gap-2">
                      <p className="text-sm font-extrabold text-textStrong">{b.name}</p>
                      {filigranAcikMi.get(b.id) && <PremiumKilitRozeti label="Filigranlı" />}
                    </div>
                    {b.slug && (
                      <p className="text-xs text-muted">yeedoy.com/m/{b.slug}</p>
                    )}
                  </div>
                  <Link
                    href={`/karekod/${b.id}`}
                    className="inline-flex items-center gap-1.5 rounded-xl bg-primary px-4 py-2 text-xs font-extrabold text-white transition-opacity hover:opacity-90"
                  >
                    <QrIcon />
                    QR Stüdyosu
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

