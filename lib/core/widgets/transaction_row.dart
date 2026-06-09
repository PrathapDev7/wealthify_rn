import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/transaction_model.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../utils/category_icon.dart';
import 'app_card.dart';
import 'wealthify_icon.dart';

class TransactionRow extends StatelessWidget {
  const TransactionRow({
    super.key,
    required this.txn,
    required this.money,
    this.onTap,
  });

  final TransactionModel txn;
  final String Function(num?) money;
  final VoidCallback? onTap;

  String _formatDate(String raw) {
    final d = DateTime.tryParse(raw);
    if (d == null) return raw;
    return DateFormat('dd MMM yyyy').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final spec = resolveCategoryIcon(txn.category, income: txn.isIncome, colors: c);
    final label = txn.isIncome
        ? ((txn.title?.isNotEmpty ?? false) ? txn.title! : txn.category)
        : txn.category;
    final amountColor = txn.isIncome ? c.accentDark : c.negative;
    final amountText = '${txn.isIncome ? '+' : '-'}${money(txn.amount)}';

    return AppCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: spec.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Center(child: WealthifyIcon(spec.name, size: 24)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodyMedium.copyWith(color: c.text)),
                const SizedBox(height: 2),
                Text(_formatDate(txn.date),
                    style: AppText.caption.copyWith(color: c.textSubtle)),
              ],
            ),
          ),
          Text(amountText,
              style: AppText.bodyStrong.copyWith(color: amountColor)),
        ],
      ),
    );
  }
}
