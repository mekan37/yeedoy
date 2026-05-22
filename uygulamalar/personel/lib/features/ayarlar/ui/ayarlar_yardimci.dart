import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../uygulama/tema/renkler.dart';

class AyarlarInfoKutucusu extends StatelessWidget {
  final String isletmeAdi;
  final String email;
  const AyarlarInfoKutucusu({super.key, required this.isletmeAdi, required this.email});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: const BoxDecoration(color: PColors.primarySoft, shape: BoxShape.circle),
            child: const Icon(Icons.store_outlined, color: PColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isletmeAdi, style: const TextStyle(fontWeight: FontWeight.w900, color: PColors.textStrong)),
                Text(email, style: const TextStyle(color: PColors.muted, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AyarlarSurumGoster extends StatefulWidget {
  const AyarlarSurumGoster({super.key});

  @override
  State<AyarlarSurumGoster> createState() => _AyarlarSurumGosterState();
}

class _AyarlarSurumGosterState extends State<AyarlarSurumGoster> {
  String _surum = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _surum = 'v${info.version}+${info.buildNumber}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(_surum, style: const TextStyle(color: PColors.muted, fontSize: 12)));
  }
}
