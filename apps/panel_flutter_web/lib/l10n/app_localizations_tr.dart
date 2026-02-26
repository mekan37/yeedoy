// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appName => 'Yeedoy';

  @override
  String get appTagline => 'Canlı menüler, doğrulanmış fiyatlar';

  @override
  String get appTaglineLine1 => 'Canlı menüler';

  @override
  String get appTaglineLine2 => 'Dogrulanmis fiyatlar';

  @override
  String get emptyTitle => 'Henüz eklenmemis';

  @override
  String get emptyRegionDescription =>
      'Yeedoy\'da bu bölgede henüz veri yok. İstersen ilk katkıyı sen ekle.';

  @override
  String get webDescription =>
      'Yeedoy - Canlı menüler, doğrulanmış fiyatlar ve akıllı keşif.';

  @override
  String get discover => 'Keşfet';

  @override
  String get home => 'Ana Sayfa';

  @override
  String get map => 'Harita';

  @override
  String get list => 'Liste';

  @override
  String get favorites => 'Favoriler';

  @override
  String get profile => 'Profil';

  @override
  String get settings => 'Ayarlar';

  @override
  String get save => 'Kaydet';

  @override
  String get cancel => 'İptal';

  @override
  String get privacy => 'Gizlilik';

  @override
  String get socialLinks => 'Sosyal Bağlantılar';

  @override
  String get logout => 'Çıkış Yap';

  @override
  String get contribute => 'Katkı Yap';

  @override
  String get uploadPhoto => 'Fotoğraf Yükle';

  @override
  String get scanQr => 'QR Tara';

  @override
  String get verifyPrice => 'Fiyatı Doğrula';

  @override
  String get openInBrowser => 'Tarayıcıda Aç';

  @override
  String get linkPreview => 'Bağlantı Önizleme';

  @override
  String get profileSettings => 'Profil Ayarları';

  @override
  String get saving => 'Kaydediliyor...';

  @override
  String get loginRequired => 'Önce giris yapmalisin.';

  @override
  String get profileSaved => 'Profil ayarları kaydedildi.';

  @override
  String saveError(String error) {
    return 'Kaydetme hatasi: $error';
  }

  @override
  String get namePrivacy => 'İsim Gizliliği';

  @override
  String get firstName => 'Ad';

  @override
  String get lastName => 'Soyad';

  @override
  String get showFullName => 'Ad Soyad Görünsün';

  @override
  String get hideLastName => 'Sadece Soyadı Gizle';

  @override
  String get hideBothNames => 'Ad ve Soyadı Gizle';

  @override
  String get preview => 'Önizleme';

  @override
  String get socialMedia => 'Sosyal Medya';

  @override
  String get language => 'Dil';

  @override
  String get systemDefault => 'Sistem (Varsayılan)';

  @override
  String get turkish => 'Türkçe';

  @override
  String get english => 'İngilizce';

  @override
  String get account => 'Hesap';

  @override
  String get invalidLink => 'Geçerli bir bağlantı gir.';

  @override
  String get socialPreview => 'Sosyal Önizleme';

  @override
  String get pasteLinkHelper => 'Bağlantı yapıştır (https://...)';

  @override
  String get privacySocialSubtitle =>
      'İsim gizliliği ve sosyal medya bağlantıları';

  @override
  String updateBusinessTitle(String businessName) {
    return '$businessName güncelle';
  }

  @override
  String get contributeSheetSubtitle =>
      'Topluluğun menü fiyatlarını doğrulamasına yardımcı ol.';

  @override
  String get scanMenuQr => 'Menü QR tara';

  @override
  String get scanMenuQrSubtitle => 'QR ile anında doğrulama';

  @override
  String get uploadPhotoSubtitle => 'Menünün fotoğrafını çek';

  @override
  String get confirmPriceChange => 'Fiyat değişimini doğrula';

  @override
  String get confirmPriceChangeSubtitle => 'Güncel olmayan bir fiyatı bildir';

  @override
  String get qrAction => 'QR Aksiyonu';

  @override
  String get embed => 'Gömülü';

  @override
  String get share => 'Paylaş';

  @override
  String get invalidLinkMessage => 'Geçersiz bağlantı';

  @override
  String get browserOpened => 'Tarayıcıda açıldı';

  @override
  String get embedFailed => 'İçerik görüntülenemedi, tarayıcıya yönlendirdik.';

  @override
  String get back => 'Geri';

  @override
  String updatedDaysAgo(int days) {
    return '$days gün önce güncellendi';
  }

  @override
  String verifiedDaysAgo(int days) {
    return '$days gün önce doğrulandı';
  }

  @override
  String distanceKm(num km) {
    return '$km km';
  }

  @override
  String avgSpendPerPerson(String amount) {
    return 'Kişi başı $amount';
  }

  @override
  String reviewsCount(int count) {
    return 'Yorum ($count)';
  }

  @override
  String get openNow => 'Şuan açık';

  @override
  String get closedNow => 'Şuan kapalı';

  @override
  String get livePrices => 'Canlı Fiyatlar';

  @override
  String get trustScore => 'Güven Skoru';

  @override
  String get lastUpdated => 'Son Güncelleme';

  @override
  String get lastAudit => 'Son Denetim';

  @override
  String get avgCost => 'Ortalama Tutar';

  @override
  String get avgSpend => 'ORT. HARCAMA';

  @override
  String get verified => 'Doğrulandı';

  @override
  String get priceVerified => 'Fiyat Doğrulandı';

  @override
  String get communityVerified => 'Toplulukça Doğrulandı';

  @override
  String confirmedByUsersToday(int users) {
    return 'Bugün $users kullanıcı tarafından doğrulandı';
  }

  @override
  String get priceHistory => 'Fiyat Geçmişi';

  @override
  String get contributeMenuPhoto => 'Menü Fotoğrafı Katkısı Yap';

  @override
  String get verify => 'DOĞRULA';

  @override
  String get signatureSteaks => 'Öne Çıkan Steakler';

  @override
  String signatureSection(String section) {
    return 'Öne Çıkan $section';
  }

  @override
  String get spottedPriceChange => 'Fiyat değişikliği mi fark ettin?';

  @override
  String get spottedPriceChangeSubtitle =>
      'Bu menüyü güncelleyerek katkı sağla.';

  @override
  String get updateDateUnavailable => 'Güncelleme tarihi yok';

  @override
  String get currentLocation => 'MEVCUT KONUM';

  @override
  String get changeLocation => 'Konumu Değiştir';

  @override
  String get filters => 'Filtreler';

  @override
  String get searchKebabsHint => 'Kebap, burger ara...';

  @override
  String get budget => 'Bütçe';

  @override
  String get freshMenuUpdates => 'Taze Menü Güncellemeleri';

  @override
  String get seeAll => 'Tümünü Gör';

  @override
  String get freshLinks => 'Yeni Bağlantılar';

  @override
  String get discoveryNearbyTitle => 'Yakınımda';

  @override
  String get discoveryNearbySubtitle => 'Konumuna göre en iyi sonuçlar';

  @override
  String get discoveryLocationSubtitle => 'Şehir/ilçeye göre keşfet';

  @override
  String get nearbyVerifiedSpots => 'Yakındaki Doğrulanmış Mekanlar';

  @override
  String get noNearbyVerifiedSpots => 'Yakında doğrulanmış mekan bulunamadı';

  @override
  String get changeFiltersTryAgain =>
      'Konumu veya filtreleri değiştirip tekrar dene.';

  @override
  String get noFreshData => 'Henüz taze veri yok';

  @override
  String get freshDataWillAppear =>
      'Yakındaki menü güncellemeleri burada görünecek.';

  @override
  String get businessLabel => 'İşletme';

  @override
  String get report => 'Bildir';

  @override
  String get favoriteAdded => 'Favorilerde';

  @override
  String get addToFavorites => 'Favoriye ekle';

  @override
  String get writeReview => 'Yorum yap';

  @override
  String get other => 'Diğer';

  @override
  String itemsCount(int count) {
    return '$count ürün';
  }

  @override
  String get weakConnectionQueueNotice =>
      'Bağlantı zayıf. Doğrulama sıraya alındı, çevrimiçi olunca otomatik gönderilecek.';

  @override
  String pendingVerificationsSent(int count) {
    return '$count bekleyen doğrulama gönderildi.';
  }

  @override
  String get loadMenuItemsFirst => 'Önce menü ürünlerini yükle.';

  @override
  String get menuNotAddedYet => 'Henüz eklenmedi';

  @override
  String get menuNotAddedYetDescription =>
      'Bu işletme için henüz menü eklenmemiş.';

  @override
  String get weakConnection => 'Bağlantı zayıf';

  @override
  String get contentLoadFailedCheckInternet =>
      'İçerik şu anda yüklenemedi. Varsa önbellek verisi gösterilecek. İnterneti kontrol edip tekrar dene.';

  @override
  String get trustDataUnavailable => 'Güven verisi yok';

  @override
  String get freshnessAndTrust => 'Güncellik ve güven';

  @override
  String get menuUpdatedLabel => 'Menü Güncellendi';

  @override
  String get lastPriceVerification => 'Son Fiyat Doğrulaması';

  @override
  String get trustScoreLabel => 'Güven Skoru';

  @override
  String get last3MonthsPriceChange => 'Son 3 Ay Fiyat Değişimi';

  @override
  String get hoursInfoUnavailable => 'Çalışma saatleri bilgisi yok';

  @override
  String get hoursInfoMissing => 'Saat bilgisi yok';

  @override
  String get addHoursHelp =>
      'Kullanıcılara yardımcı olmak için çalışma saatlerini ekle.';

  @override
  String get reportHoursInfo => 'Saat bilgisi bildir';

  @override
  String get menus => 'Menüler';

  @override
  String get menusLoadFailed => 'Menüler yüklenemedi';

  @override
  String get noMenu => 'Menü yok';

  @override
  String get addFirstMenuHelp =>
      'İlk menüyü ekleyerek kullanıcılara yardımcı ol.';

  @override
  String get crowdInfoUnavailable => 'Yoğunluk bilgisi yok';

  @override
  String liveCrowdLabel(String state) {
    return 'Anlık yoğunluk: $state';
  }

  @override
  String get reviewsLoadFailed => 'Yorumlar yüklenemedi';

  @override
  String get noReviews => 'Yorum yok';

  @override
  String get leaveFirstReviewHelp => 'İlk yorumu sen yaz.';

  @override
  String get writeFirstReview => 'İlk yorumu yaz';

  @override
  String get recentReviews => 'Son yorumlar';

  @override
  String get reviewFallbackTitle => 'Yorum';

  @override
  String get activeCampaigns => 'Aktif kampanyalar';

  @override
  String get menuDataUnavailable => 'Menü verisi yok';

  @override
  String get noMenuProductsYet => 'Henüz menü ürünü yok';

  @override
  String get menu => 'Menü';

  @override
  String featuredFromCuisine(String category, Object cuisine) {
    return '$cuisine mutfağından öne çıkanlar';
  }

  @override
  String get weeklyPriceChange => '+₺50 bu hafta';

  @override
  String get chartPlaceholderSoon => 'Grafik alanı (yakında)';

  @override
  String get featuredCuisineSuffix => 'mutfağından öne çıkan lezzetler';

  @override
  String get connectionProblemTryAgain => 'Bağlantı sorunu var, tekrar dene.';

  @override
  String get noActiveCampaign => 'Aktif kampanya yok';

  @override
  String get activeCampaignCountLabel => 'aktif kampanya';

  @override
  String get noAmenityInfo => 'İmkan bilgisi yok';

  @override
  String amenityCountLabel(Object count) {
    return '$count imkan';
  }

  @override
  String get noLocationVerificationData => 'Konum doğrulama verisi yok';

  @override
  String get lastLocationVerification => 'Son konum doğrulaması';

  @override
  String get noNewProductRecord => 'Yeni ürün kaydı yok';

  @override
  String get newProduct => 'Yeni ürün';

  @override
  String get reportInfoErrorPrefix => 'Bildirim bilgisi hatası:';

  @override
  String get noLocation => 'Konum yok';

  @override
  String get noHoursInfo => 'Saat bilgisi yok';

  @override
  String get reviewsCountSuffix => 'yorum';

  @override
  String get noTime => 'Saat yok';

  @override
  String get tabSteaks => 'Etler';

  @override
  String get tabBurgers => 'Burgerler';

  @override
  String get tabSides => 'Yan Ürünler';

  @override
  String get tabBeverages => 'İçecekler';

  @override
  String get locationNotAvailable => 'Konum kullanılamıyor';

  @override
  String get sortRecommended => 'Önerilen';

  @override
  String get sortDistance => 'Mesafe';

  @override
  String get sortRating => 'Puan';

  @override
  String get sortPriceLow => 'Fiyat';

  @override
  String get sortNewlyVerified => 'Yeni Doğrulanan';

  @override
  String get rankingFormulaTitle => 'Sıralama Formülü';

  @override
  String get rankingFormulaIntro => 'Sıralama puanı şu bileşenlerden oluşur:';

  @override
  String get rankingWeightDistance => '%30 Mesafe';

  @override
  String get rankingWeightAccuracy => 'Doğruluk ağırlığı';

  @override
  String get rankingWeightEngagement => 'Etkileşim ağırlığı';

  @override
  String get rankingWeightQuality => '%20 Kalite (kalite skoru)';

  @override
  String get rankingFormulaNote => 'Not: Puanlar düzenli olarak güncellenir.';

  @override
  String minRatingLabel(String value) {
    return 'Minimum puan: $value';
  }

  @override
  String get priceLevel => 'Fiyat seviyesi';

  @override
  String get prioritizeOpenNow => 'Şu an açık olanları öne çıkar';

  @override
  String get prioritizeNewlyVerified => 'Yeni doğrulananları öne çıkar';

  @override
  String get reset => 'Sıfırla';

  @override
  String get apply => 'Uygula';

  @override
  String get priceTierAny => 'Her seviye';

  @override
  String get priceTierBudget => 'Ekonomik';

  @override
  String get priceTierMedium => 'Orta';

  @override
  String get priceTierPremium => 'Üst Seviye';

  @override
  String get tabAllItems => 'Tüm Ürünler';

  @override
  String get tabStarters => 'Başlangıçlar';

  @override
  String get usersLabel => 'kullanıcı';

  @override
  String get unknown => 'Bilinmiyor';

  @override
  String get today => 'Bugün';

  @override
  String get dayUnit => 'gün';

  @override
  String get tekrarDene => 'Tekrar dene';

  @override
  String get vazgec => 'Vazgeç';

  @override
  String get reddet => 'Reddet';

  @override
  String get title => 'title';

  @override
  String get isleniyor => 'İşleniyor...';

  @override
  String get onayla => 'Onayla';

  @override
  String get approved => 'Onaylandı';

  @override
  String get tumu => 'Tümü';

  @override
  String get kayitBulunamadi => 'Kayıt bulunamadı.';

  @override
  String get temizle => 'Temizle';

  @override
  String get uygula => 'Uygula';

  @override
  String get pending => 'Beklemede';

  @override
  String get reddedildi => 'Reddedildi';

  @override
  String get satirSec => 'Satır seç';

  @override
  String get gonder => 'Gönder';

  @override
  String get rejected => 'Reddedildi';

  @override
  String get detay => 'Detay';

  @override
  String get duzenle => 'Düzenle';

  @override
  String get eminMisin => 'Emin misin?';

  @override
  String get guncellendi => 'Güncellendi.';

  @override
  String get reddedildi_2 => 'Reddedildi.';

  @override
  String get sla => 'Geri Dönüş Süresi';

  @override
  String get csvDisaAktar => 'CSV Dışa Aktar';

  @override
  String get onaylandi => 'Onaylandı';

  @override
  String get yenile => 'Yenile';

  @override
  String get atanan => 'Atanan';

  @override
  String get beklemede => 'Beklemede';

  @override
  String get durum => 'Durum';

  @override
  String get tabRecommended => 'Önerilenler';

  @override
  String get tabCampaigns => 'Kampanyalar';

  @override
  String get tabFoods => 'Yemekler';

  @override
  String get whyTop => 'Neden üstte?';

  @override
  String get quickSuggestionTitle => 'Hızlı Öneri';

  @override
  String get quickSuggestionSubtitle => 'Dakikalar içinde karar ver';

  @override
  String get quickSuggestionPreset => '2 kişi / ₺600';

  @override
  String get whatToEatTitle => 'Ne yesek?';

  @override
  String get whatToEatSubtitle => 'Hızlı öneriler';

  @override
  String get nearbyShort => 'Yakında';

  @override
  String get affordableShort => 'Uygun fiyat';

  @override
  String get quickDecisionShort => 'Hızlı Karar';

  @override
  String get start => 'Başla';

  @override
  String get friendGroupTitle => 'Arkadaş Grubu';

  @override
  String get friendGroupSubtitle => 'Birlikte karar verin';

  @override
  String get openGroup => 'Grubu Aç';

  @override
  String get myGroups => 'Gruplarım';

  @override
  String get onTheRoadTitle => 'Yoldayım';

  @override
  String get onTheRoadSubtitle => 'Rotandaki duraklar';

  @override
  String get heroesTitle => 'Kahramanlar';

  @override
  String get heroesSubtitle => 'Öne çıkan keşifler';

  @override
  String get view => 'Görüntüle';

  @override
  String get bestBusinessesThisWeek => 'Bu Haftanın En İyi İşletmeleri';

  @override
  String get bestBusinessesThisMonth => 'Bu Ayın En İyi İşletmeleri';

  @override
  String get onTheRoad20km => 'Yolda • 20 km';

  @override
  String nearbyKm(int km) {
    return 'Yakında • $km km';
  }

  @override
  String get liveResultsUpdating => 'Canlı sonuçlar güncelleniyor';

  @override
  String get businessApprovedData => 'İşletme onaylı verisi';

  @override
  String get communityData => 'Topluluk verisi';

  @override
  String get removeFromFavorites => 'Favorilerden çıkar';

  @override
  String get locationPermissionTitle => 'Konum izni ver';

  @override
  String get locationPermissionDescription =>
      'Yakındaki yerleri göstermek için konum izni gerekli.';

  @override
  String get allow => 'İzin Ver';

  @override
  String get selectLocation => 'Konum Seç';

  @override
  String get manualLocationHint => 'Konumu manuel seçebilirsin.';

  @override
  String get noResultsYet => 'Henüz sonuç yok';

  @override
  String get lowDataInArea => 'Bu bölgede veri az';

  @override
  String get tryDifferentSearchOrFilter =>
      'Farklı bir arama ya da filtre dene.';

  @override
  String get beFirstContributorInArea => 'Bölgede ilk katkıyı sen yap.';

  @override
  String get topVerifiedMenus => 'En Çok Doğrulanan Menüler';

  @override
  String get mostTrustedMenusInCity => 'Şehirde En Güvenilen Menüler';

  @override
  String get seeList => 'Listeyi Gör';

  @override
  String get localContributionCall => 'Yerel katkı çağrısı';

  @override
  String get addFirstMenu => 'İlk Menüyü Ekle';

  @override
  String get suggestBusiness => 'İşletme Öner';

  @override
  String get noSurpriseSuggestionNow => 'Şu an sürpriz öneri yok';

  @override
  String get priceVerifiedInLast48h => 'Bu fiyat son 48 saatte doğrulandı';

  @override
  String get menuMayBeOutdated => 'Menü güncel olmayabilir';

  @override
  String get verifiedByBusiness => 'İşletme tarafından doğrulandı';

  @override
  String get updatedByCommunity => 'Topluluk tarafından güncellendi';

  @override
  String get topRankedInDistrict => 'İlçede üst sıralarda';

  @override
  String get surpriseDiscoveryTitle => 'Sürpriz Keşif';

  @override
  String get surpriseDiscoverySubtitle => 'Alışkanlığının dışına çık';

  @override
  String get randomButGood => 'Rastgele ama iyi';

  @override
  String get outsideYourUsual => 'Rutin dışı';

  @override
  String get pricePerformanceSurprise => 'Fiyat/performans sürprizi';

  @override
  String get nearbyCampaignsAndAnnouncements =>
      'Yakındaki kampanyalar ve duyurular';

  @override
  String get noNearbyCampaign => 'Yakında kampanya yok';

  @override
  String get noActiveAnnouncementInArea => 'Bölgede aktif duyuru yok';

  @override
  String get remainingLabel => 'Kalan';

  @override
  String get campaign => 'Kampanya';

  @override
  String get active => 'Aktif';

  @override
  String get noLocationDataForMap => 'Harita için konum verisi yok';

  @override
  String get mapDataMissingUseList =>
      'Harita verisi eksik, liste görünümünü kullan.';

  @override
  String get openMapView => 'Harita Görünümünü Aç';

  @override
  String get mapHintTapPins => 'İğnelere dokunarak detayları gör.';

  @override
  String get locationPermissionRequired => 'Konum izni gerekli.';

  @override
  String get noFoodFoundForCriteria => 'Bu kriterlere uygun yemek bulunamadı';

  @override
  String get whatToEatDescription => 'Tercihlerine göre öneriler';

  @override
  String get stepPeopleCount => 'Kişi sayısı';

  @override
  String get quickDecisionThreeOptions => '3 seçenekle hızlı karar';

  @override
  String get stepBudgetTotal => 'Toplam bütçe';

  @override
  String get budgetTl => 'Bütçe (₺)';

  @override
  String get stepDistance => 'Mesafe';

  @override
  String get locationNotSelected => 'Konum seçilmedi';

  @override
  String get seeSuggestions => 'Önerileri Gör';

  @override
  String get getSingleSuggestion => 'Tek öneri al';

  @override
  String get go => 'Git';

  @override
  String get restart => 'Yeniden Başlat';

  @override
  String get quickShortcuts => 'Hızlı Kısayollar';

  @override
  String get quickShortcutsSubtitle => 'En sık kullanılanlar';

  @override
  String get savedItems => 'Kaydettiklerim';

  @override
  String get myFriendGroup => 'Arkadaş Grubum';

  @override
  String get tasteExperts => 'Lezzet Uzmanları';

  @override
  String get businessTools => 'İşletme Araçları';

  @override
  String get businessToolsSubtitle => 'Yönetim ve içgörüler';

  @override
  String get sponsoredLabelChip => 'Sponsorlu etiket';

  @override
  String get sponsored => 'Sponsorlu';

  @override
  String get ready => 'Hazır';

  @override
  String get plan => 'plan';

  @override
  String get sponsoredDisclosure => 'Sponsorlu içerik';

  @override
  String get sponsoredTooltip => 'Bu içerik sponsorlu olabilir.';

  @override
  String localInsightsReady(String area) {
    return 'Yerel içgörüler hazır';
  }

  @override
  String get show => 'Göster';

  @override
  String get restaurant => 'Restoran';

  @override
  String get cafe => 'Kafe';

  @override
  String get venue => 'Mekan';

  @override
  String get notifications => 'Bildirimler';

  @override
  String get businessPackage => 'İşletme Paketi';

  @override
  String get redirectToReservation => 'Rezervasyona yönlendir';

  @override
  String get priceAlerts => 'Fiyat Uyarıları';

  @override
  String get corporateIntegration => 'Kurumsal Entegrasyon';

  @override
  String get detailedReports => 'Detaylı Raporlar';

  @override
  String get qrTools => 'QR Araçları';

  @override
  String get unlockNewFeatures => 'Yeni özelliklerin kilidini aç';

  @override
  String get branchManagement => 'Şube Yönetimi';

  @override
  String get menuWithQr => 'QR ile Menü';

  @override
  String get newFeatures => 'Yeni Özellikler';

  @override
  String nearOpenSectionTitle(String area) {
    return 'Yakında Açık Olanlar';
  }

  @override
  String mostViewedThisWeekTitle(String area) {
    return 'Bu Haftanın En Çok Görüntülenenleri';
  }

  @override
  String get noViewDataInArea => 'Bölgede görüntüleme verisi yok';

  @override
  String viewsMetric(int count) {
    return 'görüntüleme';
  }

  @override
  String highestPriceChangeTitle(String area) {
    return 'En Yüksek Fiyat Değişimi';
  }

  @override
  String get noPriceMovementInArea => 'Bölgede fiyat hareketi yok';

  @override
  String priceChangeMetric(int count) {
    return 'fiyat değişimi';
  }

  @override
  String nightOpenFavoritesTitle(String area) {
    return 'Gece Açık Favoriler';
  }

  @override
  String get noNightOpenFavoritesInArea => 'Bölgede gece açık favori yok';

  @override
  String followersMetric(int count) {
    return 'takipçi';
  }

  @override
  String popularCategoriesTitle(String area) {
    return 'Popüler Kategoriler';
  }

  @override
  String regionalPriceIndexTitle(String area) {
    return 'Bölgesel Fiyat Endeksi';
  }

  @override
  String get detailedAnalysis => 'Detaylı Analiz';

  @override
  String get loadWhenScrolledDown => 'Aşağı kaydırınca yüklenir';

  @override
  String anomalyMonitoringTitle(String area) {
    return '$area anomali izlemesi';
  }

  @override
  String get general => 'Genel';

  @override
  String get priceIndexLoadFailed => 'Fiyat endeksi yüklenemedi';

  @override
  String get noPriceIndexDataInArea => 'Bölgede fiyat endeksi verisi yok';

  @override
  String medianPriceLabel(String price) {
    return 'Medyan fiyat $price';
  }

  @override
  String get anomalyListLoadFailed => 'Anomali listesi yüklenemedi';

  @override
  String get noPriceAnomalyLast30Days => 'Son 30 günde fiyat anomalisi yok';

  @override
  String get sectionLoadFailed => 'Bölüm yüklenemedi';

  @override
  String rankedAt(String prefix, int rank) {
    return 'Sıra: $rank';
  }

  @override
  String yourScore(Object score) {
    return 'Puanın: $score';
  }

  @override
  String get createGroup => 'Grup kur';

  @override
  String get newPlaces => 'Yeni yerler';

  @override
  String get campaignEnded => 'bitti';

  @override
  String timeDays(int count) {
    return '$count gün';
  }

  @override
  String timeHours(int count) {
    return '$count saat';
  }

  @override
  String timeMinutes(int count) {
    return '$count dk';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count gün önce';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count saat önce';
  }

  @override
  String timeMinutesAgo(int count) {
    return '$count dakika önce';
  }

  @override
  String get statusVerifiedShort => 'Doğrulandı';

  @override
  String get statusMixedShort => 'Karışık';

  @override
  String get statusOutdatedShort => 'Güncel Değil';

  @override
  String get statusUnknownShort => 'Bilinmiyor';

  @override
  String get threeMonthsShort => '(3 Ay)';

  @override
  String versionAndSource(int version, String source) {
    return 'Sürüm ve kaynak';
  }

  @override
  String get sourceOwner => 'Kaynak: işletme';

  @override
  String get sourceCommunity => 'topluluk';

  @override
  String get sourceAi => 'otomatik';

  @override
  String shareBusinessMessage(
    String name,
    String location,
    String web,
    String deep,
  ) {
    return 'İşletmeyi paylaş';
  }

  @override
  String get noLinkFound => 'Bağlantı bulunamadı';

  @override
  String get newEmbedLinksWillAppear =>
      'Yeni gömülü bağlantılar burada görünecek.';

  @override
  String get link => 'Bağlantı';

  @override
  String get untitledLink => 'Başlıksız bağlantı';

  @override
  String menuShareNotFoundTitle(String appName) {
    return 'Menü bulunamadı • $appName';
  }

  @override
  String get menuShareNotFoundDescription =>
      'Paylaşılan menü içeriği bulunamadı.';

  @override
  String get menuContentNotFound => 'Menü içeriği bulunamadı';

  @override
  String get openAppForBetterExperience =>
      'Daha iyi deneyim için uygulamayı aç.';

  @override
  String get openApp => 'Uygulamayı Aç';

  @override
  String nearbyPeopleViewed(int count) {
    return 'Yakındaki kişiler görüntüledi';
  }

  @override
  String get verifiedPrices => 'Doğrulanmış fiyatlar';

  @override
  String get selectRatingFirst => 'Önce puan seç';

  @override
  String get thankYou => 'Teşekkürler';

  @override
  String get noProductsFound => 'Ürün bulunamadı';

  @override
  String preparedWithApp(String appName) {
    return 'Uygulama ile hazırlandı';
  }

  @override
  String tableLabel(String tableNo) {
    return 'Masa $tableNo';
  }

  @override
  String tableServiceQuestion(String tableNo) {
    return 'Masa servisi var mı?';
  }

  @override
  String get shortNoteOptional => 'Kısa not (opsiyonel)';

  @override
  String get submit => 'Gönder';

  @override
  String get submitted => 'Gönderildi';

  @override
  String get submitting => 'Gönderiliyor';

  @override
  String get mySuggestionsTitle => 'Önerilerim';

  @override
  String get mySuggestionsSubtitle => 'Gönderdiğin fiyat önerileri';

  @override
  String get viewBusiness => 'İşletmeyi Gör';

  @override
  String get statusApproved => 'Onaylandı';

  @override
  String get statusRejected => 'Reddedildi';

  @override
  String get statusPending => 'Beklemede';

  @override
  String get retry => 'Tekrar dene';

  @override
  String get notNow => 'Şimdi değil';

  @override
  String get onboardingLiveMenusTitle => 'Canlı Menüler';

  @override
  String get onboardingLiveMenusDescription => 'Güncel menülere anında eriş.';

  @override
  String get onboardingContributeTitle => 'Katkıda Bulun';

  @override
  String get onboardingContributeDescription =>
      'Topluluk için fiyatları doğrula ve güncelle.';

  @override
  String get getStarted => 'Başlayalım';

  @override
  String get continueAction => 'Devam';

  @override
  String get register => 'Kayıt Ol';

  @override
  String get login => 'Giriş Yap';

  @override
  String get enableLocationTitle => 'Konumu Aç';

  @override
  String get enableLocationSubtitle =>
      'Yakındaki yerleri göstermek için konumunu aç.';

  @override
  String get locationPermissionGranted => 'Konum izni verildi';

  @override
  String get locationOptionalInfo => 'İstersen daha sonra da açabilirsin.';

  @override
  String get allowLocation => 'Konuma izin ver';

  @override
  String get chooseLocationManually => 'Konumu Elle Seç';

  @override
  String get menuReading => 'Menü okunuyor';

  @override
  String get noPriceDetectionFound => 'Fiyat tespiti bulunamadı';

  @override
  String get receiptOcrNotSupportedWeb =>
      'Web sürümünde fiş OCR desteklenmiyor';

  @override
  String get receiptReading => 'Fiş okunuyor';

  @override
  String get noPriceFoundOnReceipt => 'Fişte fiyat bulunamadı';

  @override
  String get receiptUploading => 'Fiş yükleniyor';

  @override
  String get receiptUploadFailed => 'Fiş yükleme başarısız';

  @override
  String get camera => 'Kamera';

  @override
  String get gallery => 'Galeri';

  @override
  String get matchReceipt => 'Fişi Eşleştir';

  @override
  String get matchPrices => 'Fiyatları Eşleştir';

  @override
  String autoMatchedRowsCheck(int count) {
    return 'Otomatik eşleşen satırları kontrol et.';
  }

  @override
  String get unlabeled => 'Etiketsiz';

  @override
  String get priceTry => 'Fiyat (₺)';

  @override
  String get selectMenuItem => 'Menü ürünü seç';

  @override
  String get sendReceipt => 'Fişi Gönder';

  @override
  String get sendReceiptSuggestions => 'Fiş Önerilerini Gönder';

  @override
  String get selectAtLeastOneItem => 'En az bir ürün seç';

  @override
  String get invalidPriceExists => 'Geçersiz fiyat var';

  @override
  String get sendingReceipt => 'Fiş gönderiliyor';

  @override
  String get receiptSent => 'Fiş gönderildi';

  @override
  String get sendingReceiptSuggestions => 'Fiş önerileri gönderiliyor';

  @override
  String get priceSuggestionsSent => 'Fiyat önerileri gönderildi';

  @override
  String get searchFoodHint => 'Yemek ara...';

  @override
  String get profileActive => 'Profil aktif';

  @override
  String get profileLoading => 'Profil yükleniyor';

  @override
  String get dietProfileNotFound => 'Beslenme profili bulunamadı';

  @override
  String get noResultsFound => 'Sonuç bulunamadı';

  @override
  String get allowLocationForNearby => 'Yakın sonuçlar için konum izni ver';

  @override
  String get setPriceAlert => 'Fiyat uyarısı kur';

  @override
  String get vegan => 'Vegan';

  @override
  String get vegetarian => 'Vejetaryen';

  @override
  String get lactoseFree => 'Laktozsuz';

  @override
  String get maxCalories => 'Maksimum kalori';

  @override
  String get onlyVerifiedPrice => 'Sadece teyitli fiyat';

  @override
  String votes(int count) {
    return '$count oy';
  }

  @override
  String get glutenFree => 'Glutensiz';

  @override
  String get menuItem => 'Menü ürünü';

  @override
  String get cataloged => 'Kataloglu';

  @override
  String get priceAlert => 'Fiyat Alarmı';

  @override
  String get priceAlertSubtitle =>
      'Belirlediğin fiyatın altına düşünce haber verelim.';

  @override
  String get addToBill => 'Hesaba Ekle';

  @override
  String get voteSaved => 'Oyun kaydedildi';

  @override
  String get photoAdded => 'Fotoğraf eklendi';

  @override
  String photoQualityWarning(String warnings) {
    return 'Fotoğraf $warnings görünüyor. Daha net ve aydınlık bir fotoğraf yükleyebilirsin.';
  }

  @override
  String get suggestEdit => 'Düzenleme öner';

  @override
  String get verifyPriceWithReceipt => 'Fiş ile fiyat doğrula';

  @override
  String get cart => 'Sepet';

  @override
  String get cartEmpty => 'Sepet boş';

  @override
  String get addItemToCalculate => 'Hesaplamak için ürün ekle';

  @override
  String get tipPercentage => 'Bahşiş Yüzdesi';

  @override
  String get serviceIncluded => 'Servis dahil';

  @override
  String get coverIncluded => 'Kuver dahil';

  @override
  String get subtotal => 'Ara toplam';

  @override
  String get cover => 'Kuver';

  @override
  String serviceWithPercent(int percent) {
    return 'Servis ($percent%)';
  }

  @override
  String tipWithPercent(int percent) {
    return 'Bahşiş ($percent%)';
  }

  @override
  String get serviceCoverMayVary => 'Servis/kuver işletmeye göre değişebilir.';

  @override
  String get estimatedTotal => 'Tahmini Toplam';

  @override
  String get vatExcluded => 'KDV hariç';

  @override
  String get errorOccurred => 'Bir sorun oluştu';

  @override
  String get menuItemNotFoundDescription =>
      'Aradığın ürün henüz eklenmemiş olabilir. İstersen ilk sen ekle.';

  @override
  String get trustScoreInfoNote =>
      'Bu güven puanı kullanıcı oylaması değil, katkı kalitesinden oluşur.';

  @override
  String plusPoints(int points) {
    return '+$points puan';
  }

  @override
  String get verifyContributionRaisedScore =>
      'Fiyat doğrulaman katkın puanını yükseltti.';

  @override
  String get priceVerification => 'Fiyat doğrulama';

  @override
  String get priceVerificationSteps =>
      '1) Gördüğün fiyatı yaz  2) Gerekirse not/foto ekle  3) Gönder';

  @override
  String get newPriceTry => 'Yeni fiyat (₺)';

  @override
  String get note => 'Not';

  @override
  String get addEvidencePhoto => 'Kanıt fotoğrafı ekle';

  @override
  String get evidenceAdded => 'Kanıt eklendi';

  @override
  String get menuItemName => 'Ürün adı';

  @override
  String get menuItemNameRequired => 'Ürün adı boş olamaz';

  @override
  String get enterValidPrice => 'Geçerli bir fiyat gir';

  @override
  String get sendSuggestion => 'Öneri Gönder';

  @override
  String get noChanges => 'Değişiklik yok';

  @override
  String get priceCannotBeEmpty => 'Fiyat boş olamaz';

  @override
  String get suggestionSentPendingApproval =>
      'Önerin gönderildi, onay bekliyor.';

  @override
  String get noSuggestionFound => 'Öneri bulunamadı';

  @override
  String get suggestedFoods => 'Önerilen Yemekler';

  @override
  String get priceHistoryLast3 => 'Fiyat geçmişi (son 3)';

  @override
  String get price => 'Fiyat';

  @override
  String last30DaysVotes(int ok, int bad) {
    return 'Son 30 gün oyları';
  }

  @override
  String lastVerificationDate(String date) {
    return 'Son doğrulama: $date';
  }

  @override
  String uniqueVerifiersIn48h(int count) {
    return '48 saatte doğrulayan farklı kullanıcı: $count';
  }

  @override
  String get strongConsensusPriceSafe =>
      'Güçlü uzlaşı var, fiyat güvenli görünüyor.';

  @override
  String priceConfidenceScore(int score) {
    return 'Fiyat güven puanı: %$score';
  }

  @override
  String get seenCorrect => 'Gördüm • Doğru';

  @override
  String get seenIncorrect => 'Gördüm • Yanlış';

  @override
  String get suggestNewPrice => 'Yeni fiyat öner';

  @override
  String get howCalculated => 'Nasıl hesaplandı?';

  @override
  String get verificationRate => 'Doğrulama oranı';

  @override
  String get recentPositiveVotes => 'Son olumlu oylar';

  @override
  String get priceStability => 'Fiyat istikrarı';

  @override
  String priceChangeLast30Days(int count) {
    return 'Son 30 günde fiyat değişimi: $count';
  }

  @override
  String get scoreForInfoOnly => 'Bu skor yalnızca bilgilendirme amaçlıdır.';

  @override
  String get pricePerformance => 'Fiyat/Performans';

  @override
  String get valueScoreFormulaHint =>
      'Doğrulama oranı, son olumlu oylar ve fiyat istikrarına göre hesaplanır.';

  @override
  String get menuPhotos => 'Menü Fotoğrafları';

  @override
  String updateMenuEarnPoints(int points) {
    return 'Menü güncelle, puan kazan';
  }

  @override
  String get menuPhotosHint =>
      'Menü fotoğrafları ürünü göstermeli. Otomatik kırpılır; karanlık/flu olanlar uyarılır.';

  @override
  String get noPhotosYet => 'Henüz fotoğraf yok.';

  @override
  String get yesterday => 'Dün';

  @override
  String timeMonthsAgo(int count) {
    return '$count ay önce';
  }

  @override
  String get priceInvalid => 'Fiyat geçersiz';

  @override
  String get noteNoLinkPhone => 'Not alanına bağlantı veya telefon eklenemez.';

  @override
  String get noteContainsProfanity => 'Notta uygunsuz ifade var.';

  @override
  String get noteTooManyEmoji => 'Notta çok fazla emoji var';

  @override
  String get rateLimited24h => '24 saatlik sınır aşıldı';

  @override
  String get dailyPriceSuggestionLimitReached =>
      'Günlük fiyat öneri limitine ulaşıldı';

  @override
  String get invalidEvidenceLink => 'Kanıt bağlantısı geçersiz.';

  @override
  String get invalidCurrency => 'Geçersiz para birimi';

  @override
  String get ownerSections => 'Bölümler';

  @override
  String get ownerAddSection => 'Bölüm Ekle';

  @override
  String get ownerSectionNotFound => 'Henüz bölüm yok.';

  @override
  String get ownerEditSection => 'Bölümü Düzenle';

  @override
  String get ownerDeleteSection => 'Bölümü Sil';

  @override
  String get ownerSectionWillBeDeleted => 'Bu bölüm silinecek.';

  @override
  String get ownerArchiveItemsInSection => 'Bölümdeki ürünleri arşivle';

  @override
  String get ownerSectionAdded => 'Bölüm eklendi.';

  @override
  String get ownerSectionUpdated => 'Bölüm güncellendi.';

  @override
  String get ownerSectionDeleted => 'Bölüm silindi.';

  @override
  String get ownerEditMenu => 'Menüyü Düzenle';

  @override
  String get ownerMenuTypeOptional => 'Menü türü (opsiyonel)';

  @override
  String get ownerMenuUpdated => 'Menü güncellendi.';

  @override
  String get ownerArchiveMenuConfirm => 'Bu menüyü arşivlemek istiyor musun?';

  @override
  String get ownerPublishMenuConfirm => 'Bu menüyü yayına almak istiyor musun?';

  @override
  String get ownerSharePanel => 'Menü Paylaşım Paneli';

  @override
  String get ownerMenuLink => 'Menü bağlantısı';

  @override
  String get ownerQrPng => 'QR PNG';

  @override
  String get ownerQrPdf => 'QR PDF';

  @override
  String get ownerA6Pdf => 'A6 PDF';

  @override
  String get ownerFieldGainCardTitle => 'Sahada görünürlük kartı';

  @override
  String get ownerFieldGainCardLine1 =>
      'QR kartı yazdırıp müşterilere menüyü doğrulat.';

  @override
  String get ownerFieldGainCardLine2 =>
      'Menü ne kadar güncelse o kadar çok öne çıkarsın.';

  @override
  String get ownerCopyMiniDashboard => 'Mini panel bağlantısını kopyala';

  @override
  String get ownerMoatTitle => 'İşletme güven özeti';

  @override
  String ownerMoatSummary(int trust, int freshness, int accuracy) {
    return 'Güven: $trust | Menü güncelliği: $freshness | Fiyat doğruluğu: $accuracy';
  }

  @override
  String ownerMoatSignal(int validators, int evidencePct, int viewsToday) {
    return 'Sinyal: $validators doğrulayıcı, kanıt oranı %$evidencePct, bugün menü görüntüleme: $viewsToday';
  }

  @override
  String get ownerCopyMoatText => 'Özet metni kopyala';

  @override
  String get ownerWhatsappText => 'WhatsApp metni';

  @override
  String get ownerCopyWhatsapp => 'WhatsApp için kopyala';

  @override
  String get ownerXText => 'X (Twitter) metni';

  @override
  String get ownerCopyX => 'X için kopyala';

  @override
  String get ownerInstagramBio => 'Instagram biyografi metni';

  @override
  String get ownerCopyInstagram => 'Instagram için kopyala';

  @override
  String get ownerCopied => 'Kopyalandı';

  @override
  String ownerNearbyViewed(int count) {
    return '$count kişi yakında bu menüye baktı';
  }

  @override
  String ownerViewed(int count) {
    return '$count kişi baktı';
  }

  @override
  String get ownerCurrentMenuVerifiedPrices =>
      'Güncel menü ve doğrulanmış fiyatlar';

  @override
  String get ownerCurrentMenuVerifiedPricesColon =>
      'Güncel menü ve doğrulanmış fiyatlar:';

  @override
  String get ownerStatusPublished => 'Yayında';

  @override
  String get ownerStatusArchived => 'Arşivde';

  @override
  String get ownerStatusDraft => 'Taslak';

  @override
  String ownerMenuStatus(String status) {
    return 'Durum: $status';
  }

  @override
  String get ownerProducts => 'Ürünler';

  @override
  String get ownerApplying => 'Uygulanıyor...';

  @override
  String get ownerBulkPrice => 'Toplu Fiyat';

  @override
  String get ownerCsvImport => 'CSV İçe Aktar';

  @override
  String get ownerAddItem => 'Ürün Ekle';

  @override
  String get ownerProductNotFound => 'Henüz ürün yok.';

  @override
  String get ownerLoadMore => 'Daha fazla yükle';

  @override
  String get ownerEditItem => 'Ürünü Düzenle';

  @override
  String get ownerItemAdded => 'Ürün eklendi.';

  @override
  String get ownerItemUpdated => 'Ürün güncellendi.';

  @override
  String get ownerArchiveItemConfirm => 'Bu ürünü arşivlemek istiyor musun?';

  @override
  String get ownerItemArchived => 'Ürün arşivlendi.';

  @override
  String get ownerBulkPriceUpdate => 'Toplu fiyat güncelle';

  @override
  String get ownerMethod => 'Yöntem';

  @override
  String get ownerPercent => 'Yüzde';

  @override
  String get ownerFixedAmountTl => 'Sabit tutar (TL)';

  @override
  String get ownerOperation => 'İşlem';

  @override
  String get ownerIncrease => 'Artır';

  @override
  String get ownerDecrease => 'Azalt';

  @override
  String get ownerValuePercent => 'Değer (%)';

  @override
  String get ownerValueTl => 'Değer (TL)';

  @override
  String get ownerEnterValidValue => 'Lütfen geçerli bir değer gir.';

  @override
  String ownerUpdatedItemPrices(int count) {
    return '$count ürünün fiyatı güncellendi.';
  }

  @override
  String get ownerCsvFormatHint => 'Format: ad,fiyat,açıklama,para_birimi';

  @override
  String get ownerSelecting => 'Seçiliyor...';

  @override
  String get ownerSelectFile => 'Dosya Seç';

  @override
  String get ownerCsvExample => 'Döner,220,100 gr et,TRY';

  @override
  String get ownerImportContent => 'İçe Aktar';

  @override
  String get ownerNoValidRows => 'Geçerli satır bulunamadı.';

  @override
  String ownerImportedItems(int success) {
    return '$success ürün içe aktarıldı.';
  }

  @override
  String ownerImportedItemsWithSkipped(int success, int failed) {
    return '$success ürün eklendi, $failed satır atlandı.';
  }

  @override
  String get ownerAreYouSure => 'Emin misin?';

  @override
  String get ownerConfirm => 'Onayla';

  @override
  String get ownerArchiveAction => 'Arşivle';

  @override
  String get ownerPublishAction => 'Yayına Al';

  @override
  String get ownerDelete => 'Sil';

  @override
  String get ownerItemName => 'Ürün adı';

  @override
  String get ownerDescriptionOptional => 'Açıklama (opsiyonel)';

  @override
  String get ownerPriceTl => 'Fiyat (TL)';

  @override
  String get ownerCurrency => 'Para birimi';

  @override
  String get ownerCatalogSearch => 'Katalog ara';

  @override
  String get ownerCatalogSearchHint => 'Örn: Köfte, Burger...';

  @override
  String ownerSelectedCatalogId(int id) {
    return 'Seçili katalog ID: $id';
  }

  @override
  String get ownerItemNameMin2 => 'Ürün adı en az 2 karakter olmalı.';

  @override
  String get ownerInvalidPrice => 'Fiyat geçersiz.';

  @override
  String get ownerVariants => 'Varyantlar';

  @override
  String get ownerAddVariant => 'Varyant Ekle';

  @override
  String get ownerNoVariantsHint =>
      'Bu ürün için henüz varyant yok. Örnek: 80gr / 120gr';

  @override
  String get ownerDefaultVariant => 'Varsayılan';

  @override
  String get ownerSetDefault => 'Varsayılan yap';

  @override
  String get ownerLabelExample => 'Etiket (örn: 120gr)';

  @override
  String get ownerDefaultVariantSwitch => 'Varsayılan varyant';

  @override
  String get ownerPhotos => 'Fotoğraflar';

  @override
  String get ownerUploading => 'Yükleniyor...';

  @override
  String get ownerAddPhoto => 'Fotoğraf Ekle';

  @override
  String get ownerNoPhotoYet => 'Henüz fotoğraf yok.';

  @override
  String get ownerViewAll => 'Tümünü gör';

  @override
  String get ownerPhotoUploaded => 'Fotoğraf yüklendi.';

  @override
  String get ownerDeletePhoto => 'Fotoğrafı sil';

  @override
  String get ownerDeletePhotoConfirm => 'Bu fotoğraf silinecek.';

  @override
  String get ownerPhotoDeleted => 'Fotoğraf silindi.';

  @override
  String get adminAppealsTitle => 'İtiraz Kuyruğu';

  @override
  String get adminAppealsEmptySla =>
      'İtiraz yok. Hedef süre: rapor 24 saat, sahiplik talebi 48 saat.';

  @override
  String adminAppealSourceAndUser(String sourceId, String userId) {
    return 'Kaynak: $sourceId · Kullanıcı: $userId';
  }

  @override
  String adminAppealDecisionTitle(String id) {
    return 'İtiraz Kararı · $id';
  }

  @override
  String get adminAppealApproveAction => 'Onayla';

  @override
  String get adminAppealRejectAction => 'Reddet';

  @override
  String get adminAppealDecisionLabel => 'Karar';

  @override
  String get adminAppealTemplateLabel => 'Hazır şablon';

  @override
  String get adminAppealDecisionTextLabel => 'Karar metni';

  @override
  String get adminAppealDecisionTextHint =>
      'Kullanıcıya gösterilecek kısa açıklama';

  @override
  String get ownerNewBusinessTitle => 'Yeni işletme ekle';

  @override
  String get ownerNewBusinessIntro =>
      'Yeni işletmeni eklemek için bilgileri doldur.';

  @override
  String get ownerBusinessNameLabel => 'İşletme adı';

  @override
  String get ownerCategoryLabel => 'Kategori';

  @override
  String get ownerAddressLabel => 'Adres';

  @override
  String get ownerPhoneOptionalLabel => 'Telefon (opsiyonel)';

  @override
  String get ownerWebsiteOptionalLabel => 'Web sitesi (opsiyonel)';

  @override
  String get ownerSubmitApplication => 'Başvuruyu gönder';

  @override
  String get ownerSubmitting => 'Gönderiliyor...';

  @override
  String get ownerRequiredFieldsWarning => 'Lütfen zorunlu alanları doldur.';

  @override
  String get ownerApplicationReceived => 'Başvuru alındı.';

  @override
  String get ownerBusinessesTitle => 'İşletmelerim';

  @override
  String get ownerChainPage => 'Zincir sayfası';

  @override
  String get ownerMyApplications => 'Başvurularım';

  @override
  String get ownerLinksUpdated => 'Linkler güncellendi.';

  @override
  String get ownerReservationOrderLinksTitle =>
      'Rezervasyon ve sipariş linkleri';

  @override
  String get ownerReservationUrlLabel => 'Rezervasyon URL';

  @override
  String get ownerYemeksepetiUrlLabel => 'Yemeksepeti URL';

  @override
  String get ownerTrendyolGoUrlLabel => 'Trendyol Go URL';

  @override
  String get ownerGetirUrlLabel => 'Getir URL';

  @override
  String get ownerChainLabel => 'Marka/Zincir';

  @override
  String get ownerAllBranches => 'Tüm şubeler';

  @override
  String get ownerBranchLabel => 'Şube';

  @override
  String ownerChainPrefix(String chain) {
    return 'Zincir: $chain';
  }

  @override
  String get ownerPriceVerificationAction => 'Fiyat doğrulama';

  @override
  String get ownerRequestsAction => 'Talepler';

  @override
  String get ownerRequestsOwnerOnly => 'Talepler (yalnızca işletme sahibi)';

  @override
  String get ownerReservationOrderLinksAction =>
      'Rezervasyon ve sipariş linkleri';

  @override
  String get ownerStatsNotFound => 'İstatistik bulunamadı.';

  @override
  String get ownerPerformanceLast30Days => 'Son 30 gün performans';

  @override
  String get ownerMetricMenuViews => 'Menü görüntülenme';

  @override
  String get ownerMetricQrScans => 'QR tarama';

  @override
  String get ownerMetricSearchImpressions => 'Arama gösterimi';

  @override
  String get ownerMetricConversion => 'Dönüşüm';

  @override
  String get ownerMetricOutboundClicks => 'Dış bağlantı tıklamaları';

  @override
  String get ownerMetricPriceDropoff => 'Fiyat nedeniyle vazgeçme (tahmini)';

  @override
  String get ownerMetricPriceVsCompetitors => 'Rakibe göre fiyat';

  @override
  String ownerOutboundClicksValue(int outbound, int reservation, int order) {
    return '$outbound (Rez: $reservation, Sipariş: $order)';
  }

  @override
  String ownerPricePositionHigher(String pct) {
    return 'Daha pahalı$pct';
  }

  @override
  String ownerPricePositionLower(String pct) {
    return 'Daha uygun$pct';
  }

  @override
  String get ownerPricePositionSimilar => 'Pazarla uyumlu';

  @override
  String get ownerPricePositionNoData => 'Yeterli veri yok';

  @override
  String get ownerNoBusinessesTitle => 'Henüz işletme yok';

  @override
  String get ownerNoBusinessesDescription =>
      'Yeni işletme başvurusu oluşturabilirsin.';

  @override
  String get ownerRoleOwner => 'İşletme sahibi';

  @override
  String get ownerRoleManager => 'Yönetici';

  @override
  String get ownerMenuAction => 'Menü';

  @override
  String get city => 'Şehir';

  @override
  String get district => 'İlçe';

  @override
  String ownerActiveRange(String from, String to) {
    return 'Aktif: $from - $to';
  }

  @override
  String get vatIncluded => 'KDV dahil';
}
