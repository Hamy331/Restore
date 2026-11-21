import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/utils/formatters/currency_formatter.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_local_image.dart';
import '../models/chat_models.dart';

class ChatProductPreview extends StatelessWidget {
  const ChatProductPreview({
    super.key,
    required this.product,
    this.onTap,
    this.compact = false,
  });

  final ChatProduct product;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 34.0 : 46.0;
    final price = product.price;
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          if (compact) ...[
            Container(width: 3, height: 38, color: AppColors.actionPrimary),
            const SizedBox(width: 7),
          ],
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox.square(
              dimension: size,
              child: product.image != null
                  ? AppLocalImage(path: product.image!, cacheWidth: 144)
                  : const ColoredBox(
                      color: Color(0xFFF3F4F6),
                      child: Icon(Icons.image_outlined, size: 18),
                    ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  price == null
                      ? AppLocalizations.of(context)!.homeExchangeOnly
                      : CurrencyFormatter.formatVnd(
                          price,
                          locale: Localizations.localeOf(
                            context,
                          ).toLanguageTag(),
                        ),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
