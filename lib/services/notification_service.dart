import '../core/api_service.dart';
import '../model.dart/notification_model.dart';

class NotificationService {
  final ApiService api;

  NotificationService(this.api);

  Future<List<NotificationItem>> getNotifications() async {
    try {
      final response = await api.post('/notifications/list');
      if (response != null && response['notifications'] != null) {
        return (response['notifications'] as List).map((json) => NotificationItem(
          id: json['id'],
          type: json['type'] ?? 'system',
          title: json['title'] ?? '',
          message: json['message'] ?? '',
          timestamp: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
          isRead: json['isRead'] ?? false,
        )).toList();
      }
    } catch (e) {
      print('NotificationService error: $e');
    }
    return [];
  }
}
