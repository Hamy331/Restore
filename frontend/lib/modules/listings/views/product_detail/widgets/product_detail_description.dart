import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/l10n/app_localizations.dart';

import 'product_detail_section.dart';

/// Mô tả sản phẩm; mô tả dài được rút gọn kèm nút "Xem thêm"
class ProductDetailDescription extends StatefulWidget {
  final String description;

  const ProductDetailDescription({super.key, required this.description});

  @override
  State<ProductDetailDescription> createState() =>
      _ProductDetailDescriptionState();
}

class _ProductDetailDescriptionState extends State<ProductDetailDescription> {
  static const int _collapsedLines = 5;
  static const TextStyle _style = TextStyle(
    fontSize: 14,
    height: 1.55,
    color: AppColors.textPrimary,
  );

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = widget.description.trim();

    return ProductDetailSection(
      title: l10n.productDescription,
      child: text.isEmpty
          ? Text(
              l10n.notSpecified,
              style: _style.copyWith(color: AppColors.textSecondary),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                // Đo xem mô tả có vượt số dòng rút gọn không
                final painter = TextPainter(
                  text: TextSpan(text: text, style: _style),
                  maxLines: _collapsedLines,
                  textDirection: Directionality.of(context),
                  textScaler: MediaQuery.textScalerOf(context),
                )..layout(maxWidth: constraints.maxWidth);
                final overflows = painter.didExceedMaxLines;
                painter.dispose();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: Text(
                        text,
                        style: _style,
                        maxLines: _expanded ? null : _collapsedLines,
                        overflow: _expanded
                            ? TextOverflow.visible
                            : TextOverflow.fade,
                      ),
                    ),
                    if (overflows)
                      TextButton(
                        onPressed: () => setState(() => _expanded = !_expanded),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryDark,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          _expanded
                              ? l10n.productReadLess
                              : l10n.productReadMore,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }
}
