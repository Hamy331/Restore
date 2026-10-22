import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/utils/formatters/currency_formatter.dart';
import 'package:restore/core/utils/formatters/thousands_separator_input_formatter.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_action_buttons.dart';
import 'package:restore/shared/widgets/app_labeled_text_field.dart';
import 'package:restore/shared/widgets/glass/app_glass_sheet.dart';

/// Mở sheet trả giá, trả về số tiền người mua đề nghị (null khi đóng)
Future<int?> showProductOfferSheet(BuildContext context, {required int price}) {
  final l10n = AppLocalizations.of(context)!;
  final locale = Localizations.localeOf(context).toLanguageTag();
  return showAppGlassSheet<int>(
    context,
    title: l10n.productOfferTitle,
    subtitle: l10n.productOfferSubtitle(
      CurrencyFormatter.formatVnd(price, locale: locale),
    ),
    icon: AppIcons.offer,
    builder: (_) => _OfferForm(price: price),
  );
}

class _OfferForm extends StatefulWidget {
  final int price;

  const _OfferForm({required this.price});

  @override
  State<_OfferForm> createState() => _OfferFormState();
}

class _OfferFormState extends State<_OfferForm> {
  /// Gợi ý nhanh theo % so với giá đang bán, cho phép trả cao hơn khi
  /// muốn được ưu tiên lúc nhiều người cùng trả giá
  static const List<int> _suggestions = [-10, -5, 5];

  /// Giá đề nghị tối đa gấp mấy lần giá đang bán, chặn gõ nhầm số 0
  static const int _maxRatio = 2;

  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _locale => Localizations.localeOf(context).toLanguageTag();

  int _adjusted(int percent) =>
      // Làm tròn tới nghìn đồng cho dễ đọc
      (widget.price * (100 + percent) / 100 / 1000).round() * 1000;

  void _applyAmount(int amount) {
    final text = CurrencyFormatter.formatNumber(amount, locale: _locale);
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    setState(() => _error = null);
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final amount = ThousandsSeparatorInputFormatter.parse(_controller.text);
    final error = switch (amount) {
      null || <= 0 => l10n.productOfferInvalid,
      final value when value > widget.price * _maxRatio =>
        l10n.productOfferTooHigh,
      _ => null,
    };
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(amount);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final current = ThousandsSeparatorInputFormatter.parse(_controller.text);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppLabeledTextField(
            label: l10n.productOfferAmountLabel,
            isRequired: true,
            controller: _controller,
            hintText: l10n.productOfferAmountHint,
            errorText: _error,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              ThousandsSeparatorInputFormatter(locale: _locale),
            ],
            onChanged: (_) => setState(() => _error = null),
            suffix: const Text(
              CurrencyFormatter.vndSymbol,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            alignment: Alignment.topCenter,
            child: current == null || current <= 0 || _error != null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _PriceDelta(
                      amount: current,
                      price: widget.price,
                      locale: _locale,
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final (i, percent) in _suggestions.indexed) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _SuggestionTile(
                    percent: percent,
                    amount: _adjusted(percent),
                    locale: _locale,
                    selected: current == _adjusted(percent),
                    onTap: () => _applyAmount(_adjusted(percent)),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          AppPrimaryActionButton(
            label: l10n.productOfferSubmit,
            icon: AppIcons.send,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

/// Giá đề nghị cao / thấp hơn giá gốc bao nhiêu %, cập nhật khi đang gõ
class _PriceDelta extends StatelessWidget {
  final int amount;
  final int price;
  final String locale;

  const _PriceDelta({
    required this.amount,
    required this.price,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final difference = amount - price;
    final percent = NumberFormat(
      '#,##0.#',
      locale,
    ).format(difference.abs() * 100 / price);
    final money = CurrencyFormatter.formatVnd(difference.abs(), locale: locale);
    final (icon, color, background, text) = switch (difference.sign) {
      1 => (
        AppIcons.priceUp,
        AppColors.success,
        AppColors.successBg,
        l10n.productOfferAbove('$percent%', money),
      ),
      -1 => (
        AppIcons.priceDown,
        AppColors.primaryDark,
        AppColors.primarySoft,
        l10n.productOfferBelow('$percent%', money),
      ),
      _ => (
        AppIcons.priceEqual,
        AppColors.textSecondary,
        AppColors.background,
        l10n.productOfferEqual,
      ),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ô gợi ý giá nhanh: mức % so với giá gốc và số tiền tương ứng
class _SuggestionTile extends StatelessWidget {
  final int percent;
  final int amount;
  final String locale;
  final bool selected;
  final VoidCallback onTap;

  const _SuggestionTile({
    required this.percent,
    required this.amount,
    required this.locale,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        borderRadius: radius,
        color: selected
            ? AppColors.primarySoft
            : Colors.white.withValues(alpha: 0.7),
        border: Border.all(
          color: selected
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.25),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            child: Column(
              children: [
                Text(
                  percent > 0 ? '+$percent%' : '$percent%',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    CurrencyFormatter.formatVnd(amount, locale: locale),
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
