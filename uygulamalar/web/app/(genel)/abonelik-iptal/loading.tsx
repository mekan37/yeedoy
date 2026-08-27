// abonelik-iptal/page.tsx sonuca göre (başarılı/zaten çıkılmış/süresi dolmuş/geçersiz/
// hizmet dışı) tek bir merkezlenmiş kart render eder: üstte ikon dairesi, başlık,
// 1-2 paragraf açıklama ve alt CTA butonu. Bu iskelet o ortak kart şeklini yansıtır.
export default function AbonelikIptalLoading() {
  return (
    <main className="flex min-h-screen items-center justify-center bg-bg px-4">
      <div className="mx-auto max-w-md text-center">
        <div className="mb-6 flex items-center justify-center">
          <div className="h-16 w-16 animate-pulse rounded-full bg-card" />
        </div>
        <div className="mx-auto mb-3 h-7 w-64 animate-pulse rounded-xl bg-card" />
        <div className="mx-auto mb-2 h-3.5 w-full animate-pulse rounded-full bg-card" />
        <div className="mx-auto mb-8 h-3.5 w-3/4 animate-pulse rounded-full bg-card" />
        <div className="mx-auto h-11 w-44 animate-pulse rounded-2xl bg-card" />
      </div>
    </main>
  );
}
