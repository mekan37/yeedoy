'use client';

import { useState } from 'react';

interface AlertRule {
  id: string;
  name: string;
  metric: string;
  threshold: number;
  window: string;
  severity: 'info' | 'warning' | 'critical';
  enabled: boolean;
  notifyEmail: boolean;
  notifySlack: boolean;
}

const DEFAULT_RULES: AlertRule[] = [
  { id: '1', name: 'Yüksek Hata Oranı', metric: 'error_rate_1h', threshold: 50, window: '1 saat', severity: 'critical', enabled: true, notifyEmail: true, notifySlack: false },
  { id: '2', name: 'Rate Limit Spike', metric: 'rate_limit_events_1h', threshold: 100, window: '1 saat', severity: 'warning', enabled: true, notifyEmail: true, notifySlack: true },
  { id: '3', name: 'Düşük Kullanıcı Aktivitesi', metric: 'active_users_24h', threshold: 10, window: '24 saat', severity: 'info', enabled: false, notifyEmail: false, notifySlack: false },
  { id: '4', name: 'Yüksek Sipariş Hacmi', metric: 'orders_1h', threshold: 200, window: '1 saat', severity: 'info', enabled: true, notifyEmail: false, notifySlack: true },
  { id: '5', name: 'Auth Hataları', metric: 'auth_errors_1h', threshold: 20, window: '1 saat', severity: 'critical', enabled: true, notifyEmail: true, notifySlack: true },
];

const SEVERITY_STYLE: Record<string, string> = {
  info:     'bg-blue-50 text-blue-700 border-blue-200',
  warning:  'bg-yellow-50 text-yellow-700 border-yellow-200',
  critical: 'bg-red-50 text-red-700 border-red-200',
};

const SEVERITY_LABEL: Record<string, string> = {
  info: 'Bilgi', warning: 'Uyarı', critical: 'Kritik',
};

export function AlertKonfigIstemci() {
  const [rules, setRules] = useState<AlertRule[]>(DEFAULT_RULES);
  const [saved, setSaved] = useState(false);

  const toggle = (id: string, field: keyof AlertRule) => {
    setRules(prev => prev.map(r => r.id === id ? { ...r, [field]: !r[field] } : r));
    setSaved(false);
  };

  const updateThreshold = (id: string, value: number) => {
    setRules(prev => prev.map(r => r.id === id ? { ...r, threshold: value } : r));
    setSaved(false);
  };

  const save = () => {
    // In production: POST to /sunucu/yonetici/alert-kurallar
    setSaved(true);
    setTimeout(() => setSaved(false), 3000);
  };

  return (
    <div className="flex flex-col gap-4">
      <p className="text-sm text-muted">Platform olayları için uyarı eşiklerini yapılandırın. Uyarılar e-posta veya Slack kanalına gönderilebilir.</p>

      <div className="overflow-hidden rounded-xl border border-border">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-border bg-zinc-50 text-left">
              <th className="px-4 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Kural</th>
              <th className="px-4 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Eşik</th>
              <th className="px-4 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Önem</th>
              <th className="px-4 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">E-posta</th>
              <th className="px-4 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Slack</th>
              <th className="px-4 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Aktif</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {rules.map(rule => (
              <tr key={rule.id} className={`${!rule.enabled ? 'opacity-50' : ''} hover:bg-black/[0.02]`}>
                <td className="px-4 py-3">
                  <p className="font-[700] text-textStrong">{rule.name}</p>
                  <p className="text-[10px] text-muted">{rule.metric} · {rule.window}</p>
                </td>
                <td className="px-4 py-3">
                  <input
                    type="number"
                    value={rule.threshold}
                    onChange={e => updateThreshold(rule.id, parseInt(e.target.value) || 0)}
                    className="w-20 rounded-lg border border-border bg-surface px-2 py-1 text-xs font-[700] text-textStrong focus:border-primary focus:outline-none"
                  />
                </td>
                <td className="px-4 py-3">
                  <span className={`inline-flex rounded-full border px-2 py-0.5 text-[10px] font-[700] ${SEVERITY_STYLE[rule.severity]}`}>
                    {SEVERITY_LABEL[rule.severity]}
                  </span>
                </td>
                <td className="px-4 py-3">
                  <button
                    onClick={() => toggle(rule.id, 'notifyEmail')}
                    className={`h-5 w-5 rounded border-2 transition-colors ${rule.notifyEmail ? 'border-primary bg-primary' : 'border-border bg-surface'}`}
                    aria-label="E-posta bildirimi"
                  >
                    {rule.notifyEmail && (
                      <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="3" className="mx-auto">
                        <polyline points="20 6 9 17 4 12" />
                      </svg>
                    )}
                  </button>
                </td>
                <td className="px-4 py-3">
                  <button
                    onClick={() => toggle(rule.id, 'notifySlack')}
                    className={`h-5 w-5 rounded border-2 transition-colors ${rule.notifySlack ? 'border-primary bg-primary' : 'border-border bg-surface'}`}
                    aria-label="Slack bildirimi"
                  >
                    {rule.notifySlack && (
                      <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="3" className="mx-auto">
                        <polyline points="20 6 9 17 4 12" />
                      </svg>
                    )}
                  </button>
                </td>
                <td className="px-4 py-3">
                  <button
                    onClick={() => toggle(rule.id, 'enabled')}
                    className={`relative h-5 w-9 rounded-full transition-colors ${rule.enabled ? 'bg-primary' : 'bg-zinc-300'}`}
                    aria-label={rule.enabled ? 'Devre dışı bırak' : 'Etkinleştir'}
                  >
                    <span className={`absolute top-0.5 h-4 w-4 rounded-full bg-white shadow transition-transform ${rule.enabled ? 'translate-x-4' : 'translate-x-0.5'}`} />
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="flex items-center gap-3">
        <button
          onClick={save}
          className="rounded-xl bg-primary px-4 py-2 text-sm font-[800] text-white hover:bg-primary/90"
        >
          {saved ? '✓ Kaydedildi' : 'Kaydet'}
        </button>
        <p className="text-xs text-muted">Uyarılar için Slack Webhook URL ve e-posta ayarlarını Sistem Ayarları bölümünden yapılandırın.</p>
      </div>
    </div>
  );
}
