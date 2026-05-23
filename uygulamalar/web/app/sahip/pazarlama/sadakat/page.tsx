import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinesses } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { SadakatProgramFormu } from './sadakat-form';

export const metadata: Metadata = {
  title: 'Sadakat Programı | Sahip Paneli',
  robots: { index: false, follow: false },
};

export default async function SadakatPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const businesses = user
    ? (await getOwnerBusinesses<{ id: string; name: string; is_active: boolean | null }>(
      supabase as any,
      user.id,
      'id, name, is_active',
    )).filter((business) => business.is_active !== false)
    : [];

  const bizIds = businesses.map((b: { id: string }) => b.id);

  const { data: programs } = bizIds.length > 0
    ? await (supabase as any)
        .from('loyalty_programs')
        .select('id, business_id, name, stamps_needed, reward_desc, is_active, created_at')
        .in('business_id', bizIds)
        .order('created_at', { ascending: false })
    : { data: [] };

  const bizMap = Object.fromEntries(
    businesses.map((b: { id: string; name: string }) => [b.id, b.name]),
  );

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Owner"
        title="Sadakat Programı"
        description="Dijital damga kartı ile müşteri bağlılığı oluşturun"
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="grid gap-6 lg:grid-cols-[1fr_320px]">
          <div className="flex flex-col gap-6">
            {(programs ?? []).length > 0 && (
              <PanelBolumKarti title="Aktif Programlar" noPadding>
                <ul className="divide-y divide-border">
                  {(programs as any[]).map((p: any) => (
                    <li key={p.id} className="flex items-center gap-4 px-5 py-4">
                      <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-[var(--yd-color-primary-soft)] text-xl">
                        🎫
                      </div>
                      <div className="flex-1">
                        <p className="font-[800] text-textStrong">{p.name}</p>
                        <p className="text-xs text-muted">
                          {bizMap[p.business_id] ?? '—'} · {p.stamps_needed} damga → {p.reward_desc}
                        </p>
                      </div>
                      <span className={`rounded-full px-2 py-0.5 text-[11px] font-[800] ${p.is_active ? 'bg-success/[0.10] text-success' : 'bg-border text-muted'}`}>
                        {p.is_active ? 'Aktif' : 'Pasif'}
                      </span>
                    </li>
                  ))}
                </ul>
              </PanelBolumKarti>
            )}
            <PanelBolumKarti title="Yeni Sadakat Programı">
              <SadakatProgramFormu businesses={businesses} />
            </PanelBolumKarti>
          </div>

          <div className="rounded-xl border border-border bg-cardAlt p-5">
            <p className="mb-3 text-sm font-[900] text-textStrong">Nasıl çalışır?</p>
            <ol className="space-y-3 text-sm text-muted">
              {[
                'Program oluşturun: "10 kahvaltı → 1 bedava kahvaltı"',
                'Müşteri her gelişinde damga alır — hesabından görür',
                'Hedef damgaya ulaşınca ödülü etkinleştirin',
                'Müşteri geri gelme motivasyonu artar',
              ].map((step, i) => (
                <li key={i} className="flex gap-2">
                  <span className="flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-primary/[0.12] text-[11px] font-[900] text-primary">
                    {i + 1}
                  </span>
                  {step}
                </li>
              ))}
            </ol>
          </div>
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}
