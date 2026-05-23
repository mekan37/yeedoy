import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';

export const metadata: Metadata = {
  title: 'QR Tasarım Kiti | Owner Panel',
  robots: { index: false, follow: false },
};

export default async function OwnerQrPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const { data: businesses } = await (supabase as any)
    .from('businesses')
    .select('id, name, slug')
    .eq('owner_id', user!.id) as { data: Array<{ id: string; name: string; slug: string | null }> | null };

  const list = (businesses ?? []) as Array<{ id: string; name: string; slug: string | null }>;

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Owner"
        title="QR Tasarım Kiti"
        description="İşletmeleriniz için QR kodu indirin ve masalara yerleştirin"
      />
      <PanelContentSurface className="pt-6">
        {list.length === 0 ? (
          <PanelEmptyState
            icon={<QrIcon />}
            title="İşletme bulunamadı"
            description="QR kodu oluşturmak için önce bir işletme ekleyin."
          />
        ) : (
          <PanelSectionCard title="İşletmeleriniz" description="Her işletme için QR kodu aşağıda listelenmektedir">
            <ul className="divide-y divide-border -mx-5 -mb-5">
              {list.map((b) => (
                <li key={b.id} className="flex items-center justify-between gap-4 px-5 py-4">
                  <div>
                    <p className="text-sm font-[800] text-textStrong">{b.name}</p>
                    {b.slug && (
                      <p className="text-xs text-muted">yeedoy.com/m/{b.slug}</p>
                    )}
                  </div>
                  <span className="rounded-lg border border-border bg-zinc-50 px-3 py-1.5 text-xs font-[700] text-muted">
                    QR indirme yakında
                  </span>
                </li>
              ))}
            </ul>
          </PanelSectionCard>
        )}

        <div className="mt-4 rounded-xl border border-blue-100 bg-blue-50 p-4 text-sm text-blue-800">
          QR tasarım ve indirme özellikleri yakında aktif olacak. İşletme slug&apos;larınızın tanımlı olduğundan emin olun.
        </div>
      </PanelContentSurface>
    </div>
  );
}

function QrIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="3" width="7" height="7" />
      <rect x="14" y="3" width="7" height="7" />
      <rect x="3" y="14" width="7" height="7" />
      <path d="M14 14h.01M14 17h.01M17 14h.01M17 17h.01M20 14h.01M20 17h.01M20 20h.01" />
    </svg>
  );
}
