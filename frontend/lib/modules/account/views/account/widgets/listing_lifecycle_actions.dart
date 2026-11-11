import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../boost/views/boost_listing/boost_listing_view.dart';
import '../../../../../shared/widgets/app_switch_tile.dart';
import '../../../../credits/views/credit_topup/credit_topup_view.dart';
import '../../../../../data/models/category_model.dart';
import '../../../../listings/models/display_pricing.dart';
import '../../../../listings/models/posting_quota.dart';
import '../../../../listings/widgets/display_days_sheet.dart';
import '../../../../listings/widgets/posting_limit_sheet.dart';
import '../../../bloc/account_listings/account_listings_cubit.dart';
import '../../../models/account_listing.dart';
import '../../../../plans/views/plans/plans_view.dart';

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
      case PostingLimitAction.upgradePlan:
        await context.push(PlansView.path);
      case PostingLimitAction.chooseAnotherCategory || null:
        return;
    }
  }
}

/// Gia hạn tin đang hiển thị thêm số ngày tuỳ chọn bằng xu: sheet chọn số
/// ngày (hoặc ngày hết hạn mới) hiện giá ngay, thiếu xu thì sang nạp xu.
/// Gói có tự gia hạn (Cửa hàng) thì sheet có thêm công tắc tự gia hạn.
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
  final pricing = quota.display;
  final available = quota.walletAvailable;
  final choice = await showDisplayDaysSheet(
    context,
    mode: DisplayDaysMode.extend,
    rule: rule,
    pricing: pricing,
    walletAvailable: available,
    currentEnd: item.expiresAt,
    subtitle: item.title,
    footer: pricing.autoExtend
        ? _AutoExtendSwitch(
            item: item,
            credits: pricing.extraDaysCredits(
              DisplayPricing.autoExtendDays,
              rule.dayPackCredits,
            ),
            cubit: cubit,
            messenger: messenger,
          )
        : null,
  );
  if (choice == null || choice.days <= 0 || !context.mounted) return;
  final price = pricing.extraDaysCredits(choice.days, rule.dayPackCredits);
  if (price > available) {
    await context.push(CreditTopupView.location(need: price - available));
    return;
  }
  try {
    await cubit.extend(item.id, choice.days);
    _toast(messenger, l.accExtendedDays(choice.days));
  } on AccountListingActionException catch (error) {
    if (!context.mounted) return;
    switch (error.code) {
      case AccountListingActionException.notEnoughCredits:
        final missing = (error.details['missing'] as num?)?.toInt() ?? price;
        await context.push(CreditTopupView.location(need: missing));
      case AccountListingActionException.extendTooLong:
        final addable = (error.details['addableDays'] as num?)?.toInt() ?? 0;
        _toast(
          messenger,
          addable > 0
              ? l.extendAddable(addable)
              : l.extendLimitReached(rule.maxDisplayDays),
        );
      default:
        _toast(messenger, error.message);
    }
  }
}

/// Công tắc tự gia hạn trong sheet gia hạn: đổi ngay khi chạm, lỗi thì trả
/// công tắc về như cũ.
class _AutoExtendSwitch extends StatefulWidget {
  const _AutoExtendSwitch({
    required this.item,
    required this.credits,
    required this.cubit,
    required this.messenger,
  });
  final AccountListing item;
  final int credits;
  final AccountListingsCubit cubit;
  final ScaffoldMessengerState messenger;

  @override
  State<_AutoExtendSwitch> createState() => _AutoExtendSwitchState();
}

class _AutoExtendSwitchState extends State<_AutoExtendSwitch> {
  late bool _value = widget.item.autoExtend;
  bool _busy = false;

  Future<void> _toggle(bool value) async {
    if (_busy) return;
    final l = AppLocalizations.of(context)!;
    setState(() {
      _busy = true;
      _value = value;
    });
    try {
      await widget.cubit.setAutoExtend(widget.item.id, value);
      _toast(widget.messenger, value ? l.autoExtendOn : l.autoExtendOff);
    } on AccountListingActionException catch (error) {
      if (mounted) setState(() => _value = !value);
      _toast(widget.messenger, error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AppSwitchTile(
      key: const ValueKey('listing-auto-extend'),
      label: l.autoExtendTitle,
      subtitle: l.autoExtendBody(widget.credits),
      value: _value,
      onChanged: _toggle,
    );
  }
}

/// Mở trang quảng bá tin (đẩy tin 24 giờ, Hot sale bằng xu); đã đẩy / mua
/// thì tải lại danh sách để thấy trạng thái và số xu mới.
Future<void> promoteAccountListing(
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
  final changed = await context.push<bool>(BoostListingView.location(item.id));
  if (changed == true) await cubit.load();
}

void _toast(ScaffoldMessengerState messenger, String? message) {
  if (message == null || message.isEmpty) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
