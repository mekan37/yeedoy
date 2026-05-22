import 'package:flutter/material.dart';
import '../../../uygulama/tema/renkler.dart';

class YaziciAyarlariSheet extends StatefulWidget {
  const YaziciAyarlariSheet({super.key});

  @override
  State<YaziciAyarlariSheet> createState() => _YaziciAyarlariSheetState();
}

class _YaziciAyarlariSheetState extends State<YaziciAyarlariSheet> {
  final _ipCtrl = TextEditingController(text: '192.168.1.100');
  final _portCtrl = TextEditingController(text: '9100');
  String _kagiTipi = '80mm';
  bool _otoBaskiEtkin = false;

  @override
  void dispose() {
    _ipCtrl.dispose();
    _portCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: PColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const Text('Yazıcı Ayarları (ESC/POS)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: PColors.textStrong)),
          const SizedBox(height: 4),
          const Text('Ağ yazıcısı bağlantı bilgilerini girin', style: TextStyle(color: PColors.muted, fontSize: 13)),
          const SizedBox(height: 20),
          TextFormField(
            controller: _ipCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Yazıcı IP Adresi', hintText: '192.168.1.100', prefixIcon: Icon(Icons.wifi_outlined)),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _portCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Port', hintText: '9100', prefixIcon: Icon(Icons.power_input_outlined)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Kağıt genişliği:', style: TextStyle(color: PColors.muted, fontSize: 13)),
              const SizedBox(width: 12),
              ...['58mm', '80mm'].map((w) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(label: Text(w), selected: _kagiTipi == w, onSelected: (_) => setState(() => _kagiTipi = w)),
              )),
            ],
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Yeni sipariş otomatik baskısı', style: TextStyle(fontSize: 14)),
            subtitle: const Text('Sipariş gelince otomatik yazdır', style: TextStyle(fontSize: 12, color: PColors.muted)),
            value: _otoBaskiEtkin,
            onChanged: (v) => setState(() => _otoBaskiEtkin = v),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.wifi_find_outlined, size: 18),
                  label: const Text('Test Bağlantısı'),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${_ipCtrl.text}:${_portCtrl.text} — bağlantı testi gönderildi'), backgroundColor: PColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Kaydet'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yazıcı ayarları kaydedildi')));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
