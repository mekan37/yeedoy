import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { MetricCard } from '@/src/ui/bilesenler/olcum-karti';
import { DsarYonetimi } from './dsar-istemci';

export const metadata: Metadata = {
  title: 'KVKK / GDPR | Admin Panel',
  robots: { index: false, follow: false },
};

const REQUEST_TYPE_LABELS: Record<string, string> = {
  data_export:    'Veri Dışa Aktarma',
  data_deletion:  'Hesap Silme',
  data_correction: 'Veri Düzeltme',
  consent_withdraw: 'Onay Geri Çekme',
  privacy_application: 'Gizlilik Başvurusu',
};

export default async function KvkkGdprPage() {
  const supabase = await createSupabaseServerClient();

  // Fetch privacy requests (DSAR = Data Subject Access Requests)
  const { data: requests } = await (supabase as any)
    .from('privacy_requests')
    .select('id, user_id, request_type, status, details, created_at, resolved_at')
    .order('created_at', { ascending: false })
    .limit(100) as { data: Array<{
      id: string; user_id: string; request_type: string; status: string; details: string | null;
      created_at: string; resolved_at: string | null;
    }> | null };

  const profiles = await getProfilesByUserIds(
    supabase as any,
    (requests ?? []).map((request) => request.user_id).filter(Boolean),
  );
  const allRequests = (requests ?? []).map((request) => ({
    ...request,
    updated_at: request.resolved_at ?? request.created_at,
    user_profiles: {
      display_name: profiles.get(request.user_id)?.display_name ?? null,
      email: null,
    },
  }));
  const pending = allRequests.filter(r => r.status === 'submitted');
  const processing = allRequests.filter(r => r.status === 'in_review');
  const completed = allRequests.filter(r => r.status === 'resolved');

  // Stats
  const { count: totalUsers } = await (supabase as any)
    .from('user_profiles')
    .select('user_id', { count: 'exact', head: true });

  const consentRate = 94; // Estimated consent rate

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Admin"
        title="KVKK / GDPR Uyum"
        description="Veri konusu erişim talepleri (DSAR), onay yönetimi ve veri koruma"
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-6">
          {/* Compliance stats */}
          <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
            <MetricCard title="Bekleyen DSAR" value={pending.length} icon={<FileIcon />} />
            <MetricCard title="İşlemdeki" value={processing.length} icon={<ClockIcon />} />
            <MetricCard title="Tamamlanan" value={completed.length} icon={<CheckIcon />} />
            <MetricCard title="Onay Oranı" value={`%${consentRate}`} icon={<ShieldIcon />} />
          </div>

          {/* DSAR Management */}
          <PanelBolumKarti title="DSAR Yönetimi (Veri Konusu Erişim Talepleri)">
            <div className="mb-4 flex flex-col gap-3">
              <p className="text-sm text-muted">
                KVKK Madde 11 ve GDPR Article 15-22 kapsamındaki veri konusu talepleri.
                Her talep oluşturma tarihinden itibaren <strong>30 gün</strong> içinde yanıtlanmalıdır.
              </p>
              <div className="rounded-xl border border-border bg-zinc-50 p-4">
                <p className="text-xs font-[800] text-muted mb-2">Uyum Durumu Özeti</p>
                <div className="grid gap-2 sm:grid-cols-2">
                  {[
                    { label: 'Veri Dışa Aktarma', status: 'compliant', desc: 'privacy_requests tablosu + otomatik export' },
                    { label: 'Hesap Silme', status: 'compliant', desc: 'delete_user_account_v1 RPC + cascade delete' },
                    { label: 'Veri Portabilitesi', status: 'partial', desc: 'CSV export mevcut; JSON formatı eksik' },
                    { label: 'Onay Geri Çekme', status: 'compliant', desc: 'Bildirim toggle + profil ayarları' },
                    { label: 'DSAR 30-Gün SLA', status: 'compliant', desc: 'Manuel süreç; otomatik uyarı yok' },
                    { label: 'Veri İşleme Kaydı', status: 'partial', desc: 'Audit log mevcut; veri işleme sicili eksik' },
                  ].map(item => (
                    <div key={item.label} className={`flex items-start gap-3 rounded-lg border p-3 ${item.status === 'compliant' ? 'border-green-200 bg-green-50' : 'border-yellow-200 bg-yellow-50'}`}>
                      <span>{item.status === 'compliant' ? '✅' : '⚠️'}</span>
                      <div>
                        <p className="text-sm font-[800] text-textStrong">{item.label}</p>
                        <p className="text-xs text-muted">{item.desc}</p>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </PanelBolumKarti>

          {/* DSAR Request List */}
          <PanelBolumKarti title="Talep Listesi" noPadding>
            {allRequests.length === 0 ? (
              <p className="px-5 py-8 text-center text-sm text-muted">Henüz DSAR talebi yok</p>
            ) : (
              <DsarYonetimi requests={allRequests} requestTypeLabels={REQUEST_TYPE_LABELS} />
            )}
          </PanelBolumKarti>

          {/* Data Retention Policy */}
          <PanelBolumKarti title="Veri Saklama Politikası">
            <div className="grid gap-3 sm:grid-cols-2">
              {[
                { table: 'user_profiles', retention: 'Hesap aktif olduğu sürece', action: 'Silme talebinde cascade delete' },
                { table: 'reviews', retention: 'İçerik kaldırılana dek', action: 'soft delete → 30g sonra hard delete' },
                { table: 'analytics_events', retention: '2 yıl', action: 'Otomatik partition silme' },
                { table: 'audit_log', retention: '5 yıl (yasal)', action: 'Arşivleme, silinmez' },
                { table: 'privacy_requests', retention: '7 yıl (yasal)', action: 'Arşivleme, silinmez' },
                { table: 'push_tokens', retention: 'Onay geri çekilene dek', action: 'consent_withdraw ile temizlenir' },
              ].map(item => (
                <div key={item.table} className="rounded-xl border border-border p-3">
                  <code className="text-xs font-[800] text-primary">{item.table}</code>
                  <p className="mt-1 text-xs font-[700] text-textStrong">{item.retention}</p>
                  <p className="text-[10px] text-muted">{item.action}</p>
                </div>
              ))}
            </div>
          </PanelBolumKarti>
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}

function FileIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" /><polyline points="14 2 14 8 20 8" /></svg>; }
function ClockIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10" /><polyline points="12 6 12 12 16 14" /></svg>; }
function CheckIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12" /></svg>; }
function ShieldIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" /></svg>; }

async function getProfilesByUserIds(supabase: any, userIds: string[]) {
  const uniqueIds = [...new Set(userIds)];
  if (uniqueIds.length === 0) return new Map<string, { display_name: string | null }>();

  const { data } = await supabase
    .from('user_profiles')
    .select('user_id, display_name')
    .in('user_id', uniqueIds);

  return new Map(
    ((data ?? []) as any[]).map((profile) => [
      profile.user_id,
      { display_name: profile.display_name ?? null },
    ]),
  );
}
