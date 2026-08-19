// Türkiye'nin 7 coğrafi bölgesi — statik, gerçek coğrafi bilgi (iş verisinden bağımsız).
// İl adları osm_admin_boundaries.name ile birebir eşleşecek şekilde yazıldı.
export const REGION_BY_PROVINCE: Record<string, string> = {
  'İstanbul': 'Marmara', 'Edirne': 'Marmara', 'Kırklareli': 'Marmara', 'Tekirdağ': 'Marmara',
  'Çanakkale': 'Marmara', 'Balıkesir': 'Marmara', 'Bursa': 'Marmara', 'Yalova': 'Marmara',
  'Kocaeli': 'Marmara', 'Sakarya': 'Marmara', 'Bilecik': 'Marmara',

  'İzmir': 'Ege', 'Manisa': 'Ege', 'Aydın': 'Ege', 'Muğla': 'Ege', 'Denizli': 'Ege',
  'Uşak': 'Ege', 'Kütahya': 'Ege', 'Afyonkarahisar': 'Ege',

  'Antalya': 'Akdeniz', 'Isparta': 'Akdeniz', 'Burdur': 'Akdeniz', 'Mersin': 'Akdeniz',
  'Adana': 'Akdeniz', 'Osmaniye': 'Akdeniz', 'Hatay': 'Akdeniz', 'Kahramanmaraş': 'Akdeniz',

  'Ankara': 'İç Anadolu', 'Konya': 'İç Anadolu', 'Kayseri': 'İç Anadolu', 'Sivas': 'İç Anadolu',
  'Yozgat': 'İç Anadolu', 'Kırşehir': 'İç Anadolu', 'Nevşehir': 'İç Anadolu', 'Niğde': 'İç Anadolu',
  'Aksaray': 'İç Anadolu', 'Karaman': 'İç Anadolu', 'Kırıkkale': 'İç Anadolu', 'Çankırı': 'İç Anadolu',
  'Eskişehir': 'İç Anadolu',

  'Zonguldak': 'Karadeniz', 'Bartın': 'Karadeniz', 'Karabük': 'Karadeniz', 'Kastamonu': 'Karadeniz',
  'Çorum': 'Karadeniz', 'Amasya': 'Karadeniz', 'Samsun': 'Karadeniz', 'Ordu': 'Karadeniz',
  'Giresun': 'Karadeniz', 'Trabzon': 'Karadeniz', 'Rize': 'Karadeniz', 'Artvin': 'Karadeniz',
  'Gümüşhane': 'Karadeniz', 'Bayburt': 'Karadeniz', 'Tokat': 'Karadeniz', 'Sinop': 'Karadeniz',
  'Düzce': 'Karadeniz', 'Bolu': 'Karadeniz',

  'Erzurum': 'Doğu Anadolu', 'Erzincan': 'Doğu Anadolu', 'Bingöl': 'Doğu Anadolu', 'Muş': 'Doğu Anadolu',
  'Bitlis': 'Doğu Anadolu', 'Van': 'Doğu Anadolu', 'Ağrı': 'Doğu Anadolu', 'Kars': 'Doğu Anadolu',
  'Iğdır': 'Doğu Anadolu', 'Ardahan': 'Doğu Anadolu', 'Malatya': 'Doğu Anadolu', 'Elâzığ': 'Doğu Anadolu',
  'Tunceli': 'Doğu Anadolu', 'Hakkâri': 'Doğu Anadolu',

  'Gaziantep': 'Güneydoğu Anadolu', 'Şanlıurfa': 'Güneydoğu Anadolu', 'Diyarbakır': 'Güneydoğu Anadolu',
  'Mardin': 'Güneydoğu Anadolu', 'Siirt': 'Güneydoğu Anadolu', 'Şırnak': 'Güneydoğu Anadolu',
  'Batman': 'Güneydoğu Anadolu', 'Adıyaman': 'Güneydoğu Anadolu', 'Kilis': 'Güneydoğu Anadolu',
};

export const BOLGELER = ['Marmara', 'Ege', 'Akdeniz', 'İç Anadolu', 'Karadeniz', 'Doğu Anadolu', 'Güneydoğu Anadolu'];
