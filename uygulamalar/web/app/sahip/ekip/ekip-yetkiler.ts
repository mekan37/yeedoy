/**
 * public.business_role_rank_v1 + public.business_role_has_permission_v1 (Postgres,
 * IMMUTABLE) veritabanı fonksiyonlarının aynası — gerçek RBAC eşiklerini burada
 * tekrarlar ki UI'da gösterilen "X yetki" sayısı ve açıklamalar uydurma olmasın.
 * DB tarafında bu eşikler değişirse burası da güncellenmeli.
 */
export type EkipRolu = 'owner' | 'manager' | 'editor' | 'staff' | 'viewer';

const ROLE_RANK: Record<EkipRolu, number> = {
  owner: 500,
  manager: 400,
  editor: 300,
  staff: 200,
  viewer: 100,
};

const PERMISSIONS: { key: string; label: string; minRank: number }[] = [
  { key: 'business_read', label: 'İşletme bilgilerini görüntüleme', minRank: 100 },
  { key: 'analytics_view', label: 'İstatistikleri görüntüleme', minRank: 100 },
  { key: 'media_upload', label: 'Görsel/medya yükleme', minRank: 200 },
  { key: 'qr_manage', label: 'QR menü yönetimi', minRank: 200 },
  { key: 'menu_write', label: 'Menü düzenleme', minRank: 300 },
  { key: 'business_write', label: 'İşletme bilgilerini düzenleme', minRank: 400 },
  { key: 'team_manage', label: 'Ekip yönetimi', minRank: 400 },
];

export function rolYetkileri(role: EkipRolu): string[] {
  const rank = ROLE_RANK[role];
  return PERMISSIONS.filter((p) => rank >= p.minRank).map((p) => p.label);
}

export function rolYetkiSayisi(role: EkipRolu): number {
  return rolYetkileri(role).length;
}

export const ROL_OZET_ETIKETI: Record<EkipRolu, string> = {
  owner: 'Tüm izinler',
  manager: 'Yönetim ve raporlama',
  editor: 'Menü ve içerik yönetimi',
  staff: 'Sipariş & rezervasyon',
  viewer: 'Sadece görüntüleme',
};

export const ROL_TANIMI: Record<EkipRolu, string> = {
  owner: 'Tüm yetkilere sahiptir.',
  manager: 'Yönetim, raporlama ve ekip ayarlarını yönetir.',
  editor: 'Menü ve içerik üzerinde düzenleme yapar.',
  staff: 'Belirli operasyonel yetkilerle çalışır.',
  viewer: 'Sadece görüntüleme yetkisine sahiptir.',
};
