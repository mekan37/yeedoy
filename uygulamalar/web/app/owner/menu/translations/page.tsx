import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';

export const metadata: Metadata = {
  title: 'Menü Çevirileri | Owner Panel',
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

export default async function OwnerMenuTranslationsPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const { data: businesses } = await (supabase as any)
    .from('businesses')
    .select('id, name')
    .eq('owner_id', user!.id) as { data: Array<{ id: string; name: string }> | null };

  const businessIds = (businesses ?? []).map((b) => b.id);

  const { data: menus } = businessIds.length > 0
    ? await (supabase as any)
        .from('menus')
        .select('id')
        .in('business_id', businessIds)
    : { data: [] };

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

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Owner"
        title="Menü Çevirileri"
        description="Menünüzün farklı dillerdeki çeviri durumu"
      />
      <PanelContentSurface className="pt-6">
        {list.length === 0 ? (
          <PanelEmptyState
            icon={<LanguageIcon />}
            title="Çeviri bulunamadı"
            description="Menünüz için henüz çeviri eklenmemiş. Çoklu dil desteği yakında panelden yönetilebilecek."
          />
        ) : (
          <PanelSectionCard noPadding>
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
          </PanelSectionCard>
        )}
      </PanelContentSurface>
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
