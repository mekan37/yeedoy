import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';

export const metadata: Metadata = {
  title: 'Yorumlar | Owner Panel',
  robots: { index: false, follow: false },
};

export default async function OwnerReviewsPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const { data: businesses } = await (supabase as any)
    .from('businesses')
    .select('id, name')
    .eq('owner_id', user!.id) as { data: Array<{ id: string; name: string }> | null };

  const businessIds = (businesses ?? []).map((b) => b.id);
  const businessMap = Object.fromEntries((businesses ?? []).map((b) => [b.id, b.name]));

  const { data: reviews } = businessIds.length > 0
    ? await (supabase as any)
        .from('business_reviews')
        .select('id, business_id, rating, content, created_at, is_visible, user_profiles(display_name)')
        .in('business_id', businessIds)
        .order('created_at', { ascending: false })
        .limit(50)
    : { data: [] };

  const list = (reviews ?? []) as any[];

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Owner"
        title="Yorumlar"
        description={`${list.length} yorum`}
      />
      <PanelContentSurface className="pt-6">
        {list.length === 0 ? (
          <PanelEmptyState
            icon={<StarIcon />}
            title="Henüz yorum yok"
            description="İşletmenize yapılan yorumlar burada görünür."
          />
        ) : (
          <PanelSectionCard noPadding>
            <ul className="divide-y divide-border">
              {list.map((r: any) => (
                <li key={r.id} className="px-5 py-4">
                  <div className="flex items-start justify-between gap-4">
                    <div className="min-w-0 flex-1">
                      <div className="flex items-center gap-2">
                        <StarRating rating={r.rating} />
                        <span className="text-xs font-[700] text-textStrong">
                          {r.user_profiles?.display_name ?? 'Anonim'}
                        </span>
                        {businessIds.length > 1 && (
                          <span className="text-xs text-muted">· {businessMap[r.business_id]}</span>
                        )}
                      </div>
                      {r.content && (
                        <p className="mt-1.5 text-sm leading-relaxed text-text">{r.content}</p>
                      )}
                    </div>
                    <div className="shrink-0 text-right">
                      <p className="text-xs text-muted">
                        {new Date(r.created_at).toLocaleDateString('tr-TR')}
                      </p>
                      {r.is_visible === false && (
                        <span className="mt-1 inline-block rounded-full bg-zinc-100 px-2 py-0.5 text-[11px] font-[700] text-zinc-500">
                          Gizli
                        </span>
                      )}
                    </div>
                  </div>
                </li>
              ))}
            </ul>
          </PanelSectionCard>
        )}
      </PanelContentSurface>
    </div>
  );
}

function StarRating({ rating }: { rating: number }) {
  return (
    <div className="flex items-center gap-0.5">
      {[1, 2, 3, 4, 5].map((n) => (
        <svg
          key={n}
          width="12"
          height="12"
          viewBox="0 0 24 24"
          fill={n <= rating ? 'currentColor' : 'none'}
          stroke="currentColor"
          strokeWidth="2"
          className={n <= rating ? 'text-amber-400' : 'text-zinc-300'}
        >
          <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
        </svg>
      ))}
    </div>
  );
}

function StarIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
    </svg>
  );
}
