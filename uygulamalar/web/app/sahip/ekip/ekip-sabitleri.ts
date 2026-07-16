export const ROLE_LABELS: Record<string, { label: string; className: string }> = {
  owner: { label: 'Sahip', className: 'bg-primary/10 text-primary' },
  manager: { label: 'Yönetici', className: 'bg-purple-50 text-purple-700' },
  editor: { label: 'Editör', className: 'bg-blue-50 text-blue-700' },
  staff: { label: 'Personel', className: 'bg-zinc-100 text-zinc-600' },
  viewer: { label: 'İzleyici', className: 'bg-zinc-50 text-zinc-500' },
};

export const ROLE_DESCRIPTIONS: Record<string, string> = {
  owner: 'Tüm yetkilere sahiptir.',
  manager: 'Yönetim, raporlama ve ekip yönetimi yapabilir.',
  editor: 'Menü, QR kod ve görselleri düzenleyebilir; analitikleri görüntüleyebilir.',
  staff: 'Görsel yükleyebilir; işletmeyi ve analitikleri görüntüleyebilir.',
  viewer: 'Sadece görüntüleme yetkisine sahiptir.',
};

// business_role_rank_v1 + business_role_has_permission_v1 ile birebir aynı eşik
// mantığı (bkz. supabase/migrations/00000000000000_base_schema.sql) — "yetki"
// sayısı burada gerçek RLS/RPC yetki kontrolünden türetiliyor, uydurma değil.
const ROLE_RANK: Record<string, number> = { owner: 500, manager: 400, editor: 300, staff: 200, viewer: 100 };

export const PERMISSIONS: { key: string; label: string; minRank: number }[] = [
  { key: 'business_read', label: 'İşletmeyi görüntüleme', minRank: 100 },
  { key: 'analytics_view', label: 'Analitik görüntüleme', minRank: 100 },
  { key: 'media_upload', label: 'Görsel yükleme', minRank: 200 },
  { key: 'qr_manage', label: 'QR kod yönetimi', minRank: 300 },
  { key: 'menu_write', label: 'Menü düzenleme', minRank: 300 },
  { key: 'business_write', label: 'İşletme bilgilerini düzenleme', minRank: 400 },
  { key: 'team_manage', label: 'Ekip yönetimi', minRank: 400 },
];

export function permissionsForRole(role: string) {
  const rank = ROLE_RANK[role] ?? 0;
  return PERMISSIONS.filter((p) => rank >= p.minRank);
}
