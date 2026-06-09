class InsightCategory {
  const InsightCategory({
    required this.name,
    required this.current,
    required this.previous,
    required this.delta,
    required this.deltaPct,
  });

  final String name;
  final num current;
  final num previous;
  final num delta;
  final num deltaPct;

  factory InsightCategory.fromJson(Map<String, dynamic> j) => InsightCategory(
        name: (j['name'] ?? '').toString(),
        current: (j['current'] ?? 0) as num,
        previous: (j['previous'] ?? 0) as num,
        delta: (j['delta'] ?? 0) as num,
        deltaPct: (j['deltaPct'] ?? 0) as num,
      );
}

class InsightsModel {
  const InsightsModel({
    this.month = '',
    this.currentExpense = 0,
    this.currentIncome = 0,
    this.savings = 0,
    this.savingsRate = 0,
    this.previousExpense = 0,
    this.expenseDelta = 0,
    this.expenseDeltaPct = 0,
    this.projectedExpense = 0,
    this.topCategories = const [],
    this.movers = const [],
  });

  final String month;
  final num currentExpense;
  final num currentIncome;
  final num savings;
  final num savingsRate;
  final num previousExpense;
  final num expenseDelta;
  final num expenseDeltaPct;
  final num projectedExpense;
  final List<InsightCategory> topCategories;
  final List<InsightCategory> movers;

  static List<InsightCategory> _cats(dynamic v) => (v is List)
      ? v
          .whereType<Map>()
          .map((e) => InsightCategory.fromJson(e.cast<String, dynamic>()))
          .toList()
      : const [];

  factory InsightsModel.fromData(dynamic data) {
    if (data is! Map) return const InsightsModel();
    final current = (data['current'] is Map) ? data['current'] as Map : const {};
    final previous = (data['previous'] is Map) ? data['previous'] as Map : const {};
    return InsightsModel(
      month: (data['month'] ?? '').toString(),
      currentExpense: (current['expense'] ?? 0) as num,
      currentIncome: (current['income'] ?? 0) as num,
      savings: (current['savings'] ?? 0) as num,
      savingsRate: (current['savingsRate'] ?? 0) as num,
      previousExpense: (previous['expense'] ?? 0) as num,
      expenseDelta: (data['expenseDelta'] ?? 0) as num,
      expenseDeltaPct: (data['expenseDeltaPct'] ?? 0) as num,
      projectedExpense: (data['projectedExpense'] ?? 0) as num,
      topCategories: _cats(data['topCategories']),
      movers: _cats(data['movers']),
    );
  }
}
