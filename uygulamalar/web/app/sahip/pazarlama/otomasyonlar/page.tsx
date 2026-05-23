import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinesses } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { OtomasyonToggle } from './otomasyon-toggle';

export const metadata: Metadata = {
  title: 'Otomasyonlar | Sahip Paneli',
  robots: { index: false, follow: false },
};

const TEMPLATES = [
  {
    id: 'birthday_message',
    label: 'Doğum Günü Mesajı',
    description: 'Müşterinin doğum gününde otomatik tebrik ve indirim kodu gönder.',
    trigger: 'Doğum günü',
    icon: '🎂',
    category: 'Kişiselleştirilmiş',
  },
  {
    id: 'post_visit_thankyou',
    label: 'Ziyaret Sonrası Teşekkür',
    description: 'İşletmeyi ziyaret eden müşteriye 24 saat sonra teşekkür mesajı gönder.',
    trigger: 'Ziyaret tespiti',
    icon: '🙏',
    category: 'Sadakat',
  },
  {
    id: 'inactive_winback',
    label: 'Pasif Müşteri Geri Kazanma',
    description: '60 gündür ziyaret etmeyen müşterilere "özledik" kampanyası başlat.',
    trigger: '60 gün hareketsizlik',
    icon: '💌',
    category: 'Geri Kazanma',
  },
  {
    id: 'loyalty_milestone',
    label: 'Sadakat Kilometre Taşı',
    description: '5. ve 10. ziyarette özel ödül bildirimi gönder.',
    trigger: 'Damga sayısı',
    icon: '⭐',
    category: 'Sadakat',
  },
  {
    id: 'review_request',
    label: 'Değerlendirme İsteği',
    description: 'Ziyaretten 2 gün sonra müşteriyi yorum bırakmaya davet et.',
    trigger: 'Ziyaret + 2 gün',
    icon: '⭐',
    category: 'İtibar',
  },
  {
    id: 'new_menu_announcement',
    label: 'Yeni Menü Duyurusu',
    description: 'Menüye yeni ürün eklediğinde takipçileri otomatik haberdar et.',
    trigger: 'Menü güncellemesi',
    icon: '🍽️',
    category: 'Duyuru',
  },
] as const;

export default async function OwnerAutomationsPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const businesses = user
    ? (await getOwnerBusinesses<{ id: string; name: string }>(
        supabase as any,
        user.id,
        'id, name',
      ))
    : [];

  const bizIds = businesses.map((b: { id: string }) => b.id);

  let enabledSet = new Set<string>();
  let tableReady = false;

  if (bizIds.length > 0) {
    const { data, error } = await (supabase as any)
      .from('business_automations')
      .select('template_id')
      .in('business_id', bizIds)
      .eq('is_enabled', true);

    if (!error) {
      tableReady = true;
      enabledSet = new Set((data ?? []).map((r: any) => r.template_id as string));
    }
  }

  const firstBizId = bizIds[0] ?? null;

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Pazarlama"
        title="Otomasyonlar"
        description="Tetikleyici bazlı mesajlarla müşteri ilişkisini otomatikleştirin"
      />
      <PanelIcerikYuzeyi className="pt-6">
        {!tableReady && (
          <div className="mb-5 rounded-xl border border-amber-200 bg-amber-50 px-5 py-3 text-sm text-amber-800">
            Otomasyon altyapısı yapılandırılıyor. Listeler hazır görünüyor; aktivasyon yakında açılacak.
          </div>
        )}

        <div className="grid gap-4 sm:grid-cols-2">
          {TEMPLATES.map((tmpl) => (
            <div
              key={tmpl.id}
              className="flex items-start gap-4 rounded-2xl border border-border bg-card p-5"
            >
              <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl border border-border bg-bg text-xl">
                {tmpl.icon}
              </span>
              <div className="flex-1 min-w-0">
                <div className="flex items-start justify-between gap-2">
                  <div>
                    <p className="font-[800] text-textStrong">{tmpl.label}</p>
                    <p className="mt-0.5 text-xs text-muted">{tmpl.description}</p>
                  </div>
                  <OtomasyonToggle
                    templateId={tmpl.id}
                    businessId={firstBizId}
                    enabled={enabledSet.has(tmpl.id)}
                    disabled={!tableReady || !firstBizId}
                  />
                </div>
                <div className="mt-3 flex items-center gap-2">
                  <span className="rounded-md bg-border/30 px-2 py-0.5 text-[10px] font-[700] text-muted">
                    {tmpl.trigger}
                  </span>
                  <span className="rounded-md bg-primary/8 px-2 py-0.5 text-[10px] font-[800] text-primary">
                    {tmpl.category}
                  </span>
                </div>
              </div>
            </div>
          ))}
        </div>

        <PanelBolumKarti title="Nasıl çalışır?" className="mt-6">
          <ol className="space-y-2 text-sm text-muted">
            {[
              'Otomasyon şablonunu etkinleştirin',
              'Tetikleyici koşul oluştuğunda (ziyaret, süre, damga vb.) sistem otomatik mesaj gönderir',
              'Performans raporunu Analitik sayfasından takip edin',
            ].map((s, i) => (
              <li key={i} className="flex gap-2">
                <span className="flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-primary/[0.12] text-[11px] font-[900] text-primary">
                  {i + 1}
                </span>
                {s}
              </li>
            ))}
          </ol>
        </PanelBolumKarti>
      </PanelIcerikYuzeyi>
    </div>
  );
}
