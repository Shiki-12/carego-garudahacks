import '../core/api_service.dart';
import '../model.dart/chat_model.dart';

class ChatService {
  final ApiService api;

  ChatService(this.api);

  Future<List<Conversation>> getConversations() async {
    try {
      final response = await api.get('/chat/conversations');
      if (response != null && response['conversations'] != null) {
        return (response['conversations'] as List).map((json) => Conversation(
          id: json['id'],
          participantName: json['participantName'] ?? '',
          participantRole: json['participantRole'] ?? '',
          participantPhotoUrl: json['participantPhotoUrl'] ?? 'assets/images/person.png',
          lastMessage: json['lastMessage'] ?? '',
          lastMessageTime: DateTime.tryParse(json['lastMessageTime'] ?? '') ?? DateTime.now(),
          unreadCount: json['unreadCount'] ?? 0,
        )).toList();
      }
    } catch (e) {
      print('ChatService error: $e');
    }
    return [];
  }
}
