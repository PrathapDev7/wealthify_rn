/// Unified income/expense transaction (the RN app's `Txn`).
class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.kind,
    required this.amount,
    required this.category,
    required this.date,
    this.subCategory,
    this.title,
    this.description,
    this.type,
    this.account,
    this.createdAt,
  });

  final String id;
  final String kind; // 'income' | 'expense'
  final num amount;
  final String category;
  final String date; // YYYY-MM-DD
  final String? subCategory;
  final String? title;
  final String? description;
  final String? type;
  final String? account;
  final String? createdAt;

  bool get isIncome => kind == 'income';

  /// [kind] may be supplied (from the income/expense endpoints) or inferred
  /// from `type` (for the combined `allData` in get-stats).
  factory TransactionModel.fromJson(Map<String, dynamic> j, {String? kind}) {
    final k = kind ?? (j['type'] == 'income' ? 'income' : 'expense');
    return TransactionModel(
      id: (j['_id'] ?? j['id'] ?? '').toString(),
      kind: k,
      amount: (j['amount'] ?? 0) as num,
      category: (j['category'] ?? '').toString(),
      date: (j['date'] ?? '').toString(),
      subCategory: j['sub_category']?.toString(),
      title: j['title']?.toString(),
      description: j['description']?.toString(),
      type: j['type']?.toString(),
      account: j['account']?.toString(),
      createdAt: j['createdAt']?.toString(),
    );
  }
}
