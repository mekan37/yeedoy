import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinesses } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi } from '@/src/ui/yerlesim/panel-section-card';
import { ActivateMenuButton } from './menu-aktif-yap-dugmesi';
import { NewMenuButton } from './yeni-menu-dugmesi';

export const metadata: Metadata = {
  title: 'Menüler | Sahip Paneli',
  robots: { index: false, follow: false },
};

type BizMini = { id: string; name: string };
type MenuRow = { id: string; business_id: string; title: string; status: string; created_at: string };

export default async function OwnerMenusPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const businesses = await getOwnerBusinesses<BizMini>(supabase as any, user!.id, 'id, name');
  const businessIds = businesses.map((b) => b.id);
  const bizMap = Object.fromEntries(businesses.map((b) => [b.id, b.name]));

  const { data: menus } = businessIds.length > 0
    ? await (supabase as any)
        .from('menus')
        .select('id, business_id, title, status, created_at')
        .in('business_id', businessIds)
        .order('created_at', { ascending: false }) as { data: MenuRow[] | null }
    : { data: [] as MenuRow[] };

  const list = menus ?? [];

  // Bölüm + ürün sayıları
  const menuIds = list.map((m) => m.id);
  const sectionCounts: Record<string, number> = {};
  const itemCounts: Record<string, number> = {};

  if (menuIds.length > 0) {
    const { data: sections } = await (supabase as any)
      .from('menu_sections')
      .select('id, menu_id')
      .in('menu_id', menuIds) as { data: { id: string; menu_id: string }[] | null };

    for (const s of sections ?? []) {
      sectionCounts[s.menu_id] = (sectionCounts[s.menu_id] ?? 0) + 1;
    }

    const sectionIds = (sections ?? []).map((s) => s.id);
    if (sectionIds.length > 0) {
      const { data: items } = await (supabase as any)
        .from('menu_items')
        .select('id, section_id')
        .in('section_id', sectionIds) as { data: { id: string; section_id: string }[] | null };

      const sectionMenuMap: Record<string, string> = {};
      for (const s of sections ?? []) sectionMenuMap[s.id] = s.menu_id;
      for (const item of items ?? []) {
        const mid = sectionMenuMap[item.section_id];
        if (mid) itemCounts[mid] = (itemCounts[mid] ?? 0) + 1;
      }
    }
  }

  // Sıralama: aktif menü önce
  const sorted = [...list].sort((a, b) => {
    if (a.status === 'published' && b.status !== 'published') return -1;
    if (b.status === 'published' && a.status !== 'published') return 1;
    return 0;
  });

  const createdLabel = (iso: string) =>
    new Date(iso).toLocaleDateString('tr-TR', { day: 'numeric', month: 'short', year: 'numeric' });

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Owner"
        title="Menüler"
        description="İşletmelerinize ait menüler — tek seferde yalnızca bir menü aktif olabilir"
        actions={
          <div className="flex flex-wrap items-center gap-3">
            <NewMenuButton businesses={businesses} variant="button" />
            {list.length > 0 && (
              <div className="hidden items-center gap-2 rounded-xl border border-border bg-bg px-3 py-2 text-[11px] font-[700] text-muted sm:flex">
                <InfoIcon />
                Aktif menüyü değiştirmek için &ldquo;Aktif Yap&rdquo; butonuna tıklayın
              </div>
            )}
          </div>
        }
      />
      <PanelIcerikYuzeyi className="pt-6">
        {list.length === 0 && businesses.length === 0 ? (
          <div className="flex flex-col items-center justify-center rounded-2xl border border-dashed border-border bg-bg py-20 text-center">
            <div className="mb-4 flex h-16 w-16 items-center justify-center rounded-2xl bg-card">
              <MenuIcon />
            </div>
            <p className="text-base font-[800] text-textStrong">Henüz menü yok</p>
            <p className="mt-1 max-w-xs text-sm text-muted">Önce bir işletme eklemeniz gerekiyor.</p>
            <Link
              href="/sahip/isletmeler"
              className="btn-primary mt-6 flex h-10 items-center gap-2 rounded-xl px-5 text-sm font-[800] text-white transition hover:opacity-90"
            >
              İşletmelere Git
            </Link>
          </div>
        ) : (
          <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
            {sorted.map((menu) => {
              const isActive = menu.status === 'published';
              const bizName = bizMap[menu.business_id] ?? 'İşletme';
              const sections = sectionCounts[menu.id] ?? 0;
              const items = itemCounts[menu.id] ?? 0;

              return (
                <div
                  key={menu.id}
                  className={`overflow-hidden rounded-2xl border bg-card shadow-sm transition hover:shadow-md ${
                    isActive ? 'border-green-400 ring-2 ring-green-100' : 'border-border'
                  }`}
                >
                  {/* Üst şerit */}
                  <div className={`flex items-center justify-between px-5 py-4 ${
                    isActive
                      ? 'bg-gradient-to-r from-green-800 to-green-600'
                      : 'bg-gradient-to-r from-textStrong to-textStrong/70'
                  }`}>
                    <div className="flex min-w-0 items-center gap-3">
                      <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-white/10 text-white">
                        <MenuIcon />
                      </div>
                      <div className="min-w-0">
                        <p className="truncate text-sm font-[900] text-white">{menu.title}</p>
                        <p className="truncate text-[11px] font-[600] text-white/60">{bizName}</p>
                      </div>
                    </div>
                    {isActive && (
                      <span className="ml-2 flex shrink-0 items-center gap-1 rounded-full bg-white/20 px-2.5 py-1 text-[11px] font-[800] text-white backdrop-blur-sm">
                        <svg width="10" height="10" viewBox="0 0 24 24" fill="currentColor"><circle cx="12" cy="12" r="10" /></svg>
                        Aktif
                      </span>
                    )}
                  </div>

                  {/* İstatistikler */}
                  <div className="flex divide-x divide-border border-b border-border">
                    <div className="flex flex-1 flex-col items-center py-3">
                      <p className="text-xl font-[900] text-textStrong">{sections}</p>
                      <p className="text-[11px] font-[600] text-muted">Bölüm</p>
                    </div>
                    <div className="flex flex-1 flex-col items-center py-3">
                      <p className="text-xl font-[900] text-textStrong">{items}</p>
                      <p className="text-[11px] font-[600] text-muted">Ürün</p>
                    </div>
                    <div className="flex flex-1 flex-col items-center justify-center px-1 py-3">
                      <p className="text-center text-[11px] font-[800] leading-tight text-textStrong">{createdLabel(menu.created_at)}</p>
                      <p className="text-[11px] font-[600] text-muted">Oluşturuldu</p>
                    </div>
                  </div>

                  {/* Aksiyonlar */}
                  <div className="flex flex-col gap-2 p-4">
                    <ActivateMenuButton menuId={menu.id} businessId={menu.business_id} isActive={isActive} />
                    <div className="flex gap-2">
                      <Link
                        href={`/sahip/menuler/${menu.id}/duzenle`}
                        className="flex flex-1 items-center justify-center gap-1.5 rounded-xl border border-border py-2 text-xs font-[800] text-textStrong transition hover:bg-bg"
                      >
                        <EditIcon />
                        Düzenle
                      </Link>
                      <Link
                        href={`/sahip/menuler/${menu.id}`}
                        className="flex flex-1 items-center justify-center gap-1.5 rounded-xl border border-border py-2 text-xs font-[800] text-textStrong transition hover:bg-bg"
                      >
                        <EyeIcon />
                        Önizle
                      </Link>
                    </div>
                  </div>
                </div>
              );
            })}
            <NewMenuButton businesses={businesses} variant="card" />
          </div>
        )}
      </PanelIcerikYuzeyi>
    </div>
  );
}

function MenuIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
      <polyline points="14 2 14 8 20 8" />
      <line x1="16" y1="13" x2="8" y2="13" />
      <line x1="16" y1="17" x2="8" y2="17" />
    </svg>
  );
}

function EditIcon() {
  return (
    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" />
      <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z" />
    </svg>
  );
}

function EyeIcon() {
  return (
    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" />
      <circle cx="12" cy="12" r="3" />
    </svg>
  );
}

function InfoIcon() {
  return (
    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="10" /><line x1="12" y1="8" x2="12" y2="12" /><line x1="12" y1="16" x2="12.01" y2="16" />
    </svg>
  );
}
