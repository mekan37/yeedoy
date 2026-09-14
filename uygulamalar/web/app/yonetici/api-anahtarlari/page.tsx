import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = {
  title: 'API Anahtarları | Yönetici Paneli',
  robots: { index: false, follow: false },
};

// Denetimde bulundu: üretilen anahtarları doğrulayan/tüketen hiçbir yer
// (middleware, route, dış entegrasyon) yoktu — özellik baştan sona
// dekoratifti, admin'i "bu anahtar bir şeyi koruyor" diye yanıltıyordu.
// Canlıda hiç aktif anahtar yoktu (0 satır). Gerçek bir API yüzeyi
// tasarlanana kadar push-kampanyalari ile aynı desenle geçici olarak
// kapatıldı — sayfa silinmedi, sadece erişilemez hale getirildi.
export default function ApiAnahtarlariPage(): never {
  redirect('/yonetici/gosterge-panosu');
}
