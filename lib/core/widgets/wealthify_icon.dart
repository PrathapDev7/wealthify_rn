import 'package:flutter/material.dart';

/// Bundled glyph names (PNGs under assets/wealthify/glyph_256/), ported from
/// `legacy_rn/src/components/ui/WealthifyIcon.tsx`.
const Set<String> _glyphs = {
  'auth_lock', 'balance_top_up', 'wealthify_mark', 'category_add',
  'category_bills', 'category_car', 'category_education', 'category_electricity',
  'category_entertainment', 'category_food', 'category_fuel', 'category_gas',
  'category_gifts', 'category_groceries', 'category_gym', 'category_healthcare',
  'category_home', 'category_insurance', 'category_internet', 'category_marketing',
  'category_mobile', 'category_other', 'category_rent', 'category_shopping',
  'category_subscription', 'category_transport', 'category_travel',
  'category_vacation', 'category_water', 'earn_rewards', 'earn_sharing',
  'nav_account', 'nav_add', 'nav_analytics', 'nav_home', 'nav_transaction',
  'premium_account', 'spending_wallet', 'subscriptions', 'total_balance',
  'track_referrals', 'income_bonus', 'income_business', 'income_commission',
  'income_freelance', 'income_gift', 'income_interest', 'income_investment',
  'income_other', 'income_refund', 'income_rental', 'type_expense', 'type_income',
  'ui_bell', 'ui_calendar', 'ui_settings',
};

/// Lucide/Ionicons-style aliases → glyph names.
const Map<String, String> _aliases = {
  'add': 'category_add',
  'airplane': 'category_travel',
  'apps': 'category_other',
  'barbell': 'category_gym',
  'bag-handle': 'category_groceries',
  'book': 'category_education',
  'calendar': 'ui_calendar',
  'calendar-outline': 'ui_calendar',
  'car': 'category_car',
  'car-sport': 'category_car',
  'cash': 'total_balance',
  'wealthify-mark': 'wealthify_mark',
  'diamond': 'premium_account',
  'gift': 'earn_rewards',
  'home': 'category_home',
  'key': 'category_rent',
  'lock': 'auth_lock',
  'lock-closed': 'auth_lock',
  'megaphone': 'category_marketing',
  'notifications': 'category_subscription',
  'notifications-outline': 'ui_bell',
  'person': 'nav_account',
  'receipt': 'type_expense',
  'receipt-outline': 'type_expense',
  'settings': 'ui_settings',
  'settings-outline': 'ui_settings',
  'shield': 'category_insurance',
  'sunny': 'category_vacation',
  'wallet': 'spending_wallet',
  'water': 'category_water',
  'wifi': 'category_internet',
  'trending-up': 'type_income',
  'trending-down': 'type_expense',
};

String? resolveWealthifyIconName(String? name) {
  if (name == null) return null;
  if (_glyphs.contains(name)) return name;
  return _aliases[name];
}

/// Renders a Wealthify glyph from bundled assets, with a Material-icon
/// fallback if the asset is missing or the name is unknown.
class WealthifyIcon extends StatelessWidget {
  const WealthifyIcon(this.name, {super.key, this.size = 24, this.color});

  final String name;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveWealthifyIconName(name);
    if (resolved == null) {
      return Icon(Icons.category_outlined, size: size, color: color);
    }
    return Image.asset(
      'assets/wealthify/glyph_256/$resolved.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) =>
          Icon(_fallback(resolved), size: size, color: color),
    );
  }

  IconData _fallback(String n) {
    if (n == 'type_income' || n.startsWith('income')) {
      return Icons.savings_outlined;
    }
    if (n == 'type_expense') return Icons.receipt_long_outlined;
    if (n.startsWith('nav_')) return Icons.circle_outlined;
    return Icons.category_outlined;
  }
}
