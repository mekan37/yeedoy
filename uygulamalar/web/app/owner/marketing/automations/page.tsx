import type { Metadata } from 'next';
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinesses } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { getOwnerAutomations } from '@/src/lib/veri/owner/otomasyonlar';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';
import { AutomationToggle } from './automation-toggle';

export const metadata: Metadata = {
  title: 'Otomasyonlar | Owner Panel',
  robots: { index: false, follow: false },
};

const AUTOMATION_TEMPLATES = [
  {
    id: 'birthday_message',
    label: 'Doğum Günü Mesajı',
    description: 'Müşterinin doğum gününde otomatik tebrik ve indirim kodu gönder.',
    trigger: 'Doğum günü',
    icon: '🎂',
    category: 'Kişisel',
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

interface PageProps {
  searchParams: Promise<{ business_id?: string }>;
}

export default async function OwnerAutomationsPage({ searchParams }: PageProps) {
  const supabase = await createSupabaseServerClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect('/login?redirect=/owner/marketing/automations');
  }

  type BusinessRow = { id: string; name: string };

  const businesses = await getOwnerBusinesses<BusinessRow>(
    supabase as any,
    user.id,
    'id, name',
  );

  if (businesses.length === 0) {
    return (
      <div className="flex flex-col">
        <PanelPageHeader
          eyebrow="Pazarlama"
          title="Otomasyonlar"
          description="Tetikleyici bazlı mesajlarla müşteri ilişkisini otomatikleştirin"
        />
        <PanelContentSurface className="pt-6">
          <PanelEmptyState
            icon={<ZapIcon />}
            title="Henüz bir işletmeniz yok"
            description="Otomasyon oluşturabilmek için önce bir işletme sahiplenmeniz gerekiyor."
          />
        </PanelContentSurface>
      </div>
    );
  }

  const { business_id: qBusinessId } = await searchParams;
  const selectedId =
    qBusinessId && businesses.some((b) => b.id === qBusinessId)
      ? qBusinessId
      : businesses[0].id;

  const businessIds = businesses.map((b) => b.id);
  const { automations, fetchError } = await getOwnerAutomations(supabase as any, businessIds);

  const enabledSet = new Set(
    automations
      .filter((a) => a.business_id === selectedId && a.is_enabled)
      .map((a) => a.template_id),
  );

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Pazarlama"
        title="Otomasyonlar"
        description="Tetikleyici bazlı mesajlarla müşteri ilişkisini otomatikleştirin"
      />

      <PanelContentSurface className="pt-6">
        {/* Delivery pending banner */}
        <div
          role="note"
          className="mb-5 rounded-xl border border-blue-200 bg-blue-50 px-5 py-3 text-sm text-blue-800"
        >
          Bildirim gönderimi yakında aktif edilecek. Şu an otomasyonlar planlanmış durumda
          kaydediliyor.
        </div>

        {fetchError && (
          <div
            role="alert"
            className="mb-5 rounded-xl border border-amber-200 bg-amber-50 px-5 py-3 text-sm font-[700] text-amber-800"
          >
            Otomasyon bilgileri yüklenirken hata oluştu. Sayfa varsayılan değerlerle gösteriliyor.
          </div>
        )}

        {/* Business selector — shown only when owner has multiple businesses */}
        {businesses.length > 1 && (
          <div className="mb-6">
            <BusinessSelector businesses={businesses} selectedId={selectedId} />
          </div>
        )}

        <div className="grid gap-6 lg:grid-cols-[1fr_288px]">
          {/* Template cards */}
          <div className="grid gap-4 sm:grid-cols-2">
            {AUTOMATION_TEMPLATES.map((tmpl) => (
              <div
                key={tmpl.id}
                className="flex items-start gap-4 rounded-2xl border border-border bg-card p-5"
              >
                <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl border border-border bg-bg text-xl">
                  {tmpl.icon}
                </span>
                <div className="flex-1 min-w-0">
                  <div className="flex items-start justify-between gap-2">
                    <div className="min-w-0">
                      <p className="font-[800] text-textStrong">{tmpl.label}</p>
                      <p className="mt-0.5 text-xs text-muted">{tmpl.description}</p>
                    </div>
                    <AutomationToggle
                      templateId={tmpl.id}
                      businessId={selectedId}
                      enabled={enabledSet.has(tmpl.id)}
                      disabled={fetchError}
                    />
                  </div>
                  <div className="mt-3 flex items-center gap-2">
                    <span className="rounded-md bg-border/30 px-2 py-0.5 text-[10px] font-[700] text-muted">
                      {tmpl.trigger}
                    </span>
                    <span className="rounded-md bg-primary/[0.08] px-2 py-0.5 text-[10px] font-[800] text-primary">
                      {tmpl.category}
                    </span>
                  </div>
                </div>
              </div>
            ))}
          </div>

          {/* Info sidebar */}
          <aside>
            <PanelSectionCard title="Nasıl çalışır?">
              <ol className="space-y-3 text-sm text-muted">
                {[
                  'Otomasyon şablonunu etkinleştirin.',
                  'Tetikleyici koşul oluştuğunda (ziyaret, süre, damga vb.) sistem otomatik mesaj gönderir.',
                  'Performans raporunu Analitik sayfasından takip edin.',
                ].map((step, i) => (
                  <li key={i} className="flex gap-2.5">
                    <span className="flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-primary/[0.12] text-[11px] font-[900] text-primary">
                      {i + 1}
                    </span>
                    {step}
                  </li>
                ))}
              </ol>
              <div className="mt-4 rounded-lg border border-border bg-bg p-3 text-xs text-muted">
                <strong className="font-[700] text-textStrong">Not:</strong> Otomasyonlar şu an
                pasif/taslak olarak kaydedilir. Dış bildirim sağlayıcısı (push/SMS/e-posta)
                bağlandığında otomatik devreye girer.
              </div>
            </PanelSectionCard>
          </aside>
        </div>
      </PanelContentSurface>
    </div>
  );
}

// ---- sub-components ----

function BusinessSelector({
  businesses,
  selectedId,
}: {
  businesses: Array<{ id: string; name: string }>;
  selectedId: string;
}) {
  return (
    <form method="GET" className="flex items-center gap-3">
      <label htmlFor="biz_select" className="shrink-0 text-sm font-[700] text-textStrong">
        İşletme:
      </label>
      <select
        id="biz_select"
        name="business_id"
        defaultValue={selectedId}
        className="h-10 rounded-lg border border-border bg-card px-3 text-sm text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/30"
      >
        {businesses.map((b) => (
          <option key={b.id} value={b.id}>
            {b.name}
          </option>
        ))}
      </select>
      <button
        type="submit"
        className="rounded-lg border border-border bg-card px-3 py-2 text-sm font-[700] text-textStrong hover:bg-black/[0.04]"
      >
        Seç
      </button>
    </form>
  );
}

function ZapIcon() {
  return (
    <svg
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2" />
    </svg>
  );
}
