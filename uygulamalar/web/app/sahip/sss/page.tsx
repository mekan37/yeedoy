import type { Metadata } from 'next';
import { PanelIcerikYuzeyi } from '@/src/ui/yerlesim/panel-section-card';
import { SssIstemcisi } from './sss-istemcisi';

export const metadata: Metadata = {
  title: 'Sıkça Sorulan Sorular | Sahip Paneli',
  robots: { index: false, follow: false },
};

export default function SahipSssSayfasi() {
  return (
    <div className="flex flex-col">
      <PanelIcerikYuzeyi className="pt-6">
        <SssIstemcisi />
      </PanelIcerikYuzeyi>
    </div>
  );
}
