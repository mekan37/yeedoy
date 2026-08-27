import Image from 'next/image';
import Link from 'next/link';
import { Badge } from '@/src/ui/acik/ortak';
import { Icon } from '@/src/ui/acik/simgeler';
import { BusinessCard } from '@/src/ui/acik/kesif';
import { buildMenuImageUrl } from '@/src/lib/medya-adresi';
import type { AcikIsletmeKarti } from '@/src/ui/acik/tipler';

type NotFoundBusiness = {
  id: string;
  name: string;
  category?: string | null;
  city?: string | null;
  district?: string | null;
  coverUrl?: string | null;
  logoUrl?: string | null;
  isVerified?: boolean | null;
};

type Props = {
  business?: NotFoundBusiness | null;
  similar?: AcikIsletmeKarti[];
};

export default function MenuNotFound({ business, similar = [] }: Props) {
  const cover = business ? buildMenuImageUrl(business.coverUrl || business.logoUrl, { width: 900, quality: 78 }) : null;
  const location = business ? [business.district, business.city].filter(Boolean).join(' • ') : null;

  return (
    <main className="mx-auto w-full max-w-4xl px-4 py-10 sm:px-6">
      {business ? (
        <div className="mb-6 flex items-center gap-4 rounded-[28px] border border-border bg-card p-4 shadow-yd1">
          <div className="relative h-16 w-16 shrink-0 overflow-hidden rounded-2xl bg-cardAlt">
            {cover ? (
              <Image src={cover} alt="" fill sizes="64px" className="object-cover" />
            ) : (
              <div className="flex h-full items-center justify-center text-muted"><Icon name="image" size={22} /></div>
            )}
          </div>
          <div className="min-w-0">
            <div className="flex items-center gap-2">
              <h1 className="truncate text-lg font-black text-textStrong">{business.name}</h1>
              {business.isVerified ? <Badge tone="success">Onaylı</Badge> : null}
            </div>
            <p className="mt-0.5 truncate text-sm text-muted">
              {[business.category, location].filter(Boolean).join(' · ')}
            </p>
          </div>
        </div>
      ) : null}

      <section className="w-full overflow-hidden rounded-[32px] border border-border bg-card shadow-yd2">
        <div className="bg-[radial-gradient(circle_at_top_left,rgba(255,255,255,0.28),transparent_36%),linear-gradient(135deg,rgb(var(--yd-color-primary-rgb)),rgb(var(--yd-color-primary-strong-rgb)))] px-8 py-10 text-white">
          <p className="text-xs font-black uppercase tracking-[0.24em] text-white/75">404</p>
          {business ? (
            <h2 className="mt-3 text-3xl font-black sm:text-4xl">Menü bulunamadı</h2>
          ) : (
            <h1 className="mt-3 text-3xl font-black sm:text-4xl">Menü bulunamadı</h1>
          )}
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
              <div className="mt-4 grid gap-3 sm:grid-cols-3">
                <div className="rounded-2xl border border-border bg-card p-3">
                  <p className="text-xs font-black text-textStrong">1. Sahiplen</p>
                  <p className="mt-1 text-xs leading-5 text-muted">Birkaç dakikada başvurunu yap.</p>
                </div>
                <div className="rounded-2xl border border-border bg-card p-3">
                  <p className="text-xs font-black text-textStrong">2. Menünü ekle</p>
                  <p className="mt-1 text-xs leading-5 text-muted">Kategori ve ürünlerini kolayca oluştur.</p>
                </div>
                <div className="rounded-2xl border border-border bg-card p-3">
                  <p className="text-xs font-black text-textStrong">3. Müşteriye ulaş</p>
                  <p className="mt-1 text-xs leading-5 text-muted">Karekodu okutanlar güncel menünü görsün.</p>
                </div>
              </div>
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

      {similar.length > 0 ? (
        <div className="mt-8">
          <p className="mb-4 text-lg font-black text-textStrong">Bu arada şunlara göz at</p>
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {similar.map((b) => (
              <BusinessCard key={b.id} business={b} />
            ))}
          </div>
        </div>
      ) : null}
    </main>
  );
}
