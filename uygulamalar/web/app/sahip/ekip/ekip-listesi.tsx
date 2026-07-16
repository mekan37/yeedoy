'use client';

import { useState, useTransition } from 'react';
import { changeTeamMemberRole, removeTeamMember } from './ekip-islemleri';
import { ROLE_LABELS } from './ekip-sabitleri';

export type EkipUyesi = {
  key: string;
  membershipId: string | null;
  userId: string | null;
  email: string | null;
  role: string;
  status: 'active' | 'pending';
  source: string;
  createdAt: string;
  businessId: string;
  businessName: string;
  permissionCount: number;
  manageable: boolean;
};

const SOURCE_LABELS: Record<string, string> = {
  owner_claim: 'İşletme sahibi',
  team_membership: 'Ekip üyeliği',
  chain_membership: 'Zincir üyeliği',
};

const EDITABLE_ROLES = ['manager', 'editor', 'staff', 'viewer'];

function SearchIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="11" cy="11" r="8" /><line x1="21" y1="21" x2="16.65" y2="16.65" /></svg>;
}
function TrashIcon() {
  return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="3 6 5 6 21 6" /><path d="M19 6l-1 14H6L5 6m5 0V4h4v2" /></svg>;
}

function TabButton({ active, onClick, children }: { active: boolean; onClick: () => void; children: React.ReactNode }) {
  return (
    <button
      onClick={onClick}
      className={`shrink-0 cursor-pointer border-b-2 px-3 py-2.5 text-sm font-[700] transition-colors ${
        active ? 'border-primary text-primary' : 'border-transparent text-muted hover:text-textStrong'
      }`}
    >
      {children}
    </button>
  );
}

export function EkipListesi({
  members,
  showBusinessColumn,
}: {
  members: EkipUyesi[];
  showBusinessColumn: boolean;
}) {
  const [isPending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);
  const [tab, setTab] = useState<'all' | 'active' | 'pending'>('all');
  const [search, setSearch] = useState('');
  const [roleFilter, setRoleFilter] = useState<string>('all');

  async function run(action: () => Promise<{ error: string } | null>) {
    setError(null);
    startTransition(async () => {
      const result = await action();
      if (result?.error) setError(result.error);
    });
  }

  const activeCount = members.filter((m) => m.status === 'active').length;
  const pendingCount = members.filter((m) => m.status === 'pending').length;

  const filtered = members
    .filter((m) => tab === 'all' || m.status === tab)
    .filter((m) => roleFilter === 'all' || m.role === roleFilter)
    .filter((m) => {
      const q = search.trim().toLowerCase();
      if (!q) return true;
      return (m.email ?? '').toLowerCase().includes(q);
    });

  return (
    <div className="flex flex-col gap-4">
      {error && <div className="rounded-xl bg-red-50 px-4 py-3 text-sm text-red-700">{error}</div>}

      <div className="flex items-center gap-1 overflow-x-auto border-b border-border">
        <TabButton active={tab === 'all'} onClick={() => setTab('all')}>Tüm Üyeler ({members.length})</TabButton>
        <TabButton active={tab === 'active'} onClick={() => setTab('active')}>Aktif ({activeCount})</TabButton>
        <TabButton active={tab === 'pending'} onClick={() => setTab('pending')}>Bekleyen ({pendingCount})</TabButton>
      </div>

      <div className="flex flex-wrap items-center gap-2">
        <div className="relative min-w-[200px] flex-1">
          <span className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-muted"><SearchIcon /></span>
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="E-posta ile ara…"
            className="w-full rounded-xl border border-border bg-card py-2 pl-9 pr-3 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30"
          />
        </div>
        <select
          value={roleFilter}
          onChange={(e) => setRoleFilter(e.target.value)}
          className="rounded-xl border border-border bg-card px-3 py-2 text-sm text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/30"
        >
          <option value="all">Tüm Roller</option>
          {Object.entries(ROLE_LABELS).map(([key, cfg]) => (
            <option key={key} value={key}>{cfg.label}</option>
          ))}
        </select>
      </div>

      {filtered.length === 0 ? (
        <div className="rounded-2xl border border-dashed border-border bg-card px-6 py-12 text-center text-sm text-muted">
          Filtrelere uyan ekip üyesi yok.
        </div>
      ) : (
        <div className="overflow-hidden rounded-2xl border border-border bg-card">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead>
                <tr className="border-b border-border bg-bg text-[11px] font-[800] uppercase tracking-wide text-muted">
                  <th className="px-4 py-3">Üye</th>
                  {showBusinessColumn && <th className="px-4 py-3">İşletme</th>}
                  <th className="px-4 py-3">Rol</th>
                  <th className="px-4 py-3">Yetkiler</th>
                  <th className="px-4 py-3">Durum</th>
                  <th className="px-4 py-3">Katılım</th>
                  <th className="px-4 py-3 text-right">İşlemler</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {filtered.map((m) => {
                  const roleConfig = ROLE_LABELS[m.role] ?? ROLE_LABELS.viewer;
                  return (
                    <tr key={m.key} className="align-middle hover:bg-bg/60">
                      <td className="px-4 py-3">
                        <p className="font-[700] text-textStrong">{m.email ?? '—'}</p>
                        <p className="text-xs text-muted">{SOURCE_LABELS[m.source] ?? m.source}</p>
                      </td>
                      {showBusinessColumn && <td className="px-4 py-3 text-muted">{m.businessName}</td>}
                      <td className="px-4 py-3">
                        {m.manageable && EDITABLE_ROLES.includes(m.role) ? (
                          <select
                            value={m.role}
                            disabled={isPending}
                            onChange={(e) => run(() => changeTeamMemberRole(m.businessId, m.email ?? '', e.target.value))}
                            className={`cursor-pointer rounded-full border-0 px-2.5 py-1 text-[11px] font-[700] focus:outline-none focus:ring-2 focus:ring-primary/30 disabled:opacity-60 ${roleConfig.className}`}
                          >
                            <option value="manager">Yönetici</option>
                            <option value="editor">Editör</option>
                            <option value="staff">Personel</option>
                            <option value="viewer">İzleyici</option>
                          </select>
                        ) : (
                          <span className={`rounded-full px-2.5 py-1 text-[11px] font-[700] ${roleConfig.className}`}>{roleConfig.label}</span>
                        )}
                      </td>
                      <td className="px-4 py-3 text-muted">{m.permissionCount} yetki</td>
                      <td className="px-4 py-3">
                        <span
                          className={`rounded-full px-2.5 py-1 text-[11px] font-[700] ${
                            m.status === 'active' ? 'bg-green-50 text-green-700' : 'bg-amber-50 text-amber-700'
                          }`}
                        >
                          {m.status === 'active' ? 'Aktif' : 'Davet Bekliyor'}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-[12px] text-muted">{new Date(m.createdAt).toLocaleDateString('tr-TR')}</td>
                      <td className="px-4 py-3">
                        {m.manageable ? (
                          <div className="flex justify-end">
                            <button
                              onClick={() => {
                                if (confirm(`"${m.email}" ekip üyesini kaldırmak istediğinize emin misiniz?`)) {
                                  run(() => removeTeamMember(m.businessId, m.membershipId!));
                                }
                              }}
                              disabled={isPending}
                              className="flex h-8 w-8 cursor-pointer items-center justify-center rounded-lg border border-red-200 text-red-600 hover:bg-red-50 disabled:opacity-60"
                              aria-label={`${m.email} kaldır`}
                            >
                              <TrashIcon />
                            </button>
                          </div>
                        ) : (
                          <span className="block text-right text-[11px] text-muted">—</span>
                        )}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}
