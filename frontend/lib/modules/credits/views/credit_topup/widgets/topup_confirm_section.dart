import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/constants/app_images.dart' show AppImages;
import 'package:restore/data/models/enums/credit_enums.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/glass/app_glass_container.dart';

import '../../../bloc/credit_topup/credit_topup_cubit.dart';
import '../../../utils/credit_format.dart';
import 'topup_option_card.dart';

/// Bước 2: tóm tắt gói, chọn cách trả, đồng ý điều khoản xu
class TopupConfirmSection extends StatelessWidget {
  const TopupConfirmSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.watch<CreditTopupCubit>();
    final state = cubit.state;
    final pack = state.selected!;
    final receive = pack.bonusCredits > 0
        ? l10n.creditReceiveWithBonus(
            CreditFormat.number(context, pack.totalCredits),
            CreditFormat.number(context, pack.bonusCredits),
          )
        : CreditFormat.points(context, pack.totalCredits);
    final price = CreditFormat.vnd(context, pack.priceVnd);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        AppGlassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _Row(label: l10n.creditSummaryPack, value: price),
              const SizedBox(height: 10),
              _Row(label: l10n.creditSummaryReceive, value: receive),
              const Divider(height: 24, color: AppColors.border),
              _Row(label: l10n.creditSummaryTotal, value: price, strong: true),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          l10n.creditPayMethodTitle,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        for (final method in CreditPayMethod.selectable) ...[
          TopupOptionCard(
            selected: method == state.method,
            onTap: () => cubit.selectMethod(method),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 44,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Image.asset(
                    method == CreditPayMethod.vietQr
                        ? AppImages.appLogos.vietQr
                        : AppImages.appLogos.zaloPay,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        CreditFormat.methodName(l10n, method),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        method == CreditPayMethod.zaloPay
                            ? l10n.creditMethodZalopayDesc
                            : l10n.creditMethodVietqrDesc,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  method == state.method ? AppIcons.radioOn : AppIcons.radioOff,
                  color: method == state.method
                      ? AppColors.primaryDark
                      : AppColors.textSecondary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.infoBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(AppIcons.lock, size: 18, color: AppColors.info),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.creditSandboxNote,
                  style: const TextStyle(fontSize: 13, color: AppColors.info),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: cubit.toggleAgreed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: state.agreed,
                  onChanged: (_) => cubit.toggleAgreed(),
                  activeColor: AppColors.primaryDark,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      l10n.creditAgree,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;

  const _Row({required this.label, required this.value, this.strong = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: strong ? 15 : 14,
            fontWeight: strong ? FontWeight.w700 : FontWeight.w400,
            color: strong ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: strong ? 20 : 14,
              fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
