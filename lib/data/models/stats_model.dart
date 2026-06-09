import 'transaction_model.dart';

/// GET /get-stats → { response: { allData, total_incomes, total_expenses } }.
class StatsModel {
  const StatsModel({
    this.allData = const [],
    this.totalIncomes = 0,
    this.totalExpenses = 0,
  });

  final List<TransactionModel> allData;
  final num totalIncomes;
  final num totalExpenses;

  num get balance => totalIncomes - totalExpenses;

  factory StatsModel.fromResponse(dynamic response) {
    if (response is! Map) return const StatsModel();
    final list = (response['allData'] is List)
        ? (response['allData'] as List)
            .whereType<Map>()
            .map((e) => TransactionModel.fromJson(e.cast<String, dynamic>()))
            .toList()
        : <TransactionModel>[];
    return StatsModel(
      allData: list,
      totalIncomes: (response['total_incomes'] ?? 0) as num,
      totalExpenses: (response['total_expenses'] ?? 0) as num,
    );
  }
}
