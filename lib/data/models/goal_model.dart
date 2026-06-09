class GoalContribution {
  const GoalContribution({required this.amount, this.date, this.note});
  final num amount;
  final String? date;
  final String? note;

  factory GoalContribution.fromJson(Map<String, dynamic> j) => GoalContribution(
        amount: (j['amount'] ?? 0) as num,
        date: j['date']?.toString(),
        note: j['note']?.toString(),
      );
}

class GoalModel {
  const GoalModel({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.savedAmount = 0,
    this.targetDate,
    this.icon,
    this.color,
    this.note,
    this.completed = false,
    this.contributions = const [],
  });

  final String id;
  final String name;
  final num targetAmount;
  final num savedAmount;
  final String? targetDate;
  final String? icon;
  final String? color;
  final String? note;
  final bool completed;
  final List<GoalContribution> contributions;

  double get progress =>
      targetAmount > 0 ? (savedAmount / targetAmount).clamp(0, 1).toDouble() : 0;

  factory GoalModel.fromJson(Map<String, dynamic> j) => GoalModel(
        id: (j['_id'] ?? j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        targetAmount: (j['targetAmount'] ?? 0) as num,
        savedAmount: (j['savedAmount'] ?? 0) as num,
        targetDate: j['targetDate']?.toString(),
        icon: j['icon']?.toString(),
        color: j['color']?.toString(),
        note: j['note']?.toString(),
        completed: j['completed'] == true,
        contributions: (j['contributions'] is List)
            ? (j['contributions'] as List)
                .whereType<Map>()
                .map((e) => GoalContribution.fromJson(e.cast<String, dynamic>()))
                .toList()
            : const [],
      );
}
