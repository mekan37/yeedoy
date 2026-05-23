'use client';

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';

const ASSIGNABLE_ROLES = [
  { value: 'user', label: 'Kullanıcı' },
  { value: 'community_mod', label: 'Moderatör' },
  { value: 'admin', label: 'Admin' },
];

export function RolDegistirIstemci({
  userId,
  currentRole,
  roleMap,
}: {
  userId: string;
  currentRole: string;
  roleMap: Record<string, { label: string; className: string }>;
}) {
  const router = useRouter();
  const [isPending, startTransition] = useTransition();
  const [open, setOpen] = useState(false);
  const [role, setRole] = useState(currentRole);

  const info = roleMap[role] ?? roleMap['user'];

  const changeRole = (newRole: string) => {
    if (newRole === role) { setOpen(false); return; }
    startTransition(async () => {
      await fetch('/sunucu/yonetici/kullanici-rol', {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ userId, role: newRole }),
      });
      setRole(newRole);
      setOpen(false);
      router.refresh();
    });
  };

  // Don't allow editing super_admin role
  if (currentRole === 'super_admin') {
    return (
      <span className={`rounded-full px-2 py-0.5 text-[10px] font-[800] ${info.className}`}>
        {info.label}
      </span>
    );
  }

  return (
    <div className="relative">
      <button
        onClick={() => setOpen(!open)}
        disabled={isPending}
        className={`inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-[10px] font-[800] transition-opacity disabled:opacity-50 ${info.className}`}
      >
        {isPending ? '…' : info.label}
        <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
          <polyline points="6 9 12 15 18 9" />
        </svg>
      </button>

      {open && (
        <>
          <div className="fixed inset-0 z-10" onClick={() => setOpen(false)} />
          <div className="absolute left-0 top-full z-20 mt-1 w-36 overflow-hidden rounded-xl border border-border bg-card shadow-yd2">
            {ASSIGNABLE_ROLES.map(r => (
              <button
                key={r.value}
                onClick={() => changeRole(r.value)}
                className={`flex w-full items-center gap-2 px-3 py-2 text-left text-xs font-[700] transition-colors hover:bg-black/[0.04] ${r.value === role ? 'text-primary' : 'text-textStrong'}`}
              >
                {r.value === role && (
                  <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><polyline points="20 6 9 17 4 12" /></svg>
                )}
                {r.value !== role && <span className="w-3" />}
                {r.label}
              </button>
            ))}
          </div>
        </>
      )}
    </div>
  );
}
