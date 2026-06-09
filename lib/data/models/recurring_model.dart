class RecurringModel {
  const RecurringModel({
    required this.id,
    required this.kind,
    required this.amount,
    required this.category,
    required this.frequency,
    required this.startDate,
    required this.nextRunDate,
    this.interval = 1,
    this.subCategory,
    this.title,
    this.description,
    this.type,
    this.account,
    this.endDate,
    this.lastRunDate,
    this.active = true,
  });

  final String id;
  final String kind; // expense | income
  final num amount;
  final String category;
  final String frequency; // daily | weekly | monthly | yearly
  final int interval;
  final String startDate;
  final String nextRunDate;
  final String? subCategory;
  final String? title;
  final String? description;
  final String? type;
  final String? account;
  final String? endDate;
  final String? lastRunDate;
  final bool active;

  factory RecurringModel.fromJson(Map<String, dynamic> j) => RecurringModel(
        id: (j['_id'] ?? j['id'] ?? '').toString(),
        kind: (j['kind'] ?? 'expense').toString(),
        amount: (j['amount'] ?? 0) as num,
        category: (j['category'] ?? '').toString(),
        frequency: (j['frequency'] ?? 'monthly').toString(),
        interval: (j['interval'] ?? 1) is num ? (j['interval'] ?? 1).toInt() : 1,
        startDate: (j['startDate'] ?? '').toString(),
        nextRunDate: (j['nextRunDate'] ?? '').toString(),
        subCategory: j['sub_category']?.toString(),
        title: j['title']?.toString(),
        description: j['description']?.toString(),
        type: j['type']?.toString(),
        account: j['account']?.toString(),
        endDate: j['endDate']?.toString(),
        lastRunDate: j['lastRunDate']?.toString(),
        active: j['active'] != false,
      );
}
