export type KampanyaOzet = {
  id: string;
  subject: string;
  target_segment: string;
  sent_at: string | null;
  sent_count: number;
  created_at: string;
};

function segmentEtiketi(segment: string): string {
  if (segment.startsWith('tag:')) return `Etiket: ${segment.slice(4)}`;
  if (segment === 'all_followers') return 'Tüm takipçiler';
  if (segment === 'new_30d') return 'Son 30 gün yeni takipçiler';
  if (segment === 'inactive_30d') return '30+ gündür pasif takipçiler';
  return segment;
}

export function KampanyaListesi({ kampanyalar }: { kampanyalar: KampanyaOzet[] }) {
  if (kampanyalar.length === 0) {
    return <p className="text-sm text-muted">Henüz gönderilmiş bir kampanya yok.</p>;
  }

  return (
    <ul className="flex flex-col gap-3">
      {kampanyalar.map((k) => (
        <li key={k.id} className="rounded-xl border border-border bg-card p-3">
          <p className="font-semibold text-textStrong">{k.subject}</p>
          <p className="text-sm text-muted">
            {segmentEtiketi(k.target_segment)} — {k.sent_at ? `${k.sent_count} alıcıya gönderildi` : 'Henüz gönderilmedi'}
          </p>
        </li>
      ))}
    </ul>
  );
}
