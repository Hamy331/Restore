import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/utils/helpers/t_snackbar_helper.dart';
import 'package:restore/data/models/credit_topup_model.dart';
import 'package:restore/data/models/enums/credit_enums.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_action_buttons.dart';
import 'package:restore/shared/widgets/glass/app_glass_container.dart';

import '../../../bloc/credit_topup/credit_topup_cubit.dart';
import '../../../utils/credit_format.dart';

/// Bước 3: trả tiền. VNPay (chưa nối cổng thật) hoặc mã VietQR, kèm nút giả
/// lập kết quả khi backend ở chế độ thử. Xu chỉ vào khi backend xác nhận.
class TopupPaySection extends StatelessWidget {
  const TopupPaySection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.watch<CreditTopupCubit>();
    final order = cubit.state.order!;
    final busy = cubit.state.busy;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        if (order.method == CreditPayMethod.vietQr)
          _VietQrPanel(order: order)
        else
          _VnpayPanel(order: order),
        if (order.sandbox) ...[
          const SizedBox(height: 16),
          Text(
            l10n.creditSimulateTitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AppPrimaryActionButton(
                  label: l10n.creditSimulateSuccess,
                  icon: AppIcons.check,
                  isLoading: busy,
                  onPressed: busy ? null : () => cubit.simulate(success: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppSecondaryActionButton(
                  label: l10n.creditSimulateFail,
                  icon: AppIcons.close,
                  onPressed: busy ? null : () => cubit.simulate(success: false),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: busy ? null : cubit.cancel,
            child: Text(
              l10n.creditCancelOrder,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ),
      ],
    );
  }
}

class _VnpayPanel extends StatelessWidget {
  final CreditTopupModel order;

  const _VnpayPanel({required this.order});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppGlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            CreditFormat.vnd(context, order.amountVnd),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${l10n.creditOrderCode}: ${order.code} · '
            '${CreditFormat.points(context, order.totalCredits)}',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warningBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(AppIcons.info, size: 18, color: AppColors.warning),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.creditGatewayNotConnected,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VietQrPanel extends StatelessWidget {
  final CreditTopupModel order;

  const _VietQrPanel({required this.order});

  void _copy(BuildContext context, String value) {
    Clipboard.setData(ClipboardData(text: value));
    TSnackBarHelper.showSuccess(
      context,
      message: AppLocalizations.of(context)!.creditCopied,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final qr = order.vietQr;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppGlassContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                l10n.creditScanQr,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: 220,
                height: 220,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: qr != null && qr.imageUrl.isNotEmpty
                    ? Image.network(
                        qr.imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Icon(
                          AppIcons.imageBroken,
                          color: AppColors.textSecondary,
                        ),
                      )
                    : Center(
                        child: Text(
                          l10n.creditVietQrUnavailable,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              Text(
                CreditFormat.vnd(context, order.amountVnd),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  l10n.creditQrExpires(
                    CreditFormat.time(context, order.expiresAt),
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppGlassContainer(
          showShadow: false,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Column(
            children: [
              if (qr != null) ...[
                _InfoRow(label: l10n.creditAccountName, value: qr.accountName),
                const Divider(height: 1, color: AppColors.border),
                _InfoRow(
                  label: l10n.creditAccountNo,
                  value: qr.accountNo,
                  onCopy: () => _copy(context, qr.accountNo),
                ),
                const Divider(height: 1, color: AppColors.border),
              ],
              _InfoRow(
                label: l10n.creditTransferContent,
                value: order.code,
                highlight: true,
                onCopy: () => _copy(context, order.code),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.creditWaitingTransfer,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final VoidCallback? onCopy;

  const _InfoRow({
    required this.label,
    required this.value,
    this.highlight = false,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14,
                fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
                color: highlight
                    ? AppColors.primaryDark
                    : AppColors.textPrimary,
              ),
            ),
          ),
          if (onCopy != null)
            IconButton(
              tooltip: AppLocalizations.of(context)!.creditCopy,
              icon: const Icon(AppIcons.copy, size: 18),
              color: AppColors.textSecondary,
              onPressed: onCopy,
            ),
        ],
      ),
    );
  }
}
