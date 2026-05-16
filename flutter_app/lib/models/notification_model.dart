class AppNotification {
  final String id;
  final String type;
  final String message;
  final String? refId;
  final bool read;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.message,
    this.refId,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['_id'] ?? json['id'] ?? '',
      type: json['type'] ?? '',
      message: json['message'] ?? '',
      refId: json['refId'],
      read: json['read'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}
