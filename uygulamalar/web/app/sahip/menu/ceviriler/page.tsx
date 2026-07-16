import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinesses } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { OtomatikCeviriPanel } from './otomatik-ceviri-istemci';
import { CeviriEditor } from './ceviri-editor';
import { menuCevirileriniGetir } from './ceviri-islemleri';
import { DIL_ETIKETLERI, DESTEKLENEN_DILLER } from './ceviri-sabitleri';
import { CeviriSekmeleri } from './ceviri-sekmeleri';

export const metadata: Metadata = {
  title: 'Menü Çevirileri | Sahip Paneli',
  robots: { index: false, follow: false },
};

const LOCALE_LABELS: Record<string, string> = {
  tr: 'Türkçe',
  en: 'İngilizce',
  de: 'Almanca',
  ar: 'Arapça',
  fr: 'Fransızca',
};

const ENTITY_LABELS: Record<string, string> = {
  menu: 'Menü',
  section: 'Bölüm',
  menu_item: 'Ürün',
};

interface PageProps {
  searchParams: Promise<{ isletme?: string; menu?: string; sekme?: string }>;
}

export default async function OwnerMenuTranslationsPage({ searchParams }: PageProps) {
  const { isletme: isletmeId, menu: menuIdParam, sekme: sekmeParam } = await searchParams;
  const aktifSekmeBaslangic: 'otomatik' | 'manuel' = sekmeParam === 'manuel' ? 'manuel' : 'otomatik';

  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const businesses = user
    ? await getOwnerBusinesses<{ id: string; name: string }>(supabase as any, user.id, 'id, name')
    : [];

  const businessIds = businesses.map((b) => b.id);

  if (businessIds.length === 0) {
    return (
      <div className="flex flex-col">
        <PanelSayfaBasligi
          eyebrow="Owner"
          title="Menü Çevirileri"
          description="Menünüzün farklı dillerdeki çeviri yönetimi"
        />
        <PanelIcerikYuzeyi className="pt-6">
          <PanelEmptyState
            icon={<LanguageIcon />}
            title="Kayıtlı işletme bulunamadı"
            description="Menü çevirisi yönetebilmek için onaylı bir işletmeniz olması gerekiyor."
          />
        </PanelIcerikYuzeyi>
      </div>
    );
  }

  const { data: menus } = await (supabase as any)
    .from('menus')
    .select('id')
    .in('business_id', businessIds);

  const menuIds = ((menus ?? []) as any[]).map((m: any) => m.id);

  const { data: translations } = menuIds.length > 0
    ? await (supabase as any)
        .from('menu_translations')
        .select('id, entity_type, entity_id, locale, name, created_at')
        .in('entity_id', menuIds)
        .order('created_at', { ascending: false })
        .limit(200)
    : { data: [] };

  const list = (translations ?? []) as any[];

  // ── Manuel düzenleme sekmesi için veri ──────────────────────────────
  const secilenIsletme = businesses.find((b) => b.id === isletmeId) ?? businesses[0];
  const manuelSonuc = await menuCevirileriniGetir(secilenIsletme.id, menuIdParam);
  const manuelSatirlar = manuelSonuc.success ? manuelSonuc.satirlar : [];
  const manuelToplamAdet = manuelSonuc.success ? manuelSonuc.toplamAdet : 0;

  const ceviriIstatistikleri = manuelSonuc.success
    ? DESTEKLENEN_DILLER.map((locale) => {
        const tamamlanan = manuelSatirlar.filter((s) => s.translations[locale]?.name).length;
        return {
          locale,
          tamamlanan,
          toplam: manuelToplamAdet,
          oran: manuelToplamAdet > 0 ? Math.round((tamamlanan / manuelToplamAdet) * 100) : 0,
        };
      })
    : [];

  const otomatikIcerik = (
    <>
      <PanelBolumKarti title="Otomatik Çeviri (DeepL / OpenAI)">
        <OtomatikCeviriPanel menuIds={menuIds} />
      </PanelBolumKarti>

      {list.length === 0 ? (
        <PanelEmptyState
          icon={<LanguageIcon />}
          title="Çeviri bulunamadı"
          description="Yukarıdaki 'Otomatik Çeviri' bölümünden menünüzü otomatik olarak çevirebilirsiniz."
        />
      ) : (
        <PanelBolumKarti noPadding>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border">
                  <th className="px-5 py-3 text-left text-xs font-[800] uppercase tracking-wide text-muted">Tip</th>
                  <th className="px-5 py-3 text-left text-xs font-[800] uppercase tracking-wide text-muted">Dil</th>
                  <th className="px-5 py-3 text-left text-xs font-[800] uppercase tracking-wide text-muted">Çeviri Adı</th>
                  <th className="px-5 py-3 text-left text-xs font-[800] uppercase tracking-wide text-muted">Tarih</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {list.map((t: any) => (
                  <tr key={t.id}>
                    <td className="px-5 py-3">
                      <span className="rounded-full bg-zinc-100 px-2.5 py-0.5 text-[11px] font-[700] text-zinc-600">
                        {ENTITY_LABELS[t.entity_type] ?? t.entity_type}
                      </span>
                    </td>
                    <td className="px-5 py-3 font-[700] text-textStrong">
                      {LOCALE_LABELS[t.locale] ?? t.locale}
                    </td>
                    <td className="max-w-[260px] truncate px-5 py-3 text-textStrong">{t.name ?? '—'}</td>
                    <td className="px-5 py-3 text-muted">
                      {new Date(t.created_at).toLocaleDateString('tr-TR')}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </PanelBolumKarti>
      )}
    </>
  );

  const manuelIcerik = (
    <>
      {/* Üst bilgi: işletme seçici + istatistikler */}
      <div className="flex flex-wrap items-start gap-4">
        {businesses.length > 1 && (
          <div className="flex flex-col gap-1.5">
            <label className="text-xs font-[800] uppercase tracking-wide text-muted">
              İşletme
            </label>
            <form method="GET">
              {menuIdParam && <input type="hidden" name="menu" value={menuIdParam} />}
              <input type="hidden" name="sekme" value={aktifSekmeBaslangic} />
              <select
                name="isletme"
                defaultValue={secilenIsletme.id}
                onChange={(e) => (e.target.form as HTMLFormElement).submit()}
                className="min-h-11 rounded-xl border border-border bg-bg px-3 text-sm font-[700] text-textStrong outline-none focus:ring-2 focus:ring-primary/30"
              >
                {businesses.map((b) => (
                  <option key={b.id} value={b.id}>
                    {b.name}
                  </option>
                ))}
              </select>
            </form>
          </div>
        )}

        {ceviriIstatistikleri.length > 0 && manuelToplamAdet > 0 && (
          <div className="flex flex-wrap gap-3">
            {ceviriIstatistikleri.map(({ locale, tamamlanan, toplam, oran }) => (
              <div
                key={locale}
                className="flex min-w-[120px] flex-col gap-1 rounded-xl border border-border bg-card px-4 py-3"
              >
                <p className="text-xs font-[800] uppercase tracking-wide text-muted">
                  {DIL_ETIKETLERI[locale]}
                </p>
                <p className="text-[22px] font-[900] leading-none text-textStrong">{oran}%</p>
                <p className="text-xs text-muted">
                  {tamamlanan} / {toplam} ürün
                </p>
                <div className="mt-1 h-1.5 w-full overflow-hidden rounded-full bg-black/[0.06]">
                  <div
                    className="h-full rounded-full bg-primary transition-all duration-300"
                    style={{ width: `${oran}%` }}
                  />
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {!manuelSonuc.success && (
        <div className="rounded-xl border border-red-200 bg-red-50 px-5 py-4 text-sm font-[700] text-red-700">
          {manuelSonuc.hata}
        </div>
      )}

      {manuelSonuc.success && manuelSatirlar.length === 0 && (
        <PanelEmptyState
          icon={<LanguageIcon />}
          title="Menüde ürün bulunamadı"
          description="Çeviri ekleyebilmek için önce menüde ürün oluşturmanız gerekiyor."
        />
      )}

      {manuelSonuc.success && manuelSatirlar.length > 0 && (
        <CeviriEditor satirlar={manuelSatirlar} businessId={secilenIsletme.id} />
      )}
    </>
  );

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Owner"
        title="Menü Çevirileri"
        description="Otomatik çeviri veya manuel düzenleme ile menünüzü dillere kazandırın"
      />
      <PanelIcerikYuzeyi className="pt-6">
        <CeviriSekmeleri
          otomatikIcerik={otomatikIcerik}
          manuelIcerik={manuelIcerik}
          varsayilanSekme={aktifSekmeBaslangic}
        />
      </PanelIcerikYuzeyi>
    </div>
  );
}

function LanguageIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="10" />
      <line x1="2" y1="12" x2="22" y2="12" />
      <path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z" />
    </svg>
  );
}
