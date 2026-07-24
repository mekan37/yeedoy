import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PushIzinButonu } from './push-izin-butonu';
import { BildirimTercihleri } from './bildirim-tercihleri';
import { PazarlamaEmailToggle } from './pazarlama-email-toggle';

export const metadata: Metadata = {
  title: 'Bildirim Ayarları | Yeedoy',
  robots: { index: false, follow: false },
};

const NOTIFICATION_TYPES = [
  {
    key: 'review_replies',
    label: 'Yorum Yanıtları',
    description: 'Yorumlarınıza gelen yanıtlardan haberdar olun',
  },
  {
    key: 'price_alerts',
    label: 'Fiyat Alarmları',
    description: 'Takip ettiğiniz fiyatlar değiştiğinde bildirim alın',
  },
  {
    key: 'new_businesses',
    label: 'Yeni İşletmeler',
    description: 'Çevrenizde açılan yeni mekanlardan haberdar olun',
  },
] as const;

export default async function BildirimAyarlariPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  let prefs: Record<string, boolean> = {};
  try {
    const { data } = await (supabase as any)
      .from('notification_preferences')
      .select('notification_type, enabled')
      .eq('user_id', user!.id);
    if (Array.isArray(data)) {
      for (const row of (data as Array<{ notification_type: string; enabled: boolean }>)) {
        prefs[row.notification_type] = row.enabled;
      }
    }
  } catch {
    // Table not yet migrated; show defaults
  }

  // Global pazarlama e-posta tercihi (user_profiles.marketing_email_opt_in)
  // migration 20260620000001 uygulanmadan önce sütun yoktur; hata durumunda false default.
  let marketingEmailEnabled = false;
  try {
    const { data: profileData } = await (supabase as any)
      .from('user_profiles')
      .select('marketing_email_opt_in')
      .eq('user_id', user!.id)
      .single();
    if (profileData && typeof profileData.marketing_email_opt_in === 'boolean') {
      marketingEmailEnabled = profileData.marketing_email_opt_in;
    }
  } catch {
    // Sütun henüz yok veya sorgu hatası — default false ile devam et
  }

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-lg px-4 py-12">
        <Link href="/profil" className="mb-6 inline-flex items-center gap-1.5 text-sm text-muted hover:text-primary">
          ← Profilime Dön
        </Link>
        <h1 className="mb-2 text-2xl font-black text-textStrong">Bildirim Ayarları</h1>
        <p className="mb-8 text-sm leading-relaxed text-muted">
          Push bildirimleri için önce izin verin, ardından hangi olaylardan haber almak istediğinizi seçin.
        </p>

        <section className="mb-8 rounded-2xl border border-border bg-card p-6">
          <h2 className="mb-1 text-base font-black text-textStrong">Push İzni</h2>
          <p className="mb-4 text-sm text-muted">
            Tarayıcınızın bildirim iznini etkinleştirmek için aşağıdaki butona tıklayın.
          </p>
          <PushIzinButonu />
        </section>

        <section className="mb-8 rounded-2xl border border-border bg-card p-6">
          <h2 className="mb-4 text-base font-black text-textStrong">Bildirim Türleri</h2>
          <BildirimTercihleri
            userId={user!.id}
            types={NOTIFICATION_TYPES as unknown as Array<{ key: string; label: string; description: string }>}
            initialPrefs={prefs}
          />
        </section>

        {/* E-posta tercihleri — global pazarlama izni */}
        <section className="rounded-2xl border border-border bg-card p-6">
          <h2 className="mb-1 text-base font-black text-textStrong">E-posta Tercihleri</h2>
          <p className="mb-4 text-sm text-muted">
            Yeedoy&apos;dan gelen e-postaları yönetin.
          </p>
          <PazarlamaEmailToggle initialEnabled={marketingEmailEnabled} />
          <p className="mt-3 text-xs leading-relaxed text-muted">
            Bu tercihi kapatırsanız Yeedoy&apos;dan pazarlama e-postası almayı bırakırsınız.
            İşletmelerin gönderdiği kampanya e-postaları için ayrıca her işletmenin takip
            sayfasından aboneliğinizi yönetebilirsiniz.
          </p>
        </section>
      </div>
    </main>
  );
}
