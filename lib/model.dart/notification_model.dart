class NotificationItem {
  final int id;
  final String type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.isRead,
  });

  NotificationItem copyWith({
    bool? isRead,
  }) {
    return NotificationItem(
      id: id,
      type: type,
      title: title,
      message: message,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}

class NotificationPreferences {
  final bool bookingUpdates;
  final bool promotions;
  final bool systemUpdates;
  final bool chatMessages;

  const NotificationPreferences({
    required this.bookingUpdates,
    required this.promotions,
    required this.systemUpdates,
    required this.chatMessages,
  });
}
