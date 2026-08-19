'use client';

import { useState, useTransition } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { PanelActionButton } from '@/src/ui/bilesenler/panel-eylem-dugmesi';
import { RolDegistirIstemci } from './rol-degistir-istemci';
import { KullaniciBanButonu } from './kullanici-ban-butonu';
import { ROLE_MAP, type KullaniciSatiri } from './kullanicilar-yardimcilari';

async function topluGuncelle(ids: string[], action: 'ban' | 'clear') {
  const res = await fetch('/sunucu/yonetici/toplu-islemler', {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ type: 'users', ids, action }),
  });
  if (!res.ok) throw new Error('İşlem başarısız');
}

export function KullanicilarTablosu({ rows }: { rows: KullaniciSatiri[] }) {
  const router = useRouter();
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [isPending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);

  const secilebilirler = rows.filter((r) => r.role !== 'super_admin');
  const hepsiSecili = secilebilirler.length > 0 && secilebilirler.every((r) => selected.has(r.id));

  function toggleAll() {
    setSelected(hepsiSecili ? new Set() : new Set(secilebilirler.map((r) => r.id)));
  }
  function toggleOne(id: string) {
    setSelected((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id); else next.add(id);
      return next;
    });
  }
  function bulkAction(action: 'ban' | 'clear') {
    setError(null);
    startTransition(async () => {
      try {
        await topluGuncelle(Array.from(selected), action);
        setSelected(new Set());
        router.refresh();
      } catch {
        setError('Toplu işlem başarısız oldu.');
      }
    });
  }

  return (
    <div id="toplu-islemler" className="flex flex-col gap-3 scroll-mt-20">
      {selected.size > 0 && (
        <div className="flex flex-wrap items-center justify-between gap-2 rounded-xl border border-primary/20 bg-primary/5 px-4 py-2.5">
          <p className="text-xs font-extrabold text-textStrong">{selected.size} kullanıcı seçildi</p>
          <div className="flex items-center gap-2">
            {error && <span className="text-[10px] font-bold text-red-600">{error}</span>}
            <PanelActionButton variant="secondary" loading={isPending} onClick={() => bulkAction('clear')} className="py-1 text-xs">Toplu Engeli Kaldır</PanelActionButton>
            <PanelActionButton variant="danger" loading={isPending} onClick={() => bulkAction('ban')} className="py-1 text-xs">Toplu Engelle</PanelActionButton>
          </div>
        </div>
      )}
      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-border text-left">
              <th className="px-4 py-3">
                <input type="checkbox" checked={hepsiSecili} onChange={toggleAll} disabled={secilebilirler.length === 0} className="h-4 w-4 rounded border-border" />
              </th>
              <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Kullanıcı</th>
              <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Rol</th>
              <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Şehir</th>
              <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Kayıt Tarihi</th>
              <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Son Giriş</th>
              <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Durum</th>
              <th className="px-5 py-3 text-right text-[11px] font-extrabold uppercase tracking-wide text-muted">İşlemler</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {rows.map((u) => (
              <tr key={u.id} className="hover:bg-black/2">
                <td className="px-4 py-3">
                  {u.role !== 'super_admin' && (
                    <input type="checkbox" checked={selected.has(u.id)} onChange={() => toggleOne(u.id)} className="h-4 w-4 rounded border-border" />
                  )}
                </td>
                <td className="px-5 py-3">
                  <Link href={`/yonetici/kullanicilar/${u.id}`} className="group flex items-center gap-2.5">
                    <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-primary/10 text-xs font-black text-primary">
                      {(u.displayName ?? u.email ?? '?').charAt(0).toUpperCase()}
                    </span>
                    <div className="min-w-0">
                      <p className="truncate font-bold text-textStrong transition-colors group-hover:text-primary">{u.displayName ?? '—'}</p>
                      <p className="truncate text-xs text-muted">{u.email ?? u.id.slice(0, 12)}</p>
                    </div>
                  </Link>
                </td>
                <td className="px-5 py-3">
                  <RolDegistirIstemci userId={u.id} currentRole={u.role} roleMap={ROLE_MAP} />
                  {u.isOwner && <span className="ml-1 rounded-full bg-emerald-50 px-1.5 py-0.5 text-[9px] font-extrabold text-emerald-700">Sahip</span>}
                </td>
                <td className="px-5 py-3 text-muted">{u.city ?? '—'}</td>
                <td className="px-5 py-3 text-xs text-muted">{new Date(u.createdAt).toLocaleDateString('tr-TR')}</td>
                <td className="px-5 py-3 text-xs text-muted">{u.lastSignInAt ? new Date(u.lastSignInAt).toLocaleDateString('tr-TR') : '—'}</td>
                <td className="px-5 py-3">
                  <span className={`rounded-full px-2 py-0.5 text-[11px] font-extrabold ${u.shadowBanned ? 'bg-red-50 text-red-700' : 'bg-green-50 text-green-700'}`}>
                    {u.shadowBanned ? 'Engellendi' : 'Aktif'}
                  </span>
                </td>
                <td className="px-5 py-3">
                  <div className="flex items-center justify-end gap-1.5">
                    <Link href={`/yonetici/kullanicilar/${u.id}`} title="Detay" className="flex h-8 w-8 items-center justify-center rounded-lg border border-border text-muted transition-colors hover:border-primary/30 hover:text-primary">
                      <EyeIcon />
                    </Link>
                    {u.role !== 'super_admin' && <KullaniciBanButonu userId={u.id} banned={u.shadowBanned} />}
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

function EyeIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" />
      <circle cx="12" cy="12" r="3" />
    </svg>
  );
}
