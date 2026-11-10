import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_icons.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/widgets/app_action_buttons.dart';
import '../../../../../shared/widgets/glass/app_glass_sheet.dart';
import '../../../../credits/views/credit_topup/credit_topup_view.dart';
import '../../../../../data/models/category_model.dart';
import '../../../../listings/models/posting_quota.dart';
import '../../../../listings/widgets/boost_listing_sheet.dart';
import '../../../../listings/widgets/posting_limit_sheet.dart';
import '../../../bloc/account_listings/account_listings_cubit.dart';
import '../../../models/account_listing.dart';

/// Hiện lại tin đã ẩn. Tin đã hết hạn thì đây là kích hoạt lại: tính như đăng
/// mới, hết suất miễn phí thì hỏi trả xu (hoặc nạp xu) qua sheet hết suất.
Future<void> showAccountListing(
  BuildContext context,
  AccountListing item, {
  bool payWithCredits = false,
}) async {
  final l = AppLocalizations.of(context)!;
  final cubit = context.read<AccountListingsCubit>();
  final messenger = ScaffoldMessenger.of(context);
  final expired = item.isExpiredAt(DateTime.now());
  try {
    await cubit.setStatus(
      item.id,
      AccountListingStatus.visible,
      payWithCredits: payWithCredits,
    );
    if (expired) _toast(messenger, l.accReactivated);
  } on AccountListingActionException catch (error) {
    if (!context.mounted) return;
    final limited =
        error.code == AccountListingActionException.postingLimitReached ||
        error.code == AccountListingActionException.notEnoughCredits;
    final categoryId = item.categoryId;
    if (!limited || categoryId == null) {
      _toast(messenger, error.message);
      return;
    }
    final repository = cubit.repository;
    final PostingQuota quota;
    final CategoryModel? category;
    try {
      (quota, category) = await (
        repository.postingQuota(),
        repository.category(categoryId),
      ).wait;
    } catch (_) {
      _toast(messenger, error.message);
      return;
    }
    if (!context.mounted) return;
    if (category == null) {
      _toast(messenger, error.message);
      return;
    }
    final action = await showPostingLimitSheet(
      context,
      category: category,
      quota: quota,
      reactivate: true,
    );
    if (!context.mounted) return;
    switch (action) {
      case PostingLimitAction.payWithCredits:
        await showAccountListing(context, item, payWithCredits: true);
      case PostingLimitAction.topUp:
        final price = quota.forCategory(categoryId).extraCredits ?? 0;
        await context.push(
          CreditTopupView.location(need: price - quota.walletAvailable),
        );
      case PostingLimitAction.chooseAnotherCategory || null:
        return;
    }
  }
}

/// Gia hạn tin đang hiển thị thêm một kỳ bằng xu, hỏi lại trước khi trừ xu.
Future<void> extendAccountListing(
  BuildContext context,
  AccountListing item,
) async {
  final l = AppLocalizations.of(context)!;
  final cubit = context.read<AccountListingsCubit>();
  final messenger = ScaffoldMessenger.of(context);
  final categoryId = item.categoryId;
  if (categoryId == null) return;
  final PostingQuota quota;
  try {
    quota = await cubit.repository.postingQuota();
  } catch (_) {
    if (context.mounted) {
      context.read<AccountListingsCubit>().reportUpdateError();
    }
    return;
  }
  if (!context.mounted) return;
  final rule = quota.forCategory(categoryId);
  final price = rule.extendCredits ?? rule.extraCredits ?? 0;
  final days = rule.displayDays;
  final left = item.daysLeftAt(DateTime.now());
  if (left != null && left > days) {
    _toast(messenger, l.accExtendTooEarly(days));
    return;
  }
  final available = quota.walletAvailable;
  final enough = available >= price;
  final confirmed = await showAppGlassSheet<bool>(
    context,
    title: l.accExtend,
    subtitle: item.title,
    icon: AppIcons.clock,
    builder: (sheetContext) => _ExtendSheet(
      price: price,
      days: days,
      available: available,
      enough: enough,
    ),
  );
  if (confirmed != true || !context.mounted) return;
  if (!enough) {
    await context.push(CreditTopupView.location(need: price - available));
    return;
  }
  try {
    await cubit.extend(item.id);
    _toast(messenger, l.accExtended);
  } on AccountListingActionException catch (error) {
    if (!context.mounted) return;
    if (error.code == AccountListingActionException.notEnoughCredits) {
      final missing = (error.details['missing'] as num?)?.toInt() ?? price;
      await context.push(CreditTopupView.location(need: missing));
      return;
    }
    _toast(messenger, error.message);
  }
}

/// Đẩy tin đang hiển thị lên đầu (lượt tặng của gói hoặc trả xu), xong thì
/// tải lại danh sách để thấy số xu mới.
Future<void> boostAccountListing(
  BuildContext context,
  AccountListing item,
) async {
  final cubit = context.read<AccountListingsCubit>();
  if (item.status != AccountListingStatus.visible) {
    _toast(
      ScaffoldMessenger.of(context),
      AppLocalizations.of(context)!.boostUnavailableDescription,
    );
    return;
  }
  final repository = cubit.repository;
  final boosted = await boostListingWithCredits(
    context,
    title: item.title,
    categoryId: item.categoryId,
    loadQuota: repository.postingQuota,
    boost: () => repository.boost(item.id),
  );
  if (boosted) await cubit.load();
}

void _toast(ScaffoldMessengerState messenger, String? message) {
  if (message == null || message.isEmpty) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class _ExtendSheet extends StatelessWidget {
  const _ExtendSheet({
    required this.price,
    required this.days,
    required this.available,
    required this.enough,
  });
  final int price;
  final int days;
  final int available;
  final bool enough;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final missing = price - available;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.accExtendMessage(days, price),
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            missing > 0
                ? '${l.postingPayBalance(available)} · '
                      '${l.postingPayMissing(missing)}'
                : l.postingPayBalance(available),
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
                  label: l.postingLater,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppPrimaryActionButton(
                  label: enough ? l.accExtendPay(price) : l.postingTopUp,
                  icon: AppIcons.wallet,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
