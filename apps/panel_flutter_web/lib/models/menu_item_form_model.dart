class MenuItemFormModel {
  const MenuItemFormModel({
    required this.name,
    this.description,
    required this.priceCents,
    this.currency = 'TRY',
    this.tags = const <String>[],
    this.imageUrl,
    this.isAvailable = true,
  });

  final String name;
  final String? description;
  final int priceCents;
  final String currency;
  final List<String> tags;
  final String? imageUrl;
  final bool isAvailable;

  MenuItemFormModel copyWith({
    String? name,
    String? description,
    int? priceCents,
    String? currency,
    List<String>? tags,
    String? imageUrl,
    bool? isAvailable,
  }) {
    return MenuItemFormModel(
      name: name ?? this.name,
      description: description ?? this.description,
      priceCents: priceCents ?? this.priceCents,
      currency: currency ?? this.currency,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name.trim(),
      'description': _normalizeNullable(description),
      'price_cents': priceCents,
      'currency': currency.trim().isEmpty
          ? 'TRY'
          : currency.trim().toUpperCase(),
      'tags': tags
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList(),
      'image_url': _normalizeNullable(imageUrl),
      'is_available': isAvailable,
    };
  }

  List<String> validate() {
    final errors = <String>[];
    if (name.trim().length < 2) {
      errors.add('Ürün adı en az 2 karakter olmalıdır.');
    }
    if ((description ?? '').trim().length > 500) {
      errors.add('Açıklama en fazla 500 karakter olabilir.');
    }
    if (priceCents < 0) {
      errors.add('Fiyat 0 veya daha büyük olmalıdır.');
    }
    if (currency.trim().isEmpty) {
      errors.add('Para birimi boş olamaz.');
    }
    if (tags.length > 10) {
      errors.add('En fazla 10 etiket eklenebilir.');
    }
    for (final tag in tags) {
      if (tag.trim().isEmpty) {
        errors.add('Etiket boş olamaz.');
        break;
      }
    }
    if ((imageUrl ?? '').trim().isNotEmpty && !isValidHttpUrl(imageUrl!)) {
      errors.add('Görsel URL geçerli değil.');
    }
    return errors;
  }
}

int? parsePriceTextToCents(String raw) {
  final input = raw.trim();
  if (input.isEmpty) return null;

  final normalized = input.replaceAll(' ', '').replaceAll(',', '.');
  final value = double.tryParse(normalized);
  if (value == null || value < 0) return null;

  return (value * 100).round();
}

String formatPriceCents(int? cents) {
  if (cents == null) return '';
  final absValue = cents.abs();
  final major = absValue ~/ 100;
  final minor = absValue % 100;
  final sign = cents < 0 ? '-' : '';
  return '$sign$major.${minor.toString().padLeft(2, '0')}';
}

bool isValidHttpUrl(String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null) return false;
  return uri.hasScheme &&
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.isNotEmpty;
}

String? _normalizeNullable(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}
