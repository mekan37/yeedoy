import type { MetadataRoute } from 'next';
import { appConfig } from '@/src/lib/ayarlar';
import { getSitemapBusinessChunkCount } from '@/src/lib/veri/sitemap-parcalari';

export default async function robots(): Promise<MetadataRoute.Robots> {
  const siteUrl = appConfig.siteUrl().replace(/\/$/, '');

  // app/sitemap.ts generateSitemaps() ile birden fazla dosyaya bölündüğü için
  // (id 0 = statik+coğrafi, id 1..N = işletme parçaları), Next.js bunları tek
  // bir /sitemap.xml altında birleştirmiyor — her parçanın kendi URL'i
  // (/sitemap/0.xml, /sitemap/1.xml, ...) burada ayrı ayrı listelenmeli.
  let businessChunks = 1;
  try {
    businessChunks = await getSitemapBusinessChunkCount();
  } catch {
    // DB hatasında en azından statik+coğrafi parçayı (id 0) bildir.
  }

  const sitemaps = Array.from({ length: businessChunks + 1 }, (_, i) => `${siteUrl}/sitemap/${i}.xml`);

  return {
    rules: [
      {
        userAgent: '*',
        allow: ['/', '/m/', '/kod/', '/kesif', '/en-iyiler', '/isletme/', '/arama'],
        // /admin/ ve /owner/ (İngilizce ağaçlar) 2026-07-22'de tamamen silindi —
        // artık var olmayan rotaları disallow etmenin bir faydası yok, kaldırıldı.
        // /sunucu/ eklendi: /api/ ile aynı mantıkla route handler'ların bulunduğu
        // dizin, crawler'ların GET'e izin veren uçlara (isletme-ara, acik-grafik
        // vb.) gereksiz istek göndermesini önler. /b/ BİLİNÇLİ OLARAK disallow
        // edilmiyor — /isletme/[slug]'e işaret eden bir canonical etiketi taşıyor,
        // disallow edilirse Google o sayfayı hiç crawl edemeyeceği için canonical
        // sinyalini de göremez.
        disallow: ['/giris', '/karekod/', '/api/', '/sunucu/', '/auth/', '/forbidden', '/yasakli', '/sahip/', '/yonetici/'],
      },
    ],
    sitemap: sitemaps,
    host: siteUrl,
  };
}
