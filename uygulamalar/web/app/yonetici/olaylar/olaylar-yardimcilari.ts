export type SonucTuru = 'success' | 'warning' | 'error' | 'info';
export type OlayKaynagi = 'analytics_events' | 'edge_rate_limit_events' | 'admin_audit_log' | 'reports';

export interface OlaySatiri {
  id: string;
  createdAt: string;
  incidentType: string;
  description: string;
  source: OlayKaynagi;
  sonuc: SonucTuru;
  userId: string | null;
  userName: string | null;
  userRole: string | null;
  ip: string | null;
  ipHashPrefix: string | null;
  meta: Record<string, unknown> | null;
}

export const SONUC_ETIKETLERI: Record<SonucTuru, string> = {
  success: 'Başarılı',
  warning: 'Uyarı',
  error: 'Hata',
  info: 'Bilgi',
};

export const SONUC_STILLERI: Record<SonucTuru, string> = {
  success: 'bg-emerald-50 text-emerald-700',
  warning: 'bg-amber-50 text-amber-700',
  error: 'bg-red-50 text-red-700',
  info: 'bg-blue-50 text-blue-700',
};

export const ACTOR_ROLE_ETIKETLERI: Record<string, string> = {
  admin: 'Admin',
  owner: 'İşletme Sahibi',
  community_mod: 'Moderatör',
  system: 'Sistem',
  user: 'Kullanıcı',
};

export function yuzdeDegisim(bu: number, onceki: number): number {
  if (onceki === 0) return bu > 0 ? 100 : 0;
  return Math.round(((bu - onceki) / onceki) * 100);
}

export function shortId(value: unknown): string {
  const text = String(value ?? '');
  return text.length > 14 ? `${text.slice(0, 10)}…` : text;
}

// Gerçek analytics_events.event_name değerleri — src/lib/analitik.ts'teki rpcAnalyticsEventSchema
// enum'unun birebir aynısı (tam liste, tahmini değil).
export const ANALYTICS_OLAY_ETIKETLERI: Record<string, string> = {
  menu_shared: 'Menü Paylaşıldı',
  qr_scanned: 'QR Kod Tarandı',
  menu_link_opened: 'Menü Linki Açıldı',
  app_install_from_menu: 'Menüden Uygulama İndirme Tıklandı',
  business_reservation_click: 'Rezervasyon Butonuna Tıklandı',
  business_phone_click: 'Telefon Numarasına Tıklandı',
  business_whatsapp_click: 'WhatsApp Butonuna Tıklandı',
  business_order_click: 'Sipariş Butonuna Tıklandı',
  business_directions_click: 'Yol Tarifi İstendi',
  business_page_view: 'İşletme Sayfası Görüntülendi',
  menu_view: 'Menü Görüntülendi',
  discovery_impression: 'Keşfet Listesinde Gösterildi',
  discovery_business_click: 'Keşfette İşletmeye Tıklandı',
  business_impression: 'İşletme Listede Gösterildi',
  price_suggestion_submitted: 'Fiyat Önerisi Gönderildi',
};

// Gerçek admin_audit_log.action değerleri — log_admin_action_v1() çağrılarından (base_schema.sql)
// ve bu oturumda eklenen kendi audit-log kayıtlarından (menus: restore/delete,
// business_submissions: approve/reject) derlendi.
export const AUDIT_EYLEM_ETIKETLERI: Record<string, string> = {
  'suggestion.approve': 'İşletme Önerisi Onaylandı',
  'suggestion.reject': 'İşletme Önerisi Reddedildi',
  'suggestion.assign': 'Öneri İncelemeye Alındı',
  'suggestion.unassign': 'Öneri İncelemeden Çıkarıldı',
  'suggestion.bulk_reject': 'Öneriler Toplu Reddedildi',
  'suggestion.export_csv': 'Öneriler CSV Olarak Dışa Aktarıldı',
  'suggestion.link_existing': 'Öneri Mevcut İşletmeyle Eşleştirildi',
  'claim.approve': 'Sahiplenme Talebi Onaylandı',
  'claim.approved': 'Sahiplenme Talebi Onaylandı',
  'claim.reject': 'Sahiplenme Talebi Reddedildi',
  'claim.rejected': 'Sahiplenme Talebi Reddedildi',
  'claim.updated': 'Sahiplenme Talebi Güncellendi',
  'claim.assign': 'Sahiplenme Talebi İncelemeye Alındı',
  'claim.unassign': 'Sahiplenme Talebi İncelemeden Çıkarıldı',
  'claim.bulk_decide': 'Sahiplenme Talepleri Toplu Karara Bağlandı',
  'claim.export_csv': 'Sahiplenme Talepleri CSV Olarak Dışa Aktarıldı',
  'claim.auto_approve_trusted': 'Sahiplenme Talebi Otomatik Onaylandı (Güvenilir)',
  'business_submission.assigned': 'İşletme Talebi İncelemeye Alındı',
  'business_submission.unassigned': 'İşletme Talebi İncelemeden Çıkarıldı',
  approve: 'Onaylandı',
  reject: 'Reddedildi',
  restore: 'Geri Yüklendi',
  delete: 'Kalıcı Olarak Silindi',
  'report.assign': 'Rapor İncelemeye Alındı',
  'report.unassign': 'Rapor İncelemeden Çıkarıldı',
  'report.update': 'Rapor Durumu Güncellendi',
  'report.updated': 'Rapor Durumu Güncellendi',
  'report.bulk_update': 'Raporlar Toplu Güncellendi',
  'report.export_csv': 'Raporlar CSV Olarak Dışa Aktarıldı',
  'report.auto_close_duplicate': 'Rapor Otomatik Kapatıldı (Mükerrer)',
  'report.auto_queue_grey': 'Rapor Otomatik Kuyruğa Alındı',
  'report.auto_reject_low_quality': 'Rapor Otomatik Reddedildi (Düşük Kalite)',
  'business.merge': 'İşletmeler Birleştirildi',
  'business.set_media': 'İşletme Görseli Güncellendi',
  'business.update': 'İşletme Bilgisi Güncellendi',
  'business.updated': 'İşletme Bilgisi Güncellendi',
  'business.bulk_replace_url_prefix': 'İşletme URL Ön Eki Toplu Değiştirildi',
  'admin.bulk_replace_text': 'Metin Toplu Değiştirildi',
  'menu.created': 'Menü Oluşturuldu',
  'menu.updated': 'Menü Güncellendi',
  'menu.deleted': 'Menü Silindi',
  'menu_item.created': 'Menü Ürünü Eklendi',
  'menu_item.updated': 'Menü Ürünü Güncellendi',
  'menu_item.deleted': 'Menü Ürünü Silindi',
  'price_suggestion.assigned': 'Fiyat Önerisi İncelemeye Alındı',
  'price_suggestion.unassigned': 'Fiyat Önerisi İncelemeden Çıkarıldı',
  'price_suggestion.approved': 'Fiyat Önerisi Onaylandı',
  'price_suggestion.rejected': 'Fiyat Önerisi Reddedildi',
  'price_suggestion.export_csv': 'Fiyat Önerileri CSV Olarak Dışa Aktarıldı',
  'user.anonymized': 'Kullanıcı Anonimleştirildi',
  'owner.team.upsert': 'Ekip Üyesi Eklendi/Güncellendi',
};

export const RAPOR_HEDEF_ETIKETLERI: Record<string, string> = {
  business: 'İşletme Hakkında Rapor',
  review: 'Yorum Hakkında Rapor',
  menu_item_photo: 'Fotoğraf Hakkında Rapor',
};

/** Bilinen bir etiket yoksa dot/underscore/dash'i boşluğa çevirip Başlık Harfleri yapar — hiçbir zaman ham makine metni gösterilmez. */
export function insanilesir(ham: string): string {
  return ham
    .replace(/[._-]+/g, ' ')
    .split(' ')
    .filter(Boolean)
    .map((k) => k.charAt(0).toLocaleUpperCase('tr-TR') + k.slice(1))
    .join(' ');
}

export function olayTuruEtiketi(source: OlayKaynagi, incidentType: string): string {
  if (source === 'admin_audit_log') return AUDIT_EYLEM_ETIKETLERI[incidentType] ?? insanilesir(incidentType);
  if (source === 'analytics_events') return ANALYTICS_OLAY_ETIKETLERI[incidentType] ?? insanilesir(incidentType);
  if (source === 'edge_rate_limit_events') return `Hız Sınırı: ${insanilesir(incidentType)}`;
  if (source === 'reports') {
    const hedefTuru = incidentType.replace(/^report_/, '');
    return RAPOR_HEDEF_ETIKETLERI[hedefTuru] ?? `Rapor: ${insanilesir(hedefTuru)}`;
  }
  return insanilesir(incidentType);
}

export function olaylarCsvOlustur(rows: OlaySatiri[]): string {
  const basliklar = ['Tarih/Saat', 'Kullanıcı', 'Rol', 'Olay', 'Açıklama', 'IP', 'Sonuç', 'Kaynak'];
  const satirlar = rows.map((r) => [
    new Date(r.createdAt).toLocaleString('tr-TR'),
    r.userName ?? '',
    r.userRole ?? '',
    olayTuruEtiketi(r.source, r.incidentType),
    r.description,
    r.ip ?? (r.ipHashPrefix ? `hash:${r.ipHashPrefix}` : ''),
    SONUC_ETIKETLERI[r.sonuc],
    r.source,
  ]);
  const kacis = (v: string) => `"${v.replace(/"/g, '""')}"`;
  return [basliklar, ...satirlar].map((satir) => satir.map(kacis).join(',')).join('\n');
}
