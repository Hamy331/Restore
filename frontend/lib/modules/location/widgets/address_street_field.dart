import 'dart:async';

import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/theme/app_glass.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_labeled_text_field.dart';

import '../models/address_suggestion.dart';
import '../repositories/address_suggest_repository.dart';

/// Ô số nhà, tên đường (không bắt buộc, không hiển thị công khai).
/// Có [suggest] thì gõ tới đâu gợi ý tên đường tới đó, danh sách hiện ngay
/// dưới ô; chọn một gợi ý thì điền vào ô và báo [onSuggestionSelected].
class AddressStreetField extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;
  final Future<List<AddressSuggestion>> Function(String query)? suggest;
  final ValueChanged<AddressSuggestion>? onSuggestionSelected;

  static const int maxLength = 120;

  /// Chờ người dùng ngừng gõ một chút rồi mới gọi gợi ý
  static const Duration debounce = Duration(milliseconds: 350);

  const AddressStreetField({
    super.key,
    required this.initialValue,
    required this.onChanged,
    this.suggest,
    this.onSuggestionSelected,
  });

  @override
  State<AddressStreetField> createState() => _AddressStreetFieldState();
}

class _AddressStreetFieldState extends State<AddressStreetField> {
  late final TextEditingController _controller;
  Timer? _debounce;
  List<AddressSuggestion> _suggestions = const [];
  bool _loading = false;

  /// Tăng mỗi lần gõ để bỏ kết quả về muộn của lần gõ trước
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    widget.onChanged(value);
    final suggest = widget.suggest;
    if (suggest == null) return;
    _debounce?.cancel();
    final request = ++_request;
    final query = value.trim();
    if (query.length < AddressSuggestRepository.minQueryLength) {
      setState(() {
        _suggestions = const [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(AddressStreetField.debounce, () async {
      List<AddressSuggestion> results;
      try {
        results = await suggest(query);
      } catch (_) {
        // Lỗi gợi ý không chặn việc gõ tay
        results = const [];
      }
      if (!mounted || request != _request) return;
      setState(() {
        _suggestions = results;
        _loading = false;
      });
    });
  }

  void _select(AddressSuggestion suggestion) {
    _debounce?.cancel();
    _request++;
    final text = suggestion.label.length > AddressStreetField.maxLength
        ? suggestion.label.substring(0, AddressStreetField.maxLength)
        : suggestion.label;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    setState(() {
      _suggestions = const [];
      _loading = false;
    });
    widget.onChanged(text);
    widget.onSuggestionSelected?.call(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppLabeledTextField(
          label: l10n.streetAddressLabel,
          controller: _controller,
          hintText: l10n.streetAddressHint,
          helperText: l10n.streetAddressHelper,
          maxLength: AddressStreetField.maxLength,
          textInputAction: TextInputAction.done,
          onChanged: _onChanged,
          suffix: _loading
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
        ),
        if (_suggestions.isNotEmpty)
          _SuggestionList(
            title: l10n.streetSuggestionsTitle,
            suggestions: _suggestions,
            onSelected: _select,
          ),
      ],
    );
  }
}

class _SuggestionList extends StatelessWidget {
  final String title;
  final List<AddressSuggestion> suggestions;
  final ValueChanged<AddressSuggestion> onSelected;

  const _SuggestionList({
    required this.title,
    required this.suggestions,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: AppGlass.fillStrong,
        borderRadius: BorderRadius.circular(AppGlass.fieldRadius),
        border: Border.all(color: AppGlass.stroke),
        boxShadow: AppGlass.shadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          for (final suggestion in suggestions)
            InkWell(
              onTap: () => onSelected(suggestion),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    const Icon(
                      AppIcons.location,
                      size: 18,
                      color: AppColors.primaryDark,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            suggestion.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (suggestion.description.isNotEmpty)
                            Text(
                              suggestion.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
