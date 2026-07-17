class Conversation {
  final int id;
  final String participantName;
  final String participantRole;
  final String participantPhotoUrl;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;

  const Conversation({
    required this.id,
    required this.participantName,
    required this.participantRole,
    required this.participantPhotoUrl,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
  });
}

class Message {
  final int id;
  final String text;
  final bool isSentByMe;
  final DateTime timestamp;
  final bool isRead;

  const Message({
    required this.id,
    required this.text,
    required this.isSentByMe,
    required this.timestamp,
    required this.isRead,
  });
}
