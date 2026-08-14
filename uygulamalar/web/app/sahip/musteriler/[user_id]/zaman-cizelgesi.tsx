export type ZamanCizelgesiOlayi = {
  event_type: 'review' | 'reservation' | 'loyalty_scan' | 'loyalty_redeem' | 'follow' | 'note';
  occurred_at: string;
  summary: string;
  branch_label: string | null;
};

const OLAY_ETIKETLERI: Record<ZamanCizelgesiOlayi['event_type'], string> = {
  review: '⭐ Yorum yaptı',
  reservation: '📅 Rezervasyon',
  loyalty_scan: '🎁 Sadakat',
  loyalty_redeem: '🎁 Ödül',
  follow: '❤️ Takip',
  note: '📝 Not',
};

export function ZamanCizelgesi({
  olaylar,
  subeEtiketiGoster = false,
}: {
  olaylar: ZamanCizelgesiOlayi[];
  subeEtiketiGoster?: boolean;
}) {
  if (olaylar.length === 0) {
    return <p className="text-sm text-muted">Henüz kayıtlı bir etkileşim yok.</p>;
  }

  return (
    <ul className="flex flex-col gap-3">
      {olaylar.map((o, i) => (
        <li key={i} className="rounded-xl border border-border bg-card p-3">
          <p className="text-xs font-bold uppercase tracking-wide text-muted">
            {OLAY_ETIKETLERI[o.event_type]} — {new Date(o.occurred_at).toLocaleDateString('tr-TR')}
            {subeEtiketiGoster && o.branch_label && (
              <span className="ml-2 rounded-full bg-primary/10 px-2 py-0.5 text-[10px] font-bold normal-case tracking-normal text-primary">
                {o.branch_label}
              </span>
            )}
          </p>
          <p className="mt-1 text-sm text-textStrong">{o.summary}</p>
        </li>
      ))}
    </ul>
  );
}
