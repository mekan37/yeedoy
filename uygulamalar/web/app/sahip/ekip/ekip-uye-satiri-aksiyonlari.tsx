'use client';

import { useEffect, useRef, useState, useTransition } from 'react';
import { changeTeamMemberRole, removeTeamMember } from './ekip-islemleri';
import type { EkipRolu } from './ekip-yetkiler';

const ROLE_OPTIONS: { value: EkipRolu; label: string }[] = [
  { value: 'manager', label: 'Yönetici' },
  { value: 'editor', label: 'Editör' },
  { value: 'staff', label: 'Personel' },
  { value: 'viewer', label: 'Kısıtlı' },
];

export function EkipUyeSatiriAksiyonlari({
  businessId,
  email,
  role,
  membershipId,
  onRemoved,
  onRoleChanged,
}: {
  businessId: string;
  email: string;
  role: EkipRolu;
  membershipId: string | null;
  onRemoved: () => void;
  onRoleChanged: (newRole: EkipRolu) => void;
}) {
  const [open, setOpen] = useState(false);
  const [isPending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    function onPointerDown(e: PointerEvent) {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false);
    }
    document.addEventListener('pointerdown', onPointerDown);
    return () => document.removeEventListener('pointerdown', onPointerDown);
  }, []);

  function handleRoleChange(newRole: EkipRolu) {
    setError(null);
    setOpen(false);
    startTransition(async () => {
      const result = await changeTeamMemberRole(businessId, email, newRole);
      if (result?.error) setError(result.error);
      else onRoleChanged(newRole);
    });
  }

  function handleRemove() {
    if (!membershipId) return;
    if (!confirm(`${email} ekipten kaldırılsın mı?`)) return;
    setError(null);
    setOpen(false);
    startTransition(async () => {
      const result = await removeTeamMember(businessId, membershipId);
      if (result?.error) setError(result.error);
      else onRemoved();
    });
  }

  return (
    <div ref={ref} className="relative inline-flex flex-col items-end gap-1">
      <button
        type="button"
        disabled={isPending}
        onClick={() => setOpen((v) => !v)}
        aria-haspopup="true"
        aria-expanded={open}
        aria-label={`${email} için işlemler`}
        className="flex h-8 w-8 items-center justify-center rounded-lg text-muted transition-colors hover:bg-black/6 hover:text-textStrong disabled:opacity-50"
      >
        <DotsIcon />
      </button>

      {open && (
        <div className="absolute right-0 top-full z-20 mt-1 w-48 overflow-hidden rounded-xl border border-border bg-card py-1 shadow-yd2">
          <p className="px-3 py-1.5 text-[10px] font-extrabold uppercase tracking-wide text-muted">Rolü değiştir</p>
          {ROLE_OPTIONS.map((opt) => (
            <button
              key={opt.value}
              type="button"
              disabled={opt.value === role}
              onClick={() => handleRoleChange(opt.value)}
              className="block w-full px-3 py-2 text-left text-sm font-semibold text-textStrong hover:bg-black/4 disabled:cursor-default disabled:text-muted disabled:hover:bg-transparent"
            >
              {opt.label}{opt.value === role ? ' (mevcut)' : ''}
            </button>
          ))}
          {membershipId && (
            <>
              <div className="my-1 border-t border-border" />
              <button
                type="button"
                onClick={handleRemove}
                className="block w-full px-3 py-2 text-left text-sm font-semibold text-danger hover:bg-red-50"
              >
                Ekipten Kaldır
              </button>
            </>
          )}
        </div>
      )}

      {error && <span className="text-[11px] font-bold text-danger">{error}</span>}
    </div>
  );
}

function DotsIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
      <circle cx="12" cy="5" r="1.5" />
      <circle cx="12" cy="12" r="1.5" />
      <circle cx="12" cy="19" r="1.5" />
    </svg>
  );
}
