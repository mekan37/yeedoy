import type { Metadata } from 'next';
import Link from 'next/link';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelActionButton } from '@/src/ui/components/panel-action-button';
import { NewBusinessForm } from './new-business-form';

export const metadata: Metadata = {
  title: 'Yeni İşletme Başvurusu | Owner Panel',
  robots: { index: false, follow: false },
};

export default function OwnerNewBusinessPage() {
  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="İşletmeler"
        title="Yeni İşletme Başvurusu"
        description="İşletmenizi platforma eklemek için başvuru formu doldurun"
        actions={
          <Link href="/owner/businesses">
            <PanelActionButton variant="ghost">← Geri</PanelActionButton>
          </Link>
        }
      />
      <PanelContentSurface className="pt-6">
        <div className="grid grid-cols-1 gap-5 lg:grid-cols-3">
          <div className="lg:col-span-2">
            <PanelSectionCard title="İşletme Bilgileri">
              <NewBusinessForm />
            </PanelSectionCard>
          </div>
          <div>
            <PanelSectionCard title="Nasıl Çalışır?">
              <ol className="space-y-3 text-sm text-textStrong">
                {[
                  'Formu eksiksiz doldurun',
                  'Başvurunuz ekibimize iletilir',
                  'Bilgileriniz doğrulanır (1-3 iş günü)',
                  'Onay sonrası işletmeniz yayına alınır',
                  'Menünüzü oluşturmaya başlayabilirsiniz',
                ].map((step, i) => (
                  <li key={i} className="flex gap-3">
                    <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-primary/10 text-xs font-[900] text-primary">
                      {i + 1}
                    </span>
                    {step}
                  </li>
                ))}
              </ol>
            </PanelSectionCard>
          </div>
        </div>
      </PanelContentSurface>
    </div>
  );
}
