import 'package:flutter/material.dart';

/// İşletme uygulaması renk paleti.
/// Müşteri uygulamasından farklı: koyu, profesyonel, operasyonel.
class PColors {
  // Marka
  static const primary = Color(0xFF7F1D1D);
  static const primaryStrong = Color(0xFFDC2626);
  static const primarySoft = Color(0xFF3B1515);
  static const onPrimary = Color(0xFFFFFFFF);

  // Arka planlar — koyu tema
  static const bg = Color(0xFF0D0F13);
  static const surface = Color(0xFF161A22);
  static const surfaceAlt = Color(0xFF1C2030);
  static const card = Color(0xFF1C2030);
  static const cardElevated = Color(0xFF222840);

  // Metin
  static const textStrong = Color(0xFFF0F4FC);
  static const text = Color(0xFFC8D0E0);
  static const muted = Color(0xFF6B7A96);

  // Sınır
  static const border = Color(0xFF2A3040);
  static const borderStrong = Color(0xFF3A4555);

  // Durum
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  // Sipariş durumu renkleri
  static const orderPending = Color(0xFFF59E0B);    // sarı — bekliyor
  static const orderSeen = Color(0xFF3B82F6);       // mavi — görüldü
  static const orderDone = Color(0xFF22C55E);       // yeşil — tamamlandı
}
