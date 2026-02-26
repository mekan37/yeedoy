import 'dart:ui';

import 'package:flutter/material.dart';

@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.space4,
    required this.space8,
    required this.space12,
    required this.space16,
    required this.space20,
    required this.space24,
    required this.radius12,
    required this.radius16,
    required this.radius20,
    required this.radius24,
    required this.elevation1,
    required this.elevation2,
    required this.elevation3,
    required this.minHitTarget,
    required this.fast,
    required this.medium,
    required this.slow,
  });

  final double space4;
  final double space8;
  final double space12;
  final double space16;
  final double space20;
  final double space24;

  final double radius12;
  final double radius16;
  final double radius20;
  final double radius24;
  final double elevation1;
  final double elevation2;
  final double elevation3;
  final double minHitTarget;

  final Duration fast;
  final Duration medium;
  final Duration slow;

  EdgeInsets get pagePadding =>
      EdgeInsets.symmetric(horizontal: space16, vertical: space24);
  EdgeInsets get sectionPadding =>
      EdgeInsets.symmetric(horizontal: space16, vertical: space24);

  SizedBox gap8() => SizedBox(height: space8);
  SizedBox gap12() => SizedBox(height: space12);
  SizedBox gap16() => SizedBox(height: space16);
  SizedBox gap24() => SizedBox(height: space24);
  SizedBox sectionGap() => SizedBox(height: space24);

  static AppTokens of(BuildContext context) {
    return Theme.of(context).extension<AppTokens>()!;
  }

  @override
  AppTokens copyWith({
    double? space4,
    double? space8,
    double? space12,
    double? space16,
    double? space20,
    double? space24,
    double? radius12,
    double? radius16,
    double? radius20,
    double? radius24,
    double? elevation1,
    double? elevation2,
    double? elevation3,
    double? minHitTarget,
    Duration? fast,
    Duration? medium,
    Duration? slow,
  }) {
    return AppTokens(
      space4: space4 ?? this.space4,
      space8: space8 ?? this.space8,
      space12: space12 ?? this.space12,
      space16: space16 ?? this.space16,
      space20: space20 ?? this.space20,
      space24: space24 ?? this.space24,
      radius12: radius12 ?? this.radius12,
      radius16: radius16 ?? this.radius16,
      radius20: radius20 ?? this.radius20,
      radius24: radius24 ?? this.radius24,
      elevation1: elevation1 ?? this.elevation1,
      elevation2: elevation2 ?? this.elevation2,
      elevation3: elevation3 ?? this.elevation3,
      minHitTarget: minHitTarget ?? this.minHitTarget,
      fast: fast ?? this.fast,
      medium: medium ?? this.medium,
      slow: slow ?? this.slow,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      space4: lerpDouble(space4, other.space4, t)!,
      space8: lerpDouble(space8, other.space8, t)!,
      space12: lerpDouble(space12, other.space12, t)!,
      space16: lerpDouble(space16, other.space16, t)!,
      space20: lerpDouble(space20, other.space20, t)!,
      space24: lerpDouble(space24, other.space24, t)!,
      radius12: lerpDouble(radius12, other.radius12, t)!,
      radius16: lerpDouble(radius16, other.radius16, t)!,
      radius20: lerpDouble(radius20, other.radius20, t)!,
      radius24: lerpDouble(radius24, other.radius24, t)!,
      elevation1: lerpDouble(elevation1, other.elevation1, t)!,
      elevation2: lerpDouble(elevation2, other.elevation2, t)!,
      elevation3: lerpDouble(elevation3, other.elevation3, t)!,
      minHitTarget: lerpDouble(minHitTarget, other.minHitTarget, t)!,
      fast: _lerpDuration(fast, other.fast, t),
      medium: _lerpDuration(medium, other.medium, t),
      slow: _lerpDuration(slow, other.slow, t),
    );
  }

  static Duration _lerpDuration(Duration a, Duration b, double t) {
    final ms =
        a.inMilliseconds + ((b.inMilliseconds - a.inMilliseconds) * t).round();
    return Duration(milliseconds: ms);
  }
}
