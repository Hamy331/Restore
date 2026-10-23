import 'package:flutter/material.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/models/listing_filter.dart';
import 'package:restore/shared/widgets/app_option_sheet.dart';

import 'listing_filter_labels.dart';

/// Sheet chọn cách sắp xếp tin, chỉ hiện [options] mà trang hỗ trợ
/// (VD "Gần nhất" chỉ có khi biết vị trí, "Phù hợp nhất" khi có từ khoá).
/// Trả về null nếu người dùng đóng sheet.
Future<ListingSort?> showListingSortSheet(
  BuildContext context, {
  required ListingSort selected,
  required List<ListingSort> options,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showAppOptionSheet<ListingSort>(
    context,
    title: l10n.listingSortTitle,
    selected: selected,
    options: [
      for (final sort in options) AppSheetOption(sort, sort.label(l10n)),
    ],
  );
}
