import 'package:flutter/material.dart';
import 'package:yeedoy_shared_ui_components/yeedoy_shared_ui_components.dart';

class PersonelListIskeleti extends StatelessWidget {
  const PersonelListIskeleti({super.key, this.satirSayisi = 6});

  final int satirSayisi;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: satirSayisi,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, _) => const AppSkeletonCard(lines: 2),
    );
  }
}

class PersonelDashboardIskeleti extends StatelessWidget {
  const PersonelDashboardIskeleti({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: AppSkeletonBox(height: 80)),
              SizedBox(width: 12),
              Expanded(child: AppSkeletonBox(height: 80)),
              SizedBox(width: 12),
              Expanded(child: AppSkeletonBox(height: 80)),
            ],
          ),
          SizedBox(height: 16),
          AppSkeletonBox(height: 180),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: AppSkeletonBox(height: 60)),
              SizedBox(width: 12),
              Expanded(child: AppSkeletonBox(height: 60)),
            ],
          ),
        ],
      ),
    );
  }
}
