import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yeedoy/features/kesif/domain/isletme_karti.dart';
import 'package:yeedoy/features/kesif/domain/kesif_arama_durumu.dart';
import 'package:yeedoy/features/favoriler/domain/favoriler_kontrolcu.dart';
import 'package:yeedoy/features/menuler/data/yemek_katalogu_deposu.dart';
import 'package:yeedoy/features/menuler/domain/yemek_katalogu_modelleri.dart';
import 'package:yeedoy/features/menuler/ui/menu_urunler_sekmesi.dart';
import 'package:yeedoy/features/menuler/domain/menu_urun_arama_modeli.dart';

import '../../../uygulama/tema/renkler.dart';
import '../../../core/analitik/analitik_istemcisi.dart';
import '../../../core/analitik/uygulama_olaylari.dart';
import '../../../core/analitik/analitik_deposu.dart';
import '../../../core/ceviri/uygulama_yerellesmeleri.dart';
import '../../../core/ceviri/bicimlendiriciler.dart';
import '../../../core/ayarlar/ozellik_bayraklari.dart';
import '../../../core/konum/kullanici_konum_kontrolcusu.dart';
import '../../../core/depolama/kategori_tercihleri.dart';
import '../../../core/depolama/cevrimdisi_onbellek_tercihleri.dart';
import '../../../core/depolama/arama_tercihleri.dart';

import '../../kimlik/domain/kimlik_saglayicilari.dart';
import '../../en_iyi_isletmeler/ui/en_iyi_isletmeler_seridi.dart';

import '../domain/kesif_arama_bildiricisi.dart';
import '../domain/kesif_akis_olusturucu.dart';
import '../domain/yakin_kampanya.dart';
import '../domain/yakin_kampanya_saglayicisi.dart';
import '../domain/fiyat_anomalisi.dart';
import '../domain/bolgesel_fiyat_endeksi.dart';
import '../data/kesif_deposu.dart';
import '../domain/ana_akis.dart';
import '../domain/trend_isletme.dart';
import '../../../features/shared/ui/bilesenler/konum_secici_paneli.dart';
import '../domain/bugunun_secimi_kontrolcusu.dart';
import '../domain/bugunun_spesiyali.dart';
import '../../favoriler/domain/favori_durumu_saglayicisi.dart';
import '../../shared/ui/isletme_karti.dart';
import '../../shared/ui/kategori_etiketi.dart';
import '../../../core/hatalar/uygulama_hata_esleyicisi.dart';
import '../../../core/buyume/ab_deneyleri.dart';
import '../../../core/buyume/huni_izleyici.dart';
import '../../../core/performans/firebase_performans_izi.dart';
import '../../sponsorluk/domain/sponsorlu_isletmeler_saglayicisi.dart';
import '../../reklamlar/data/yerel_reklam_kontrolcusu.dart';
import '../../reklamlar/ui/yerel_reklam_karti.dart';
import '../../profil/domain/profil_ilerleme_saglayicisi.dart';
import '../../profil/domain/profil_ilerleme.dart';
import '../../katki/ui/katki_girdisi.dart';
import '../../gomulu/data/gomulu_deposu.dart';
import '../../gomulu/ui/gomulu_goruntuleyici_sayfasi.dart';
import '../../isletme/domain/ogun_karti_saglayicilari_saglayicisi.dart';
import '../../shared/ui/yardimci-bilesenler/ogun_karti_rozet.dart';
import '../../../core/hizmetler/anasayfa_bileseni_servisi.dart';
import '../../../core/hizmetler/asistan_kisa_yollari_servisi.dart';
import 'kategori_yapilandirmasi.dart';
import 'bilesenler/kategori_hizli_filtreleri.dart';
import 'bilesenler/kesif_arama_cubugu.dart';
import '../../../features/shared/ui/tasarim_sistemi.dart';
import '../../../features/shared/ui/bilesenler/hizli_giris_paneli.dart';
import '../../../features/shared/ui/bilesenler/hava_durumu_ipucu_cubugu.dart';

part 'yuzeyler/kesif_kampanyalar_sekmesi.dart';
part 'yuzeyler/kesif_harita_yuzeyi.dart';
part 'yuzeyler/kesif_ozet_bolumleri.dart';
part 'parcalar/kesif_saglayicilari.dart';
part 'parcalar/kesif_onerilenler_sekmesi.dart';
part 'parcalar/kesif_kartlari.dart';
part 'parcalar/kesif_panelleri.dart';
part 'parcalar/kesif_bilesenleri.dart';
part 'parcalar/kesif_kontrolleri.dart';

class DiscoveryPage extends ConsumerWidget {
  const DiscoveryPage({super.key, this.initialSort});

  /// Optional initial sort to apply when the page is opened via deep link.
  /// Matches [DiscoverySort] enum name, e.g. 'priceLow'.
  final String? initialSort;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return Material(
      color: AppColors.bg,
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            TabBar(
              tabs: [
                Tab(text: t.tabRecommended),
                Tab(text: t.tabCampaigns),
                Tab(text: t.tabFoods),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _KeepAliveTab(
                    child: _RecommendedTab(initialSort: initialSort),
                  ),
                  _KeepAliveTab(child: _CampaignsTab()),
                  _KeepAliveTab(child: MenuItemsTab()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
