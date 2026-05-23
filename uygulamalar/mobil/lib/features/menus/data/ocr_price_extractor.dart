import 'package:google_ml_kit/google_ml_kit.dart';

class OcrPriceDetection {
  const OcrPriceDetection({
    required this.line,
    required this.priceCents,
    required this.isFallback,
  });

  final String line;
  final int priceCents;
  final bool isFallback;
}

Future<List<OcrPriceDetection>> runMenuPriceOcr(String path) async {
  final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  try {
    final input = InputImage.fromFilePath(path);
    final result = await recognizer.processImage(input);
    final detections = <OcrPriceDetection>[];
    for (final block in result.blocks) {
      for (final line in block.lines) {
        final hit = _extractPrice(line.text);
        if (hit == null) continue;
        detections.add(
          OcrPriceDetection(
            line: line.text.trim(),
            priceCents: hit.cents,
            isFallback: hit.isFallback,
          ),
        );
      }
    }
    return detections;
  } finally {
    await recognizer.close();
  }
}

int? parsePriceCents(String raw) {
  final normalized = raw.replaceAll(',', '.');
  final value = double.tryParse(normalized);
  if (value == null) return null;
  if (value <= 0) return null;
  return (value * 100).round();
}

_PriceHit? _extractPrice(String text) {
  final currencyPattern = RegExp(
    r'(?:₺|TL|TRY)\\s*([0-9]{1,4}(?:[.,][0-9]{1,2})?)|([0-9]{1,4}(?:[.,][0-9]{1,2})?)\\s*(?:₺|TL|TRY)',
    caseSensitive: false,
  );
  final currencyMatch = currencyPattern.firstMatch(text);
  if (currencyMatch != null) {
    final raw = (currencyMatch.group(1) ?? currencyMatch.group(2) ?? '').trim();
    final cents = parsePriceCents(raw);
    if (cents != null) return _PriceHit(cents: cents, isFallback: false);
  }

  final fallbackPattern = RegExp(r'\b([1-9][0-9]{1,3}(?:[.,][0-9]{1,2})?)\b');
  final fallbackMatch = fallbackPattern.firstMatch(text);
  if (fallbackMatch != null) {
    final raw = fallbackMatch.group(1);
    if (raw != null) {
      final cents = parsePriceCents(raw);
      if (cents != null) return _PriceHit(cents: cents, isFallback: true);
    }
  }
  return null;
}

class _PriceHit {
  const _PriceHit({required this.cents, required this.isFallback});

  final int cents;
  final bool isFallback;
}
