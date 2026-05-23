'use client';

import { useState, useEffect, useCallback } from 'react';
import { clsx } from 'clsx';

interface Order {
  id: string;
  table_number: string;
  items_json: Array<{ name: string; qty: number; note?: string }>;
  customer_note: string | null;
  status: 'pending' | 'seen' | 'done';
  created_at: string;
  businessName: string;
}

export function SiparisYonetimi({ orders: initial }: { orders: Order[] }) {
  const [orders, setOrders] = useState<Order[]>(initial);
  const [loading, setLoading] = useState<string | null>(null);
  const [lastRefresh, setLastRefresh] = useState(new Date());
  const [autoRefresh, setAutoRefresh] = useState(true);
  const [prevPendingCount, setPrevPendingCount] = useState(initial.filter(o => o.status === 'pending').length);

  const refreshOrders = useCallback(async () => {
    try {
      const res = await fetch('/sunucu/sahip/siparis-listesi', { cache: 'no-store' });
      if (res.ok) {
        const data = await res.json() as { orders: Order[] };
        const newOrders = data.orders ?? [];
        const newPendingCount = newOrders.filter(o => o.status === 'pending').length;

        // Browser notification on new order
        if (newPendingCount > prevPendingCount && 'Notification' in window && Notification.permission === 'granted') {
          new Notification('Yeni Sipariş!', {
            body: `${newPendingCount - prevPendingCount} yeni sipariş geldi`,
            icon: '/favicon.svg',
          });
        }
        setPrevPendingCount(newPendingCount);
        setOrders(newOrders);
        setLastRefresh(new Date());
      }
    } catch {}
  }, [prevPendingCount]);

  useEffect(() => {
    if (!autoRefresh) return;
    const interval = setInterval(refreshOrders, 30000); // 30s auto-refresh
    return () => clearInterval(interval);
  }, [autoRefresh, refreshOrders]);

  // Request notification permission
  useEffect(() => {
    if ('Notification' in window && Notification.permission === 'default') {
      Notification.requestPermission();
    }
  }, []);

  async function updateStatus(orderId: string, status: 'seen' | 'done') {
    setLoading(orderId);
    try {
      const res = await fetch('/sunucu/masa-siparisi/durum', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ orderId, status }),
      });
      if (res.ok) {
        setOrders((prev) =>
          status === 'done'
            ? prev.filter((o) => o.id !== orderId)
            : prev.map((o) => o.id === orderId ? { ...o, status } : o),
        );
      }
    } finally {
      setLoading(null);
    }
  }

  const pending = orders.filter((o) => o.status === 'pending');
  const seen = orders.filter((o) => o.status === 'seen');

  function printOrder(order: Order) {
    const win = window.open('', '_blank', 'width=400,height=600');
    if (!win) return;
    win.document.write(`
      <html><head><title>Sipariş #${order.table_number}</title>
      <style>body{font-family:monospace;padding:16px}h2{font-size:18px}ul{margin:8px 0}li{margin:4px 0}hr{margin:8px 0}</style>
      </head><body>
      <h2>Masa ${order.table_number}</h2>
      <p>${new Date(order.created_at).toLocaleString('tr-TR')}</p>
      <hr/>
      <ul>${order.items_json.map(i => `<li>${i.qty}x ${i.name}${i.note ? ` (${i.note})` : ''}</li>`).join('')}</ul>
      ${order.customer_note ? `<hr/><p>Not: ${order.customer_note}</p>` : ''}
      <hr/><p>Yeedoy POS</p>
      <script>window.print();window.close();</script>
      </body></html>
    `);
    win.document.close();
  }

  function SiparisKarti({ order }: { order: Order }) {
    const elapsed = Math.round((Date.now() - new Date(order.created_at).getTime()) / 60000);
    return (
      <div className={clsx(
        'rounded-xl border p-4 flex flex-col gap-3',
        order.status === 'pending' ? 'border-amber-300 bg-amber-50/50' : 'border-border bg-cardAlt',
      )}>
        <div className="flex items-start justify-between gap-3">
          <div>
            <div className="flex items-center gap-2">
              <span className="text-base font-[900] text-textStrong">Masa {order.table_number}</span>
              {order.status === 'pending' && (
                <span className="animate-pulse rounded-full bg-amber-400 px-2 py-0.5 text-[10px] font-[900] text-white">YENİ</span>
              )}
            </div>
            {orders.length > 0 && orders.some((o) => o.businessName !== orders[0].businessName) && (
              <p className="text-xs text-muted">{order.businessName}</p>
            )}
          </div>
          <span className="shrink-0 text-xs text-muted">{elapsed === 0 ? 'Az önce' : `${elapsed} dk önce`}</span>
        </div>

        <ul className="space-y-1">
          {order.items_json.map((item, i) => (
            <li key={i} className="flex items-center gap-2 text-sm">
              <span className="font-[900] text-primary">{item.qty}×</span>
              <span className="text-textStrong">{item.name}</span>
              {item.note && <span className="text-muted">({item.note})</span>}
            </li>
          ))}
        </ul>

        {order.customer_note && (
          <p className="rounded-lg border border-border bg-card px-3 py-2 text-xs text-muted">
            Not: {order.customer_note}
          </p>
        )}

        <div className="flex gap-2">
          {order.status === 'pending' && (
            <button
              onClick={() => updateStatus(order.id, 'seen')}
              disabled={loading === order.id}
              className="flex-1 rounded-xl border border-border bg-card py-2 text-xs font-[800] text-textStrong hover:bg-cardAlt disabled:opacity-50"
            >
              {loading === order.id ? '…' : 'Görüldü'}
            </button>
          )}
          <button
            onClick={() => updateStatus(order.id, 'done')}
            disabled={loading === order.id}
            className="flex-1 btn-primary rounded-xl py-2 text-xs font-[800] text-white disabled:opacity-50"
          >
            {loading === order.id ? '…' : 'Tamamlandı'}
          </button>
          <button
            onClick={() => printOrder(order)}
            className="rounded-xl border border-border px-2 py-2 text-muted hover:border-primary hover:text-primary"
            title="Yazdır"
          >
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <polyline points="6 9 6 2 18 2 18 9" />
              <path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2" />
              <rect x="6" y="14" width="12" height="8" />
            </svg>
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-4">
      {/* Auto-refresh controls */}
      <div className="flex items-center justify-between rounded-xl border border-border bg-surface px-4 py-2.5">
        <div className="flex items-center gap-3">
          <div className={`h-2 w-2 rounded-full ${autoRefresh ? 'animate-pulse bg-green-500' : 'bg-zinc-300'}`} />
          <p className="text-xs font-[700] text-muted">
            {autoRefresh ? `Otomatik yenileme aktif (30s)` : 'Otomatik yenileme kapalı'} · Son: {lastRefresh.toLocaleTimeString('tr-TR')}
          </p>
        </div>
        <div className="flex gap-2">
          <button onClick={refreshOrders} className="rounded-lg border border-border px-3 py-1 text-xs font-[700] text-muted hover:text-textStrong">
            Şimdi Yenile
          </button>
          <button
            onClick={() => setAutoRefresh(!autoRefresh)}
            className={`rounded-lg px-3 py-1 text-xs font-[700] ${autoRefresh ? 'bg-green-100 text-green-700' : 'bg-zinc-100 text-zinc-500'}`}
          >
            {autoRefresh ? 'Otomatik Açık' : 'Otomatik Kapalı'}
          </button>
        </div>
      </div>

    <div className="grid gap-6 lg:grid-cols-2">
      <div>
        <h2 className="mb-3 text-base font-[900] text-textStrong">
          Bekleyen <span className="ml-1 rounded-full bg-amber-100 px-2 py-0.5 text-xs font-[900] text-amber-700">{pending.length}</span>
        </h2>
        {pending.length === 0
          ? <p className="text-sm text-muted">Bekleyen sipariş yok.</p>
          : <div className="flex flex-col gap-3">{pending.map((o) => <SiparisKarti key={o.id} order={o} />)}</div>
        }
      </div>
      <div>
        <h2 className="mb-3 text-base font-[900] text-textStrong">
          Hazırlanıyor <span className="ml-1 rounded-full bg-border px-2 py-0.5 text-xs font-[900] text-muted">{seen.length}</span>
        </h2>
        {seen.length === 0
          ? <p className="text-sm text-muted">Yok.</p>
          : <div className="flex flex-col gap-3">{seen.map((o) => <SiparisKarti key={o.id} order={o} />)}</div>
        }
      </div>
    </div>
    </div>
  );
}
