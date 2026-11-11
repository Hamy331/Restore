import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/data/models/category_model.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_action_buttons.dart';

import '../../../models/plan_package.dart';

/// Người dùng chọn gì ở sheet thanh toán gói
sealed class PlanCheckoutResult {
  const PlanCheckoutResult();
}

/// Trả xu, kèm chuyên mục chính đã chọn
class PlanCheckoutPay extends PlanCheckoutResult {
  const PlanCheckoutPay(this.categoryId);
  final String? categoryId;
}

/// Ví không đủ xu: mở trang nạp
class PlanCheckoutTopUp extends PlanCheckoutResult {
  const PlanCheckoutTopUp();
}

/// Nội dung sheet thanh toán gói: giá, phần trừ khi nâng gói, số phải trả,
/// hạn mới, chuyên mục chính và số xu trong ví.
class PlanCheckoutSheet extends StatefulWidget {
  const PlanCheckoutSheet({
    super.key,
    required this.quote,
    required this.categories,
    this.initialCategoryId,
  });

  final PlanQuote quote;
  final List<CategoryModel> categories;
  final String? initialCategoryId;

  @override
  State<PlanCheckoutSheet> createState() => _PlanCheckoutSheetState();
}

class _PlanCheckoutSheetState extends State<PlanCheckoutSheet> {
  late String? _categoryId =
      widget.categories.any((item) => item.id == widget.initialCategoryId)
      ? widget.initialCategoryId
      : null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final quote = widget.quote;
    final missing = quote.amount - quote.available;
    final canPay = _categoryId != null || widget.categories.isEmpty;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Line(l10n.plansCheckoutPrice, l10n.plansCredits(quote.price)),
          if (quote.credit > 0)
            _Line(
              l10n.plansCheckoutCredit,
              '-${l10n.plansCredits(quote.credit)}',
            ),
          _Line(
            l10n.plansCheckoutTotal,
            l10n.plansCredits(quote.amount),
            strong: true,
          ),
          _Line(
            l10n.plansCheckoutUntil,
            DateFormat('dd/MM/yyyy').format(quote.endsAt),
          ),
          if (widget.categories.isNotEmpty) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _categoryId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.plansCheckoutCategory,
                helperText: l10n.plansCheckoutCategoryHint,
              ),
              items: [
                for (final category in widget.categories)
                  DropdownMenuItem(
                    value: category.id,
                    child: Text(category.name.of(context)),
                  ),
              ],
              onChanged: (value) => setState(() => _categoryId = value),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            missing > 0
                ? '${l10n.postingPayBalance(quote.available)} · '
                      '${l10n.postingPayMissing(missing)}'
                : l10n.postingPayBalance(quote.available),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: missing > 0 ? AppColors.error : AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppSecondaryActionButton(
                  label: l10n.postingLater,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: quote.enough
                    ? AppPrimaryActionButton(
                        label: l10n.plansPay(quote.amount),
                        icon: AppIcons.wallet,
                        onPressed: canPay
                            ? () => Navigator.of(
                                context,
                              ).pop(PlanCheckoutPay(_categoryId))
                            : null,
                      )
                    : AppPrimaryActionButton(
                        label: l10n.postingTopUp,
                        icon: AppIcons.wallet,
                        onPressed: () => Navigator.of(
                          context,
                        ).pop(const PlanCheckoutTopUp()),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.strong = false});
  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: strong ? 16 : 14,
            fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
            color: strong ? AppColors.primaryDark : AppColors.textPrimary,
          ),
        ),
      ],
    ),
  );
}
