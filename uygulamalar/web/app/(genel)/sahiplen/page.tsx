import type { Metadata } from 'next';
import Link from 'next/link';
import { PublicShell } from '@/src/ui/acik/yerlesim';
import { Container, ButtonLink, Card, SectionHeader, Badge } from '@/src/ui/acik/ortak';
import { Icon } from '@/src/ui/acik/simgeler';
import { appConfig } from '@/src/lib/ayarlar';

type ClaimPageProps = {
  searchParams: Promise<{ business?: string }>;
};

export function generateMetadata(): Metadata {
  const siteUrl = appConfig.siteUrl().replace(/\/$/, '');
  return {
    title: 'İşletmeni Sahiplen | Yeedoy',
    description: 'İşletmeni Yeedoy\'da sahiplen, menünü ve işletme bilgilerini kendi panelinden güncel tut.',
    alternates: { canonical: `${siteUrl}/sahiplen` },
    robots: { index: true, follow: true },
  };
}

export default async function ClaimPage({ searchParams }: ClaimPageProps) {
  const params = await searchParams;
  const business = params.business?.trim();
  const panelHref = business ? `/giris?redirect=${encodeURIComponent(`/sahip/baslangic?business=${business}`)}` : '/giris';

  return (
    <PublicShell variant="owner">
      <main>
        <section className="border-b border-border bg-cardAlt py-12">
          <Container className="grid gap-8 lg:grid-cols-[1fr_360px] lg:items-center">
            <div>
              <p className="yd-eyebrow">Sahiplenme</p>
              <h1 className="mt-3 max-w-3xl text-4xl font-black leading-tight text-textStrong sm:text-5xl">İşletme sayfanı sahiplen, yönetimi panelde tut.</h1>
              <p className="mt-5 max-w-2xl text-base leading-7 text-muted">İşletmeni doğrula, menünü güncel tut ve müşteri yorumlarına panelden yanıt ver.</p>
              <div className="mt-7 flex flex-wrap gap-2">
                <ButtonLink href={panelHref}>Panele devam et</ButtonLink>
                <ButtonLink href="/kesif" variant="secondary">İşletmeni bul</ButtonLink>
              </div>
            </div>
            <Card className="p-5">
              <Badge tone="success"><Icon name="check" size={13} /> Ücretsiz ve hızlı</Badge>
              <div className="mt-5 grid gap-4">
                {['İşletme doğrulaması', 'QR ve marka ayarları', 'Menü yönetimi', 'Yönetici incelemesi'].map((item) => (
                  <div key={item} className="flex items-center gap-3 rounded-2xl bg-cardAlt px-3 py-3 text-sm font-black text-textStrong">
                    <Icon name="check" size={16} className="text-success" />
                    {item}
                  </div>
                ))}
              </div>
            </Card>
          </Container>
        </section>
        <Container className="grid gap-5 py-10 md:grid-cols-3">
          <Card className="p-5">
            <SectionHeader title="1. İşletmeni bul" subtitle="Yeedoy keşif veya arama üzerinden işletmenin sayfasına ulaş." />
          </Card>
          <Card className="p-5">
            <SectionHeader title="2. Sahiplenme talebi aç" subtitle="Kimliğini ve işletmenle bağlantını doğrula." />
          </Card>
          <Card className="p-5">
            <SectionHeader title="3. Panelden yönet" subtitle="Menünü güncelle, fiyatları düzenle, işletme bilgilerini yönet." />
          </Card>
        </Container>
        <Container className="pb-10 text-sm text-muted">
          <Link href="/giris" className="font-black text-primary hover:underline">Mevcut hesabınla giriş yap</Link>
        </Container>
      </main>
    </PublicShell>
  );
}

