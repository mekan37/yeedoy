import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = {
  title: 'Pazarlama | Sahip Paneli',
  robots: { index: false, follow: false },
};

// docs/product/2026-yeedoy-final-scope-source-of-truth.md'ye göre Sadakat/Loyalty
// açıkça MVP dışı; E-posta ve Otomasyonlar da (arka uç gönderim mekanizması hazır
// olmadığı için) kapalı tutuluyor. Pazarlama alanında şu an kapsamda olan tek
// alt özellik Kampanyalar — bu yüzden "Pazarlama" nav öğesi eskiden olduğu gibi
// Genel Bakış'a değil, doğrudan çalışan Kampanyalar sayfasına yönlendiriyor.
export default function OwnerMarketingPage(): never {
  redirect('/sahip/pazarlama/kampanyalar');
}
