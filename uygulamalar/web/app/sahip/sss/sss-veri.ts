export type SssKategoriId =
  | 'hesap'
  | 'isletme'
  | 'menu'
  | 'qr'
  | 'rezervasyon'
  | 'yorumlar'
  | 'pazarlama'
  | 'plan';

export interface SssKategori {
  id: SssKategoriId;
  label: string;
}

export const SSS_KATEGORILERI: SssKategori[] = [
  { id: 'hesap', label: 'Hesap & Profil' },
  { id: 'isletme', label: 'İşletme Yönetimi' },
  { id: 'menu', label: 'Menü Yönetimi' },
  { id: 'qr', label: 'QR Menü' },
  { id: 'rezervasyon', label: 'Rezervasyon' },
  { id: 'yorumlar', label: 'Yorumlar & Müşteriler' },
  { id: 'pazarlama', label: 'Pazarlama' },
  { id: 'plan', label: 'Abonelik & Plan' },
];

export interface SssSoru {
  id: string;
  category: SssKategoriId;
  q: string;
  a: string;
}

export const SSS_SORULARI: SssSoru[] = [
  {
    id: 'profil-guncelle',
    category: 'hesap',
    q: 'Profil bilgilerimi nasıl güncellerim?',
    a: 'Sağ üstteki profil menüsünden "Profilim" sayfasına girip Kişisel Bilgiler sekmesinden adınızı, telefon numaranızı, doğum tarihinizi ve fotoğrafınızı güncelleyebilirsiniz.',
  },
  {
    id: 'sifre-degistir',
    category: 'hesap',
    q: 'Şifremi nasıl değiştiririm?',
    a: 'Profilim sayfasındaki Güvenlik sekmesinden mevcut şifrenizi girip yeni bir şifre belirleyebilirsiniz.',
  },
  {
    id: 'bildirim-tercihleri',
    category: 'hesap',
    q: 'Hangi bildirimleri alacağımı nasıl seçerim?',
    a: 'Profilim sayfasındaki Bildirim Tercihleri sekmesinden yeni yorum, rezervasyon talebi, fiyat önerisi ve haftalık özet bildirimlerini ayrı ayrı açıp kapatabilirsiniz.',
  },
  {
    id: 'hesap-sil',
    category: 'hesap',
    q: 'Hesabımı nasıl silerim?',
    a: 'Profilim sayfasındaki "Hesabımı Sil" bölümünden hesap silme akışını başlatabilirsiniz. Bu işlem tüm verilerinizi kalıcı olarak siler ve geri alınamaz.',
  },
  {
    id: 'isletme-bilgi-guncelle',
    category: 'isletme',
    q: 'İşletme bilgilerimi nasıl güncellerim?',
    a: 'Ayarlar sayfasından işletme adı, adres, kategori, çalışma saatleri ve iletişim bilgilerinizi düzenleyebilirsiniz.',
  },
  {
    id: 'coklu-sube',
    category: 'isletme',
    q: 'Birden fazla şubem varsa nasıl yönetirim?',
    a: 'Çoklu Şube Yönetimi sayfasından şubelerinizi tek panelden yönetebilir, üst menüdeki işletme değiştiriciyle şubeler arasında geçiş yapabilirsiniz.',
  },
  {
    id: 'ekip-davet',
    category: 'isletme',
    q: 'Ekibime panel erişimi nasıl veririm?',
    a: 'Ekip sayfasından e-posta adresiyle davet gönderip erişim yetkilerini belirleyebilirsiniz.',
  },
  {
    id: 'aktivite-gecmisi',
    category: 'isletme',
    q: 'Panelde yapılan değişiklikleri nereden takip ederim?',
    a: 'Aktivite Geçmişi sayfasından ekibinizin panelde yaptığı işlemlerin kaydını görebilirsiniz.',
  },
  {
    id: 'cop-kutusu',
    category: 'isletme',
    q: 'Yanlışlıkla sildiğim bir içeriği geri alabilir miyim?',
    a: 'Çöp Kutusu sayfasından silinen menü öğeleri gibi içerikleri geri yükleyebilirsiniz.',
  },
  {
    id: 'menu-urun-ekle',
    category: 'menu',
    q: 'Menüme nasıl ürün eklerim?',
    a: 'Menü Yönetimi sayfasından bir kategori seçip yeni ürün ekleyebilir; ürün adı, fiyat, açıklama ve fotoğraf girebilirsiniz.',
  },
  {
    id: 'fiyat-guncelle',
    category: 'menu',
    q: 'Ürün fiyatlarımı nasıl güncellerim?',
    a: 'Menü Yönetimi’nde ilgili ürünü düzenleyerek fiyatını değiştirebilirsiniz. Fiyat Raporu sayfasından bölgenizdeki benzer işletmelerle karşılaştırma yapabilirsiniz.',
  },
  {
    id: 'fotograf-ekle',
    category: 'menu',
    q: 'İşletme ve menü fotoğraflarımı nereden eklerim?',
    a: 'Fotoğraflar sayfasından işletmenize ve menü ürünlerinize ait fotoğrafları yükleyip düzenleyebilirsiniz.',
  },
  {
    id: 'qr-olustur',
    category: 'qr',
    q: 'QR menü kodumu nasıl oluştururum?',
    a: 'QR Menü & QR Kod sayfasında işletmeniz için otomatik oluşturulan kodu indirip masalarınıza yerleştirebilirsiniz.',
  },
  {
    id: 'qr-guncel-mi',
    category: 'qr',
    q: 'Menümde değişiklik yaptığımda QR kod güncellenir mi?',
    a: 'Evet. QR kod her zaman güncel menünüze bağlıdır; Menü Yönetimi’nde yaptığınız her değişiklik müşterinin taradığı sayfaya anında yansır, kodu yeniden oluşturmanıza gerek yoktur.',
  },
  {
    id: 'rezervasyon-ac',
    category: 'rezervasyon',
    q: 'Rezervasyon almaya nasıl başlarım?',
    a: 'Ayarlar sayfasındaki Rezervasyon sekmesinden rezervasyon kabulünü açmanız gerekir. Açtıktan sonra Rezervasyonlar sayfası ve müşteri tarafındaki rezervasyon butonu aktif hale gelir.',
  },
  {
    id: 'rezervasyon-yonet',
    category: 'rezervasyon',
    q: 'Gelen rezervasyon taleplerini nereden görürüm?',
    a: 'Rezervasyonlar sayfasından gelen talepleri görüntüleyebilir, onaylayabilir veya reddedebilirsiniz.',
  },
  {
    id: 'yorum-cevapla',
    category: 'yorumlar',
    q: 'Müşteri yorumlarına nasıl cevap veririm?',
    a: 'Yorumlar sayfasından her yoruma doğrudan yanıt yazabilirsiniz.',
  },
  {
    id: 'musteri-takip',
    category: 'yorumlar',
    q: 'Müşterilerimi nereden takip ederim?',
    a: 'Müşteriler sayfasında ziyaret geçmişi ve sadakat etkileşimleri gibi bilgileri görebilirsiniz.',
  },
  {
    id: 'kampanya-olustur',
    category: 'pazarlama',
    q: 'Kampanya nasıl oluştururum?',
    a: 'Pazarlama > Kampanyalar sayfasından e-posta kampanyası oluşturup takipçi müşterilerinize gönderebilirsiniz.',
  },
  {
    id: 'sadakat-kur',
    category: 'pazarlama',
    q: 'Sadakat programı nasıl kurulur?',
    a: 'Pazarlama > Sadakat sayfasından programınızı tanımlayıp müşterilerinizin ziyaretlerinde puan kazanmasını sağlayabilirsiniz.',
  },
  {
    id: 'plan-yukselt',
    category: 'plan',
    q: 'Planımı nasıl yükseltirim?',
    a: 'Ayarlar > Plan sayfasından mevcut kademenizi ve özellik limitlerinizi görebilirsiniz. Yükseltme talebi için destek@yeedoy.com üzerinden ekibimizle iletişime geçebilirsiniz.',
  },
  {
    id: 'plan-farklari',
    category: 'plan',
    q: 'Kademeler arasında ne fark var?',
    a: 'Plan sayfasında kademenize göre açık/kilitli özellikler ve varsa kullanım limitleriniz (ör. fotoğraf sayısı) listelenir.',
  },
];
