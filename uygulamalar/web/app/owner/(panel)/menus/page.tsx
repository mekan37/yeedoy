import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { getOwnerMenus } from '@/src/lib/veri/owner/sahip-menuler';
import { getOwnerBusinesses } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { ActivateMenuButton } from './_components/activate-menu-button';
import { NewMenuButton } from './_components/new-menu-button';

export const metadata: Metadata = {
  title: 'Menüler | Owner Panel',
  robots: { index: false, follow: false },
};

type BizMini = { id: string; name: string };

export default async function OwnerMenusPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return null;

  const [menus, businesses] = await Promise.all([
    getOwnerMenus(user.id),
    getOwnerBusinesses<BizMini>(supabase as any, user.id, 'id, name'),
  ]);

  const bizMap = Object.fromEntries(businesses.map((b) => [b.id, b.name]));

  // Section + item counts
  const menuIds = menus.map((m) => m.id);
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

  // Sort: active menu first within each business group
  const sorted = [...menus].sort((a, b) => {
    if (a.status === 'published' && b.status !== 'published') return -1;
    if (b.status === 'published' && a.status !== 'published') return 1;
    return 0;
  });

  const createdLabel = (iso: string) =>
    new Date(iso).toLocaleDateString('tr-TR', { day: 'numeric', month: 'short', year: 'numeric' });

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Owner"
        title="Menüler"
        description="İşletmelerinize ait menüler — tek seferde yalnızca bir menü aktif olabilir"
        actions={
          <div className="flex flex-wrap items-center gap-3">
            <NewMenuButton businesses={businesses} variant="button" />
            {menus.length > 0 && (
              <div className="hidden sm:flex items-center gap-2 rounded-xl border border-[#f0f0f0] bg-[#fafafa] px-3 py-2 text-[11px] font-[700] text-[#94a3b8]">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <circle cx="12" cy="12" r="10" /><line x1="12" y1="8" x2="12" y2="12" /><line x1="12" y1="16" x2="12.01" y2="16" />
                </svg>
                Aktif menüyü değiştirmek için &ldquo;Aktif Yap&rdquo; butonuna tıklayın
              </div>
            )}
          </div>
        }
      />

      <div className="px-6 pb-8 pt-2">
        {menus.length === 0 && businesses.length === 0 ? (
          /* İşletme de yok */
          <div className="flex flex-col items-center justify-center rounded-2xl border border-dashed border-[#e5e7eb] bg-[#fafafa] py-20 text-center">
            <div className="mb-4 flex h-16 w-16 items-center justify-center rounded-2xl bg-[#f3f4f6]">
              <MenuEmptyIcon />
            </div>
            <p className="text-base font-[800] text-[#1a1a2e]">Henüz menü yok</p>
            <p className="mt-1 max-w-xs text-sm text-[#94a3b8]">
              Önce bir işletme eklemeniz gerekiyor.
            </p>
            <Link
              href="/owner/businesses"
              className="mt-6 flex h-10 items-center gap-2 rounded-xl bg-[#dc2626] px-5 text-sm font-[800] text-white shadow-[0_2px_6px_rgba(220,38,38,0.25)] transition hover:bg-[#b91c1c]"
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
                  className={`overflow-hidden rounded-2xl border bg-white shadow-[0_1px_3px_rgba(0,0,0,0.04)] transition hover:shadow-[0_4px_16px_rgba(0,0,0,0.08)] ${
                    isActive
                      ? 'border-green-400 ring-2 ring-green-100'
                      : 'border-[#f0f0f0]'
                  }`}
                >
                  {/* Top band */}
                  <div className={`flex items-center justify-between px-5 py-4 ${
                    isActive
                      ? 'bg-gradient-to-r from-[#14532d] to-[#16a34a]'
                      : 'bg-gradient-to-r from-[#1a1a2e] to-[#2d2d44]'
                  }`}>
                    <div className="flex items-center gap-3 min-w-0">
                      <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-white/10 text-white">
                        <MenuIcon />
                      </div>
                      <div className="min-w-0">
                        <p className="truncate text-[14px] font-[900] text-white">{menu.title}</p>
                        <p className="text-[11px] text-white/60 font-[600]">{bizName}</p>
                      </div>
                    </div>
                    {isActive && (
                      <span className="ml-2 shrink-0 flex items-center gap-1 rounded-full bg-white/20 px-2.5 py-1 text-[11px] font-[800] text-white backdrop-blur-sm">
                        <svg width="10" height="10" viewBox="0 0 24 24" fill="currentColor">
                          <circle cx="12" cy="12" r="10" />
                        </svg>
                        Aktif
                      </span>
                    )}
                  </div>

                  {/* Stats */}
                  <div className="flex divide-x divide-[#f0f0f0] border-b border-[#f0f0f0]">
                    <div className="flex flex-1 flex-col items-center py-3">
                      <p className="text-[20px] font-[900] text-[#1a1a2e]">{sections}</p>
                      <p className="text-[11px] font-[600] text-[#94a3b8]">Bölüm</p>
                    </div>
                    <div className="flex flex-1 flex-col items-center py-3">
                      <p className="text-[20px] font-[900] text-[#1a1a2e]">{items}</p>
                      <p className="text-[11px] font-[600] text-[#94a3b8]">Ürün</p>
                    </div>
                    <div className="flex flex-1 flex-col items-center justify-center py-3 px-1">
                      <p className="text-[11px] font-[800] text-[#475569] text-center leading-tight">{createdLabel(menu.created_at)}</p>
                      <p className="text-[11px] font-[600] text-[#94a3b8]">Oluşturuldu</p>
                    </div>
                  </div>

                  {/* Actions */}
                  <div className="flex flex-col gap-2 p-4">
                    {/* Activate toggle */}
                    <ActivateMenuButton
                      menuId={menu.id}
                      businessId={menu.business_id}
                      isActive={isActive}
                    />

                    {/* Edit / Preview row */}
                    <div className="flex gap-2">
                      <Link
                        href={`/owner/menus/${menu.id}/edit`}
                        className="flex flex-1 items-center justify-center gap-1.5 rounded-xl border border-[#e2e8f0] py-2 text-[12px] font-[800] text-[#475569] transition hover:bg-[#f8fafc]"
                      >
                        <EditIcon />
                        Düzenle
                      </Link>
                      <Link
                        href={`/owner/menus/${menu.id}`}
                        className="flex flex-1 items-center justify-center gap-1.5 rounded-xl border border-[#e2e8f0] py-2 text-[12px] font-[800] text-[#475569] transition hover:bg-[#f8fafc]"
                      >
                        <EyeIcon />
                        Önizle
                      </Link>
                    </div>
                  </div>
                </div>
              );
            })}
            {/* Grid sonunda "Yeni Menü Ekle" kartı */}
            <NewMenuButton businesses={businesses} variant="card" />
          </div>
        )}
      </div>
    </div>
  );
}

function MenuEmptyIcon() {
  return (
    <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
      <polyline points="14 2 14 8 20 8" />
      <line x1="16" y1="13" x2="8" y2="13" />
      <line x1="16" y1="17" x2="8" y2="17" />
    </svg>
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
