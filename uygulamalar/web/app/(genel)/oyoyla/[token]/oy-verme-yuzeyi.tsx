'use client';

import { useState } from 'react';
import Link from 'next/link';
import { clsx } from 'clsx';
import { Trophy } from 'lucide-react';

interface OyItem {
  id: string;
  businessId: string;
  businessName: string;
  businessSlug: string;
  category: string | null;
  location: string;
  upVotes: number;
  downVotes: number;
}

interface OyVermeYuzeyiProps {
  listId: string;
  token: string;
  items: OyItem[];
}

export function OyVermeYuzeyi({ listId, token, items: initial }: OyVermeYuzeyiProps) {
  const [items, setItems] = useState<OyItem[]>(initial);
  const [myVotes, setMyVotes] = useState<Record<string, 1 | -1>>({});
  const [loading, setLoading] = useState<string | null>(null);

  const sorted = [...items].sort((a, b) => (b.upVotes - b.downVotes) - (a.upVotes - a.downVotes));
  const winner = sorted[0] && (sorted[0].upVotes - sorted[0].downVotes) > 0 ? sorted[0] : null;

  async function castVote(itemId: string, vote: 1 | -1) {
    if (loading) return;
    const prev = myVotes[itemId];
    const newVote = prev === vote ? null : vote; // toggle

    // Optimistic update
    setItems((arr) => arr.map((it) => {
      if (it.id !== itemId) return it;
      let up = it.upVotes;
      let down = it.downVotes;
      if (prev === 1) up--;
      if (prev === -1) down--;
      if (newVote === 1) up++;
      if (newVote === -1) down++;
      return { ...it, upVotes: up, downVotes: down };
    }));
    setMyVotes((m) => {
      if (newVote === null) { const n = { ...m }; delete n[itemId]; return n; }
      return { ...m, [itemId]: newVote };
    });

    setLoading(itemId);
    try {
      await fetch('/sunucu/ortak-liste/oy', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ listId, itemId, vote: newVote ?? 0 }),
      });
    } finally {
      setLoading(null);
    }
  }

  return (
    <div className="flex flex-col gap-4">
      {winner && (
        <div className="rounded-2xl border border-success/30 bg-success/6 px-4 py-3 text-center">
          <p className="text-xs font-extrabold uppercase tracking-wide text-success">Şu anki önde gelen</p>
          <p className="mt-1 text-lg font-black text-textStrong">{winner.businessName}</p>
          <p className="text-xs text-muted">{winner.upVotes} evet · {winner.downVotes} hayır</p>
        </div>
      )}

      {sorted.map((item, idx) => {
        const score = item.upVotes - item.downVotes;
        const myVote = myVotes[item.id];
        return (
          <div key={item.id} className="rounded-2xl border border-border bg-card p-4">
            <div className="flex items-start justify-between gap-3">
              <div className="flex-1">
                <div className="flex items-center gap-2">
                  {idx === 0 && score > 0 && <Trophy className="h-4 w-4 shrink-0 text-warning" aria-hidden="true" />}
                  <h3 className="font-black text-textStrong">{item.businessName}</h3>
                </div>
                {(item.category || item.location) && (
                  <p className="mt-0.5 text-sm text-muted">
                    {[item.category, item.location].filter(Boolean).join(' · ')}
                  </p>
                )}
                <Link
                  href={`/m/${item.businessSlug}`}
                  target="_blank"
                  className="mt-1 inline-block text-xs font-bold text-primary hover:underline"
                >
                  Menüye bak →
                </Link>
              </div>

              {/* Oy sayısı */}
              <div className="shrink-0 text-center">
                <p className={clsx(
                  'text-xl font-black',
                  score > 0 ? 'text-success' : score < 0 ? 'text-danger' : 'text-muted',
                )}>
                  {score > 0 ? '+' : ''}{score}
                </p>
                <p className="text-[10px] text-muted">{item.upVotes}✓ {item.downVotes}✗</p>
              </div>
            </div>

            {/* Oy butonları */}
            <div className="mt-3 flex gap-2">
              <button
                onClick={() => castVote(item.id, 1)}
                disabled={loading === item.id}
                className={clsx(
                  'flex flex-1 items-center justify-center gap-1.5 rounded-xl border py-2.5 text-sm font-extrabold transition-all',
                  myVote === 1
                    ? 'border-success/30 bg-success/12 text-success'
                    : 'border-border bg-cardAlt text-muted hover:border-success/30 hover:text-success',
                )}
              >
                👍 Evet
              </button>
              <button
                onClick={() => castVote(item.id, -1)}
                disabled={loading === item.id}
                className={clsx(
                  'flex flex-1 items-center justify-center gap-1.5 rounded-xl border py-2.5 text-sm font-extrabold transition-all',
                  myVote === -1
                    ? 'border-danger/30 bg-danger/10 text-danger'
                    : 'border-border bg-cardAlt text-muted hover:border-danger/30 hover:text-danger',
                )}
              >
                👎 Hayır
              </button>
            </div>
          </div>
        );
      })}

      <p className="text-center text-xs text-muted">
        Oylar anonim — hesap gerekmez.
        <br />
        Bağlantıyı arkadaşlarınla paylaş: /oyoyla/{token}
      </p>
    </div>
  );
}
