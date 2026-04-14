import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PanelIcon extends StatelessWidget {
  const PanelIcon({
    super.key,
    required this.icon,
    required this.color,
    this.materialSize = 20,
    this.awesomeSize = 16,
  });

  final IconData icon;
  final Color color;
  final double materialSize;
  final double awesomeSize;

  @override
  Widget build(BuildContext context) {
    final family = icon.fontFamily ?? '';
    final isAwesome = family.contains('FontAwesome');
    if (isAwesome) {
      return FaIcon(icon, size: awesomeSize, color: color);
    }
    return Icon(icon, size: materialSize, color: color);
  }
}
