import { Skeleton, SkeletonText } from '@/src/ui/bilesenler/iskele';

// Bu 24+ /(kimlik) rotasının paylaştığı jenerik yedek — form sayfaları
// (ayarlar, şifre değiştir) ile liste sayfaları (yorumlarım, takip) arasında
// ortak bir zemin olsun diye kart/avatar şekli yerine nötr, tam genişlik
// bloklar kullanılıyor. Yüksek trafikli rotalarda kendi loading.tsx'i olsun.
export default function AuthLoading() {
  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-2xl px-4 py-12">
        {/* Back link */}
        <div className="mb-6 h-5 w-24 animate-pulse rounded-lg bg-border" />

        {/* Title */}
        <div className="mb-8 h-8 w-48 animate-pulse rounded-xl bg-border" />

        {/* Nötr içerik blokları */}
        <div className="flex flex-col gap-4">
          <Skeleton className="h-12 w-full" />
          <Skeleton className="h-12 w-full" />
          <Skeleton className="h-12 w-2/3" />
          <SkeletonText lines={3} className="mt-2" />
        </div>
      </div>
    </main>
  );
}
