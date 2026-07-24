import type { Metadata } from 'next';
import Link from 'next/link';
import { PublicShell } from '@/src/ui/acik/yerlesim';
import { Container } from '@/src/ui/acik/ortak';

export const metadata: Metadata = {
  title: 'Gizlilik Politikası | Yeedoy',
  description:
    'Yeedoy uygulamasının kişisel veri işleme politikası, KVKK kapsamında haklarınız ve iletişim bilgileri.',
  alternates: {
    canonical: 'https://yeedoy.com/gizlilik',
  },
  robots: { index: true, follow: true },
};

export default function GizlilikPolitikasiSayfasi() {
  return (
    <PublicShell>
      <main className="min-h-screen bg-bg">
        <Container className="py-12">
          <div className="mx-auto max-w-3xl">
            {/* Geri linki */}
            <div className="mb-8">
              <Link
                href="/yasal"
                className="inline-flex items-center gap-1.5 text-sm text-muted hover:text-primary"
              >
                ← Yasal Bilgilere Dön
              </Link>
            </div>

            {/* Başlık */}
            <h1 className="mb-2 text-3xl font-black text-textStrong">Gizlilik Politikası</h1>
            <p className="mb-10 text-xs text-muted">Son güncelleme: Haziran 2026</p>

            {/* 1. Giriş */}
            <section className="mb-8">
              <h2 className="mb-3 text-lg font-extrabold text-textStrong">1. Giriş</h2>
              <p className="text-sm leading-7 text-text">
                Yeedoy (&quot;biz&quot;, &quot;uygulama&quot;) olarak gizliliğinize önem veriyoruz.
                Bu politika, Yeedoy mobil uygulaması ve web sitesi aracılığıyla hangi kişisel
                verileri topladığımızı, bu verileri nasıl kullandığımızı ve 6698 sayılı Kişisel
                Verilerin Korunması Kanunu (KVKK) kapsamında haklarınızı açıklamaktadır.
              </p>
            </section>

            {/* 2. Hangi Verileri Topluyoruz */}
            <section className="mb-8">
              <h2 className="mb-3 text-lg font-extrabold text-textStrong">2. Hangi Verileri Topluyoruz?</h2>

              <h3 className="mb-2 text-sm font-extrabold text-textStrong">2.1 Hesap ve Profil Verileri</h3>
              <p className="mb-5 text-sm leading-7 text-text">
                Kayıt olduğunuzda e-posta adresinizi ve seçtiğiniz kullanıcı adını topluyoruz.
                Profil fotoğrafı eklemeyi tercih ederseniz bu görsel de saklanır. Sosyal giriş
                (Google) kullanırsanız yalnızca temel profil bilgileri aktarılır.
              </p>

              <h3 className="mb-2 text-sm font-extrabold text-textStrong">2.2 Konum Verisi</h3>
              <p className="mb-5 text-sm leading-7 text-text">
                Yakın çevredeki işletmeleri gösterebilmek için uygulamanın konum iznine ihtiyacı
                vardır. Konum verisi yalnızca arama anında kullanılır, sürekli arka planda
                izlenmez ve saklanmaz. Konum iznini dilediğiniz zaman cihaz ayarlarından
                kaldırabilirsiniz.
              </p>

              <h3 className="mb-2 text-sm font-extrabold text-textStrong">2.3 Menü ve Fiyat Katkıları</h3>
              <p className="mb-5 text-sm leading-7 text-text">
                Menü fiyatı bildirimi veya yorum yapmanız durumunda bu katkı hesabınızla
                ilişkilendirilir. Topluluk verisi olarak anonim aggregate halinde kullanılabilir;
                bireysel katkılar yalnızca hesabınız üzerinden görünür.
              </p>

              <h3 className="mb-2 text-sm font-extrabold text-textStrong">2.4 Fotoğraf ve Kamera İzinleri</h3>
              <p className="mb-5 text-sm leading-7 text-text">
                QR kod okuma ve profil/menü fotoğrafı yükleme işlevleri için kamera iznine
                ihtiyaç duyulur. Bu izin yalnızca siz aktif olarak kullanırken çalışır.
              </p>

              <h3 className="mb-2 text-sm font-extrabold text-textStrong">2.5 Bildirim İzinleri</h3>
              <p className="text-sm leading-7 text-text">
                Push bildirimi göndermek için sisteminizin bildirim iznini kullanırız.
                Bildirimleri istediğiniz zaman cihaz ayarlarından veya uygulama ayarlarından
                kapatabilirsiniz.
              </p>
            </section>

            {/* 3. Üçüncü Taraf Hizmetler */}
            <section className="mb-8">
              <h2 className="mb-3 text-lg font-extrabold text-textStrong">3. Üçüncü Taraf Hizmetler</h2>

              <h3 className="mb-2 text-sm font-extrabold text-textStrong">3.1 Google AdMob</h3>
              <p className="mb-5 text-sm leading-7 text-text">
                Uygulama içi reklam gösterimi için Google AdMob kullanılmaktadır. AdMob, reklam
                kişiselleştirme amacıyla cihaz tanımlayıcısı ve kullanım verisi toplayabilir.
                Google&apos;ın gizlilik politikası:{' '}
                <a
                  href="https://policies.google.com/privacy"
                  className="text-primary hover:underline"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  policies.google.com/privacy
                </a>
              </p>

              <h3 className="mb-2 text-sm font-extrabold text-textStrong">3.2 Firebase / Google Analytics</h3>
              <p className="text-sm leading-7 text-text">
                Uygulama performansını iyileştirmek için Firebase Analytics ve Firebase
                Crashlytics kullanılmaktadır. Bu hizmetler anonim kullanım istatistikleri ve
                hata raporları toplar. Toplanan veriler bireysel olarak tanımlanamaz.
              </p>
            </section>

            {/* 4. KVKK Hakları */}
            <section className="mb-8">
              <h2 className="mb-3 text-lg font-extrabold text-textStrong">4. KVKK Kapsamında Haklarınız</h2>
              <p className="mb-4 text-sm leading-7 text-text">
                6698 sayılı KVKK kapsamında kişisel verilerinize ilişkin şu haklara sahipsiniz:
              </p>
              <ul className="space-y-2 pl-5 text-sm leading-7 text-text" style={{ listStyleType: 'disc' }}>
                <li>Kişisel verilerinizin işlenip işlenmediğini öğrenme</li>
                <li>Kişisel verileriniz işlenmişse buna ilişkin bilgi talep etme</li>
                <li>
                  Kişisel verilerinizin işlenme amacını ve bunların amacına uygun kullanılıp
                  kullanılmadığını öğrenme
                </li>
                <li>
                  Yurt içinde veya yurt dışında kişisel verilerinizin aktarıldığı üçüncü
                  kişileri bilme
                </li>
                <li>Eksik veya yanlış işlenen kişisel verilerinizin düzeltilmesini isteme</li>
                <li>
                  KVKK&apos;nın 7. maddesinde öngörülen şartlar çerçevesinde kişisel
                  verilerinizin silinmesini veya yok edilmesini isteme
                </li>
                <li>
                  İşlenen verilerin münhasıran otomatik sistemler vasıtasıyla analiz edilmesi
                  suretiyle aleyhinize bir sonucun ortaya çıkmasına itiraz etme
                </li>
              </ul>
              <p className="mt-4 text-sm leading-7 text-text">
                Bu haklarınızı kullanmak için aşağıdaki iletişim bilgilerini kullanabilirsiniz.
              </p>
            </section>

            {/* 5. Saklama ve Silme */}
            <section className="mb-8">
              <h2 className="mb-3 text-lg font-extrabold text-textStrong">
                5. Verilerin Saklanması ve Silinmesi
              </h2>
              <p className="text-sm leading-7 text-text">
                Kişisel verileriniz, hizmet ilişkisi devam ettiği sürece veya yasal yükümlülükler
                gerektirdiği ölçüde saklanır. Hesabınızı sildiğinizde kişisel verileriniz yasal
                saklama süreleri saklı kalmak kaydıyla 30 gün içinde sistemlerimizden kaldırılır.
                Anonim aggregate veri (örn. fiyat endeksi istatistikleri) anonimleştirilmiş
                şekilde saklanmaya devam edebilir.
              </p>
            </section>

            {/* 6. İletişim */}
            <section className="mb-8">
              <h2 className="mb-3 text-lg font-extrabold text-textStrong">6. İletişim</h2>
              <p className="mb-3 text-sm leading-7 text-text">
                Gizlilik politikamız veya kişisel verilerinizle ilgili sorularınız için:
              </p>
              <ul className="space-y-1 text-sm text-text" style={{ listStyleType: 'none' }}>
                <li>
                  E-posta:{' '}
                  <a
                    href="mailto:destek@yeedoy.com"
                    className="text-primary hover:underline"
                  >
                    destek@yeedoy.com
                  </a>
                </li>
                <li>
                  Web:{' '}
                  <a
                    href="https://yeedoy.com"
                    className="text-primary hover:underline"
                  >
                    yeedoy.com
                  </a>
                </li>
              </ul>
            </section>

            {/* Alt çizgi */}
            <hr className="my-8 border-border" />
            <p className="text-xs text-muted">
              Bu gizlilik politikası en son Haziran 2026 tarihinde güncellenmiştir. Değişiklikler
              bu sayfada yayınlanacaktır.
            </p>
          </div>
        </Container>
      </main>
    </PublicShell>
  );
}
