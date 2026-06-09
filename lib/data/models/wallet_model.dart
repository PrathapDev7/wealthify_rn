class WalletModel {
  const WalletModel({
    required this.id,
    required this.name,
    required this.kind,
    this.openingBalance = 0,
    this.icon,
    this.color,
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
  final num balance; // computed server-side
  final num income;
  final num expense;

  factory WalletModel.fromJson(Map<String, dynamic> j) => WalletModel(
        id: (j['_id'] ?? j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        kind: (j['kind'] ?? 'cash').toString(),
        openingBalance: (j['openingBalance'] ?? 0) as num,
        icon: j['icon']?.toString(),
        color: j['color']?.toString(),
        balance: (j['balance'] ?? 0) as num,
        income: (j['income'] ?? 0) as num,
        expense: (j['expense'] ?? 0) as num,
      );
}
