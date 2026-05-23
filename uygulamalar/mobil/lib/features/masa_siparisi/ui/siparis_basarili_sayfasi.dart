import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../uygulama/tema/renkler.dart';
import '../../../features/shared/ui/tasarim_sistemi.dart';
import '../../../features/shared/ui/bilesenler/uygulama_ust_cubugu.dart';

class SiparisBasariliSayfasi extends StatelessWidget {
  const SiparisBasariliSayfasi({
    super.key,
    required this.businessName,
    required this.masaNo,
    required this.orderId,
  });

  final String businessName;
  final String masaNo;
  final String orderId;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const AppAppBar(title: Text('Sipariş Alındı')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Siparişiniz mutfağa iletildi!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  color: AppColors.textStrong,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '$businessName · Masa $masaNo',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Siparişiniz hazırlandıkça masanıza getirilecektir.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 32),
              AppCard(
                child: Column(
                  children: [
                    _SiparisDetaySatiri(
                      label: 'İşletme',
                      value: businessName,
                    ),
                    const Divider(height: 16),
                    _SiparisDetaySatiri(
                      label: 'Masa',
                      value: masaNo,
                    ),
                    if (orderId.isNotEmpty &&
                        orderId != 'ok') ...[
                      const Divider(height: 16),
                      _SiparisDetaySatiri(
                        label: 'Sipariş No',
                        value: orderId.length > 8
                            ? orderId.substring(0, 8).toUpperCase()
                            : orderId.toUpperCase(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.go('/discover'),
                  child: const Text('Tamam'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/siparislerim'),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Siparişlerim'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SiparisDetaySatiri extends StatelessWidget {
  const _SiparisDetaySatiri({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: AppColors.textStrong,
          ),
        ),
      ],
    );
  }
}
