class DailyMicroTask {
  DailyMicroTask({
    required this.taskKey,
    required this.title,
    required this.description,
    required this.currentValue,
    required this.targetValue,
    required this.completed,
  });

  final String taskKey;
  final String title;
  final String description;
  final int currentValue;
  final int targetValue;
  final bool completed;

  double get progress {
    if (targetValue <= 0) return 0;
    return (currentValue / targetValue).clamp(0.0, 1.0);
  }

  factory DailyMicroTask.fromMap(Map<String, dynamic> map) {
    return DailyMicroTask(
      taskKey: (map['task_key'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      currentValue: (map['current_value'] as num?)?.toInt() ?? 0,
      targetValue: (map['target_value'] as num?)?.toInt() ?? 1,
      completed: map['completed'] == true,
    );
  }
}
