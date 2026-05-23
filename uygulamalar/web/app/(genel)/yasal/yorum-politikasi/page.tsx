import type { Metadata } from 'next';
import Link from 'next/link';

export const metadata: Metadata = {
  title: 'Yorum ve İçerik Politikası | Yeedoy',
  description: 'Yeedoy platformunda yorum, fiyat katkısı ve içerik paylaşımına ilişkin kurallar.',
};

export default function YorumPolitikasiPage() {
  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-3xl px-4 py-12">
        <div className="mb-8">
          <Link href="/yasal" className="inline-flex items-center gap-1.5 text-sm text-muted hover:text-primary">
            ← Yasal Bilgilere Dön
          </Link>
        </div>

        <h1 className="mb-3 text-3xl font-[900] text-textStrong">Yorum ve İçerik Politikası</h1>
        <p className="mb-8 text-sm text-muted">Son güncelleme: Mayıs 2026</p>

        <div className="prose-yeedoy space-y-8 text-sm leading-7 text-text">

          <section>
            <h2 className="mb-3 text-lg font-[900] text-textStrong">1. Genel İlkeler</h2>
            <p>
              Yeedoy, kullanıcıların restoran ve yemek deneyimlerini paylaşması için bir platform sunar.
              Tüm yorumlar, fiyat katkıları ve diğer içerikler gerçek deneyimlere dayalı, dürüst ve saygılı olmalıdır.
            </p>
          </section>

          <section>
            <h2 className="mb-3 text-lg font-[900] text-textStrong">2. Yorum Kuralları</h2>
            <ul className="mt-2 space-y-2 pl-5">
              {[
                'Yorumlar gerçek bir ziyaret veya sipariş deneyimine dayanmalıdır.',
                'Hakaret, ayrımcılık veya nefret söylemi içeren yorumlar kabul edilmez.',
                'Rakip işletme sahiplerinin kendi işletmeleri için yorum yazması yasaktır.',
                'Ticari amaçlı veya sponsorlu içerikler açıkça belirtilmelidir.',
                'Kişisel iletişim bilgileri (telefon, e-posta) yorum içinde paylaşılamaz.',
                'Telif hakkı ihlali içeren fotoğraf veya metin kullanımı yasaktır.',
              ].map((rule) => (
                <li key={rule} className="flex items-start gap-2">
                  <span className="mt-1.5 h-1.5 w-1.5 shrink-0 rounded-full bg-primary" />
                  {rule}
                </li>
              ))}
            </ul>
          </section>

          <section>
            <h2 className="mb-3 text-lg font-[900] text-textStrong">3. Fiyat Katkıları</h2>
            <p>
              Fiyat katkıları, gerçek menü fiyatlarını yansıtmalıdır. Kasıtlı olarak yanlış fiyat
              girilmesi, kasıtlı manipülasyon sayılır ve hesap kapatılmasına yol açabilir.
              Tüm fiyat katkıları editöryal incelemeden geçer.
            </p>
          </section>

          <section>
            <h2 className="mb-3 text-lg font-[900] text-textStrong">4. İçerik Sahipliği</h2>
            <p>
              Platforma yüklediğiniz yorumlar, fotoğraflar ve katkılar için Yeedoy&apos;a geniş kapsamlı,
              telif ücretsiz, alt lisans verilebilir bir lisans vermiş olursunuz. Özgün içeriğinizin
              sahibi olmaya devam edersiniz; ancak Yeedoy bu içerikleri platform amaçlarıyla kullanabilir.
            </p>
          </section>

          <section>
            <h2 className="mb-3 text-lg font-[900] text-textStrong">5. İçerik Denetimi ve Kaldırma</h2>
            <p>
              Yeedoy, kurallara aykırı içerikleri önceden haber vermeksizin kaldırma ve hesapları
              askıya alma hakkını saklı tutar. İçerik kaldırma kararlarına itiraz için{' '}
              <a href="mailto:icerik@yeedoy.com" className="text-primary hover:underline">
                icerik@yeedoy.com
              </a>{' '}
              adresine yazabilirsiniz.
            </p>
          </section>

          <section>
            <h2 className="mb-3 text-lg font-[900] text-textStrong">6. Yorum Yanıtları</h2>
            <p>
              İşletme sahipleri, kendilerine yapılan yorumlara yanıt verebilir. Bu yanıtlar da aynı
              kurallar çerçevesinde değerlendirilir. Yanıtlar müşteri şikayetlerini çözmek amacıyla
              kullanılmalı, kişisel saldırı veya yanıltıcı bilgi içermemelidir.
            </p>
          </section>

          <section>
            <h2 className="mb-3 text-lg font-[900] text-textStrong">7. Anonim Katkılar ve Hesap Silme</h2>
            <p>
              Hesabınızı sildiğinizde yorumlarınız anonimleştirilir (kullanıcı adı kaldırılır) ancak
              içerik platformda kalabilir. Fiyat katkılarınız topluluk verisi olarak anonimleştirilerek
              saklanır.
            </p>
          </section>

          <section>
            <h2 className="mb-3 text-lg font-[900] text-textStrong">8. Şikayet ve Bildirme</h2>
            <p>
              Kurallara aykırı bir içerik gördüğünüzde &quot;Şikayet Et&quot; özelliğini kullanabilir veya{' '}
              <a href="mailto:destek@yeedoy.com" className="text-primary hover:underline">
                destek@yeedoy.com
              </a>{' '}
              adresine bildirme yapabilirsiniz. Tüm bildirimleri 5 iş günü içinde inceliyoruz.
            </p>
          </section>

        </div>

        <div className="mt-12 flex flex-wrap gap-4 border-t border-border pt-8">
          <Link href="/yasal" className="text-sm font-[700] text-primary hover:underline">Tüm Yasal Belgeler</Link>
          <Link href="/yasal/terms" className="text-sm font-[700] text-muted hover:text-primary">Kullanım Şartları</Link>
          <Link href="/yasal/privacy" className="text-sm font-[700] text-muted hover:text-primary">Gizlilik Politikası</Link>
        </div>
      </div>
    </main>
  );
}
