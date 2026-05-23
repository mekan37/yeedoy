'use client';

import { useState } from 'react';
import Link from 'next/link';

type SiparisCategory = { id: string; name: string };

type SiparisItem = {
  id: string;
  name: string;
  price_cents: number;
  currency: string;
  is_available: boolean;
  category_id: string;
  description?: string | null;
};

type Props = {
  business: { id: string; name: string; slug: string };
  menuCategories: SiparisCategory[];
  menuItems: SiparisItem[];
};

function formatFiyat(cents: number, currency: string): string {
  return new Intl.NumberFormat('tr-TR', {
    style: 'currency',
    currency: currency || 'TRY',
    minimumFractionDigits: 0,
    maximumFractionDigits: 2,
  }).format(cents / 100);
}

export function SiparisClient({ business, menuCategories, menuItems }: Props) {
  const [tableNo, setTableNo] = useState('');
  const [cart, setCart] = useState<Map<string, number>>(new Map());
  const [step, setStep] = useState<'menu' | 'confirm' | 'success' | 'error'>('menu');
  const [orderId, setOrderId] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [activeCategory, setActiveCategory] = useState<string>(menuCategories[0]?.id ?? '');

  function addToCart(itemId: string) {
    setCart((prev) => {
      const next = new Map(prev);
      next.set(itemId, (next.get(itemId) ?? 0) + 1);
      return next;
    });
  }

  function removeFromCart(itemId: string) {
    setCart((prev) => {
      const next = new Map(prev);
      const current = next.get(itemId) ?? 0;
      if (current <= 1) {
        next.delete(itemId);
      } else {
        next.set(itemId, current - 1);
      }
      return next;
    });
  }

  const cartTotalItems = Array.from(cart.values()).reduce((sum, qty) => sum + qty, 0);
  const cartTotalCents = Array.from(cart.entries()).reduce((sum, [itemId, qty]) => {
    const item = menuItems.find((i) => i.id === itemId);
    return sum + (item?.price_cents ?? 0) * qty;
  }, 0);

  const firstItemCurrency = menuItems[0]?.currency ?? 'TRY';

  async function handleOrder() {
    if (!tableNo.trim()) {
      alert('Lütfen masa numaranızı girin.');
      return;
    }
    if (cart.size === 0) {
      alert('Sepetiniz boş.');
      return;
    }

    const items = Array.from(cart.entries()).map(([itemId, qty]) => {
      const item = menuItems.find((i) => i.id === itemId);
      return { name: item?.name ?? itemId, qty };
    });

    setLoading(true);
    try {
      const response = await fetch('/sunucu/masa-siparisi', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          businessId: business.id,
          tableNumber: tableNo.trim(),
          items,
        }),
      });

      const json = await response.json().catch(() => ({})) as { ok?: boolean; orderId?: string; error?: string };

      if (response.ok && json.ok) {
        setOrderId(json.orderId ?? null);
        setStep('success');
      } else {
        setStep('error');
      }
    } catch {
      setStep('error');
    } finally {
      setLoading(false);
    }
  }

  if (step === 'success') {
    return (
      <main className="min-h-screen bg-bg">
        <div className="mx-auto flex min-h-screen max-w-lg flex-col items-center justify-center px-4 py-16 text-center">
          <div className="flex h-20 w-20 items-center justify-center rounded-full bg-success/[0.12] text-4xl">
            ✓
          </div>
          <h1 className="mt-6 text-2xl font-[900] text-textStrong">Siparişiniz alındı!</h1>
          <p className="mt-3 text-base leading-7 text-muted">
            Masanıza gelecek. Afiyet olsun!
          </p>
          {orderId && (
            <p className="mt-2 rounded-2xl border border-border bg-card px-4 py-2 text-sm font-[900] text-textStrong">
              Sipariş No: <span className="text-primary">{orderId}</span>
            </p>
          )}
          <button
            type="button"
            onClick={() => {
              setStep('menu');
              setCart(new Map());
              setTableNo('');
              setOrderId(null);
            }}
            className="mt-8 inline-flex min-h-[52px] items-center justify-center rounded-2xl border border-border bg-card px-6 text-sm font-[900] text-textStrong hover:border-primary/30"
          >
            Menüye dön
          </button>
          <Link
            href={`/isletme/${business.slug}`}
            className="mt-3 text-sm font-[700] text-primary hover:underline"
          >
            {business.name} sayfasına git
          </Link>
        </div>
      </main>
    );
  }

  if (step === 'error') {
    return (
      <main className="min-h-screen bg-bg">
        <div className="mx-auto flex min-h-screen max-w-lg flex-col items-center justify-center px-4 py-16 text-center">
          <div className="flex h-20 w-20 items-center justify-center rounded-full bg-danger/[0.10] text-4xl">
            ✕
          </div>
          <h1 className="mt-6 text-2xl font-[900] text-textStrong">Sipariş gönderilemedi</h1>
          <p className="mt-3 text-sm text-muted">
            Bir sorun oluştu. Tekrar deneyebilir veya personele bildirebilirsiniz.
          </p>
          <button
            type="button"
            onClick={() => setStep('menu')}
            className="mt-8 inline-flex min-h-[52px] items-center justify-center rounded-2xl px-6 text-sm font-[900] text-white"
            style={{ background: 'var(--yd-gradient-primary)' }}
          >
            Tekrar dene
          </button>
        </div>
      </main>
    );
  }

  const displayedItems =
    activeCategory
      ? menuItems.filter((item) => item.category_id === activeCategory)
      : menuItems;

  return (
    <main className="min-h-screen bg-bg pb-36">
      {/* Header */}
      <header className="sticky top-0 z-30 border-b border-border bg-card/90 backdrop-blur">
        <div className="mx-auto max-w-lg px-4 py-3">
          <div className="flex items-center justify-between gap-3">
            <h1 className="text-lg font-[900] text-textStrong">{business.name}</h1>
            <span className="inline-flex items-center gap-1 rounded-full border border-primary/25 bg-[var(--yd-color-primary-soft)] px-3 py-1 text-xs font-[900] text-primary">
              Sipariş Ver
            </span>
          </div>

          {/* Table number input */}
          <div className="mt-3">
            <label className="block text-xs font-[900] text-muted">
              Masa numaranız
            </label>
            <input
              type="number"
              min={1}
              max={99}
              value={tableNo}
              onChange={(e) => setTableNo(e.target.value)}
              placeholder="örn. 5"
              required
              className="mt-1 w-full rounded-2xl border border-border bg-bg px-4 py-2.5 text-sm font-[900] text-textStrong placeholder:font-[400] placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30"
            />
          </div>
        </div>
      </header>

      <div className="mx-auto max-w-lg px-4">
        {/* Category tabs */}
        {menuCategories.length > 1 && (
          <div className="sticky top-[126px] z-20 -mx-4 flex gap-2 overflow-x-auto bg-bg px-4 py-3 [-ms-overflow-style:none] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
            {menuCategories.map((cat) => (
              <button
                key={cat.id}
                type="button"
                onClick={() => setActiveCategory(cat.id)}
                className={
                  activeCategory === cat.id
                    ? 'inline-flex min-h-[40px] shrink-0 items-center rounded-full border border-primary/30 bg-[var(--yd-color-primary-soft)] px-4 text-sm font-[900] text-primary'
                    : 'inline-flex min-h-[40px] shrink-0 items-center rounded-full border border-border bg-card px-4 text-sm font-[900] text-textStrong hover:border-primary/25'
                }
              >
                {cat.name}
              </button>
            ))}
          </div>
        )}

        {/* Menu items */}
        <div className="mt-4 grid gap-3">
          {displayedItems.length === 0 && (
            <div className="rounded-[20px] border border-border bg-card p-10 text-center">
              <p className="text-sm font-[900] text-muted">Bu kategoride ürün yok.</p>
            </div>
          )}
          {displayedItems.map((item) => {
            const qty = cart.get(item.id) ?? 0;
            return (
              <div
                key={item.id}
                className="rounded-[20px] border border-border bg-card p-4 shadow-yd1"
              >
                <div className="flex items-start justify-between gap-3">
                  <div className="min-w-0 flex-1">
                    <p className="font-[900] text-textStrong">{item.name}</p>
                    {item.description && (
                      <p className="mt-1 line-clamp-2 text-xs leading-5 text-muted">
                        {item.description}
                      </p>
                    )}
                    <p className="mt-2 text-sm font-[900] text-primary">
                      {formatFiyat(item.price_cents, item.currency)}
                    </p>
                    {!item.is_available && (
                      <span className="mt-1 inline-flex rounded-full border border-danger/25 bg-danger/[0.10] px-2 py-0.5 text-[10px] font-[900] text-danger">
                        Tükendi
                      </span>
                    )}
                  </div>

                  {/* +/- controls */}
                  <div className="flex shrink-0 items-center gap-2">
                    {qty > 0 ? (
                      <>
                        <button
                          type="button"
                          aria-label="Azalt"
                          onClick={() => removeFromCart(item.id)}
                          className="flex h-11 w-11 items-center justify-center rounded-2xl border border-border bg-bg text-lg font-[900] text-textStrong hover:border-primary/30 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30"
                        >
                          −
                        </button>
                        <span className="min-w-[20px] text-center text-sm font-[900] text-textStrong">
                          {qty}
                        </span>
                      </>
                    ) : null}
                    <button
                      type="button"
                      aria-label="Ekle"
                      disabled={!item.is_available}
                      onClick={() => addToCart(item.id)}
                      className="flex h-11 w-11 items-center justify-center rounded-2xl border border-primary/30 bg-[var(--yd-color-primary-soft)] text-lg font-[900] text-primary hover:bg-primary/20 disabled:cursor-not-allowed disabled:opacity-40 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30"
                    >
                      +
                    </button>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Sticky cart footer */}
      {cartTotalItems > 0 && (
        <div className="fixed inset-x-0 bottom-0 z-40 border-t border-border bg-card/95 px-4 py-4 backdrop-blur">
          <div className="mx-auto flex max-w-lg items-center justify-between gap-4">
            <div>
              <p className="text-sm font-[900] text-textStrong">
                Sepet: {cartTotalItems} ürün
              </p>
              <p className="text-xs text-muted">
                {formatFiyat(cartTotalCents, firstItemCurrency)}
              </p>
            </div>
            <button
              type="button"
              disabled={loading || !tableNo.trim()}
              onClick={handleOrder}
              className="inline-flex min-h-[52px] items-center justify-center rounded-2xl px-6 text-sm font-[900] text-white disabled:cursor-not-allowed disabled:opacity-60 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30"
              style={{ background: 'var(--yd-gradient-primary)' }}
            >
              {loading ? 'Gönderiliyor...' : 'Siparişi Onayla'}
            </button>
          </div>
          {!tableNo.trim() && (
            <p className="mx-auto mt-2 max-w-lg text-center text-xs font-[700] text-danger">
              Sipariş vermek için masa numaranızı girin.
            </p>
          )}
        </div>
      )}
    </main>
  );
}
