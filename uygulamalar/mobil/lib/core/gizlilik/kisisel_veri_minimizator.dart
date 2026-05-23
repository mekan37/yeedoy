import 'dart:math';

double roundCoordinate(double value, {int decimals = 3}) {
  final mod = decimals <= 0 ? 1.0 : pow(10, decimals).toDouble();
  if (mod == 0) return value;
  return (value * mod).round() / mod;
}
