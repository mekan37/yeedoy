import type { Metadata } from 'next';
import { PublicShell } from '@/src/ui/acik/yerlesim';
import { Container } from '@/src/ui/acik/ortak';

// aria-labelledby bir IDREF listesidir (boşlukla ayrılır) — section.title'daki boşluklar
// ve Türkçe karakterler id/aria-labelledby'yi geçersiz kılıyordu (ekran okuyucular
// referansı bulamıyordu). Başlığı geçerli tek bir id token'ına indirger.
function slugifySection(text: string): string {
  return text
    .toLocaleLowerCase('tr-TR')
    .replace(/ğ/g, 'g')
    .replace(/ş/g, 's')
    .replace(/ı/g, 'i')
    .replace(/ç/g, 'c')
    .replace(/ö/g, 'o')
    .replace(/ü/g, 'u')
    .replace(/\s+/g, '-')
    .replace(/[^a-z0-9-]/g, '');
}

export const metadata: Metadata = {
  title: 'Yardım Merkezi | Yeedoy',
  description:
    'Yeedoy hakkında sık sorulan sorular, hesap yönetimi ve destek iletişim bilgileri.',
  alternates: {
    canonical: '/destek',
  },
  robots: { index: true, follow: true },
};

const FAQ_SECTIONS = [
  {
    title: 'Hesap ve Giriş',
    items: [
      {
        q: 'Hesap nasıl oluşturabilirim?',
        a: 'Sağ üstteki "Giriş Yap" butonuna tıklayıp "Hesap oluştur" seçeneğini kullanabilirsiniz. E-posta adresinizle veya Google / Apple hesabınızla kayıt olabilirsiniz.',
      },
      {
        q: 'Şifremi unuttum, ne yapmalıyım?',
        a: 'Giriş sayfasındaki "Şifremi unuttum" bağlantısına tıklayın. E-posta adresinize sıfırlama bağlantısı gönderilecektir. Birkaç dakika içinde gelmezse spam klasörünüzü kontrol edin.',
      },
      {
        q: 'Hesabımı nasıl silebilirim?',
        a: 'Profil → Düzenle → Hesabı Sil bölümünden hesabınızı kalıcı olarak silebilirsiniz. Silme işlemi geri alınamaz; tüm kişisel verileriniz KVKK kapsamında kaldırılır.',
      },
      {
        q: 'Profil bilgilerimi nasıl güncelleyebilirim?',
        a: 'Profil sayfasındaki "Düzenle" butonuna tıklayarak görünen adınızı, biyografinizi, şehrinizi ve profil fotoğrafınızı düzenleyebilirsiniz.',
      },
    ],
  },
  {
    title: 'Keşif ve Arama',
    items: [
      {
        q: 'İşletmeleri nasıl bulabilirim?',
        a: 'Keşfet sayfasından şehir, kategori veya işletme adıyla arama yapabilirsiniz. Konum iznini etkinleştirerek çevrenizde açık olan mekanları listeleyebilirsiniz.',
      },
      {
        q: 'QR kod menüsü nasıl çalışır?',
        a: 'İşletmedeki QR kodu kameranızla taratın. Dijital menü tarayıcınızda açılır; uygulama indirmeniz gerekmez.',
      },
      {
        q: 'Favori işletmelerimi nasıl kaydederim?',
        a: 'İşletme kartındaki veya detay sayfasındaki kalp ikonuna tıklayarak favorilerinize ekleyebilirsiniz. Favorilerinize Profil → Favorilerim bölümünden ulaşabilirsiniz.',
      },
    ],
  },
  {
    title: 'Fiyat Katkıları ve Öneriler',
    items: [
      {
        q: 'Menü fiyatını nasıl güncelleyebilirim?',
        a: 'Menü sayfasındaki bir ürüne tıklayıp "Fiyat güncelle" seçeneğini kullanın. Katkılarınız topluluk doğrulama sürecinden geçtikten sonra yayınlanır.',
      },
      {
        q: 'Yeni bir işletme önerebilir miyim?',
        a: "Evet! Önerilerim sayfasından Yeedoy'da görmek istediğiniz işletmeleri ekibimize iletebilirsiniz. Önerilerinizin durumunu aynı sayfadan takip edebilirsiniz.",
      },
    ],
  },
  {
    title: 'İşletme Sahipleri',
    items: [
      {
        q: "İşletmemi Yeedoy'a nasıl ekletirim?",
        a: '"İşletmeni Ekle" sayfasından başvurunuzu yapabilirsiniz. Ekibimiz en kısa sürede inceleyip size geri dönecektir.',
      },
      {
        q: 'Menü ve fiyatlarımı nasıl yönetirim?',
        a: 'İşletme sahipliğinizi doğruladıktan sonra sahip panelinden menülerinizi, ürünlerinizi ve fiyatlarınızı kolayca güncelleyebilirsiniz.',
      },
    ],
  },
  {
    title: 'Gizlilik ve Verilerim',
    items: [
      {
        q: 'Kişisel verilerimi silmek istiyorum, ne yapmalıyım?',
        a: 'Profil → Düzenle → Hesabı Sil adımlarını izleyerek tüm verilerinizin silinmesini talep edebilirsiniz. KVKK kapsamındaki diğer veri talepleriniz için kvkk@yeedoy.com adresine yazabilirsiniz.',
      },
      {
        q: 'Pazarlama e-postalarını nasıl durdurabilirim?',
        a: 'Profil → Bildirim Ayarları sayfasından "Pazarlama E-postaları" seçeneğini kapatabilirsiniz.',
      },
    ],
  },
];

export default function DestekSayfasi() {
  return (
    <PublicShell>
      <main className="min-h-screen bg-bg py-12">
        <Container>
          <div className="mx-auto max-w-3xl">
            {/* Başlık */}
            <div className="mb-10">
              <p className="mb-1 text-xs font-black uppercase tracking-widest text-primary">Destek</p>
              <h1 className="text-3xl font-black text-textStrong sm:text-4xl">Yardım Merkezi</h1>
              <p className="mt-3 text-base leading-relaxed text-muted">
                Sık sorulan sorular ve Yeedoy&apos;u nasıl kullanacağınıza dair rehber.
              </p>
            </div>

            {/* SSS bölümleri */}
            <div className="space-y-8">
              {FAQ_SECTIONS.map((section) => (
                <section key={section.title} aria-labelledby={`section-${slugifySection(section.title)}`}>
                  <h2
                    id={`section-${slugifySection(section.title)}`}
                    className="mb-4 text-lg font-black text-textStrong"
                  >
                    {section.title}
                  </h2>
                  <div className="overflow-hidden divide-y divide-border rounded-[24px] border border-border bg-card">
                    {section.items.map((item) => (
                      <details key={item.q} className="group px-5 py-4">
                        <summary className="flex cursor-pointer list-none items-center justify-between gap-4 text-sm font-extrabold text-textStrong [&::-webkit-details-marker]:hidden">
                          <span>{item.q}</span>
                          <svg
                            viewBox="0 0 24 24"
                            className="h-4 w-4 shrink-0 text-muted transition-transform duration-200 group-open:rotate-180"
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

            {/* Destek iletişim kartı */}
            <div className="mt-12 rounded-[24px] border border-border bg-cardAlt p-8 text-center">
              <div className="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-2xl bg-(--yd-color-primary-soft)">
                <svg
                  viewBox="0 0 24 24"
                  className="h-6 w-6 fill-none stroke-current text-primary"
                  strokeWidth="2"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  aria-hidden="true"
                >
                  <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z" />
                  <polyline points="22,6 12,13 2,6" />
                </svg>
              </div>
              <h3 className="mb-2 font-black text-textStrong">Cevabını bulamadın mı?</h3>
              <p className="mb-5 text-sm leading-relaxed text-muted">
                Destek ekibimiz Pazartesi–Cuma 09:00–18:00 saatleri arasında size yardımcı olmaktan mutluluk duyar.
              </p>
              <a
                href="mailto:destek@yeedoy.com"
                className="inline-flex min-h-11 items-center gap-2.5 rounded-2xl border border-border bg-card px-5 text-sm font-extrabold text-textStrong transition-colors hover:border-primary/30 hover:text-primary focus-visible:outline-hidden focus-visible:ring-2 focus-visible:ring-primary/30"
              >
                <svg
                  viewBox="0 0 24 24"
                  className="h-4 w-4 shrink-0 fill-none stroke-current"
                  strokeWidth="2"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  aria-hidden="true"
                >
                  <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z" />
                  <polyline points="22,6 12,13 2,6" />
                </svg>
                destek@yeedoy.com
              </a>
            </div>
          </div>
        </Container>
      </main>
    </PublicShell>
  );
}
