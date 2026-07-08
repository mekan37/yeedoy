/// Returns a time-aware Turkish greeting, optionally addressed to [name].
///
///  05:00–11:59 → Günaydın
///  12:00–17:59 → Merhaba
///  18:00–21:59 → İyi Akşamlar
///  22:00–04:59 → İyi Geceler
String timeBasedGreeting([String? name]) {
  final hour = DateTime.now().hour;
  final String base;
  if (hour >= 5 && hour < 12) {
    base = 'Günaydın';
  } else if (hour >= 12 && hour < 18) {
    base = 'Merhaba';
  } else if (hour >= 18 && hour < 22) {
    base = 'İyi Akşamlar';
  } else {
    base = 'İyi Geceler';
  }
  if (name != null && name.trim().isNotEmpty) {
    return '$base, ${name.trim()} 👋';
  }
  return '$base 👋';
}
