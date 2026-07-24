import type { Metadata } from 'next';
import Link from 'next/link';
import { ClipboardList, Wallet, MapPin, Star, BarChart2, Link2, type LucideProps } from 'lucide-react';
import type { ComponentType } from 'react';
import { PublicShell } from '@/src/ui/acik/yerlesim';

export const metadata: Metadata = {
  title: 'İşletmeniz için Yeedoy | Akıllı Menü ve Fiyat Platformu',
  description:
    'Restoranınızın menüsünü dijitalleştirin, fiyatlarınızı güncel tutun ve müşterilerinize ulaşın. Yeedoy ile işletmenizi öne çıkarın.',
  robots: { index: true, follow: true },
};

const OZELLIKLER: { icon: ComponentType<LucideProps>; baslik: string; aciklama: string }[] = [
  {
    icon: ClipboardList,
    baslik: 'Dijital Menü',
    aciklama:
      'QR kod ile erişilebilen, anında güncellenebilen dijital menü. Baskı masrafı yok, her zaman güncel.',
  },
  {
    icon: Wallet,
    baslik: 'Canlı Fiyat Takibi',
    aciklama:
      'Topluluk tarafından doğrulanan fiyatlar. Müşteriler menünüzü görerek gelir — sürpriz yok.',
  },
  {
    icon: MapPin,
    baslik: 'Konum Bazlı Keşif',
    aciklama:
      'Yakınındaki müşteriler sizi bulur. Kategori, fiyat ve kalite filtreleriyle doğru kitleye ulaşın.',
  },
  {
    icon: Star,
    baslik: 'Güvenilir Yorumlar',
    aciklama:
      'Gerçek ziyaretçilerden gelen doğrulanmış yorumlar. Puanınızı yükseltin, müşteri güvenini kazanın.',
  },
  {
    icon: BarChart2,
    baslik: 'Analitik Panel',
    aciklama:
      'Menü görüntülenme, tıklama ve dönüşüm verilerinizi takip edin. Kararlarınızı veriye dayandırın.',
  },
  {
    icon: Link2,
    baslik: 'Kolay Entegrasyon',
    aciklama:
      'Mevcut QR menü linkinizi ekleyin ya da menünüzü sıfırdan oluşturun. Her iki yol da birkaç dakika.',
  },
];

const ADIMLAR = [
  { no: '01', baslik: 'Hesap Oluştur', aciklama: 'E-posta ile kayıt olun, işletmenizi ekleyin.' },
  { no: '02', baslik: 'Menünüzü Ekleyin', aciklama: 'Mevcut QR linkinizi yapıştırın veya menüyü elle girin.' },
  { no: '03', baslik: 'Yayına Alın', aciklama: 'Onay sonrası işletmeniz keşif sayfasında görünür.' },
];

export default function IsletmeLandingPage() {
  return (
    <PublicShell variant="owner">
      {/* ── Hero ── */}
      <section className="mx-auto max-w-4xl px-5 pb-16 pt-20 text-center sm:pt-28">
        <span className="inline-block rounded-full border border-primary/25 bg-primary/8 px-4 py-1.5 text-xs font-extrabold uppercase tracking-[0.18em] text-primary">
          İşletmeler için
        </span>
        <h1 className="mt-5 text-4xl font-black leading-tight text-textStrong sm:text-5xl">
          Müşterileriniz menünüzü
          <br />
          <span className="text-primary">Google&apos;a bakmadan bulsun</span>
        </h1>
        <p className="mx-auto mt-5 max-w-2xl text-base leading-7 text-muted sm:text-lg">
          Yeedoy ile restoranınızın dijital menüsünü yayına alın, fiyatlarınızı güncel tutun
          ve yakınındaki müşterilere ulaşın. Ücretsiz başlayın.
        </p>
        <div className="mt-8 flex flex-wrap justify-center gap-3">
          <Link
            href="/sahiplen/ara"
            className="rounded-2xl bg-primary px-6 py-3.5 text-sm font-black text-white shadow-xs transition-opacity hover:opacity-90"
          >
            İşletmemi Bul →
          </Link>
          <a
            href="#nasil-calisir"
            className="rounded-2xl border border-border bg-bg px-6 py-3.5 text-sm font-extrabold text-text transition-colors hover:bg-card"
          >
            Nasıl çalışır?
          </a>
        </div>
      </section>

      {/* ── Özellikler ── */}
      <section className="border-t border-border bg-card py-16">
        <div className="mx-auto max-w-5xl px-5">
          <h2 className="text-center text-2xl font-black text-textStrong sm:text-3xl">
            İşletmeniz için her şey bir arada
          </h2>
          <div className="mt-10 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
            {OZELLIKLER.map((o) => (
              <div
                key={o.baslik}
                className="rounded-2xl border border-border bg-bg p-5"
              >
                <o.icon className="h-7 w-7 text-primary" aria-hidden="true" />
                <h3 className="mt-3 text-base font-black text-textStrong">{o.baslik}</h3>
                <p className="mt-1.5 text-sm leading-6 text-muted">{o.aciklama}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── Nasıl Çalışır ── */}
      <section id="nasil-calisir" className="py-16">
        <div className="mx-auto max-w-3xl px-5 text-center">
          <h2 className="text-2xl font-black text-textStrong sm:text-3xl">
            3 adımda başlayın
          </h2>
          <div className="mt-10 grid gap-5 sm:grid-cols-3">
            {ADIMLAR.map((a) => (
              <div key={a.no} className="rounded-2xl border border-border bg-bg p-6">
                <p className="text-3xl font-black text-primary/30">{a.no}</p>
                <h3 className="mt-2 text-base font-black text-textStrong">{a.baslik}</h3>
                <p className="mt-1.5 text-sm leading-6 text-muted">{a.aciklama}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── İletişim ── */}
      <section id="iletisim" className="border-t border-border bg-card py-16">
        <div className="mx-auto max-w-2xl px-5 text-center">
          <h2 className="text-2xl font-black text-textStrong sm:text-3xl">
            Sorularınız mı var?
          </h2>
          <p className="mt-3 text-muted">
            İşletmenizi platforma eklemeden önce bilgi almak isterseniz yazın.
          </p>
          <div className="mt-8 overflow-hidden rounded-2xl border border-border bg-bg">
            <form
              action="https://formsubmit.co/dtm3706@gmail.com"
              method="POST"
              className="space-y-4 p-6"
            >
              <input type="hidden" name="_subject" value="Yeedoy İşletme Başvurusu" />
              <input type="hidden" name="_captcha" value="false" />
              <input type="hidden" name="_template" value="table" />
              <div className="grid gap-4 sm:grid-cols-2">
                <div className="flex flex-col gap-1.5">
                  <label className="text-xs font-extrabold text-muted">İşletme Adı</label>
                  <input
                    name="isletme_adi"
                    required
                    placeholder="Restoran / Kafe adı"
                    className="min-h-11 rounded-xl border border-border bg-bg px-3 text-sm font-bold text-textStrong outline-hidden focus:ring-2 focus:ring-primary/30"
                  />
                </div>
                <div className="flex flex-col gap-1.5">
                  <label className="text-xs font-extrabold text-muted">E-posta</label>
                  <input
                    name="email"
                    type="email"
                    required
                    placeholder="siz@ornek.com"
                    className="min-h-11 rounded-xl border border-border bg-bg px-3 text-sm font-bold text-textStrong outline-hidden focus:ring-2 focus:ring-primary/30"
                  />
                </div>
              </div>
              <div className="flex flex-col gap-1.5">
                <label className="text-xs font-extrabold text-muted">Mesajınız</label>
                <textarea
                  name="mesaj"
                  rows={3}
                  placeholder="Merhaba, işletmemi nasıl ekleyebilirim?"
                  className="rounded-xl border border-border bg-bg px-3 py-2.5 text-sm font-bold text-textStrong outline-hidden focus:ring-2 focus:ring-primary/30"
                />
              </div>
              <button
                type="submit"
                className="w-full rounded-xl bg-primary py-3 text-sm font-black text-white transition-opacity hover:opacity-90"
              >
                Mesaj Gönder
              </button>
            </form>
          </div>
        </div>
      </section>

      {/* ── CTA Footer ── */}
      <section className="py-12 text-center">
        <p className="text-muted">
          Zaten hesabınız var mı?{' '}
          <Link href="/giris" className="font-extrabold text-primary hover:underline">
            Panel girişi →
          </Link>
        </p>
      </section>
    </PublicShell>
  );
}
