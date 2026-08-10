import type { Metadata } from 'next';
import QRCode from 'qrcode';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

export const metadata: Metadata = {
  title: 'Sadakat Kartlarım | Yeedoy',
  robots: { index: false, follow: false },
};

type SadakatKarti = {
  program_id: string;
  mode: 'stamp' | 'points';
  business_name: string;
  logo_url: string | null;
  progress: number;
  reward_threshold: number;
  reward_desc: string;
};

export default async function SadakatPage() {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return null;

  const qrDataUrl = await QRCode.toDataURL(user.id, { margin: 1, width: 220 });

  const { data: cards } = (await (supabase as any).rpc('get_my_loyalty_cards_v1')) as {
    data: SadakatKarti[] | null;
  };
  const list = cards ?? [];

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-2xl px-4 py-12">
        <div className="mb-6">
          <h1 className="text-2xl font-black text-textStrong">Sadakat Kartlarım</h1>
          <p className="mt-1 text-sm text-muted">
            Damga/puan kazanmak için işletmede bu kodu gösterin.
          </p>
        </div>

        <div className="mb-8 flex flex-col items-center gap-3 rounded-2xl border border-border bg-card p-6">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src={qrDataUrl} alt="Sadakat kodum" width={220} height={220} className="rounded-xl" />
          <p className="text-xs text-muted">Bu kod size özeldir, paylaşmayın.</p>
        </div>

        {list.length === 0 ? (
          <div className="rounded-2xl border border-border bg-card p-10 text-center">
            <p className="mb-3 text-3xl">🎁</p>
            <p className="mb-2 font-bold text-textStrong">Henüz sadakat kartınız yok</p>
            <p className="text-sm text-muted">
              Katıldığınız işletmelerin sadakat programları burada görünecek.
            </p>
          </div>
        ) : (
          <div className="flex flex-col gap-3">
            {list.map((card) => (
              <div key={card.program_id} className="rounded-2xl border border-border bg-card p-5">
                <div className="flex items-center gap-3">
                  {card.logo_url ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img
                      src={card.logo_url}
                      alt={card.business_name}
                      className="h-10 w-10 rounded-full object-cover"
                    />
                  ) : (
                    <div className="flex h-10 w-10 items-center justify-center rounded-full bg-zinc-100 text-sm font-black text-zinc-500">
                      {card.business_name.charAt(0).toUpperCase()}
                    </div>
                  )}
                  <div className="min-w-0 flex-1">
                    <p className="font-black text-textStrong">{card.business_name}</p>
                    <p className="text-xs text-muted">{card.reward_desc}</p>
                  </div>
                </div>
                <div className="mt-3 h-2.5 overflow-hidden rounded-full bg-zinc-100">
                  <div
                    className="h-2.5 rounded-full bg-primary"
                    style={{
                      width: `${Math.min(100, Math.round((card.progress / card.reward_threshold) * 100))}%`,
                    }}
                  />
                </div>
                <p className="mt-1.5 text-xs font-bold text-textStrong">
                  {card.progress} / {card.reward_threshold}
                </p>
              </div>
            ))}
          </div>
        )}
      </div>
    </main>
  );
}
