import type { Metadata } from 'next';
import Link from 'next/link';
import { PublicShell } from '@/src/ui/acik/yerlesim';
import { Container } from '@/src/ui/acik/ortak';
import { appConfig } from '@/src/lib/ayarlar';
import { createSupabasePublicClient } from '@/src/lib/taban/acik';

export const revalidate = 3600;

export const metadata: Metadata = {
  title: 'Türkiye Restoran Fiyat Endeksi | Yeedoy',
  description:
    'Yeedoy topluluğunun doğruladığı gerçek zamanlı restoran fiyat verileri. Kategori bazlı medyan fiyatlar, fiyat değişimleri ve bölgesel karşılaştırmalar.',
  alternates: { canonical: `${appConfig.siteUrl().replace(/\/$/, '')}/fiyat-endeksi` },
  openGraph: {
    title: 'Türkiye Restoran Fiyat Endeksi | Yeedoy',
    description: 'Gerçek zamanlı restoran fiyat verileri — Yeedoy topluluğu tarafından doğrulanmış.',
  },
};

type PriceRow = {
  category: string;
  median_price_cents: number;
  avg_price_cents: number;
  sample_count: number;
  updated_in_30d: number;
};

function formatTL(cents: number) {
  return `₺${(cents / 100).toLocaleString('tr-TR', { minimumFractionDigits: 0, maximumFractionDigits: 0 })}`;
}

export default async function FiyatEndeksiPage() {
  const supabase = createSupabasePublicClient();
  const siteUrl = appConfig.siteUrl().replace(/\/$/, '');

  const { data } = await (supabase as any).rpc('get_regional_price_index_v2', {
    p_city: null,
    p_district: null,
    p_limit: 20,
  }) as { data: PriceRow[] | null };

  const rows = (data ?? []).filter((r) => r.sample_count >= 3);

  const totalSamples = rows.reduce((s, r) => s + r.sample_count, 0);
  const totalUpdated = rows.reduce((s, r) => s + r.updated_in_30d, 0);
  const now = new Date();
  const ay = now.toLocaleDateString('tr-TR', { month: 'long', year: 'numeric' });

  const schema = {
    '@context': 'https://schema.org',
    '@type': 'Dataset',
    name: `Türkiye Restoran Fiyat Endeksi — ${ay}`,
    description: 'Yeedoy kullanıcıları tarafından doğrulanmış aylık restoran fiyat endeksi verisi.',
    url: `${siteUrl}/fiyat-endeksi`,
    publisher: { '@type': 'Organization', name: 'Yeedoy', url: siteUrl },
    temporalCoverage: `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`,
    spatialCoverage: { '@type': 'Place', name: 'Türkiye' },
  };

  return (
    <PublicShell>
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(schema) }} />
      <Container className="py-10">
        {/* Başlık */}
        <div className="mb-8">
          <p className="text-sm font-[700] text-primary uppercase tracking-widest mb-2">Yeedoy Veri</p>
          <h1 className="text-4xl font-[900] tracking-tight text-textStrong leading-tight">
            Türkiye Restoran<br />Fiyat Endeksi
          </h1>
          <p className="mt-3 text-muted max-w-xl">
            Yeedoy topluluğu tarafından doğrulanmış gerçek zamanlı fiyat verileri.
            Her ay güncellenir — medya ve araştırmacılar için serbestçe alıntılanabilir.
          </p>
          <p className="mt-2 text-xs text-muted">Güncelleme: {ay}</p>
        </div>

        {/* Özet istatistikler */}
        <div className="grid gap-4 sm:grid-cols-3 mb-8">
          {[
            { label: 'Fiyat Örneği', value: totalSamples.toLocaleString('tr-TR'), sub: 'doğrulanmış menü kalemi' },
            { label: '30 Günde Güncellenen', value: totalUpdated.toLocaleString('tr-TR'), sub: 'aktif fiyat kaydı' },
            { label: 'Kategori', value: rows.length.toString(), sub: 'yeterli veri olan' },
          ].map((s) => (
            <div key={s.label} className="rounded-2xl border border-border bg-card p-5">
              <p className="text-xs font-[700] text-muted uppercase tracking-wide">{s.label}</p>
              <p className="mt-1 text-3xl font-[900] text-textStrong">{s.value}</p>
              <p className="text-xs text-muted">{s.sub}</p>
            </div>
          ))}
        </div>

        {rows.length === 0 ? (
          /* Veri yok — erken aşama */
          <div className="rounded-2xl border border-border bg-card p-10 text-center">
            <p className="text-lg font-[800] text-textStrong">Veri biriktirilyor</p>
            <p className="mt-2 text-sm text-muted max-w-sm mx-auto">
              Yeedoy topluluğu menü fiyatlarını doğruladıkça bu endeks güncellenecek.
              Veriye katkı sağlamak için{' '}
              <Link href="/kesif" className="text-primary font-[700] hover:underline">
                bir işletme ziyaret et
              </Link>
              .
            </p>
          </div>
        ) : (
          /* Kategori fiyat tablosu */
          <section>
            <h2 className="mb-4 text-xl font-[900] text-textStrong">Kategoriye Göre Medyan Fiyat</h2>
            <div className="overflow-x-auto rounded-2xl border border-border bg-card">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-border text-left">
                    <th className="px-5 py-3.5 text-[11px] font-[800] uppercase tracking-wide text-muted">Kategori</th>
                    <th className="px-5 py-3.5 text-[11px] font-[800] uppercase tracking-wide text-muted text-right">Medyan</th>
                    <th className="px-5 py-3.5 text-[11px] font-[800] uppercase tracking-wide text-muted text-right">Ortalama</th>
                    <th className="px-5 py-3.5 text-[11px] font-[800] uppercase tracking-wide text-muted text-right">Örnek</th>
                    <th className="px-5 py-3.5 text-[11px] font-[800] uppercase tracking-wide text-muted text-right">30 Gün</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border">
                  {rows.map((row) => (
                    <tr key={row.category} className="hover:bg-border/20 transition-colors">
                      <td className="px-5 py-3.5 font-[700] text-textStrong">{row.category}</td>
                      <td className="px-5 py-3.5 text-right font-[900] text-textStrong">
                        {formatTL(row.median_price_cents)}
                      </td>
                      <td className="px-5 py-3.5 text-right text-muted">
                        {formatTL(row.avg_price_cents)}
                      </td>
                      <td className="px-5 py-3.5 text-right text-muted">
                        {row.sample_count.toLocaleString('tr-TR')}
                      </td>
                      <td className="px-5 py-3.5 text-right">
                        <span className={`rounded-full px-2 py-0.5 text-[10px] font-[800] ${
                          row.updated_in_30d > 0 ? 'bg-green-50 text-green-700' : 'bg-zinc-100 text-zinc-500'
                        }`}>
                          {row.updated_in_30d}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </section>
        )}

        {/* Medya atıf notu */}
        <div className="mt-8 rounded-2xl bg-primary/5 border border-primary/15 p-5">
          <p className="text-sm font-[800] text-textStrong mb-1">Medya ve Araştırmacılar İçin</p>
          <p className="text-sm text-muted">
            Bu veriler{' '}
            <strong className="text-textStrong">Yeedoy Restoran Fiyat Endeksi</strong>{' '}
            adıyla kaynak gösterilerek serbestçe kullanılabilir. Veri veya API erişimi için{' '}
            <a href="mailto:veri@yeedoy.com" className="text-primary font-[700] hover:underline">
              veri@yeedoy.com
            </a>{' '}
            adresine yazın.
          </p>
        </div>
      </Container>
    </PublicShell>
  );
}
