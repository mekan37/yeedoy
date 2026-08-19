export type TicketTab = 'tumu' | 'acik' | 'beklemede' | 'cozuldu';

export function ticketMatchesTab(status: string, tab: TicketTab): boolean {
  if (tab === 'tumu') return true;
  if (tab === 'acik') return status === 'open';
  if (tab === 'beklemede') return status === 'in_progress';
  return status === 'resolved' || status === 'closed';
}

export function formatTicketNo(id: string): string {
  return '#' + id.slice(0, 8).toUpperCase();
}

export const STATUS_MAP: Record<string, { label: string; color: string }> = {
  open: { label: 'Açık', color: 'bg-blue-50 text-blue-700' },
  in_progress: { label: 'İşlemde', color: 'bg-yellow-50 text-yellow-700' },
  resolved: { label: 'Çözüldü', color: 'bg-green-50 text-green-700' },
  closed: { label: 'Kapatıldı', color: 'bg-zinc-100 text-zinc-500' },
};

export const CATEGORY_OPTIONS = ['Fatura/Ödeme', 'Teknik Sorun', 'Özellik Talebi', 'Hesap/Erişim', 'Diğer'] as const;
export type DestekKategori = (typeof CATEGORY_OPTIONS)[number];

export const FAQ_ITEMS: Array<{ q: string; a: string }> = [
  {
    q: "İşletmemi Yeedoy'a nasıl ekletirim?",
    a: '"İşletmeni Ekle" sayfasından başvurunuzu yapabilirsiniz. Ekibimiz en kısa sürede inceleyip size geri dönecektir.',
  },
  {
    q: 'Menü ve fiyatlarımı nasıl yönetirim?',
    a: 'İşletme sahipliğinizi doğruladıktan sonra sahip panelinden menülerinizi, ürünlerinizi ve fiyatlarınızı kolayca güncelleyebilirsiniz.',
  },
  {
    q: 'Destek talebimin durumunu nereden takip ederim?',
    a: 'Bu sayfadaki "Destek Taleplerim" bölümünden tüm taleplerinizin durumunu ve yanıtlarını görebilirsiniz.',
  },
  {
    q: 'Destek talebime ne zaman yanıt alırım?',
    a: 'Destek ekibimiz Pazartesi–Cuma 09:00–18:00 saatleri arasında taleplerinizi yanıtlar. Yanıt geldiğinde e-posta ile bilgilendirilirsiniz.',
  },
  {
    q: 'Birden fazla işletmem varsa talebi hangisi için açtığımı nasıl belirtirim?',
    a: 'Yeni talep oluştururken açılan "İşletme" alanından ilgili işletmenizi seçebilirsiniz.',
  },
];

export const POPULER_KONULAR = [
  { title: 'İşletme Profili', description: 'İşletme bilgilerinizi düzenleme, doğrulama ve profil ayarları.', href: '/sahip/ayarlar', tone: 'red' as const },
  { title: 'Menü Yönetimi', description: 'Menü ekleme, ürün düzenleme ve fiyat güncelleme.', href: '/sahip/menu-yonetimi', tone: 'green' as const },
  { title: 'QR Menü & Kod', description: 'QR menü oluşturma ve baskı materyalleri.', href: '/sahip/karekod', tone: 'teal' as const },
  { title: 'İstatistikler', description: 'Görüntülenme, tıklama ve performans raporları.', href: '/sahip/analitik', tone: 'purple' as const },
  { title: 'Rezervasyonlar', description: 'Rezervasyon ayarları ve yönetimi.', href: '/sahip/rezervasyonlar', tone: 'blue' as const },
] as const;
