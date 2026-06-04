import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinesses, getOwnerBusinessIds } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { YapayZekaAnalizKarti } from './yapay-zeka-analiz-karti';
import { isleriniListele } from './yapay-zeka-analiz-islemi';

export const metadata: Metadata = {
  title: 'Yapay Zeka Menü Analizi | Sahip Paneli',
  robots: { index: false, follow: false },
};

export default async function OwnerAiAnalysisPage() {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  type BusinessRow = { id: string; name: string };

  const isletmeler = user
    ? await getOwnerBusinesses<BusinessRow>(supabase as any, user.id, 'id, name')
    : [];

  // İlk işletme için OCR job listesini sunucu tarafında pre-fetch et
  const ilkIsletme = isletmeler[0] ?? null;
  const ilkJoblar =
    ilkIsletme && user
      ? await (async () => {
          const sonuc = await isleriniListele(ilkIsletme.id);
          return sonuc.basarili ? sonuc.veri : [];
        })()
      : [];

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Sahip"
        title="Yapay Zeka Menü Analizi"
        description="Menü görsellerini OCR ile tarayın, yapay zeka ile alerjen, kalori ve içerik analizi yapın."
      />
      <PanelIcerikYuzeyi className="pt-6">
        {isletmeler.length === 0 ? (
          <PanelEmptyState
            icon={<SparklesIcon />}
            title="İşletme bulunamadı"
            description="Yapay zeka analizi için önce bir işletme oluşturun."
          />
        ) : (
          <div className="flex flex-col gap-6">
            {/* Bilgi kartı */}
            <div className="rounded-xl border border-blue-100 bg-blue-50 p-4 text-sm text-blue-800">
              <p className="font-[800]">Nasıl çalışır?</p>
              <ol className="mt-2 list-decimal pl-4 text-xs leading-relaxed text-blue-700">
                <li>Menü görseli yükleyin — DeepSeek OCR metni çıkarır (REPLICATE_API_TOKEN gerekli).</li>
                <li>
                  AI analizi başlatın — OpenRouter / Llama 3.1 8B her ürünü analiz eder
                  (OPENROUTER_API_KEY gerekli).
                </li>
                <li>Sonuçları inceleyin, doğru olanları onaylayın veya reddedin.</li>
              </ol>
            </div>

            {/* Birden fazla işletme varsa selector */}
            {isletmeler.length > 1 && (
              <PanelBolumKarti title="İşletme Seçin" description="Analiz yapmak istediğiniz işletmeyi seçin">
                <div className="flex flex-col gap-2">
                  {isletmeler.map((b) => (
                    <Link
                      key={b.id}
                      href={`/sahip/yapay-zeka-analizi?isletme=${b.id}`}
                      className="flex items-center justify-between rounded-xl border border-border bg-card px-4 py-3 hover:border-primary/40 hover:bg-primary/5 transition-colors"
                    >
                      <p className="text-sm font-[700] text-textStrong">{b.name}</p>
                      <span className="text-xs text-muted">Analiz Et →</span>
                    </Link>
                  ))}
                </div>
              </PanelBolumKarti>
            )}

            {/* Ana analiz kartı */}
            {ilkIsletme && (
              <PanelBolumKarti
                title={isletmeler.length === 1 ? ilkIsletme.name : undefined}
                description={isletmeler.length === 1 ? 'OCR görevleri ve analiz sonuçları' : undefined}
              >
                <YapayZekaAnalizKarti
                  businessId={ilkIsletme.id}
                  businessName={ilkIsletme.name}
                  initialJobs={ilkJoblar}
                />
              </PanelBolumKarti>
            )}
          </div>
        )}
      </PanelIcerikYuzeyi>
    </div>
  );
}

function SparklesIcon() {
  return (
    <svg
      width="20"
      height="20"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <path d="M12 3l1.88 5.76L20 9l-5.12 3.73L16.76 18 12 14.6 7.24 18l1.88-5.27L4 9l6.12-.24L12 3z" />
    </svg>
  );
}
