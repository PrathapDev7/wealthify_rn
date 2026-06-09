class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.title,
    required this.type,
    this.icon,
    this.color,
    this.archived = false,
  });

  final String id;
  final String title;
  final String type; // 'income' | 'expense'
  final String? icon;
  final String? color;
  final bool archived;

  bool get isIncome => type == 'income';

  factory CategoryModel.fromJson(Map<String, dynamic> j) => CategoryModel(
        id: (j['_id'] ?? j['id'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        type: (j['type'] ?? 'expense').toString(),
        icon: j['icon']?.toString(),
        color: j['color']?.toString(),
        archived: j['archived'] == true,
      );
}
