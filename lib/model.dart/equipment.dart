class Equipment {
  final int id;
  final String name;
  final String category;
  final String description;
  final Map<String, String> specifications;
  final int dailyRate;
  final int weeklyRate;
  final int deposit;
  final int stock;
  final List<String> images;
  final bool isAvailable;

  const Equipment({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.specifications,
    required this.dailyRate,
    required this.weeklyRate,
    required this.deposit,
    required this.stock,
    required this.images,
    required this.isAvailable,
  });
}
