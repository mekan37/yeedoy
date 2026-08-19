import { OlaySatiriRow } from './olay-satiri';
import type { OlaySatiri } from './olaylar-yardimcilari';

export function OlaylarTablosu({ rows }: { rows: OlaySatiri[] }) {
  return (
    <div className="overflow-x-auto">
      <table className="w-full text-sm">
        <thead>
          <tr className="border-b border-border text-left">
            <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Tarih / Saat</th>
            <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Kullanıcı</th>
            <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Olay</th>
            <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Açıklama</th>
            <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">IP Adresi</th>
            <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Sonuç</th>
            <th className="px-5 py-3 text-right text-[11px] font-extrabold uppercase tracking-wide text-muted">Ayrıntılar</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-border">
          {rows.map((row) => <OlaySatiriRow key={row.id} row={row} />)}
        </tbody>
      </table>
    </div>
  );
}
