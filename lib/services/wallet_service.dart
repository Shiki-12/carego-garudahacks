import '../core/api_service.dart';
import '../model.dart/transaction_model.dart';

class WalletService {
  final ApiService api;

  WalletService(this.api);

  Future<List<TransactionModel>> getTransactions() async {
    try {
      final response = await api.get('/wallet/transactions');
      if (response != null && response['transactions'] != null) {
        return (response['transactions'] as List).map((json) => TransactionModel(
          id: json['id'],
          title: json['title'] ?? json['description'] ?? 'Transaksi',
          amount: json['amount'] ?? 0,
          isCredit: json['type'] == 'credit',
          date: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        )).toList();
      }
    } catch (e) {
      print('WalletService error: $e');
    }
    return [];
  }
}
