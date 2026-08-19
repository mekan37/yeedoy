export type SadakatUyesi = {
  member_id: string;
  user_id: string;
  display_name: string;
  progress: number;
  redeemed_count: number;
};

export function UyeListesi({ members, threshold }: { members: SadakatUyesi[]; threshold?: number }) {
  if (members.length === 0) {
    return <p className="text-sm text-muted">Henüz hiç üye yok.</p>;
  }

  return (
    <div className="overflow-x-auto">
      <table className="w-full text-sm">
        <thead>
          <tr className="border-b border-border text-left text-xs font-bold uppercase tracking-wide text-muted">
            <th className="py-2 pr-3">Müşteri</th>
            <th className="py-2 pr-3">İlerleme</th>
            <th className="py-2">Kullanılan Ödül</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-border">
          {members.map((m) => {
            const pct = threshold && threshold > 0 ? Math.min(100, Math.round((m.progress / threshold) * 100)) : null;
            return (
              <tr key={m.member_id}>
                <td className="py-2.5 pr-3">
                  <div className="flex items-center gap-2.5">
                    <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-primary/10 text-xs font-black text-primary">
                      {m.display_name.charAt(0).toUpperCase()}
                    </span>
                    <span className="font-semibold text-textStrong">{m.display_name}</span>
                  </div>
                </td>
                <td className="py-2.5 pr-3">
                  {pct !== null ? (
                    <div className="flex items-center gap-2">
                      <div className="h-1.5 w-24 overflow-hidden rounded-full bg-black/5">
                        <div className="h-full rounded-full bg-primary" style={{ width: `${pct}%` }} />
                      </div>
                      <span className="text-xs font-bold text-textStrong">{m.progress}/{threshold}</span>
                    </div>
                  ) : (
                    <span className="font-bold text-textStrong">{m.progress}</span>
                  )}
                </td>
                <td className="py-2.5 text-muted">{m.redeemed_count}</td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}
