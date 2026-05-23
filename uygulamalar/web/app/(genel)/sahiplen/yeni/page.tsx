import type { Metadata } from 'next';
import Link from 'next/link';
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PublicShell } from '@/src/ui/acik/yerlesim';
import { YeniIsletmeFormu } from './yeni-isletme-formu';

export const metadata: Metadata = {
  title: 'İşletmeni Ekle | Yeedoy',
  description: 'İşletmeniz Yeedoy\'da listeli değilse buradan başvuru yapın.',
  robots: { index: false, follow: false },
};

export default async function SahiplenYeniPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  // Giriş yoksa login'e yönlendir
  if (!user) {
    redirect(`/giris?redirect=${encodeURIComponent('/sahiplen/yeni')}`);
  }

  return (
    <PublicShell variant="owner">
      <main className="mx-auto max-w-xl px-4 py-10 sm:px-6">
        {/* Breadcrumb */}
        <div className="mb-2 flex items-center gap-2 text-xs text-muted">
          <Link href="/sahiplen/ara" className="hover:text-primary">← İşletme ara</Link>
          <span>›</span>
          <span>Yeni işletme ekle</span>
        </div>

        <div className="mb-8">
          <p className="text-xs font-[800] uppercase tracking-[0.2em] text-primary">
            İşletmem listede yok
          </p>
          <h1 className="mt-2 text-3xl font-[900] text-textStrong">
            Yeni İşletme Başvurusu
          </h1>
          <p className="mt-2 text-sm text-muted">
            Bilgilerinizi doldurun. Admin ekibimiz 1–3 iş günü içinde inceler, onay sonrası işletmeniz yayına alınır.
          </p>
        </div>

        <YeniIsletmeFormu />
      </main>
    </PublicShell>
  );
}
