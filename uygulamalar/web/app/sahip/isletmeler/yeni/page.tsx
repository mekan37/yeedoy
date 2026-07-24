import type { Metadata } from 'next';
import Link from 'next/link';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelActionButton } from '@/src/ui/bilesenler/panel-eylem-dugmesi';
import { NewBusinessForm } from './yeni-isletme-formu';

export const metadata: Metadata = {
  title: 'Yeni İşletme Başvurusu | Sahip Paneli',
  robots: { index: false, follow: false },
};

export default function OwnerNewBusinessPage() {
  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="İşletmeler"
        title="Yeni İşletme Başvurusu"
        description="İşletmenizi platforma eklemek için başvuru formu doldurun"
        actions={
          <Link href="/sahip/isletmeler">
            <PanelActionButton variant="ghost">← Geri</PanelActionButton>
          </Link>
        }
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="grid grid-cols-1 gap-5 lg:grid-cols-3">
          <div className="lg:col-span-2">
            <PanelBolumKarti title="İşletme Bilgileri">
              <NewBusinessForm />
            </PanelBolumKarti>
          </div>
          <div>
            <PanelBolumKarti title="Nasıl Çalışır?">
              <ol className="space-y-3 text-sm text-textStrong">
                {[
                  'Formu eksiksiz doldurun',
                  'Başvurunuz ekibimize iletilir',
                  'Bilgileriniz doğrulanır (1-3 iş günü)',
                  'Onay sonrası işletmeniz yayına alınır',
                  'Menünüzü oluşturmaya başlayabilirsiniz',
                ].map((step, i) => (
                  <li key={i} className="flex gap-3">
                    <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-primary/10 text-xs font-black text-primary">
                      {i + 1}
                    </span>
                    {step}
                  </li>
                ))}
              </ol>
            </PanelBolumKarti>
          </div>
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}

