class OwnerOnboardingProgress {
  const OwnerOnboardingProgress({
    required this.stepCompleted,
    required this.updatedAt,
  });

  final int stepCompleted;
  final DateTime? updatedAt;
}

class OwnerBusinessProfile {
  const OwnerBusinessProfile({
    required this.logoUrl,
    required this.coverUrl,
  });

  final String logoUrl;
  final String coverUrl;
}

class OwnerBusinessHours {
  const OwnerBusinessHours({
    required this.openTime,
    required this.closeTime,
  });

  final String? openTime;
  final String? closeTime;
}

class OwnerOnboardingMenuStatus {
  const OwnerOnboardingMenuStatus({
    required this.menuCount,
    required this.sectionCount,
    required this.itemCount,
    required this.primaryMenuId,
    required this.primaryMenuTitle,
  });

  final int menuCount;
  final int sectionCount;
  final int itemCount;
  final String? primaryMenuId;
  final String? primaryMenuTitle;

  bool get isComplete => sectionCount > 0 && itemCount > 0;
}

class OwnerOnboardingMenuPreview {
  const OwnerOnboardingMenuPreview({
    required this.menuId,
    required this.menuTitle,
    required this.sections,
  });

  final String menuId;
  final String menuTitle;
  final List<OwnerOnboardingMenuSection> sections;
}

class OwnerOnboardingMenuSection {
  const OwnerOnboardingMenuSection({
    required this.id,
    required this.title,
    required this.items,
  });

  final String id;
  final String title;
  final List<OwnerOnboardingMenuItem> items;
}

class OwnerOnboardingMenuItem {
  const OwnerOnboardingMenuItem({
    required this.name,
    required this.description,
    required this.priceCents,
    required this.currency,
  });

  final String name;
  final String description;
  final int? priceCents;
  final String? currency;
}

class OwnerBusinessProfileScore {
  const OwnerBusinessProfileScore({
    required this.score,
    required this.breakdown,
  });

  final int score;
  final Map<String, dynamic> breakdown;
}


