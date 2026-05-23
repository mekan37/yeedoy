import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinesses } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';

export const metadata: Metadata = {
  title: 'Yapay Zeka Menu Analizi | Sahip Paneli',
  robots: { index: false, follow: false },
};

export default async function OwnerAiAnalysisPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const list = user
    ? await getOwnerBusinesses<{ id: string; name: string }>(supabase as any, user.id, 'id, name')
    : [];

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Sahip"
        title="Yapay Zeka Menu Analizi"
        description="Yapay zeka ile menunuzu optimize edin"
      />
      <PanelIcerikYuzeyi className="pt-6">
        {list.length === 0 ? (
          <PanelEmptyState
            icon={<SparklesIcon />}
            title="İşletme bulunamadı"
            description="Yapay zeka analizi icin once bir isletme olusturun."
          />
        ) : (
          <>
            <PanelBolumKarti title="Menu Analizi" description="Yapay zeka destekli menu optimizasyon onerileri">
              <p className="mb-4 text-sm text-muted">
                Yapay zeka, menunuzdeki urunleri analiz ederek fiyat optimizasyonu, populerlik tahmini ve
                eksik icerik tespiti gibi onerilerde bulunur. Analiz etmek istediginiz isletmeyi secin.
              </p>
              <div className="flex flex-col gap-3">
                {list.map((b) => (
                  <div
                    key={b.id}
                    className="flex items-center justify-between rounded-xl border border-border bg-zinc-50 px-4 py-3"
                  >
                    <p className="text-sm font-[700] text-textStrong">{b.name}</p>
                    <span className="rounded-lg border border-border bg-white px-3 py-1.5 text-xs font-[700] text-muted">
                      Analiz Et - yakinda
                    </span>
                  </div>
                ))}
              </div>
            </PanelBolumKarti>

            <div className="mt-4 rounded-xl border border-blue-100 bg-blue-50 p-4 text-sm text-blue-800">
              Yapay zeka analiz motoru gelistirme asamasindadir. Yakinda otomatik fiyat onerileri, eksik gorsel tespiti ve kategori duzenleme onerileri sunulacak.
            </div>
          </>
        )}
      </PanelIcerikYuzeyi>
    </div>
  );
}

function SparklesIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 3l1.88 5.76L20 9l-5.12 3.73L16.76 18 12 14.6 7.24 18l1.88-5.27L4 9l6.12-.24L12 3z" />
    </svg>
  );
}

