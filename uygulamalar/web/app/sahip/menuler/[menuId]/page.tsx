import type { Metadata } from 'next';
import Link from 'next/link';
import Image from 'next/image';
import { notFound, redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getMenuWithSections } from '@/src/lib/veri/owner/sahip-menuler';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { PanelActionButton } from '@/src/ui/bilesenler/panel-eylem-dugmesi';
import { SpesiyelToggle } from './spesiyel-toggle';

type Props = { params: Promise<{ menuId: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { menuId } = await params;
  const supabase = await createSupabaseServerClient();
  const { data } = await (supabase as any).from('menus').select('title').eq('id', menuId).single() as { data: { title: string } | null };
  return {
    title: data ? `${data.title} | Sahip Paneli` : 'Menü | Sahip Paneli',
    robots: { index: false, follow: false },
  };
}

function formatPrice(cents: number, currency: string) {
  return new Intl.NumberFormat('tr-TR', {
    style: 'currency',
    currency: currency || 'TRY',
    minimumFractionDigits: 2,
  }).format(cents / 100);
}

export default async function OwnerMenuDetailPage({ params }: Props) {
  const { menuId } = await params;
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    redirect(`/giris?redirect=${encodeURIComponent(`/sahip/menuler/${menuId}`)}`);
  }

  const detail = await getMenuWithSections(menuId, user.id);
  if (!detail) notFound();

  const { menu, business: biz, sections, items } = detail;

  const itemsBySection = ((items ?? []) as any[]).reduce<Record<string, any[]>>((acc, item) => {
    if (!acc[item.section_id]) acc[item.section_id] = [];
    acc[item.section_id].push(item);
    return acc;
  }, {});

  const today = new Date().toISOString().split('T')[0];

  const statusInfo = menu.status === 'published'
    ? { label: 'Yayında', className: 'bg-green-50 text-green-700' }
    : menu.status === 'archived'
      ? { label: 'Arşiv', className: 'bg-zinc-100 text-zinc-500' }
      : { label: 'Taslak', className: 'bg-amber-50 text-amber-700' };

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow={biz.name}
        title={menu.title}
        description={`${sections.length} bölüm · ${items.length} ürün`}
        actions={
          <div className="flex items-center gap-2">
            <span className={`rounded-full px-3 py-1 text-xs font-[800] ${statusInfo.className}`}>
              {statusInfo.label}
            </span>
            <a
              href={`/sunucu/sahip/menu-csv?menuId=${menuId}`}
              className="inline-flex items-center gap-1.5 rounded-xl border border-border bg-card px-3 py-1.5 text-xs font-[700] text-muted hover:border-primary hover:text-primary transition-colors"
            >
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" /><polyline points="7 10 12 15 17 10" /><line x1="12" y1="15" x2="12" y2="3" /></svg>
              CSV İndir
            </a>
            <Link href={`/karekod/${biz.id}`}>
              <PanelActionButton variant="secondary">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="3" width="7" height="7" /><rect x="14" y="3" width="7" height="7" /><rect x="3" y="14" width="7" height="7" /><rect x="14" y="14" width="3" height="3" /></svg>
                QR Studio
              </PanelActionButton>
            </Link>
            <Link href={`/sahip/menuler/${menuId}/duzenle`}>
              <PanelActionButton>Düzenle</PanelActionButton>
            </Link>
            <Link href="/sahip/menuler">
              <PanelActionButton variant="ghost">← Menüler</PanelActionButton>
            </Link>
          </div>
        }
      />
      <PanelIcerikYuzeyi className="pt-6">
        {sections.length === 0 ? (
          <PanelEmptyState
            icon={<SectionIcon />}
            title="Henüz bölüm eklenmedi"
            description="Bu menüde henüz bir bölüm bulunmuyor."
          />
        ) : (
          <div className="flex flex-col gap-4">
            {sections.map((section) => {
              const sectionItems = itemsBySection[section.id] ?? [];
              return (
                <PanelBolumKarti key={section.id} title={section.title} noPadding>
                  {sectionItems.length === 0 ? (
                    <p className="px-5 py-4 text-sm text-muted">Bu bölümde ürün yok.</p>
                  ) : (
                    <ul className="divide-y divide-border">
                      {sectionItems.map((item: any) => (
                        <li key={item.id} className="flex items-center gap-4 px-5 py-3">
                          {item.image_url && (
                            <Image
                              src={item.image_url}
                              alt={item.name}
                              width={40}
                              height={40}
                              className="h-10 w-10 shrink-0 rounded-lg object-cover"
                              unoptimized
                            />
                          )}
                          <div className="min-w-0 flex-1">
                            <div className="flex items-center gap-2">
                              <p className="truncate text-sm font-[800] text-textStrong">{item.name}</p>
                              {!item.is_available && (
                                <span className="rounded-full bg-zinc-100 px-2 py-0.5 text-[10px] font-[700] text-zinc-500">
                                  Mevcut Değil
                                </span>
                              )}
                              {item.is_today_special && item.special_date === today && (
                                <span className="rounded-full border border-amber-300 bg-amber-50 px-2 py-0.5 text-[10px] font-[800] text-amber-700">
                                  ⭐ Spesiyel
                                </span>
                              )}
                            </div>
                            {item.description && (
                              <p className="mt-0.5 line-clamp-1 text-xs text-muted">{item.description}</p>
                            )}
                          </div>
                          <div className="flex shrink-0 flex-col items-end gap-1">
                            <span className="text-sm font-[900] text-textStrong">
                              {formatPrice(item.price_cents, item.currency)}
                            </span>
                            <SpesiyelToggle
                              menuItemId={item.id}
                              itemName={item.name}
                              isSpecial={item.is_today_special && item.special_date === today}
                              specialNote={item.special_note ?? null}
                            />
                          </div>
                        </li>
                      ))}
                    </ul>
                  )}
                </PanelBolumKarti>
              );
            })}
          </div>
        )}
      </PanelIcerikYuzeyi>
    </div>
  );
}

function SectionIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <line x1="8" y1="6" x2="21" y2="6" /><line x1="8" y1="12" x2="21" y2="12" /><line x1="8" y1="18" x2="21" y2="18" />
      <line x1="3" y1="6" x2="3.01" y2="6" /><line x1="3" y1="12" x2="3.01" y2="12" /><line x1="3" y1="18" x2="3.01" y2="18" />
    </svg>
  );
}
