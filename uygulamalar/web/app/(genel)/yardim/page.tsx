import type { Metadata } from 'next';
import Link from 'next/link';
import { PublicShell } from '@/src/ui/acik/yerlesim';
import { Container } from '@/src/ui/acik/ortak';

export const metadata: Metadata = {
  title: 'Yardım & SSS | Yeedoy',
  description: 'Sık sorulan sorular ve yardım rehberi.',
};

const SECTIONS = [
  {
    title: 'Hesap & Giriş',
    items: [
      {
        q: 'Hesap nasıl oluşturabilirim?',
        a: 'Sağ üstteki "Giriş Yap" butonuna tıklayıp "Hesap oluştur" seçeneğini kullanabilirsiniz. E-posta veya Google/Apple hesabınızla kayıt olabilirsiniz.',
      },
      {
        q: 'Şifremi unuttum, ne yapmalıyım?',
        a: 'Giriş sayfasında "Şifremi unuttum" bağlantısına tıklayarak e-posta adresinize şifre sıfırlama bağlantısı gönderebilirsiniz.',
      },
      {
        q: 'Hesabımı nasıl silebilirim?',
        a: 'Profil → Ayarlar → Hesabı Sil bölümünden hesabınızı kalıcı olarak silebilirsiniz. Bu işlem geri alınamaz.',
      },
    ],
  },
  {
    title: 'Keşfet & Arama',
    items: [
      {
        q: 'İşletmeleri nasıl bulabilirim?',
        a: 'Keşfet sayfasından şehir, kategori veya ad ile arama yapabilirsiniz. Konumunuzu paylaşarak yakın işletmeleri de listeleyebilirsiniz.',
      },
      {
        q: 'Favorilere nasıl ekleyebilirim?',
        a: 'İşletme kartı veya detay sayfasındaki kalp ikonuna tıklayarak favorilerinize ekleyebilirsiniz.',
      },
      {
        q: 'QR kod menüsü nasıl çalışır?',
        a: 'İşletmenin masasındaki QR kodu telefonunuzla taratarak dijital menüye anında ulaşabilirsiniz.',
      },
    ],
  },
  {
    title: 'Fiyat Katkıları',
    items: [
      {
        q: 'Fiyat nasıl güncelleyebilirim?',
        a: 'Menü sayfasındaki herhangi bir ürüne tıklayıp "Fiyat güncelle" seçeneğiyle güncel fiyatı girebilirsiniz. Katkılarınız doğrulama sürecinden geçer.',
      },
      {
        q: 'Katkılarım puanı nasıl etkiler?',
        a: 'Her onaylanan fiyat güncellemesi ve yorum puan kazandırır. Puan tablonuzu Liderler sayfasından görebilirsiniz.',
      },
    ],
  },
  {
    title: 'İşletme Sahipleri',
    items: [
      {
        q: 'İşletmemi nasıl ekleyebilirim?',
        a: '"İşletmeni Ekle" sayfasından başvurunuzu yapabilirsiniz. Ekibimiz en kısa sürede inceleyecektir.',
      },
      {
        q: 'Menü ve fiyatlarımı nasıl yönetirim?',
        a: 'İşletme panelinizden menü öğelerinizi düzenleyebilir, fiyat ve stok bilgilerini güncelleyebilirsiniz.',
      },
    ],
  },
];

export default function HelpPage() {
  return (
    <PublicShell>
      <main className="min-h-screen bg-bg py-12">
        <Container>
          <div className="mx-auto max-w-3xl">
            <h1 className="mb-3 text-3xl font-black text-textStrong">Yardım & SSS</h1>
            <p className="mb-10 text-muted">Sık sorulan sorular ve nasıl kullanacağınıza dair rehber.</p>

            <div className="space-y-8">
              {SECTIONS.map((section) => (
                <section key={section.title}>
                  <h2 className="mb-4 text-lg font-black text-textStrong">{section.title}</h2>
                  <div className="divide-y divide-border rounded-[24px] border border-border bg-card overflow-hidden">
                    {section.items.map((item) => (
                      <details key={item.q} className="group px-5 py-4">
                        <summary className="flex cursor-pointer items-center justify-between gap-4 text-sm font-extrabold text-textStrong [&::-webkit-details-marker]:hidden">
                          {item.q}
                          <svg
                            viewBox="0 0 24 24"
                            className="h-4 w-4 shrink-0 text-muted transition-transform group-open:rotate-180"
                            fill="none"
                            stroke="currentColor"
                            strokeWidth="2"
                            strokeLinecap="round"
                            strokeLinejoin="round"
                            aria-hidden="true"
                          >
                            <polyline points="6 9 12 15 18 9" />
                          </svg>
                        </summary>
                        <p className="mt-3 text-sm leading-relaxed text-muted">{item.a}</p>
                      </details>
                    ))}
                  </div>
                </section>
              ))}
            </div>

            <div className="mt-12 rounded-[24px] border border-border bg-cardAlt p-8 text-center">
              <h3 className="mb-2 font-black text-textStrong">Cevabını bulamadın mı?</h3>
              <p className="mb-4 text-sm text-muted">Doğrudan bize ulaşabilirsin.</p>
              <a
                href="mailto:destek@yeedoy.com"
                className="inline-flex min-h-11 items-center gap-2 rounded-2xl border border-border bg-card px-5 text-sm font-extrabold text-textStrong hover:border-primary/30"
              >
                destek@yeedoy.com
              </a>
            </div>
          </div>
        </Container>
      </main>
    </PublicShell>
  );
}
