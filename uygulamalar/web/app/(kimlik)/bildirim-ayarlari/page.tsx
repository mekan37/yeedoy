import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PushIzinButonu } from './push-izin-butonu';
import { BildirimTercihleri } from './bildirim-tercihleri';

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

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-lg px-4 py-12">
        <Link href="/profil" className="mb-6 inline-flex items-center gap-1.5 text-sm text-muted hover:text-primary">
          ← Profilime Dön
        </Link>
        <h1 className="mb-2 text-2xl font-[900] text-textStrong">Bildirim Ayarları</h1>
        <p className="mb-8 text-sm leading-relaxed text-muted">
          Push bildirimleri için önce izin verin, ardından hangi olaylardan haber almak istediğinizi seçin.
        </p>

        <section className="mb-8 rounded-2xl border border-border bg-card p-6">
          <h2 className="mb-1 text-base font-[900] text-textStrong">Push İzni</h2>
          <p className="mb-4 text-sm text-muted">
            Tarayıcınızın bildirim iznini etkinleştirmek için aşağıdaki butona tıklayın.
          </p>
          <PushIzinButonu />
        </section>

        <section className="rounded-2xl border border-border bg-card p-6">
          <h2 className="mb-4 text-base font-[900] text-textStrong">Bildirim Türleri</h2>
          <BildirimTercihleri
            userId={user!.id}
            types={NOTIFICATION_TYPES as unknown as Array<{ key: string; label: string; description: string }>}
            initialPrefs={prefs}
          />
        </section>
      </div>
    </main>
  );
}
