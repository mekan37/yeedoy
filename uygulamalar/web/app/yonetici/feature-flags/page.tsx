import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { FlagToggle, YeniFlagForm } from './flag-islemleri';

export const metadata: Metadata = {
  title: 'Feature Flags | Yönetici Paneli',
  robots: { index: false, follow: false },
};

type Flag = {
  key: string;
  enabled: boolean;
  rollout_percent: number;
  metadata: { description?: string; environment?: string } | null;
  updated_at: string;
};

export default async function FeatureFlagsPage() {
  const supabase = await createSupabaseServerClient();

  const { data: flags } = await (supabase as any)
    .from('runtime_feature_flags')
    .select('key, enabled, rollout_percent, metadata, updated_at')
    .order('key', { ascending: true }) as { data: Flag[] | null };

  const liste = flags ?? [];
  const aktifSayi = liste.filter(f => f.enabled).length;

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Yönetici"
        title="Feature Flags"
        description={`${aktifSayi}/${liste.length} flag aktif`}
      />
      <PanelIcerikYuzeyi className="pt-6">
        {/* Yeni flag formu */}
        <PanelBolumKarti title="Yeni Flag Ekle" className="mb-6">
          <YeniFlagForm />
        </PanelBolumKarti>

        {/* Flag listesi */}
        <PanelBolumKarti title="Tüm Flagler" noPadding>
          {liste.length === 0 ? (
            <div className="px-5 py-10 text-center text-sm text-muted">
              Henüz flag yok. Yukarıdan ekleyin.
            </div>
          ) : (
            <div className="divide-y divide-border">
              {liste.map(flag => (
                <div key={flag.key} className="flex items-center gap-4 px-5 py-4">
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <code className="rounded bg-cardAlt px-2 py-0.5 text-xs font-bold text-primary">
                        {flag.key}
                      </code>
                      <span className={`rounded-full px-2 py-0.5 text-[10px] font-extrabold ${
                        flag.metadata?.environment === 'production'
                          ? 'bg-danger/10 text-danger'
                          : 'bg-info/10 text-info'
                      }`}>
                        {flag.metadata?.environment ?? 'all'}
                      </span>
                    </div>
                    {flag.metadata?.description && (
                      <p className="mt-0.5 text-xs text-muted">{flag.metadata.description}</p>
                    )}
                    <p className="mt-1 text-[11px] text-muted">
                      Yayılım: <strong>%{flag.rollout_percent}</strong> ·
                      Güncellendi: {new Date(flag.updated_at).toLocaleDateString('tr-TR')}
                    </p>
                  </div>
                  <FlagToggle flagId={flag.key} enabled={flag.enabled} rolloutPct={flag.rollout_percent} />
                </div>
              ))}
            </div>
          )}
        </PanelBolumKarti>

        {/* Bilgilendirme */}
        <div className="mt-4 rounded-xl border border-border bg-cardAlt p-4 text-xs text-muted">
          <strong>Production flaglerini</strong> dikkatli kullanın — değişiklikler anlık yürürlüğe girer.
          Kısmi yayılım (%rollout) için kullanıcılar ID hash&apos;ine göre seçilir.
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}
