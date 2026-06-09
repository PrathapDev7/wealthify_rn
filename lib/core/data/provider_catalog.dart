import 'package:flutter/material.dart';

/// A bank or digital-wallet brand in the curated India catalog.
///
/// The catalog is bundled in-app (no network) per the product decision. Each
/// entry renders as a brand-colored badge with a short monogram via
/// [ProviderAvatar]; drop a real logo into `assets/banks/<id>.png` later and
/// point [ProviderAvatar] at it to upgrade without touching call sites.
class FinProvider {
  const FinProvider(
    this.id,
    this.name,
    this.short,
    this.type,
    this.colorValue, {
    this.popular = false,
  });

  final String id;
  final String name;
  final String short; // monogram for the badge, e.g. 'HDFC', 'SBI', 'PT'
  final String type; // 'bank' | 'wallet'
  final int colorValue; // 0xFFRRGGBB brand color
  final bool popular; // shown inline in the chips row

  Color get color => Color(colorValue);
}

/// Maps a wallet [kind] to the catalog provider type. Cards pick from banks.
String providerTypeForKind(String kind) =>
    kind == 'wallet' ? 'wallet' : 'bank';

/// Curated catalog of major Indian banks + digital wallets. Anything not listed
/// is still usable as a free-typed name (rendered with an initials badge).
const List<FinProvider> kProviders = [
  // ---------------------------- Banks ----------------------------
  FinProvider('sbi', 'State Bank of India', 'SBI', 'bank', 0xFF22A0DD, popular: true),
  FinProvider('hdfc', 'HDFC Bank', 'HDFC', 'bank', 0xFF004C8F, popular: true),
  FinProvider('icici', 'ICICI Bank', 'ICICI', 'bank', 0xFFAE282E, popular: true),
  FinProvider('axis', 'Axis Bank', 'AXIS', 'bank', 0xFF97144D, popular: true),
  FinProvider('kotak', 'Kotak Mahindra Bank', 'KOTAK', 'bank', 0xFFEF3E42, popular: true),
  FinProvider('pnb', 'Punjab National Bank', 'PNB', 'bank', 0xFFB5121B, popular: true),
  FinProvider('bob', 'Bank of Baroda', 'BOB', 'bank', 0xFFF37021, popular: true),
  FinProvider('canara', 'Canara Bank', 'CAN', 'bank', 0xFF00548E, popular: true),
  FinProvider('idfc', 'IDFC FIRST Bank', 'IDFC', 'bank', 0xFF9C1D26, popular: true),
  FinProvider('union', 'Union Bank of India', 'UBI', 'bank', 0xFFC8102E, popular: true),
  FinProvider('yes', 'YES Bank', 'YES', 'bank', 0xFF1A4F8B),
  FinProvider('indusind', 'IndusInd Bank', 'IIB', 'bank', 0xFF98272B),
  FinProvider('federal', 'Federal Bank', 'FED', 'bank', 0xFF003D7A),
  FinProvider('rbl', 'RBL Bank', 'RBL', 'bank', 0xFFC8102E),
  FinProvider('au', 'AU Small Finance Bank', 'AU', 'bank', 0xFF6E2B62),
  FinProvider('bandhan', 'Bandhan Bank', 'BAN', 'bank', 0xFFA6093D),
  FinProvider('idbi', 'IDBI Bank', 'IDBI', 'bank', 0xFF006A4D),
  FinProvider('boi', 'Bank of India', 'BOI', 'bank', 0xFF003F87),
  FinProvider('central', 'Central Bank of India', 'CBI', 'bank', 0xFF6F2C91),
  FinProvider('indian', 'Indian Bank', 'IB', 'bank', 0xFF1F3B73),
  FinProvider('iob', 'Indian Overseas Bank', 'IOB', 'bank', 0xFF1B4D9B),
  FinProvider('uco', 'UCO Bank', 'UCO', 'bank', 0xFF00529B),
  FinProvider('maharashtra', 'Bank of Maharashtra', 'BOM', 'bank', 0xFFF58220),
  FinProvider('psb', 'Punjab & Sind Bank', 'PSB', 'bank', 0xFFC8102E),
  FinProvider('southindian', 'South Indian Bank', 'SIB', 'bank', 0xFFE03A3E),
  FinProvider('karnataka', 'Karnataka Bank', 'KBL', 'bank', 0xFFED1C24),
  FinProvider('kvb', 'Karur Vysya Bank', 'KVB', 'bank', 0xFF00529B),
  FinProvider('tmb', 'Tamilnad Mercantile Bank', 'TMB', 'bank', 0xFF1B4D9B),
  FinProvider('cityunion', 'City Union Bank', 'CUB', 'bank', 0xFFE4002B),
  FinProvider('dcb', 'DCB Bank', 'DCB', 'bank', 0xFF00A4E4),
  FinProvider('csb', 'CSB Bank', 'CSB', 'bank', 0xFF1F4E79),
  FinProvider('jk', 'Jammu & Kashmir Bank', 'JKB', 'bank', 0xFFED1C24),
  FinProvider('dhanlaxmi', 'Dhanlaxmi Bank', 'DHAN', 'bank', 0xFFE4002B),
  FinProvider('equitas', 'Equitas Small Finance Bank', 'EQ', 'bank', 0xFFF58220),
  FinProvider('ujjivan', 'Ujjivan Small Finance Bank', 'UJ', 'bank', 0xFFC8102E),
  FinProvider('jana', 'Jana Small Finance Bank', 'JANA', 'bank', 0xFF00A14B),
  FinProvider('citi', 'Citibank', 'CITI', 'bank', 0xFF003B70),
  FinProvider('hsbc', 'HSBC', 'HSBC', 'bank', 0xFFDB0011),
  FinProvider('sc', 'Standard Chartered', 'SC', 'bank', 0xFF0473EA),
  FinProvider('dbs', 'DBS Bank', 'DBS', 'bank', 0xFFFF6600),
  FinProvider('deutsche', 'Deutsche Bank', 'DB', 'bank', 0xFF0018A8),

  // --------------------------- Wallets ---------------------------
  FinProvider('paytm', 'Paytm', 'PT', 'wallet', 0xFF00BAF2, popular: true),
  FinProvider('phonepe', 'PhonePe', 'PP', 'wallet', 0xFF5F259F, popular: true),
  FinProvider('gpay', 'Google Pay', 'GP', 'wallet', 0xFF4285F4, popular: true),
  FinProvider('amazonpay', 'Amazon Pay', 'AP', 'wallet', 0xFFFF9900, popular: true),
  FinProvider('mobikwik', 'MobiKwik', 'MK', 'wallet', 0xFFE1262D, popular: true),
  FinProvider('bhim', 'BHIM UPI', 'BHIM', 'wallet', 0xFF00788C, popular: true),
  FinProvider('freecharge', 'Freecharge', 'FC', 'wallet', 0xFFF47216),
  FinProvider('airtel', 'Airtel Payments Bank', 'AIR', 'wallet', 0xFFE40000),
  FinProvider('jio', 'Jio Money', 'JIO', 'wallet', 0xFF0F3CC9),
  FinProvider('payzapp', 'PayZapp', 'PZ', 'wallet', 0xFF004C8F),
  FinProvider('olamoney', 'Ola Money', 'OLA', 'wallet', 0xFF6DBE45),
  FinProvider('whatsapp', 'WhatsApp Pay', 'WA', 'wallet', 0xFF25D366),
  FinProvider('cred', 'CRED', 'CRED', 'wallet', 0xFF111111),
  FinProvider('slice', 'slice', 'SL', 'wallet', 0xFF5A00F0),
];

List<FinProvider> providersFor(String type) =>
    kProviders.where((p) => p.type == type).toList();

List<FinProvider> popularProviders(String type) =>
    kProviders.where((p) => p.type == type && p.popular).toList();

List<FinProvider> searchProviders(String type, String query) {
  final q = query.trim().toLowerCase();
  final list = providersFor(type);
  if (q.isEmpty) return list;
  return list
      .where((p) =>
          p.name.toLowerCase().contains(q) ||
          p.short.toLowerCase().contains(q))
      .toList();
}

FinProvider? providerById(String? id) {
  if (id == null || id.isEmpty) return null;
  for (final p in kProviders) {
    if (p.id == id) return p;
  }
  return null;
}

/// A square brand badge for a provider. Renders the brand color + monogram.
///
/// Resolution order: explicit [provider] → looked-up by nothing → the [label]'s
/// initials over [color] → an [icon] (e.g. cash) when there's no text at all.
class ProviderAvatar extends StatelessWidget {
  const ProviderAvatar({
    super.key,
    this.provider,
    this.label,
    this.color,
    this.size = 40,
    this.icon,
  });

  final FinProvider? provider;
  final String? label;
  final Color? color;
  final double size;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = provider;
    final bg = p?.color ?? color ?? const Color(0xFF6C5CE7);
    final text = p?.short ?? _initials(label);
    final showIcon = text.isEmpty && icon != null;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bg, _darken(bg)],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: showIcon
          ? Icon(icon, size: size * 0.5, color: Colors.white)
          : Text(
              text,
              maxLines: 1,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: _fontFor(text, size),
                letterSpacing: 0.2,
              ),
            ),
    );
  }
}

String _initials(String? label) {
  final s = (label ?? '').trim();
  if (s.isEmpty) return '';
  final parts = s.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (parts.isEmpty) return '';
  if (parts.length == 1) {
    final w = parts.first;
    return (w.length >= 2 ? w.substring(0, 2) : w).toUpperCase();
  }
  return (parts[0][0] + parts[1][0]).toUpperCase();
}

Color _darken(Color c, [double amount = 0.12]) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
}

double _fontFor(String text, double size) {
  final n = text.length;
  if (n <= 2) return size * 0.36;
  if (n == 3) return size * 0.30;
  if (n == 4) return size * 0.24;
  return size * 0.20;
}
