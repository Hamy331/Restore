import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_labeled_text_field.dart';

import 'listing_filter_section.dart';

/// Khoảng giá trị của một thuộc tính dạng số trong sheet Bộ lọc
/// (Năm sản xuất, Số km...): hai ô Từ / Đến, mỗi ô trống là không giới hạn.
/// Ô nhập tự cập nhật khi giá trị đổi từ bên ngoài (xoá bộ lọc).
class ListingFilterRangeSection extends StatefulWidget {
  final String title;

  /// Đơn vị hiện sau ô nhập (km, cc, tháng...)
  final String? unit;
  final int? min;
  final int? max;
  final void Function({required int? min, required int? max}) onChanged;

  const ListingFilterRangeSection({
    super.key,
    required this.title,
    this.unit,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  State<ListingFilterRangeSection> createState() =>
      _ListingFilterRangeSectionState();
}

class _ListingFilterRangeSectionState extends State<ListingFilterRangeSection> {
  late final _minController = TextEditingController(text: _text(widget.min));
  late final _maxController = TextEditingController(text: _text(widget.max));

  static String _text(int? value) => value?.toString() ?? '';

  @override
  void didUpdateWidget(ListingFilterRangeSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Chỉ ghi đè khi giá trị thật sự khác, để không nhảy con trỏ lúc đang gõ
    if (int.tryParse(_minController.text) != widget.min) {
      _minController.text = _text(widget.min);
    }
    if (int.tryParse(_maxController.text) != widget.max) {
      _maxController.text = _text(widget.max);
    }
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _onTyped(String _) => widget.onChanged(
    min: int.tryParse(_minController.text),
    max: int.tryParse(_maxController.text),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final min = widget.min;
    final max = widget.max;
    final unit = widget.unit;

    Widget field(String label, TextEditingController controller) =>
        AppLabeledTextField(
          label: label,
          controller: controller,
          hintText: l10n.listingFilterPriceAny,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(12),
          ],
          onChanged: _onTyped,
          suffix: unit == null || unit.isEmpty
              ? null
              : Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
        );

    return ListingFilterSection(
      title: widget.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: field(l10n.listingFilterRangeFrom, _minController),
              ),
              const SizedBox(width: 10),
              Expanded(child: field(l10n.listingFilterRangeTo, _maxController)),
            ],
          ),
          if (min != null && max != null && min > max) ...[
            const SizedBox(height: 6),
            Text(
              l10n.listingFilterRangeInvalid,
              style: const TextStyle(fontSize: 12, color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }
}
