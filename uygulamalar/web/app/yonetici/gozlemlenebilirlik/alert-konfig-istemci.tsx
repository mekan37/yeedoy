'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';

export interface AlertRule {
  id: string;
  name: string;
  metric: 'event_rate_1h' | 'rate_limit_events_1h' | 'active_users_24h';
  threshold: number;
  severity: 'info' | 'warning' | 'critical';
  enabled: boolean;
  notify_email: boolean;
  notify_slack: boolean;
}

const METRIC_LABELS: Record<AlertRule['metric'], string> = {
  event_rate_1h: 'Olay Sayısı (1s)',
  rate_limit_events_1h: 'Rate Limit Vakası (1s)',
  active_users_24h: 'Aktif Kullanıcı (24s)',
};

const SEVERITY_STYLE: Record<string, string> = {
  info: 'bg-blue-50 text-blue-700 border-blue-200',
  warning: 'bg-yellow-50 text-yellow-700 border-yellow-200',
  critical: 'bg-red-50 text-red-700 border-red-200',
};

const SEVERITY_LABEL: Record<string, string> = { info: 'Bilgi', warning: 'Uyarı', critical: 'Kritik' };

async function apiPost(body: Record<string, unknown>) {
  return fetch('/sunucu/yonetici/gozlemlenebilirlik', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
}

export function AlertKonfigIstemci({ rules, liveValues }: { rules: AlertRule[]; liveValues: Record<AlertRule['metric'], number> }) {
  const router = useRouter();
  const [pending, setPending] = useState<string | null>(null);
  const [showForm, setShowForm] = useState(false);
  const [name, setName] = useState('');
  const [metric, setMetric] = useState<AlertRule['metric']>('event_rate_1h');
  const [threshold, setThreshold] = useState(50);
  const [severity, setSeverity] = useState<AlertRule['severity']>('warning');

  async function toggleField(rule: AlertRule, field: 'enabled' | 'notify_email' | 'notify_slack') {
    setPending(rule.id);
    try {
      await apiPost({
        id: rule.id, name: rule.name, metric: rule.metric, threshold: rule.threshold, severity: rule.severity,
        enabled: field === 'enabled' ? !rule.enabled : rule.enabled,
        notifyEmail: field === 'notify_email' ? !rule.notify_email : rule.notify_email,
        notifySlack: field === 'notify_slack' ? !rule.notify_slack : rule.notify_slack,
      });
      router.refresh();
    } finally {
      setPending(null);
    }
  }

  async function updateThreshold(rule: AlertRule, value: number) {
    setPending(rule.id);
    try {
      await apiPost({
        id: rule.id, name: rule.name, metric: rule.metric, threshold: value, severity: rule.severity,
        enabled: rule.enabled, notifyEmail: rule.notify_email, notifySlack: rule.notify_slack,
      });
      router.refresh();
    } finally {
      setPending(null);
    }
  }

  async function remove(rule: AlertRule) {
    if (!confirm(`"${rule.name}" kuralı silinecek. Devam et?`)) return;
    setPending(rule.id);
    try {
      await fetch('/sunucu/yonetici/gozlemlenebilirlik', {
        method: 'DELETE',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id: rule.id }),
      });
      router.refresh();
    } finally {
      setPending(null);
    }
  }

  async function create(e: React.FormEvent) {
    e.preventDefault();
    if (!name.trim()) return;
    setPending('new');
    try {
      const res = await apiPost({ name: name.trim(), metric, threshold, severity, enabled: true, notifyEmail: false, notifySlack: false });
      if (res.ok) {
        setName('');
        setThreshold(50);
        setShowForm(false);
        router.refresh();
      }
    } finally {
      setPending(null);
    }
  }

  return (
    <div className="flex flex-col gap-4">
      <p className="text-sm text-muted">
        Platform olayları için uyarı eşiklerini yapılandırın. Eşik, gerçek zamanlı ölçülen değerle karşılaştırılır — aşılırsa kural Aktif Uyarılar listesinde görünür.
        Bildirim gönderimi (e-posta/Slack) henüz bağlı değil, yalnızca tercih olarak kaydedilir.
      </p>

      <div className="overflow-hidden rounded-xl border border-border">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-border bg-zinc-50 text-left">
              <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Kural</th>
              <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Eşik</th>
              <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Şu An</th>
              <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Önem</th>
              <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">E-posta</th>
              <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Slack</th>
              <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Aktif</th>
              <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted" />
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {rules.length === 0 && (
              <tr><td colSpan={8} className="px-4 py-6 text-center text-xs text-muted">Henüz uyarı kuralı yok.</td></tr>
            )}
            {rules.map((rule) => {
              const current = liveValues[rule.metric] ?? 0;
              const breached = rule.enabled && current >= rule.threshold;
              return (
                <tr key={rule.id} className={`${!rule.enabled ? 'opacity-50' : ''} hover:bg-black/2`}>
                  <td className="px-4 py-3">
                    <p className="font-bold text-textStrong">{rule.name}</p>
                    <p className="text-[10px] text-muted">{METRIC_LABELS[rule.metric]}</p>
                  </td>
                  <td className="px-4 py-3">
                    <input
                      type="number"
                      defaultValue={rule.threshold}
                      onBlur={(e) => { const v = parseInt(e.target.value, 10); if (!Number.isNaN(v) && v !== rule.threshold) updateThreshold(rule, v); }}
                      disabled={pending === rule.id}
                      className="w-20 rounded-lg border border-border bg-surface px-2 py-1 text-xs font-bold text-textStrong focus:border-primary focus:outline-hidden disabled:opacity-50"
                    />
                  </td>
                  <td className="px-4 py-3">
                    <span className={`text-xs font-extrabold ${breached ? 'text-danger' : 'text-textStrong'}`}>{current.toLocaleString('tr-TR')}</span>
                    {breached && <span className="ml-1.5 rounded-full bg-danger/10 px-1.5 py-0.5 text-[9px] font-extrabold text-danger">AŞILDI</span>}
                  </td>
                  <td className="px-4 py-3">
                    <span className={`inline-flex rounded-full border px-2 py-0.5 text-[10px] font-bold ${SEVERITY_STYLE[rule.severity]}`}>
                      {SEVERITY_LABEL[rule.severity]}
                    </span>
                  </td>
                  <td className="px-4 py-3">
                    <button
                      type="button"
                      onClick={() => toggleField(rule, 'notify_email')}
                      disabled={pending === rule.id}
                      className={`h-5 w-5 rounded border-2 transition-colors disabled:opacity-50 ${rule.notify_email ? 'border-primary bg-primary' : 'border-border bg-surface'}`}
                      aria-label="E-posta bildirimi"
                    >
                      {rule.notify_email && <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="3" className="mx-auto"><polyline points="20 6 9 17 4 12" /></svg>}
                    </button>
                  </td>
                  <td className="px-4 py-3">
                    <button
                      type="button"
                      onClick={() => toggleField(rule, 'notify_slack')}
                      disabled={pending === rule.id}
                      className={`h-5 w-5 rounded border-2 transition-colors disabled:opacity-50 ${rule.notify_slack ? 'border-primary bg-primary' : 'border-border bg-surface'}`}
                      aria-label="Slack bildirimi"
                    >
                      {rule.notify_slack && <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="3" className="mx-auto"><polyline points="20 6 9 17 4 12" /></svg>}
                    </button>
                  </td>
                  <td className="px-4 py-3">
                    <button
                      type="button"
                      onClick={() => toggleField(rule, 'enabled')}
                      disabled={pending === rule.id}
                      className={`relative h-5 w-9 rounded-full transition-colors disabled:opacity-50 ${rule.enabled ? 'bg-primary' : 'bg-zinc-300'}`}
                      aria-label={rule.enabled ? 'Devre dışı bırak' : 'Etkinleştir'}
                    >
                      <span className={`absolute top-0.5 h-4 w-4 rounded-full bg-white shadow-sm transition-transform ${rule.enabled ? 'translate-x-4' : 'translate-x-0.5'}`} />
                    </button>
                  </td>
                  <td className="px-4 py-3">
                    <button type="button" onClick={() => remove(rule)} disabled={pending === rule.id} className="text-xs font-bold text-danger hover:underline disabled:opacity-50">Sil</button>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>

      {showForm ? (
        <form onSubmit={create} className="flex flex-wrap items-end gap-3 rounded-xl border border-border p-3">
          <div className="flex flex-col gap-1">
            <label className="text-[11px] font-bold text-muted">Kural Adı</label>
            <input value={name} onChange={(e) => setName(e.target.value)} required maxLength={80} className="input-yd rounded-lg px-2.5 py-1.5 text-xs" placeholder="ör. Yüksek Rate Limit" />
          </div>
          <div className="flex flex-col gap-1">
            <label className="text-[11px] font-bold text-muted">Metrik</label>
            <select value={metric} onChange={(e) => setMetric(e.target.value as AlertRule['metric'])} className="input-yd rounded-lg px-2.5 py-1.5 text-xs">
              {Object.entries(METRIC_LABELS).map(([v, l]) => <option key={v} value={v}>{l}</option>)}
            </select>
          </div>
          <div className="flex flex-col gap-1">
            <label className="text-[11px] font-bold text-muted">Eşik</label>
            <input type="number" value={threshold} onChange={(e) => setThreshold(parseInt(e.target.value, 10) || 0)} min={0} className="input-yd w-24 rounded-lg px-2.5 py-1.5 text-xs" />
          </div>
          <div className="flex flex-col gap-1">
            <label className="text-[11px] font-bold text-muted">Önem</label>
            <select value={severity} onChange={(e) => setSeverity(e.target.value as AlertRule['severity'])} className="input-yd rounded-lg px-2.5 py-1.5 text-xs">
              {Object.entries(SEVERITY_LABEL).map(([v, l]) => <option key={v} value={v}>{l}</option>)}
            </select>
          </div>
          <button type="submit" disabled={pending === 'new'} className="rounded-xl bg-primary px-4 py-2 text-sm font-extrabold text-white disabled:opacity-50">
            {pending === 'new' ? 'Ekleniyor…' : 'Ekle'}
          </button>
          <button type="button" onClick={() => setShowForm(false)} className="rounded-xl border border-border px-4 py-2 text-sm font-bold text-muted hover:text-textStrong">İptal</button>
        </form>
      ) : (
        <button type="button" onClick={() => setShowForm(true)} className="self-start rounded-xl border border-border px-4 py-2 text-sm font-extrabold text-textStrong hover:border-primary/30 hover:text-primary">
          + Yeni Kural
        </button>
      )}
    </div>
  );
}
