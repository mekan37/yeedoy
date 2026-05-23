import Image from 'next/image';
import type { ReactNode } from 'react';
import { buildMenuImageUrl } from '@/src/lib/medya-adresi';
import { Badge, Card, EmptyState, SectionHeader, Skeleton } from '@/src/ui/acik/ortak';
import { Icon } from '@/src/ui/acik/simgeler';
import type { AcikMenuUrunKarti } from '@/src/ui/acik/tipler';

export function PublicMenuLayout({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section className="mx-auto w-full max-w-6xl px-4 py-6 sm:px-6 lg:px-8">
      <SectionHeader title={title} subtitle="Kategoriler, ürünler, fiyatlar ve alerjen bilgileri public menü yüzeyinde okunur." className="mb-5" />
      {children}
    </section>
  );
}

export function MenuSectionTabs({ sections }: { sections: Array<{ id: string; title: string; href?: string; active?: boolean }> }) {
  return (
    <div className="flex gap-2 overflow-x-auto py-1 [-ms-overflow-style:none] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
      {sections.map((section) => (
        <a key={section.id} href={section.href ?? `#${section.id}`} className={section.active ? 'inline-flex min-h-11 shrink-0 items-center rounded-full border border-primary/30 bg-[var(--yd-color-primary-soft)] px-4 text-sm font-[900] text-primary' : 'inline-flex min-h-11 shrink-0 items-center rounded-full border border-border bg-card px-4 text-sm font-[900] text-textStrong hover:border-primary/25'}>
          {section.title}
        </a>
      ))}
    </div>
  );
}

export function MenuCategoryBlock({ title, items }: { title: string; items: AcikMenuUrunKarti[] }) {
  return (
    <section id={title.toLowerCase().replace(/\s+/g, '-')} className="scroll-mt-24">
      <SectionHeader title={title} subtitle={`${items.length} ürün`} className="mb-4" />
      {items.length > 0 ? (
        <div className="grid gap-3 md:grid-cols-2">
          {items.map((item) => <MenuItemCard key={item.id} item={item} />)}
        </div>
      ) : <EmptyMenuState />}
    </section>
  );
}

export function MenuItemCard({ item }: { item: AcikMenuUrunKarti }) {
  return (
    <Card className="flex gap-3 p-3">
      <MenuItemPhoto item={item} />
      <div className="min-w-0 flex-1">
        <div className="flex items-start justify-between gap-3">
          <div className="min-w-0">
            <h3 className="truncate font-[900] text-textStrong">{item.name}</h3>
            {item.description ? <p className="mt-1 line-clamp-2 text-sm leading-5 text-muted">{item.description}</p> : null}
          </div>
          <PriceBadge cents={item.priceCents} currency={item.currency} />
        </div>
        <div className="mt-3 flex flex-wrap gap-1.5">
          {!item.isAvailable ? <Badge tone="danger">Tükendi</Badge> : null}
          {item.tags?.slice(0, 3).map((tag) => <Badge key={tag}>{tag}</Badge>)}
          <AllergenBadges allergens={item.allergens ?? []} />
        </div>
      </div>
    </Card>
  );
}

export function MenuItemPhoto({ item }: { item: AcikMenuUrunKarti }) {
  const url = buildMenuImageUrl(item.imageUrl, { width: 220, quality: 78 });
  return (
    <div className="relative h-24 w-24 shrink-0 overflow-hidden rounded-[18px] bg-cardAlt">
      {url ? <Image src={url} alt={item.name} fill sizes="96px" className="object-cover" loading="lazy" /> : <div className="flex h-full items-center justify-center text-muted"><Icon name="image" /></div>}
    </div>
  );
}

export function PriceBadge({ cents, currency }: { cents: number; currency: string }) {
  return (
    <span className="shrink-0 rounded-full bg-[var(--yd-color-primary-soft)] px-3 py-1 text-sm font-[900] text-primary">
      {new Intl.NumberFormat('tr-TR', { style: 'currency', currency: currency || 'TRY' }).format(cents / 100)}
    </span>
  );
}

export function AllergenBadges({ allergens }: { allergens: string[] }) {
  if (allergens.length === 0) return null;
  return <>{allergens.slice(0, 3).map((allergen) => <Badge key={allergen} tone="warning">{allergen}</Badge>)}</>;
}

export function MenuItemSkeleton() {
  return (
    <Card className="flex gap-3 p-3">
      <Skeleton className="h-24 w-24 rounded-[18px]" />
      <div className="flex-1 space-y-3">
        <Skeleton className="h-5 w-2/3" />
        <Skeleton className="h-4 w-full" />
        <Skeleton className="h-7 w-20 rounded-full" />
      </div>
    </Card>
  );
}

export function EmptyMenuState() {
  return <EmptyState title="Menü öğesi bulunamadı" body="Bu kategori için yayınlanmış ürün yok veya filtre sonucu boş." />;
}
