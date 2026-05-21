'use client';

import { useState, type FormEvent } from 'react';
import Link from 'next/link';
import { clsx } from 'clsx';
import { Icon } from '@/src/ui/acik/simgeler';
import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';
import { toast } from '@/src/lib/toast-deposu';

export function CreateCollectionButton({ onCreated }: { onCreated?: () => void }) {
  const [open, setOpen] = useState(false);
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [status, setStatus] = useState<'idle' | 'loading' | 'done' | 'error'>('idle');

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const trimmedName = name.trim();
    if (!trimmedName) return;
    setStatus('loading');
    const response = await fetch('/sunucu/koleksiyonlar', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: trimmedName, description: description.trim() || null }),
    }).catch(() => null);
    if (response?.ok) {
      setStatus('done');
      setName('');
      setDescription('');
      toast('Koleksiyon oluşturuldu', 'success');
      window.setTimeout(() => {
        setOpen(false);
        setStatus('idle');
        onCreated?.();
      }, 800);
    } else {
      setStatus('error');
      toast('Koleksiyon oluşturulamadı', 'danger');
    }
  }

  function handleClose() {
    if (status === 'loading') return;
    setOpen(false);
    setStatus('idle');
    setName('');
    setDescription('');
  }

  return (
    <>
      <button
        type="button"
        onClick={() => setOpen(true)}
        className="inline-flex min-h-[44px] items-center gap-2 rounded-2xl border border-border bg-card px-4 text-sm font-[800] text-textStrong transition-all hover:-translate-y-px hover:border-primary/30 hover:shadow-yd1 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30"
      >
        <svg viewBox="0 0 24 24" className="h-4 w-4 fill-current text-primary" aria-hidden="true">
          <path d="M19 13h-6v6h-2v-6H5v-2h6V5h2v6h6v2z"/>
        </svg>
        Yeni Koleksiyon
      </button>

      {open && (
        <div
          className="fixed inset-0 z-50 grid place-items-end bg-black/35 p-3 sm:place-items-center"
          role="dialog"
          aria-modal="true"
          aria-labelledby="create-col-title"
          onClick={(e) => { if (e.target === e.currentTarget) handleClose(); }}
        >
          <form
            onSubmit={handleSubmit}
            className="w-full max-w-md rounded-[24px] border border-border bg-card p-5 shadow-yd3"
          >
            <div className="flex items-start justify-between gap-4">
              <div>
                <h2 id="create-col-title" className="text-lg font-[900] text-textStrong">Yeni Koleksiyon</h2>
                <p className="mt-1 text-sm text-muted">Favori işletmelerinizi gruplandırın.</p>
              </div>
              <button
                type="button"
                onClick={handleClose}
                className="min-h-11 rounded-2xl px-3 text-sm font-[900] text-muted hover:bg-cardAlt"
              >
                Kapat
              </button>
            </div>

            <label className="mt-5 block text-sm font-[900] text-textStrong">
              Koleksiyon Adı
              <input
                type="text"
                value={name}
                onChange={(e) => setName(e.target.value)}
                maxLength={80}
                required
                placeholder="örn. Kahvaltı Mekanları"
                className="mt-2 w-full rounded-2xl border border-border bg-bg px-4 py-3 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30"
              />
            </label>

            <label className="mt-4 block text-sm font-[900] text-textStrong">
              Açıklama{' '}
              <span className="font-[700] text-muted">(isteğe bağlı)</span>
              <textarea
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                maxLength={300}
                rows={3}
                placeholder="Bu koleksiyon hakkında kısa bir açıklama..."
                className="mt-2 w-full rounded-2xl border border-border bg-bg px-4 py-3 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30"
              />
            </label>

            <button
              type="submit"
              disabled={status === 'loading' || status === 'done' || !name.trim()}
              className="mt-5 inline-flex min-h-[52px] w-full items-center justify-center rounded-2xl px-5 text-sm font-[900] text-white disabled:opacity-60"
              style={{ background: 'var(--yd-gradient-primary)' }}
            >
              {status === 'loading' ? 'Oluşturuluyor...' : status === 'done' ? 'Oluşturuldu!' : 'Oluştur'}
            </button>

            {status === 'error' && (
              <p className="mt-3 text-sm font-[800] text-danger">
                Koleksiyon oluşturulamadı. Daha sonra tekrar deneyin.
              </p>
            )}
          </form>
        </div>
      )}
    </>
  );
}

export function FavoriteButton({
  label = 'Favori',
  className,
}: {
  label?: string;
  className?: string;
}) {
  const [active, setActive] = useState(false);
  return (
    <button
      type="button"
      aria-pressed={active}
      onClick={(event) => {
        event.preventDefault();
        const next = !active;
        setActive(next);
        toast(next ? 'Favorilere eklendi' : 'Favorilerden çıkarıldı', next ? 'success' : 'default');
      }}
      className={clsx(
        'inline-flex min-h-11 items-center justify-center gap-2 rounded-2xl border px-3.5 text-sm font-[900]',
        'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30',
        active
          ? 'border-primary/30 bg-[var(--yd-color-primary-soft)] text-primary'
          : 'border-border bg-card text-textStrong hover:border-primary/30',
        className,
      )}
    >
      <Icon name="heart" size={16} className={active ? 'fill-current' : undefined} />
      <span className="sr-only sm:not-sr-only">{active ? 'Favoride' : label}</span>
    </button>
  );
}

export function ShareButton({ title, url, className }: { title: string; url?: string; className?: string }) {
  const [copied, setCopied] = useState(false);
  return (
    <button
      type="button"
      onClick={async (event) => {
        event.preventDefault();
        const href = url ?? window.location.href;
        if (navigator.share) {
          await navigator.share({ title, url: href }).catch(() => undefined);
          return;
        }
        await navigator.clipboard?.writeText(href).catch(() => undefined);
        setCopied(true);
        toast('Bağlantı kopyalandı', 'success', 2500);
        window.setTimeout(() => setCopied(false), 1600);
      }}
      className={clsx(
        'inline-flex min-h-11 items-center justify-center gap-2 rounded-2xl border border-border bg-card px-3.5 text-sm font-[900] text-textStrong hover:border-primary/30',
        'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30',
        className,
      )}
    >
      <Icon name="share" size={16} />
      <span className="sr-only sm:not-sr-only">{copied ? 'Kopyalandı' : 'Paylaş'}</span>
    </button>
  );
}

export function ReportBusinessButton({ businessId, businessName }: { businessId: string; businessName: string }) {
  const [open, setOpen] = useState(false);
  const [status, setStatus] = useState<'idle' | 'loading' | 'done' | 'error'>('idle');

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setStatus('loading');
    const formData = new FormData(event.currentTarget);
    const message = String(formData.get('message') ?? '').trim();
    const category = String(formData.get('category') ?? 'other') as 'menu' | 'price' | 'service' | 'app' | 'other';
    const response = await fetch('/sunucu/geri-bildirim', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ businessId, rating: 1, category, message }),
    }).catch(() => null);
    setStatus(response?.ok ? 'done' : 'error');
  }

  return (
    <>
      <button
        type="button"
        onClick={() => setOpen(true)}
        className="inline-flex min-h-11 items-center justify-center gap-2 rounded-2xl border border-border bg-card px-4 text-sm font-[900] text-textStrong hover:border-danger/35 hover:text-danger focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30"
      >
        <Icon name="flag" size={16} />
        Rapor et
      </button>
      {open ? (
        <div className="fixed inset-0 z-50 grid place-items-end bg-black/35 p-3 sm:place-items-center" role="dialog" aria-modal="true">
          <form onSubmit={submit} className="w-full max-w-md rounded-[24px] border border-border bg-card p-5 shadow-yd3">
            <div className="flex items-start justify-between gap-4">
              <div>
                <h2 className="text-lg font-[900] text-textStrong">{businessName} için rapor</h2>
                <p className="mt-1 text-sm text-muted">Menü, fiyat ya da işletme bilgisiyle ilgili sorunu iletin.</p>
              </div>
              <button type="button" onClick={() => setOpen(false)} className="min-h-11 rounded-2xl px-3 text-sm font-[900] text-muted hover:bg-cardAlt">
                Kapat
              </button>
            </div>
            <label className="mt-5 block text-sm font-[900] text-textStrong">
              Konu
              <select name="category" className="mt-2 w-full rounded-2xl border border-border bg-bg px-4 py-3 text-sm text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/30">
                <option value="menu">Menü içeriği</option>
                <option value="price">Fiyat bilgisi</option>
                <option value="service">Servis / işletme bilgisi</option>
                <option value="other">Diğer</option>
              </select>
            </label>
            <label className="mt-4 block text-sm font-[900] text-textStrong">
              Açıklama
              <textarea name="message" maxLength={500} rows={4} className="mt-2 w-full rounded-2xl border border-border bg-bg px-4 py-3 text-sm text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/30" />
            </label>
            <button
              type="submit"
              disabled={status === 'loading' || status === 'done'}
              className="mt-5 inline-flex min-h-[52px] w-full items-center justify-center rounded-2xl px-5 text-sm font-[900] text-white disabled:opacity-60"
              style={{ background: 'var(--yd-gradient-primary)' }}
            >
              {status === 'loading' ? 'Gönderiliyor...' : status === 'done' ? 'Rapor alındı' : 'Gönder'}
            </button>
            {status === 'error' ? <p className="mt-3 text-sm font-[800] text-danger">Rapor gönderilemedi. Daha sonra tekrar deneyin.</p> : null}
          </form>
        </div>
      ) : null}
    </>
  );
}

export function HelpfulVoteButton() {
  const [count, setCount] = useState(0);
  return (
    <button
      type="button"
      onClick={() => setCount((value) => value + 1)}
      className="inline-flex min-h-11 items-center rounded-2xl border border-border bg-card px-3 text-xs font-[900] text-textStrong hover:border-primary/30"
    >
      Faydalı{count > 0 ? ` (${count})` : ''}
    </button>
  );
}

export function FiyatTakipDugmesi({ businessId }: { businessId: string }) {
  const [status, setStatus] = useState<'idle' | 'loading' | 'active' | 'no-auth'>('idle');

  async function handleToggle() {
    const supabase = createSupabaseBrowserClient();
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) {
      setStatus('no-auth');
      return;
    }
    setStatus('loading');
    try {
      await (supabase as any).rpc('toggle_price_alert_v1', { p_business_id: businessId });
      setStatus('active');
      toast('Fiyat alarmı eklendi', 'success');
      window.setTimeout(() => setStatus('idle'), 3000);
    } catch {
      setStatus('idle');
      toast('Fiyat alarmı kaydedilemedi', 'danger');
    }
  }

  if (status === 'no-auth') {
    return (
      <div className="rounded-[20px] border border-border bg-card p-5 shadow-yd1">
        <p className="text-sm font-[900] text-textStrong">Fiyat takip et</p>
        <p className="mt-2 text-xs leading-5 text-muted">Giriş yaparak fiyat değişimlerinde bildirim alabilirsin.</p>
        <Link
          href="/giris"
          className="mt-3 inline-flex min-h-11 items-center justify-center rounded-2xl px-5 text-sm font-[900] text-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30"
          style={{ background: 'var(--yd-gradient-primary)' }}
        >
          Giriş yap
        </Link>
      </div>
    );
  }

  if (status === 'active') {
    return (
      <div className="rounded-[20px] border border-success/25 bg-success/[0.12] p-5 shadow-yd1">
        <p className="text-sm font-[900] text-success">Fiyat alarmı eklendi</p>
        <p className="mt-1 text-xs text-muted">Bu işletmenin fiyatları değiştiğinde seni haberdar edeceğiz.</p>
      </div>
    );
  }

  return (
    <div className="rounded-[20px] border border-border bg-card p-5 shadow-yd1">
      <p className="text-sm font-[900] text-textStrong">Fiyat takip et</p>
      <p className="mt-2 text-xs leading-5 text-muted">Fiyat değişirse haber verelim.</p>
      <button
        type="button"
        disabled={status === 'loading'}
        onClick={handleToggle}
        className="mt-3 inline-flex min-h-11 w-full items-center justify-center gap-2 rounded-2xl border border-border bg-bg px-4 text-sm font-[900] text-textStrong hover:border-primary/30 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30 disabled:opacity-60"
      >
        <Icon name="bell" size={16} />
        {status === 'loading' ? 'Kaydediliyor...' : 'Fiyat değişirse haber ver'}
      </button>
    </div>
  );
}

export function CheckinDugmesi({ businessId, className }: { businessId: string; className?: string }) {
  const [status, setStatus] = useState<'idle' | 'loading' | 'done' | 'duplicate'>('idle');

  async function handleCheckin() {
    const supabase = createSupabaseBrowserClient();
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) {
      alert('Giriş yapmanız gerekiyor');
      return;
    }
    setStatus('loading');
    const { error } = await (supabase as any).rpc('submit_checkin_v1', { p_business_id: businessId });
    if (!error) {
      setStatus('done');
      toast('Check-in yapıldı!', 'success');
      window.setTimeout(() => setStatus('idle'), 3000);
    } else if (error.message?.toLowerCase().includes('already') || error.code === '23505') {
      setStatus('duplicate');
      toast('Bugün zaten check-in yaptınız', 'warning');
      window.setTimeout(() => setStatus('idle'), 3000);
    } else {
      setStatus('idle');
      toast('Check-in başarısız oldu', 'danger');
    }
  }

  if (status === 'done') {
    return (
      <span className={clsx('inline-flex min-h-11 items-center gap-2 rounded-2xl border border-success/25 bg-success/[0.12] px-4 text-sm font-[900] text-success', className)}>
        ✓ Check-in yapıldı!
      </span>
    );
  }

  if (status === 'duplicate') {
    return (
      <span className={clsx('inline-flex min-h-11 items-center gap-2 rounded-2xl border border-warning/25 bg-warning/[0.14] px-4 text-sm font-[900] text-textStrong', className)}>
        Bugün zaten check-in yaptınız
      </span>
    );
  }

  return (
    <button
      type="button"
      disabled={status === 'loading'}
      onClick={handleCheckin}
      className={clsx(
        'inline-flex min-h-11 items-center justify-center gap-2 rounded-2xl border border-border bg-card px-4 text-sm font-[900] text-textStrong',
        'hover:border-primary/30 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30',
        'disabled:opacity-60',
        className,
      )}
    >
      <Icon name="pin" size={16} />
      {status === 'loading' ? 'Gönderiliyor...' : 'Buradayım'}
    </button>
  );
}

