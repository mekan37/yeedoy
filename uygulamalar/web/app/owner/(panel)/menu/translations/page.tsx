import type { Metadata } from 'next';
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { getOwnerBusinesses } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';
import { menuCevirileriniGetir } from './ceviri-islemleri';
import { DIL_ETIKETLERI, DESTEKLENEN_DILLER } from './ceviri-sabitleri';
import { CeviriEditor } from './ceviri-editor';

export const metadata: Metadata = {
  title: 'Menü Çevirileri | Owner Panel',
  robots: { index: false, follow: false },
};

interface PageProps {
  searchParams: Promise<{ isletme?: string; menu?: string }>;
}

export default async function OwnerMenuTranslationsPage({ searchParams }: PageProps) {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) redirect('/giris');

  const { isletme: isletmeId, menu: menuIdParam } = await searchParams;

  // Owner'a ait işletmeler
  type BusinessRow = { id: string; name: string };
  const isletmeler = await getOwnerBusinesses<BusinessRow>(
    supabase as any,
    user.id,
    'id,name',
  );

  if (isletmeler.length === 0) {
    return (
      <div className="flex flex-col">
        <PanelPageHeader
          eyebrow="Owner"
          title="Menü Çevirileri"
          description="Menünüzün farklı dillerdeki çeviri yönetimi"
        />
        <PanelContentSurface className="pt-6">
          <PanelEmptyState
            icon={<LanguageIcon />}
            title="Kayıtlı işletme bulunamadı"
            description="Menü çevirisi yönetebilmek için onaylı bir işletmeniz olması gerekiyor."
          />
        </PanelContentSurface>
      </div>
    );
  }

  // Seçili işletme — URL param veya ilk işletme
  const secilenIsletme =
    isletmeler.find((b) => b.id === isletmeId) ?? isletmeler[0];

  // Çevirileri çek
  const sonuc = await menuCevirileriniGetir(
    secilenIsletme.id,
    menuIdParam,
  );

  const satirlar = sonuc.success ? sonuc.satirlar : [];
  const toplamAdet = sonuc.success ? sonuc.toplamAdet : 0;

  // Çeviri tamamlanma oranı
  const ceviriIstatistikleri = sonuc.success
    ? DESTEKLENEN_DILLER.map((locale) => {
        const tamamlanan = satirlar.filter(
          (s) => s.translations[locale]?.name,
        ).length;
        return {
          locale,
          tamamlanan,
          toplam: toplamAdet,
          oran: toplamAdet > 0 ? Math.round((tamamlanan / toplamAdet) * 100) : 0,
        };
      })
    : [];

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Owner"
        title="Menü Çevirileri"
        description={
          isletmeler.length > 1
            ? `${secilenIsletme.name} — ${toplamAdet} ürün`
            : `${toplamAdet} ürün için çeviri yönetimi`
        }
      />

      <PanelContentSurface className="pt-6">
        <div className="flex flex-col gap-6">
          {/* Üst bilgi: işletme seçici + istatistikler */}
          <div className="flex flex-wrap items-start gap-4">
            {/* Çoklu işletme varsa seçici */}
            {isletmeler.length > 1 && (
              <div className="flex flex-col gap-1.5">
                <label className="text-xs font-[800] uppercase tracking-wide text-muted">
                  İşletme
                </label>
                <form method="GET">
                  {menuIdParam && (
                    <input type="hidden" name="menu" value={menuIdParam} />
                  )}
                  <select
                    name="isletme"
                    defaultValue={secilenIsletme.id}
                    onChange={(e) => (e.target.form as HTMLFormElement).submit()}
                    className="rounded-xl border border-border bg-card px-3 py-2 text-sm font-[700] text-textStrong focus:border-[#7f1d1d] focus:outline-none focus:ring-1 focus:ring-[#7f1d1d]/30"
                  >
                    {isletmeler.map((b) => (
                      <option key={b.id} value={b.id}>
                        {b.name}
                      </option>
                    ))}
                  </select>
                </form>
              </div>
            )}

            {/* Dil istatistikleri */}
            {ceviriIstatistikleri.length > 0 && toplamAdet > 0 && (
              <div className="flex flex-wrap gap-3">
                {ceviriIstatistikleri.map(({ locale, tamamlanan, toplam, oran }) => (
                  <div
                    key={locale}
                    className="flex flex-col gap-1 rounded-xl border border-border bg-card px-4 py-3 min-w-[120px]"
                  >
                    <p className="text-xs font-[800] uppercase tracking-wide text-muted">
                      {DIL_ETIKETLERI[locale]}
                    </p>
                    <p className="text-[22px] font-[900] text-textStrong leading-none">
                      {oran}%
                    </p>
                    <p className="text-xs text-muted">
                      {tamamlanan} / {toplam} ürün
                    </p>
                    {/* İlerleme çubuğu */}
                    <div className="mt-1 h-1.5 w-full overflow-hidden rounded-full bg-black/[0.06]">
                      <div
                        className="h-full rounded-full bg-[#7f1d1d] transition-all duration-300"
                        style={{ width: `${oran}%` }}
                      />
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Hata durumu */}
          {!sonuc.success && (
            <div className="rounded-xl border border-red-200 bg-red-50 px-5 py-4 text-sm font-[700] text-red-700">
              {sonuc.hata}
            </div>
          )}

          {/* Boş durum */}
          {sonuc.success && satirlar.length === 0 && (
            <PanelEmptyState
              icon={<LanguageIcon />}
              title="Menüde ürün bulunamadı"
              description="Çeviri ekleyebilmek için önce menüde ürün oluşturmanız gerekiyor."
            />
          )}

          {/* Ana editor */}
          {sonuc.success && satirlar.length > 0 && (
            <CeviriEditor
              satirlar={satirlar}
              businessId={secilenIsletme.id}
            />
          )}
        </div>
      </PanelContentSurface>
    </div>
  );
}

function LanguageIcon() {
  return (
    <svg
      width="20"
      height="20"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <circle cx="12" cy="12" r="10" />
      <line x1="2" y1="12" x2="22" y2="12" />
      <path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z" />
    </svg>
  );
}
