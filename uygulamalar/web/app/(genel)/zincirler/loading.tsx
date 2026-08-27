// zincirler/page.tsx MVP kapsamı dışıdır ve senkron redirect('/kesif') ile hiçbir
// içerik render etmeden yönlendirir. Bu iskelet, yönlendirme sırasında olası kısa
// bir an için nötr/genel bir yükleme durumu gösterir — sayfaya özgü gerçek bir
// içerik yerleşimi yoktur.
export default function ZincilerLoading() {
  return (
    <main className="flex min-h-screen items-center justify-center bg-bg px-4">
      <div className="flex flex-col items-center gap-3">
        <div className="h-10 w-10 animate-pulse rounded-full bg-card" />
        <div className="h-3.5 w-40 animate-pulse rounded-full bg-card" />
      </div>
    </main>
  );
}
