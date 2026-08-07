'use client';

import { useState } from 'react';
import type { CokluSubeOverview } from './coklu-sube-yardimcilari';
import { subeCikar, subeSirasiGuncelle } from './coklu-sube-islemleri';
import { IstatistikKartlari } from './bilesenler/istatistik-kartlari';
import { SubeTablosu } from './bilesenler/sube-tablosu';
import { SehirDagilimi } from './bilesenler/sehir-dagilimi';
import { ZincirOlusturFormu } from './bilesenler/zincir-olustur-formu';
import { YeniSubeEkleFormu } from './bilesenler/yeni-sube-ekle-formu';
import { TopluSaatFormu } from './bilesenler/toplu-saat-formu';
import { TopluKampanyaFormu } from './bilesenler/toplu-kampanya-formu';

type ActiveModal = 'yeni-sube' | 'toplu-saat' | 'toplu-kampanya' | null;

export function CokluSubeIstemcisi({
  businessId,
  initialOverview,
}: {
  businessId: string;
  initialOverview: CokluSubeOverview;
}) {
  const overview = initialOverview;
  const [activeModal, setActiveModal] = useState<ActiveModal>(null);
  const [error, setError] = useState<string | null>(null);
  const [bulkResult, setBulkResult] = useState<string | null>(null);
  const [reorderMode, setReorderMode] = useState(false);

  async function handleRemove(businessIdToRemove: string) {
    setError(null);
    const result = await subeCikar(businessIdToRemove);
    if (result?.error) setError(result.error);
  }

  async function handleReorder(businessIdToMove: string, newSortOrder: number) {
    setError(null);
    const result = await subeSirasiGuncelle(businessIdToMove, newSortOrder);
    if (result?.error) setError(result.error);
  }

  function handleBulkDone(kind: 'saat' | 'kampanya', successCount: number, failedCount: number) {
    setActiveModal(null);
    const label = kind === 'saat' ? 'Çalışma saatleri' : 'Kampanya';
    setBulkResult(
      failedCount === 0
        ? `${label} ${successCount} şubeye başarıyla uygulandı.`
        : `${label} ${successCount} şubeye uygulandı, ${failedCount} şubede hata oluştu.`,
    );
  }

  if (!overview.chain_id) {
    return <ZincirOlusturFormu businessId={businessId} onSuccess={() => setActiveModal(null)} />;
  }

  return (
    <div className="flex flex-col gap-6 lg:flex-row lg:items-start">
      <div className="flex min-w-0 flex-1 flex-col gap-6">
        <IstatistikKartlari overview={overview} />

        {error && <p className="text-xs font-bold text-red-600">{error}</p>}
        {bulkResult && <p className="rounded-xl bg-bg px-4 py-3 text-sm text-textStrong">{bulkResult}</p>}

        <div className="flex justify-end">
          <button
            type="button"
            onClick={() => setActiveModal('yeni-sube')}
            className="rounded-xl bg-primary px-3 py-2 text-sm font-bold text-white cursor-pointer"
          >
            + Yeni Şube Ekle
          </button>
        </div>

        <SubeTablosu
          branches={overview.branches}
          onRemove={handleRemove}
          onReorder={handleReorder}
          reorderMode={reorderMode}
        />
      </div>

      <div className="flex w-full flex-col gap-4 lg:w-80 lg:shrink-0">
        <SehirDagilimi branches={overview.branches} />

        <div className="rounded-2xl border border-border bg-card p-4">
          <h3 className="mb-3 text-sm font-black text-textStrong">Hızlı İşlemler</h3>
          <div className="flex flex-col gap-2">
            <button
              type="button"
              onClick={() => setReorderMode((prev) => !prev)}
              className={`rounded-xl border px-3 py-2 text-left text-xs font-bold cursor-pointer ${
                reorderMode ? 'border-primary bg-primary/10 text-primary' : 'border-border text-textStrong hover:bg-bg'
              }`}
            >
              {reorderMode ? 'Sıralamayı Bitir' : 'Şube Sıralamasını Düzenle'}
            </button>
            <button
              type="button"
              onClick={() => setActiveModal('toplu-saat')}
              className="rounded-xl border border-border px-3 py-2 text-left text-xs font-bold text-textStrong hover:bg-bg cursor-pointer"
            >
              Çalışma Saatlerini Yönet
            </button>
            <button
              type="button"
              onClick={() => setActiveModal('toplu-kampanya')}
              className="rounded-xl border border-border px-3 py-2 text-left text-xs font-bold text-textStrong hover:bg-bg cursor-pointer"
            >
              Kampanya Ata
            </button>
            <a
              href={`/sunucu/sahip/coklu-sube-rapor-csv?businessId=${businessId}`}
              className="rounded-xl border border-border px-3 py-2 text-left text-xs font-bold text-textStrong hover:bg-bg"
            >
              Raporu Dışa Aktar (CSV)
            </a>
          </div>
        </div>
      </div>

      {activeModal === 'yeni-sube' && (
        <YeniSubeEkleFormu
          chainId={overview.chain_id}
          onSuccess={() => setActiveModal(null)}
          onCancel={() => setActiveModal(null)}
        />
      )}
      {activeModal === 'toplu-saat' && (
        <TopluSaatFormu
          branches={overview.branches}
          onDone={(s, f) => handleBulkDone('saat', s, f)}
          onCancel={() => setActiveModal(null)}
        />
      )}
      {activeModal === 'toplu-kampanya' && (
        <TopluKampanyaFormu
          branches={overview.branches}
          onDone={(s, f) => handleBulkDone('kampanya', s, f)}
          onCancel={() => setActiveModal(null)}
        />
      )}
    </div>
  );
}
