'use client';

import { Fragment, useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import type { AdminRole } from './roller-yardimcilari';
import { EditRolButonu } from './rol-modal';

interface Uye { user_id: string; role_id: string; created_at: string }

export function RolTablosu({ roles, members, nameByUserId }: { roles: AdminRole[]; members: Uye[]; nameByUserId: Record<string, string> }) {
  const router = useRouter();
  const [genisletilen, setGenisletilen] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();
  const [tasima, setTasima] = useState<Record<string, string>>({});

  function tasi(userId: string, currentRoleId: string) {
    const hedefRoleId = tasima[userId];
    if (!hedefRoleId || hedefRoleId === currentRoleId) return;
    startTransition(async () => {
      await fetch('/sunucu/yonetici/roller/kullanici-ata', {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ userId, roleId: hedefRoleId }),
      });
      router.refresh();
    });
  }

  function sil(roleId: string) {
    if (!confirm('Bu rol silinecek. Devam et?')) return;
    startTransition(async () => {
      const res = await fetch('/sunucu/yonetici/roller', {
        method: 'DELETE',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id: roleId }),
      });
      const json = await res.json().catch(() => ({}));
      if (!res.ok) { alert(json.error ?? 'Silinemedi'); return; }
      router.refresh();
    });
  }

  return (
    <div className="overflow-hidden rounded-2xl border border-border bg-card">
      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-border text-left">
              <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Rol Adı</th>
              <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Açıklama</th>
              <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Tür</th>
              <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Kullanıcı Sayısı</th>
              <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Durum</th>
              <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Son Güncelleme</th>
              <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">İşlemler</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {roles.map((r) => {
              const uyeler = members.filter((m) => m.role_id === r.id);
              const acik = genisletilen === r.id;
              return (
                <Fragment key={r.id}>
                  <tr className="hover:bg-black/2">
                    <td className="px-4 py-3">
                      <span className="font-extrabold text-textStrong">{r.name}</span>
                      <span className="ml-1.5 rounded-full bg-zinc-100 px-2 py-0.5 text-[10px] font-bold text-zinc-600">{r.is_system ? 'Sistem' : 'Özel'}</span>
                    </td>
                    <td className="max-w-[220px] px-4 py-3 text-xs text-muted">{r.description ?? '—'}</td>
                    <td className="px-4 py-3 text-xs text-muted">{r.is_system ? 'Sistem' : 'Özel'}</td>
                    <td className="px-4 py-3">
                      <button
                        type="button"
                        onClick={() => setGenisletilen(acik ? null : r.id)}
                        disabled={uyeler.length === 0}
                        className="font-extrabold text-primary underline decoration-dotted disabled:text-muted disabled:no-underline"
                      >
                        {uyeler.length}
                      </button>
                    </td>
                    <td className="px-4 py-3">
                      <span className={`inline-flex rounded-full px-2 py-0.5 text-[10px] font-bold ${r.is_active ? 'bg-emerald-50 text-emerald-700' : 'bg-zinc-100 text-zinc-600'}`}>
                        {r.is_active ? 'Aktif' : 'Pasif'}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-xs text-muted">
                      <p>{new Date(r.updated_at).toLocaleDateString('tr-TR')}</p>
                      {r.updated_by_name && <p className="text-[10px]">{r.updated_by_name}</p>}
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-1.5">
                        <EditRolButonu role={r} />
                        <button
                          type="button"
                          disabled={r.is_system || uyeler.length > 0 || isPending}
                          onClick={() => sil(r.id)}
                          title={r.is_system ? 'Sistem rolü silinemez' : uyeler.length > 0 ? 'Önce kullanıcıları başka role taşıyın' : 'Sil'}
                          className="rounded-lg border border-danger/30 px-2.5 py-1.5 text-xs font-bold text-danger transition-colors hover:bg-danger/6 disabled:cursor-not-allowed disabled:opacity-40"
                        >
                          Sil
                        </button>
                      </div>
                    </td>
                  </tr>
                  {acik && uyeler.length > 0 && (
                    <tr>
                      <td colSpan={7} className="bg-cardAlt px-6 py-4">
                        <p className="mb-2 text-[11px] font-extrabold uppercase tracking-wide text-muted">Bu Role Atanmış Kullanıcılar</p>
                        <div className="flex flex-col gap-2">
                          {uyeler.map((u) => (
                            <div key={u.user_id} className="flex items-center justify-between gap-3 rounded-lg border border-border bg-card px-3 py-2">
                              <span className="text-xs font-bold text-textStrong">{nameByUserId[u.user_id] ?? u.user_id.slice(0, 12)}</span>
                              <div className="flex items-center gap-2">
                                <select
                                  value={tasima[u.user_id] ?? r.id}
                                  onChange={(e) => setTasima((prev) => ({ ...prev, [u.user_id]: e.target.value }))}
                                  className="rounded-lg border border-border bg-bg px-2 py-1 text-xs font-bold text-textStrong"
                                >
                                  {roles.map((rr) => <option key={rr.id} value={rr.id}>{rr.name}</option>)}
                                </select>
                                <button type="button" disabled={isPending} onClick={() => tasi(u.user_id, r.id)} className="rounded-lg bg-primary px-2.5 py-1 text-xs font-bold text-white disabled:opacity-50">
                                  Taşı
                                </button>
                              </div>
                            </div>
                          ))}
                        </div>
                      </td>
                    </tr>
                  )}
                </Fragment>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}
