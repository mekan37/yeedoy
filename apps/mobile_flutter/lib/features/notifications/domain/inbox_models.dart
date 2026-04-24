class InboxItem {
  InboxItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.targetPath,
    this.isRead = false,
    this.meta = const {},
  });

  final String id;
  final String type;
  final String title;
  final String message;
  final DateTime createdAt;
  final String targetPath;
  final bool isRead;
  final Map<String, dynamic> meta;

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'title': title,
        'message': message,
        'created_at': createdAt.toIso8601String(),
        'target_path': targetPath,
        'is_read': isRead,
        'meta': meta,
      };

  factory InboxItem.fromMap(Map<String, dynamic> map) => InboxItem(
        id: (map['id'] ?? '').toString(),
        type: (map['type'] ?? '').toString(),
        title: (map['title'] ?? '').toString(),
        message: (map['message'] ?? '').toString(),
        createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
            DateTime.now(),
        targetPath: (map['target_path'] ?? '').toString(),
        isRead: map['is_read'] == true,
        meta: (map['meta'] as Map<String, dynamic>?) ?? const {},
      );
}
