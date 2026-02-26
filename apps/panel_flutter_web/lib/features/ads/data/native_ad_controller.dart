import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../core/config/ad_config.dart';

final nativeAdControllerProvider = NotifierProvider<NativeAdController, int>(
  NativeAdController.new,
);

class NativeAdController extends Notifier<int> {
  static const _maxCachedAds = 2;

  final List<NativeAd> _readyAds = <NativeAd>[];
  final Map<int, NativeAd> _slotAds = <int, NativeAd>{};
  int _inFlight = 0;
  bool _disposed = false;

  @override
  int build() {
    ref.onDispose(_disposeAll);
    load();
    return 0;
  }

  void load() {
    if (!AdConfig.isNativeEnabled || _disposed) return;
    _warmPool();
  }

  NativeAd? adForSlot(int slotIndex) {
    final existing = _slotAds[slotIndex];
    if (existing != null) return existing;
    if (_readyAds.isEmpty) {
      _warmPool();
      return null;
    }
    final ad = _readyAds.removeAt(0);
    _slotAds[slotIndex] = ad;
    _warmPool();
    return ad;
  }

  void _warmPool() {
    if (_disposed) return;
    if (_readyAds.length + _inFlight >= _maxCachedAds) return;
    while (_readyAds.length + _inFlight < _maxCachedAds) {
      _inFlight += 1;
      _loadOne();
    }
  }

  void _loadOne() {
    final ad = NativeAd(
      adUnitId: AdConfig.nativeUnitId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (adObj) {
          _inFlight = _inFlight > 0 ? _inFlight - 1 : 0;
          if (_disposed) {
            adObj.dispose();
            return;
          }
          if (adObj is NativeAd) {
            if (_readyAds.length >= _maxCachedAds) {
              adObj.dispose();
            } else {
              _readyAds.add(adObj);
            }
          }
          if (kDebugMode) debugPrint('native_ad load success');
          state += 1;
          _warmPool();
        },
        onAdFailedToLoad: (adObj, error) {
          _inFlight = _inFlight > 0 ? _inFlight - 1 : 0;
          adObj.dispose();
          if (kDebugMode) {
            debugPrint('native_ad load failed: ${error.code} ${error.message}');
          }
          _warmPool();
        },
      ),
      nativeAdOptions: NativeAdOptions(),
    );
    ad.load();
  }

  void _disposeAll() {
    _disposed = true;
    for (final ad in _readyAds) {
      ad.dispose();
    }
    _readyAds.clear();
    for (final ad in _slotAds.values) {
      ad.dispose();
    }
    _slotAds.clear();
  }
}
