import type { Metadata } from 'next';
import Link from 'next/link';
import { Bell } from 'lucide-react';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { AlarmToggle, AlarmSilButonu } from './alarm-islemleri';

export const metadata: Metadata = { title: 'Fiyat Alarmlarım | Yeedoy', robots: { index: false, follow: false } };

type AlertRow = {
  id: string; target_price_cents: number; currency: string; is_active: boolean;
  current_price_cents: number | null; notified_at: string | null; created_at: string;
  menu_items: { name: string; businesses: { name: string; slug: string } | null } | null;
};

export default async function PriceAlertsPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  let list: AlertRow[] = [];
  try {
    const { data, error } = await (supabase as any)
      .from('price_alerts')
      .select('id, target_price_cents, currency, is_active, current_price_cents, notified_at, created_at, menu_items(name, businesses(name, slug))')
      .eq('user_id', user!.id)
      .order('created_at', { ascending: false }) as { data: AlertRow[] | null; error: any };
    if (!error || error.code !== '42P01') list = data ?? [];
  } catch { list = []; }

  function fmt(cents: number, cur: string) {
    return (cents / 100).toLocaleString('tr-TR', { style: 'currency', currency: cur || 'TRY', minimumFractionDigits: 0 });
  }

  const active = list.filter((a) => a.is_active);
  const inactive = list.filter((a) => !a.is_active);

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-2xl px-4 py-12">
        <Link href="/profil" className="mb-6 inline-flex items-center gap-1.5 text-sm text-muted hover:text-primary">← Profilime Dön</Link>

        <div className="mb-6 flex items-center gap-3">
          <h1 className="text-2xl font-[900] text-textStrong">Fiyat Alarmlarım</h1>
          {active.length > 0 && (
            <span className="rounded-full bg-primary px-2 py-0.5 text-[11px] font-[700] text-white">{active.length} aktif</span>
          )}
        </div>

        {list.length === 0 ? (
          <div className="rounded-2xl border border-border bg-card p-10 text-center">
            <Bell className="mx-auto mb-3 h-8 w-8 text-muted" aria-hidden="true" />
            <p className="font-[700] text-textStrong mb-2">Henüz fiyat alarmınız yok</p>
            <p className="text-sm text-muted mb-6">Bir ürün fiyatı hedef seviyenize düştüğünde bildirim alın.</p>
            <Link href="/kesif" className="inline-flex min-h-[44px] items-center rounded-2xl px-5 text-sm font-[800] text-white" style={{ background: 'var(--yd-gradient-primary)' }}>
              Menü Keşfet
            </Link>
          </div>
        ) : (
          <div className="flex flex-col gap-6">
            {active.length > 0 && (
              <section>
                <p className="mb-3 text-xs font-[900] uppercase tracking-wide text-muted">Aktif Alarmlar</p>
                <div className="flex flex-col gap-3">
                  {active.map((a) => (
                    <AlertCard key={a.id} alert={a} fmt={fmt} />
                  ))}
                </div>
              </section>
            )}
            {inactive.length > 0 && (
              <section>
                <p className="mb-3 text-xs font-[900] uppercase tracking-wide text-muted">Pasif</p>
                <div className="flex flex-col gap-3 opacity-70">
                  {inactive.map((a) => (
                    <AlertCard key={a.id} alert={a} fmt={fmt} />
                  ))}
                </div>
              </section>
            )}
          </div>
        )}

        <p className="mt-8 text-[11px] text-muted leading-relaxed">
          Fiyat değişikliğinde bildirim almak için{' '}
          <Link href="/bildirim-ayarlari" className="font-[700] text-primary hover:underline">bildirim ayarlarından</Link>
          {' '}fiyat alarmlarını açık tutun.
        </p>
      </div>
    </main>
  );
}

function AlertCard({ alert: a, fmt }: { alert: AlertRow; fmt: (cents: number, cur: string) => string }) {
  const item = a.menu_items;
  const biz = item?.businesses;
  const dropped = a.current_price_cents != null && a.current_price_cents <= a.target_price_cents;

  return (
    <div className={`rounded-2xl border bg-card p-5 ${dropped ? 'border-success/40' : 'border-border'}`}>
      <div className="flex items-start gap-4">
        <div className="min-w-0 flex-1">
          <p className="font-[900] text-textStrong">{item?.name ?? 'Bilinmeyen ürün'}</p>
          {biz && (
            <Link href={`/isletme/${biz.slug}`} className="mt-0.5 block text-[12px] font-[700] text-primary hover:underline">
              {biz.name}
            </Link>
          )}
          <div className="mt-2 flex flex-wrap items-center gap-3">
            <div>
              <p className="text-[11px] text-muted">Hedef</p>
              <p className="text-sm font-[900] text-textStrong">{fmt(a.target_price_cents, a.currency)}</p>
            </div>
            {a.current_price_cents != null && (
              <div>
                <p className="text-[11px] text-muted">Güncel</p>
                <p className={`text-sm font-[900] ${dropped ? 'text-success' : 'text-textStrong'}`}>
                  {fmt(a.current_price_cents, a.currency)}
                  {dropped && ' ✓'}
                </p>
              </div>
            )}
          </div>
          {dropped && (
            <p className="mt-2 inline-flex items-center gap-1 rounded-full bg-success/10 px-2.5 py-1 text-[11px] font-[900] text-success">
              Fiyat hedefe ulaştı!
            </p>
          )}
        </div>
        <div className="flex shrink-0 flex-col items-end gap-3">
          <AlarmToggle alertId={a.id} isActive={a.is_active} />
          <AlarmSilButonu alertId={a.id} />
        </div>
      </div>
    </div>
  );
}
