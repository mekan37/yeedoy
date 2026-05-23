import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';

export const metadata: Metadata = {
  title: 'AI Menü Analizi | Owner Panel',
  robots: { index: false, follow: false },
};

export default async function OwnerAiAnalysisPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const { data: businesses } = await (supabase as any)
    .from('businesses')
    .select('id, name')
    .eq('owner_id', user!.id) as { data: Array<{ id: string; name: string }> | null };

  const list = (businesses ?? []) as Array<{ id: string; name: string }>;

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Owner"
        title="AI Menü Analizi"
        description="Yapay zeka ile menünüzü optimize edin"
      />
      <PanelContentSurface className="pt-6">
        {list.length === 0 ? (
          <PanelEmptyState
            icon={<SparklesIcon />}
            title="İşletme bulunamadı"
            description="AI analizi için önce bir işletme oluşturun."
          />
        ) : (
          <>
            <PanelSectionCard title="Menü Analizi" description="AI destekli menü optimizasyon önerileri">
              <p className="mb-4 text-sm text-muted">
                Yapay zeka, menünüzdeki ürünleri analiz ederek fiyat optimizasyonu, popülerlik tahmini ve
                eksik içerik tespiti gibi önerilerde bulunur. Analiz etmek istediğiniz işletmeyi seçin.
              </p>
              <div className="flex flex-col gap-3">
                {list.map((b) => (
                  <div
                    key={b.id}
                    className="flex items-center justify-between rounded-xl border border-border bg-zinc-50 px-4 py-3"
                  >
                    <p className="text-sm font-[700] text-textStrong">{b.name}</p>
                    <span className="rounded-lg border border-border bg-white px-3 py-1.5 text-xs font-[700] text-muted">
                      Analiz Et — yakında
                    </span>
                  </div>
                ))}
              </div>
            </PanelSectionCard>

            <div className="mt-4 rounded-xl border border-blue-100 bg-blue-50 p-4 text-sm text-blue-800">
              AI analiz motoru geliştirme aşamasındadır. Yakında otomatik fiyat önerileri, eksik görsel tespiti ve kategori düzenleme önerileri sunulacak.
            </div>
          </>
        )}
      </PanelContentSurface>
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
