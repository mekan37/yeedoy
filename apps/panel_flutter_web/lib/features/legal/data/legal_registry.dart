import 'dart:collection';

import 'package:flutter/material.dart';

import '../domain/legal_document.dart';

class LegalRegistry {
  const LegalRegistry._();

  static const companyName = '[Şirket Adı]';
  static const companyAddress = '[Adres]';
  static const companyTaxNumber = '[Vergi No]';
  static const legalEmail = '[Hukuki E-posta]';
  static const _version = '2026.03-tr-v1';
  static final DateTime _lastUpdated = DateTime(2026, 3, 10);

  static final List<LegalDocument> documents = List<LegalDocument>.unmodifiable(
    <LegalDocument>[
      _terms,
      _privacy,
      _cookies,
      _community,
      _business,
      _copyright,
      _ai,
      _dmca,
      _dsa,
      _dataSafety,
      _trustSafety,
      _security,
      _lawEnforcement,
      _deleteAccount,
    ],
  );

  static final Map<String, LegalDocument> _documentsBySlug =
      UnmodifiableMapView<String, LegalDocument>(
        <String, LegalDocument>{
          for (final document in documents) document.slug: document,
        },
      );

  static int get count => documents.length;
  static String get currentVersion => _version;
  static DateTime get currentLastUpdated => _lastUpdated;

  static LegalDocument? bySlug(String slug) => _documentsBySlug[slug];
  static bool containsSlug(String slug) => _documentsBySlug.containsKey(slug);

  static LegalSection _contactSection({
    String id = 'iletisim',
    String title = 'İletişim ve Kurumsal Bilgiler',
  }) {
    return LegalSection(
      id: id,
      title: title,
      paragraphs: const <String>[
        'Bu doküman Yeedoy platformunun hukuki ve operasyonel çerçevesini açıklar. Kurumsal bilgiler tescil süreci tamamlanana kadar aşağıdaki placeholder alanlarla yayımlanır ve resmi bilgiler güncellendiğinde yeni sürüm yayınlanır.',
      ],
      bullets: const <String>[
        'Şirket unvanı: [Şirket Adı]',
        'Adres: [Adres]',
        'Vergi numarası: [Vergi No]',
        'Hukuki iletişim: [Hukuki E-posta]',
      ],
    );
  }

  static LegalSection _intermediarySection() {
    return const LegalSection(
      id: 'araci-hizmet',
      title: 'Aracı Hizmet Sağlayıcı Yaklaşımı',
      paragraphs: <String>[
        'Yeedoy; işletmeler, kullanıcılar ve içerik sağlayıcılar tarafından sunulan menü, fiyat, görsel, açıklama, rezervasyon veya bağlantı verilerini bir araya getiren dijital bir platformdur. Platform; içeriklerin kaynağı değildir, içeriklerin güncelliği üzerinde makul denetim uygular ancak her bilginin mutlak doğruluğunu garanti etmez.',
        'Yeedoy; hukuka aykırılık, güvenlik riski, yanıltıcı beyan, spam, telif ihlali, topluluk güvenliğine zarar, platform bütünlüğüne tehdit veya ticari suistimal tespit ettiğinde içerikleri kaldırabilir, görünürlüğünü azaltabilir, erişimi sınırlayabilir veya hesabı askıya alabilir.',
      ],
    );
  }

  static LegalSection _transparencySection() {
    return const LegalSection(
      id: 'seffaflik',
      title: 'Şeffaflık ve Veri İşleme İlkeleri',
      paragraphs: <String>[
        'Yeedoy; hangi veriyi neden işlediğini, hangi taraflarla hangi kapsamda paylaştığını ve hangi sürelerle sakladığını politika metinlerinde açıklar. İşleme amaçları hizmet sunumu, güvenlik, sahtekarlık önleme, mevzuat uyumu, ürün geliştirme ve kullanıcı destek süreçleri ile sınırlıdır.',
        'Gizlilik, güvenlik ve moderasyon kararlarında orantılılık, veri minimizasyonu ve hesap verilebilirlik ilkeleri uygulanır. Kullanıcılar hak taleplerini kayıt altına aldırabilir; başvurular statü takibi yapılabilecek şekilde işlenir.',
      ],
    );
  }

  static LegalSection _dataRightsSection() {
    return const LegalSection(
      id: 'veri-haklari',
      title: 'Veri Hakları ve Başvuru Kanalları',
      paragraphs: <String>[
        'Kullanıcılar; kişisel verilerine erişim, düzeltme, silme, işleme kısıtlama, itiraz, taşınabilirlik ve ilgili mevzuat kapsamında diğer haklarını kullanabilir. Talepler uygulama içi başvuru akışları veya hukuki iletişim kanalı üzerinden alınır.',
        'Hesap silme talepleri, yasal saklama zorunlulukları ve güvenlik/audit kayıtları dikkate alınarak sonuçlandırılır. Vergisel, sözleşmesel, dolandırıcılık önleme veya uyuşmazlık çözümü için gerekli kayıtlar ilgili mevzuat süresince tutulabilir.',
      ],
    );
  }

  static LegalSection _moderationSection() {
    return const LegalSection(
      id: 'moderasyon',
      title: 'Moderasyon ve Kötüye Kullanım Yönetimi',
      paragraphs: <String>[
        'Topluluk güvenliğini korumak için içerik ve hesap davranışları otomatik sinyaller, kullanıcı bildirimleri ve manuel inceleme ile değerlendirilebilir. Moderasyon kararları; içerik görünürlüğünü düşürme, düzeltme isteme, kaldırma, sınırlandırma, geçici askıya alma veya kalıcı kapatma şeklinde olabilir.',
      ],
      bullets: <String>[
        'Spam, bot davranışı, koordineli manipülasyon ve sahte etkileşim yasaktır.',
        'Taciz, ayrımcı söylem, tehdit, yasa dışı ürün/hizmet teşviki ve zararlı yönlendirmeler yasaktır.',
        'İşletme veya menü verisini kasıtlı olarak yanıltıcı göstermek sözleşme ihlalidir.',
      ],
    );
  }

  static LegalSection _aiSection() {
    return const LegalSection(
      id: 'ai-ocr',
      title: 'Yapay Zeka ve OCR Şeffaflığı',
      paragraphs: <String>[
        'Yeedoy; menü fotoğraflarından veri çıkarımı, içerik sınıflandırma, güvenlik sinyali üretimi, kalite kontrol ve destek operasyonları için OCR veya yapay zeka destekli sistemlerden yararlanabilir. Bu araçlar nihai hukuki değerlendirme yerine yardımcı karar desteği sağlar.',
        'Yapay zeka çıktıları hatalı olabilir. Bu nedenle kritik moderasyon, telif, hesap yaptırımı, güvenlik ve hukuki başvurular için gerektiğinde insan incelemesi devreye alınır.',
      ],
    );
  }

  static LegalDocument get _terms => LegalDocument(
    slug: 'terms',
    title: 'Kullanım Şartları',
    description:
        'Platformun kullanım koşulları, kullanıcı sorumlulukları, hesap yönetimi ve hizmet sınırları.',
    version: _version,
    lastUpdated: _lastUpdated,
    icon: Icons.gavel_outlined,
    sections: <LegalSection>[
      _contactSection(),
      _intermediarySection(),
      const LegalSection(
        id: 'hesap-ve-erisim',
        title: 'Hesap, Erişim ve Uygun Kullanım',
        paragraphs: <String>[
          'Platformu kullanırken doğru, güncel ve yetkili olduğunuz bilgileri sağlamanız gerekir. Hesabınız altında gerçekleşen işlemlerden makul ölçüde siz sorumlusunuz; yetkisiz kullanım şüphesinde şifrenizi değiştirmeniz ve destek ekibini bilgilendirmeniz gerekir.',
          'Yeedoy; teknik bakım, güvenlik önlemi, kapasite yönetimi, kötüye kullanım, hukuki yükümlülük veya ürün stratejisi nedeniyle hizmet özelliklerini değiştirebilir, kısmen durdurabilir veya sonlandırabilir.',
        ],
      ),
      const LegalSection(
        id: 'icerik-ve-sorumluluk',
        title: 'İçerik Sorumluluğu ve Kaldırma Yetkisi',
        paragraphs: <String>[
          'Kullanıcılar, işletmeler ve üçüncü taraf kaynaklar tarafından sağlanan menü, fiyat, açıklama, fotoğraf, bağlantı ve diğer içeriklerden bunları yükleyen veya ileten taraf sorumludur. Yeedoy içeriklerin her birini önceden onaylama yükümlülüğü üstlenmez.',
          'Yeedoy; kanuna aykırı, aldatıcı, zararlı, telif hakkını ihlal eden, kişilik hakkını zedeleyen veya platform güvenliğine tehdit oluşturan içerikleri önceden bildirim yapmaksızın kaldırabilir ya da erişimini sınırlandırabilir.',
        ],
      ),
      _moderationSection(),
      const LegalSection(
        id: 'uyusmazlik',
        title: 'Sorumluluk Sınırı ve Uyuşmazlıklar',
        paragraphs: <String>[
          'Yeedoy; açıkça üstlenmediği ölçüde, üçüncü taraf içeriklerinden, işletme-ziyaretçi uyuşmazlıklarından, fiyat değişikliklerinden, stok veya servis farklılıklarından doğan dolaylı zararlardan sorumlu tutulamaz.',
          'Zorunlu tüketici ve elektronik ticaret mevzuatından doğan haklar saklıdır. Uyuşmazlık çözümünde yürürlükteki emredici hukuk kuralları öncelikli olarak uygulanır.',
        ],
      ),
      _dataRightsSection(),
      _aiSection(),
    ],
  );

  static LegalDocument get _privacy => LegalDocument(
    slug: 'privacy',
    title: 'Gizlilik Politikası',
    description:
        'Kişisel veri kategorileri, işleme amaçları, saklama süreleri ve kullanıcı hakları.',
    version: _version,
    lastUpdated: _lastUpdated,
    icon: Icons.privacy_tip_outlined,
    sections: <LegalSection>[
      _contactSection(),
      const LegalSection(
        id: 'islenen-veriler',
        title: 'İşlenen Veri Kategorileri',
        paragraphs: <String>[
          'Yeedoy; hesap bilgileri, profil verileri, cihaz ve oturum bilgileri, kullanım analitiği, konum tercihleri, içerik katkıları, güvenlik logları, destek başvuruları ve hukuki talep kayıtlarını işleyebilir.',
        ],
        bullets: <String>[
          'Kimlik ve iletişim verileri: e-posta, hesap kimliği, profil adı.',
          'Kullanım verileri: sayfa/ekran görüntüleme, tıklama, hata, performans ve güvenlik olayları.',
          'İçerik verileri: menü fotoğrafı, fiyat doğrulaması, yorum, rapor, talep açıklamaları.',
          'Cihaz verileri: uygulama sürümü, işletim sistemi, kullanıcı aracısı, dil ve oturum sinyalleri.',
        ],
      ),
      const LegalSection(
        id: 'isleme-amaclari',
        title: 'İşleme Amaçları ve Hukuki Sebepler',
        paragraphs: <String>[
          'Veriler; hizmeti sağlamak, hesabı doğrulamak, kullanıcı deneyimini kişiselleştirmek, topluluk güvenliğini korumak, kötüye kullanımı önlemek, yasal yükümlülükleri yerine getirmek ve destek taleplerini yönetmek amaçlarıyla işlenir.',
          'Açık rıza gerektiren iletişim, pazarlama veya benzeri tercihler zorunlu sözleşme kabulünden ayrı değerlendirilir ve geri çekilebilir şekilde yönetilir.',
        ],
      ),
      _transparencySection(),
      const LegalSection(
        id: 'saklama-paylasim',
        title: 'Saklama, Paylaşım ve Uluslararası Aktarım',
        paragraphs: <String>[
          'Veriler yalnızca hizmeti yürütmek için gerekli süre boyunca veya ilgili mevzuatın öngördüğü saklama süreleri kadar tutulur. Güvenlik, denetim ve uyuşmazlık çözümü için gerekli kayıtlar sınırlı erişimle korunur.',
          'Bulut altyapısı, analitik, hata izleme, destek ve ödeme/kurumsal süreçlerde yetkili hizmet sağlayıcılarla veri paylaşımı yapılabilir. Bu paylaşımlar sözleşmesel güvenlik yükümlülükleri ve veri minimizasyonu ilkeleriyle sınırlandırılır.',
        ],
      ),
      _dataRightsSection(),
      _aiSection(),
    ],
  );

  static LegalDocument get _cookies => LegalDocument(
    slug: 'cookies',
    title: 'Çerez Politikası',
    description:
        'Web deneyiminde kullanılan çerez türleri, kullanım amaçları ve tercih yönetimi.',
    version: _version,
    lastUpdated: _lastUpdated,
    icon: Icons.cookie_outlined,
    sections: <LegalSection>[
      _contactSection(),
      const LegalSection(
        id: 'cerez-turleri',
        title: 'Kullanılan Çerez ve Benzeri Teknolojiler',
        paragraphs: <String>[
          'Panel web ve kamuya açık sayfalarda oturum sürekliliği, güvenlik, tercih saklama, performans ölçümü ve ürün iyileştirme için çerezler veya benzeri istemci tarafı depolama mekanizmaları kullanılabilir.',
        ],
        bullets: <String>[
          'Zorunlu çerezler: oturum, güvenlik ve yönlendirme için gereklidir.',
          'Tercih çerezleri: dil, tema veya kullanıcı tercihi saklar.',
          'Analitik çerezleri: anonim veya azaltılmış verilerle performans ve kullanım eğilimlerini ölçer.',
        ],
      ),
      const LegalSection(
        id: 'cerez-yonetimi',
        title: 'Tercih Yönetimi',
        paragraphs: <String>[
          'Zorunlu olmayan çerezler, uygulanabilir mevzuata göre kullanıcı tercihlerine bağlı olarak etkinleştirilir. Tarayıcı ayarları üzerinden çerezleri silebilir veya engelleyebilirsiniz; ancak bu durumda bazı fonksiyonlar sınırlı çalışabilir.',
        ],
      ),
      _transparencySection(),
      _dataRightsSection(),
    ],
  );

  static LegalDocument get _community => LegalDocument(
    slug: 'community',
    title: 'Topluluk Kuralları',
    description:
        'Kullanıcı davranışları, içerik standartları, raporlama ve yaptırım prensipleri.',
    version: _version,
    lastUpdated: _lastUpdated,
    icon: Icons.groups_outlined,
    sections: <LegalSection>[
      _contactSection(),
      const LegalSection(
        id: 'beklenen-davranis',
        title: 'Beklenen Davranış',
        paragraphs: <String>[
          'Topluluk katkıları dürüst, doğrulanabilir ve kamusal faydayı gözeten bir şekilde sunulmalıdır. Kullanıcılar; yorum, fiyat doğrulaması, fotoğraf ve diğer katkılarda gerçek deneyimi yansıtan bilgi paylaşmalıdır.',
        ],
      ),
      _moderationSection(),
      const LegalSection(
        id: 'raporlama',
        title: 'Raporlama ve İtiraz',
        paragraphs: <String>[
          'İhlal şüphesi taşıyan içerikler uygulama içi raporlama araçları, DMCA/DSA kanalları veya hukuki iletişim e-postası üzerinden bildirilebilir. Moderasyon kararı verilmesi halinde, uygun olduğu ölçüde itiraz veya ek açıklama imkânı sunulur.',
        ],
      ),
      _aiSection(),
    ],
  );

  static LegalDocument get _business => LegalDocument(
    slug: 'business',
    title: 'İşletme Kullanım Koşulları',
    description:
        'İşletme sahipleri ve ekip üyeleri için veri doğruluğu, yayın sorumluluğu ve ticari yükümlülükler.',
    version: _version,
    lastUpdated: _lastUpdated,
    icon: Icons.storefront_outlined,
    sections: <LegalSection>[
      _contactSection(),
      const LegalSection(
        id: 'yetki-ve-temsil',
        title: 'Yetki ve Temsil Beyanı',
        paragraphs: <String>[
          'İşletme panelini kullanan kişi; ilgili işletmeyi temsil etmeye, içerik yüklemeye ve güncelleme yapmaya yetkili olduğunu beyan eder. Yanlış veya yetkisiz temsil; hesap kısıtlaması, başvuru reddi veya hukuki süreç başlatılması sonucunu doğurabilir.',
        ],
      ),
      const LegalSection(
        id: 'dogruluk-yukumlulugu',
        title: 'Menü ve İşletme Bilgilerinin Doğruluğu',
        paragraphs: <String>[
          'İşletme; menü, fiyat, alerjen, stok, servis kapsamı, rezervasyon bağlantısı, iletişim bilgisi ve kampanya içeriklerinin güncel ve doğru olmasından sorumludur. Eski, yanıltıcı veya tüketiciyi aldatıcı bilgi yayınlamak sözleşmeye aykırıdır.',
        ],
        bullets: <String>[
          'Menü değişiklikleri makul sürede güncellenmelidir.',
          'Yasal uyarı gerektiren içerikler açık biçimde gösterilmelidir.',
          'Telif hakkı, marka veya üçüncü taraf haklarını ihlal eden materyal yüklenmemelidir.',
        ],
      ),
      const LegalSection(
        id: 'denetim-ve-yaptirim',
        title: 'Denetim, Askıya Alma ve Kaldırma Yetkisi',
        paragraphs: <String>[
          'Yeedoy; işletme içeriğini kalite, güvenlik, mevzuat, tüketici koruması ve platform bütünlüğü bakımından inceleyebilir. Gerekli görüldüğünde düzeltme isteyebilir, belirli alanları pasife alabilir veya işletme hesabını askıya alabilir.',
        ],
      ),
      _transparencySection(),
      _dataRightsSection(),
    ],
  );

  static LegalDocument get _copyright => LegalDocument(
    slug: 'copyright',
    title: 'Telif ve İçerik Hakları Politikası',
    description:
        'Menü, görsel, metin ve marka unsurlarına ilişkin hak sahipliği ve ihlal prosedürleri.',
    version: _version,
    lastUpdated: _lastUpdated,
    icon: Icons.copyright_outlined,
    sections: <LegalSection>[
      _contactSection(),
      const LegalSection(
        id: 'hak-sahipligi',
        title: 'Hak Sahipliği',
        paragraphs: <String>[
          'Kullanıcılar ve işletmeler, platforma yükledikleri içeriklerin kullanım hakkına sahip olduklarını veya gerekli izinleri aldıklarını taahhüt eder. Menü görselleri, fotoğraflar, marka öğeleri ve açıklamalar üzerinde üçüncü taraf hakları bulunabilir.',
        ],
      ),
      const LegalSection(
        id: 'ihlal-bildirimi',
        title: 'İhlal Bildirimi Mantığı',
        paragraphs: <String>[
          'Hak sahipleri; ihlal eden içeriğin bağlantısı, hak sahipliği beyanı, iletişim bilgileri ve doğruluk taahhüdü ile bildirimde bulunabilir. Açık şekilde temellendirilen bildirimler öncelikli olarak incelenir ve gerektiğinde içerik kaldırılır.',
        ],
      ),
      const LegalSection(
        id: 'tekrar-ihlaller',
        title: 'Tekrarlayan İhlaller',
        paragraphs: <String>[
          'Tekrarlayan veya sistematik telif ihlali yapan hesaplar hakkında görünürlük azaltma, içerik engelleme, geçici askıya alma veya kalıcı kapatma dahil yaptırımlar uygulanabilir.',
        ],
      ),
      _moderationSection(),
    ],
  );

  static LegalDocument get _ai => LegalDocument(
    slug: 'ai',
    title: 'Yapay Zeka ve OCR Politikası',
    description:
        'OCR, sınıflandırma ve karar destek sistemlerinin kapsamı, sınırları ve şeffaflık ilkeleri.',
    version: _version,
    lastUpdated: _lastUpdated,
    icon: Icons.auto_awesome_outlined,
    sections: <LegalSection>[
      _contactSection(),
      _aiSection(),
      const LegalSection(
        id: 'kullanim-alanlari',
        title: 'Kullanım Alanları',
        paragraphs: <String>[
          'AI/OCR sistemleri; menü fotoğraflarından fiyat veya ürün adı çıkarımı, içerik etiketleme, kalite puanlama, sahtekarlık sinyali üretimi ve güvenlik ekibine önceliklendirme desteği sağlamak için kullanılabilir.',
        ],
      ),
      const LegalSection(
        id: 'sinirlar-ve-insan-denetimi',
        title: 'Sınırlar ve İnsan Denetimi',
        paragraphs: <String>[
          'Otomatik sistemler tek başına kesin doğruluk iddiası taşımaz. İçerik kaldırma, hesap yaptırımı, telif/ihlal kararı veya hukuki başvurular gibi yüksek etkili alanlarda manuel inceleme ve itiraz mekanizması korunur.',
        ],
      ),
      _transparencySection(),
    ],
  );

  static LegalDocument get _dmca => LegalDocument(
    slug: 'dmca',
    title: 'DMCA ve Takedown Politikası',
    description:
        'Hak sahiplerinin bildirim süreçleri, karşı bildirim mantığı ve tekrar ihlal yaklaşımı.',
    version: _version,
    lastUpdated: _lastUpdated,
    icon: Icons.report_gmailerrorred_outlined,
    sections: <LegalSection>[
      _contactSection(),
      const LegalSection(
        id: 'dmca-bildirim',
        title: 'DMCA Bildirimi',
        paragraphs: <String>[
          'Hak sahipleri veya yetkili temsilcileri; ihlal ettiği düşünülen içeriğin tam bağlantısı, ihlale konu eser tanımı, hak sahipliği beyanı, iletişim bilgileri ve iyi niyet/doğruluk taahhüdü ile bildirim yapabilir.',
        ],
      ),
      const LegalSection(
        id: 'karsi-bildirim',
        title: 'Karşı Bildirim',
        paragraphs: <String>[
          'İçerik kaldırılan taraf, yanlışlık veya yetkili kullanım iddiası varsa karşı bildirimde bulunabilir. Karşı bildirim; içerik tanımı, iletişim bilgileri ve beyan içermelidir. Gerekli görüldüğünde taraflar ek belge sunmaya davet edilir.',
        ],
      ),
      const LegalSection(
        id: 'islem-akisi',
        title: 'İşlem Akışı',
        paragraphs: <String>[
          'Yeedoy, yeterli temele sahip DMCA bildirimlerini makul sürede inceleyerek içeriği geçici veya kalıcı kaldırabilir. Dolandırıcı, kötü niyetli veya seri ihlal bildirimleri reddedilebilir ve ilgili hesaplar kısıtlanabilir.',
        ],
      ),
      _moderationSection(),
    ],
  );

  static LegalDocument get _dsa => LegalDocument(
    slug: 'dsa',
    title: 'DSA Uyum ve Yasa Dışı İçerik Bildirim Politikası',
    description:
        'AB Dijital Hizmetler Yasası yaklaşımı, notice-and-action mantığı ve açıklama yükümlülükleri.',
    version: _version,
    lastUpdated: _lastUpdated,
    icon: Icons.balance_outlined,
    sections: <LegalSection>[
      _contactSection(),
      const LegalSection(
        id: 'notice-action',
        title: 'Notice and Action Süreci',
        paragraphs: <String>[
          'Yasa dışı içerik, mevzuata aykırı ürün/hizmet tanıtımı, telif ihlali, dolandırıcılık, sahte temsil, tüketiciyi yanıltma veya topluluk güvenliğini tehdit eden içerikler için erişilebilir bir bildirim kanalı sunulur. Bildirimler kayıt altına alınır ve duruma göre önceliklendirilir.',
        ],
      ),
      const LegalSection(
        id: 'karar-bildirimi',
        title: 'Karar Gerekçesi ve Şeffaflık',
        paragraphs: <String>[
          'İçerik kaldırma, görünürlük azaltma veya hesap kısıtlaması gibi kararlar, uygun olduğu ölçüde gerekçelendirilir. Şeffaflık raporları ve iç süreçler mevzuat gereklilikleriyle uyumlu şekilde sürdürülebilir.',
        ],
      ),
      _moderationSection(),
      _dataRightsSection(),
    ],
  );

  static LegalDocument get _dataSafety => LegalDocument(
    slug: 'data-safety',
    title: 'Veri Güvenliği ve Data Safety Politikası',
    description:
        'Google Play Data Safety yaklaşımı, veri koruma tedbirleri ve yaşam döngüsü yönetimi.',
    version: _version,
    lastUpdated: _lastUpdated,
    icon: Icons.dataset_outlined,
    sections: <LegalSection>[
      _contactSection(),
      const LegalSection(
        id: 'guvenlik-kontrolleri',
        title: 'Temel Güvenlik Kontrolleri',
        paragraphs: <String>[
          'Veriler; erişim yetkilendirmesi, audit log, saklama sınırları, şifreleme, imzalı istekler, oran sınırlama, kötüye kullanım tespiti ve operasyonel izleme gibi kontrollerle korunur.',
        ],
        bullets: <String>[
          'Üretim erişimleri rol tabanlı olarak sınırlandırılır.',
          'Kritik yazma işlemleri loglanır ve gerektiğinde geriye dönük incelenebilir.',
          'Silme ve dışa aktarma talepleri süreç bazlı olarak takip edilir.',
        ],
      ),
      _transparencySection(),
      _dataRightsSection(),
      _aiSection(),
    ],
  );

  static LegalDocument get _trustSafety => LegalDocument(
    slug: 'trust-safety',
    title: 'Trust & Safety Politikası',
    description:
        'Platform bütünlüğü, moderasyon, spam/abuse önleme ve güvenlik operasyonlarının ana çerçevesi.',
    version: _version,
    lastUpdated: _lastUpdated,
    icon: Icons.shield_outlined,
    sections: <LegalSection>[
      _contactSection(),
      _intermediarySection(),
      _moderationSection(),
      const LegalSection(
        id: 'risk-yonetimi',
        title: 'Risk Yönetimi ve Operasyonel Öncelikler',
        paragraphs: <String>[
          'Trust & Safety programı; yasa dışı içerik, dolandırıcılık, bot ağları, yanlış sahiplik talepleri, telif ihlali, çocuk güvenliği, kişisel veri sızıntısı ve manipülatif davranışlar gibi riskleri azaltmayı hedefler.',
          'Kararlar; otomatik sinyaller, güven puanları, kullanıcı şikayetleri, geçmiş ihlal örüntüleri ve operasyon ekiplerinin incelemeleriyle desteklenebilir.',
        ],
      ),
      const LegalSection(
        id: 'uygulama-araclari',
        title: 'Uygulama Araçları',
        bullets: <String>[
          'İçerik gizleme veya kaldırma',
          'Hesap doğrulama isteği',
          'Geçici askıya alma veya hız sınırlama',
          'Kalıntı verilerin güvenli arşivlenmesi',
          'Yetkili makamlara veya hak sahiplerine dönüş',
        ],
      ),
      _aiSection(),
    ],
  );

  static LegalDocument get _security => LegalDocument(
    slug: 'security',
    title: 'Güvenlik ve Zafiyet Bildirim Politikası',
    description:
        'Güvenlik araştırmacıları, açıklama kuralları ve sistem koruma prensipleri.',
    version: _version,
    lastUpdated: _lastUpdated,
    icon: Icons.security_outlined,
    sections: <LegalSection>[
      _contactSection(),
      const LegalSection(
        id: 'sorumlu-aciklama',
        title: 'Sorumlu Açıklama',
        paragraphs: <String>[
          'Güvenlik araştırmacıları, sistemlere zarar vermeden ve kullanıcı verisini gereksiz yere işlemeksizin tespit ettikleri güvenlik açıklarını sorumlu biçimde bildirebilir. Yetkisiz erişim, veri indirme, hizmet kesintisi veya sosyal mühendislik eylemleri kabul edilmez.',
        ],
      ),
      const LegalSection(
        id: 'bildirim-icerigi',
        title: 'Bildirim İçeriği',
        bullets: <String>[
          'Etkilenen yüzeyin adresi veya rota bilgisi',
          'Yeniden üretim adımları ve risk açıklaması',
          'Varsa ekran görüntüsü veya güvenli PoC',
          'İletişim için dönüş adresi',
        ],
      ),
      const LegalSection(
        id: 'koruma-onlemleri',
        title: 'Koruma Önlemleri',
        paragraphs: <String>[
          'Yeedoy; zafiyetlerin etkisini azaltmak için erişim kısıtlama, geçici devre dışı bırakma, anahtar rotasyonu, log inceleme ve yapılandırma sıkılaştırma gibi önlemleri uygulayabilir.',
        ],
      ),
      _transparencySection(),
    ],
  );

  static LegalDocument get _lawEnforcement => LegalDocument(
    slug: 'law-enforcement',
    title: 'Kolluk Kuvvetleri ve Resmî Makam Talepleri',
    description:
        'Yasal taleplerin doğrulanması, veri paylaşım sınırları ve acil durum yaklaşımı.',
    version: _version,
    lastUpdated: _lastUpdated,
    icon: Icons.local_police_outlined,
    sections: <LegalSection>[
      _contactSection(),
      const LegalSection(
        id: 'talep-dogrulama',
        title: 'Talep Doğrulama',
        paragraphs: <String>[
          'Resmî makam talepleri yalnızca yetki, konu, kapsam ve hukuki dayanak bakımından doğrulanabildiği ölçüde değerlendirilir. Kapsamı belirsiz veya aşırı geniş talepler daraltma veya ek bilgi isteme gerekçesiyle bekletilebilir.',
        ],
      ),
      const LegalSection(
        id: 'acil-durum',
        title: 'Acil Durum Talepleri',
        paragraphs: <String>[
          'Hayat veya fiziksel güvenlik açısından acil risk doğuran durumlarda, hukuken izin verilen ölçüde hızlandırılmış değerlendirme uygulanabilir. Bu tür paylaşımlar olay bazlı olarak kayıt altına alınır ve sonrası için denetlenebilir tutulur.',
        ],
      ),
      _transparencySection(),
      _dataRightsSection(),
    ],
  );

  static LegalDocument get _deleteAccount => LegalDocument(
    slug: 'delete-account',
    title: 'Hesap Silme ve Veri Talebi Politikası',
    description:
        'Hesap silme, veri dışa aktarma ve gizlilik başvurularının işlenme şekli.',
    version: _version,
    lastUpdated: _lastUpdated,
    icon: Icons.delete_forever_outlined,
    sections: <LegalSection>[
      _contactSection(),
      const LegalSection(
        id: 'hesap-silme',
        title: 'Hesap Silme Süreci',
        paragraphs: <String>[
          'Kullanıcılar mobil uygulama içindeki ilgili alanlardan veya hukuki iletişim kanalı üzerinden hesap silme talebi oluşturabilir. Talep alındığında kimlik doğrulama, açık oturum, olası kötüye kullanım ve saklama zorunlulukları değerlendirilir.',
          'Hesap silme; aktif görünürlüğü sona erdirir, erişimi kapatır ve silinebilir verileri belirlenen iş akışıyla kaldırır. Yasal zorunluluk, sahtekarlık önleme, muhasebe veya uyuşmazlık çözümü için tutulması gereken kayıtlar saklanabilir.',
        ],
      ),
      const LegalSection(
        id: 'veri-disa-aktarma',
        title: 'Veri Dışa Aktarma ve Gizlilik Başvuruları',
        paragraphs: <String>[
          'Kullanıcılar kişisel verilerinin kopyasını talep edebilir, düzeltme veya işleme itiraz başvurusu yapabilir. Başvurular statü bazlı takip edilir ve makul sürede sonuçlandırılır.',
        ],
      ),
      _dataRightsSection(),
      _transparencySection(),
    ],
  );
}
