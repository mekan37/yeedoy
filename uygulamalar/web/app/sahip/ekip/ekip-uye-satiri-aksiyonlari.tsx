'use client';

import { useState, useTransition } from 'react';
import { changeTeamMemberRole, removeTeamMember } from './ekip-islemleri';
import { ROLE_LABELS } from './ekip-sabitleri';

export function EkipUyeSatiriAksiyonlari({
  businessId,
  email,
  role,
  membershipId,
}: {
  businessId: string;
  email: string;
  role: string;
  membershipId: string | null;
}) {
  const [isPending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);

  function handleRoleChange(newRole: string) {
    setError(null);
    startTransition(async () => {
      const result = await changeTeamMemberRole(businessId, email, newRole);
      if (result?.error) setError(result.error);
    });
  }

  function handleRemove() {
    if (!membershipId) return;
    if (!confirm(`${email} ekipten kaldırılsın mı?`)) return;
    setError(null);
    startTransition(async () => {
      const result = await removeTeamMember(businessId, membershipId);
      if (result?.error) setError(result.error);
    });
  }

  return (
    <div className="flex items-center gap-2">
      <select
        value={role}
        disabled={isPending}
        onChange={(e) => handleRoleChange(e.target.value)}
        aria-label={`${email} rolü`}
        className="min-h-[32px] rounded-lg border border-border bg-bg px-2 text-[11px] font-[700] text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/30"
      >
        {Object.entries(ROLE_LABELS).filter(([key]) => key !== 'owner').map(([key, cfg]) => (
          <option key={key} value={key}>{cfg.label}</option>
        ))}
      </select>
      {membershipId && (
        <button
          type="button"
          disabled={isPending}
          onClick={handleRemove}
          aria-label={`${email} kaldır`}
          className="text-[11px] font-[700] text-danger hover:underline disabled:opacity-50"
        >
          Kaldır
        </button>
      )}
      {error && <span className="text-[11px] text-danger">{error}</span>}
    </div>
  );
}
