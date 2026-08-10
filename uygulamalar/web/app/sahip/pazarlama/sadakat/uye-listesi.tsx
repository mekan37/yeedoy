export type SadakatUyesi = {
  member_id: string;
  user_id: string;
  display_name: string;
  progress: number;
  redeemed_count: number;
};

export function UyeListesi({ members }: { members: SadakatUyesi[] }) {
  if (members.length === 0) {
    return <p className="text-sm text-muted">Henüz hiç üye yok.</p>;
  }

  return (
    <div className="overflow-x-auto">
      <table className="w-full text-sm">
        <thead>
          <tr className="border-b border-border text-left text-xs font-bold uppercase tracking-wide text-muted">
            <th className="py-2">Müşteri</th>
            <th className="py-2">İlerleme</th>
            <th className="py-2">Kullanılan Ödül</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-border">
          {members.map((m) => (
            <tr key={m.member_id}>
              <td className="py-2 font-semibold text-textStrong">{m.display_name}</td>
              <td className="py-2 text-textStrong">{m.progress}</td>
              <td className="py-2 text-muted">{m.redeemed_count}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
