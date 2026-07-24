import Link from 'next/link';
import { Badge, Card, EmptyState, SectionHeader } from '@/src/ui/acik/ortak';
import { HelpfulVoteButton } from '@/src/ui/acik/eylem-istemcisi';
import { Icon } from '@/src/ui/acik/simgeler';
import type { AcikYorumKarti } from '@/src/ui/acik/tipler';

export function YorumlarBolumu({ reviews, businessSlug }: { reviews: AcikYorumKarti[]; businessSlug: string }) {
  return (
    <section>
      <div className="mb-4 flex items-center justify-between">
        <SectionHeader title="Yorumlar" subtitle={reviews.length > 0 ? 'Topluluk sinyali ve doğrulanmış ziyaretler' : undefined} />
        <Link href={`/isletme/${businessSlug}/yorumlar`} className="text-sm font-black text-primary hover:underline">Tümü</Link>
      </div>
      {reviews.length > 0 ? (
        <div className="grid gap-3">
          {reviews.map((review) => <YorumKarti key={review.id} review={review} />)}
        </div>
      ) : <BosYorumDurumu businessSlug={businessSlug} />}
    </section>
  );
}

export function YorumKarti({ review }: { review: AcikYorumKarti }) {
  return (
    <Card className="p-5">
      <div className="flex items-start justify-between gap-3">
        <div>
          <p className="font-black text-textStrong">{review.author}</p>
          <div className="mt-1 flex items-center gap-2">
            <span className="inline-flex items-center gap-1 text-sm font-black text-warning">
              <Icon name="star" size={14} />
              {review.rating.toFixed(1)}
            </span>
            {review.verifiedVisit ? <Badge tone="success">Doğrulanmış ziyaret</Badge> : null}
          </div>
        </div>
        <p className="text-xs font-extrabold text-muted">{new Date(review.createdAt).toLocaleDateString('tr-TR')}</p>
      </div>
      {review.content ? <p className="mt-4 text-sm leading-6 text-textStrong">&ldquo;{review.content}&rdquo;</p> : null}
      <div className="mt-4 flex flex-wrap gap-2">
        <HelpfulVoteButton reviewId={review.id} initialCount={review.helpfulCount ?? 0} />
        <YorumuRaporlaButonu />
      </div>
    </Card>
  );
}

export function YorumuRaporlaButonu() {
  return (
    <button type="button" className="inline-flex min-h-11 items-center rounded-2xl border border-border bg-card px-3 text-xs font-black text-muted hover:border-danger/30 hover:text-danger">
      Rapor et
    </button>
  );
}

export function BosYorumDurumu({ businessSlug }: { businessSlug: string }) {
  return (
    <EmptyState
      title="Henüz yorum yok"
      body="Bu işletme için ilk public yorumu yazanlardan biri olabilirsiniz."
      actionHref={`/isletme/${businessSlug}/yorumlar/new`}
      actionLabel="Yorum yaz"
    />
  );
}

