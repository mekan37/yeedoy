import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { hasPermission } from '@/src/lib/yetki-kontrol';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { MetricCard } from '@/src/ui/bilesenler/olcum-karti';
import { YetkisizErisim } from '@/src/ui/bilesenler/yetkisiz-erisim';
import { DsarYonetimi } from './dsar-istemci';
import { HesapSilmeYonetimi } from './hesap-silme-istemci';
import { PolitikaYonetimi } from './politika-istemci';

export const metadata: Metadata = {
  title: 'KVKK / GDPR | Admin Panel',
  robots: { index: false, follow: false },
};

// privacy_requests.request_type CHECK kısıtındaki 13 gerçek değerle birebir
// eşleşiyor — önceki liste 3 hiç var olmayan kod (data_deletion,
// data_correction, consent_withdraw) içeriyordu, gerçek değerlerin çoğu
// (access, rectification, erasure, restriction, objection, portability,
// delete_*, other) hiç etiketlenmemişti ve panelde ham kod olarak görünüyordu.
const REQUEST_TYPE_LABELS: Record<string, string> = {
  data_export: 'Veri Dışa Aktarma',
  privacy_application: 'Gizlilik Başvurusu',
  access: 'Verilere Erişim',
  rectification: 'Veri Düzeltme',
  erasure: 'Hesap/Veri Silme',
  restriction: 'İşlemenin Kısıtlanması',
  objection: 'İtiraz',
  portability: 'Veri Taşınabilirliği',
  delete_data: 'Veri Silme',
  delete_interactions: 'Etkileşim Verisi Silme',
  delete_support: 'Destek Kaydı Silme',
  delete_owner_claims: 'Sahiplenme Talebi Silme',
  other: 'Diğer',
};

export default async function KvkkGdprPage() {
  const yetkili = await hasPermission('page:kvkk-gdpr');
  if (!yetkili) {
    return (
      <div className="flex flex-col">
        <PanelSayfaBasligi eyebrow="Yönetici" title="KVKK / GDPR" description="Bu sayfayı görüntüleme yetkiniz yok." />
        <PanelIcerikYuzeyi className="pt-6"><YetkisizErisim sayfaAdi="KVKK / GDPR" /></PanelIcerikYuzeyi>
      </div>
    );
  }

  const supabase = await createSupabaseServerClient();

  // Fetch privacy requests (DSAR = Data Subject Access Requests)
  const { data: requests } = await (supabase)
    .from('privacy_requests')
    .select('id, user_id, request_type, status, details, created_at, resolved_at')
    .order('created_at', { ascending: false })
    .limit(100) as { data: Array<{
      id: string; user_id: string; request_type: string; status: string; details: string | null;
      created_at: string; resolved_at: string | null;
    }> | null };

  const requestUserIds = (requests ?? []).map((request) => request.user_id).filter(Boolean);
  const profiles = await getProfilesByUserIds(supabase, requestUserIds);
  // Talep sahibinin e-postası önceden sabit null dönüyordu (user_profiles'ta
  // email hiç yok, auth.users'ta) — "E-posta Gönder" linki hiç çalışmıyordu.
  const emailByUser = await getEmailsByUserIds(supabase, requestUserIds);
  const allRequests = (requests ?? []).map((request) => ({
    ...request,
    updated_at: request.resolved_at ?? request.created_at,
    user_profiles: {
      display_name: profiles.get(request.user_id)?.display_name ?? null,
      email: emailByUser.get(request.user_id) ?? null,
    },
  }));
  const pending = allRequests.filter(r => r.status === 'submitted');
  const processing = allRequests.filter(r => r.status === 'in_review');
  const completed = allRequests.filter(r => r.status === 'resolved');

  // account_deletion_requests: mobil uygulamadan gelen resmi KVKK hesap silme
  // talepleri — önceden bu tabloyu işleyecek hiçbir admin aracı yoktu,
  // talepler sonsuza dek 'requested' kalıyordu.
  const { data: deletionRequests } = await (supabase as unknown as { rpc: (fn: string, args?: Record<string, unknown>) => Promise<{ data: unknown }> })
    .rpc('admin_list_account_deletion_requests_v1', { p_limit: 200 }) as { data: Array<{
      id: string; user_id: string; email: string | null; display_name: string | null;
      reason: string | null; status: string; requested_at: string; completed_at: string | null;
    }> | null };
  const allDeletionRequests = deletionRequests ?? [];
  const pendingDeletionCount = allDeletionRequests.filter((r) => r.status === 'requested').length;

  const { data: legalDocs } = await (supabase)
    .from('legal_documents')
    .select('id, slug, title, description, content, is_published, sort_order, updated_at')
    .order('sort_order') as { data: Array<{
      id: string; slug: string; title: string; description: string | null; content: string;
      is_published: boolean; sort_order: number; updated_at: string;
    }> | null };
  const allLegalDocs = legalDocs ?? [];
  const publishedDocCount = allLegalDocs.filter(d => d.is_published).length;

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Yönetici"
        title="KVKK / GDPR Uyum"
        description="Veri konusu erişim talepleri (DSAR), onay yönetimi ve veri koruma"
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-6">
          {/* Compliance stats */}
          <div className="grid grid-cols-2 gap-4 sm:grid-cols-5">
            <MetricCard title="Bekleyen DSAR" value={pending.length} icon={<FileIcon />} />
            <MetricCard title="İşlemdeki" value={processing.length} icon={<ClockIcon />} />
            <MetricCard title="Tamamlanan" value={completed.length} icon={<CheckIcon />} />
            <MetricCard title="Yayındaki Politika" value={publishedDocCount} icon={<ShieldIcon />} />
            <MetricCard title="Bekleyen Hesap Silme" value={pendingDeletionCount} icon={<FileIcon />} />
          </div>

          {/* DSAR Management */}
          <PanelBolumKarti title="DSAR Yönetimi (Veri Konusu Erişim Talepleri)">
            <p className="text-sm text-muted">
              KVKK Madde 11 ve GDPR Article 15-22 kapsamındaki veri konusu talepleri.
              Her talep oluşturma tarihinden itibaren <strong>30 gün</strong> içinde yanıtlanmalıdır.
            </p>
          </PanelBolumKarti>

          {/* DSAR Request List */}
          <PanelBolumKarti title="Talep Listesi" noPadding>
            {allRequests.length === 0 ? (
              <p className="px-5 py-8 text-center text-sm text-muted">Henüz DSAR talebi yok</p>
            ) : (
              <DsarYonetimi requests={allRequests} requestTypeLabels={REQUEST_TYPE_LABELS} />
            )}
          </PanelBolumKarti>

          {/* Account deletion requests */}
          <PanelBolumKarti
            title="Hesap Silme Talepleri"
            description="Mobil uygulamadan gönderilen resmi hesap silme talepleri. Silme geri alınamaz."
            noPadding
          >
            {allDeletionRequests.length === 0 ? (
              <p className="px-5 py-8 text-center text-sm text-muted">Henüz hesap silme talebi yok</p>
            ) : (
              <HesapSilmeYonetimi requests={allDeletionRequests} />
            )}
          </PanelBolumKarti>

          {/* Legal document management */}
          <PanelBolumKarti title="Politikalar & Belgeler" description="Gizlilik/kullanım/çerez politikalarının halka açık /yasal sayfalarında görünen içeriği. Yayınlanan belgeler anında canlıya yansır.">
            <PolitikaYonetimi documents={allLegalDocs} />
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

async function getEmailsByUserIds(supabase: any, userIds: string[]) {
  const uniqueIds = [...new Set(userIds)];
  if (uniqueIds.length === 0) return new Map<string, string | null>();

  const { data } = await supabase.rpc('admin_list_user_emails_v1', { p_user_ids: uniqueIds });
  return new Map(((data ?? []) as Array<{ user_id: string; email: string | null }>).map((row) => [row.user_id, row.email]));
}

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
