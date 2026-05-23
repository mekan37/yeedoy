import 'package:flutter/material.dart';

import '../../../../features/shared/ui/tasarim_sistemi.dart';

class TopBusinessSkeleton extends StatelessWidget {
  const TopBusinessSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: 220,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Align(
              alignment: Alignment.topRight,
              child: AppSkeletonBox(height: 18, width: 46),
            ),
            SizedBox(height: 8),
            AppSkeletonBox(height: 12),
            SizedBox(height: 6),
            AppSkeletonBox(height: 12, width: 140),
            SizedBox(height: 8),
            Row(
              children: [
                AppSkeletonBox(height: 18, width: 70),
                SizedBox(width: 8),
                Expanded(child: AppSkeletonBox(height: 12)),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                AppSkeletonBox(height: 12, width: 40),
                SizedBox(width: 10),
                AppSkeletonBox(height: 12, width: 90),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


