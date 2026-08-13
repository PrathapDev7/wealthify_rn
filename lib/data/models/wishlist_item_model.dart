class WishlistItemModel {
  const WishlistItemModel({
    required this.id,
    required this.title,
    required this.estimatedAmount,
    required this.priority,
    required this.category,
    required this.targetDate,
    required this.notes,
    required this.isPurchased,
    required this.createdAt,
  });

  final String id;
  final String title;
  final double? estimatedAmount;
  final String priority;
  final String category;
  final DateTime? targetDate;
  final String notes;
  final bool isPurchased;
  final DateTime createdAt;

  WishlistItemModel copyWith({
    String? id,
    String? title,
    double? estimatedAmount,
    String? priority,
    String? category,
    DateTime? targetDate,
    String? notes,
    bool? isPurchased,
    DateTime? createdAt,
  }) {
    return WishlistItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      estimatedAmount: estimatedAmount ?? this.estimatedAmount,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      targetDate: targetDate ?? this.targetDate,
      notes: notes ?? this.notes,
      isPurchased: isPurchased ?? this.isPurchased,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'estimatedAmount': estimatedAmount,
    'priority': priority,
    'category': category,
    'targetDate': targetDate?.toIso8601String(),
    'notes': notes,
    'isPurchased': isPurchased,
    'createdAt': createdAt.toIso8601String(),
  };

  factory WishlistItemModel.fromJson(Map<String, dynamic> json) {
    return WishlistItemModel(
      id: json['id'] as String,
      title: json['title'] as String,
      estimatedAmount: (json['estimatedAmount'] as num?)?.toDouble(),
      priority: json['priority'] as String? ?? 'Medium',
      category: json['category'] as String? ?? 'Other',
      targetDate: json['targetDate'] == null
          ? null
          : DateTime.tryParse(json['targetDate'] as String),
      notes: json['notes'] as String? ?? '',
      isPurchased: json['isPurchased'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
