'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { X } from 'lucide-react';
import { ADMIN_PERMISSIONS, ADMIN_PERMISSION_GROUPS, type AdminPermissionKey } from '@/src/lib/admin-izinler';
import type { AdminRole } from './roller-yardimcilari';

export function YeniRolButonu({ variant = 'primary' }: { variant?: 'primary' | 'list' }) {
  const [open, setOpen] = useState(false);
  return (
    <>
      {variant === 'primary' ? (
        <button
          type="button"
          onClick={() => setOpen(true)}
          className="flex items-center gap-2 rounded-xl bg-primary px-4 py-2.5 text-sm font-extrabold text-white transition-opacity hover:opacity-90"
        >
          <PlusIcon /> Yeni Rol Oluştur
        </button>
      ) : (
        <button
          type="button"
          onClick={() => setOpen(true)}
          className="flex items-center gap-3 rounded-xl border border-border px-3 py-2.5 text-left transition-colors hover:border-primary/30 hover:bg-black/2"
        >
          <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-(--yd-color-primary)"><PlusIcon /></div>
          <div className="min-w-0">
            <p className="text-xs font-extrabold text-textStrong">Yeni Rol Oluştur</p>
            <p className="truncate text-[10px] text-muted">Sıfırdan yeni bir rol tanımlayın</p>
          </div>
        </button>
      )}
      {open && <RolModal onClose={() => setOpen(false)} />}
    </>
  );
}

export function EditRolButonu({ role }: { role: AdminRole }) {
  const [open, setOpen] = useState(false);
  return (
    <>
      <button
        type="button"
        onClick={() => setOpen(true)}
        title="Düzenle"
        className="rounded-lg border border-border px-2.5 py-1.5 text-xs font-bold text-textStrong transition-colors hover:border-primary/30 hover:text-primary"
      >
        Düzenle
      </button>
      {open && <RolModal onClose={() => setOpen(false)} role={role} />}
    </>
  );
}

function RolModal({ onClose, role }: { onClose: () => void; role?: AdminRole }) {
  const router = useRouter();
  const [pending, setPending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [name, setName] = useState(role?.name ?? '');
  const [description, setDescription] = useState(role?.description ?? '');
  const [isActive, setIsActive] = useState(role?.is_active ?? true);
  const [permissions, setPermissions] = useState<Set<AdminPermissionKey>>(new Set(role?.permissions ?? []));

  const readOnly = role?.is_system ?? false;

  function toggle(key: AdminPermissionKey) {
    setPermissions((prev) => {
      const s = new Set(prev);
      if (s.has(key)) s.delete(key); else s.add(key);
      return s;
    });
  }
  function toggleGroup(group: string, hepsi: boolean) {
    const keys = ADMIN_PERMISSIONS.filter((p) => p.group === group).map((p) => p.key);
    setPermissions((prev) => {
      const s = new Set(prev);
      keys.forEach((k) => { if (hepsi) s.add(k); else s.delete(k); });
      return s;
    });
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!name.trim() || readOnly) return;
    setPending(true);
    setError(null);
    try {
      const body = { name: name.trim(), description: description.trim() || undefined, permissions: Array.from(permissions) };
      const res = role
        ? await fetch('/sunucu/yonetici/roller', { method: 'PATCH', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ id: role.id, ...body, isActive }) })
        : await fetch('/sunucu/yonetici/roller', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) });
      const json = await res.json().catch(() => ({}));
      if (!res.ok) { setError(json.error ?? 'Hata oluştu'); return; }
      router.refresh();
      onClose();
    } catch {
      setError('Bağlantı hatası');
    } finally {
      setPending(false);
    }
  }

  return (
    <>
      <div className="fixed inset-0 z-40 bg-black/30" onClick={onClose} aria-hidden="true" />
      <div className="fixed left-1/2 top-1/2 z-50 w-full max-w-xl -translate-x-1/2 -translate-y-1/2 rounded-2xl border border-border bg-white p-6 shadow-2xl">
        <div className="mb-4 flex items-center justify-between">
          <h2 className="text-lg font-black text-textStrong">{role ? 'Rolü Düzenle' : 'Yeni Rol'}</h2>
          <button onClick={onClose} className="rounded-lg p-1.5 text-muted hover:bg-black/4 hover:text-textStrong" aria-label="Kapat">
            <X className="h-4 w-4" />
          </button>
        </div>

        {readOnly ? (
          <p className="rounded-xl border border-border bg-cardAlt px-4 py-3 text-sm text-muted">Sistem rolleri (Süper Admin) düzenlenemez.</p>
        ) : (
          <form onSubmit={handleSubmit} className="flex max-h-[70vh] flex-col gap-4 overflow-y-auto">
            <div className="flex flex-col gap-1.5">
              <label className="text-sm font-bold text-textStrong">Rol Adı</label>
              <input type="text" value={name} onChange={(e) => setName(e.target.value)} required maxLength={60} className="input-yd rounded-xl px-3 py-2.5 text-sm" placeholder="ör. Destek Ekibi" />
            </div>
            <div className="flex flex-col gap-1.5">
              <label className="text-sm font-bold text-textStrong">Açıklama</label>
              <input type="text" value={description} onChange={(e) => setDescription(e.target.value)} maxLength={200} className="input-yd rounded-xl px-3 py-2.5 text-sm" placeholder="Bu rol ne için kullanılıyor?" />
            </div>
            {role && (
              <label className="flex items-center gap-2 text-sm font-bold text-textStrong">
                <input type="checkbox" checked={isActive} onChange={(e) => setIsActive(e.target.checked)} className="h-4 w-4 rounded border-border" />
                Aktif
              </label>
            )}
            <div className="flex flex-col gap-3">
              <p className="text-sm font-bold text-textStrong">İzinler ({permissions.size} seçili)</p>
              {ADMIN_PERMISSION_GROUPS.map((group) => {
                const items = ADMIN_PERMISSIONS.filter((p) => p.group === group);
                const hepsiSecili = items.every((p) => permissions.has(p.key));
                return (
                  <div key={group} className="rounded-xl border border-border p-3">
                    <div className="mb-2 flex items-center justify-between">
                      <p className="text-xs font-extrabold uppercase tracking-wide text-muted">{group}</p>
                      <button type="button" onClick={() => toggleGroup(group, !hepsiSecili)} className="text-[11px] font-bold text-primary hover:underline">
                        {hepsiSecili ? 'Hiçbirini seçme' : 'Hepsini seç'}
                      </button>
                    </div>
                    <div className="grid grid-cols-2 gap-1.5 sm:grid-cols-3">
                      {items.map((p) => (
                        <label key={p.key} className="flex items-center gap-1.5 text-xs font-bold text-textStrong">
                          <input type="checkbox" checked={permissions.has(p.key)} onChange={() => toggle(p.key)} className="h-3.5 w-3.5 rounded border-border" />
                          {p.label}
                        </label>
                      ))}
                    </div>
                  </div>
                );
              })}
            </div>
            {error && <p className="text-sm font-bold text-danger">{error}</p>}
            <div className="flex justify-end gap-2">
              <button type="button" onClick={onClose} className="rounded-xl border border-border px-4 py-2.5 text-sm font-bold text-muted hover:text-textStrong">İptal</button>
              <button type="submit" disabled={pending} className="rounded-xl bg-primary px-4 py-2.5 text-sm font-bold text-white disabled:opacity-50">
                {pending ? 'Kaydediliyor…' : role ? 'Kaydet' : 'Rol Oluştur'}
              </button>
            </div>
          </form>
        )}
      </div>
    </>
  );
}

function PlusIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="12" y1="5" x2="12" y2="19" /><line x1="5" y1="12" x2="19" y2="12" /></svg>;
}
