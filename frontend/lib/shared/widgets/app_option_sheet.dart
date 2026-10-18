import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/theme/app_glass.dart';
import 'package:restore/core/utils/helpers/vietnamese_text.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/animations/fade_slide_in.dart';
import 'package:restore/core/utils/animations/app_animation_durations.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'glass/app_glass_sheet.dart';

class AppSheetOption<T> {
  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;
  const AppSheetOption(this.value, this.label, {this.subtitle, this.icon});
}

/// Bottom sheet kính mờ chọn một giá trị, trả về `value` (null nếu đóng).
///
/// - Danh sách dài: bật [searchable] (mặc định khi > 8 lựa chọn), tìm không
///   dấu (VD "thu duc").
/// - Ít lựa chọn (≤ 3) và lựa chọn nào cũng có icon: hiện dạng thẻ lớn nằm
///   ngang (VD chụp ảnh / thư viện).
Future<T?> showAppOptionSheet<T>(
  BuildContext context, {
  required String title,
  required List<AppSheetOption<T>> options,
  T? selected,
  bool? searchable,
  String? subtitle,
  IconData? icon,
}) {
  final useSearch = searchable ?? options.length > 8;
  final useCards =
      !useSearch &&
      options.length <= 3 &&
      options.every((option) => option.icon != null);
  return showAppGlassSheet<T>(
    context,
    title: title,
    subtitle: subtitle,
    icon: icon,
    heightFactor: useSearch ? 0.85 : null,
    builder: (_) => useCards
        ? _AppOptionCards<T>(options: options, selected: selected)
        : _AppOptionList<T>(
            options: options,
            selected: selected,
            searchable: useSearch,
          ),
  );
}

class _AppOptionList<T> extends StatefulWidget {
  final List<AppSheetOption<T>> options;
  final T? selected;
  final bool searchable;

  const _AppOptionList({
    required this.options,
    required this.selected,
    required this.searchable,
  });

  @override
  State<_AppOptionList<T>> createState() => _AppOptionListState<T>();
}

class _AppOptionListState<T> extends State<_AppOptionList<T>> {
  String _query = '';

  List<AppSheetOption<T>> get _filtered => _query.isEmpty
      ? widget.options
      : [
          for (final option in widget.options)
            if (VietnameseText.matches(option.label, _query)) option,
        ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final options = _filtered;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.searchable)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _SheetSearchField(
              hint: l10n.searchOptionHint,
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
        Flexible(
          child: options.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        AppIcons.searchEmpty,
                        size: 36,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.noMatchingOptions,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                  itemCount: options.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (_, index) {
                    final tile = _OptionTile<T>(
                      option: options[index],
                      isSelected: options[index].value == widget.selected,
                    );
                    // Chỉ chạy hiệu ứng lần lượt cho vài dòng đầu khi mở sheet
                    return _query.isEmpty && index < 8
                        ? FadeSlideIn(index: index, offsetY: 10, child: tile)
                        : tile;
                  },
                ),
        ),
      ],
    );
  }
}

/// Một dòng lựa chọn dạng thẻ kính; dòng đang chọn có viền ấm và dấu tích
class _OptionTile<T> extends StatelessWidget {
  final AppSheetOption<T> option;
  final bool isSelected;

  const _OptionTile({required this.option, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    return AnimatedContainer(
      duration: AppAnimationDurations.normal,
      curve: AppAnimationDurations.enterCurve,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: isSelected
            ? AppColors.primarySoft.withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.5),
        border: Border.all(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.55)
              : Colors.white.withValues(alpha: 0.9),
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: () => Navigator.of(context).pop(option.value),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                if (option.icon != null) ...[
                  Icon(option.icon!, size: 22, color: AppColors.primaryDark),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.label,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textPrimary,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      if (option.subtitle != null)
                        Text(
                          option.subtitle!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                AnimatedScale(
                  scale: isSelected ? 1 : 0,
                  duration: AppAnimationDurations.normal,
                  curve: Curves.easeOutBack,
                  child: const _CheckBubble(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lựa chọn dạng thẻ lớn nằm ngang, mỗi thẻ có huy hiệu icon
class _AppOptionCards<T> extends StatelessWidget {
  final List<AppSheetOption<T>> options;
  final T? selected;

  const _AppOptionCards({required this.options, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(
              child: FadeSlideIn(
                index: i,
                offsetY: 14,
                child: _OptionCard<T>(
                  option: options[i],
                  isSelected: options[i].value == selected,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionCard<T> extends StatelessWidget {
  final AppSheetOption<T> option;
  final bool isSelected;

  const _OptionCard({required this.option, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(22);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.85),
            Colors.white.withValues(alpha: 0.45),
          ],
        ),
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.white,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: () => Navigator.of(context).pop(option.value),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 18, 12, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppGlassIconBadge(icon: option.icon!, size: 56),
                const SizedBox(height: 12),
                Text(
                  option.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (option.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    option.subtitle!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckBubble extends StatelessWidget {
  const _CheckBubble();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.primary, Color(0xFFF08A3C)],
        ),
      ),
      child: const Icon(AppIcons.check, size: 14, color: Colors.white),
    );
  }
}

class _SheetSearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const _SheetSearchField({required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: AppGlass.stroke),
    );
    return TextField(
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        prefixIcon: const Icon(AppIcons.search, size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.6),
        contentPadding: const EdgeInsets.symmetric(vertical: 13),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
  }
}
