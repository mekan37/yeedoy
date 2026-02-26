import 'dart:async';

import 'package:flutter/services.dart';

import '../errors/app_error_codes.dart';

class ContentModerationResult {
  const ContentModerationResult({required this.code, required this.message});

  final String code;
  final String message;
}

class ContentModeration {
  ContentModeration._();

  static final ContentModeration instance = ContentModeration._();

  static const _blacklistAsset = 'assets/json/karaliste.txt';
  static const _minContentLength = 8;
  static const _maxEmojiCount = 6;

  Future<ContentModerationResult?> validateReview({
    required String content,
    String? title,
  }) async {
    if (content.trim().length < _minContentLength) {
      return const ContentModerationResult(
        code: AppErrorCodes.contentTooShort,
        message: 'Yorum en az 8 karakter olmali.',
      );
    }

    final risky = await _validateText(content);
    if (risky != null) return risky;

    if (title != null && title.trim().isNotEmpty) {
      final titleRisk = await _validateText(title);
      if (titleRisk != null) return titleRisk;
    }

    return null;
  }

  Future<ContentModerationResult?> validateNote(String text) async {
    if (text.trim().isEmpty) return null;
    return _validateText(text);
  }

  Future<ContentModerationResult?> _validateText(String text) async {
    if (_containsLinkPhoneOrEmail(text)) {
      return const ContentModerationResult(
        code: AppErrorCodes.containsLinkOrPhone,
        message: 'Link, e-posta veya telefon paylasamazsin.',
      );
    }

    if (_isEmojiSpam(text)) {
      return const ContentModerationResult(
        code: AppErrorCodes.emojiSpam,
        message: 'Çok fazla emoji kullanımı tespit edildi.',
      );
    }

    if (_hasRepeatedJunk(text)) {
      return const ContentModerationResult(
        code: AppErrorCodes.emojiSpam,
        message: 'Tekrarlayan spam icerik tespit edildi.',
      );
    }

    if (_containsObfuscatedProfanity(text) ||
        await _containsBlacklistedTerm(text)) {
      return const ContentModerationResult(
        code: AppErrorCodes.containsProfanity,
        message: 'Uygunsuz içerik tespit edildi.',
      );
    }

    return null;
  }

  bool _containsLinkPhoneOrEmail(String text) {
    final pattern = RegExp(
      r'(https?://|www\.|t\.me/|wa\.me/|instagram\.com/|[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}|(\+?\d[\d\s\-\(\)]{7,}\d))',
      caseSensitive: false,
    );
    return pattern.hasMatch(text);
  }

  bool _isEmojiSpam(String text) {
    final emojiPattern = RegExp(
      r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]',
      unicode: true,
    );
    final matches = emojiPattern.allMatches(text);
    if (matches.length >= _maxEmojiCount) return true;

    final nonWord = text.replaceAll(RegExp(r'[A-Za-z0-9\s\u00C0-\u017F]'), '');
    return nonWord.length >= 10;
  }

  bool _hasRepeatedJunk(String text) {
    final normalized = text.trim();
    if (normalized.isEmpty) return false;
    if (RegExp(r'(.)\1{5,}').hasMatch(normalized)) return true;
    if (RegExp(r'([!?.,])\1{4,}').hasMatch(normalized)) return true;
    if (RegExp(
      r'\b(\w{2,})\b(?:\s+\1\b){3,}',
      caseSensitive: false,
    ).hasMatch(normalized)) {
      return true;
    }
    return false;
  }

  bool _containsObfuscatedProfanity(String text) {
    final normalized = _normalizeForSearch(text);
    final compact = normalized.replaceAll(' ', '');

    if (RegExp(
      r'(^| )a\s*m\s*k( |$)',
      caseSensitive: false,
    ).hasMatch(normalized)) {
      return true;
    }

    if (RegExp(
      r'(amk|amq|aq|siktir|sikik|sikicem|orospu|orosbu|pic|yarrak|gavat|ibne|gotveren)',
      caseSensitive: false,
    ).hasMatch(compact)) {
      return true;
    }

    return false;
  }

  Future<bool> _containsBlacklistedTerm(String text) async {
    final blacklist = await _loadBlacklist();
    if (blacklist.isEmpty) return false;

    final raw = text.toLowerCase();
    final normalizedText = _normalizeForSearch(raw);
    final compactText = normalizedText.replaceAll(' ', '');

    for (final term in blacklist) {
      if (term.isEmpty) continue;

      final t = term.toLowerCase();
      if (raw.contains(t)) return true;

      final normalizedTerm = _normalizeForSearch(t);
      if (normalizedTerm.isEmpty) continue;
      if (normalizedText.contains(normalizedTerm)) return true;

      final compactTerm = normalizedTerm.replaceAll(' ', '');
      if (compactTerm.isNotEmpty && compactText.contains(compactTerm)) {
        return true;
      }
    }

    return false;
  }

  String _normalizeForSearch(String text) {
    var s = text.toLowerCase();
    s = s
        .replaceAll('\u00e7', 'c')
        .replaceAll('\u011f', 'g')
        .replaceAll('\u0131', 'i')
        .replaceAll('\u00f6', 'o')
        .replaceAll('\u015f', 's')
        .replaceAll('\u00fc', 'u')
        .replaceAll('@', 'a')
        .replaceAll('4', 'a')
        .replaceAll('0', 'o')
        .replaceAll('1', 'i')
        .replaceAll('!', 'i')
        .replaceAll('5', 's')
        .replaceAll(r'$', 's')
        .replaceAll('3', 'e');
    return s.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }

  static Future<List<String>>? _blacklistCache;

  Future<List<String>> _loadBlacklist() {
    return _blacklistCache ??= _readBlacklist();
  }

  static Future<List<String>> _readBlacklist() async {
    try {
      final raw = await rootBundle.loadString(_blacklistAsset);
      return raw
          .split('\n')
          .map((line) => line.trim().toLowerCase())
          .where((line) => line.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }
}

