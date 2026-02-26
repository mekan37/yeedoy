enum NamePrivacyMode { full, maskLastName, maskBoth }

NamePrivacyMode parsePrivacy(String? value) {
  final normalized = (value ?? '').trim().toLowerCase();
  switch (normalized) {
    case 'masklastname':
    case 'mask_last_name':
    case 'mask_lastname':
      return NamePrivacyMode.maskLastName;
    case 'maskboth':
    case 'mask_both':
      return NamePrivacyMode.maskBoth;
    case 'full':
    default:
      return NamePrivacyMode.full;
  }
}

String privacyToDb(NamePrivacyMode mode) {
  switch (mode) {
    case NamePrivacyMode.full:
      return 'full';
    case NamePrivacyMode.maskLastName:
      return 'mask_last_name';
    case NamePrivacyMode.maskBoth:
      return 'mask_both';
  }
}

String maskWord(String? s, {int visiblePrefix = 1}) {
  final input = (s ?? '').trim();
  if (input.isEmpty) return '';
  final chars = input.runes.toList();
  if (chars.length <= 1) return input;
  final safePrefix = visiblePrefix < 0 ? 0 : visiblePrefix;
  final keep = safePrefix.clamp(0, chars.length);
  final prefix = String.fromCharCodes(chars.take(keep));
  final maskedLen = chars.length - keep;
  if (maskedLen <= 0) return input;
  return '$prefix${List.filled(maskedLen, '*').join()}';
}

String formatDisplayName({
  required String? firstName,
  required String? lastName,
  required NamePrivacyMode mode,
}) {
  final first = (firstName ?? '').trim();
  final last = (lastName ?? '').trim();

  switch (mode) {
    case NamePrivacyMode.full:
      if (first.isEmpty && last.isEmpty) return '';
      if (first.isEmpty) return last;
      if (last.isEmpty) return first;
      return '$first $last';
    case NamePrivacyMode.maskLastName:
      if (first.isEmpty && last.isEmpty) return '';
      if (first.isEmpty) return maskWord(last);
      if (last.isEmpty) return first;
      return '$first ${maskWord(last)}';
    case NamePrivacyMode.maskBoth:
      if (first.isEmpty && last.isEmpty) return '';
      if (first.isEmpty) return maskWord(last);
      if (last.isEmpty) return maskWord(first);
      return '${maskWord(first)} ${maskWord(last)}';
  }
}
