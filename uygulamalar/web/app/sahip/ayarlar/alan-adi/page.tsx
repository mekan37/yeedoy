import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinesses } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';

export const metadata: Metadata = {
  title: 'Özel Domain | Sahip Paneli',
  robots: { index: false, follow: false },
};

export default async function OwnerSettingsDomainPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const list = user
    ? await getOwnerBusinesses<{ id: string; name: string; custom_domain: string | null }>(
      supabase as any,
      user.id,
      'id, name, custom_domain',
    )
    : [];

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Owner"
        title="Özel Domain"
        description="İşletmeleriniz için özel alan adı ayarlarını yönetin"
      />
      <PanelIcerikYuzeyi className="pt-6">
        {list.length === 0 ? (
          <PanelEmptyState
            icon={<GlobeIcon />}
            title="İşletme bulunamadı"
            description="Özel domain eklemek için önce bir işletme oluşturun."
          />
        ) : (
          <div className="flex flex-col gap-4">
            {list.map((b) => (
              <PanelBolumKarti key={b.id} title={b.name}>
                <div className="flex flex-col gap-3">
                  <div>
                    <p className="text-xs font-[700] uppercase tracking-wide text-muted mb-1">Mevcut Domain</p>
                    {b.custom_domain ? (
                      <div className="flex items-center gap-2">
                        <span className="rounded-lg border border-green-200 bg-green-50 px-3 py-1.5 text-sm font-[700] text-green-700">
                          {b.custom_domain}
                        </span>
                        <span className="rounded-full bg-green-50 px-2 py-0.5 text-[11px] font-[800] text-green-700">
                          Aktif
                        </span>
                      </div>
                    ) : (
                      <span className="text-sm text-muted">Özel domain tanımlanmamış</span>
                    )}
                  </div>
                  <div className="rounded-lg border border-border bg-zinc-50 px-4 py-3 text-xs text-muted">
                    Domain ekleme ve doğrulama özellikleri yakında aktif olacak. Ekibimizle iletişime geçin.
                  </div>
                </div>
              </PanelBolumKarti>
            ))}
          </div>
        )}
      </PanelIcerikYuzeyi>
    </div>
  );
}

function GlobeIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="10" />
      <line x1="2" y1="12" x2="22" y2="12" />
      <path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z" />
    </svg>
  );
}

