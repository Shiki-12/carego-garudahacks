class OrderModel {
  final int id;
  final String serviceType;
  final String providerName;
  final String status;
  final int totalPrice;
  final DateTime date;
  final String pickupAddress;
  final String? destinationAddress;
  final String notes;

  const OrderModel({
    required this.id,
    required this.serviceType,
    required this.providerName,
    required this.status,
    required this.totalPrice,
    required this.date,
    required this.pickupAddress,
    this.destinationAddress,
    required this.notes,
  });
}
