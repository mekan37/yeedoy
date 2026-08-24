export type AdminPermissionKey =
  | 'page:isletmeler' | 'page:zincirler' | 'page:kuyruklar' | 'page:isletme-basvurulari'
  | 'page:raporlar' | 'page:kullanicilar' | 'page:yorumlar' | 'page:itirazlar'
  | 'page:fis-basvurulari' | 'page:cop-kutusu' | 'page:olaylar' | 'page:konumlar'
  | 'page:analitik' | 'page:musteri-destek' | 'page:oneriler' | 'page:fiyat-onerileri'
  | 'page:fraud-tespiti' | 'page:fotograf-moderasyon' | 'page:feature-flags'
  | 'page:api-anahtarlari' | 'page:roller' | 'page:gozlemlenebilirlik'
  | 'page:gelistirme-araclari' | 'page:kvkk-gdpr' | 'page:gecici-yuklemeler'
  | 'page:gorsel-kutuphanesi';

export interface AdminPermissionInfo {
  key: AdminPermissionKey;
  label: string;
  group: 'Operasyon' | 'Büyüme ve Gelir' | 'Güvenlik ve Sistem';
  href: string;
}

// src/ui/kabuk/yonetici-kabuk-istemcisi.tsx'teki adminNavSections ile birebir
// senkron tutulmalı (yeni bir admin sayfası eklenince buraya da eklenir, ve
// migration'daki admin_permission_key enum'una da eklenir).
export const ADMIN_PERMISSIONS: AdminPermissionInfo[] = [
  { key: 'page:isletmeler', label: 'İşletmeler', group: 'Operasyon', href: '/yonetici/isletmeler' },
  { key: 'page:zincirler', label: 'Zincirler', group: 'Operasyon', href: '/yonetici/zincirler' },
  { key: 'page:kuyruklar', label: 'Kuyruklar', group: 'Operasyon', href: '/yonetici/kuyruklar' },
  { key: 'page:isletme-basvurulari', label: 'İşletme Talepleri', group: 'Operasyon', href: '/yonetici/isletme-basvurulari' },
  { key: 'page:raporlar', label: 'Raporlar', group: 'Operasyon', href: '/yonetici/raporlar' },
  { key: 'page:kullanicilar', label: 'Kullanıcılar', group: 'Operasyon', href: '/yonetici/kullanicilar' },
  { key: 'page:yorumlar', label: 'Yorumlar', group: 'Operasyon', href: '/yonetici/yorumlar' },
  { key: 'page:itirazlar', label: 'İtirazlar', group: 'Operasyon', href: '/yonetici/itirazlar' },
  { key: 'page:fis-basvurulari', label: 'Fiş Başvuruları', group: 'Operasyon', href: '/yonetici/fis-basvurulari' },
  { key: 'page:cop-kutusu', label: 'Silinmiş Menüler', group: 'Operasyon', href: '/yonetici/cop-kutusu' },
  { key: 'page:olaylar', label: 'Olaylar', group: 'Operasyon', href: '/yonetici/olaylar' },
  { key: 'page:konumlar', label: 'Konumlar', group: 'Operasyon', href: '/yonetici/konumlar' },
  { key: 'page:gorsel-kutuphanesi', label: 'Görsel Kütüphanesi', group: 'Operasyon', href: '/yonetici/gorsel-kutuphanesi' },
  { key: 'page:analitik', label: 'Analitik', group: 'Büyüme ve Gelir', href: '/yonetici/analitik' },
  { key: 'page:musteri-destek', label: 'Müşteri Destek', group: 'Büyüme ve Gelir', href: '/yonetici/musteri-destek' },
  { key: 'page:oneriler', label: 'Öneriler', group: 'Büyüme ve Gelir', href: '/yonetici/oneriler' },
  { key: 'page:fiyat-onerileri', label: 'Fiyat Önerileri', group: 'Büyüme ve Gelir', href: '/yonetici/fiyat-onerileri' },
  { key: 'page:fraud-tespiti', label: 'Fraud Tespiti', group: 'Güvenlik ve Sistem', href: '/yonetici/fraud-tespiti' },
  { key: 'page:fotograf-moderasyon', label: 'Fotoğraf Moderasyon', group: 'Güvenlik ve Sistem', href: '/yonetici/fotograf-moderasyon' },
  { key: 'page:feature-flags', label: 'Feature Flags', group: 'Güvenlik ve Sistem', href: '/yonetici/feature-flags' },
  { key: 'page:api-anahtarlari', label: 'API Anahtarları', group: 'Güvenlik ve Sistem', href: '/yonetici/api-anahtarlari' },
  { key: 'page:roller', label: 'Roller', group: 'Güvenlik ve Sistem', href: '/yonetici/roller' },
  { key: 'page:gozlemlenebilirlik', label: 'Gözlemlenebilirlik', group: 'Güvenlik ve Sistem', href: '/yonetici/gozlemlenebilirlik' },
  { key: 'page:gelistirme-araclari', label: 'Geliştirici Araçları', group: 'Güvenlik ve Sistem', href: '/yonetici/gelistirme-araclari' },
  { key: 'page:kvkk-gdpr', label: 'KVKK / GDPR', group: 'Güvenlik ve Sistem', href: '/yonetici/kvkk-gdpr' },
  { key: 'page:gecici-yuklemeler', label: 'Geçici Yüklemeler', group: 'Güvenlik ve Sistem', href: '/yonetici/gecici-yuklemeler' },
];

export const ADMIN_PERMISSION_GROUPS = Array.from(new Set(ADMIN_PERMISSIONS.map((p) => p.group)));
