import type { Metadata } from 'next';
import Link from 'next/link';
import { Store, Star, CircleDollarSign } from 'lucide-react';

export const metadata: Metadata = { title: 'Katkı Yap | Yeedoy', robots: { index: false, follow: false } };

const CONTRIBUTE_ITEMS = [
  { href: '/oneri', label: 'İşletme Öner', description: 'Yeedoy\'da görmek istediğin bir işletmeyi öner', icon: Store },
  { href: '/b', label: 'Yorum Yaz', description: 'Ziyaret ettiğin işletmelere yorum bırak', icon: Star },
  { href: '/kesif', label: 'Fiyat Doğrula', description: 'Menü fiyatlarının güncelliğini doğrula', icon: CircleDollarSign },
];

export default function ContributePage() {
  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-xl px-4 py-12">
        <Link href="/profil" className="mb-6 inline-flex items-center gap-1.5 text-sm text-muted hover:text-primary cursor-pointer">← Profile Dön</Link>
        <h1 className="mb-2 text-2xl font-black text-textStrong">Katkı Yap</h1>
        <p className="mb-8 text-sm text-muted">Topluluğa katkıda bulunarak puan ve rozet kazanın.</p>
        <div className="flex flex-col gap-4">
          {CONTRIBUTE_ITEMS.map(item => (
            <Link key={item.href} href={item.href} className="flex items-center gap-4 rounded-2xl border border-border bg-card p-5 transition-colors hover:border-primary/30 cursor-pointer">
              <item.icon className="h-7 w-7 shrink-0 text-primary" aria-hidden="true" />
              <div>
                <p className="font-bold text-textStrong">{item.label}</p>
                <p className="mt-0.5 text-sm text-muted">{item.description}</p>
              </div>
            </Link>
          ))}
        </div>
      </div>
    </main>
  );
}



