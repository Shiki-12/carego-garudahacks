import '../core/api_service.dart';
import '../model.dart/equipment.dart';

class RentalService {
  final ApiService api;

  RentalService(this.api);

  Future<List<Equipment>> getEquipments() async {
    final response = await api.get('/rental/equipment');
    if (response != null && response['equipments'] != null) {
      return (response['equipments'] as List).map((json) => Equipment(
        id: json['id'],
        name: json['name'] ?? '',
        category: json['category'] ?? '',
        description: json['description'] ?? '',
        specifications: Map<String, String>.from(json['specifications'] ?? {}),
        dailyRate: json['dailyRate'] ?? 0,
        weeklyRate: json['weeklyRate'] ?? 0,
        deposit: json['deposit'] ?? 0,
        stock: json['stock'] ?? 0,
        images: (json['images'] as List?)?.map((e) => e.toString()).toList() ?? ['assets/images/doctor_1.png'],
        isAvailable: json['isAvailable'] ?? false,
      )).toList();
    }
    return [];
  }
}
