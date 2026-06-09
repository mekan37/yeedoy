-- ============================================================
-- turkey_districts_reference
-- Türkiye 81 il + ~973 ilçe referans tablosu (salt okunur).
-- Normalizasyon migration'ı (20260609000003) bu tabloyu kullanır.
-- RLS gerekmez — tamamen read-only, hassas veri yok.
-- Oluşturulma: 2026-06-09
-- ============================================================

CREATE TABLE IF NOT EXISTS public.turkey_districts_reference (
  id             serial  PRIMARY KEY,
  province_name  text    NOT NULL,
  district_name  text    NOT NULL,
  CONSTRAINT uq_turkey_district UNIQUE (province_name, district_name)
);

CREATE INDEX IF NOT EXISTS idx_turkey_dist_district
  ON public.turkey_districts_reference(lower(district_name));

CREATE INDEX IF NOT EXISTS idx_turkey_dist_province
  ON public.turkey_districts_reference(lower(province_name));

COMMENT ON TABLE public.turkey_districts_reference IS
  'Türkiye 81 il ve ilçe referans tablosu. Salt okunur; normalizasyon ve alias kontrolü için kullanılır.';

-- ── Veri ────────────────────────────────────────────────────

INSERT INTO public.turkey_districts_reference (province_name, district_name) VALUES
-- Adana
('Adana','Aladağ'),('Adana','Ceyhan'),('Adana','Çukurova'),('Adana','Feke'),
('Adana','İmamoğlu'),('Adana','Karaisalı'),('Adana','Karataş'),('Adana','Kozan'),
('Adana','Pozantı'),('Adana','Saimbeyli'),('Adana','Sarıçam'),('Adana','Seyhan'),
('Adana','Tufanbeyli'),('Adana','Yumurtalık'),('Adana','Yüreğir'),
-- Adıyaman
('Adıyaman','Besni'),('Adıyaman','Çelikhan'),('Adıyaman','Gerger'),
('Adıyaman','Gölbaşı'),('Adıyaman','Kahta'),('Adıyaman','Merkez'),
('Adıyaman','Samsat'),('Adıyaman','Sincik'),('Adıyaman','Tut'),
-- Afyonkarahisar
('Afyonkarahisar','Başmakçı'),('Afyonkarahisar','Bayat'),('Afyonkarahisar','Bolvadin'),
('Afyonkarahisar','Çay'),('Afyonkarahisar','Çobanlar'),('Afyonkarahisar','Dazkırı'),
('Afyonkarahisar','Dinar'),('Afyonkarahisar','Emirdağ'),('Afyonkarahisar','Evciler'),
('Afyonkarahisar','Hocalar'),('Afyonkarahisar','İhsaniye'),('Afyonkarahisar','İscehisar'),
('Afyonkarahisar','Kızılören'),('Afyonkarahisar','Merkez'),('Afyonkarahisar','Sandıklı'),
('Afyonkarahisar','Sinanpaşa'),('Afyonkarahisar','Sultandağı'),('Afyonkarahisar','Şuhut'),
-- Ağrı
('Ağrı','Diyadin'),('Ağrı','Doğubayazıt'),('Ağrı','Eleşkirt'),
('Ağrı','Hamur'),('Ağrı','Merkez'),('Ağrı','Patnos'),
('Ağrı','Taşlıçay'),('Ağrı','Tutak'),
-- Aksaray
('Aksaray','Ağaçören'),('Aksaray','Eskil'),('Aksaray','Gülağaç'),
('Aksaray','Güzelyurt'),('Aksaray','Merkez'),('Aksaray','Ortaköy'),
('Aksaray','Sarıyahşi'),('Aksaray','Sultanhanı'),
-- Amasya
('Amasya','Göynücek'),('Amasya','Gümüşhacıköy'),('Amasya','Hamamözü'),
('Amasya','Merkez'),('Amasya','Merzifon'),('Amasya','Suluova'),('Amasya','Taşova'),
-- Ankara
('Ankara','Akyurt'),('Ankara','Altındağ'),('Ankara','Ayaş'),('Ankara','Bala'),
('Ankara','Beypazarı'),('Ankara','Çamlıdere'),('Ankara','Çankaya'),('Ankara','Çubuk'),
('Ankara','Elmadağ'),('Ankara','Etimesgut'),('Ankara','Evren'),('Ankara','Gölbaşı'),
('Ankara','Güdül'),('Ankara','Haymana'),('Ankara','Kalecik'),
('Ankara','Kahramankazan'),('Ankara','Kızılcahamam'),('Ankara','Mamak'),
('Ankara','Nallıhan'),('Ankara','Polatlı'),('Ankara','Pursaklar'),
('Ankara','Sincan'),('Ankara','Şereflikoçhisar'),('Ankara','Yenimahalle'),
-- Antalya
('Antalya','Akseki'),('Antalya','Aksu'),('Antalya','Alanya'),('Antalya','Demre'),
('Antalya','Döşemealtı'),('Antalya','Elmalı'),('Antalya','Finike'),
('Antalya','Gazipaşa'),('Antalya','Gündoğmuş'),('Antalya','İbradı'),
('Antalya','Kaş'),('Antalya','Kemer'),('Antalya','Kepez'),
('Antalya','Konyaaltı'),('Antalya','Korkuteli'),('Antalya','Kumluca'),
('Antalya','Manavgat'),('Antalya','Muratpaşa'),('Antalya','Serik'),
-- Ardahan
('Ardahan','Çıldır'),('Ardahan','Damal'),('Ardahan','Göle'),
('Ardahan','Hanak'),('Ardahan','Merkez'),('Ardahan','Posof'),
-- Artvin
('Artvin','Ardanuç'),('Artvin','Arhavi'),('Artvin','Borçka'),('Artvin','Hopa'),
('Artvin','Kemalpaşa'),('Artvin','Merkez'),('Artvin','Murgul'),
('Artvin','Şavşat'),('Artvin','Yusufeli'),
-- Aydın
('Aydın','Bozdoğan'),('Aydın','Buharkent'),('Aydın','Çine'),('Aydın','Didim'),
('Aydın','Efeler'),('Aydın','Germencik'),('Aydın','İncirliova'),('Aydın','Karacasu'),
('Aydın','Karpuzlu'),('Aydın','Koçarlı'),('Aydın','Köşk'),('Aydın','Kuşadası'),
('Aydın','Kuyucak'),('Aydın','Nazilli'),('Aydın','Söke'),
('Aydın','Sultanhisar'),('Aydın','Yenipazar'),
-- Balıkesir
('Balıkesir','Altıeylül'),('Balıkesir','Ayvalık'),('Balıkesir','Balya'),
('Balıkesir','Bandırma'),('Balıkesir','Bigadiç'),('Balıkesir','Burhaniye'),
('Balıkesir','Dursunbey'),('Balıkesir','Edremit'),('Balıkesir','Erdek'),
('Balıkesir','Gömeç'),('Balıkesir','Gönen'),('Balıkesir','Havran'),
('Balıkesir','İvrindi'),('Balıkesir','Karesi'),('Balıkesir','Kepsut'),
('Balıkesir','Manyas'),('Balıkesir','Marmara'),('Balıkesir','Savaştepe'),
('Balıkesir','Sındırgı'),('Balıkesir','Susurluk'),
-- Bartın
('Bartın','Amasra'),('Bartın','Kurucaşile'),('Bartın','Merkez'),('Bartın','Ulus'),
-- Batman
('Batman','Beşiri'),('Batman','Gercüş'),('Batman','Hasankeyf'),
('Batman','Kozluk'),('Batman','Merkez'),('Batman','Sason'),
-- Bayburt
('Bayburt','Aydıntepe'),('Bayburt','Demirözü'),('Bayburt','Merkez'),
-- Bilecik
('Bilecik','Bozüyük'),('Bilecik','Gölpazarı'),('Bilecik','İnhisar'),
('Bilecik','Merkez'),('Bilecik','Osmaneli'),('Bilecik','Pazaryeri'),
('Bilecik','Söğüt'),('Bilecik','Yenipazar'),
-- Bingöl
('Bingöl','Adaklı'),('Bingöl','Genç'),('Bingöl','Karlıova'),('Bingöl','Kiğı'),
('Bingöl','Merkez'),('Bingöl','Solhan'),('Bingöl','Yayladere'),('Bingöl','Yedisu'),
-- Bitlis
('Bitlis','Adilcevaz'),('Bitlis','Ahlat'),('Bitlis','Güroymak'),
('Bitlis','Hizan'),('Bitlis','Merkez'),('Bitlis','Mutki'),('Bitlis','Tatvan'),
-- Bolu
('Bolu','Dörtdivan'),('Bolu','Gerede'),('Bolu','Göynük'),('Bolu','Kıbrıscık'),
('Bolu','Mengen'),('Bolu','Merkez'),('Bolu','Mudurnu'),
('Bolu','Seben'),('Bolu','Yeniçağa'),
-- Burdur
('Burdur','Ağlasun'),('Burdur','Altınyayla'),('Burdur','Bucak'),
('Burdur','Çavdır'),('Burdur','Çeltikçi'),('Burdur','Gölhisar'),
('Burdur','Karamanlı'),('Burdur','Kemer'),('Burdur','Merkez'),
('Burdur','Tefenni'),('Burdur','Yeşilova'),
-- Bursa
('Bursa','Büyükorhan'),('Bursa','Gemlik'),('Bursa','Gürsu'),('Bursa','Harmancık'),
('Bursa','İnegöl'),('Bursa','İznik'),('Bursa','Karacabey'),('Bursa','Keles'),
('Bursa','Kestel'),('Bursa','Mudanya'),('Bursa','Mustafakemalpaşa'),
('Bursa','Nilüfer'),('Bursa','Orhaneli'),('Bursa','Orhangazi'),
('Bursa','Osmangazi'),('Bursa','Yıldırım'),('Bursa','Yenişehir'),
-- Çanakkale
('Çanakkale','Ayvacık'),('Çanakkale','Bayramiç'),('Çanakkale','Biga'),
('Çanakkale','Bozcaada'),('Çanakkale','Çan'),('Çanakkale','Eceabat'),
('Çanakkale','Ezine'),('Çanakkale','Gelibolu'),('Çanakkale','Gökçeada'),
('Çanakkale','Lapseki'),('Çanakkale','Merkez'),('Çanakkale','Yenice'),
-- Çankırı
('Çankırı','Atkaracalar'),('Çankırı','Bayramören'),('Çankırı','Çerkeş'),
('Çankırı','Eldivan'),('Çankırı','Ilgaz'),('Çankırı','Kızılırmak'),
('Çankırı','Korgun'),('Çankırı','Kurşunlu'),('Çankırı','Merkez'),
('Çankırı','Orta'),('Çankırı','Şabanözü'),('Çankırı','Yapraklı'),
-- Çorum
('Çorum','Alaca'),('Çorum','Bayat'),('Çorum','Boğazkale'),('Çorum','Dodurga'),
('Çorum','İskilip'),('Çorum','Kargı'),('Çorum','Laçin'),('Çorum','Mecitözü'),
('Çorum','Merkez'),('Çorum','Oğuzlar'),('Çorum','Ortaköy'),
('Çorum','Osmancık'),('Çorum','Sungurlu'),('Çorum','Uğurludağ'),
-- Denizli
('Denizli','Acıpayam'),('Denizli','Babadağ'),('Denizli','Baklan'),
('Denizli','Bekilli'),('Denizli','Beyağaç'),('Denizli','Bozkurt'),
('Denizli','Buldan'),('Denizli','Çal'),('Denizli','Çameli'),
('Denizli','Çardak'),('Denizli','Çivril'),('Denizli','Güney'),
('Denizli','Honaz'),('Denizli','Kale'),('Denizli','Merkez'),
('Denizli','Pamukkale'),('Denizli','Sarayköy'),('Denizli','Serinhisar'),
('Denizli','Tavas'),
-- Diyarbakır
('Diyarbakır','Bağlar'),('Diyarbakır','Bismil'),('Diyarbakır','Çermik'),
('Diyarbakır','Çınar'),('Diyarbakır','Çüngüş'),('Diyarbakır','Dicle'),
('Diyarbakır','Eğil'),('Diyarbakır','Ergani'),('Diyarbakır','Hani'),
('Diyarbakır','Hazro'),('Diyarbakır','Kayapınar'),('Diyarbakır','Kocaköy'),
('Diyarbakır','Kulp'),('Diyarbakır','Lice'),('Diyarbakır','Merkez'),
('Diyarbakır','Silvan'),('Diyarbakır','Sur'),('Diyarbakır','Yenişehir'),
-- Düzce
('Düzce','Akçakoca'),('Düzce','Cumayeri'),('Düzce','Çilimli'),
('Düzce','Gölyaka'),('Düzce','Gümüşova'),('Düzce','Kaynaşlı'),
('Düzce','Merkez'),('Düzce','Yığılca'),
-- Edirne
('Edirne','Enez'),('Edirne','Havsa'),('Edirne','İpsala'),('Edirne','Keşan'),
('Edirne','Lalapaşa'),('Edirne','Meriç'),('Edirne','Merkez'),
('Edirne','Süloğlu'),('Edirne','Uzunköprü'),
-- Elazığ
('Elazığ','Ağın'),('Elazığ','Alacakaya'),('Elazığ','Arıcak'),
('Elazığ','Baskil'),('Elazığ','Karakoçan'),('Elazığ','Keban'),
('Elazığ','Kovancılar'),('Elazığ','Maden'),('Elazığ','Merkez'),
('Elazığ','Palu'),('Elazığ','Sivrice'),
-- Erzincan
('Erzincan','Çayırlı'),('Erzincan','İliç'),('Erzincan','Kemah'),
('Erzincan','Kemaliye'),('Erzincan','Merkez'),('Erzincan','Otlukbeli'),
('Erzincan','Refahiye'),('Erzincan','Tercan'),('Erzincan','Üzümlü'),
-- Erzurum
('Erzurum','Aşkale'),('Erzurum','Aziziye'),('Erzurum','Çat'),
('Erzurum','Hınıs'),('Erzurum','Horasan'),('Erzurum','İspir'),
('Erzurum','Karaçoban'),('Erzurum','Karayazı'),('Erzurum','Köprüköy'),
('Erzurum','Merkez'),('Erzurum','Narman'),('Erzurum','Oltu'),
('Erzurum','Olur'),('Erzurum','Palandöken'),('Erzurum','Pasinler'),
('Erzurum','Pazaryolu'),('Erzurum','Şenkaya'),('Erzurum','Tekman'),
('Erzurum','Tortum'),('Erzurum','Uzundere'),('Erzurum','Yakutiye'),
-- Eskişehir
('Eskişehir','Alpu'),('Eskişehir','Beylikova'),('Eskişehir','Çifteler'),
('Eskişehir','Günyüzü'),('Eskişehir','Han'),('Eskişehir','İnönü'),
('Eskişehir','Mahmudiye'),('Eskişehir','Mihalgazi'),('Eskişehir','Mihallıçcık'),
('Eskişehir','Odunpazarı'),('Eskişehir','Sarıcakaya'),('Eskişehir','Seyitgazi'),
('Eskişehir','Sivrihisar'),('Eskişehir','Tepebaşı'),
-- Gaziantep
('Gaziantep','Araban'),('Gaziantep','İslahiye'),('Gaziantep','Karkamış'),
('Gaziantep','Merkez'),('Gaziantep','Nizip'),('Gaziantep','Nurdağı'),
('Gaziantep','Oğuzeli'),('Gaziantep','Şahinbey'),('Gaziantep','Şehitkamil'),
('Gaziantep','Yavuzeli'),
-- Giresun
('Giresun','Alucra'),('Giresun','Bulancak'),('Giresun','Çamoluk'),
('Giresun','Çanakçı'),('Giresun','Dereli'),('Giresun','Doğankent'),
('Giresun','Espiye'),('Giresun','Eynesil'),('Giresun','Görele'),
('Giresun','Güce'),('Giresun','Keşap'),('Giresun','Merkez'),
('Giresun','Piraziz'),('Giresun','Şebinkarahisar'),
('Giresun','Tirebolu'),('Giresun','Yağlıdere'),
-- Gümüşhane
('Gümüşhane','Kelkit'),('Gümüşhane','Köse'),('Gümüşhane','Kürtün'),
('Gümüşhane','Merkez'),('Gümüşhane','Şiran'),('Gümüşhane','Torul'),
-- Hakkari
('Hakkari','Çukurca'),('Hakkari','Derecik'),('Hakkari','Merkez'),
('Hakkari','Şemdinli'),('Hakkari','Yüksekova'),
-- Hatay
('Hatay','Altınözü'),('Hatay','Antakya'),('Hatay','Arsuz'),
('Hatay','Belen'),('Hatay','Defne'),('Hatay','Dörtyol'),
('Hatay','Erzin'),('Hatay','Hassa'),('Hatay','İskenderun'),
('Hatay','Kırıkhan'),('Hatay','Kumlu'),('Hatay','Merkez'),
('Hatay','Payas'),('Hatay','Reyhanlı'),('Hatay','Samandağ'),
('Hatay','Yayladağı'),
-- Iğdır
('Iğdır','Aralık'),('Iğdır','Karakoyunlu'),('Iğdır','Merkez'),('Iğdır','Tuzluca'),
-- Isparta
('Isparta','Aksu'),('Isparta','Atabey'),('Isparta','Eğirdir'),
('Isparta','Gelendost'),('Isparta','Gönen'),('Isparta','Keçiborlu'),
('Isparta','Merkez'),('Isparta','Senirkent'),('Isparta','Sütçüler'),
('Isparta','Şarkikaraağaç'),('Isparta','Uluborlu'),('Isparta','Yalvaç'),
('Isparta','Yenişarbademli'),
-- İstanbul
('İstanbul','Adalar'),('İstanbul','Arnavutköy'),('İstanbul','Ataşehir'),
('İstanbul','Avcılar'),('İstanbul','Bağcılar'),('İstanbul','Bahçelievler'),
('İstanbul','Bakırköy'),('İstanbul','Başakşehir'),('İstanbul','Bayrampaşa'),
('İstanbul','Beşiktaş'),('İstanbul','Beykoz'),('İstanbul','Beylikdüzü'),
('İstanbul','Beyoğlu'),('İstanbul','Büyükçekmece'),('İstanbul','Çatalca'),
('İstanbul','Çekmeköy'),('İstanbul','Esenler'),('İstanbul','Esenyurt'),
('İstanbul','Eyüpsultan'),('İstanbul','Fatih'),('İstanbul','Gaziosmanpaşa'),
('İstanbul','Güngören'),('İstanbul','Kadıköy'),('İstanbul','Kağıthane'),
('İstanbul','Kartal'),('İstanbul','Küçükçekmece'),('İstanbul','Maltepe'),
('İstanbul','Pendik'),('İstanbul','Sancaktepe'),('İstanbul','Sarıyer'),
('İstanbul','Silivri'),('İstanbul','Sultanbeyli'),('İstanbul','Sultangazi'),
('İstanbul','Şile'),('İstanbul','Şişli'),('İstanbul','Tuzla'),
('İstanbul','Ümraniye'),('İstanbul','Üsküdar'),('İstanbul','Zeytinburnu'),
-- İzmir
('İzmir','Aliağa'),('İzmir','Balçova'),('İzmir','Bayındır'),
('İzmir','Bayraklı'),('İzmir','Bergama'),('İzmir','Beydağ'),
('İzmir','Bornova'),('İzmir','Buca'),('İzmir','Çeşme'),
('İzmir','Çiğli'),('İzmir','Dikili'),('İzmir','Foça'),
('İzmir','Gaziemir'),('İzmir','Güzelbahçe'),('İzmir','Karabağlar'),
('İzmir','Karaburun'),('İzmir','Karşıyaka'),('İzmir','Kemalpaşa'),
('İzmir','Kınık'),('İzmir','Kiraz'),('İzmir','Konak'),
('İzmir','Menderes'),('İzmir','Menemen'),('İzmir','Narlıdere'),
('İzmir','Ödemiş'),('İzmir','Selçuk'),('İzmir','Seferihisar'),
('İzmir','Tire'),('İzmir','Torbalı'),('İzmir','Urla'),
-- Kahramanmaraş
('Kahramanmaraş','Afşin'),('Kahramanmaraş','Andırın'),
('Kahramanmaraş','Çağlayancerit'),('Kahramanmaraş','Dulkadiroğlu'),
('Kahramanmaraş','Ekinözü'),('Kahramanmaraş','Elbistan'),
('Kahramanmaraş','Göksun'),('Kahramanmaraş','Merkez'),
('Kahramanmaraş','Nurhak'),('Kahramanmaraş','Onikişubat'),
('Kahramanmaraş','Pazarcık'),('Kahramanmaraş','Türkoğlu'),
-- Karabük
('Karabük','Eflani'),('Karabük','Eskipazar'),('Karabük','Merkez'),
('Karabük','Ovacık'),('Karabük','Safranbolu'),('Karabük','Yenice'),
-- Karaman
('Karaman','Ayrancı'),('Karaman','Başyayla'),('Karaman','Ermenek'),
('Karaman','Kazımkarabekir'),('Karaman','Merkez'),('Karaman','Sarıveliler'),
-- Kars
('Kars','Akyaka'),('Kars','Arpaçay'),('Kars','Digor'),
('Kars','Kağızman'),('Kars','Merkez'),('Kars','Sarıkamış'),
('Kars','Selim'),('Kars','Susuz'),
-- Kastamonu
('Kastamonu','Abana'),('Kastamonu','Ağlı'),('Kastamonu','Araç'),
('Kastamonu','Azdavay'),('Kastamonu','Bozkurt'),('Kastamonu','Çatalzeytin'),
('Kastamonu','Cide'),('Kastamonu','Daday'),('Kastamonu','Devrekani'),
('Kastamonu','Doğanyurt'),('Kastamonu','Hanönü'),('Kastamonu','İhsangazi'),
('Kastamonu','İnebolu'),('Kastamonu','Küre'),('Kastamonu','Merkez'),
('Kastamonu','Pınarbaşı'),('Kastamonu','Seydiler'),('Kastamonu','Şenpazar'),
('Kastamonu','Taşköprü'),('Kastamonu','Tosya'),
-- Kayseri
('Kayseri','Akkışla'),('Kayseri','Bünyan'),('Kayseri','Develi'),
('Kayseri','Felahiye'),('Kayseri','Hacılar'),('Kayseri','İncesu'),
('Kayseri','Kocasinan'),('Kayseri','Melikgazi'),('Kayseri','Özvatan'),
('Kayseri','Pınarbaşı'),('Kayseri','Sarıoğlan'),('Kayseri','Sarız'),
('Kayseri','Talas'),('Kayseri','Tomarza'),('Kayseri','Yahyalı'),
('Kayseri','Yeşilhisar'),
-- Kilis
('Kilis','Elbeyli'),('Kilis','Merkez'),('Kilis','Musabeyli'),('Kilis','Polateli'),
-- Kırıkkale
('Kırıkkale','Bahşili'),('Kırıkkale','Balışeyh'),('Kırıkkale','Çelebi'),
('Kırıkkale','Delice'),('Kırıkkale','Karakeçili'),('Kırıkkale','Keskin'),
('Kırıkkale','Merkez'),('Kırıkkale','Sulakyurt'),('Kırıkkale','Yahşihan'),
-- Kırklareli
('Kırklareli','Babaeski'),('Kırklareli','Demirköy'),('Kırklareli','Kofçaz'),
('Kırklareli','Lüleburgaz'),('Kırklareli','Merkez'),('Kırklareli','Pehlivanköy'),
('Kırklareli','Pınarhisar'),('Kırklareli','Vize'),
-- Kırşehir
('Kırşehir','Akçakent'),('Kırşehir','Akpınar'),('Kırşehir','Boztepe'),
('Kırşehir','Çiçekdağı'),('Kırşehir','Kaman'),('Kırşehir','Merkez'),
('Kırşehir','Mucur'),
-- Kocaeli
('Kocaeli','Başiskele'),('Kocaeli','Çayırova'),('Kocaeli','Darıca'),
('Kocaeli','Derince'),('Kocaeli','Dilovası'),('Kocaeli','Gebze'),
('Kocaeli','Gölcük'),('Kocaeli','İzmit'),('Kocaeli','Kandıra'),
('Kocaeli','Karamürsel'),('Kocaeli','Kartepe'),('Kocaeli','Körfez'),
-- Konya
('Konya','Ahırlı'),('Konya','Akören'),('Konya','Akşehir'),
('Konya','Altınekin'),('Konya','Beyşehir'),('Konya','Bozkır'),
('Konya','Cihanbeyli'),('Konya','Çeltik'),('Konya','Çumra'),
('Konya','Derbent'),('Konya','Derebucak'),('Konya','Doğanhisar'),
('Konya','Emirgazi'),('Konya','Ereğli'),('Konya','Güneysınır'),
('Konya','Hadim'),('Konya','Halkapınar'),('Konya','Hüyük'),
('Konya','Ilgın'),('Konya','Kadınhanı'),('Konya','Karapınar'),
('Konya','Karatay'),('Konya','Kulu'),('Konya','Meram'),
('Konya','Sarayönü'),('Konya','Selçuklu'),('Konya','Seydişehir'),
('Konya','Taşkent'),('Konya','Tuzlukçu'),('Konya','Yalıhüyük'),
('Konya','Yunak'),
-- Kütahya
('Kütahya','Altıntaş'),('Kütahya','Aslanapa'),('Kütahya','Çavdarhisar'),
('Kütahya','Domaniç'),('Kütahya','Dumlupınar'),('Kütahya','Emet'),
('Kütahya','Gediz'),('Kütahya','Hisarcık'),('Kütahya','Merkez'),
('Kütahya','Pazarlar'),('Kütahya','Şaphane'),('Kütahya','Simav'),
('Kütahya','Tavşanlı'),
-- Malatya
('Malatya','Akçadağ'),('Malatya','Arapgir'),('Malatya','Arguvan'),
('Malatya','Battalgazi'),('Malatya','Darende'),('Malatya','Doğanşehir'),
('Malatya','Doğanyol'),('Malatya','Hekimhan'),('Malatya','Kale'),
('Malatya','Kuluncak'),('Malatya','Merkez'),('Malatya','Pütürge'),
('Malatya','Yazıhan'),('Malatya','Yeşilyurt'),
-- Manisa
('Manisa','Ahmetli'),('Manisa','Akhisar'),('Manisa','Alaşehir'),
('Manisa','Demirci'),('Manisa','Gölmarmara'),('Manisa','Gördes'),
('Manisa','Kırkağaç'),('Manisa','Köprübaşı'),('Manisa','Kula'),
('Manisa','Merkez'),('Manisa','Salihli'),('Manisa','Sarıgöl'),
('Manisa','Saruhanlı'),('Manisa','Selendi'),('Manisa','Soma'),
('Manisa','Şehzadeler'),('Manisa','Turgutlu'),('Manisa','Yunusemre'),
-- Mardin
('Mardin','Artuklu'),('Mardin','Dargeçit'),('Mardin','Derik'),
('Mardin','Kızıltepe'),('Mardin','Mazıdağı'),('Mardin','Merkez'),
('Mardin','Midyat'),('Mardin','Nusaybin'),('Mardin','Ömerli'),
('Mardin','Savur'),('Mardin','Yeşilli'),
-- Mersin
('Mersin','Akdeniz'),('Mersin','Anamur'),('Mersin','Aydıncık'),
('Mersin','Bozyazı'),('Mersin','Çamlıyayla'),('Mersin','Erdemli'),
('Mersin','Gülnar'),('Mersin','Mezitli'),('Mersin','Mut'),
('Mersin','Silifke'),('Mersin','Tarsus'),('Mersin','Toroslar'),
('Mersin','Yenişehir'),
-- Muğla
('Muğla','Bodrum'),('Muğla','Dalaman'),('Muğla','Datça'),
('Muğla','Fethiye'),('Muğla','Kavaklıdere'),('Muğla','Köyceğiz'),
('Muğla','Marmaris'),('Muğla','Menteşe'),('Muğla','Milas'),
('Muğla','Ortaca'),('Muğla','Seydikemer'),('Muğla','Ula'),
('Muğla','Yatağan'),
-- Muş
('Muş','Bulanık'),('Muş','Hasköy'),('Muş','Korkut'),
('Muş','Malazgirt'),('Muş','Merkez'),('Muş','Varto'),
-- Nevşehir
('Nevşehir','Acıgöl'),('Nevşehir','Avanos'),('Nevşehir','Derinkuyu'),
('Nevşehir','Gülşehir'),('Nevşehir','Hacıbektaş'),('Nevşehir','Kozaklı'),
('Nevşehir','Merkez'),('Nevşehir','Ürgüp'),
-- Niğde
('Niğde','Altunhisar'),('Niğde','Bor'),('Niğde','Çamardı'),
('Niğde','Çiftlik'),('Niğde','Merkez'),('Niğde','Ulukışla'),
-- Ordu
('Ordu','Akkuş'),('Ordu','Altınordu'),('Ordu','Aybastı'),
('Ordu','Çamaş'),('Ordu','Çatalpınar'),('Ordu','Çaybaşı'),
('Ordu','Fatsa'),('Ordu','Gölköy'),('Ordu','Gülyalı'),
('Ordu','Gürgentepe'),('Ordu','İkizce'),('Ordu','Kabadüz'),
('Ordu','Kabataş'),('Ordu','Korgan'),('Ordu','Kumru'),
('Ordu','Mesudiye'),('Ordu','Perşembe'),('Ordu','Ulubey'),
('Ordu','Ünye'),
-- Osmaniye
('Osmaniye','Bahçe'),('Osmaniye','Düziçi'),('Osmaniye','Hasanbeyli'),
('Osmaniye','Kadirli'),('Osmaniye','Merkez'),('Osmaniye','Sumbas'),
('Osmaniye','Toprakkale'),
-- Rize
('Rize','Ardeşen'),('Rize','Çamlıhemşin'),('Rize','Çayeli'),
('Rize','Derepazarı'),('Rize','Fındıklı'),('Rize','Güneysu'),
('Rize','Hemşin'),('Rize','İkizdere'),('Rize','İyidere'),
('Rize','Kalkandere'),('Rize','Merkez'),('Rize','Pazar'),
-- Sakarya
('Sakarya','Adapazarı'),('Sakarya','Akyazı'),('Sakarya','Arifiye'),
('Sakarya','Erenler'),('Sakarya','Ferizli'),('Sakarya','Geyve'),
('Sakarya','Hendek'),('Sakarya','Karapürçek'),('Sakarya','Karasu'),
('Sakarya','Kaynarca'),('Sakarya','Kocaali'),('Sakarya','Mithatpaşa'),
('Sakarya','Pamukova'),('Sakarya','Sapanca'),('Sakarya','Serdivan'),
('Sakarya','Söğütlü'),('Sakarya','Taraklı'),
-- Samsun
('Samsun','19 Mayıs'),('Samsun','Alaçam'),('Samsun','Asarcık'),
('Samsun','Atakum'),('Samsun','Ayvacık'),('Samsun','Bafra'),
('Samsun','Canik'),('Samsun','Çarşamba'),('Samsun','Havza'),
('Samsun','İlkadım'),('Samsun','Kavak'),('Samsun','Ladik'),
('Samsun','Merkez'),('Samsun','Ondokuzmayıs'),('Samsun','Salıpazarı'),
('Samsun','Tekkeköy'),('Samsun','Terme'),('Samsun','Vezirköprü'),
('Samsun','Yakakent'),
-- Siirt
('Siirt','Baykan'),('Siirt','Eruh'),('Siirt','Kurtalan'),
('Siirt','Merkez'),('Siirt','Pervari'),('Siirt','Şirvan'),('Siirt','Tillo'),
-- Sinop
('Sinop','Ayancık'),('Sinop','Boyabat'),('Sinop','Dikmen'),
('Sinop','Durağan'),('Sinop','Erfelek'),('Sinop','Gerze'),
('Sinop','Merkez'),('Sinop','Saraydüzü'),('Sinop','Türkeli'),
-- Sivas
('Sivas','Akıncılar'),('Sivas','Altınyayla'),('Sivas','Divriği'),
('Sivas','Doğanşar'),('Sivas','Gemerek'),('Sivas','Gölova'),
('Sivas','Gürun'),('Sivas','Hafik'),('Sivas','İmranlı'),
('Sivas','Kangal'),('Sivas','Koyulhisar'),('Sivas','Merkez'),
('Sivas','Suşehri'),('Sivas','Şarkışla'),('Sivas','Ulaş'),
('Sivas','Yıldızeli'),('Sivas','Zara'),
-- Şanlıurfa
('Şanlıurfa','Akçakale'),('Şanlıurfa','Birecik'),('Şanlıurfa','Bozova'),
('Şanlıurfa','Ceylanpınar'),('Şanlıurfa','Eyyübiye'),('Şanlıurfa','Halfeti'),
('Şanlıurfa','Haliliye'),('Şanlıurfa','Harran'),('Şanlıurfa','Hilvan'),
('Şanlıurfa','Karaköprü'),('Şanlıurfa','Merkez'),('Şanlıurfa','Siverek'),
('Şanlıurfa','Suruç'),('Şanlıurfa','Viranşehir'),
-- Şırnak
('Şırnak','Beytüşşebap'),('Şırnak','Cizre'),('Şırnak','Güçlükonak'),
('Şırnak','İdil'),('Şırnak','Merkez'),('Şırnak','Silopi'),
('Şırnak','Uludere'),
-- Tekirdağ
('Tekirdağ','Çerkezköy'),('Tekirdağ','Çorlu'),('Tekirdağ','Ergene'),
('Tekirdağ','Hayrabolu'),('Tekirdağ','Kapaklı'),('Tekirdağ','Malkara'),
('Tekirdağ','Marmara Ereğlisi'),('Tekirdağ','Merkez'),('Tekirdağ','Muratlı'),
('Tekirdağ','Saray'),('Tekirdağ','Süleymanpaşa'),('Tekirdağ','Şarköy'),
-- Tokat
('Tokat','Almus'),('Tokat','Artova'),('Tokat','Başçiftlik'),
('Tokat','Erbaa'),('Tokat','Merkez'),('Tokat','Niksar'),
('Tokat','Pazar'),('Tokat','Reşadiye'),('Tokat','Sulusaray'),
('Tokat','Turhal'),('Tokat','Yeşilyurt'),('Tokat','Zile'),
-- Trabzon
('Trabzon','Akçaabat'),('Trabzon','Araklı'),('Trabzon','Arsin'),
('Trabzon','Beşikdüzü'),('Trabzon','Çarşıbaşı'),('Trabzon','Çaykara'),
('Trabzon','Dernekpazarı'),('Trabzon','Düzköy'),('Trabzon','Hayrat'),
('Trabzon','Köprübaşı'),('Trabzon','Maçka'),('Trabzon','Merkez'),
('Trabzon','Of'),('Trabzon','Ortahisar'),('Trabzon','Şalpazarı'),
('Trabzon','Sürmene'),('Trabzon','Tonya'),('Trabzon','Vakfıkebir'),
('Trabzon','Yomra'),
-- Tunceli
('Tunceli','Çemişgezek'),('Tunceli','Hozat'),('Tunceli','Mazgirt'),
('Tunceli','Merkez'),('Tunceli','Nazimiye'),('Tunceli','Ovacık'),
('Tunceli','Pertek'),('Tunceli','Pülümür'),
-- Uşak
('Uşak','Banaz'),('Uşak','Eşme'),('Uşak','Karahallı'),
('Uşak','Merkez'),('Uşak','Sivaslı'),('Uşak','Ulubey'),
-- Van
('Van','Bahçesaray'),('Van','Başkale'),('Van','Çaldıran'),
('Van','Çatak'),('Van','Edremit'),('Van','Erciş'),
('Van','Gevaş'),('Van','Gürpınar'),('Van','İpekyolu'),
('Van','Merkez'),('Van','Muradiye'),('Van','Özalp'),
('Van','Saray'),('Van','Tuşba'),
-- Yalova
('Yalova','Altınova'),('Yalova','Armutlu'),('Yalova','Çiftlikköy'),
('Yalova','Çınarcık'),('Yalova','Merkez'),('Yalova','Termal'),
-- Yozgat
('Yozgat','Akdağmadeni'),('Yozgat','Aydıncık'),('Yozgat','Boğazlıyan'),
('Yozgat','Çandır'),('Yozgat','Çayıralan'),('Yozgat','Çekerek'),
('Yozgat','Kadışehri'),('Yozgat','Merkez'),('Yozgat','Saraykent'),
('Yozgat','Sarıkaya'),('Yozgat','Şefaatli'),('Yozgat','Sorgun'),
('Yozgat','Yenifakılı'),('Yozgat','Yerköy'),
-- Zonguldak
('Zonguldak','Alaplı'),('Zonguldak','Çaycuma'),('Zonguldak','Devrek'),
('Zonguldak','Ereğli'),('Zonguldak','Gökçebey'),('Zonguldak','Kilimli'),
('Zonguldak','Kozlu'),('Zonguldak','Merkez')
ON CONFLICT (province_name, district_name) DO NOTHING;
