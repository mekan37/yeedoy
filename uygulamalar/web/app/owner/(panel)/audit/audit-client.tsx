'use client';

import { useRouter } from 'next/navigation';
import { useState } from 'react';
import { PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';

export type AuditLogRow = {
  id: string;
  created_at: string;
  actor_id: string;
  actor_name: string;
  actor_avatar_url: string | null;
  actor_role: string;
  action: string;
  description: string;
  target_table: string | null;
  target_id: string | null;
  target_label: string | null;
  business_id: string;
  business_name: string | null;
};

export type MemberOption = { user_id: string; display_name: string; role: string };

interface Props {
  logRows: AuditLogRow[];
  total: number;
  page: number;
  pageSize: number;
  members: MemberOption[];
  showBusinessColumn: boolean;
  filters: { actor: string; action: string; from: string; to: string };
}

const ROLE_LABELS: Record<string, { label: string; className: string }> = {
  owner: { label: 'İşletme Sahibi', className: 'bg-red-50 text-red-700' },
  manager: { label: 'Yönetici', className: 'bg-purple-50 text-purple-700' },
  editor: { label: 'Editör', className: 'bg-blue-50 text-blue-700' },
  staff: { label: 'Personel', className: 'bg-zinc-100 text-zinc-600' },
  viewer: { label: 'İzleyici', className: 'bg-zinc-50 text-zinc-500' },
};

const ACTION_META: Record<string, { label: string; className: string; icon: React.ComponentType<{ className?: string }> }> = {
  menu_item_updated: { label: 'Menü öğesi güncellendi', className: 'bg-blue-50 text-blue-600', icon: PencilIcon },
  menu_item_created: { label: 'Yeni ürün eklendi', className: 'bg-emerald-50 text-emerald-600', icon: PlusIcon },
  menu_item_deleted: { label: 'Ürün silindi', className: 'bg-orange-50 text-orange-600', icon: TrashIcon },
  photo_uploaded: { label: 'Fotoğraf yüklendi', className: 'bg-purple-50 text-purple-600', icon: ImageIcon },
  business_info_updated: { label: 'İşletme bilgileri güncellendi', className: 'bg-slate-100 text-slate-600', icon: SettingsIcon },
  campaign_created: { label: 'Kampanya oluşturuldu', className: 'bg-pink-50 text-pink-600', icon: MegaphoneIcon },
  team_role_changed: { label: 'Ekip üyesi rolü değiştirildi', className: 'bg-teal-50 text-teal-600', icon: UsersIcon },
  review_replied: { label: 'Yorum yanıtlandı', className: 'bg-cyan-50 text-cyan-600', icon: MessageIcon },
  reservation_note_added: { label: 'Rezervasyon notu eklendi', className: 'bg-red-50 text-red-600', icon: LockIcon },
  qr_menu_previewed: { label: 'QR menü önizlendi', className: 'bg-zinc-100 text-zinc-600', icon: EyeIcon },
};

const ACTION_OPTIONS = Object.entries(ACTION_META).map(([key, meta]) => ({ key, label: meta.label }));

function buildPageNumbers(current: number, total: number): (number | '…')[] {
  if (total <= 7) return Array.from({ length: total }, (_, i) => i + 1);
  const pages = new Set<number>([1, 2, total - 1, total, current - 1, current, current + 1]);
  const sorted = Array.from(pages).filter((p) => p >= 1 && p <= total).sort((a, b) => a - b);
  const result: (number | '…')[] = [];
  let prev = 0;
  for (const p of sorted) {
    if (prev && p - prev > 1) result.push('…');
    result.push(p);
    prev = p;
  }
  return result;
}

export function AuditClient({ logRows, total, page, pageSize, members, showBusinessColumn, filters }: Props) {
  const router = useRouter();
  const [actor, setActor] = useState(filters.actor);
  const [action, setAction] = useState(filters.action);
  const [from, setFrom] = useState(filters.from);
  const [to, setTo] = useState(filters.to);

  function navigate(targetPage: number, overrides?: Partial<{ actor: string; action: string; from: string; to: string }>) {
    const params = new URLSearchParams();
    const a = overrides?.actor ?? actor;
    const ac = overrides?.action ?? action;
    const f = overrides?.from ?? from;
    const t = overrides?.to ?? to;
    if (a) params.set('actor', a);
    if (ac) params.set('action', ac);
    if (f) params.set('from', f);
    if (t) params.set('to', t);
    params.set('page', String(targetPage));
    router.push(`/owner/audit?${params.toString()}`);
  }

  const totalPages = Math.max(1, Math.ceil(total / pageSize));
  const pageNumbers = buildPageNumbers(page, totalPages);

  return (
    <div className="mx-auto w-full max-w-[1520px] px-6 pb-10 pt-2">
      {/* Filtre satırı */}
      <div className="mb-4 flex flex-wrap items-center gap-2">
        <input
          type="date"
          value={from}
          onChange={(e) => setFrom(e.target.value)}
          className="rounded-xl border border-border bg-card px-3 py-2 text-sm text-textStrong"
        />
        <span className="text-sm text-muted">—</span>
        <input
          type="date"
          value={to}
          onChange={(e) => setTo(e.target.value)}
          className="rounded-xl border border-border bg-card px-3 py-2 text-sm text-textStrong"
        />
        <select
          value={actor}
          onChange={(e) => setActor(e.target.value)}
          className="rounded-xl border border-border bg-card px-3 py-2 text-sm text-textStrong"
        >
          <option value="">Tüm Üyeler</option>
          {members.map((m) => (
            <option key={m.user_id} value={m.user_id}>{m.display_name}</option>
          ))}
        </select>
        <select
          value={action}
          onChange={(e) => setAction(e.target.value)}
          className="rounded-xl border border-border bg-card px-3 py-2 text-sm text-textStrong"
        >
          <option value="">Tüm İşlemler</option>
          {ACTION_OPTIONS.map((o) => (
            <option key={o.key} value={o.key}>{o.label}</option>
          ))}
        </select>
        <button
          onClick={() => navigate(1)}
          className="flex items-center gap-1.5 rounded-xl bg-primary px-4 py-2 text-sm font-[800] text-white transition hover:opacity-90"
        >
          <FilterIcon className="h-4 w-4" /> Filtrele
        </button>
      </div>

      {logRows.length === 0 ? (
        <PanelSectionCard>
          <PanelEmptyState
            icon={<ShieldIcon />}
            title="Denetim kaydı yok"
            description="Seçilen filtrelerle eşleşen bir kayıt bulunmuyor."
          />
        </PanelSectionCard>
      ) : (
        <PanelSectionCard noPadding>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border">
                  <th className="px-5 py-3 text-left text-xs font-[800] uppercase tracking-wide text-muted">Tarih & Saat</th>
                  <th className="px-5 py-3 text-left text-xs font-[800] uppercase tracking-wide text-muted">Kullanıcı</th>
                  {showBusinessColumn && (
                    <th className="px-5 py-3 text-left text-xs font-[800] uppercase tracking-wide text-muted">İşletme</th>
                  )}
                  <th className="px-5 py-3 text-left text-xs font-[800] uppercase tracking-wide text-muted">İşlem</th>
                  <th className="px-5 py-3 text-left text-xs font-[800] uppercase tracking-wide text-muted">Açıklama</th>
                  <th className="px-5 py-3 text-left text-xs font-[800] uppercase tracking-wide text-muted">İlgili Kayıt</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {logRows.map((log) => {
                  const roleConfig = ROLE_LABELS[log.actor_role] ?? ROLE_LABELS.viewer;
                  const actionConfig = ACTION_META[log.action];
                  const ActionIcon = actionConfig?.icon ?? EyeIcon;
                  return (
                    <tr key={log.id}>
                      <td className="whitespace-nowrap px-5 py-3 text-muted">
                        {new Date(log.created_at).toLocaleDateString('tr-TR', {
                          day: 'numeric', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit',
                        })}
                      </td>
                      <td className="px-5 py-3">
                        <div className="flex items-center gap-2">
                          <Avatar name={log.actor_name} url={log.actor_avatar_url} />
                          <div>
                            <p className="font-[700] text-textStrong">{log.actor_name}</p>
                            <span className={`rounded-full px-2 py-0.5 text-[10px] font-[800] ${roleConfig.className}`}>
                              {roleConfig.label}
                            </span>
                          </div>
                        </div>
                      </td>
                      {showBusinessColumn && (
                        <td className="px-5 py-3 text-muted">{log.business_name ?? '—'}</td>
                      )}
                      <td className="px-5 py-3">
                        <div className="flex items-center gap-2">
                          <span className={`flex h-7 w-7 shrink-0 items-center justify-center rounded-lg ${actionConfig?.className ?? 'bg-zinc-100 text-zinc-600'}`}>
                            <ActionIcon className="h-3.5 w-3.5" />
                          </span>
                          <span className="font-[700] text-textStrong">{actionConfig?.label ?? log.action}</span>
                        </div>
                      </td>
                      <td className="max-w-[260px] px-5 py-3 text-muted">{log.description}</td>
                      <td className="px-5 py-3 text-muted">{log.target_label ?? '—'}</td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
          <div className="flex flex-wrap items-center justify-between gap-3 border-t border-border px-5 py-3">
            <span className="text-xs text-muted">Toplam {total} işlem</span>
            <div className="flex items-center gap-1">
              <button
                disabled={page <= 1}
                onClick={() => navigate(page - 1)}
                className="flex h-7 w-7 items-center justify-center rounded-lg border border-border text-muted disabled:opacity-40"
              >
                <ChevLeftIcon className="h-3.5 w-3.5" />
              </button>
              {pageNumbers.map((p, i) =>
                p === '…' ? (
                  <span key={`ellipsis-${i}`} className="px-1 text-xs text-muted">…</span>
                ) : (
                  <button
                    key={p}
                    onClick={() => navigate(p)}
                    className={`flex h-7 w-7 items-center justify-center rounded-lg border text-[11px] font-[900] ${
                      p === page ? 'border-primary bg-primary text-white' : 'border-border text-muted hover:bg-black/[0.03]'
                    }`}
                  >
                    {p}
                  </button>
                ),
              )}
              <button
                disabled={page >= totalPages}
                onClick={() => navigate(page + 1)}
                className="flex h-7 w-7 items-center justify-center rounded-lg border border-border text-muted disabled:opacity-40"
              >
                <ChevRightIcon className="h-3.5 w-3.5" />
              </button>
            </div>
          </div>
        </PanelSectionCard>
      )}

      <div className="mt-4 flex items-center gap-2 rounded-2xl border border-border bg-card px-5 py-3 text-xs text-muted">
        <ShieldIcon className="h-4 w-4 shrink-0" />
        Denetim kayıtları 12 ay boyunca saklanır. Güvenliğiniz için bu kayıtlar düzenlenemez veya silinemez.
      </div>
    </div>
  );
}

function Avatar({ name, url }: { name: string; url: string | null }) {
  if (url) {
    return (
      // eslint-disable-next-line @next/next/no-img-element
      <img src={url} alt={name} className="h-8 w-8 rounded-full border border-border object-cover" />
    );
  }
  return (
    <div className="flex h-8 w-8 items-center justify-center rounded-full bg-primary text-[13px] font-[900] text-white">
      {name.charAt(0).toUpperCase()}
    </div>
  );
}

// ── Icons ─────────────────────────────────────────────────────────────────────
function ShieldIcon({ className = 'h-5 w-5' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" /></svg>;
}
function FilterIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><polygon points="22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3" /></svg>;
}
function ChevLeftIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><polyline points="15 18 9 12 15 6" /></svg>;
}
function ChevRightIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><polyline points="9 6 15 12 9 18" /></svg>;
}
function PencilIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5z" /></svg>;
}
function PlusIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><line x1="12" y1="5" x2="12" y2="19" /><line x1="5" y1="12" x2="19" y2="12" /></svg>;
}
function TrashIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="3 6 5 6 21 6" /><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" /></svg>;
}
function ImageIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="3" width="18" height="18" rx="2" /><circle cx="8.5" cy="8.5" r="1.5" /><polyline points="21 15 16 10 5 21" /></svg>;
}
function SettingsIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="3" /><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z" /></svg>;
}
function MegaphoneIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 11l18-5v12L3 13v-2z" /><path d="M11.6 16.8a3 3 0 1 1-5.8-1.6" /></svg>;
}
function UsersIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /><path d="M23 21v-2a4 4 0 0 0-3-3.87" /><path d="M16 3.13a4 4 0 0 1 0 7.75" /></svg>;
}
function MessageIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" /></svg>;
}
function LockIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="11" width="18" height="11" rx="2" /><path d="M7 11V7a5 5 0 0 1 10 0v4" /></svg>;
}
function EyeIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" /><circle cx="12" cy="12" r="3" /></svg>;
}
