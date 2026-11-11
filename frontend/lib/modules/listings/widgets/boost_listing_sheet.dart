import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_action_buttons.dart';
import '../../../shared/widgets/glass/app_glass_sheet.dart';
import '../../credits/views/credit_topup/credit_topup_view.dart';
import '../models/posting_quota.dart';
import '../repositories/listings_repository.dart';

/// Đẩy tin lên đầu 24 giờ: còn lượt tặng của gói thì miễn phí, hết lượt thì
/// trả xu theo chuyên mục (gói cao được giảm giá). Hỏi lại trước khi đẩy,
/// thiếu xu thì mở trang nạp. Trả về true khi đã đẩy.
///
/// [loadQuota] và [boost] lấy từ repository của màn gọi, để test thay được.
/// Bấm liên tục khi đang xử lý thì bỏ qua (xem [runPromotionAction]).
Future<bool> boostListingWithCredits(
  BuildContext context, {
  required String title,
  required String? categoryId,
  required Future<PostingQuota> Function() loadQuota,
  required Future<BoostResult> Function() boost,
}) => runPromotionAction(
  () => _boost(
    context,
    title: title,
    categoryId: categoryId,
    loadQuota: loadQuota,
    boost: boost,
  ),
);

/// Đang có một lượt đẩy tin / mua Hot sale chạy (từ lúc tải giá tới lúc
/// có kết quả). Chặn bấm nhanh nhiều lần mở nhiều sheet hoặc gửi nhiều yêu cầu.
bool _promotionBusy = false;

/// Chạy [action] nếu chưa có lượt đẩy tin / Hot sale nào đang chạy, không
/// thì bỏ qua và trả false.
Future<bool> runPromotionAction(Future<bool> Function() action) async {
  if (_promotionBusy) return false;
  _promotionBusy = true;
  try {
    return await action();
  } finally {
    _promotionBusy = false;
  }
}

/// Đóng sheet một lần: bấm hai lần liên tiếp không được đóng luôn trang bên dưới
void popSheetOnce<T>(BuildContext context, T result) {
  if (ModalRoute.of(context)?.isCurrent ?? false) {
    Navigator.of(context).pop(result);
  }
}

Future<bool> _boost(
  BuildContext context, {
  required String title,
  required String? categoryId,
  required Future<PostingQuota> Function() loadQuota,
  required Future<BoostResult> Function() boost,
}) async {
  final l = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final PostingQuota quota;
  try {
    quota = await loadQuota();
  } catch (_) {
    _toast(messenger, l.accUpdateListingError);
    return false;
  }
  if (!context.mounted) return false;
  final price = quota.forCategory(categoryId ?? '').boostCredits ?? 0;
  final free = quota.boostFreeLeft > 0;
  final available = quota.walletAvailable;
  final enough = free || available >= price;
  final confirmed = await showAppGlassSheet<bool>(
    context,
    title: l.accBoost,
    subtitle: title,
    icon: AppIcons.boost,
    builder: (_) =>
        _BoostSheet(quota: quota, price: price, free: free, enough: enough),
  );
  if (confirmed != true || !context.mounted) return false;
  if (!enough) {
    await context.push(CreditTopupView.location(need: price - available));
    return false;
  }
  try {
    await boost();
    _toast(messenger, l.boostDone);
    return true;
  } on ListingBoostException catch (error) {
    if (!context.mounted) return false;
    switch (error.code) {
      case ListingBoostException.notEnoughCredits:
        final missing = (error.details['missing'] as num?)?.toInt() ?? price;
        await context.push(CreditTopupView.location(need: missing));
      case ListingBoostException.tooSoon:
        final at = DateTime.tryParse('${error.details['availableAt']}');
        final hours = at == null
            ? 24
            : (at.difference(DateTime.now()).inMinutes / 60).ceil().clamp(
                1,
                24,
              );
        _toast(messenger, l.boostTooSoon(hours));
      default:
        _toast(messenger, error.message ?? l.accUpdateListingError);
    }
    return false;
  } catch (_) {
    _toast(messenger, l.accUpdateListingError);
    return false;
  }
}

void _toast(ScaffoldMessengerState messenger, String message) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class _BoostSheet extends StatelessWidget {
  const _BoostSheet({
    required this.quota,
    required this.price,
    required this.free,
    required this.enough,
  });
  final PostingQuota quota;
  final int price;
  final bool free;
  final bool enough;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final available = quota.walletAvailable;
    final missing = price - available;
    final discount = quota.boostDiscountPercent;
    final note = free
        ? l.boostFreeNote(quota.boostFreeLeft, quota.boostFreePerMonth)
        : discount > 0
        ? '${l.boostPayNote(price)} ${l.boostDiscountNote(discount)}'
        : l.boostPayNote(price);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${l.boostSheetMessage} $note',
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          if (!free) ...[
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
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppSecondaryActionButton(
                  label: l.postingLater,
                  onPressed: () => popSheetOnce(context, false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppPrimaryActionButton(
                  label: free
                      ? l.boostUseFree
                      : enough
                      ? l.boostPay(price)
                      : l.postingTopUp,
                  icon: free || enough ? AppIcons.boost : AppIcons.wallet,
                  onPressed: () => popSheetOnce(context, true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
