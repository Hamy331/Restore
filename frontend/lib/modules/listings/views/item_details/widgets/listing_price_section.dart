import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/utils/animations/app_animation_durations.dart';
import 'package:restore/core/utils/formatters/currency_formatter.dart';
import 'package:restore/core/utils/formatters/thousands_separator_input_formatter.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_field_message.dart';
import '../../../bloc/create_listing/create_listing_bloc.dart';
import '../../../bloc/create_listing/create_listing_event.dart';
import '../../../models/listing_draft.dart';
import 'listing_form_widgets.dart';

/// Chọn Bán / Cho tặng, nhập giá và bật giá cố định.
class ListingPriceSection extends StatefulWidget {
  const ListingPriceSection({super.key, required this.draft, this.priceError});

  final ListingDraft draft;
  final String? priceError;

  @override
  State<ListingPriceSection> createState() => _ListingPriceSectionState();
}

class _ListingPriceSectionState extends State<ListingPriceSection> {
  final _price = TextEditingController();
  ThousandsSeparatorInputFormatter? _formatter;
  String? _locale;

  CreateListingBloc get _bloc => context.read<CreateListingBloc>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).toLanguageTag();
    if (locale == _locale) return;
    // Định dạng lại giá theo ngôn ngữ hiện tại (15.000.000 hoặc 15,000,000)
    _locale = locale;
    _formatter = ThousandsSeparatorInputFormatter(locale: locale);
    String format(int? value) => value == null
        ? ''
        : CurrencyFormatter.formatNumber(value, locale: locale);
    _price.text = format(widget.draft.price);
  }

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final draft = widget.draft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.priceSectionTitle, style: ListingFormStyle.sectionTitle),
        const SizedBox(height: 18),
        Row(
          children: [
            _PriceChip(
              label: l10n.priceForSale,
              selected: !draft.isFree,
              onTap: () => _bloc.add(const FreeChanged(false)),
            ),
            const SizedBox(width: 12),
            _PriceChip(
              label: l10n.priceForFree,
              selected: draft.isFree,
              onTap: () => _bloc.add(const FreeChanged(true)),
            ),
          ],
        ),
        AnimatedSize(
          duration: AppAnimationDurations.normal,
          curve: AppAnimationDurations.enterCurve,
          alignment: Alignment.topCenter,
          child: draft.isFree
              ? _FreeNote(text: l10n.freeThanks)
              : _buildSale(l10n, draft),
        ),
      ],
    );
  }

  Widget _buildSale(AppLocalizations l10n, ListingDraft draft) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 22),
        Center(
          child: SizedBox(
            width: 260,
            child: TextField(
              key: const ValueKey('listing-price'),
              controller: _price,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [?_formatter],
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFC9C5BE),
                ),
                suffixText: CurrencyFormatter.vndSymbol,
                suffixStyle: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.only(bottom: 8),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: widget.priceError != null
                        ? AppColors.error
                        : AppColors.border,
                    width: 1.5,
                  ),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: widget.priceError != null
                        ? AppColors.error
                        : AppColors.actionPrimary,
                    width: 2,
                  ),
                ),
              ),
              onChanged: (value) => _bloc.add(
                PriceChanged(ThousandsSeparatorInputFormatter.parse(value)),
              ),
            ),
          ),
        ),
        Center(child: AppFieldMessage(errorText: widget.priceError)),
        const SizedBox(height: 18),
        ListingSwitchRow(
          title: l10n.fixedPriceTitle,
          subtitle: l10n.fixedPriceSubtitle,
          value: draft.fixedPrice,
          onChanged: (value) => _bloc.add(FixedPriceChanged(value)),
        ),
      ],
    );
  }
}

/// Nút chọn hình thức giá dạng viên thuốc
class _PriceChip extends StatelessWidget {
  const _PriceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(30);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.actionSoft : AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected ? AppColors.actionPrimary : AppColors.border,
            width: selected ? 1.5 : 1.2,
          ),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 17,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected
                    ? AppColors.actionPrimaryDark
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FreeNote extends StatelessWidget {
  const _FreeNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 4),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.successBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(AppIcons.gift, color: AppColors.success),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
