'use client';

import { useEffect, useState } from 'react';
import { YorumSatiri } from './yorum-satiri';

const LS_KEY = 'sahip_yorumlar_son_gorulme';

export interface YorumSatiriVeri {
  id: string;
  businessId: string;
  rating: number;
  title: string | null;
  content: string | null;
  helpfulCount: number;
  status: string;
  createdAt: string;
  displayName: string | null;
  ownerReply: string | null;
  ownerRepliedAt: string | null;
}

interface Props {
  reviews: YorumSatiriVeri[];
  businessMap: Record<string, string>;
  showBusinessName: boolean;
}

export function YorumlarIstemcisi({ reviews, businessMap, showBusinessName }: Props) {
  // lastSeenAt: önceki ziyarette localStorage'a yazılan timestamp.
  // Sayfadan çıkıldığında güncellenir → bir sonraki girişte "Yeni" rozeti sıfırlanır.
  const [lastSeenAt, setLastSeenAt] = useState<number>(0);

  useEffect(() => {
    const stored = localStorage.getItem(LS_KEY);
    if (stored) setLastSeenAt(parseInt(stored, 10));

    // Unmount = kullanıcı sayfadan çıktı → şimdiki zamanı kaydet
    return () => {
      localStorage.setItem(LS_KEY, Date.now().toString());
    };
  }, []);

  return (
    <ul className="divide-y divide-border">
      {reviews.map((r) => (
        <YorumSatiri
          key={r.id}
          reviewId={r.id}
          businessName={showBusinessName ? (businessMap[r.businessId] ?? '') : ''}
          rating={r.rating}
          title={r.title}
          content={r.content}
          displayName={r.displayName}
          createdAt={r.createdAt}
          isVisible={r.status === 'approved'}
          status={r.status}
          helpfulCount={r.helpfulCount}
          isNew={lastSeenAt > 0 && new Date(r.createdAt).getTime() > lastSeenAt}
          ownerReply={r.ownerReply}
          ownerRepliedAt={r.ownerRepliedAt}
        />
      ))}
    </ul>
  );
}
