import '../core/api_service.dart';
import '../model.dart/order_model.dart';

class OrderService {
  final ApiService api;

  OrderService(this.api);

  Future<List<OrderModel>> getOrders() async {
    try {
      final response = await api.post('/bookings/list');
      if (response != null && response['bookings'] != null) {
        return (response['bookings'] as List).map((json) => OrderModel(
          id: json['id'],
          serviceType: json['serviceType'] ?? '',
          providerName: json['providerName'] ?? '',
          status: json['status'] ?? '',
          totalPrice: json['totalPrice'] ?? 0,
          date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
          pickupAddress: json['pickupAddress'] ?? '',
          destinationAddress: json['destinationAddress'],
          notes: json['notes'] ?? '',
        )).toList();
      }
    } catch (e) {
      print('OrderService getOrders error: $e');
    }
    return [];
  }
}
