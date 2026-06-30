import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../domain/business_location_provider.dart';

class BusinessLocationPage extends ConsumerStatefulWidget {
  const BusinessLocationPage({super.key, required this.businessId});

  final String businessId;

  @override
  ConsumerState<BusinessLocationPage> createState() =>
      _BusinessLocationPageState();
}

class _BusinessLocationPageState extends ConsumerState<BusinessLocationPage> {
  final _mapController = MapController();
  LatLng? _selectedPoint;
  bool _gettingGps = false;

  // Varsayılan merkez: Adana (Yeedoy birincil pazarı)
  static const _kDefaultCenter = LatLng(37.0, 35.3213);

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);

    // Mevcut koordinatlar yüklendiğinde _selectedPoint'i bir kez başlat
    ref.listen<AsyncValue<BusinessLocationState>>(
      businessLocationProvider(widget.businessId),
      (prev, next) {
        final nextData = next.asData?.value;
        if (nextData == null) return;

        // İlk yüklemede haritayı işletme konumuna taşı
        if (_selectedPoint == null && nextData.hasCoordinates) {
          final point = LatLng(nextData.latitude!, nextData.longitude!);
          setState(() => _selectedPoint = point);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              try {
                _mapController.move(point, 15);
              } catch (_) {
                // Harita henüz oluşturulmamışsa yok say; initialCenter kullanılır
              }
            }
          });
        }

        final prevData = prev?.asData?.value;

        // Kayıt başarılıysa bildir
        if (nextData.saveSuccess && prevData?.saveSuccess != true) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Konum başarıyla güncellendi.'),
                duration: Duration(seconds: 2),
              ),
            );
          });
        }

        // Kayıt hatasını bildir
        if (nextData.error != null && prevData?.error == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Konum kaydedilemedi. Tekrar deneyin.'),
                duration: Duration(seconds: 3),
              ),
            );
          });
        }
      },
    );

    final locationAsync =
        ref.watch(businessLocationProvider(widget.businessId));
    final isSaving = locationAsync.asData?.value.isSaving ?? false;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // ── Harita ───────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedPoint ?? _kDefaultCenter,
              initialZoom: 15.0,
              onTap: (_, point) => setState(() => _selectedPoint = point),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.yeedoy.app',
              ),
              if (_selectedPoint != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedPoint!,
                      width: 48,
                      height: 56,
                      alignment: Alignment.bottomCenter,
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.primary,
                        size: 48,
                        shadows: [
                          Shadow(blurRadius: 12, color: Color(0x33000000)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // ── Yüklenme örtüsü ──────────────────────────────────────────────────
          if (locationAsync.isLoading)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x66FFFFFF),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            ),

          // ── Dokunma ipucu etiketi ─────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 72,
            left: 0,
            right: 0,
            child: Center(
              child: _HintChip(
                icon: Icons.touch_app_rounded,
                label: 'Haritaya dokunarak konum seçin',
                tokens: tokens,
              ),
            ),
          ),

          // ── Geri butonu ──────────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: _MapFab(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),

          // ── GPS butonu ───────────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: _MapFab(
              icon: _gettingGps
                  ? Icons.hourglass_top_rounded
                  : Icons.my_location_rounded,
              onTap: _gettingGps ? null : _useGpsLocation,
            ),
          ),

          // ── Alt panel ────────────────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomPanel(
              selectedPoint: _selectedPoint,
              isSaving: isSaving,
              tokens: tokens,
              onSave: _save,
            ),
          ),
        ],
      ),
    );
  }

  // ── Eylemler ─────────────────────────────────────────────────────────────────

  Future<void> _useGpsLocation() async {
    setState(() => _gettingGps = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final point = LatLng(pos.latitude, pos.longitude);
      setState(() => _selectedPoint = point);
      try {
        _mapController.move(point, 16);
      } catch (_) {}
    } catch (_) {
      // Konum alınamazsa sessizce yok say
    } finally {
      if (mounted) setState(() => _gettingGps = false);
    }
  }

  Future<void> _save() async {
    if (_selectedPoint == null) return;
    await ref
        .read(businessLocationProvider(widget.businessId).notifier)
        .save(_selectedPoint!.latitude, _selectedPoint!.longitude);
  }
}

// ── Alt panel widget'ı ────────────────────────────────────────────────────────

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.selectedPoint,
    required this.isSaving,
    required this.tokens,
    required this.onSave,
  });

  final LatLng? selectedPoint;
  final bool isSaving;
  final AppTokens tokens;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(tokens.radius20)),
        boxShadow: AppTokens.shadow3,
      ),
      padding: EdgeInsets.fromLTRB(
        tokens.space16,
        tokens.space16,
        tokens.space16,
        tokens.space16 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kaydırma tutamacı
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: EdgeInsets.only(bottom: tokens.space12),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const Text(
            'İşletme Konumu',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: AppColors.textStrong,
            ),
          ),
          SizedBox(height: tokens.space4),
          const Text(
            'Haritaya dokunarak yeni konumu seçin, ardından kaydedin.',
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          SizedBox(height: tokens.space12),

          // Koordinat göstergesi
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.space12,
              vertical: tokens.space12,
            ),
            decoration: BoxDecoration(
              color: AppColors.cardAlt,
              borderRadius: BorderRadius.circular(tokens.radius12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.pin_drop_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
                SizedBox(width: tokens.space8),
                Expanded(
                  child: Text(
                    selectedPoint != null
                        ? '${selectedPoint!.latitude.toStringAsFixed(6)}, '
                            '${selectedPoint!.longitude.toStringAsFixed(6)}'
                        : 'Henüz konum seçilmedi',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selectedPoint != null
                          ? AppColors.textStrong
                          : AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: tokens.space16),

          // Kaydet butonu
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (isSaving || selectedPoint == null) ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                disabledBackgroundColor: AppColors.border,
                disabledForegroundColor: AppColors.muted,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(tokens.radius12),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.onPrimary,
                      ),
                    )
                  : const Text('Bu Konumu Kaydet'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Yardımcı widget'lar ───────────────────────────────────────────────────────

class _MapFab extends StatelessWidget {
  const _MapFab({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: AppColors.shadow,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: AppColors.textStrong),
        ),
      ),
    );
  }
}

class _HintChip extends StatelessWidget {
  const _HintChip({
    required this.icon,
    required this.label,
    required this.tokens,
  });

  final IconData icon;
  final String label;
  final AppTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.space12,
        vertical: tokens.space8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xEEFFFFFF),
        borderRadius: BorderRadius.circular(tokens.radius20),
        boxShadow: AppTokens.shadow2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.muted),
          SizedBox(width: tokens.space4 + 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textStrong,
            ),
          ),
        ],
      ),
    );
  }
}
