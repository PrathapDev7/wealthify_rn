/// User budget document: a flexible map of category-name -> limit (plus an
/// optional "Overall" key). Mirrors the backend UserBudget model.
class BudgetModel {
  const BudgetModel({this.id, this.budgets = const {}});

  final String? id;
  final Map<String, num> budgets;

  num? get overall => budgets['Overall'];

  /// Parses the `response` field returned by GET /get-budgets (may be null).
  factory BudgetModel.fromResponse(dynamic response) {
    if (response is! Map) return const BudgetModel();
    final map = <String, num>{};
    final raw = response['budgets'];
    if (raw is Map) {
      raw.forEach((key, value) {
        if (value is num) map[key.toString()] = value;
      });
    }
    return BudgetModel(id: response['_id']?.toString(), budgets: map);
  }
}
