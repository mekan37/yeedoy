import Link from 'next/link';

export type MusteriOzet = {
  user_id: string;
  display_name: string;
  avatar_url: string | null;
  last_interaction_at: string;
  review_count: number;
  reservation_count: number;
  loyalty_progress: number | null;
  loyalty_reward_threshold: number | null;
  tags: { id: string; tag: string }[];
};

export function MusteriListesi({ musteriler }: { musteriler: MusteriOzet[] }) {
  if (musteriler.length === 0) {
    return <p className="text-sm text-muted">Henüz hiç müşteri etkileşimi yok.</p>;
  }

  return (
    <div className="overflow-x-auto">
      <table className="w-full text-sm">
        <thead>
          <tr className="border-b border-border text-left text-xs font-bold uppercase tracking-wide text-muted">
            <th className="py-2">Müşteri</th>
            <th className="py-2">Son Etkileşim</th>
            <th className="py-2">Yorum</th>
            <th className="py-2">Rezervasyon</th>
            <th className="py-2">Sadakat</th>
            <th className="py-2">Etiketler</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-border">
          {musteriler.map((m) => (
            <tr key={m.user_id}>
              <td className="py-2">
                <Link
                  href={`/sahip/musteriler/${m.user_id}`}
                  className="font-semibold text-textStrong hover:underline"
                >
                  {m.display_name}
                </Link>
              </td>
              <td className="py-2 text-muted">
                {new Date(m.last_interaction_at).toLocaleDateString('tr-TR')}
              </td>
              <td className="py-2 text-textStrong">{m.review_count}</td>
              <td className="py-2 text-textStrong">{m.reservation_count}</td>
              <td className="py-2 text-textStrong">{m.loyalty_progress ?? '—'}</td>
              <td className="py-2">
                <div className="flex flex-wrap gap-1">
                  {m.tags.map((t) => (
                    <span
                      key={t.id}
                      className="rounded-full bg-primary/10 px-2 py-0.5 text-xs font-bold text-primary"
                    >
                      {t.tag}
                    </span>
                  ))}
                </div>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
