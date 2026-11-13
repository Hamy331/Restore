import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import '../bloc/create_listing/create_listing_bloc.dart';
import '../bloc/create_listing/create_listing_event.dart';
import '../bloc/create_listing/create_listing_state.dart';
import 'display_days_sheet.dart';

/// Thẻ "Thời gian hiển thị" ở bước 3 và trang xem trước. Mặc định là số
/// ngày miễn phí của chuyên mục nên ai không quan tâm cứ bấm Đăng tin;
/// chạm vào để chọn ngày bắt đầu, ngày kết thúc hoặc mua thêm ngày.
/// Ẩn khi chưa tải được hạn mức (backend vẫn dùng số ngày miễn phí).
class ListingDisplayDaysCard extends StatelessWidget {
  const ListingDisplayDaysCard({super.key});

  Future<void> _open(BuildContext context, CreateListingState state) async {
    final quota = state.quota;
    final rule = state.categoryQuota;
    if (quota == null || rule == null) return;
    final bloc = context.read<CreateListingBloc>();
    final choice = await showDisplayDaysSheet(
      context,
      mode: DisplayDaysMode.posting,
      rule: rule,
      pricing: quota.display,
      walletAvailable: quota.walletAvailable,
      initialDays: state.draft.displayDays,
      initialStart: state.draft.startsAt,
    );
    if (choice == null) return;
    bloc.add(
      DisplayDaysChanged(
        // Đúng số ngày miễn phí thì để null: backend tự dùng số ngày miễn phí
        days: choice.days == rule.displayDays ? null : choice.days,
        startsAt: choice.startsAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateListingBloc, CreateListingState>(
      buildWhen: (previous, current) =>
          previous.quota != current.quota ||
          previous.draft.categoryId != current.draft.categoryId ||
          previous.draft.displayDays != current.draft.displayDays ||
          previous.draft.startsAt != current.draft.startsAt,
      builder: (context, state) {
        final quota = state.quota;
        final rule = state.categoryQuota;
        if (quota == null || rule == null) return const SizedBox.shrink();
        final l = AppLocalizations.of(context)!;
        final date = DateFormat('dd/MM');
        final now = DateTime.now();
        final start =
            state.draft.startsAt != null && state.draft.startsAt!.isAfter(now)
            ? state.draft.startsAt!
            : now;
        final days = (state.draft.displayDays ?? rule.displayDays).clamp(
          1,
          rule.maxDisplayDays,
        );
        final extra = (days - rule.displayDays).clamp(0, 365);
        final credits = quota.display.extraDaysCredits(
          extra,
          rule.dayPackCredits,
        );
        final range = l.displayDaysRange(
          start == now ? l.displayDaysTodayShort : date.format(start),
          date.format(start.add(Duration(days: days))),
          days,
        );

        return Material(
          color: AppColors.surface.withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            key: const ValueKey('listing-display-days-card'),
            borderRadius: BorderRadius.circular(18),
            onTap: () => _open(context, state),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      AppIcons.calendar,
                      size: 20,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.displayDaysTitle,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          range,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          credits == 0
                              ? '${l.displayDaysNoCharge} · ${l.displayDaysCardHint}'
                              : l.displayDaysExtraPrice(extra, credits),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: credits == 0
                                ? FontWeight.w400
                                : FontWeight.w600,
                            color: credits == 0
                                ? AppColors.textSecondary
                                : AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    AppIcons.chevronRight,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
