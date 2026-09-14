import { redirect } from 'next/navigation';

// "Etkinlik" özelliği devre dışı — business_events tablosu hiçbir
// migration'da tanımlanmamış, her mutasyon 500 dönüyordu (Sahip Paneli
// Güvenlik Denetimi P2). Ürün kararı: özellik geçici olarak kapatıldı.
export default function OwnerEtkinlikPage() {
  redirect('/sahip/gosterge-panosu');
}
