import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { MetricCard } from '@/src/ui/bilesenler/olcum-karti';

export const metadata: Metadata = {
  title: 'Fraud Tespiti | Yönetici Paneli',
  robots: { index: false, follow: false },
};

export default async function FraudTespitiPage() {
  const supabase = await createSupabaseServerClient();

  const yediGunOnce = new Date(Date.now() - 7 * 86400000).toISOString();
  const otuzGunOnce = new Date(Date.now() - 30 * 86400000).toISOString();

  async function detectSpamReviews() {
    try {
      return await (supabase as any).rpc('detect_spam_reviews_v1', { p_days: 7, p_min_count: 5 });
    } catch {
      return { data: [] };
    }
  }

  // Şüpheli yorum tespiti: aynı IP'den çok fazla yorum, aynı kullanıcıdan çok fazla yorum
  const [
    tekrarliYorumlarRes,
    hizliKayitRes,
    yeniYorumFlagRes,
    toplamFlagRes,
  ] = await Promise.all([
    // Aynı kullanıcıdan 7 günde 5+ yorum
    detectSpamReviews(),
    // Son 7 günde 50+ yeni kayıt (bot)
    (supabase as any)
      .from('user_profiles')
      .select('user_id', { count: 'exact', head: true })
      .gte('created_at', yediGunOnce),
    // Son 30 günde şikayet edilen yorumlar
    (supabase as any)
      .from('reports')
      .select('id', { count: 'exact', head: true })
      .eq('target_type', 'review')
      .gte('created_at', otuzGunOnce),
    // Toplam açık şikayet
    (supabase as any)
      .from('reports')
      .select('id', { count: 'exact', head: true })
      .eq('target_type', 'review')
      .eq('status', 'open'),
  ]);

  // Şüpheli kullanıcılar: kısa sürede çok yorum
  const sphUsers = (tekrarliYorumlarRes.data ?? []) as Array<{
    user_id: string;
    review_count: number;
    display_name: string | null;
  }>;

  // Son flaglenen yorumlar
  const { data: sonFlagler } = await (supabase as any)
    .from('reports')
    .select('id, review_id, target_id, reason, details, created_at, reviews:review_id(content, rating, business_id)')
    .eq('target_type', 'review')
    .order('created_at', { ascending: false })
    .limit(20);

  const flagListesi = (sonFlagler ?? []) as Array<{
    id: string;
    review_id: string | null;
    target_id: string;
    reason: string | null;
    details: string | null;
    created_at: string;
    reviews: { content: string | null; rating: number; business_id: string } | null;
  }>;

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Admin"
        title="Fraud Tespiti"
        description="Sahte yorum, bot hesap ve anormallik analizi"
      />
      <PanelIcerikYuzeyi className="pt-6">
        {/* Özet metrikler */}
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <MetricCard
            title="Şüpheli Kullanıcı"
            value={sphUsers.length.toString()}
            subtitle="7 günde 5+ yorum"
            icon={<AlertIcon />}
          />
          <MetricCard
            title="Yeni Kayıt (7g)"
            value={(hizliKayitRes.count ?? 0).toLocaleString('tr-TR')}
            subtitle="Bot risk analizi"
            icon={<UserPlusIcon />}
          />
          <MetricCard
            title="Yeni Şikayet (30g)"
            value={(yeniYorumFlagRes.count ?? 0).toLocaleString('tr-TR')}
            subtitle="Son 30 gün"
            icon={<FlagIcon />}
          />
          <MetricCard
            title="Bekleyen Şikayet"
            value={(toplamFlagRes.count ?? 0).toLocaleString('tr-TR')}
            subtitle="İnceleme gerekiyor"
            icon={<ClockIcon />}
          />
        </div>

        {/* Şüpheli kullanıcılar */}
        {sphUsers.length > 0 && (
          <PanelBolumKarti title="Şüpheli Kullanıcılar (7 günde 5+ yorum)" noPadding className="mt-6">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border text-left">
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Kullanıcı</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted text-right">Yorum Sayısı</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">İşlem</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {sphUsers.map(u => (
                  <tr key={u.user_id} className="hover:bg-cardAlt/50">
                    <td className="px-5 py-3">
                      <div className="flex items-center gap-2">
                        <span className="flex h-7 w-7 items-center justify-center rounded-full bg-danger/10 text-xs font-[800] text-danger">
                          {u.display_name?.[0]?.toUpperCase() ?? '?'}
                        </span>
                        <span className="font-[700] text-textStrong">{u.display_name ?? 'Anonim'}</span>
                      </div>
                    </td>
                    <td className="px-5 py-3 text-right">
                      <span className="rounded-full bg-danger/10 px-2 py-0.5 text-xs font-[900] text-danger">
                        {u.review_count} yorum
                      </span>
                    </td>
                    <td className="px-5 py-3">
                      <Link
                        href={`/yonetici/kullanicilar?id=${u.user_id}`}
                        className="text-xs font-[700] text-primary hover:underline"
                      >
                        İncele →
                      </Link>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </PanelBolumKarti>
        )}

        {/* Şikayet edilen yorumlar */}
        <PanelBolumKarti title="Son Şikayet Edilen Yorumlar" noPadding className="mt-6">
          {flagListesi.length === 0 ? (
            <div className="px-5 py-10 text-center text-sm text-muted">
              Bekleyen şikayet yok ✓
            </div>
          ) : (
            <div className="divide-y divide-border">
              {flagListesi.map(flag => (
                <div key={flag.id} className="flex items-start gap-4 px-5 py-4">
                  <div className="mt-0.5 shrink-0">
                    <span className="flex h-8 w-8 items-center justify-center rounded-xl bg-warning/10">
                      <FlagIcon />
                    </span>
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <span className="text-xs font-[700] text-textStrong">
                        {flag.reason ?? flag.details ?? 'Sebep belirtilmedi'}
                      </span>
                      {flag.reviews && (
                        <span className="text-[10px] text-muted">
                          ★ {flag.reviews.rating}
                        </span>
                      )}
                    </div>
                    {flag.reviews?.content && (
                      <p className="mt-0.5 line-clamp-2 text-xs text-muted">{flag.reviews.content}</p>
                    )}
                    <p className="mt-0.5 text-[11px] text-muted">
                      {new Date(flag.created_at).toLocaleDateString('tr-TR')}
                    </p>
                  </div>
                  <div className="shrink-0">
                    <Link
                      href={`/yonetici/yorumlar?id=${flag.review_id ?? flag.target_id}`}
                      className="rounded-lg border border-border px-3 py-1.5 text-xs font-[700] text-textStrong hover:border-primary/30 transition-colors"
                    >
                      İncele
                    </Link>
                  </div>
                </div>
              ))}
            </div>
          )}
        </PanelBolumKarti>

        {/* Otomatik tespit kuralları */}
        <PanelBolumKarti title="Tespit Kuralları" className="mt-6">
          <div className="grid gap-3 sm:grid-cols-2">
            <KuralKart
              baslik="Hız Limiti Kuralı"
              aciklama="Kullanıcı 7 günde 5+ yorum → otomatik inceleme kuyruğuna girer"
              aktif
            />
            <KuralKart
              baslik="IP Bazlı Tespit"
              aciklama="Aynı IP'den 24s içinde 10+ istek → geçici engel"
              aktif
            />
            <KuralKart
              baslik="Yeni Hesap Koruma"
              aciklama="Kayıttan 24 saat içinde yorum → ekstra doğrulama"
              aktif={false}
            />
            <KuralKart
              baslik="AI İçerik Analizi"
              aciklama="GPT-4o ile spam/toksik içerik otomatik tespiti"
              aktif={false}
            />
          </div>
        </PanelBolumKarti>
      </PanelIcerikYuzeyi>
    </div>
  );
}

function KuralKart({ baslik, aciklama, aktif }: { baslik: string; aciklama: string; aktif: boolean }) {
  return (
    <div className={`rounded-xl border p-4 ${aktif ? 'border-success/30 bg-success/[0.04]' : 'border-border bg-card opacity-60'}`}>
      <div className="flex items-center gap-2">
        <span className={`h-2 w-2 rounded-full ${aktif ? 'bg-success' : 'bg-muted'}`} />
        <span className="font-[800] text-sm text-textStrong">{baslik}</span>
      </div>
      <p className="mt-1 text-xs text-muted">{aciklama}</p>
    </div>
  );
}

function AlertIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z" /><line x1="12" y1="9" x2="12" y2="13" /><line x1="12" y1="17" x2="12.01" y2="17" /></svg>; }
function UserPlusIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="8.5" cy="7" r="4" /><line x1="20" y1="8" x2="20" y2="14" /><line x1="23" y1="11" x2="17" y2="11" /></svg>; }
function FlagIcon() { return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1z" /><line x1="4" y1="22" x2="4" y2="15" /></svg>; }
function ClockIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10" /><polyline points="12 6 12 12 16 14" /></svg>; }
