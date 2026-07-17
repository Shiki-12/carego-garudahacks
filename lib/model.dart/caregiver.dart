class Caregiver {
  final int id;
  final String name;
  final String specialization;
  final int experienceYears;
  final int hourlyRate;
  final double rating;
  final int reviews;
  final String photoUrl;
  final bool isAvailable;
  final String bio;

  Caregiver({
    required this.id,
    required this.name,
    required this.specialization,
    required this.experienceYears,
    required this.hourlyRate,
    required this.rating,
    required this.reviews,
    required this.photoUrl,
    required this.isAvailable,
    required this.bio,
  });
}
