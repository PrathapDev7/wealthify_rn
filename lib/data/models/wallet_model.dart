class WalletModel {
  const WalletModel({
    required this.id,
    required this.name,
    required this.kind,
    this.openingBalance = 0,
    this.icon,
    this.color,
    this.provider,
    this.providerName,
    this.cardType,
    this.last4,
    this.holderName,
    this.reminderDay,
    this.expiry,
    this.balance = 0,
    this.income = 0,
    this.expense = 0,
  });

  final String id;
  final String name;
  final String kind; // cash | bank | card | wallet
  final num openingBalance;
  final String? icon;
  final String? color;
  final String? provider; // catalog id, e.g. 'hdfc' / 'paytm'
  final String? providerName; // display name, e.g. 'HDFC Bank'
  final String? cardType; // '' | credit | debit (kind == card)
  final String? last4; // optional last 4 digits (any kind)
  final String? holderName; // optional account/card holder name
  final int? reminderDay; // optional 1..31 bill-reminder day (cards)
  final String? expiry; // optional MM/YY (cards)
  final num balance; // computed server-side
  final num income;
  final num expense;

  bool get isCard => kind == 'card';

  factory WalletModel.fromJson(Map<String, dynamic> j) => WalletModel(
        id: (j['_id'] ?? j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        kind: (j['kind'] ?? 'cash').toString(),
        openingBalance: (j['openingBalance'] ?? 0) as num,
        icon: _str(j['icon']),
        color: _str(j['color']),
        provider: _str(j['provider']),
        providerName: _str(j['providerName']),
        cardType: _str(j['cardType']),
        last4: _str(j['last4']),
        holderName: _str(j['holderName']),
        reminderDay: (j['reminderDay'] as num?)?.toInt(),
        expiry: _str(j['expiry']),
        balance: (j['balance'] ?? 0) as num,
        income: (j['income'] ?? 0) as num,
        expense: (j['expense'] ?? 0) as num,
      );
}

/// Trims a dynamic JSON value to a non-empty String, or null.
String? _str(dynamic v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}
