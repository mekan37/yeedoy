class WeeklyMissions {
  WeeklyMissions({
    required this.weekStart,
    required this.reviewsDone,
    required this.visitsDone,
    required this.votesDone,
    required this.reviewsGoal,
    required this.visitsGoal,
    required this.votesGoal,
    required this.completedCount,
  });

  final DateTime weekStart;
  final int reviewsDone;
  final int visitsDone;
  final int votesDone;

  final int reviewsGoal;
  final int visitsGoal;
  final int votesGoal;

  final int completedCount;

  factory WeeklyMissions.fromMap(Map<String, dynamic> m) => WeeklyMissions(
    weekStart: DateTime.parse(m['week_start'].toString()),
    reviewsDone: (m['reviews_done'] as num?)?.toInt() ?? 0,
    visitsDone: (m['visits_done'] as num?)?.toInt() ?? 0,
    votesDone: (m['votes_done'] as num?)?.toInt() ?? 0,
    reviewsGoal: (m['reviews_goal'] as num?)?.toInt() ?? 1,
    visitsGoal: (m['visits_goal'] as num?)?.toInt() ?? 3,
    votesGoal: (m['votes_goal'] as num?)?.toInt() ?? 3,
    completedCount: (m['completed_count'] as num?)?.toInt() ?? 0,
  );
}
