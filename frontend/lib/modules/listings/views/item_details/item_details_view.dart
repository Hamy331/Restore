import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/utils/helpers/t_snackbar_helper.dart';
import 'package:restore/data/models/enums/listing_condition.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/desktop/desktop_layout.dart';
import '../../bloc/create_listing/create_listing_bloc.dart';
import '../../bloc/create_listing/create_listing_event.dart';
import '../../bloc/create_listing/create_listing_state.dart';
import '../../models/create_listing_step.dart';
import '../../models/listing_draft.dart';
import '../../repositories/listing_ai_repository.dart';
import '../../utils/listing_validator.dart';
import '../../widgets/create_listing_scaffold.dart';
import '../../widgets/edit_listing_notice.dart';
import 'widgets/ai_suggestion_sheet.dart';
import 'widgets/listing_attribute_field.dart';
import 'widgets/listing_category_summary.dart';
import 'widgets/listing_condition_field.dart';
import 'widgets/listing_form_widgets.dart';
import 'widgets/listing_meet_up_section.dart';
import 'widgets/listing_photos_section.dart';
import 'widgets/listing_price_section.dart';
import 'widgets/posting_quota_note.dart';

/// Bước 2: ảnh, tiêu đề, tình trạng, thông tin theo danh mục (cũng là bộ
/// lọc khi tìm kiếm), mô tả, giá (bán / cho tặng) và khu vực gặp mặt
class ItemDetailsView extends StatefulWidget {
  const ItemDetailsView({super.key, this.ai});

  /// AI soạn tin từ ảnh bìa (mặc định gọi API thật)
  final ListingAiRepository? ai;

  @override
  State<ItemDetailsView> createState() => _ItemDetailsViewState();
}

class _ItemDetailsViewState extends State<ItemDetailsView> {
  late final CreateListingBloc _bloc = context.read<CreateListingBloc>();
  late final _title = TextEditingController(text: _bloc.state.draft.title);
  late final _description = TextEditingController(
    text: _bloc.state.draft.description,
  );

  late final ListingAiRepository _ai = widget.ai ?? ListingAiRepository();
  bool _composing = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  /// AI xem ảnh bìa, gợi ý tiêu đề / mô tả / tình trạng; người dùng xem trước
  /// rồi mới điền vào form
  Future<void> _composeWithAi() async {
    final l10n = AppLocalizations.of(context)!;
    final draft = _bloc.state.draft;
    if (_composing || draft.images.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _composing = true);
    try {
      final suggestion = await _ai.compose(
        draft.images.first,
        categoryId: draft.categoryId,
      );
      if (!mounted) return;
      final apply = await showAiSuggestionSheet(
        context,
        suggestion: suggestion,
        vehicle: ListingCondition.usesVehicleScale(
          draft.categoryId,
          draft.subcategoryId,
        ),
      );
      if (apply == true && mounted) _applySuggestion(suggestion);
    } on ListingAiException catch (error) {
      if (!mounted) return;
      TSnackBarHelper.showError(
        context,
        message: switch (error.code) {
          'AI_NOT_CONFIGURED' => l10n.aiComposeUnavailable,
          'RATE_LIMITED' => error.message ?? l10n.aiComposeFailed,
          _ => l10n.aiComposeFailed,
        },
      );
    } on Exception {
      if (mounted) {
        TSnackBarHelper.showError(context, message: l10n.aiComposeFailed);
      }
    } finally {
      if (mounted) setState(() => _composing = false);
    }
  }

  void _applySuggestion(ListingAiSuggestion suggestion) {
    final title = suggestion.title.characters
        .take(ListingDraft.maxTitleLength)
        .toString();
    final description = suggestion.description.characters
        .take(ListingDraft.maxDescriptionLength)
        .toString();
    if (title.isNotEmpty) {
      _title.text = title;
      _bloc.add(TitleChanged(title));
    }
    if (description.isNotEmpty) {
      _description.text = description;
      _bloc.add(DescriptionChanged(description));
    }
    final condition = suggestion.condition;
    if (condition != null && (_bloc.state.category?.hasCondition ?? true)) {
      _bloc.add(ConditionChanged(condition));
    }
  }

  void _onNext() {
    FocusScope.of(context).unfocus();
    _bloc.add(const DetailsSubmitted());
    final state = _bloc.state;
    if (ListingValidator.isReadyToPublish(state.draft, state.category)) {
      context.push(CreateListingStep.preview.path);
    } else {
      final l10n = AppLocalizations.of(context)!;
      TSnackBarHelper.showWarning(context, message: l10n.missingRequiredFields);
    }
  }

  /// Về bước chọn danh mục (giữ nội dung đã nhập). Sửa tin đã đăng thì
  /// không đổi danh mục: thoát luồng như nút X.
  void _onBack() {
    if (Navigator.of(context).canPop()) {
      context.pop();
    } else if (_bloc.state.isEditing) {
      closeCreateListingFlow(context);
    } else {
      context.pushReplacement(CreateListingStep.category.path);
    }
  }

  void _changeCategory() {
    if (Navigator.of(context).canPop()) {
      context.pop();
    } else {
      context.pushReplacement(CreateListingStep.category.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final desktop = isDesktopLayout(context);

    return BlocBuilder<CreateListingBloc, CreateListingState>(
      builder: (context, state) {
        final draft = state.draft;
        final category = state.category;
        final errors = state.visibleErrors;
        final hasCondition = category?.hasCondition ?? true;
        final attributes = category?.attributes ?? const [];

        return CreateListingScaffold(
          step: CreateListingStep.details,
          title: state.isEditing
              ? l10n.editListingTitle
              : l10n.itemDetailsTitle,
          bottomBar: CreateListingBottomBar(
            primaryLabel: l10n.createListingNext,
            onPrimary: _onNext,
            onBack: _onBack,
          ),
          children: [
            if (state.isEditing) ...[
              const EditListingNotice(),
              const SizedBox(height: 16),
            ],
            if (category != null) ...[
              ListingCategorySummary(
                category: category,
                onChange: state.isEditing ? null : _changeCategory,
              ),
              const SizedBox(height: 24),
            ],
            ListingPhotosSection(
              images: draft.images,
              errorText: errors.has(ListingField.photos)
                  ? l10n.photosRequiredError
                  : null,
            ),
            if (draft.images.isNotEmpty && !AppEnvironment.useMockData) ...[
              const SizedBox(height: 12),
              _AiComposeButton(busy: _composing, onPressed: _composeWithAi),
            ],
            const SizedBox(height: 24),
            ListingLabeledField(
              label: l10n.listingTitleLabel,
              errorText: errors.has(ListingField.title)
                  ? l10n.listingTitleMinLengthError(ListingDraft.minTitleLength)
                  : null,
              child: ListingFilledTextField(
                controller: _title,
                hintText: l10n.listingNameHint,
                maxLength: ListingDraft.maxTitleLength,
                textInputAction: TextInputAction.next,
                hasError: errors.has(ListingField.title),
                onChanged: (value) => _bloc.add(TitleChanged(value)),
              ),
            ),
            if (hasCondition) ...[
              const SizedBox(height: 22),
              ListingConditionField(
                selected: draft.condition,
                vehicle: ListingCondition.usesVehicleScale(
                  draft.categoryId,
                  draft.subcategoryId,
                ),
                errorText: errors.has(ListingField.condition)
                    ? l10n.fieldSelectRequiredError
                    : null,
                onSelected: (value) => _bloc.add(ConditionChanged(value)),
              ),
            ],
            if (attributes.isNotEmpty) ...[
              const SizedBox(height: 30),
              Text(
                l10n.detailedInfoTitle,
                style: ListingFormStyle.sectionTitle.copyWith(fontSize: 19),
              ),
              const SizedBox(height: 16),
              _AttributeGrid(
                columns: desktop ? 2 : 1,
                children: [
                  for (final attribute in attributes)
                    ListingAttributeField(
                      // Key theo danh mục để ô nhập tạo lại khi đổi danh mục
                      key: ValueKey(
                        '${category?.id}_${category?.subcategory?.id}_${attribute.key}',
                      ),
                      attribute: attribute,
                      value: draft.attributes[attribute.key],
                      error: errors.attributes[attribute.key],
                      onChanged: (value) =>
                          _bloc.add(AttributeChanged(attribute.key, value)),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 26),
            ListingLabeledField(
              label: l10n.descriptionOptionalLabel,
              child: ListingFilledTextField(
                controller: _description,
                hintText: l10n.descriptionStoryHint,
                minLines: 5,
                maxLines: 10,
                maxLength: ListingDraft.maxDescriptionLength,
                keyboardType: TextInputType.multiline,
                onChanged: (value) => _bloc.add(DescriptionChanged(value)),
              ),
            ),
            const SizedBox(height: 22),
            _MultipleUnitsRow(
              value: draft.multipleUnits,
              onChanged: (value) => _bloc.add(MultipleUnitsChanged(value)),
            ),
            const SizedBox(height: 30),
            ListingPriceSection(
              draft: draft,
              priceError: errors.has(ListingField.price)
                  ? l10n.priceRequiredError
                  : null,
            ),
            const SizedBox(height: 28),
            ListingMeetUpSection(
              meetUp: draft.meetUp,
              address: draft.address,
              errorText: errors.has(ListingField.location)
                  ? l10n.fieldSelectRequiredError
                  : null,
            ),
            if (state.categoryQuota != null && !state.isEditing) ...[
              const SizedBox(height: 24),
              PostingQuotaNote(quota: state.categoryQuota!),
            ],
            if (category == null &&
                state.categoriesStatus == RequestStatus.success) ...[
              const SizedBox(height: 16),
              _MissingCategory(onChoose: _changeCategory),
            ],
          ],
        );
      },
    );
  }
}

/// "Soạn bằng AI" dưới phần ảnh, kèm ghi chú ảnh bìa được gửi cho AI
class _AiComposeButton extends StatelessWidget {
  const _AiComposeButton({required this.busy, required this.onPressed});

  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: busy ? null : onPressed,
          icon: busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(AppIcons.sparkle),
          label: Text(busy ? l10n.aiComposeLoading : l10n.aiComposeButton),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.actionPrimary,
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        const SizedBox(height: 6),
        Text(l10n.aiComposeHint, style: ListingFormStyle.subtitle),
      ],
    );
  }
}

/// Thuộc tính theo danh mục: 1 cột trên điện thoại, 2 cột trên desktop
class _AttributeGrid extends StatelessWidget {
  const _AttributeGrid({required this.columns, required this.children});

  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (columns == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final child in children)
            Padding(padding: const EdgeInsets.only(bottom: 16), child: child),
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 16.0;
        final width = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: 16,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

/// "Tôi có nhiều hơn một món giống nhau" kèm vòng chọn
class _MultipleUnitsRow extends StatelessWidget {
  const _MultipleUnitsRow({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      checked: value,
      button: true,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.multipleUnitsTitle,
                      style: ListingFormStyle.label.copyWith(fontSize: 17),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.multipleUnitsSubtitle,
                      style: ListingFormStyle.subtitle,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ListingRadioMark(selected: value),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissingCategory extends StatelessWidget {
  const _MissingCategory({required this.onChoose});

  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OutlinedButton(
      onPressed: onChoose,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.actionPrimary,
        minimumSize: const Size.fromHeight(48),
      ),
      child: Text(l10n.chooseCategoryTitle),
    );
  }
}
