'use client';

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';

interface ABTest {
  id: string; name: string; description: string; enabled: boolean;
  rollout_percent: number; environment: string; created_at: string; updated_at: string;
  impressions_a?: number; impressions_b?: number;
  conversions_a?: number; conversions_b?: number;
  winner?: 'a' | 'b' | null;
}

const PREDEFINED_TESTS = [
  { name: 'ab_homepage_hero', description: 'Ana sayfa hero banner varyantı (A: mevcut, B: yeni tasarım)' },
  { name: 'ab_onboarding_flow', description: 'Onboarding akışı (A: 3-adım, B: tek sayfa)' },
  { name: 'ab_price_display', description: 'Fiyat gösterimi (A: liste, B: kart + sparkline)' },
  { name: 'ab_checkin_cta', description: 'Check-in buton konumu (A: üst, B: alt sabit)' },
  { name: 'ab_loyalty_nudge', description: 'Sadakat kartı promosyon zamanlaması (A: hemen, B: 2. ziyarette)' },
];

function convRate(conversions: number, impressions: number): number {
  return impressions > 0 ? Math.round((conversions / impressions) * 1000) / 10 : 0;
}

function significanceBadge(ca: number, ia: number, cb: number, ib: number): { label: string; winner: 'a' | 'b' | null; color: string } | null {
  if (ia < 100 || ib < 100) return null;
  const ra = ca / ia; const rb = cb / ib;
  const diff = Math.abs(ra - rb);
  if (diff < 0.005) return { label: 'İstatistiksel fark yok', winner: null, color: 'text-zinc-500 bg-zinc-100' };
  const winner = rb > ra ? 'b' : 'a';
  const lift = ra > 0 ? Math.round(((rb - ra) / ra) * 100) : 0;
  const significant = (ia + ib) > 500 && Math.abs(lift) > 5;
  if (!significant) return { label: 'Veri toplaniyor…', winner: null, color: 'text-yellow-600 bg-yellow-50' };
  return {
    label: `${winner.toUpperCase()} kazanıyor +%${Math.abs(lift)} lift`,
    winner,
    color: 'text-green-700 bg-green-50',
  };
}

async function createAbTest(name: string, description: string, rollout: number, environment: string) {
  await fetch('/sunucu/yonetici/ab-test', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ name, description, rolloutPercent: rollout, environment }),
  });
}

async function toggleAbTest(id: string, enabled: boolean) {
  await fetch('/sunucu/yonetici/ab-test', {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ id, enabled }),
  });
}

async function declareWinner(id: string, winner: 'a' | 'b') {
  await fetch('/sunucu/yonetici/ab-test', {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ id, winner }),
  });
}

export function AbTestYonetici({ tests, totalUsers }: { tests: ABTest[]; totalUsers: number }) {
  const router = useRouter();
  const [isPending, startTransition] = useTransition();
  const [showCreate, setShowCreate] = useState(false);
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [rollout, setRollout] = useState(10);
  const [environment, setEnvironment] = useState<'staging' | 'production'>('staging');
  const [error, setError] = useState('');
  const [tab, setTab] = useState<'active' | 'all'>('active');
  const [expanded, setExpanded] = useState<string | null>(null);

  const filtered = tab === 'active' ? tests.filter(t => t.enabled) : tests;

  const create = () => {
    if (!name.trim()) { setError('Test adı zorunludur'); return; }
    if (!name.startsWith('ab_')) { setError('Test adı "ab_" ile başlamalıdır'); return; }
    setError('');
    startTransition(async () => {
      await createAbTest(name.trim(), description.trim(), rollout, environment);
      setName(''); setDescription(''); setRollout(10); setShowCreate(false);
      router.refresh();
    });
  };

  const toggle = (id: string, current: boolean) => {
    startTransition(async () => {
      await toggleAbTest(id, !current);
      router.refresh();
    });
  };

  const setWinner = (id: string, winner: 'a' | 'b') => {
    startTransition(async () => {
      await declareWinner(id, winner);
      router.refresh();
    });
  };

  // Summary stats
  const activeCount = tests.filter(t => t.enabled).length;
  const completedCount = tests.filter(t => t.winner).length;
  const pendingData = tests.filter(t => t.enabled && !t.winner && (t.impressions_a ?? 0) + (t.impressions_b ?? 0) < 200).length;

  return (
    <div className="flex flex-col gap-4">
      {/* Summary */}
      <div className="grid grid-cols-3 gap-3">
        <div className="rounded-xl border border-border bg-surface p-3">
          <p className="text-[10px] font-[700] uppercase tracking-wide text-muted">Aktif Test</p>
          <p className="mt-0.5 text-xl font-[900] text-primary">{activeCount}</p>
        </div>
        <div className="rounded-xl border border-border bg-surface p-3">
          <p className="text-[10px] font-[700] uppercase tracking-wide text-muted">Tamamlanan</p>
          <p className="mt-0.5 text-xl font-[900] text-green-600">{completedCount}</p>
        </div>
        <div className="rounded-xl border border-border bg-surface p-3">
          <p className="text-[10px] font-[700] uppercase tracking-wide text-muted">Veri Bekliyor</p>
          <p className="mt-0.5 text-xl font-[900] text-yellow-600">{pendingData}</p>
        </div>
      </div>

      {/* Create Button */}
      <div className="flex items-center justify-between">
        <div className="flex gap-1 rounded-xl bg-zinc-100 p-1 dark:bg-zinc-800">
          {(['active', 'all'] as const).map(t => (
            <button key={t} onClick={() => setTab(t)} className={`rounded-lg px-4 py-1.5 text-sm font-[700] transition-colors ${tab === t ? 'bg-white text-textStrong shadow dark:bg-zinc-700' : 'text-muted'}`}>
              {t === 'active' ? `Aktif (${tests.filter(t => t.enabled).length})` : `Tümü (${tests.length})`}
            </button>
          ))}
        </div>
        <button
          onClick={() => setShowCreate(!showCreate)}
          className="rounded-xl bg-primary px-4 py-2 text-sm font-[800] text-white hover:bg-primary/90"
        >
          + Yeni Test
        </button>
      </div>

      {/* Create Form */}
      {showCreate && (
        <div className="rounded-2xl border border-primary/30 bg-primary/5 p-5">
          <p className="mb-4 font-[800] text-textStrong">Yeni A/B Test Oluştur</p>

          <div className="mb-3">
            <p className="mb-2 text-xs font-[700] text-muted">Hazır Şablonlar</p>
            <div className="flex flex-wrap gap-2">
              {PREDEFINED_TESTS.map(pt => (
                <button key={pt.name} onClick={() => { setName(pt.name); setDescription(pt.description); }}
                  className="rounded-lg border border-border bg-surface px-2.5 py-1 text-xs font-[600] text-muted hover:border-primary hover:text-primary">
                  {pt.name.replace('ab_', '')}
                </button>
              ))}
            </div>
          </div>

          <div className="flex flex-col gap-3">
            <div>
              <label className="mb-1 block text-xs font-[700] text-muted">Test Adı (ab_ ile başlamalı)</label>
              <input value={name} onChange={e => setName(e.target.value)} placeholder="ab_ornek_test"
                className="w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm focus:border-primary focus:outline-none" />
            </div>
            <div>
              <label className="mb-1 block text-xs font-[700] text-muted">Açıklama (A varyantı vs B varyantı)</label>
              <input value={description} onChange={e => setDescription(e.target.value)} placeholder="A: mevcut tasarım, B: yeni deneme"
                className="w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm focus:border-primary focus:outline-none" />
            </div>
            <div className="flex gap-4">
              <div className="flex-1">
                <label className="mb-1 block text-xs font-[700] text-muted">Yayılım Oranı: %{rollout} (~{Math.round(totalUsers * rollout / 100).toLocaleString('tr-TR')} kullanıcı)</label>
                <input type="range" min={1} max={100} value={rollout} onChange={e => setRollout(+e.target.value)} className="w-full" />
                <div className="flex justify-between text-[10px] text-muted">
                  <span>%1</span><span>%50</span><span>%100</span>
                </div>
              </div>
              <div>
                <label className="mb-1 block text-xs font-[700] text-muted">Ortam</label>
                <select value={environment} onChange={e => setEnvironment(e.target.value as 'staging' | 'production')}
                  className="rounded-lg border border-border bg-surface px-3 py-2 text-sm focus:border-primary focus:outline-none">
                  <option value="staging">Staging</option>
                  <option value="production">Production</option>
                </select>
              </div>
            </div>
            {error && <p className="text-xs font-[700] text-red-600">{error}</p>}
            <div className="flex gap-2">
              <button onClick={create} disabled={isPending}
                className="rounded-lg bg-primary px-4 py-2 text-sm font-[800] text-white hover:bg-primary/90 disabled:opacity-50">
                {isPending ? 'Oluşturuluyor…' : 'Oluştur'}
              </button>
              <button onClick={() => setShowCreate(false)} className="rounded-lg border border-border px-4 py-2 text-sm font-[700] text-muted hover:text-textStrong">İptal</button>
            </div>
          </div>
        </div>
      )}

      {/* Tests List */}
      <div className="rounded-xl border border-border overflow-hidden">
        {filtered.length === 0 ? (
          <div className="flex flex-col items-center gap-3 py-16">
            <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" className="text-muted"><path d="M9 3H5a2 2 0 0 0-2 2v4m6-6h10a2 2 0 0 1 2 2v4M9 3v18m0 0h10a2 2 0 0 0 2-2V9M9 21H5a2 2 0 0 1-2-2V9m0 0h18" /></svg>
            <p className="text-sm text-muted">Henüz A/B test yok</p>
          </div>
        ) : (
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-border text-left bg-zinc-50 dark:bg-zinc-900/40">
                <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Test Adı</th>
                <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Açıklama</th>
                <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Yayılım</th>
                <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Ortam</th>
                <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Sonuç</th>
                <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Durum</th>
                <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted" />
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {filtered.map(test => {
                const ia = test.impressions_a ?? 0; const ib = test.impressions_b ?? 0;
                const ca = test.conversions_a ?? 0; const cb = test.conversions_b ?? 0;
                const rateA = convRate(ca, ia); const rateB = convRate(cb, ib);
                const sig = significanceBadge(ca, ia, cb, ib);
                const durationDays = Math.ceil((Date.now() - new Date(test.created_at).getTime()) / 86_400_000);
                const isExpanded = expanded === test.id;

                return (
                  <>
                    <tr key={test.id} className="hover:bg-black/[0.02] cursor-pointer" onClick={() => setExpanded(isExpanded ? null : test.id)}>
                      <td className="px-5 py-3 font-[800] text-primary">{test.name}</td>
                      <td className="px-5 py-3 max-w-xs">
                        <p className="line-clamp-2 text-xs text-muted">{test.description}</p>
                      </td>
                      <td className="px-5 py-3">
                        <div className="flex items-center gap-2">
                          <div className="h-1.5 w-20 overflow-hidden rounded-full bg-zinc-100">
                            <div className="h-full rounded-full bg-primary" style={{ width: `${test.rollout_percent}%` }} />
                          </div>
                          <span className="text-xs font-[700] text-textStrong">%{test.rollout_percent}</span>
                        </div>
                      </td>
                      <td className="px-5 py-3">
                        <span className={`inline-flex rounded-full px-2 py-0.5 text-[10px] font-[700] ${test.environment === 'production' ? 'bg-red-50 text-red-700' : 'bg-blue-50 text-blue-700'}`}>
                          {test.environment}
                        </span>
                      </td>
                      <td className="px-5 py-3">
                        {sig ? (
                          <span className={`inline-flex rounded-full px-2 py-0.5 text-[10px] font-[700] ${sig.color}`}>
                            {sig.label}
                          </span>
                        ) : (
                          <span className="text-[10px] text-muted">{durationDays}g sürdü</span>
                        )}
                      </td>
                      <td className="px-5 py-3">
                        <span className={`inline-flex rounded-full px-2 py-0.5 text-[10px] font-[700] ${test.winner ? 'bg-purple-50 text-purple-700' : test.enabled ? 'bg-green-50 text-green-700' : 'bg-zinc-100 text-zinc-500'}`}>
                          {test.winner ? `${test.winner.toUpperCase()} Kazandı` : test.enabled ? 'Aktif' : 'Pasif'}
                        </span>
                      </td>
                      <td className="px-5 py-3">
                        <div className="flex items-center gap-1">
                          <button
                            disabled={isPending}
                            onClick={e => { e.stopPropagation(); toggle(test.id, test.enabled); }}
                            className={`rounded-lg px-3 py-1 text-xs font-[700] ${test.enabled ? 'bg-zinc-100 text-zinc-600 hover:bg-zinc-200' : 'bg-green-100 text-green-700 hover:bg-green-200'} disabled:opacity-50`}
                          >
                            {test.enabled ? 'Durdur' : 'Başlat'}
                          </button>
                          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className={`text-muted transition-transform ${isExpanded ? 'rotate-180' : ''}`}>
                            <polyline points="6 9 12 15 18 9" />
                          </svg>
                        </div>
                      </td>
                    </tr>

                    {/* Expanded: variant results */}
                    {isExpanded && (
                      <tr key={`${test.id}-detail`} className="bg-zinc-50 dark:bg-zinc-900/20">
                        <td colSpan={7} className="px-5 py-4">
                          <div className="flex flex-col gap-4">
                            <p className="text-[10px] font-[800] uppercase tracking-wide text-muted">Varyant Sonuçları</p>
                            <div className="grid grid-cols-2 gap-4">
                              {/* Variant A */}
                              <div className={`rounded-xl border p-4 ${sig?.winner === 'a' ? 'border-green-300 bg-green-50' : 'border-border bg-surface'}`}>
                                <div className="flex items-center justify-between mb-2">
                                  <span className="text-xs font-[800] text-textStrong">Varyant A (Kontrol)</span>
                                  {sig?.winner === 'a' && <span className="rounded-full bg-green-600 px-2 py-0.5 text-[9px] font-[800] text-white">🏆 KAZANAN</span>}
                                </div>
                                <div className="grid grid-cols-3 gap-2 text-center">
                                  <div>
                                    <p className="text-[10px] text-muted">Görüntülenme</p>
                                    <p className="text-lg font-[900] text-textStrong">{ia.toLocaleString('tr-TR')}</p>
                                  </div>
                                  <div>
                                    <p className="text-[10px] text-muted">Dönüşüm</p>
                                    <p className="text-lg font-[900] text-textStrong">{ca.toLocaleString('tr-TR')}</p>
                                  </div>
                                  <div>
                                    <p className="text-[10px] text-muted">Oran</p>
                                    <p className="text-lg font-[900] text-primary">%{rateA}</p>
                                  </div>
                                </div>
                                {ia > 0 && (
                                  <div className="mt-2 overflow-hidden rounded-full bg-zinc-200 h-1.5">
                                    <div className="h-full rounded-full bg-primary" style={{ width: `${Math.min(rateA * 5, 100)}%` }} />
                                  </div>
                                )}
                              </div>

                              {/* Variant B */}
                              <div className={`rounded-xl border p-4 ${sig?.winner === 'b' ? 'border-green-300 bg-green-50' : 'border-border bg-surface'}`}>
                                <div className="flex items-center justify-between mb-2">
                                  <span className="text-xs font-[800] text-textStrong">Varyant B (Deney)</span>
                                  {sig?.winner === 'b' && <span className="rounded-full bg-green-600 px-2 py-0.5 text-[9px] font-[800] text-white">🏆 KAZANAN</span>}
                                </div>
                                <div className="grid grid-cols-3 gap-2 text-center">
                                  <div>
                                    <p className="text-[10px] text-muted">Görüntülenme</p>
                                    <p className="text-lg font-[900] text-textStrong">{ib.toLocaleString('tr-TR')}</p>
                                  </div>
                                  <div>
                                    <p className="text-[10px] text-muted">Dönüşüm</p>
                                    <p className="text-lg font-[900] text-textStrong">{cb.toLocaleString('tr-TR')}</p>
                                  </div>
                                  <div>
                                    <p className="text-[10px] text-muted">Oran</p>
                                    <p className="text-lg font-[900] text-primary">%{rateB}</p>
                                  </div>
                                </div>
                                {ib > 0 && (
                                  <div className="mt-2 overflow-hidden rounded-full bg-zinc-200 h-1.5">
                                    <div className="h-full rounded-full bg-primary" style={{ width: `${Math.min(rateB * 5, 100)}%` }} />
                                  </div>
                                )}
                              </div>
                            </div>

                            {/* Statistical significance */}
                            {sig && (
                              <div className={`rounded-xl p-3 ${sig.color}`}>
                                <p className="text-xs font-[800]">📊 {sig.label}</p>
                                <p className="mt-0.5 text-[10px] opacity-80">
                                  Toplam görüntülenme: {(ia + ib).toLocaleString('tr-TR')} · Test süresi: {durationDays} gün
                                </p>
                              </div>
                            )}

                            {/* Winner declaration */}
                            {test.enabled && !test.winner && sig?.winner && (
                              <div className="flex gap-2">
                                <button
                                  disabled={isPending}
                                  onClick={() => setWinner(test.id, sig.winner!)}
                                  className="rounded-lg bg-green-600 px-4 py-2 text-xs font-[800] text-white hover:bg-green-700 disabled:opacity-50"
                                >
                                  {sig.winner.toUpperCase()} Varyantını Kazanan İlan Et
                                </button>
                                <button
                                  disabled={isPending}
                                  onClick={() => toggle(test.id, true)}
                                  className="rounded-lg border border-border px-4 py-2 text-xs font-[700] text-muted hover:text-textStrong disabled:opacity-50"
                                >
                                  Testi Durdur
                                </button>
                              </div>
                            )}
                          </div>
                        </td>
                      </tr>
                    )}
                  </>
                );
              })}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
