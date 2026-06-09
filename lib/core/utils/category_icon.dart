import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Resolved icon for a category: a WealthifyIcon glyph name + a brand color.
class CategoryIconSpec {
  const CategoryIconSpec(this.name, this.color);
  final String name;
  final Color color;
}

/// Maps a color key (as used in the RN `categoryIcon.ts`) onto the active palette.
Color _pick(AppColors c, String key) {
  switch (key) {
    case 'warning':
      return c.warning;
    case 'deepPurple':
      return c.deepPurple;
    case 'blue':
      return c.blue;
    case 'negative':
      return c.negative;
    case 'pink':
      return c.pink;
    case 'cyan':
      return c.cyan;
    case 'accentDark':
      return c.accentDark;
    case 'primary':
      return c.primary;
  }
  if (key.startsWith('cat.')) return c.categoryColor(key.substring(4));
  return c.primary;
}

// (glyphName, colorKey) — ported 1:1 from legacy_rn/src/utils/categoryIcon.ts
const Map<String, (String, String)> _expense = {
  'groceries': ('category_groceries', 'cat.groceries'),
  'grocery': ('category_groceries', 'cat.groceries'),
  'food': ('category_food', 'warning'),
  'dining': ('category_food', 'warning'),
  'restaurant': ('category_food', 'warning'),
  'restaurants': ('category_food', 'warning'),
  'travel': ('category_travel', 'cat.travel'),
  'transport': ('category_transport', 'cat.car'),
  'transportation': ('category_transport', 'cat.car'),
  'car': ('category_car', 'cat.car'),
  'fuel': ('category_fuel', 'warning'),
  'gas': ('category_gas', 'warning'),
  'petrol': ('category_fuel', 'warning'),
  'home': ('category_home', 'cat.home'),
  'rent': ('category_rent', 'cat.rent'),
  'bills': ('category_bills', 'deepPurple'),
  'bill': ('category_bills', 'deepPurple'),
  'utilities': ('category_bills', 'deepPurple'),
  'electricity': ('category_electricity', 'warning'),
  'insurance': ('category_insurance', 'cat.insurance'),
  'insurances': ('category_insurance', 'cat.insurance'),
  'education': ('category_education', 'cat.education'),
  'marketing': ('category_marketing', 'cat.marketing'),
  'shopping': ('category_shopping', 'cat.shopping'),
  'internet': ('category_internet', 'cat.internet'),
  'mobile': ('category_mobile', 'blue'),
  'phone': ('category_mobile', 'blue'),
  'healthcare': ('category_healthcare', 'negative'),
  'health': ('category_healthcare', 'negative'),
  'medical': ('category_healthcare', 'negative'),
  'entertainment': ('category_entertainment', 'pink'),
  'water': ('category_water', 'cat.water'),
  'gym': ('category_gym', 'cat.gym'),
  'subscription': ('category_subscription', 'cat.subscription'),
  'subscriptions': ('category_subscription', 'cat.subscription'),
  'gifts': ('category_gifts', 'warning'),
  'gift': ('category_gifts', 'warning'),
  'vacation': ('category_vacation', 'cat.vacation'),
  'salary': ('type_income', 'primary'),
  'bonus': ('income_bonus', 'warning'),
  'freelance': ('income_freelance', 'cyan'),
  'investment': ('income_investment', 'accentDark'),
  'other': ('income_other', 'cat.other'),
};

const Map<String, (String, String)> _income = {
  'salary': ('type_income', 'primary'),
  'bonus': ('income_bonus', 'warning'),
  'freelance': ('income_freelance', 'cyan'),
  'business': ('income_business', 'primary'),
  'sales': ('income_business', 'primary'),
  'commission': ('income_commission', 'accentDark'),
  'tips': ('earn_rewards', 'warning'),
  'investment': ('income_investment', 'accentDark'),
  'rental income': ('income_rental', 'cat.rent'),
  'rent': ('income_rental', 'cat.rent'),
  'interest': ('income_interest', 'accentDark'),
  'dividends': ('income_investment', 'accentDark'),
  'refund': ('income_refund', 'primary'),
  'reimbursement': ('income_refund', 'primary'),
  'gift': ('income_gift', 'warning'),
  'cashback': ('earn_rewards', 'warning'),
  'other': ('income_other', 'primary'),
};

CategoryIconSpec resolveCategoryIcon(
  String? category, {
  bool income = false,
  required AppColors colors,
}) {
  if (category == null || category.trim().isEmpty) {
    return CategoryIconSpec('category_other', colors.primary);
  }
  final key = category.toLowerCase().trim();
  final hit = income ? (_income[key] ?? _expense[key]) : _expense[key];
  final spec = hit ?? ('category_other', 'primary');
  return CategoryIconSpec(spec.$1, _pick(colors, spec.$2));
}
