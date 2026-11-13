import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/glass/app_glass_container.dart';

import '../../../bloc/credit_topup/credit_topup_cubit.dart';
import '../../../bloc/credit_topup/credit_topup_state.dart';
import '../../../utils/credit_format.dart';

/// Bước 4: thành công / đang chờ xác nhận / thất bại, kèm thông tin đơn
class TopupResultSection extends StatelessWidget {
  const TopupResultSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = context.watch<CreditTopupCubit>().state;
    final order = state.order!;
    final (icon, color, background, title, body) = switch (state.outcome) {
      TopupOutcome.success => (
        AppIcons.check,
        AppColors.success,
        AppColors.successBg,
        l10n.creditSuccessTitle,
        l10n.creditSuccessBody,
      ),
      TopupOutcome.pending => (
        AppIcons.clock,
        AppColors.warning,
        AppColors.warningBg,
        l10n.creditPendingTitle,
        l10n.creditPendingBody,
      ),
      TopupOutcome.failed => (
        AppIcons.close,
        AppColors.error,
        AppColors.errorBg,
        l10n.creditFailTitle,
        l10n.creditFailBody,
      ),
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 34, color: color),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        if (state.outcome == TopupOutcome.success) ...[
          const SizedBox(height: 6),
          Text(
            l10n.creditSuccessAmount(
              CreditFormat.number(context, order.totalCredits),
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: AppColors.success,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            height: 1.6,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        AppGlassContainer(
          showShadow: false,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Column(
            children: [
              _Row(label: l10n.creditOrderCode, value: order.code),
              const Divider(height: 1, color: AppColors.border),
              _Row(
                label: l10n.creditSummaryTotal,
                value: CreditFormat.vnd(context, order.amountVnd),
              ),
              const Divider(height: 1, color: AppColors.border),
              _Row(
                label: l10n.creditPayMethodTitle,
                value: CreditFormat.methodName(l10n, order.method),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
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
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
