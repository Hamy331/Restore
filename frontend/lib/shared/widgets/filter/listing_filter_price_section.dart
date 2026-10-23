import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/utils/formatters/currency_formatter.dart';
import 'package:restore/core/utils/formatters/thousands_separator_input_formatter.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/models/listing_filter_options.dart';
import 'package:restore/shared/widgets/app_labeled_text_field.dart';

import 'app_filter_bar.dart';
import 'listing_filter_section.dart';

/// Khoảng giá trong sheet Bộ lọc: hai ô nhập giá và các mức giá gợi ý.
/// Ô nhập tự cập nhật khi giá đổi từ bên ngoài (chọn mức gợi ý, xoá bộ lọc).
class ListingFilterPriceSection extends StatefulWidget {
  final int? minPrice;
  final int? maxPrice;
  final List<PriceRangeOption> presets;
  final bool isInvalid;
  final void Function({required int? min, required int? max}) onChanged;

  const ListingFilterPriceSection({
    super.key,
    required this.minPrice,
    required this.maxPrice,
    required this.presets,
    required this.isInvalid,
    required this.onChanged,
  });

  @override
  State<ListingFilterPriceSection> createState() =>
      _ListingFilterPriceSectionState();
}

class _ListingFilterPriceSectionState extends State<ListingFilterPriceSection> {
  final _minController = TextEditingController();
  final _maxController = TextEditingController();

  String get _locale => Localizations.localeOf(context).toLanguageTag();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync(_minController, widget.minPrice);
    _sync(_maxController, widget.maxPrice);
  }

  @override
  void didUpdateWidget(ListingFilterPriceSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync(_minController, widget.minPrice);
    _sync(_maxController, widget.maxPrice);
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  /// Chỉ ghi đè ô nhập khi giá trị thật sự khác, để không nhảy con trỏ
  /// lúc người dùng đang gõ
  void _sync(TextEditingController controller, int? value) {
    if (ThousandsSeparatorInputFormatter.parse(controller.text) == value) {
      return;
    }
    controller.text = value == null
        ? ''
        : CurrencyFormatter.formatNumber(value, locale: _locale);
  }

  void _onTyped(String _) => widget.onChanged(
    min: ThousandsSeparatorInputFormatter.parse(_minController.text),
    max: ThousandsSeparatorInputFormatter.parse(_maxController.text),
  );

  String _presetLabel(AppLocalizations l10n, PriceRangeOption range) {
    String price(int value) =>
        CurrencyFormatter.formatCompact(value, l10n, locale: _locale);
    final min = range.min;
    final max = range.max;
    return switch ((min, max)) {
      (null, final int max) => l10n.listingFilterPriceUnder(price(max)),
      (final int min, null) => l10n.listingFilterPriceOver(price(min)),
      (final min, final max) => l10n.listingFilterPriceBetween(
        price(min ?? 0),
        price(max ?? 0),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasRange = widget.minPrice != null || widget.maxPrice != null;

    Widget field(String label, TextEditingController controller) =>
        AppLabeledTextField(
          label: label,
          controller: controller,
          hintText: l10n.listingFilterPriceAny,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          inputFormatters: [ThousandsSeparatorInputFormatter(locale: _locale)],
          onChanged: _onTyped,
          suffix: const Text(
            CurrencyFormatter.vndSymbol,
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
          ),
        );

    return ListingFilterSection(
      title: l10n.listingFilterPrice,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: field(l10n.listingFilterPriceMin, _minController),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: field(l10n.listingFilterPriceMax, _maxController),
              ),
            ],
          ),
          if (widget.isInvalid || hasRange) ...[
            const SizedBox(height: 6),
            Text(
              widget.isInvalid
                  ? l10n.listingFilterPriceInvalid
                  : l10n.listingFilterPriceHelper,
              style: TextStyle(
                fontSize: 12,
                color: widget.isInvalid
                    ? AppColors.error
                    : AppColors.textSecondary,
              ),
            ),
          ],
          if (widget.presets.isNotEmpty) ...[
            const SizedBox(height: 12),
            ListingFilterChipWrap(
              children: [
                for (final range in widget.presets)
                  AppFilterChip(
                    label: _presetLabel(l10n, range),
                    selected:
                        range.min == widget.minPrice &&
                        range.max == widget.maxPrice,
                    // Bấm lại mức đang chọn thì bỏ lọc giá
                    onTap: () =>
                        range.min == widget.minPrice &&
                            range.max == widget.maxPrice
                        ? widget.onChanged(min: null, max: null)
                        : widget.onChanged(min: range.min, max: range.max),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
