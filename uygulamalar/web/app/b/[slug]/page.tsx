import { permanentRedirect } from 'next/navigation';

type Props = { params: Promise<{ slug: string }> };

// /b/<slug> mobil uygulamanın paylaştığı kısa deep-link formatıdır (bkz.
// yeedoy_route_resolver.dart) — kaldırılamaz. Asıl işletme sayfası
// /isletme/[slug]'de yaşıyor, kod tekrarını önlemek için buraya kalıcı
// yönlendirme yapılıyor. Bilerek `(public)` grubunun DIŞINDA tutuluyor:
// `(public)/loading.tsx` bu grubun tüm sayfalarını bir Suspense sınırına
// sarıyor, ve o sınırın içindeki bir sayfada redirect() çağrısı gerçek
// bir HTTP 308 yerine yalnızca istemci tarafında (JS ile) çalışıyor —
// link-unfurl bot'ları veya curl gibi JS çalıştırmayan istemciler için
// yetersiz kalır.
export default async function BusinessShortLinkPage({ params }: Props) {
  const { slug } = await params;
  permanentRedirect(`/isletme/${slug}`);
}
