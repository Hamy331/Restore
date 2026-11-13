import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_action_buttons.dart';
import '../../../shared/widgets/glass/app_glass_sheet.dart';
import '../../credits/utils/credit_format.dart';
import '../../credits/views/credit_topup/credit_topup_view.dart';
import '../repositories/listings_repository.dart';
import 'boost_listing_sheet.dart';

/// Mua tin ưu tiên (Hot sale) bằng xu: chọn số ngày, giá theo nhóm chuyên mục
/// đã giảm theo gói. Thiếu xu thì mở trang nạp. Trả về true khi đã mua.
///
/// [loadQuote] và [feature] lấy từ repository của màn gọi, để test thay được.
/// Dùng chung khoá với đẩy tin nên bấm liên tục không mở nhiều sheet.
Future<bool> featureListingWithCredits(
  BuildContext context, {
  required String title,
  required Future<FeatureQuote> Function() loadQuote,
  required Future<DateTime?> Function(String packageId) feature,
}) => runPromotionAction(() async {
  final l = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final FeatureQuote quote;
  try {
    quote = await loadQuote();
  } catch (_) {
    _toast(messenger, l.accUpdateListingError);
    return false;
  }
  if (!context.mounted) return false;
  final running = quote.runningUntil;
  if (running != null) {
    _toast(messenger, l.featureRunning(_date(running)));
    return false;
  }
  if (quote.options.isEmpty) {
    _toast(messenger, l.featureNoOptions);
    return false;
  }
  final picked = await showAppGlassSheet<FeatureOption>(
    context,
    title: l.featureAction,
    subtitle: title,
    icon: AppIcons.hot,
    builder: (_) => _FeatureSheet(quote: quote),
  );
  if (picked == null || !context.mounted) return false;
  if (quote.available < picked.credits) {
    await context.push(
      CreditTopupView.location(need: picked.credits - quote.available),
    );
    return false;
  }
  try {
    await feature(picked.packageId);
    _toast(messenger, l.featureDone);
    return true;
  } on ListingBoostException catch (error) {
    if (!context.mounted) return false;
    switch (error.code) {
      case ListingBoostException.notEnoughCredits:
        final missing =
            (error.details['missing'] as num?)?.toInt() ?? picked.credits;
        await context.push(CreditTopupView.location(need: missing));
      case ListingBoostException.featureActive:
        final until = DateTime.tryParse('${error.details['availableAt']}');
        _toast(
          messenger,
          until == null
              ? (error.message ?? l.accUpdateListingError)
              : l.featureRunning(_date(until.toLocal())),
        );
      default:
        _toast(messenger, error.message ?? l.accUpdateListingError);
    }
    return false;
  } catch (_) {
    _toast(messenger, l.accUpdateListingError);
    return false;
  }
});

String _date(DateTime value) => DateFormat('HH:mm · dd/MM').format(value);

void _toast(ScaffoldMessengerState messenger, String message) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class _FeatureSheet extends StatefulWidget {
  const _FeatureSheet({required this.quote});
  final FeatureQuote quote;

  @override
  State<_FeatureSheet> createState() => _FeatureSheetState();
}

class _FeatureSheetState extends State<_FeatureSheet> {
  late FeatureOption _selected = widget.quote.options.first;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final quote = widget.quote;
    final missing = _selected.credits - quote.available;
    final enough = missing <= 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            quote.discountPercent > 0
                ? '${l.featureSheetMessage} '
                      '${l.boostDiscountNote(quote.discountPercent)}'
                : l.featureSheetMessage,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          for (final option in quote.options) ...[
            _OptionTile(
              option: option,
              selected: option.packageId == _selected.packageId,
              onTap: () => setState(() => _selected = option),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 2),
          Text(
            enough
                ? l.postingPayBalance(quote.available)
                : '${l.postingPayBalance(quote.available)} · '
                      '${l.postingPayMissing(missing)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: enough ? AppColors.primaryDark : AppColors.error,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppSecondaryActionButton(
                  label: l.postingLater,
                  onPressed: () => popSheetOnce<FeatureOption?>(context, null),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppPrimaryActionButton(
                  label: enough
                      ? l.featurePay(_selected.credits)
                      : l.postingTopUp,
                  icon: enough ? AppIcons.hot : AppIcons.wallet,
                  onPressed: () => popSheetOnce(context, _selected),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });
  final FeatureOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.10)
          : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                selected ? AppIcons.hot : AppIcons.clock,
                size: 18,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l.featureDays(option.durationDays),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                CreditFormat.points(context, option.credits),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? AppColors.primaryDark
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
