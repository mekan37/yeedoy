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
}
