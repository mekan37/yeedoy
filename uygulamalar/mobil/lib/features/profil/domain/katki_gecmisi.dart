class ContributionHistory {
  ContributionHistory({
    required this.menuSuggestionsCount,
    required this.priceVerificationsCount,
    required this.businessSuggestionsCount,
    required this.recentItems,
  });

  final int menuSuggestionsCount;
  final int priceVerificationsCount;
  final int businessSuggestionsCount;
  final List<ContributionHistoryItem> recentItems;
}

class ContributionHistoryItem {
  ContributionHistoryItem({
    required this.type,
    required this.title,
    required this.status,
    required this.createdAt,
  });

  final String type;
  final String title;
  final String status;
  final DateTime createdAt;
}
