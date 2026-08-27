import Link from 'next/link';

type Props = {
  business?: { id: string; name: string } | null;
};

export default function MenuNotFound({ business }: Props) {
  return (
    <main className="mx-auto flex min-h-screen w-full max-w-4xl items-center px-4 py-12 sm:px-6">
      <section className="w-full overflow-hidden rounded-[32px] border border-border bg-card shadow-yd2">
        <div className="bg-[radial-gradient(circle_at_top_left,rgba(255,255,255,0.28),transparent_36%),linear-gradient(135deg,rgb(var(--yd-color-primary-rgb)),rgb(var(--yd-color-primary-strong-rgb)))] px-8 py-10 text-white">
          <p className="text-xs font-black uppercase tracking-[0.24em] text-white/75">404</p>
          <h1 className="mt-3 text-3xl font-black sm:text-4xl">Menü bulunamadı</h1>
          <p className="mt-3 max-w-2xl text-sm leading-7 text-white/84">
            {business
              ? `${business.name} için henüz yayında bir menü yok.`
              : 'Bu işletmenin yayında bir açık menüsü yok ya da yol anahtarı artık geçersiz.'}
          </p>
        </div>
        <div className="space-y-5 px-8 py-8">
          {business ? (
            <div className="rounded-[24px] border border-primary/20 bg-(--yd-color-primary-soft) p-5">
              <p className="text-xs font-black uppercase tracking-[0.2em] text-primary">Bu senin işletmen mi?</p>
              <p className="mt-2 text-sm leading-7 text-text">
                Bu işletmeyi sahiplenip birkaç dakikada dijital menünü oluşturabilirsin — müşterilerin karekodu
                okuttuğunda güncel menünü görsün.
              </p>
              <Link
                href={`/sahiplen/talep?id=${encodeURIComponent(business.id)}`}
                className="mt-4 inline-flex rounded-2xl bg-primary px-5 py-3 text-sm font-black text-white shadow-xs transition-all hover:opacity-90"
              >
                İşletmeni sahiplen, menünü ekle
              </Link>
            </div>
          ) : (
            <div className="rounded-[24px] border border-border bg-bg p-5">
              <p className="text-xs font-black uppercase tracking-[0.2em] text-muted">Neye bakılmalı</p>
              <p className="mt-2 text-sm leading-7 text-text">
                Karekodu tekrar açın, açık menü slug&apos;ını ya da karekod bağlantısını doğrulayın.
              </p>
            </div>
          )}
          <Link
            href="/"
            className="inline-flex rounded-2xl border border-border bg-card px-5 py-3 text-sm font-black text-textStrong transition-colors hover:bg-cardAlt"
          >
            Ana sayfa
          </Link>
        </div>
      </section>
    </main>
  );
}
