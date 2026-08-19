'use client';

import { useState } from 'react';
import { SONUC_ETIKETLERI, SONUC_STILLERI, olayTuruEtiketi, type OlaySatiri } from './olaylar-yardimcilari';

export function OlaySatiriRow({ row }: { row: OlaySatiri }) {
  const [acik, setAcik] = useState(false);

  return (
    <>
      <tr className="hover:bg-black/2">
        <td className="whitespace-nowrap px-5 py-3 text-xs text-muted">
          {new Date(row.createdAt).toLocaleString('tr-TR', { day: '2-digit', month: '2-digit', year: 'numeric' })}
          <br />
          <span className="font-bold text-textStrong">{new Date(row.createdAt).toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' })}</span>
        </td>
        <td className="px-5 py-3">
          <p className="font-bold text-textStrong">{row.userName ?? 'Ziyaretçi'}</p>
          {row.userRole && <p className="text-[11px] text-muted">{row.userRole}</p>}
        </td>
        <td className="px-5 py-3">
          <p className="font-bold text-textStrong">{olayTuruEtiketi(row.source, row.incidentType)}</p>
        </td>
        <td className="max-w-[280px] px-5 py-3 text-muted">
          <p className="line-clamp-2" title={row.description}>{row.description}</p>
        </td>
        <td className="px-5 py-3 font-mono text-xs text-muted">
          {row.ip ?? (row.ipHashPrefix ? <span title="IP hash (ham IP saklanmaz)">hash:{row.ipHashPrefix}</span> : '—')}
        </td>
        <td className="px-5 py-3">
          <span className={`rounded-full px-2 py-0.5 text-[10px] font-extrabold ${SONUC_STILLERI[row.sonuc]}`}>
            {SONUC_ETIKETLERI[row.sonuc]}
          </span>
        </td>
        <td className="px-5 py-3 text-right">
          <button
            type="button"
            onClick={() => setAcik((v) => !v)}
            className="rounded-lg border border-border px-2.5 py-1 text-xs font-bold text-muted transition-colors hover:border-primary/30 hover:text-primary"
          >
            {acik ? 'Gizle' : 'Detay'}
          </button>
        </td>
      </tr>
      {acik && (
        <tr className="bg-black/2">
          <td colSpan={7} className="px-5 py-3">
            <div className="flex flex-col gap-1.5 text-xs">
              <p><span className="font-extrabold text-textStrong">Kaynak tablo:</span> <span className="font-mono text-muted">{row.source}</span></p>
              <p><span className="font-extrabold text-textStrong">Olay ID:</span> <span className="font-mono text-muted">{row.id}</span></p>
              {row.meta && Object.keys(row.meta).length > 0 && (
                <pre className="mt-1 max-w-full overflow-x-auto rounded-lg bg-card p-2.5 font-mono text-[11px] text-muted">
                  {JSON.stringify(row.meta, null, 2)}
                </pre>
              )}
            </div>
          </td>
        </tr>
      )}
    </>
  );
}
