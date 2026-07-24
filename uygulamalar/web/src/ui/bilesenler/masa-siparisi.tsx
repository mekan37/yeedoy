'use client';

import { useState, type ReactNode } from 'react';
import { clsx } from 'clsx';

interface SepetUrun {
  id: string;
  name: string;
  qty: number;
  priceCents: number;
  currency: string;
}

interface MasaSimarisiProps {
  businessId: string;
  /** Menü ürünleri listesi — sadece sepete eklenenleri göster */
  sepet: SepetUrun[];
  onSepetGuncelle: (id: string, delta: number) => void;
  formatFiyat: (cents: number, currency: string) => string;
}

export function MasaSimarisiPaneli({ businessId, sepet, onSepetGuncelle, formatFiyat }: MasaSimarisiProps) {
  const [open, setOpen] = useState(false);
  const [masaNo, setMasaNo] = useState('');
  const [not, setNot] = useState('');
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState<'success' | 'error' | null>(null);
  const [errorMsg, setErrorMsg] = useState('');

  const totalItems = sepet.reduce((s, i) => s + i.qty, 0);
  const totalCents = sepet.reduce((s, i) => s + i.qty * i.priceCents, 0);
  const currency = sepet[0]?.currency ?? 'TRY';

  async function handleGonder() {
    if (!masaNo.trim() || sepet.length === 0) return;
    setLoading(true);
    setResult(null);
    try {
      const res = await fetch('/sunucu/masa-siparisi', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          businessId,
          tableNumber: masaNo.trim(),
          items: sepet.map((i) => ({ name: i.name, qty: i.qty })),
          note: not.trim() || undefined,
        }),
      });
      const json = await res.json();
      if (!res.ok) throw new Error(json.error ?? 'Hata');
      setResult('success');
      setMasaNo('');
      setNot('');
    } catch (e: any) {
      setResult('error');
      setErrorMsg(e.message === 'rate_limited' ? 'Çok sık sipariş gönderildi. Lütfen bekleyin.' : 'Sipariş gönderilemedi.');
    } finally {
      setLoading(false);
    }
  }

  if (totalItems === 0) return null;

  return (
    <div className="fixed bottom-4 right-4 z-40">
      {/* Sepet Butonu */}
      {!open && (
        <button
          onClick={() => setOpen(true)}
          className="btn-primary flex items-center gap-2 rounded-2xl px-4 py-3 text-sm font-extrabold text-white shadow-yd3"
        >
          <BasketIcon />
          <span>{totalItems} ürün · {formatFiyat(totalCents, currency)}</span>
          <ChevronIcon />
        </button>
      )}

      {/* Sipariş Paneli */}
      {open && (
        <div className="animate-sheet-in w-[320px] rounded-[24px] border border-border bg-card shadow-yd4">
          <div className="flex items-center justify-between border-b border-border px-4 py-3">
            <span className="font-black text-textStrong">Garsona Bildir</span>
            <button onClick={() => setOpen(false)} className="text-muted hover:text-textStrong">✕</button>
          </div>
          <div className="max-h-48 overflow-y-auto px-4 py-3">
            {sepet.map((item) => (
              <div key={item.id} className="flex items-center justify-between py-1.5">
                <span className="flex-1 text-sm font-bold text-textStrong">{item.name}</span>
                <div className="flex items-center gap-1.5 ml-2">
                  <button
                    onClick={() => onSepetGuncelle(item.id, -1)}
                    className="flex h-6 w-6 items-center justify-center rounded-full border border-border text-muted hover:bg-cardAlt"
                  >−</button>
                  <span className="w-5 text-center text-sm font-extrabold">{item.qty}</span>
                  <button
                    onClick={() => onSepetGuncelle(item.id, +1)}
                    className="flex h-6 w-6 items-center justify-center rounded-full border border-border text-muted hover:bg-cardAlt"
                  >+</button>
                </div>
              </div>
            ))}
          </div>
          <div className="border-t border-border px-4 py-3 flex flex-col gap-2">
            <input
              type="text"
              value={masaNo}
              onChange={(e) => setMasaNo(e.target.value)}
              placeholder="Masa numaranız (örn: 5, A3)"
              className="input-yd w-full rounded-xl px-3 py-2 text-sm"
            />
            <textarea
              value={not}
              onChange={(e) => setNot(e.target.value)}
              placeholder="Not (opsiyonel)"
              rows={2}
              maxLength={500}
              className="input-yd w-full resize-none rounded-xl px-3 py-2 text-sm"
            />
            {result === 'success' && (
              <p className="rounded-xl bg-success/8 border border-success/20 px-3 py-2 text-xs font-extrabold text-success">
                Sipariş iletildi! Garsonunuz yakında gelecek.
              </p>
            )}
            {result === 'error' && (
              <p className="rounded-xl bg-danger/8 border border-danger/20 px-3 py-2 text-xs font-bold text-danger">
                {errorMsg}
              </p>
            )}
            <button
              onClick={handleGonder}
              disabled={loading || !masaNo.trim() || result === 'success'}
              className="btn-primary w-full rounded-xl py-2.5 text-sm font-extrabold text-white disabled:cursor-not-allowed disabled:opacity-50"
            >
              {loading ? 'Gönderiliyor…' : 'Garsona Bildir'}
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

function BasketIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M6 2L3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z"/><line x1="3" y1="6" x2="21" y2="6"/><path d="M16 10a4 4 0 0 1-8 0"/>
    </svg>
  );
}

function ChevronIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <polyline points="18 15 12 9 6 15"/>
    </svg>
  );
}
