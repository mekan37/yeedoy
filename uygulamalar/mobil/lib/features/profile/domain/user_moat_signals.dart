class UserMoatSignals {
  const UserMoatSignals({
    required this.trustScore,
    required this.trustedActions,
    required this.rejectedActions,
    required this.spamSignals,
    required this.accuracyScore,
    required this.primarySegment,
    required this.priceActions,
    required this.discoveryActions,
    required this.photoActions,
    required this.silentQualityScore,
    required this.isSilentQuality,
    required this.approvedCount,
    required this.contributionCount,
  });

  final int trustScore;
  final int trustedActions;
  final int rejectedActions;
  final int spamSignals;
  final int accuracyScore;
  final String primarySegment;
  final int priceActions;
  final int discoveryActions;
  final int photoActions;
  final int silentQualityScore;
  final bool isSilentQuality;
  final int approvedCount;
  final int contributionCount;

  factory UserMoatSignals.fromMaps({
    required Map<String, dynamic> trust,
    required Map<String, dynamic> segment,
    required Map<String, dynamic> silent,
  }) {
    return UserMoatSignals(
      trustScore: ((trust['trust_score'] as num?) ?? 0).toInt(),
      trustedActions: ((trust['trusted_actions'] as num?) ?? 0).toInt(),
      rejectedActions: ((trust['rejected_actions'] as num?) ?? 0).toInt(),
      spamSignals: ((trust['spam_signals'] as num?) ?? 0).toInt(),
      accuracyScore: ((trust['accuracy_score'] as num?) ?? 0).toInt(),
      primarySegment: (segment['primary_segment'] ?? 'balanced').toString(),
      priceActions: ((segment['price_actions'] as num?) ?? 0).toInt(),
      discoveryActions: ((segment['discovery_actions'] as num?) ?? 0).toInt(),
      photoActions: ((segment['photo_actions'] as num?) ?? 0).toInt(),
      silentQualityScore: ((silent['silent_quality_score'] as num?) ?? 0)
          .toInt(),
      isSilentQuality: silent['is_silent_quality'] == true,
      approvedCount: ((silent['approved_count'] as num?) ?? 0).toInt(),
      contributionCount: ((silent['contribution_count'] as num?) ?? 0).toInt(),
    );
  }
}
