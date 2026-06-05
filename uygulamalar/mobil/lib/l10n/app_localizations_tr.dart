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
  String get shareAsImage => 'Görsel Paylaş';

  @override
  String get shareLink => 'Link Paylaş';

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
  String get verify => 'Doğrula';

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
  String get trustDataUnavailable => 'Veri güveni verisi yok';

  @override
  String get freshnessAndTrust => 'Veri güveni dökümü';

  @override
  String get menuUpdatedLabel => 'Menü Güncellendi';

  @override
  String get lastPriceVerification => 'Son Fiyat Doğrulaması';

  @override
  String get trustScoreLabel => 'Güven Skoru';

  @override
  String get communityScoreDataTrustLabel => 'Veri güveni';

  @override
  String get communityScoreMenuFreshnessLabel => 'Menü güncelliği';

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
  String featuredFromCuisine(String cuisine) {
    return '$cuisine mutfağından öne çıkanlar';
  }

  @override
  String get weeklyPriceChange => '+₺50 bu hafta';

  @override
  String get chartPlaceholderSoon => 'Grafik alanı (yakında)';

  @override
  String get noPriceDataYet => 'Henüz fiyat verisi yok';

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
  String amenityCountLabel(int count) {
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
  String get decreaseQuantity => 'Azalt';

  @override
  String get increaseQuantity => 'Artır';

  @override
  String get kapat => 'Kapat';

  @override
  String get suspendedMealsEmptyDescription =>
      'Askıya aldığınız yemek planları burada görünecek.';

  @override
  String get ara => 'Ara';

  @override
  String ratingLabel(int count) {
    return '$count yıldız';
  }

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
    return 'Yerel içgörüler hazır • $area';
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
    return 'Yakında Açık Olanlar • $area';
  }

  @override
  String mostViewedThisWeekTitle(String area) {
    return 'Bu Haftanın En Çok Görüntülenenleri • $area';
  }

  @override
  String get noViewDataInArea => 'Bölgede görüntüleme verisi yok';

  @override
  String viewsMetric(int count) {
    return '$count görüntüleme';
  }

  @override
  String highestPriceChangeTitle(String area) {
    return 'En Yüksek Fiyat Değişimi • $area';
  }

  @override
  String get noPriceMovementInArea => 'Bölgede fiyat hareketi yok';

  @override
  String priceChangeMetric(int count) {
    return '$count fiyat değişimi';
  }

  @override
  String nightOpenFavoritesTitle(String area) {
    return 'Gece Açık Favoriler • $area';
  }

  @override
  String get noNightOpenFavoritesInArea => 'Bölgede gece açık favori yok';

  @override
  String followersMetric(int count) {
    return '$count takipçi';
  }

  @override
  String popularCategoriesTitle(String area) {
    return 'Popüler Kategoriler • $area';
  }

  @override
  String regionalPriceIndexTitle(String area) {
    return 'Bölgesel Fiyat Endeksi • $area';
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
  String rankedAt(int rank) {
    return 'Sıra: $rank';
  }

  @override
  String yourScore(String score) {
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
    return 'Sürüm $version • Kaynak: $source';
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
    return '$name • $location\n$web\n$deep';
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
    return 'Yakındaki $count kişi görüntüledi';
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
    return '$appName ile hazırlandı';
  }

  @override
  String tableLabel(String tableNo) {
    return 'Masa $tableNo';
  }

  @override
  String tableServiceQuestion(String tableNo) {
    return 'Masa $tableNo - servis var mı?';
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
  String get onboardingPriceTitle => 'Şehrin Fiyatlarını\nSen Belirle';

  @override
  String get onboardingPriceBody1 => 'Restoranları gerçek fiyatlarıyla keşfet';

  @override
  String get onboardingPriceBody2 =>
      'Fiyat geçmişini ve şehir ortalamasını gör';

  @override
  String get onboardingPriceBody3 => 'Bütçene göre filtrele, tasarruf et';

  @override
  String get onboardingCommunityTitle => 'Topluluğun Gücü';

  @override
  String get onboardingCommunitySubtitle =>
      'Her fiyat doğrulaması herkese yardım eder';

  @override
  String get onboardingCommunityBody1 =>
      'Gerçek kullanıcılar menüleri güncel tutar';

  @override
  String get onboardingCommunityBody2 => 'Fiyat sapmaları anında tespit edilir';

  @override
  String get onboardingCommunityBody3 => 'Katkın için XP ve rozetler kazan';

  @override
  String get onboardingNotificationTitle => 'Anlık Bildirimler';

  @override
  String get onboardingNotificationDescription =>
      'Favori mekanlarındaki fiyat değişikliklerini, kampanyaları ve grup taleplerini anında öğren.';

  @override
  String get onboardingNotificationsEnabled => 'Bildirimler etkinleştirildi';

  @override
  String get onboardingAllowNotifications => 'Bildirimlere İzin Ver';

  @override
  String get onboardingSkipNotifications => 'Şimdi değil';

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
    return 'Otomatik eşleşen $count satırı kontrol et.';
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
      'Bu puan kullanıcı oylaması değil, toplulukta ne kadar güvenilir katkı verdiğini gösterir.';

  @override
  String plusPoints(int points) {
    return '+$points puan';
  }

  @override
  String get verifyContributionRaisedScore =>
      'Fiyat doğrulaman topluluk güvenini destekledi.';

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
    return 'Son 30 gün oyları • Uygun: $ok • Uygunsuz: $bad';
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
  String get priceConfidenceDataTrustHint =>
      'Fiyat güveni, veri güveninin bir parçasıdır; son doğrulama ve uzlaşıya bakar.';

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
  String get communityScoreExplainAction => 'Skorlar ne anlama geliyor?';

  @override
  String get communityScoreWhatImproves => 'Neler etkiler?';

  @override
  String get communityScoreHowUsed => 'Uygulamada nasıl kullanılır?';

  @override
  String get communityScoreUserTrustCategory => 'Kullanıcı güveni';

  @override
  String get communityScoreDataTrustCategory => 'Veri güveni';

  @override
  String get communityScoreInfoOnlyCategory => 'Bilgi skoru';

  @override
  String get communityScoreUserTrustSummary =>
      'Topluluğun katkılarını ne kadar güvenilir bulduğunu gösterir. Popülerlik değil, doğruluk ve onay kalitesi bu puanı büyütür.';

  @override
  String get communityScoreUserTrustSignalAccuracy =>
      'Doğru çıkan katkılar ve isabetli doğrulamalar';

  @override
  String get communityScoreUserTrustSignalApproval => 'Onaylanan katkı oranı';

  @override
  String get communityScoreUserTrustSignalSafety =>
      'Düşük spam, suistimal ve red sinyali';

  @override
  String get communityScoreUserTrustUsage =>
      'Daha güvenilir katkılar topluluk akışında ve doğrulama kararlarında daha hızlı öne çıkar.';

  @override
  String get communityScoreDataTrustSummary =>
      'Bir menü veya fiyat bilgisinin şu anda ne kadar güvenilir olduğunu gösterir.';

  @override
  String get communityScoreDataTrustSignalFreshness =>
      'Menünün güncelliği ve son denetim tarihi';

  @override
  String get communityScoreDataTrustSignalConsensus =>
      'Birden fazla doğrulayıcı ve güçlü uzlaşı';

  @override
  String get communityScoreDataTrustSignalStability =>
      'Düşük çelişki ve tutarlı değişim geçmişi';

  @override
  String get communityScoreDataTrustUsage =>
      'Uygulama, fiyat veya menü bilgisini güvenle göstermek için bu sinyali kullanır.';

  @override
  String get communityScoreValueInsightSummary =>
      'Bu bir güven puanı değildir; doğrulama, oy ve fiyat istikrarından üretilen bilgi skorudur.';

  @override
  String get communityScoreValueSignalVerification => 'Doğrulama oranı';

  @override
  String get communityScoreValueSignalVotes => 'Son olumlu oylar';

  @override
  String get communityScoreValueSignalStability => 'Fiyat istikrarı';

  @override
  String get communityScoreValueUsage =>
      'Karar yardımcısıdır; tek başına kanıt yerine kullanılmaz.';

  @override
  String get menuPhotos => 'Menü Fotoğrafları';

  @override
  String updateMenuEarnPoints(int points) {
    return 'Menü güncelle, $points puan kazan';
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
  String get loginPageTitle => 'Giriş Yap';

  @override
  String get loginActionFailedTitle => 'İşlem tamamlanamadı';

  @override
  String loginActionFailedDescription(String error) {
    return '$error\nBağlantıyı kontrol edip tekrar dene.';
  }

  @override
  String get loginEmailLabel => 'E-posta';

  @override
  String get loginPasswordLabel => 'Şifre';

  @override
  String get loginPrimaryAction => 'Giriş Yap';

  @override
  String get loginSigningInAction => 'Giriş yapılıyor...';

  @override
  String get loginSignupAction => 'Giriş / Kayıt';

  @override
  String get loginSigningUpAction => 'Kayıt oluşturuluyor...';

  @override
  String get loginSignupSuccessMessage =>
      'Kayıt oluşturuldu. E-posta/telefon doğrulamasını tamamla.';

  @override
  String get drawerTopBusinesses => 'Top İşletmeler';

  @override
  String get drawerSocial => 'Sosyal';

  @override
  String get drawerGourmets => 'Lezzet uzmanları';

  @override
  String get drawerFollowing => 'Takip';

  @override
  String get drawerExperimental => 'Deneysel';

  @override
  String get drawerFeed => 'Akış';

  @override
  String get drawerTasteTwin => 'Tat eşleri';

  @override
  String get drawerHeroes => 'Kahramanlar';

  @override
  String get drawerGroupRequests => 'Grup Talepleri';

  @override
  String get drawerCompare => 'Karşılaştır';

  @override
  String get drawerQuickTools => 'Hızlı Araçlar';

  @override
  String get drawerSmartSuggestionShortcut => 'Akıllı Öneri (2 kişi / 600 TL)';

  @override
  String get drawerAccount => 'Hesap';

  @override
  String get drawerMyFavorites => 'Favorilerim';

  @override
  String get drawerInbox => 'Bildirim Kutusu';

  @override
  String drawerInboxWithCount(int count) {
    return 'Bildirim Kutusu ($count)';
  }

  @override
  String get drawerMySuggestions => 'Önerilerim';

  @override
  String get drawerSuspendedMeals => 'Askıda';

  @override
  String get drawerLegalAndTrust => 'Yasal ve Güven';

  @override
  String get budgetComboEntryTitle => 'Bütçem şu kadar';

  @override
  String get budgetComboLocationNotSelected => 'Konum seçilmedi';

  @override
  String get budgetComboBudgetLabel => 'Bütçe (TL)';

  @override
  String get budgetComboPartySizeLabel => 'Kişi';

  @override
  String get budgetComboCategoryOptionalLabel => 'Kategori (opsiyonel)';

  @override
  String get budgetComboSeeSuggestions => 'Önerileri Gör';

  @override
  String get budgetComboAllCategories => 'Tüm kategoriler';

  @override
  String get budgetComboCategoryCafe => 'Kafe';

  @override
  String get budgetComboCategoryRestaurant => 'Restoran';

  @override
  String get budgetComboCategoryDessert => 'Tatlıcı';

  @override
  String get budgetComboCategoryBreakfast => 'Kahvaltı';

  @override
  String get budgetComboCategoryFishMeat => 'Balık / Et';

  @override
  String get budgetComboCategoryVenue => 'Mekan';

  @override
  String get budgetComboResultsTitle => 'Bütçe Kombinleri';

  @override
  String get budgetComboMissingInfoTitle => 'Eksik bilgi';

  @override
  String get budgetComboMissingInfoDescription =>
      'Lütfen bütçe ve konum bilgisini girin.';

  @override
  String get budgetComboNoResultsTitle => 'Henüz uygun kombin yok';

  @override
  String get budgetComboNoResultsDescription =>
      'Bütçeyi artırmayı ya da kişi sayısını azaltmayı deneyin.';

  @override
  String get budgetComboAdjustCriteriaTitle => 'Kriter değiştir';

  @override
  String get budgetComboDefaultAction => 'Varsayılıan';

  @override
  String get budgetComboRadiusDistrictScope =>
      'Yakınlık filtresi şehir/ilçe düzeyinde uygulanır.';

  @override
  String budgetComboRadiusTarget(String km) {
    return 'Yakınlık hedefi: $km km';
  }

  @override
  String get budgetComboWeightDistance => 'Mesafe';

  @override
  String get budgetComboWeightPrice => 'Fiyat';

  @override
  String get budgetComboWeightRating => 'Puan';

  @override
  String get budgetComboFallbackSortHint =>
      'Mesafe/puan verisi yoksa sıralama fiyata göre yapılır.';

  @override
  String get budgetComboBestComboTitle => 'En uygun kombin';

  @override
  String get budgetComboTagTop => 'Top';

  @override
  String get budgetComboOtherSuggestionsTitle => 'Diğer öneriler';

  @override
  String budgetComboRatingLabelValue(String rating) {
    return 'Puan $rating';
  }

  @override
  String get budgetComboBestTag => 'En uygun';

  @override
  String get budgetComboMainItemLabel => 'Ana';

  @override
  String get budgetComboDrinkItemLabel => 'İçecek';

  @override
  String budgetComboTotalLabel(String price) {
    return '$price toplam';
  }

  @override
  String get budgetComboGoToBusinessAction => 'İşletmeye git';

  @override
  String get panelAccessTitle => 'Panel Erişimi';

  @override
  String get panelWebOnlyMessage => 'Bu panel web üzerinden kullanılır.';

  @override
  String panelRedirectedPath(String path) {
    return 'Yönlendirilen yol: $path';
  }

  @override
  String get panelBackToDiscover => 'Keşfet sayfasına dön';

  @override
  String get notFoundTitle => 'Sayfa Bulunamadı';

  @override
  String get businessHeaderStatusClosingLabel => 'Durum / Kapanış';

  @override
  String get businessHeaderAveragePriceLabel => 'Ortalama fiyat';

  @override
  String get businessHeaderPopularItemLabel => 'Popüler ürün';

  @override
  String get businessHeaderLastVerificationLabel => 'Son doğrulama';

  @override
  String get businessStatusOpen => 'Açık';

  @override
  String get businessStatusClosed => 'Kapalı';

  @override
  String get businessHeaderDirectionsAction => 'Yol tarifi';

  @override
  String get chainPageTitle => 'Zincir';

  @override
  String get chainPageNoBranches => 'Şube bulunamadı.';

  @override
  String get chainPageNearbyBranchesTitle => 'Yakın şubeler';

  @override
  String get chainPageBranchMenuPriceHint =>
      'Şube menü ve fiyatları farklı olabilir.';

  @override
  String chainPageBranchMoreExpensive(String pct) {
    return 'Bu şube daha pahalı (%$pct)';
  }

  @override
  String chainPageBranchMoreAffordable(String pct) {
    return 'Bu şube daha uygun (%$pct)';
  }

  @override
  String get chainPageBranchNearAverage => 'Zincir ortalamasına yakınlık';

  @override
  String get comparePageTitle => 'Karşılaştırma';

  @override
  String get compareEmptyTitle => 'Karşılaştırma boş';

  @override
  String get compareEmptyDescription =>
      'İşletme sayfalarından karşılaştırmaya ekle.';

  @override
  String get compareBackToDiscover => 'Keşfet sayfasına dön';

  @override
  String get compareBestPickAction => 'En mantıklı seçimi göster';

  @override
  String get compareSuggestedBadge => 'Öneri';

  @override
  String get compareMedianPriceLabel => 'Median fiyat';

  @override
  String get compareVerifiedRateLabel => 'Verified oranı';

  @override
  String get compareLastUpdateLabel => 'Son güncelleme';

  @override
  String get compareBestItemTitle => 'Uygun item';

  @override
  String get compareGoToBusinessAction => 'İşletmeye git';

  @override
  String get compareRemoveTooltip => 'Kaldır';

  @override
  String compareRecommendedSnack(String name) {
    return 'Öneri: $name';
  }

  @override
  String get contributeDefaultBusinessName => 'bu işletme';

  @override
  String get contributeOpenBusinessFirst =>
      'Bu katkı için önce bir işletme sayfası aç.';

  @override
  String get contributeUploadingProgress => 'Gönderiliyor...';

  @override
  String get contributeUploadSentSingle =>
      'Gönderildi - kontrol sonrası menüye eklenecek.';

  @override
  String contributeUploadSentMultiple(int count) {
    return '$count sayfa gönderildi - kontrol sonrası menüye eklenecek.';
  }

  @override
  String get contributeUploadFailed =>
      'Gönderim başarısız. Lütfen tekrar dene.';

  @override
  String get contributeQrDecodingProgress => 'QR çözülüyor...';

  @override
  String get contributeQrUnreadableSentReview =>
      'QR okunamadı. Görsel inceleme için gönderiliyor.';

  @override
  String get contributeQrVerifiedRedirecting =>
      'QR doğrulandı. Yönlendiriliyorsun.';

  @override
  String get contributeQrProcessFailed => 'QR işlenemedi. Lütfen tekrar dene.';

  @override
  String get contributeExternalQrUseBusinessPage =>
      'Dış QR kodu için işletme sayfasında Katkı yap kullan.';

  @override
  String get contributeSendingForReviewProgress =>
      'İnceleme için gönderiliyor...';

  @override
  String get contributeQrImageSentForReview =>
      'QR görüntüsü gönderildi. İnceleme sonrası işleme alınacak.';

  @override
  String get contributeExternalLinkSentForReview =>
      'Dış link incelemeye gönderildi.';

  @override
  String get contributeSourceCamera => 'Kamera';

  @override
  String get contributeSourceGallery => 'Galeri';

  @override
  String get contributeSelectBusinessForPriceVerification =>
      'Fiyat doğrulama için önce bir işletme seç.';

  @override
  String get contributeSelectMenuItemToVerifyPrice =>
      'Menüden tek ürün seçip fiyatını doğrulayabilirsin.';

  @override
  String get discoveryFilterCafe => 'Kafe';

  @override
  String get discoveryFilterRestaurant => 'Restoran';

  @override
  String get discoveryFilterDessertPastry => 'Tatlı / Pastane';

  @override
  String get discoveryFilterBreakfast => 'Kahvaltı';

  @override
  String get discoveryFilterFishMeat => 'Balık / Et';

  @override
  String get discoveryFilterVenue => 'Mekan';

  @override
  String get discoveryHomeCategoryDoner => 'İnce Döner';

  @override
  String get discoveryHomeCategoryPide => 'Pide';

  @override
  String get discoveryHomeCategoryLahmacun => 'Lahmacun';

  @override
  String get discoveryHomeCategoryBurger => 'Burger';

  @override
  String get discoveryHomeCategoryPizza => 'Pizza';

  @override
  String get discoveryHomeCategoryKebap => 'Kebap';

  @override
  String get discoveryHomeCategoryCorba => 'Çorba';

  @override
  String get discoveryHomeCategoryKahvalti => 'Kahvaltı';

  @override
  String get discoveryHomeCategoryManti => 'Mantı';

  @override
  String get discoveryHomeCategoryTatli => 'Tatlı';

  @override
  String get discoveryRecentSearches => 'Son aramalar';

  @override
  String get discoveryCatalogSuggestions => 'Katalog önerileri';

  @override
  String get feedEmptyMessage =>
      'Henüz akış yok. Lezzet uzmanlarını takip ederek başlayabilirsin.';

  @override
  String get all => 'Tümü';

  @override
  String get sil => 'Sil';

  @override
  String get favoritesCollectionLabel => 'Koleksiyon';

  @override
  String get favoritesSavedHereSubtitle => 'Kaydettiklerin burada';

  @override
  String favoritesSharedCollectionSubtitle(String name) {
    return 'Paylaşılan koleksiyon: $name';
  }

  @override
  String get favoritesSearchHint => 'Favorilerde ara';

  @override
  String get favoritesNearbyLoadingLocation =>
      'Yakınındakiler için konum alınıyor...';

  @override
  String get favoritesNearbyFallbackOrdering =>
      'Konum alınamadı. Varsaylan sıralama gösteriliyor.';

  @override
  String get favoritesNearbySortedByDistance =>
      'Yakınındakiler mesafeye göre sıralandı.';

  @override
  String get favoritesCollectionsTitle => 'Koleksiyonlar';

  @override
  String get favoritesCreateCollectionTooltip => 'Koleksiyon oluştur';

  @override
  String get favoritesShareCollectionTooltip => 'Koleksiyonu paylaş';

  @override
  String get favoritesDeleteCollectionTooltip => 'Koleksiyonu sil';

  @override
  String get favoritesCreatorSelectCollectionHint =>
      'İçerik üretici modu için önce bir koleksiyon seç.';

  @override
  String get favoritesCreatorCollectionTitle => 'İçerik üretici koleksiyonu';

  @override
  String get favoritesCreatorCollectionSubtitle =>
      'Koleksiyonunu yayınla, takipçi kazan. Reklam içeriği varsa etiket zorunludur.';

  @override
  String get favoritesPublishAction => 'Yayınla';

  @override
  String get favoritesPublishVisibleSubtitle =>
      'Profilinde ve paylaşım bağlantılarında görünür.';

  @override
  String get favoritesPublishPrivateSubtitle =>
      'Bu koleksiyonu sadece sen görürsün.';

  @override
  String get favoritesSharedCollectionTitle => 'Paylaşılan koleksiyon';

  @override
  String get favoritesFollowCollectionHint =>
      'Bu koleksiyonu takip ederek güncellemeleri kaçırmama.';

  @override
  String get favoritesFollowAction => 'Takip et';

  @override
  String get favoritesFollowingAction => 'Takiptesin';

  @override
  String favoritesFollowersChip(int count) {
    return 'Takipçi $count';
  }

  @override
  String favoritesEngagementChip(int count) {
    return 'Etkileşim $count';
  }

  @override
  String get favoritesNewCollectionTitle => 'Yeni Koleksiyon';

  @override
  String get favoritesCollectionNameExample => 'Örn: Gece döneri';

  @override
  String get favoritesCreateAction => 'Oluştur';

  @override
  String get favoritesDeleteCollectionConfirmTitle => 'Koleksiyon silinsin mi?';

  @override
  String get favoritesDeleteCollectionConfirmBody => 'Bu işlem geri alınamaz.';

  @override
  String favoritesBusinessCollectionsTitle(String businessName) {
    return '\"$businessName\" koleksiyonları';
  }

  @override
  String get favoritesNoCollectionYet =>
      'Henüz koleksiyon yok. Önce koleksiyon oluştur.';

  @override
  String get favoritesNewCollectionAction => 'Yeni koleksiyon';

  @override
  String get favoritesDisclosureSponsored => 'Reklam';

  @override
  String get favoritesDisclosureOrganic => 'Organik';

  @override
  String get favoritesDisclosurePrivate => 'Özel';

  @override
  String favoritesShareText(String name, String link, String disclosure) {
    return 'Yeedoy koleksiyonum: $name\n$link\n\nMod: Yakınındakilerden öner\nEtiket: $disclosure';
  }

  @override
  String get favoritesAdDisclosureTitle => 'Reklam bildirimi';

  @override
  String get favoritesAdDisclosureBody =>
      'Bu koleksiyonda iş birliği varsa \"Reklam\" olarak işaretlemek zorunludur.';

  @override
  String favoritesCacheStaleMessage(int days) {
    return 'Veri $days gün önce güncellenmiş¸ olabilir.';
  }

  @override
  String get favoritesAddToCollectionTooltip => 'Koleksiyona ekle';

  @override
  String get followingPageTitle => 'Takip Ettiklerim';

  @override
  String get followingPageEmpty => 'Henüz kimseyi takip etmiyorsun.';

  @override
  String get followingPageUnfollowAction => 'Takibi bırak';

  @override
  String get gourmetsPageTitle => 'Lezzet uzmanlarının keşfet';

  @override
  String get gourmetsPageEmpty => 'Henüz lezzet uzmanı yok.';

  @override
  String get groupRequestWizardTitle => 'Grup Yemeği Talebi';

  @override
  String get groupRequestWizardEnterDetails => 'Detayları gir';

  @override
  String get groupRequestWizardCityLabel => 'Şehir';

  @override
  String get groupRequestWizardDistrictLabel => 'İlçe';

  @override
  String get groupRequestWizardCategoryHint => 'Kategori (kahve, lokanta...)';

  @override
  String get groupRequestWizardPartySizeLabel => 'Kişi sayısı';

  @override
  String get groupRequestWizardTotalBudgetLabel => 'Toplam bütçe (TL)';

  @override
  String get groupRequestWizardNotesLabel => 'Notlar';

  @override
  String get groupRequestWizardCreateAction => 'Talep Oluştur';

  @override
  String get groupRequestWizardInfoTitle => 'Teklifler işletmelerden gelir';

  @override
  String get groupRequestWizardInfoDescription =>
      'Talebin açıldığında işletmeler teklif verebilir.';

  @override
  String get groupRequestWizardMissingFields => 'Eksik alan var';

  @override
  String get groupRequestWizardPickDateTime => 'Tarih ve saat seç';

  @override
  String get groupRequestMyRequestsTitle => 'Taleplerim';

  @override
  String get groupRequestNewRequestAction => 'Yeni Talep';

  @override
  String get groupRequestNoRequestsTitle => 'Talep yok';

  @override
  String get groupRequestNoRequestsDescription =>
      'İlk grup yemeği talebini oluştur.';

  @override
  String groupRequestPartyAndBudget(int party, String budget) {
    return '$party kişi · $budget';
  }

  @override
  String get groupRequestStatusOpen => 'Açık';

  @override
  String get groupRequestStatusAwarded => 'Kazandırıldı';

  @override
  String get groupRequestStatusClosed => 'Kapandı';

  @override
  String get groupRequestStatusCancelled => 'İptal';

  @override
  String get groupRequestDetailTitle => 'Grup Talebi';

  @override
  String get groupRequestLinkCopied => 'Grup linki kopyalandı';

  @override
  String get groupRequestNotFound => 'Talep bulunamadı';

  @override
  String get groupRequestCreatedBannerTitle => 'Talebin yayında';

  @override
  String get groupRequestCreatedBannerDescription =>
      'Grup linkini paylaş. Herkes önerileri ekler, oylar.';

  @override
  String get groupRequestLinkTitle => 'Grup linki';

  @override
  String get groupRequestCopyAction => 'Kopyala';

  @override
  String get groupRequestAddSuggestionTitle => 'Öneri ekle';

  @override
  String get groupRequestAddSuggestionDescription =>
      'İşletme seç, teklif ekle ve grup oylasın.';

  @override
  String get groupRequestAddSuggestionAction => 'Öneri ekle';

  @override
  String get groupRequestOffersTitle => 'Teklifler';

  @override
  String get groupRequestNoOffersTitle => 'Henüz teklif yok';

  @override
  String get groupRequestNoOffersDescription =>
      'Teklifler geldiğinde burada görünecek.';

  @override
  String get groupRequestBusinessFallback => 'İşletme';

  @override
  String get groupRequestTopContributorBadge => 'Grubu en iyi besleyen';

  @override
  String groupRequestOfferPriceLabel(String price) {
    return 'Teklif: $price';
  }

  @override
  String get groupRequestUndoVoteAction => 'Oyunu geri al';

  @override
  String get groupRequestVoteAction => 'Oy ver';

  @override
  String get groupRequestProcessing => 'İşleniyor...';

  @override
  String get groupRequestAcceptOfferAction => 'Teklifi kabul et';

  @override
  String groupRequestVotesLabel(int count) {
    return 'Oy: $count';
  }

  @override
  String get groupRequestSearchMinChars => 'En az 2 karakter yaz';

  @override
  String get groupRequestBusinessAndPriceRequired => 'İşletme ve fiyat gerekli';

  @override
  String get groupRequestSuggestionAdded => 'Öneri eklendi';

  @override
  String get groupRequestSearchBusinessLabel => 'İşletme ara';

  @override
  String get groupRequestSuggestIfMissing => 'İşletme yoksa öner';

  @override
  String get groupRequestTryDifferentName => 'Farklı bir isim deneyin.';

  @override
  String get groupRequestOfferTotalPriceLabel => 'Teklif toplam fiyat (TL)';

  @override
  String get groupRequestNoteLabel => 'Not';

  @override
  String get groupRequestChangeAction => 'Değiştir';

  @override
  String groupRequestAcceptedSummary(String price) {
    return 'Sonuç seçildi. Toplam: $price';
  }

  @override
  String get groupRequestCopyResultAction => 'Sonuç kopyala';

  @override
  String get heroesPageTitle => 'Kahramanlar';

  @override
  String get heroesPageSubtitle => 'Askıya yemek bırakanlar';

  @override
  String get heroesPageEmpty => 'Henüz kahraman yok.';

  @override
  String get heroesPageUserFallback => 'Kullanıcı';

  @override
  String heroesPageDonatedMealCount(int count) {
    return '$count askıda yemek';
  }

  @override
  String get verifyPriceIsCorrectQuestion => 'Fiyat doğru mu?';

  @override
  String get verifyPriceCorrectAction => 'Doğru';

  @override
  String get verifyPriceIncorrectAction => 'Yanlış';

  @override
  String get verifyPriceCorrectPriceLabel => 'Doğru fiyat (TL)';

  @override
  String get verifyPriceCorrectPriceHint => 'Örn: 245,50';

  @override
  String get verifyPriceChooseCorrectnessFirst => 'Önce doğru/yanlış seçin.';

  @override
  String get verifyPriceEnterValidPrice => 'Geçerli bir fiyat girin.';

  @override
  String menuItemCalories(int calories) {
    return '$calories kcal';
  }

  @override
  String get menuItemAutoApprovedMessage =>
      'Fiyat otomatik onaylandı ve menü güncellendi.';

  @override
  String menuItemPendingCountMessage(int count) {
    return 'Önerin alındı. Bu ürün için $count öneri sırada.';
  }

  @override
  String get menuItemPendingSingleMessage => 'Önerin alındı, onay bekliyor.';

  @override
  String get menuItemOnsiteVerifiedPrioritizedMessage =>
      'Teşekkürler. Mekandan doğrulama sinyali alındı, önerin önceliklendirildi.';

  @override
  String get menuPhotoWarningDark => 'karanlık';

  @override
  String get menuPhotoWarningBlurry => 'bulanık';

  @override
  String get menuContributionLevelLabel => 'Katkı Seviyesi';

  @override
  String get menuScoreUpdated => 'Puanın güncellendi';

  @override
  String menuLevel(int level) {
    return 'Seviye $level';
  }

  @override
  String menuXpValue(int xp) {
    return '$xp XP';
  }

  @override
  String menuSelectedVariantLabel(String label, String price) {
    return 'Seçili varyant: $label ($price)';
  }

  @override
  String menuPriceHistoryCurrent(String current, String source) {
    return '$current > $source';
  }

  @override
  String menuPriceHistoryTransition(
    String previous,
    String current,
    String source,
  ) {
    return '$previous > $current > $source';
  }

  @override
  String menuPriceHistoryMeta(String relative, String date, String delta) {
    return '$relative • $date$delta';
  }

  @override
  String get inboxTitle => 'Bildirim Kutusu';

  @override
  String get inboxMarkAllRead => 'Tümünü okundu işaretle';

  @override
  String get inboxEmptyTitle => 'Bildirim yok';

  @override
  String get inboxEmptyDescription =>
      'Fiyat önerisi, claim, rapor ve yorum cevabı bildirimleri burada görünecek.';

  @override
  String inboxXpGain(int xp) {
    return '+$xp XP';
  }

  @override
  String inboxNewLevel(int level) {
    return 'Yeni seviye: $level';
  }

  @override
  String inboxLevel(int level) {
    return 'Seviye: $level';
  }

  @override
  String get inboxNow => 'Şimdi';

  @override
  String get inboxReengagementTitle => 'Seni özledik';

  @override
  String get inboxReengagementSubtitle => 'Yakındaki yeni menülere göz at.';

  @override
  String get inboxRecentBusinessClosedTitle =>
      'Son baktığın işletme kapandı görünüyor';

  @override
  String get inboxRecentBusinessPriceChangedTitle =>
      'Son baktığın yerde fiyat değişti';

  @override
  String get inboxRecentBusinessNearbyTitle => 'Son baktığın yer yakında';

  @override
  String get inboxRecentBusinessTitle => 'Son baktığın yer';

  @override
  String get inboxRecentBusinessNearbyReason =>
      'Sana yakın olduğu için öne alındı';

  @override
  String get inboxFavoritesPriceChangedTitle => 'Favorilerinde fiyat değişti';

  @override
  String inboxFavoritesPriceChangedSubtitle(String name, int count) {
    return '$name • Son $count doğrulama';
  }

  @override
  String get inboxDailyTaskTitle => 'Sana uygun bugünün görevi';

  @override
  String get inboxSegmentPriceHunter =>
      'Bugün 1 fiyat doğrula; güven skorun daha hızlı artsın.';

  @override
  String get inboxSegmentPhotoProof => 'Bugün 1 net menü/fotoğraf kanıtı ekle.';

  @override
  String get inboxSegmentExplorer =>
      'Bugün yeni bir mekan aç ve fiyat durumunu kontrol et.';

  @override
  String get inboxSegmentSilentQuality =>
      'Sessiz kalite katkın güçlü, doğru veriyi sürdür.';

  @override
  String get inboxSegmentDefault =>
      'Bugün küçük bir katkıyla grafiğini güçlendir.';

  @override
  String inboxAlertPriceUp(String pct) {
    return 'Fiyat %$pct çıktığında';
  }

  @override
  String inboxAlertPriceDown(String pct) {
    return 'Fiyat %$pct düştü';
  }

  @override
  String inboxAlertCheaperNow(String pct) {
    return 'Şuan %$pct daha ucuz';
  }

  @override
  String get inboxAlertAboveDistrictAverage =>
      'Bu semtte ortalamanın üstüne çıktığında';

  @override
  String get inboxAlertBelowDistrictAverage =>
      'Bu semtte ortalamanın altına indi';

  @override
  String get inboxAlertTriggered => 'Fiyat alarmı tetiklendi';

  @override
  String get inboxBusinessClosedArchived => 'İşletme kapandı (arşiv).';

  @override
  String get inboxBusinessMoved => 'İşletme taşındı.';

  @override
  String get inboxBusinessTemporarilyClosed => 'İşletme geçici kapalı.';

  @override
  String get inboxBusinessStatusUpdated => 'Durum güncellendi';

  @override
  String get priceAlertSheetTitle => 'Fiyat alarmı oluşturma';

  @override
  String get priceAlertSheetQueryLabel => 'Ürün veya arama metni';

  @override
  String get priceAlertSheetMaxPriceLabel => 'Maksimum fiyat (TL)';

  @override
  String get priceAlertSheetCategoryLabel => 'Kategori';

  @override
  String get priceAlertSheetValidationError =>
      'Arama metni ve geçerli bir fiyat girin.';

  @override
  String get priceAlertSheetSaved => 'Fiyat alarmı kaydedildi.';

  @override
  String get achievementStatusUnlocked => 'Durum: Açık';

  @override
  String get achievementStatusLocked => 'Durum: Kilitli';

  @override
  String get profileGuestUser => 'Misafir';

  @override
  String get profileIdentitySupportMessage =>
      'Topluluğa katkılı yaparak profilini güçlendirebilirsin.';

  @override
  String get profileAlertsTab => 'Alarmlar';

  @override
  String get profileFeedTab => 'Akış';

  @override
  String get profileLoginToSeeContributions =>
      'Katkılarını ve istatistiklerini görmek için giriş yap.';

  @override
  String get profileCreatorBadgeTitle => 'İçerik üretici rozeti';

  @override
  String get profileCreatorBadgeEnabled =>
      'Profilin içerik üretici olarak görünüyor.';

  @override
  String get profileCreatorBadgeDisabled =>
      'İstersen içerik üretici rozetini açabilirsin.';

  @override
  String get profileAddSocialLinkTitle => 'Sosyal bağlantı ekle';

  @override
  String get linkLabel => 'Bağlantı';

  @override
  String get profileSocialLinksHint => 'YouTube / Instagram / Facebook';

  @override
  String get profileSocialSaveComingSoon =>
      'Sosyal bağlantı kaydetme özelliği yakında.';

  @override
  String get profileSocialSaved => 'Sosyal bağlantı kaydedildi.';

  @override
  String get profileSocialSaveError => 'Kaydedilemedi. Lütfen tekrar deneyin.';

  @override
  String get profileStatsTitle => 'Profil istatistikleri';

  @override
  String get profileCommunityTrustTitle => 'Topluluk güveni';

  @override
  String get profileCalculating => 'Hesaplanıyor...';

  @override
  String profileTrustScorePercent(int score) {
    return 'Topluluk güveni: %$score';
  }

  @override
  String profileLevelXp(int level, int xp) {
    return 'Seviye $level • Toplam $xp XP';
  }

  @override
  String get profileMyAchievementsTitle => 'Başarı rozetlerim';

  @override
  String get profileNoAchievementYet => 'Henüz rozet kazanmadın.';

  @override
  String get profileAlertsLoginRequired => 'Alarmları görmek için giriş yap.';

  @override
  String get profileAlertsEmpty => 'Henüz alarm bildirimi yok.';

  @override
  String get profileFeedLoginRequired => 'Akışı görmek için giriş yap.';

  @override
  String get profileFeedEmpty => 'Akışta henüz içerik yok.';

  @override
  String get profileFeedEventPriceVerified => 'Fiyat doğrulandı';

  @override
  String get profileFeedEventMenuUpdated => 'Menü güncellendi';

  @override
  String get profileFeedEventSponsored => 'Sponsorlu güncelleme';

  @override
  String get profileDailyTaskTitle => 'Bugünün görevi';

  @override
  String get profileDailyTaskCompleted => 'Tamamlandı';

  @override
  String get profileSegmentHintPriceHunter =>
      'Fiyat doğrulama tarafında güçlüsün; bugün tek bir ürün doğrulaması yeterli.';

  @override
  String get profileSegmentHintPhotoProof =>
      'Kanıt odaklı gidiyorsun; net bir menü fotoğrafı etkiyi artırır.';

  @override
  String get profileSegmentHintExplorer =>
      'Keşif odaklısın; yeni bir işletmeyi kontrol etmek görevi hızlandırır.';

  @override
  String get profileSegmentHintDefault =>
      'Küçük ama doğru katkılar güven grafiğini en hızlı büyütür.';

  @override
  String get profileStatReviews => 'Yorum';

  @override
  String get profileStatHelpfulVotes => 'Faydalı oy';

  @override
  String get profileStatFavorites => 'Favori';

  @override
  String get profileStatContributions => 'Katkı';

  @override
  String get profileStatVisits => 'Ziyaret';

  @override
  String get profileLatestAchievementTitle => 'Son kazanılan başarı';

  @override
  String profileAlertCurrentPrice(String price) {
    return 'Güncel fiyat: $price TL';
  }

  @override
  String profileAlertPriceChanged(String previous, String current) {
    return 'Fiyat değişti: $previous → $current TL';
  }

  @override
  String get profileSegmentPriceHunter => 'Fiyat avcısı';

  @override
  String get profileSegmentExplorer => 'Keşif';

  @override
  String get profileSegmentPhotoProof => 'Fotoğraf kanıtı';

  @override
  String get profileSegmentBalanced => 'Dengeli';

  @override
  String get profileMoatSignalsTitle => 'Destek sinyalleri';

  @override
  String get profileSignalTrust => 'Güven';

  @override
  String get profileSignalAccuracy => 'Doğruluk';

  @override
  String get profileSignalSegment => 'Katkı stili';

  @override
  String get profileSignalSilentQuality => 'Kalite serisi';

  @override
  String get profileSignalApprovalRate => 'Onay oranı';

  @override
  String get profileSupportSignalsSummary =>
      'Bu sinyaller topluluk güvenini besler; ayrı ana skorlar değildir.';

  @override
  String profileMoatTrustedRejectedSpam(int trusted, int rejected, int spam) {
    return 'Güvenilen katkı: $trusted • Reddedilen: $rejected • Spam sinyali: $spam';
  }

  @override
  String profileMoatBehaviorSummary(int price, int discovery, int photo) {
    return 'Davranış: fiyat $price, keşif $discovery, fotoğraf $photo';
  }

  @override
  String get profileMoatSilentQualityHint =>
      'Kalite serin güçlü; az ama doğru katkıların öne çıkıyor.';

  @override
  String get businessReviewsCommunityExperiences => 'Topluluğun deneyimleri';

  @override
  String get businessReviewsOwnerCanModerate =>
      'İşletme sahibi uygun olmayan yorumları yönetebilir.';

  @override
  String get businessReviewsOwnersCanOnlyReply =>
      'İşletme sahipleri yalnızca yorumlara cevap verebilir.';

  @override
  String get sortNewest => 'En yeni';

  @override
  String get sortMostHelpful => 'En faydalı';

  @override
  String get sortVerified => 'Doğrulanmış';

  @override
  String businessReviewsQualityLabel(String score) {
    return 'Kalite skoru: $score';
  }

  @override
  String helpfulCount(int count) {
    return 'Faydalı ($count)';
  }

  @override
  String get businessReviewsEmpty => 'Henüz yorum yok.';

  @override
  String get reviewCreateRatingLabel => 'Puan';

  @override
  String get reviewCreateOptionalTitleLabel => 'Başlık (isteğe bağlı)';

  @override
  String get reviewCreateContentRequired => 'Yorum boş olamaz.';

  @override
  String get reviewCreateSubmitted => 'Yorum gönderildi.';

  @override
  String get reviewCreateErrorNewAccountRateLimited =>
      'Yeni hesaplar için günlük yorum limiti doldu.';

  @override
  String get reviewCreateErrorSameBusinessCooldown =>
      'Aynı işletme için kısa sürede tekrar yorum gönderemezsin.';

  @override
  String get reviewCreateErrorContainsLinkOrPhone =>
      'Yorumda link veya telefon bilgisi paylaşılamaz.';

  @override
  String get reviewCreateErrorContainsProfanity =>
      'Yorumda uygunsuz ifade var.';

  @override
  String get reviewCreateErrorEmojiSpam => 'Yorumda çok fazla emoji var.';

  @override
  String get quality => 'Kalite';

  @override
  String get smartFeedEmptyTitle => 'Henüz akış yok';

  @override
  String get smartFeedEmptyDescription =>
      'Filtreleri gevşetebilir ya da ilk katkıyı sen ekleyebilirsin.';

  @override
  String get smartFeedCurationTitle => 'Kürasyon';

  @override
  String get smartFeedCategoriesLabel => 'Kategoriler';

  @override
  String get smartFeedScenarioLabel => 'Senaryo';

  @override
  String smartFeedBudgetMax(String amount) {
    return 'En fazla â‚º$amount';
  }

  @override
  String get smartFeedUnlimited => 'Sınırsız';

  @override
  String smartFeedPreferenceHint(String label) {
    return 'Tercih: $label';
  }

  @override
  String smartFeedScenarioHint(String label) {
    return 'Senaryo: $label';
  }

  @override
  String get smartFeedContextDefault =>
      'Bugünün akışını senin ritmine göre hazırlıyoruz.';

  @override
  String get smartFeedCategoryMeyhane => 'Meyhane';

  @override
  String get smartFeedCategoryAffordable => 'Uygun fiyatlı';

  @override
  String get smartFeedBundleStudentFriendly => 'Öğrenci dostu';

  @override
  String get smartFeedBundleFirstDate => 'İlk randevu';

  @override
  String get smartFeedBundleNightSoup => 'Gece çorbası';

  @override
  String smartFeedMinutesAgo(int count) {
    return '$count dk önce';
  }

  @override
  String smartFeedHoursAgo(int count) {
    return '$count saat önce';
  }

  @override
  String smartFeedDaysAgo(int count) {
    return '$count gün önce';
  }

  @override
  String get smartFeedEventMenu => 'Menü';

  @override
  String get smartFeedEventPrice => 'Fiyat';

  @override
  String get smartFeedEventPhoto => 'Fotoğraf';

  @override
  String get smartFeedEventDaily => 'Günlük';

  @override
  String get smartFeedEventSponsor => 'Sponsor';

  @override
  String get smartFeedFallbackPriceChanged => 'Fiyat güncellendi';

  @override
  String get smartFeedFallbackPhotoAdded => 'Yeni fotoğraf eklendi';

  @override
  String get smartFeedFallbackDailyMenu => 'Günün menüsü';

  @override
  String get smartFeedFallbackNewContent => 'Yeni içerik';

  @override
  String get smartFeedCtaGoToMenu => 'Menüye git';

  @override
  String get smartFeedCtaOpenItem => 'Ürünü aç';

  @override
  String get smartFeedCtaViewPhoto => 'Fotoğrafa bak';

  @override
  String get smartFeedCtaGoToBusiness => 'İşletmeye git';

  @override
  String smartFeedNearbyKm(String km) {
    return 'Yakınında $km km';
  }

  @override
  String get smartFeedReasonCategoryMatch => 'Sana uygun kategori';

  @override
  String get smartFeedReasonScenarioMatch => 'Senin senaryon';

  @override
  String get smartFeedReasonSimilarUsers => 'Benzer kullanıcılar seviyor';

  @override
  String get smartFeedDayWeekend => 'Hafta sonu';

  @override
  String get smartFeedDayWeekday => 'Hafta içi';

  @override
  String get smartFeedTimeMorning => 'Sabah';

  @override
  String get smartFeedTimeNoon => 'Öğle';

  @override
  String get smartFeedTimeEvening => 'Akşam';

  @override
  String get smartFeedTimeNight => 'Gece';

  @override
  String get suggestBusinessSubmitDialogTitle => 'Önerin alındı mı?';

  @override
  String suggestBusinessSubmitDialogContent(String code) {
    return 'Teşekkürler! İnceleme sonucunda işletme yayına alınacak.\n\nTakip Kodu: $code';
  }

  @override
  String get ok => 'Tamam';

  @override
  String get suggestBusinessPageTitle => 'İşletme Ekle';

  @override
  String get suggestBusinessPageSubtitle =>
      'Bulduğun işletmeyi ekle, topluluğa katkı yap. İnceleme sonucunda yayınlarız.';

  @override
  String get suggestBusinessNameLabel => 'İşletme adı';

  @override
  String get requiredField => 'Zorunlu';

  @override
  String get suggestBusinessCategoryLabel => 'Kategori';

  @override
  String get suggestBusinessAddressLabel => 'Adres';

  @override
  String get suggestBusinessPhoneLabel => 'Telefon';

  @override
  String get suggestBusinessWebsiteLabel => 'Web sitesi';

  @override
  String get suggestBusinessDuplicateTitle => 'Bu işletme zaten var olabilir';

  @override
  String get suggestBusinessDuplicateFound =>
      'Arama sonucunda benzer işletmeler bulundu:';

  @override
  String get suggestBusinessDuplicateConfirm =>
      'Yine de yeni öneriyi göndermek istiyor musun?';

  @override
  String get suggestBusinessSendAnyway => 'Yine de Gönder';

  @override
  String get suggestBusinessOpenAction => 'Aç';

  @override
  String get copy => 'Kopyala';

  @override
  String get topBusinessesNotEnoughData => 'Henüz yeterli veri yok.';

  @override
  String get topBusinessesBadgeMonth => 'Ay';

  @override
  String get topBusinessesBadgeWeek => 'Hafta';

  @override
  String get suspendedMealsMyClaimsTitle => 'Askıda Yemeklerim';

  @override
  String get suspendedMealsStatusCodeReady => 'Kod hazır';

  @override
  String get suspendedMealsStatusFulfilled => 'Teslim alındı';

  @override
  String get suspendedMealsNoRecords => 'Kayıt yok.';

  @override
  String get suspendedMealsDeliveryCode => 'Teslim kodu';

  @override
  String get suspendedMealsCodeCopied => 'Kod kopyalandı';

  @override
  String get suspendedMealsCodeHint => 'Restorana gidip bu kodu söyle.';

  @override
  String get suspendedMealsPendingReview => 'İnceleniyor';

  @override
  String suspendedMealsMonthsAgo(int count) {
    return '$count ay önce';
  }

  @override
  String get tasteTwinTitle => 'Damak Tadı İkizi';

  @override
  String get tasteTwinLoginRequired =>
      'Bu sayfayı görmek için giriş yapmalısın.';

  @override
  String get tasteTwinSubtitle => 'Puanlamalarına göre sana benzeyen kişiler';

  @override
  String get tasteTwinNoMatches => 'Henüz eşleşme yok.';

  @override
  String tasteTwinMatchSummary(int similarity, int places) {
    return '%$similarity uyum • Ortak $places yer';
  }

  @override
  String get tasteTwinSignalHint => 'Yorum + menü sinyali';

  @override
  String get tasteTwinViewSuggestions => 'Önerileri gör';

  @override
  String tasteTwinRecommendationsTitle(String name) {
    return '$name önerileri';
  }

  @override
  String get tasteTwinFollowGourmet => 'Bu gurmeyi takip et';

  @override
  String get tasteTwinNoSuggestionsYet => 'Şimdilik öneri yok.';

  @override
  String get tasteTwinWhyMatchedTitle => 'Neden eşleştiniz?';

  @override
  String get tasteTwinReviewOverlapTitle => 'Yorum ortaklığı';

  @override
  String get tasteTwinNoSampleYet => 'Henüz örnek yok.';

  @override
  String get tasteTwinMenuSignalOverlapTitle => 'Menü sinyali ortaklığı';

  @override
  String get tasteTwinMenuSignalOverlapHint =>
      'Fiyat teyidi / fotoğraf beğenisi / fotoğraf ekleme sinyalleri';

  @override
  String get tasteTwinDivergenceTitle => 'Burada anlaşılmadınız :)';

  @override
  String tasteTwinRatingComparison(int myRating, int otherRating) {
    return 'Sen: $myRating • O: $otherRating';
  }

  @override
  String tasteTwinYouAt(String value) {
    return 'Sen $value';
  }

  @override
  String tasteTwinSignalComparison(int mySignal, int otherSignal) {
    return 'Sen: +$mySignal • O: +$otherSignal';
  }

  @override
  String tasteTwinMatchRated(int rating) {
    return 'Eşleşmen $rating puan verdi';
  }

  @override
  String tasteTwinRatedAt(String when, String text) {
    return '$when $text';
  }

  @override
  String tasteTwinDebugReviewAndSignal(int review, int signal) {
    return 'Yorum $review% + sinyal $signal%';
  }

  @override
  String tasteTwinDebugReviewOnly(int review) {
    return 'Yorum $review%';
  }

  @override
  String tasteTwinDebugSignalOnly(int signal) {
    return 'Sinyal $signal%';
  }

  @override
  String get tasteTwinTodayLower => 'bugün';

  @override
  String get tasteTwinYesterdayLower => 'dün';

  @override
  String get use => 'Kullan';

  @override
  String get quickLoginTitle => 'Devam etmek için giriş yap';

  @override
  String get quickLoginDescription =>
      'Bu işlem için hesap gerekiyor. Giriş yapabilir veya Şimdi geçebilirsin.';

  @override
  String get quickLoginAction => 'Hızlı giriş';

  @override
  String get statusBadgeVerified => 'Doğrulandı';

  @override
  String get statusBadgePending => 'Beklemede';

  @override
  String get statusBadgeOutdated => 'Güncel değil';

  @override
  String get locationPickerManualHint =>
      'Manuel seçimde il/ilçe bazlı arama yapılır. Yakınlardaki kalite için yarıçap (5/10/20 km) ve konum izni daha iyi sonuç verir.';

  @override
  String get locationPickerUseAuto => 'Otomatik konumu kullan';

  @override
  String get locationPickerMakeDefault => 'Varsayılan yap';

  @override
  String get locationPickerMakeDefaultHint =>
      'Seçtiğin konum bir sonraki açılışta da kullanılsın.';

  @override
  String get locationPickerRecent => 'Son seçilenler';

  @override
  String get locationPickerSearchDistrict => 'İlçe ara';

  @override
  String get locationPickerPopularDistricts => 'Popüler ilçeler';

  @override
  String locationPickerBusinessCount(String city, int count) {
    return '$city • $count işletme';
  }

  @override
  String get legalPageTitle => 'Yasal ve Güven';

  @override
  String get legalKvkkSectionTitle => 'KVKK / GDPR';

  @override
  String get legalKvkkIntro =>
      'Yeedoy kişisel verileri yalnızca hizmeti sunmak için işler. Açık rızası gerektiren işlemler için onay alınır, talep halinde veriler silinir veya taşınabilir şekilde paylaşılr.';

  @override
  String get legalKvkkCategoriesAndRights =>
      'Veri kategorileri: profil, konum, cihaz bilgisi, kullanım analitiği. Haklar: erişim, düzeltme, silme, itiraz, taşınabilirlik.';

  @override
  String get legalPrivacyPolicy => 'Gizlilik Politikası';

  @override
  String get legalKvkkText => 'KVKK Metni';

  @override
  String get legalGdprText => 'GDPR Metni';

  @override
  String get legalApplicationByEmail => 'Başvuru: e-posta ile talep oluştur.';

  @override
  String get legalCopyrightSectionTitle => 'Foto Telif Bildirimi';

  @override
  String get legalCopyrightIntro =>
      'Menü ve mekan fotoğrafları telif hakkına tabi olabilir. İhlal gördüğünde Bildir > Telif ile iletebilirsin.';

  @override
  String get legalCopyrightDetails =>
      'Telif bildirimi için içerik bağlantısı, kanıt ve kısa açıklama yeterlidir. Doğrulanan ihlaller içerikten kaldırılır.';

  @override
  String get legalCopyrightPolicy => 'Telif Politikası';

  @override
  String get legalOwnershipAppealSectionTitle => 'İşletme Sahipliği İtirazı';

  @override
  String get legalOwnershipAppealIntro =>
      'Sahiplik talebi reddedildiyse itiraz edebilirsin. Belgelerin tekrar incelenir.';

  @override
  String get legalOwnershipAppealRequiredInfo =>
      'İtiraz için gerekli bilgiler:';

  @override
  String get legalOwnershipAppealRequiredList =>
      '• İşyeri ünvanı ve vergi/ruhsat bilgisi\n• Yetkilendirme belgesi\n• İletişim telefonu';

  @override
  String get legalSendAppealEmail => 'İtiraz e-postası gönder';

  @override
  String get legalProductPrinciplesSectionTitle => 'Ürün İlkeleri';

  @override
  String get legalDontsTitle => 'Yapılmaması gerekenler:';

  @override
  String get legalDontsList =>
      '• Herkese her şeyi açmak\n• Sponsorlu içeriği gizlemek\n• Owner hesaba yorum silme yetkisi vermek\n• Büyüme için kalite eşeğini gevşetmek';

  @override
  String legalPolicySummary(
    String requireSponsoredLabel,
    String minSponsoredTrust,
    String ownerCanDeleteReviews,
  ) {
    return 'Politika: sponsor etiketi zorunlu=$requireSponsoredLabel, minimum sponsor güven=$minSponsoredTrust, owner yorum silme=$ownerCanDeleteReviews.';
  }

  @override
  String get legalFooter =>
      'Güncel politika metinleri ve detaylar web sitesinde yayımlanır.';

  @override
  String topBusinessReviews(int count) {
    return 'Yorum: $count';
  }

  @override
  String get reportRateLimitBusiness =>
      'Bu işletme için bugün zaten bildirim gönderdin.';

  @override
  String get reportRateLimitReview =>
      'Bu yorum için son 24 saatte zaten bildirim gönderdin.';

  @override
  String get reportRateLimitPhoto =>
      'Bu fotoğraf için son 24 saatte zaten bildirim gönderdin.';

  @override
  String get reportReasonSpam => 'Spam / reklam';

  @override
  String get reportReasonAbuse => 'Hakaret / uygunsuz';

  @override
  String get reportReasonWrongInfo => 'Yanlış bilgi';

  @override
  String get reportReasonCopyright => 'Telif ihlali';

  @override
  String get reportReasonIllegal => 'Yasa dışı';

  @override
  String get reportReasonWrongImage => 'Yanlış görsel';

  @override
  String get reportReasonClosed => 'İşletme kapandı';

  @override
  String get reportReasonMoved => 'Taşındı';

  @override
  String get reportReasonWrongPrice => 'Fiyat yanlış';

  @override
  String get reportBusinessHint =>
      'Çok sayıda yanlış bilgi bildirimi görünürliği düşürür. İşletme sahibi doğruladıktan sonra tekrar yükselir.';

  @override
  String get reportReasonLabel => 'Sebep';

  @override
  String get reportCopyrightUrlLabel => 'İhlal URL (fotoğraf bağlantısı)';

  @override
  String get reportCopyrightOwnerLabel => 'Hak sahibi adı (opsiyonel)';

  @override
  String get reportCopyrightEmailLabel => 'Hak sahibi e-posta (opsiyonel)';

  @override
  String get reportDetailsLabel => 'Detaylar (opsiyonel)';

  @override
  String get reportSubmittedThanks => 'Teşekkürler, incelenecek.';

  @override
  String get reportCopyrightUrlPrefix => 'İhlal URL';

  @override
  String get reportCopyrightOwnerPrefix => 'Hak sahibi';

  @override
  String get reportCopyrightEmailPrefix => 'E-posta';

  @override
  String get unexpectedError => 'Bir hata oluştu.';

  @override
  String get weatherHeadlineRainy => 'Yağmurlu hava';

  @override
  String get weatherHeadlineSnowy => 'Soğuk hava';

  @override
  String get weatherHeadlineHot => 'Sıcak hava';

  @override
  String get weatherHeadlineClear => 'Hava açık';

  @override
  String get weatherHintRainy => 'Sıcak bir şey iyi gider';

  @override
  String get weatherHintSnowy => 'Sıcak çorba iyi gider';

  @override
  String get weatherHintHot => 'Serin bir şey iyi gider';

  @override
  String get weatherHintClear => 'Dış mekan keyifli';

  @override
  String get paste => 'Yapıştır';

  @override
  String get addFirstMenuCta => 'İlk menüyü ekle';

  @override
  String get vatIncluded => 'KDV dahil';

  @override
  String businessViewingNow(int count) {
    return '$count kişi şu an bakıyor';
  }

  @override
  String get delete => 'Sil';

  @override
  String get remove => 'Kaldır';

  @override
  String get create => 'Oluştur';

  @override
  String get required => 'Bu alan zorunludur';

  @override
  String get collabListsTitle => 'Ortak Listelerim';

  @override
  String get collabListCreate => 'Liste Oluştur';

  @override
  String get collabListsEmpty => 'Henüz liste yok';

  @override
  String get collabListsEmptyDesc =>
      'Arkadaşlarınla ortak listeler oluştur ve favori mekanları birlikte oylayın.';

  @override
  String get collabListNameLabel => 'Liste adı';

  @override
  String get collabListDescLabel => 'Açıklama (isteğe bağlı)';

  @override
  String get collabListItemsEmpty => 'Liste boş';

  @override
  String get collabListItemsEmptyDesc =>
      'İşletme sayfasından bu listeye ekleyebilirsin.';

  @override
  String get collabListShare => 'Davet Bağlantısını Kopyala';

  @override
  String get collabListDelete => 'Listeyi Sil';

  @override
  String get collabListDeleteConfirm =>
      'Bu listeyi ve tüm içeriğini silmek istediğinden emin misin?';

  @override
  String get collabListLeave => 'Listeden Ayrıl';

  @override
  String get collabListLeaveConfirm =>
      'Bu listeden ayrılmak istediğinden emin misin?';

  @override
  String get collabListLinkCopied => 'Davet bağlantısı kopyalandı';

  @override
  String get collabListJoining => 'Listeye katılınıyor...';

  @override
  String get collabListInvalidInvite => 'Geçersiz davet bağlantısı.';

  @override
  String get goToMyLists => 'Listelerime Git';
}
