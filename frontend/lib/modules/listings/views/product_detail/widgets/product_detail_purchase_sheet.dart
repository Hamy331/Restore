import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/utils/formatters/currency_formatter.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_action_buttons.dart';
import 'package:restore/shared/widgets/app_labeled_text_field.dart';
import 'package:restore/shared/widgets/app_local_image.dart';
import 'package:restore/shared/widgets/glass/app_glass_sheet.dart';

import '../../../models/product_detail.dart';

/// Mở sheet xác nhận yêu cầu mua. Trả về lời nhắn (có thể rỗng) khi người
/// dùng bấm gửi, null khi đóng sheet.
Future<String?> showProductPurchaseSheet(
  BuildContext context, {
  required ProductDetail detail,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showAppGlassSheet<String>(
    context,
    title: l10n.productBuyTitle,
    subtitle: l10n.productBuySubtitle,
    icon: AppIcons.buy,
    builder: (_) => _PurchaseForm(detail: detail),
  );
}

class _PurchaseForm extends StatefulWidget {
  final ProductDetail detail;

  const _PurchaseForm({required this.detail});

  @override
  State<_PurchaseForm> createState() => _PurchaseFormState();
}

class _PurchaseFormState extends State<_PurchaseForm> {
  static const int _noteMaxLength = 200;

  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final listing = widget.detail.listing;
    final cover = listing.coverImage;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox.square(
                    dimension: 56,
                    child: cover == null
                        ? const ColoredBox(color: AppColors.cream)
                        : AppLocalImage(path: cover, cacheWidth: 160),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${l10n.productBuyPriceLabel}: '
                        '${CurrencyFormatter.formatVnd(listing.price ?? 0, locale: locale)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppLabeledTextField(
            label: l10n.productBuyNoteLabel,
            controller: _controller,
            hintText: l10n.productBuyNoteHint,
            minLines: 2,
            maxLines: 4,
            maxLength: _noteMaxLength,
            textInputAction: TextInputAction.newline,
          ),
          const SizedBox(height: 20),
          AppPrimaryActionButton(
            label: l10n.productBuySubmit,
            icon: AppIcons.send,
            onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          ),
        ],
      ),
    );
  }
}
