import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/data/models/enums/wanted_alert_match_level.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_choice_chips.dart';
import 'package:restore/shared/widgets/app_labeled_text_field.dart';
import 'package:restore/shared/widgets/filter/listing_filter_section.dart';

import '../../../bloc/wanted_alert_create/wanted_alert_create_state.dart';
import '../../../models/wanted_alert_draft.dart';
import '../../../models/wanted_alert_match.dart';
import '../../../utils/wanted_alert_criteria.dart';
import 'wanted_alert_criteria_card.dart';
import 'wanted_alert_preview_strip.dart';

/// Bước soạn thông báo: món cần tìm, tiêu chí (mở sheet Bộ lọc / trang chọn
/// khu vực), mức độ giống và các tin đang khớp để xem trước khi bật
class WantedAlertComposeForm extends StatelessWidget {
  final WantedAlertCreateState state;

  /// Chiều cao header nổi phía trên
  final double topInset;
  final TextEditingController keywordsController;
  final ValueChanged<String> onKeywordsChanged;
  final VoidCallback onEditFilters;
  final VoidCallback onPickArea;
  final ValueChanged<WantedAlertMatchLevel> onLevelChanged;
  final ValueChanged<WantedAlertMatch> onOpenListing;
  final ValueChanged<WantedAlertMatch> onFavoriteTap;
  final VoidCallback onRetryPreview;

  const WantedAlertComposeForm({
    super.key,
    required this.state,
    this.topInset = 0,
    required this.keywordsController,
    required this.onKeywordsChanged,
    required this.onEditFilters,
    required this.onPickArea,
    required this.onLevelChanged,
    required this.onOpenListing,
    required this.onFavoriteTap,
    required this.onRetryPreview,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final draft = state.draft;
    final language = Localizations.localeOf(context).languageCode;
    final keywords = draft.trimmedKeywords;
    final criteria = WantedAlertCriteria.of(
      context,
      filter: draft.filter,
      categoryName: state.selectedCategory?.name.resolve(language),
      areaLabel: draft.area?.label,
    );

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(16, topInset + 12, 16, 24),
      children: [
        AppLabeledTextField(
          label: l10n.wantedAlertKeywordsLabel,
          isRequired: true,
          controller: keywordsController,
          onChanged: onKeywordsChanged,
          hintText: l10n.wantedAlertKeywordsHint,
          maxLength: WantedAlertDraft.keywordsMaxLength,
          textInputAction: TextInputAction.done,
          errorText: keywords.isNotEmpty && !draft.hasKeywords
              ? l10n.wantedAlertKeywordsError(
                  WantedAlertDraft.keywordsMinLength,
                )
              : null,
          helperText: l10n.wantedAlertKeywordsHelper,
        ),
        const SizedBox(height: 18),
        ListingFilterSection(
          title: l10n.wantedAlertCriteriaTitle,
          child: WantedAlertCriteriaCard(
            criteria: criteria,
            onEditFilters: onEditFilters,
            onPickArea: onPickArea,
          ),
        ),
        ListingFilterSection(
          title: l10n.wantedAlertLevelTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppChoiceChips<WantedAlertMatchLevel>(
                alignment: WrapAlignment.start,
                items: [
                  for (final level in WantedAlertMatchLevel.values)
                    AppChoiceItem(level, level.label(l10n)),
                ],
                selected: draft.matchLevel,
                onSelected: onLevelChanged,
              ),
              const SizedBox(height: 8),
              Text(
                draft.matchLevel.description(l10n),
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        ListingFilterSection(
          title: l10n.wantedAlertPreviewTitle,
          child: WantedAlertPreviewStrip(
            status: state.previewStatus,
            matches: state.suggestions,
            onOpenListing: onOpenListing,
            onFavoriteTap: onFavoriteTap,
            onRetry: onRetryPreview,
          ),
        ),
      ],
    );
  }
}
