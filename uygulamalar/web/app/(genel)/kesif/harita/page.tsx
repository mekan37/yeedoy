import type { Metadata } from 'next';
import { PublicShell } from '@/src/ui/acik/yerlesim';
import { getMapBusinesses } from '@/src/lib/veri/harita-okuma';
import { appConfig } from '@/src/lib/ayarlar';
import { HaritaSarmalayici } from './harita-sarmalayici';

export const revalidate = 120;

export function generateMetadata(): Metadata {
  const siteUrl = appConfig.siteUrl().replace(/\/$/, '');
  const canonical = `${siteUrl}/kesif/harita`;
  return {
    title: 'Harita — Yakındaki Restoranlar | Yeedoy',
    description: 'Türkiye genelinde restoranları, kafeleri ve işletmeleri harita üzerinde keşfedin.',
    alternates: { canonical },
    robots: { index: true, follow: true },
    openGraph: {
      title: 'Harita — Yakındaki Restoranlar | Yeedoy',
      description: 'İşletmeleri harita üzerinde keşfet. Fiyat seviyesi, açık/kapalı durumu ve menü detayı.',
      url: canonical,
      images: [{ url: `${siteUrl}/sunucu/acik-grafik?title=Harita+Ke%C5%9Ffi`, width: 1200, height: 630, alt: 'Harita Keşfi | Yeedoy' }],
    },
  };
}

export default async function HaritaPage() {
  const businesses = await getMapBusinesses(39.9334, 32.8597, 50, 200);

  return (
    <PublicShell footer={false}>
      {/* calc: 100vh - header yüksekliği (64px) */}
      <div style={{ height: 'calc(100vh - 64px)' }} className="overflow-hidden">
        <HaritaSarmalayici businesses={businesses} />
      </div>
    </PublicShell>
  );
}
