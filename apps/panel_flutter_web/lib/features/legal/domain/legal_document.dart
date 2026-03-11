import 'package:flutter/material.dart';

@immutable
class LegalSection {
  const LegalSection({
    required this.id,
    required this.title,
    this.paragraphs = const <String>[],
    this.bullets = const <String>[],
  });

  final String id;
  final String title;
  final List<String> paragraphs;
  final List<String> bullets;
}

@immutable
class LegalDocument {
  const LegalDocument({
    required this.slug,
    required this.title,
    required this.description,
    required this.version,
    required this.lastUpdated,
    required this.icon,
    required this.sections,
  });

  final String slug;
  final String title;
  final String description;
  final String version;
  final DateTime lastUpdated;
  final IconData icon;
  final List<LegalSection> sections;
}
