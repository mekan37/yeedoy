export type ZamanCizelgesiOlayi = {
  event_type: 'review' | 'reservation' | 'loyalty_scan' | 'loyalty_redeem' | 'follow' | 'note';
  occurred_at: string;
  summary: string;
};

const OLAY_ETIKETLERI: Record<ZamanCizelgesiOlayi['event_type'], string> = {
  review: '⭐ Yorum yaptı',
  reservation: '📅 Rezervasyon',
  loyalty_scan: '🎁 Sadakat',
  loyalty_redeem: '🎁 Ödül',
  follow: '❤️ Takip',
  note: '📝 Not',
};

export function ZamanCizelgesi({ olaylar }: { olaylar: ZamanCizelgesiOlayi[] }) {
  if (olaylar.length === 0) {
    return <p className="text-sm text-muted">Henüz kayıtlı bir etkileşim yok.</p>;
  }

  return (
    <ul className="flex flex-col gap-3">
      {olaylar.map((o, i) => (
        <li key={i} className="rounded-xl border border-border bg-card p-3">
          <p className="text-xs font-bold uppercase tracking-wide text-muted">
            {OLAY_ETIKETLERI[o.event_type]} — {new Date(o.occurred_at).toLocaleDateString('tr-TR')}
          </p>
          <p className="mt-1 text-sm text-textStrong">{o.summary}</p>
        </li>
      ))}
    </ul>
  );
}
