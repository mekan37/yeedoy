'use client';

import Link from 'next/link';
import { useState, useTransition } from 'react';
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
  const [isMutating, startMutation] = useTransition();

  function handleRemove(businessIdToRemove: string) {
    if (isMutating) return;
    setError(null);
    startMutation(async () => {
      const result = await subeCikar(businessIdToRemove);
      if (result?.error) setError(result.error);
    });
  }

  function handleReorder(businessIdToMove: string, newSortOrder: number) {
    if (isMutating) return;
    setError(null);
    startMutation(async () => {
      const result = await subeSirasiGuncelle(businessIdToMove, newSortOrder);
      if (result?.error) setError(result.error);
    });
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
    <div className="flex flex-col gap-6">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <h1 className="text-2xl font-black tracking-tight text-textStrong">Çoklu Şube Yönetimi</h1>
          <p className="mt-1 text-sm text-muted">Tüm şubelerinizi yönetin, performanslarını takip edin ve detaylara hızlıca erişin.</p>
        </div>
        <button
          type="button"
          onClick={() => setActiveModal('yeni-sube')}
          className="inline-flex shrink-0 items-center gap-2 self-start rounded-xl px-4 py-2.5 text-sm font-extrabold text-white shadow-[0_4px_16px_rgba(127,29,29,0.28)] transition-all hover:-translate-y-px"
          style={{ background: 'linear-gradient(135deg, #7f1d1d, #dc2626)' }}
        >
          <PlusIcon /> Yeni Şube Ekle
        </button>
      </div>

      <div className="flex flex-col gap-6 lg:flex-row lg:items-start">
        <div className="flex min-w-0 flex-1 flex-col gap-6">
          <IstatistikKartlari overview={overview} />

          {error && <p className="text-xs font-bold text-red-600">{error}</p>}
          {bulkResult && <p className="rounded-xl bg-bg px-4 py-3 text-sm text-textStrong">{bulkResult}</p>}

          <SubeTablosu
            branches={overview.branches}
            onRemove={handleRemove}
            onReorder={handleReorder}
            reorderMode={reorderMode}
          />

          <div
            className="flex flex-col items-center gap-3 rounded-2xl border border-border p-6 text-center sm:flex-row sm:justify-between sm:text-left"
            style={{ background: 'linear-gradient(135deg, rgba(127,29,29,0.06), rgba(220,38,38,0.03))' }}
          >
            <div>
              <p className="font-black text-textStrong">Yeni şube ekleyerek büyüyün</p>
              <p className="text-sm text-muted">Yeni bir şube ekleyin, bilgilerini girin ve müşterilerin sizi daha kolay bulmasını sağlayın.</p>
            </div>
            <button
              type="button"
              onClick={() => setActiveModal('yeni-sube')}
              className="inline-flex shrink-0 items-center gap-2 rounded-xl px-4 py-2.5 text-sm font-extrabold text-white shadow-[0_4px_16px_rgba(127,29,29,0.28)] transition-all hover:-translate-y-px"
              style={{ background: 'linear-gradient(135deg, #7f1d1d, #dc2626)' }}
            >
              <PlusIcon /> Yeni Şube Ekle
            </button>
          </div>
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
                Kampanya Atama
              </button>
              <a
                href={`/sunucu/sahip/coklu-sube-rapor-csv?businessId=${businessId}`}
                className="rounded-xl border border-border px-3 py-2 text-left text-xs font-bold text-textStrong hover:bg-bg"
              >
                Raporu Dışa Aktar
              </a>
            </div>
          </div>

          <div className="rounded-2xl border border-amber-200 bg-amber-50 p-4">
            <p className="mb-1 flex items-center gap-1.5 text-xs font-extrabold text-amber-700">
              <BulbIcon /> İpucu
            </p>
            <p className="text-[11px] leading-relaxed text-amber-700/80">
              Şubelerinizin performansını artırmak için kampanya ve duyurularınızı bölgesel olarak özelleştirebilirsiniz.
            </p>
            <Link href="/sahip/destek" className="mt-2 inline-block text-[11px] font-extrabold text-amber-800 hover:underline">
              Daha fazla bilgi al →
            </Link>
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

function PlusIcon() {
  return (
    <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
      <path d="M12 5v14M5 12h14" />
    </svg>
  );
}
function BulbIcon() {
  return (
    <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M9 18h6M10 22h4M12 2a6 6 0 0 0-4 10.5c.5.5.8 1 1 1.5.2.5.2 1 .2 1.5V16h5.6v-1c0-.5 0-1 .2-1.5.2-.5.5-1 1-1.5A6 6 0 0 0 12 2Z" />
    </svg>
  );
}
