import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

type Props = { params: Promise<{ businessId: string }> };

type BizRow = { id: string; name: string; slug: string; description: string | null; logo_url: string | null; category: string | null; city: string | null };
type MenuRow = { id: string; title: string; slug: string | null };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { businessId } = await params;
  const supabase = await createSupabaseServerClient();
  const { data } = await (supabase as any).from('businesses').select('name').eq('id', businessId).single() as { data: { name: string } | null };
  return {
    title: data ? `${data.name} | Yeedoy` : 'Yeedoy',
    robots: { index: false, follow: false },
  };
}

export const revalidate = 300;

export default async function EmbedViewerPage({ params }: Props) {
  const { businessId } = await params;
  const supabase = await createSupabaseServerClient();

  const { data: biz } = await (supabase as any)
    .from('businesses')
    .select('id, name, slug, description, logo_url, category, city')
    .eq('id', businessId)
    .single() as { data: BizRow | null };

  if (!biz) notFound();

  const { data: menus } = await (supabase as any)
    .from('menus')
    .select('id, title, slug')
    .eq('business_id', businessId)
    .eq('status', 'published')
    .limit(5) as { data: MenuRow[] | null };

  const publishedMenus = menus ?? [];

  return (
    <div
      className="p-4 max-w-sm font-sans"
      style={{ background: '#fff', minHeight: '100%' }}
    >
      {/* Business header */}
      <div className="flex items-center gap-3 mb-4">
        {biz.logo_url ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={biz.logo_url}
            alt={biz.name}
            className="h-12 w-12 rounded-xl object-cover border border-border shrink-0"
          />
        ) : (
          <div
            className="h-12 w-12 shrink-0 rounded-xl flex items-center justify-center text-white text-xl font-black"
            style={{ background: 'linear-gradient(135deg, #7f1d1d, #dc2626)' }}
          >
            {biz.name[0]}
          </div>
        )}
        <div>
          <p className="font-black text-textStrong text-sm">{biz.name}</p>
          {(biz.city || biz.category) && (
            <p className="text-xs text-muted mt-0.5">
              {[biz.city, biz.category].filter(Boolean).join(' · ')}
            </p>
          )}
        </div>
      </div>

      {biz.description && (
        <p className="text-xs text-muted leading-relaxed mb-4 line-clamp-2">{biz.description}</p>
      )}

      {publishedMenus.length > 0 ? (
        <div>
          <p className="text-[10px] font-extrabold uppercase tracking-widest text-muted mb-2">Menüler</p>
          <div className="flex flex-col gap-2">
            {publishedMenus.map((m) => (
              <a
                key={m.id}
                href={`/m/${m.slug ?? m.id}`}
                target="_blank"
                rel="noopener noreferrer"
                className="flex items-center justify-between rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong hover:border-primary/40 transition-colors no-underline"
              >
                {m.title}
                <span className="text-primary text-xs ml-2">→</span>
              </a>
            ))}
          </div>
        </div>
      ) : (
        <p className="text-xs text-muted">Aktif menü bulunamadı.</p>
      )}

      <div className="mt-4 pt-3 border-t border-border flex justify-end">
        <a
          href={`/isletme/${biz.slug}`}
          target="_blank"
          rel="noopener noreferrer"
          className="text-[10px] text-muted hover:text-primary transition-colors no-underline"
        >
          Yeedoy&apos;da gör →
        </a>
      </div>
    </div>
  );
}

