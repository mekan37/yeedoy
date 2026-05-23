import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../uygulama/tema/renkler.dart';
import '../../../core/ceviri/uygulama_yerellesmeleri.dart';
import '../../../features/shared/ui/bilesenler/uygulama_karti.dart';

class NativeAdCard extends StatelessWidget {
  const NativeAdCard({super.key, required this.ad});

  final NativeAd ad;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.borderStrong),
                    ),
                    child: Text(
                      AppLocalizations.of(context).sponsoredDisclosure,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'AdChoices',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(height: 120, child: AdWidget(ad: ad)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}



