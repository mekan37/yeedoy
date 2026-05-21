import 'package:flutter/material.dart';

import 'colors.dart';

class YeedoyLogo extends StatelessWidget {
  const YeedoyLogo({
    super.key,
    this.size = 40,
    this.showText = true,
    this.textColor = AppColors.textStrong,
  });

  final double size;
  final bool showText;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    // Aspect ratio 821:834
    final h = size * (834 / 821);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: h,
          child: CustomPaint(painter: const _YeedoyMarkPainter()),
        ),
        if (showText) ...[
          SizedBox(width: size * .18),
          Text(
            'eedoy',
            style: TextStyle(
              color: textColor,
              fontSize: size * .78,
              fontFamily: 'Flexing',
              fontWeight: FontWeight.w800,
              height: 1,
              letterSpacing: -size * .045,
            ),
          ),
        ],
      ],
    );
  }
}

class _YeedoyMarkPainter extends CustomPainter {
  const _YeedoyMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Orijinal viewBox: 821 x 834
    final sx = size.width / 821.0;
    final sy = size.height / 834.0;
    canvas
      ..save()
      ..scale(sx, sy);

    // Ana gövde gradyanı
    final mainGrad = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.primaryStrong, AppColors.primary, AppColors.primaryDeep],
    ).createShader(const Rect.fromLTWH(10, 91, 800, 732));

    // Nokta vurgu gradyanı
    final accentGrad = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFF87171), AppColors.primaryStrong],
    ).createShader(const Rect.fromLTWH(575, 10, 65, 193));

    // Y mark ana gövde
    final main = Path()
      ..moveTo(10, 91)
      ..lineTo(116, 169)
      ..lineTo(298, 498)
      ..lineTo(313, 727)
      ..lineTo(292, 788)
      ..lineTo(253, 823)
      ..lineTo(344, 821)
      ..lineTo(376, 794)
      ..lineTo(386, 690)
      ..lineTo(360, 626)
      ..lineTo(372, 515)
      ..lineTo(376, 619)
      ..lineTo(391, 516)
      ..lineTo(398, 615)
      ..lineTo(399, 515)
      ..lineTo(416, 615)
      ..lineTo(419, 517)
      ..lineTo(429, 621)
      ..lineTo(402, 685)
      ..lineTo(410, 791)
      ..lineTo(444, 821)
      ..lineTo(526, 823)
      ..lineTo(488, 788)
      ..lineTo(467, 725)
      ..lineTo(480, 495)
      ..lineTo(734, 141)
      ..lineTo(810, 90)
      ..lineTo(686, 113)
      ..lineTo(520, 242)
      ..lineTo(391, 406)
      ..lineTo(351, 535)
      ..lineTo(358, 453)
      ..lineTo(397, 366)
      ..lineTo(302, 234)
      ..lineTo(311, 142)
      ..lineTo(226, 93)
      ..close();

    // Nokta vurgu
    final accent = Path()
      ..moveTo(629, 10)
      ..lineTo(621, 12)
      ..lineTo(598, 25)
      ..lineTo(586, 37)
      ..lineTo(576, 55)
      ..lineTo(575, 74)
      ..lineTo(579, 86)
      ..lineTo(594, 104)
      ..lineTo(600, 116)
      ..lineTo(600, 137)
      ..lineTo(594, 152)
      ..lineTo(584, 166)
      ..lineTo(564, 186)
      ..lineTo(543, 203)
      ..lineTo(551, 201)
      ..lineTo(551, 199)
      ..lineTo(573, 187)
      ..lineTo(604, 165)
      ..lineTo(624, 146)
      ..lineTo(636, 128)
      ..lineTo(640, 109)
      ..lineTo(637, 94)
      ..lineTo(632, 86)
      ..lineTo(615, 69)
      ..lineTo(609, 57)
      ..lineTo(609, 40)
      ..lineTo(618, 22)
      ..close();

    canvas
      ..drawPath(main, Paint()..shader = mainGrad)
      ..drawPath(accent, Paint()..shader = accentGrad)
      ..restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
