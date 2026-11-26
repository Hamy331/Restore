import 'package:flutter/material.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/models/listing_filter.dart';
import 'package:restore/shared/widgets/app_dropdown_menu.dart';
import 'package:restore/shared/widgets/app_option_sheet.dart';

import 'listing_filter_labels.dart';

/// Menu thả xuống chọn cách sắp xếp tin, mở ngay dưới nút vừa bấm ([anchor]
/// là context của nút). Chỉ hiện [options] mà trang hỗ trợ (VD "Gần nhất"
/// chỉ có khi biết vị trí). Trả về null nếu người dùng bấm ra ngoài.
Future<ListingSort?> showListingSortSheet(
  BuildContext anchor, {
  required ListingSort selected,
  required List<ListingSort> options,
}) {
  final l10n = AppLocalizations.of(anchor)!;
  return showAppDropdown<ListingSort>(
    anchor,
    selected: selected,
    options: [
      for (final sort in options) AppSheetOption(sort, sort.label(l10n)),
    ],
  );
}
