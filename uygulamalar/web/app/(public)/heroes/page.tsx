import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = {
  title: 'Yeedoy',
  robots: { index: false, follow: false },
};

// /(genel)/liderler artık gerçek bir özellik sayfası (yönlendirme değil) —
// bu İngilizce mirror güncellenmemiş, yanlışlıkla /discover'a (iki sekmelik
// zincirle /kesif'e) düşüyordu. Doğrudan gerçek sayfaya yönlendir.
export default function HeroesPage(): never {
  redirect('/liderler');
}
