# Owner→Sahip Türkçeleştirme Tamamlama Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `app/owner` ağacını, kayıp özellik olmadan kalıcı olarak kaldırmak; `/sahip` tek kanonik owner paneli olsun ve canlı `isletme.yeedoy.com` subdomain trafiği de oraya aksın.

**Architecture:** Next.js 15 App Router. İki iş grubu var: (A) Faz 1 planı (13 Temmuz) yazıldıktan SONRA `/owner` ağacına eklenmiş/güncellenmiş 5 özelliği `/sahip`'e uzlaştırmak (Denetim Kaydı, Analitik, Gösterge Panosu link'i, `/sahip/etkinlik` nav etiketi, Mesajlar temizliği); (B) Faz 1 planının hiç uygulanmamış Task 15-20'sini uygulamak (ölü stub'ları silme, nav güncelleme, cross-reference, redirect'ler, `app/owner`'ın nihai silinmesi + middleware/subdomain-rewrite güncellemesi, final doğrulama).

**Tech Stack:** Next.js 15 (App Router), TypeScript, Supabase, Tailwind (semantic token sınıfları).

**Referans:** `docs/superpowers/specs/2026-07-20-owner-turkification-tamamlama-design.md` (bu planın kaynağı) ve `docs/superpowers/plans/2026-07-13-owner-panel-turkification-plan.md` (orijinal Faz 1 planı — Task 15-18'in referans metni buradan alınmıştır).

---

## Dosya Yapısı Özeti

**Değiştirilecek (içerik birleştirme):**
- `app/sahip/denetim-kaydi/page.tsx` (owner'ın çalışan sürümüyle tamamen değiştirilir)
- `app/sahip/analitik/page.tsx` (owner'ın 18 Temmuz redesign'ından eksik bölümler eklenir)
- `app/sahip/gosterge-panosu/page.tsx` (varsa link düzeltmesi — koşullu)
- `src/ui/kabuk/sahip-kabuk-istemcisi.tsx` (nav'a 7 yeni item + "Aktivite"→"Etkinlikler" etiket düzeltmesi)
- `app/forbidden/page.tsx`, `app/login/page.tsx` (`/owner/*` referansları `/sahip/*`'e)
- `next.config.mjs` (redirect'ler eklenir)
- `middleware.ts` (guard sadeleşir, subdomain rewrite prefix'i `/sahip` olur, `OWNER_LOGIN_PATH` → `/giris`)

**Oluşturulacak:**
- `app/sahip/denetim-kaydi/denetim-kaydi-istemcisi.tsx`

**Silinecek:**
- `app/owner/**` (tüm ağaç, tamamen)
- `app/api/owner/**` (varsa kalan)
- `app/sahip/crm/`, `app/sahip/sponsorluk/`, `app/sahip/finansal/`, `app/sahip/envanter/`, `app/sahip/siparisler/` (ölü stub'lar)
- `app/sunucu/sahip/envanter/`, `app/sunucu/sahip/siparis-listesi/`, `app/sunucu/sahip/finansal-csv/` (ölü API stub'ları)
- `src/ui/shell/owner-shell-client.tsx` (kullanılmıyor)

---

### Task 1: Denetim Kaydı — owner'ın çalışan sürümünü sahip'e taşı

**Files:**
- Modify: `uygulamalar/web/app/sahip/denetim-kaydi/page.tsx` (tamamen değiştirilecek)
- Create: `uygulamalar/web/app/sahip/denetim-kaydi/denetim-kaydi-istemcisi.tsx`
- Delete (bu task sonunda değil, Task 10'da `app/owner` toptan silinirken): `app/owner/(panel)/audit/**`

**Bağlam:** `/sahip/denetim-kaydi` şu an var olmayan/yanlış bir tabloyu (`admin_audit_log`) sorgulayan bozuk bir stub. `/owner/(panel)/audit` ise 17-18 Temmuz'da inşa edilmiş, `business_audit_log` + `get_business_audit_log_v1` RPC'sine bağlı, filtre (tarih/üye/işlem türü) ve sayfalama destekli, tam çalışan bir sayfa. Bu task, owner'ın içeriğini sahip'in Türkçe dosya/import konvansiyonuna uyarlayarak taşır.

- [ ] **Step 1: `page.tsx`'i tamamen değiştir**

`uygulamalar/web/app/sahip/denetim-kaydi/page.tsx`:

```tsx
import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { PanelActionButton } from '@/src/ui/bilesenler/panel-eylem-dugmesi';
import { DenetimKaydiIstemcisi } from './denetim-kaydi-istemcisi';
import type { DenetimKaydiSatiri, UyeSecenegi } from './denetim-kaydi-istemcisi';

export const metadata: Metadata = {
  title: 'Denetim Kaydı | Sahip Paneli',
  robots: { index: false, follow: false },
};

const SAYFA_BOYUTU = 10;

type Props = {
  searchParams: Promise<{
    page?: string;
    actor?: string;
    action?: string;
    from?: string;
    to?: string;
  }>;
};

type IsletmeBirlestirmeSatiri = { business_id: string; businesses: { id: string; name: string } | null };

export default async function SahipDenetimKaydiSayfasi({ searchParams }: Props) {
  const { page: pageParam, actor, action, from, to } = await searchParams;
  const page = Math.max(1, Number(pageParam) || 1);

  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return null;

  const [{ data: ownerBiz }, { data: teamBiz }, { data: ownProfile }] = await Promise.all([
    (supabase as any)
      .from('owner_claims')
      .select('business_id, businesses(id, name)')
      .eq('user_id', user.id)
      .eq('status', 'approved'),
    (supabase as any)
      .from('business_team_memberships')
      .select('business_id, businesses(id, name)')
      .eq('user_id', user.id)
      .not('accepted_at', 'is', null)
      .is('revoked_at', null),
    (supabase as any)
      .from('user_profiles')
      .select('user_id, display_name')
      .eq('user_id', user.id)
      .maybeSingle(),
  ]);

  const ownerRows = (ownerBiz ?? []) as IsletmeBirlestirmeSatiri[];
  const teamRows = (teamBiz ?? []) as IsletmeBirlestirmeSatiri[];

  const businessMap = new Map<string, string>();
  for (const r of [...ownerRows, ...teamRows]) {
    if (r.businesses) businessMap.set(r.businesses.id, r.businesses.name);
  }
  const businessIds = Array.from(businessMap.keys());

  if (businessIds.length === 0) {
    return (
      <div className="flex flex-col">
        <PanelSayfaBasligi eyebrow="Owner" title="Denetim Kaydı" description="Ekip üyelerinizin yaptığı tüm işlemleri burada görüntüleyebilir ve filtreleyebilirsiniz." />
        <PanelIcerikYuzeyi className="pt-6">
          <PanelEmptyState
            icon={<ShieldIcon />}
            title="İşletme bulunamadı"
            description="Denetim kaydını görmek için önce bir işletmeye erişiminiz olmalı."
          />
        </PanelIcerikYuzeyi>
      </div>
    );
  }

  const { data: memberRows } = await (supabase as any)
    .from('business_team_memberships')
    .select('user_id, role, user_profiles(user_id, display_name)')
    .in('business_id', businessIds)
    .not('accepted_at', 'is', null)
    .is('revoked_at', null);

  type UyeBirlestirmeSatiri = { user_id: string; role: string; user_profiles: { user_id: string; display_name: string } | null };
  const memberMap = new Map<string, UyeSecenegi>();

  const ownDisplayName = (ownProfile as { display_name: string } | null)?.display_name ?? 'Ben';
  memberMap.set(user.id, { user_id: user.id, display_name: ownDisplayName, role: 'owner' });

  for (const m of (memberRows ?? []) as UyeBirlestirmeSatiri[]) {
    if (!memberMap.has(m.user_id)) {
      memberMap.set(m.user_id, {
        user_id: m.user_id,
        display_name: m.user_profiles?.display_name ?? 'Kullanıcı',
        role: m.role,
      });
    }
  }
  const members = Array.from(memberMap.values());

  const offset = (page - 1) * SAYFA_BOYUTU;
  const { data: result } = await (supabase as any).rpc('get_business_audit_log_v1', {
    p_business_ids: businessIds,
    p_actor_id: actor || null,
    p_action: action || null,
    p_date_from: from || null,
    p_date_to: to || null,
    p_limit: SAYFA_BOYUTU,
    p_offset: offset,
  });

  const logRows = (result?.rows ?? []) as DenetimKaydiSatiri[];
  const total = (result?.total ?? 0) as number;

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Owner"
        title="Denetim Kaydı"
        description="Ekip üyelerinizin yaptığı tüm işlemleri burada görüntüleyebilir ve filtreleyebilirsiniz."
        actions={
          <>
            <PanelActionButton variant="secondary" disabled title="Yakında aktif olacak">Dışa Aktar</PanelActionButton>
            <PanelActionButton variant="primary" disabled title="Yakında aktif olacak">Denetim Raporu</PanelActionButton>
          </>
        }
      />
      <DenetimKaydiIstemcisi
        logRows={logRows}
        total={total}
        page={page}
        pageSize={SAYFA_BOYUTU}
        members={members}
        showBusinessColumn={businessIds.length > 1}
        filters={{ actor: actor ?? '', action: action ?? '', from: from ?? '', to: to ?? '' }}
      />
    </div>
  );
}

function ShieldIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
    </svg>
  );
}
```

- [ ] **Step 2: `denetim-kaydi-istemcisi.tsx`'i oluştur**

`uygulamalar/web/app/sahip/denetim-kaydi/denetim-kaydi-istemcisi.tsx`:

```tsx
'use client';

import { useRouter } from 'next/navigation';
import { useState } from 'react';
import { PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';

export type DenetimKaydiSatiri = {
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

export type UyeSecenegi = { user_id: string; display_name: string; role: string };

interface Props {
  logRows: DenetimKaydiSatiri[];
  total: number;
  page: number;
  pageSize: number;
  members: UyeSecenegi[];
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

export function DenetimKaydiIstemcisi({ logRows, total, page, pageSize, members, showBusinessColumn, filters }: Props) {
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
    router.push(`/sahip/denetim-kaydi?${params.toString()}`);
  }

  const totalPages = Math.max(1, Math.ceil(total / pageSize));
  const pageNumbers = buildPageNumbers(page, totalPages);

  return (
    <div className="mx-auto w-full max-w-[1520px] px-6 pb-10 pt-2">
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
        <PanelBolumKarti>
          <PanelEmptyState
            icon={<ShieldIcon />}
            title="Denetim kaydı yok"
            description="Seçilen filtrelerle eşleşen bir kayıt bulunmuyor."
          />
        </PanelBolumKarti>
      ) : (
        <PanelBolumKarti noPadding>
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
        </PanelBolumKarti>
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
```

- [ ] **Step 3: Typecheck**

Run: `cd uygulamalar/web && npm run typecheck`
Expected: `app/sahip/denetim-kaydi/**` için hata yok. (Repo genelinde `app/owner` ile ilgili önceden var olan hatalar bu task'ın kapsamı dışında — henüz silinmedi, Task 10'da silinecek.)

- [ ] **Step 4: Lint**

Run: `cd uygulamalar/web && npm run lint`
Expected: Bu iki dosyada hata yok (`<img>` satırı için `eslint-disable-next-line @next/next/no-img-element` zaten eklendi).

- [ ] **Step 5: Commit**

```bash
cd uygulamalar/web
git add app/sahip/denetim-kaydi
git commit -m "feat(web): sahip denetim kaydı sayfası owner'ın çalışan sürümüyle değiştirildi

Eski /sahip/denetim-kaydi var olmayan admin_audit_log tablosunu
sorguluyordu. Yerine business_audit_log + get_business_audit_log_v1
RPC'sine bağlı, filtre ve sayfalama destekli çalışan sürüm taşındı
(kaynak: app/owner/(panel)/audit, 17-18 Temmuz'da inşa edilmişti)."
```

---

### Task 2: Analitik — owner'ın 18 Temmuz redesign'ından eksik bölümleri sahip'e ekle

**Files:**
- Read: `uygulamalar/web/app/owner/(panel)/analytics/page.tsx` (251 satır), `analytics-client.tsx` (460 satır)
- Modify: `uygulamalar/web/app/sahip/analitik/page.tsx` (347 satır, tek dosya)

**Bağlam:** `/sahip/analitik` 16 Temmuz'da bir kez merge edilmişti (commit `2422093`). İki gün sonra (18 Temmuz, commit `0af2aaa`) `/owner/(panel)/analytics` ayrıca "mockup tasarımına göre" yeniden tasarlandı — bu son güncelleme `/sahip`'e hiç yansımadı. Owner tarafı artık page.tsx (251) + analytics-client.tsx (460) = 711 satır; sahip tarafı hâlâ 347 satırlık tek dosya. Aradaki fark, 18 Temmuz'daki redesign'da eklenen/değişen bölümlerdir.

- [ ] **Step 1: Owner'ın güncel sürümünü tam oku**

`app/owner/(panel)/analytics/page.tsx` ve `app/owner/(panel)/analytics/analytics-client.tsx`'in tamamını oku. Hangi state'lerin (`useState` çağrıları), hangi fonksiyonların ve hangi JSX bölüm başlıklarının 18 Temmuz'da eklendiğini anlamak için `git show 0af2aaa -- "uygulamalar/web/app/owner/(panel)/analytics/analytics-client.tsx"` ve `git show 0af2aaa -- "uygulamalar/web/app/owner/(panel)/analytics/page.tsx"` diff'lerini de oku — bu, redesign'da NEYİN değiştiğini (tamamı değil, sadece farkı) gösterir.

- [ ] **Step 2: Sahip'in mevcut sürümünü tam oku**

`app/sahip/analitik/page.tsx`'in tamamını oku (347 satır, tek dosya — page+client ayrımı yok). 16 Temmuz'daki merge'de (`2422093`) hangi owner bölümlerinin zaten alındığını not al.

- [ ] **Step 3: Fark listesi çıkar**

Owner'ın `analytics-client.tsx`'indeki state/fonksiyon/JSX-bölüm listesini, sahip'in `analitik/page.tsx`'indekiyle karşılaştır. Sadece owner'da olan (18 Temmuz'da eklenmiş, sahip'e hiç yansımamış) her state/fonksiyon/UI bölümünü listele — bu, eklenecek şeylerin listesidir. Sahip'in kendine özgü mantığını (Yoğun Saatler widget'ı, whatsapp_click/qr_scan tracking, saatlik dağılım grafiği — 13 Temmuz planının Task 6'sında zaten korunmuştu) SİLME.

- [ ] **Step 4: `app/sahip/analitik/page.tsx`'i güncelle**

Step 3'te bulunan "sadece owner'da olan" bölümleri, sahip'in mevcut dosya yapısına (tek dosya, Türkçe import path'leri: `@/src/lib/taban-sunucu`, `@/src/ui/yerlesim/*`, `@/src/ui/bilesenler/*`) uyarlayarak ekle. Dosya 711 satıra yaklaşacak kadar büyürse (owner + sahip birleşimi), CLAUDE.md'nin "dosya büyürse böl" kuralına uyarak `app/sahip/analitik/analitik-istemcisi.tsx` adında ayrı bir client component dosyasına böl — `page.tsx` sadece veri çekip client'a prop geçirsin (owner'ın page.tsx/analytics-client.tsx ayrımıyla tutarlı bir desen).

- [ ] **Step 5: Typecheck + lint**

Run: `cd uygulamalar/web && npm run typecheck && npm run lint`
Expected: Hata yok.

- [ ] **Step 6: Tarayıcıda manuel doğrulama**

`npm run dev`, `/sahip/analitik`'e giriş yaparak git, hem owner'ın 18 Temmuz'da eklediği bölümlerin hem sahip'in Yoğun Saatler/whatsapp/qr_scan mantığının aynı sayfada göründüğünü doğrula.

- [ ] **Step 7: Commit**

```bash
cd uygulamalar/web
git add -A app/sahip/analitik
git commit -m "feat(web): analitik sayfasına owner'ın 18 Temmuz redesign'ından eksik bölümler eklendi"
```

---

### Task 3: Gösterge Panosu — owner'daki link düzeltmesini kontrol et (koşullu)

**Files:**
- Read: `uygulamalar/web/app/sahip/gosterge-panosu/page.tsx`

**Bağlam:** `/owner/(panel)/dashboard`'da 18 Temmuz'da (commit `71b1a9a`) şu değişiklik yapıldı: `<Link href="/owner/activity">Tüm Aktiviteler →</Link>` → `<Link href="/owner/audit">Tüm Denetim Kayıtları →</Link>`. Bu, "Son Aktiviteler" (son 3 yorum önizlemesi) bölümünün altındaki bir link. **Ön kontrol yapıldı**: `/sahip/gosterge-panosu/page.tsx`'te şu an böyle bir "Son Aktiviteler" bölümü/linki YOK — yani 13 Temmuz'daki Task 8 merge'i bu bölümü hiç almamış olabilir. Bu task'ın kapsamı SADECE link düzeltmesini yansıtmaktır — eğer bölümün kendisi hiç yoksa, o bölümü owner'dan yeniden inşa etmek bu task'ın kapsamında DEĞİLDİR (bu, ayrı ve daha büyük bir Gösterge Panosu merge işi olur, mevcut spec'in kapsamı dışında).

- [ ] **Step 1: `app/sahip/gosterge-panosu/page.tsx`'i oku, "Son Aktiviteler" veya benzeri bir link bölümü olup olmadığını doğrula**

`grep -n "Son Aktivite\|Tüm Aktiviteler\|owner/activity\|owner/audit" app/sahip/gosterge-panosu/page.tsx` çalıştır.

- [ ] **Step 2a: Eğer bölüm/link bulunduysa, hedefini düzelt**

Bulunan link'in `href`'ini `/sahip/denetim-kaydi` yap, metnini "Tüm Denetim Kayıtları →" olarak güncelle (owner'daki değişiklikle tutarlı).

- [ ] **Step 2b: Eğer bölüm/link bulunamadıysa, hiçbir değişiklik yapma**

Bu durumda Step 1'in grep sonucunun boş olduğunu bu task'ın notlarına (commit mesajına gerek yok, sadece kendi takibin için) yaz ve Task 4'e geç — "Son Aktiviteler" bölümünü owner'dan yeniden inşa ETME (kapsam dışı).

- [ ] **Step 3: Değişiklik yapıldıysa typecheck + commit**

Eğer Step 2a uygulandıysa:
```bash
cd uygulamalar/web && npm run typecheck && npm run lint
git add app/sahip/gosterge-panosu
git commit -m "fix(web): gösterge panosu linki denetim kaydına güncellendi"
```
Değişiklik yapılmadıysa bu adımı atla.

---

### Task 4: `/sahip/etkinlik` nav etiketini düzelt

**Files:**
- Modify: `uygulamalar/web/src/ui/kabuk/sahip-kabuk-istemcisi.tsx:37`

**Bağlam:** `/sahip/etkinlik` sayfası incelendi — bu, `business_events` tablosuna bağlı, gerçek ve çalışan bir Etkinlik/Bilet Yönetimi özelliği (audit/denetim konusuyla alakasız). Ancak nav'da yanlışlıkla "Aktivite" olarak etiketlenmiş, bu da yeni eklenecek "Denetim Kaydı" (Task 7) ile karışabilir. İçerik değişmiyor, sadece etiket.

- [ ] **Step 1: Nav satırını değiştir**

`src/ui/kabuk/sahip-kabuk-istemcisi.tsx` içinde (37. satır civarı), `Yönetim` bölümündeki:

```tsx
      { href: '/sahip/etkinlik', label: 'Aktivite', icon: <ActivityIcon /> },
```

satırını şununla değiştir:

```tsx
      { href: '/sahip/etkinlik', label: 'Etkinlikler', icon: <ActivityIcon /> },
```

- [ ] **Step 2: Typecheck**

Run: `cd uygulamalar/web && npm run typecheck`
Expected: Hata yok.

- [ ] **Step 3: Commit**

```bash
cd uygulamalar/web
git add src/ui/kabuk/sahip-kabuk-istemcisi.tsx
git commit -m "fix(web): sahip nav'ında Etkinlikler sayfasının etiketi düzeltildi (Aktivite -> Etkinlikler, Denetim Kaydı ile karışmasın diye)"
```

---

### Task 5: Owner'ın "Mesajlar" placeholder'ını sil

**Files:**
- Delete: `app/owner/(panel)/messages/page.tsx`

**Bağlam:** İçeriği doğrulandı: `PanelPageHeader` + "Bu bölüm yakında aktif olacak" placeholder'ı, gerçek bir Supabase çağrısı yok, hiçbir nav'da (`owner-shell-client.tsx` veya `sahip-kabuk-istemcisi.tsx`) linki yok. Sahip'e taşınmaz, doğrudan silinir. (Bu klasör zaten Task 10'da `app/owner` toptan silinirken de gidecekti — burada erken ve açıkça silmek, "neden silindi" kaydını commit geçmişinde tutmak için.)

- [ ] **Step 1: Sil**

```bash
cd uygulamalar/web
git rm -r "app/owner/(panel)/messages"
```

- [ ] **Step 2: Hiçbir yerden referans olmadığını doğrula**

```bash
grep -rn "owner/messages\|OwnerMessagesPage" app src --include="*.ts" --include="*.tsx"
```

Expected: Sonuç boş.

- [ ] **Step 3: Commit**

```bash
git commit -m "chore(web): owner mesajlar placeholder sayfası silindi (linksiz, gerçek mantık yok)"
```

---

### Task 6: Ölü stub route'ları sil (Faz 1 Task 15, resume)

**Files:**
- Delete: `app/sahip/crm/`, `app/sahip/sponsorluk/`, `app/sahip/finansal/`, `app/sahip/envanter/`, `app/sahip/siparisler/`
- Delete: `app/sunucu/sahip/envanter/`, `app/sunucu/sahip/siparis-listesi/`, `app/sunucu/sahip/finansal-csv/`

**Bağlam:** Doğrulandı — bu 5 route'un `page.tsx`'i her durumda `redirect('/sahip/gosterge-panosu')` ile başlıyor ve hiçbir alt component'i render etmiyor (yani `sponsorluk-formu.tsx`, `sponsorluk-islemleri.ts`, `envanter-istemci.tsx`, `siparis-yonetimi.tsx` gibi RPC çağrısı içeren dosyalar bile tamamen erişilemez/ölü kod — page.tsx onları hiç import etmiyor). `fiyat-raporu` SİLİNMEZ (canlı, nav'da linkli, kapsam dışı).

- [ ] **Step 1: Redirect-only olduklarını son bir kez doğrula**

```bash
cd uygulamalar/web
grep -L "redirect(" app/sahip/crm/page.tsx app/sahip/sponsorluk/page.tsx app/sahip/finansal/page.tsx app/sahip/envanter/page.tsx app/sahip/siparisler/page.tsx
```

Expected: Sonuç boş (hepsi `redirect(` içeriyor, `grep -L` eşleşmeyenleri listeler).

- [ ] **Step 2: Sayfaları sil**

```bash
git rm -r app/sahip/crm app/sahip/sponsorluk app/sahip/finansal app/sahip/envanter app/sahip/siparisler
```

- [ ] **Step 3: Karşılık gelen ölü API stub'larını sil**

```bash
grep -rln "sunucu/sahip/envanter\|sunucu/sahip/siparis-listesi\|sunucu/sahip/finansal-csv" app src --include="*.ts" --include="*.tsx"
```

Expected: Sonuç boş (Step 2'de silinen dosyalar zaten gitti, başka hiçbir yer bu API'leri çağırmıyor — daha önce doğrulandı). Sonra:

```bash
git rm -r app/sunucu/sahip/envanter app/sunucu/sahip/siparis-listesi app/sunucu/sahip/finansal-csv
```

- [ ] **Step 4: Nav'da bu route'lara link olmadığını doğrula**

```bash
grep -n "crm\|sponsorluk\|finansal\|envanter\|siparisler" src/ui/kabuk/sahip-kabuk-istemcisi.tsx
```

Expected: Sonuç boş.

- [ ] **Step 5: Typecheck + lint**

Run: `npm run typecheck && npm run lint`
Expected: Hata yok.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "chore(web): kapsam dışı bırakılan sahip stub sayfaları (crm/sponsorluk/finansal/envanter/siparisler) silindi"
```

---

### Task 7: Nav güncelle — eksik 7 item ekle, `owner-shell-client.tsx` sil (Faz 1 Task 16, resume)

**Files:**
- Modify: `uygulamalar/web/src/ui/kabuk/sahip-kabuk-istemcisi.tsx`
- Delete: `uygulamalar/web/src/ui/shell/owner-shell-client.tsx`

**Bağlam:** Doğrulandı — nav'da şu 7 route hiç linklenmemiş: `/sahip/rezervasyonlar`, `/sahip/fotograflar`, `/sahip/bildirimler`, `/sahip/pazarlama`, `/sahip/buyume`, `/sahip/denetim-kaydi` (Task 1'de içeriği düzeltildi ama nav linki hâlâ yok), `/sahip/yapay-zeka-analizi`. Dosyalar zaten var, sadece nav'a ekleniyor.

- [ ] **Step 1: `ownerNavSections` dizisine yeni item'ları ekle**

`src/ui/kabuk/sahip-kabuk-istemcisi.tsx` içindeki `ownerNavSections` dizisini şu hale getir (mevcut 3 bölüm + item'lar korunur, yeni item'lar eklenir):

```tsx
const ownerNavSections: NavSection[] = [
  {
    title: 'Operasyon',
    items: [
      { href: '/sahip/gosterge-panosu', label: 'Genel Bakış', icon: <HomeIcon />, exact: true },
      { href: '/sahip/isletmeler', label: 'İşletmeler', icon: <BuildingIcon /> },
      { href: '/sahip/menuler', label: 'Menüler', icon: <MenuIcon /> },
      { href: '/sahip/rezervasyonlar', label: 'Rezervasyonlar', icon: <CalendarIcon /> },
      { href: '/sahip/fotograflar', label: 'Fotoğraflar', icon: <ImageIcon /> },
      { href: '/sahip/baslangic', label: 'Başlangıç Rehberi', icon: <RocketIcon /> },
    ],
  },
  {
    title: 'Büyüme',
    items: [
      { href: '/sahip/analitik', label: 'Analitik', icon: <ChartIcon /> },
      { href: '/sahip/fiyat-raporu', label: 'Fiyat Raporu', icon: <PriceIcon /> },
      { href: '/sahip/yorumlar', label: 'Yorumlar', icon: <StarIcon /> },
      { href: '/sahip/karekod', label: 'QR Kodlar', icon: <QrIcon /> },
      { href: '/sahip/pazarlama', label: 'Pazarlama', icon: <MegaphoneIcon /> },
      { href: '/sahip/buyume', label: 'Büyüme', icon: <TrendingUpIcon /> },
      { href: '/sahip/yapay-zeka-analizi', label: 'Yapay Zeka Analizi', icon: <SparklesIcon /> },
    ],
  },
  {
    title: 'Yönetim',
    items: [
      { href: '/sahip/ekip', label: 'Ekip', icon: <UsersIcon /> },
      { href: '/sahip/fiyat-onerileri', label: 'Fiyat Önerileri', icon: <TagIcon /> },
      { href: '/sahip/istekler', label: 'Grup İstekleri', icon: <GroupIcon /> },
      { href: '/sahip/etkinlik', label: 'Etkinlikler', icon: <ActivityIcon /> },
      { href: '/sahip/bildirimler', label: 'Bildirimler', icon: <BellIcon /> },
      { href: '/sahip/denetim-kaydi', label: 'Denetim Kaydı', icon: <ShieldIcon /> },
      { href: '/sahip/cop-kutusu', label: 'Çöp Kutusu', icon: <TrashIcon /> },
      { href: '/sahip/ayarlar', label: 'Ayarlar', icon: <SettingsIcon /> },
    ],
  },
];
```

(Not: `Aktivite`→`Etkinlikler` etiket değişikliği Task 4'te zaten yapıldı, yukarıdaki blok o değişikliği de içeriyor — Task 4 daha önce commit edildiyse burada tekrar aynı satırı yazman idempotent, sorun değil.)

- [ ] **Step 2: Eksik ikon component'lerini dosyanın altına ekle**

Mevcut `TrashIcon` fonksiyonunun hemen altına (dosya sonuna) şu yeni ikon component'lerini ekle:

```tsx
function CalendarIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="4" width="18" height="18" rx="2" ry="2" />
      <line x1="16" y1="2" x2="16" y2="6" />
      <line x1="8" y1="2" x2="8" y2="6" />
      <line x1="3" y1="10" x2="21" y2="10" />
    </svg>
  );
}

function ImageIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="3" width="18" height="18" rx="2" />
      <circle cx="8.5" cy="8.5" r="1.5" />
      <polyline points="21 15 16 10 5 21" />
    </svg>
  );
}

function MegaphoneIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M3 11l18-5v12L3 13v-2z" />
      <path d="M11.6 16.8a3 3 0 1 1-5.8-1.6" />
    </svg>
  );
}

function TrendingUpIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <polyline points="23 6 13.5 15.5 8.5 10.5 1 18" />
      <polyline points="17 6 23 6 23 12" />
    </svg>
  );
}

function SparklesIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 3l1.9 4.9L19 9.8l-5.1 1.9L12 16.6l-1.9-4.9L5 9.8l5.1-1.9z" />
      <path d="M19 3v4M17 5h4" />
    </svg>
  );
}

function BellIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" />
      <path d="M13.73 21a2 2 0 0 1-3.46 0" />
    </svg>
  );
}

function ShieldIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
    </svg>
  );
}
```

- [ ] **Step 3: Kullanılmayan dosyayı sil**

```bash
cd uygulamalar/web
grep -rn "owner-shell-client" src/ app/ --include="*.tsx" --include="*.ts"
```

Expected: Sıfır sonuç (hiçbir yerden import edilmiyor). Sonra:

```bash
git rm src/ui/shell/owner-shell-client.tsx
```

- [ ] **Step 4: Typecheck + lint**

Run: `npm run typecheck && npm run lint`
Expected: Hata yok.

- [ ] **Step 5: Tarayıcıda manuel doğrulama**

`npm run dev`, `/sahip/gosterge-panosu`'na giriş yaparak git, sidebar'da 7 yeni item'ın (Rezervasyonlar, Fotoğraflar, Bildirimler, Pazarlama, Büyüme, Denetim Kaydı, Yapay Zeka Analizi) göründüğünü ve hepsinin doğru sayfaya gittiğini doğrula.

- [ ] **Step 6: Commit**

```bash
git add -A src/ui
git commit -m "feat(web): sahip nav'ına yeni taşınan ve önceden erişilemeyen sayfalar eklendi"
```

---

### Task 8: Cross-reference güncellemeleri (Faz 1 Task 17, genişletilmiş)

**Files:**
- Modify: `uygulamalar/web/app/forbidden/page.tsx:45,160`
- Modify: `uygulamalar/web/app/login/page.tsx:26`
- Modify: `uygulamalar/web/middleware.ts:52` (`OWNER_LOGIN_PATH`)

**Bağlam:** `app/giris/page.tsx` zaten var ve kanonik login sayfası olarak çalışıyor (Faz 1 Task 13 daha önce tamamlanmış görünüyor), ama `middleware.ts`'teki `OWNER_LOGIN_PATH` sabiti hâlâ `/owner/login`'e işaret ediyor — bu tutarsızlık burada düzeltiliyor.

- [ ] **Step 1: `forbidden/page.tsx`'i güncelle**

`app/forbidden/page.tsx:45` içindeki:
```tsx
              href="/owner/dashboard"
```
satırını:
```tsx
              href="/sahip/gosterge-panosu"
```
yap.

`app/forbidden/page.tsx:160` içindeki:
```tsx
                href="/owner/login"
```
satırını:
```tsx
                href="/giris"
```
yap.

- [ ] **Step 2: Kök `login/page.tsx`'i güncelle**

`app/login/page.tsx:26` içindeki:
```tsx
    ? `${panelBase.replace(/\/$/, '')}/isletme-giris?redirect=${encodeURIComponent('/owner/businesses')}`
```
satırını:
```tsx
    ? `${panelBase.replace(/\/$/, '')}/isletme-giris?redirect=${encodeURIComponent('/sahip/isletmeler')}`
```
yap.

- [ ] **Step 3: `middleware.ts`'te `OWNER_LOGIN_PATH`'i düzelt**

`middleware.ts:52` içindeki:
```ts
const OWNER_LOGIN_PATH = '/owner/login';
```
satırını:
```ts
const OWNER_LOGIN_PATH = '/giris';
```
yap. (Bu satır `guardPanelRoute` içinde girişsiz owner-route ziyaretçilerinin nereye yönlendirileceğini belirliyor — `/giris` zaten kanonik login sayfası, bu değişiklik onu gerçekten kullanılır hale getiriyor.)

- [ ] **Step 4: Repo genelinde kalan `/owner/` referanslarını tara**

```bash
cd uygulamalar/web
grep -rn "'/owner/\|\"/owner/\|\`/owner/" app src --include="*.ts" --include="*.tsx" | grep -v "app/owner/"
```

Expected: Sadece `next.config.mjs`'teki mevcut eski redirect kaynak path'leri (varsa) kalmalı — bunlara Task 9'da zaten dokunulacak. Bulunan başka her referansı aynı mantıkla (`/owner/X` → `/sahip/X` karşılığı, madde 9'daki tabloya bak) düzelt.

- [ ] **Step 5: Typecheck + lint**

Run: `npm run typecheck && npm run lint`
Expected: Hata yok.

- [ ] **Step 6: Commit**

```bash
git add app/forbidden app/login middleware.ts
git commit -m "fix(web): forbidden/login/middleware'deki owner referansları sahip'e ve giriş'e güncellendi"
```

---

### Task 9: Redirect'leri ekle (Faz 1 Task 18, resume)

**Files:**
- Modify: `uygulamalar/web/next.config.mjs`

- [ ] **Step 1: Mevcut `redirects()` array'ini oku**

`next.config.mjs`'in tam içeriğini oku (özellikle satır 76-81 civarındaki mevcut `/owner/qr/design`, `/owner/menu/editor`, `/owner/menu/section-editor` redirect'leri — bunlara dokunulmayacak, yeni kurallar bunların altına, aynı array'in sonuna eklenecek).

- [ ] **Step 2: Owner→sahip redirect'lerini array'in sonuna ekle**

`redirects()` fonksiyonunun döndürdüğü array'e şu girdileri ekle:

```js
      // Owner paneli Türkçeleştirme — eski İngilizce path'lerden yenilerine
      { source: '/owner', destination: '/sahip', permanent: true },
      { source: '/owner/login', destination: '/giris', permanent: true },
      { source: '/owner/dashboard', destination: '/sahip/gosterge-panosu', permanent: true },
      { source: '/owner/businesses', destination: '/sahip/isletmeler', permanent: true },
      { source: '/owner/businesses/new', destination: '/sahip/isletmeler/yeni', permanent: true },
      { source: '/owner/businesses/submissions', destination: '/sahip/isletmeler/basvurular', permanent: true },
      { source: '/owner/businesses/:id', destination: '/sahip/isletmeler/:id', permanent: true },
      { source: '/owner/menus', destination: '/sahip/menuler', permanent: true },
      { source: '/owner/menus/:menuId', destination: '/sahip/menuler/:menuId', permanent: true },
      { source: '/owner/menus/:menuId/edit', destination: '/sahip/menuler/:menuId/duzenle', permanent: true },
      { source: '/owner/menu/translations', destination: '/sahip/menu/ceviriler', permanent: true },
      { source: '/owner/photos', destination: '/sahip/fotograflar', permanent: true },
      { source: '/owner/reviews', destination: '/sahip/yorumlar', permanent: true },
      { source: '/owner/reservations', destination: '/sahip/rezervasyonlar', permanent: true },
      { source: '/owner/analytics', destination: '/sahip/analitik', permanent: true },
      { source: '/owner/marketing', destination: '/sahip/pazarlama', permanent: true },
      { source: '/owner/marketing/:path*', destination: '/sahip/pazarlama/:path*', permanent: true },
      { source: '/owner/qr', destination: '/sahip/karekod', permanent: true },
      { source: '/owner/notifications', destination: '/sahip/bildirimler', permanent: true },
      { source: '/owner/settings', destination: '/sahip/ayarlar', permanent: true },
      { source: '/owner/settings/domain', destination: '/sahip/ayarlar/alan-adi', permanent: true },
      { source: '/owner/settings/hours', destination: '/sahip/ayarlar/saatler', permanent: true },
      { source: '/owner/ai-analysis', destination: '/sahip/yapay-zeka-analizi', permanent: true },
      { source: '/owner/team', destination: '/sahip/ekip', permanent: true },
      { source: '/owner/trash', destination: '/sahip/cop-kutusu', permanent: true },
      { source: '/owner/price-suggestions', destination: '/sahip/fiyat-onerileri', permanent: true },
      { source: '/owner/growth', destination: '/sahip/buyume', permanent: true },
      { source: '/owner/audit', destination: '/sahip/denetim-kaydi', permanent: true },
      { source: '/owner/activity', destination: '/sahip/denetim-kaydi', permanent: true },
      { source: '/owner/requests', destination: '/sahip/istekler', permanent: true },
      { source: '/owner/suspended', destination: '/sahip/askiya-alinanlar', permanent: true },
      { source: '/owner/pricing', destination: '/sahip/fiyatlandirma', permanent: true },
      { source: '/owner/onboarding', destination: '/sahip/baslangic', permanent: true },
```

(Not: `/owner/activity` redirect'i orijinal Faz 1 planında sonradan kaldırılmıştı çünkü o sayfa bozuktu ve linksizdi — burada geri ekleniyor çünkü artık `/owner/activity/page.tsx` tamamen silinmiş durumda (Faz 1.1'de) ve `/owner/audit` üzerinden erişilen içerik `/sahip/denetim-kaydi`'ye taşındı; eski `/owner/activity` URL'sine hâlâ gelen (bookmarklanmış vb.) trafik olursa doğru yere düşsün diye eklendi.)

- [ ] **Step 3: Build ile redirect syntax'ını doğrula**

Run: `cd uygulamalar/web && npm run build`
Expected: Build hatasız tamamlanır.

- [ ] **Step 4: Manuel redirect testi**

`npm run dev` başlat, tarayıcıda `/owner/dashboard`, `/owner/businesses`, `/owner/audit` en az 3 eski URL'yi dene, her birinin doğru `/sahip/...` path'ine yönlendirdiğini doğrula.

- [ ] **Step 5: Commit**

```bash
git add next.config.mjs
git commit -m "feat(web): eski /owner/* path'lerinden yeni /sahip/* path'lerine kalıcı redirect eklendi"
```

---

### Task 10: `app/owner`'ı tamamen sil, middleware'i sadeleştir + subdomain rewrite'ı düzelt (Faz 1 Task 19, genişletilmiş)

**Files:**
- Delete: `app/owner/**` (kalan tüm dosyalar)
- Delete: `app/api/owner/**` (varsa kalan)
- Modify: `middleware.ts`

**⚠️ Riskli adım:** Bu task'ın Step 4'ü canlı `isletme.yeedoy.com` subdomain trafiğinin hedefini değiştiriyor. Dikkatli test şart (Step 6-7).

- [ ] **Step 1: `app/owner` altında kalan dosyaları listele**

```bash
cd uygulamalar/web
find app/owner -type f
```

Bu noktada Task 1-9'da ele alınmayan her dosyayı gözden geçir: her birinin `/sahip` tarafında bir karşılığı olduğunu (isim eşleşmesi + en azından temel işlevin var olduğunu, satır satır tam eşitlik gerekmez) doğrula. Beklenmedik/karşılığı olmayan bir dosya bulursan (Task 1-9'da öngörülmemiş), o dosyayı oku ve `/sahip` tarafında gerçekten karşılığı olup olmadığına karar ver — yoksa bu adımı durdur ve kullanıcıya danış (silmeden önce).

- [ ] **Step 2: Kalan her şeyi sil**

```bash
git rm -r app/owner
```

- [ ] **Step 3: `app/api/owner` altında kalanları kontrol et ve sil**

```bash
find app/api/owner -type f 2>/dev/null
```

Bulunan her dosya için, `/sunucu/sahip` karşılığının olduğunu ve hiçbir sahip sayfası tarafından artık çağrılmadığını doğrula:

```bash
grep -rn "/api/owner/" app/sahip
```

Expected: Sonuç boş. Sonra:

```bash
git rm -r app/api/owner
```

(Eğer `app/api/owner` hiç yoksa veya zaten boşsa bu adımı atla.)

- [ ] **Step 4: `middleware.ts`'i sadeleştir — guard mantığı**

`middleware.ts` içinde:
- `const OWNER_PREFIX = '/owner';` satırını sil (satır 41 civarı).
- `guardPanelRoute` içindeki (satır 57-60 civarı) şu bloğu:
  ```ts
  const OWNER_PUBLIC_PATHS = [OWNER_LOGIN_PATH, '/owner'];
  const isOwnerRoute =
    (pathname.startsWith(OWNER_PREFIX) || pathname.startsWith(SAHIP_PREFIX)) &&
    !OWNER_PUBLIC_PATHS.includes(pathname);
  ```
  şununla değiştir:
  ```ts
  const OWNER_PUBLIC_PATHS = [OWNER_LOGIN_PATH, '/sahip'];
  const isOwnerRoute =
    pathname.startsWith(SAHIP_PREFIX) && !OWNER_PUBLIC_PATHS.includes(pathname);
  ```

- [ ] **Step 5: `middleware.ts`'i sadeleştir — subdomain rewrite prefix'i**

`rewriteSubdomainPanel` fonksiyonu içinde (satır 31 civarı):
```ts
  const prefix = isOwnerHost ? '/owner' : '/admin';
```
satırını:
```ts
  const prefix = isOwnerHost ? '/sahip' : '/admin';
```
yap. (Admin tarafı bu planın kapsamı dışında, `/admin` olarak kalıyor.)

- [ ] **Step 6: Typecheck + lint + build**

Run: `npm run typecheck && npm run lint && npm run build`
Expected: Hepsi hatasız geçer.

- [ ] **Step 7: Subdomain rewrite'ı local'de doğrula**

```bash
npm run dev
```

Ayrı bir terminalde (veya aynı oturumda arka planda çalışırken):

```bash
curl -s -D - -o /dev/null --max-time 8 -H "Host: isletme.localhost:3000" http://localhost:3000/
```

Expected: Response header'larında bir rewrite/redirect belirtisi olmayabilir (rewrite şeffaf çalışır, URL bar değişmez) ama **500 hatası OLMAMALI** ve response `/sahip` içeriğini render etmeli (gövdede "Sahip" veya login sayfası HTML'i görünmeli, `/owner` değil). Eğer `OWNER_HOSTNAMES` env var'ı local'de `isletme.localhost` içermiyorsa bu adım anlamlı sonuç vermez — bu durumda en azından `middleware.ts`'in derlendiğini ve `rewriteSubdomainPanel` fonksiyonunun statik olarak doğru olduğunu (Step 6'daki typecheck/build) kanıt olarak kabul et, gerçek subdomain testini staging/prod deploy sonrası yapılacak manuel bir adım olarak not et.

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "chore(web): eski /owner ağacı tamamen kaldırıldı, middleware ve subdomain rewrite sahip'e göre sadeleştirildi

Canlı isletme.yeedoy.com subdomain rewrite'ı artık /owner yerine /sahip'e
rewrite ediyor. Bu, app/owner'ın tamamen silinmesiyle birlikte gereken
bir değişiklik - aksi halde subdomain 404 verirdi."
```

---

### Task 11: Final doğrulama (Faz 1 Task 20, resume)

**Files:** (değişiklik yok, sadece doğrulama)

- [ ] **Step 1: Tam otomatik doğrulama paketi**

Run: `cd uygulamalar/web && npm run typecheck && npm run lint && npm run test:unit && npm run build`
Expected: Hepsi başarılı.

- [ ] **Step 2: Manuel owner akışı — uçtan uca**

`npm run dev`, tarayıcıda:
1. Çıkış yapmış halde `/sahip`'e git → landing page görünür (veya `/giris`'e yönlenir, mevcut davranış neyse)
2. Giriş yap → `/sahip/gosterge-panosu`'na yönlenir
3. Sidebar'dan sırayla: İşletmeler → Menüler → Rezervasyonlar → Fotoğraflar → Analitik (owner'ın 18 Temmuz bölümleri + sahip'in Yoğun Saatler'i görünüyor mu) → Yorumlar → QR Kodlar → Pazarlama → Büyüme → Yapay Zeka Analizi → Ekip → Fiyat Önerileri → Grup İstekleri → Etkinlikler → Bildirimler → Denetim Kaydı (filtre/sayfalama çalışıyor mu, gerçek veri/boş-durum doğru render oluyor mu) → Çöp Kutusu → Ayarlar
4. Çıkış yap

- [ ] **Step 3: Redirect doğrulaması**

En az 5 eski `/owner/...` URL'sini (Task 9 Step 4'te test edilenlerden farklı) tarayıcıda dene, hepsinin doğru `/sahip/...`'e düştüğünü doğrula.

- [ ] **Step 4: Kalan referans taraması**

```bash
cd uygulamalar/web
grep -rn "/owner/\|app/owner\b" app src middleware.ts next.config.mjs --include="*.ts" --include="*.tsx" --include="*.mjs"
```

Expected: Sonuç boş olmalı, `next.config.mjs` içindeki `source: '/owner/...'` redirect kaynak path'leri hariç.

- [ ] **Step 5: Final commit (varsa küçük düzeltmeler)**

Eğer Step 1-4'te herhangi bir düzeltme yapıldıysa:

```bash
git add -A
git commit -m "fix(web): owner-sahip türkçeleştirme tamamlama final doğrulama düzeltmeleri"
```
