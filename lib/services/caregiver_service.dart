import '../core/api_service.dart';
import '../model.dart/caregiver.dart';

class CaregiverService {
  final ApiService api;

  CaregiverService(this.api);

  Future<List<Caregiver>> getCaregivers() async {
    final response = await api.get('/caregiver/list');
    if (response != null && response['caregivers'] != null) {
      return (response['caregivers'] as List).map((json) => Caregiver(
        id: json['id'],
        name: json['name'] ?? '',
        specialization: json['specialization'] ?? '',
        experienceYears: json['experienceYears'] ?? 0,
        hourlyRate: json['hourlyRate'] ?? 0,
        rating: (json['rating'] ?? 0.0).toDouble(),
        reviews: json['reviews'] ?? 0,
        photoUrl: json['photoUrl'] ?? 'assets/images/doctor_1.png',
        isAvailable: json['isAvailable'] ?? false,
        bio: json['bio'] ?? '',
      )).toList();
    }
    return [];
  }
}
