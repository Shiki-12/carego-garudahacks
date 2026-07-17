class TransactionModel {
  final int id;
  final String title;
  final int amount;
  final bool isCredit;
  final DateTime date;

  const TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.isCredit,
    required this.date,
  });
}
