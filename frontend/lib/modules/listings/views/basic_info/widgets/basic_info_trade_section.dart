import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/utils/animations/app_animation_durations.dart';
import 'package:restore/core/utils/formatters/currency_formatter.dart';
import 'package:restore/core/utils/formatters/thousands_separator_input_formatter.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_choice_chips.dart';
import 'package:restore/shared/widgets/app_labeled_choice_row.dart';
import 'package:restore/shared/widgets/app_labeled_text_field.dart';
import 'package:restore/shared/widgets/app_switch_tile.dart';
import '../../../bloc/create_listing/create_listing_bloc.dart';
import '../../../bloc/create_listing/create_listing_event.dart';
import '../../../models/listing_draft.dart';
import '../../../models/listing_enums.dart';

/// Hình thức giao dịch, kèm ô giá bán / mong muốn trao đổi
/// hiện hoặc ẩn mượt theo hình thức đang chọn
class BasicInfoTradeSection extends StatefulWidget {
  final TradeType tradeType;
  final bool isNegotiable;
  final bool hasPriceError;

  const BasicInfoTradeSection({
    super.key,
    required this.tradeType,
    required this.isNegotiable,
    this.hasPriceError = false,
  });

  @override
  State<BasicInfoTradeSection> createState() => _BasicInfoTradeSectionState();
}

class _BasicInfoTradeSectionState extends State<BasicInfoTradeSection> {
  final TextEditingController _priceController = TextEditingController();
  late final TextEditingController _exchangeWishController;
  ThousandsSeparatorInputFormatter? _priceFormatter;
  String? _locale;

  CreateListingBloc get _bloc => context.read<CreateListingBloc>();

  @override
  void initState() {
    super.initState();
    _exchangeWishController = TextEditingController(
      text: _bloc.state.draft.exchangeWish,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).toLanguageTag();
    if (locale == _locale) return;
    // Định dạng lại giá theo ngôn ngữ hiện tại (15.000.000 hoặc 15,000,000)
    _locale = locale;
    _priceFormatter = ThousandsSeparatorInputFormatter(locale: locale);
    final price = _bloc.state.draft.price;
    _priceController.text = price == null
        ? ''
        : CurrencyFormatter.formatNumber(price, locale: locale);
  }

  @override
  void dispose() {
    _priceController.dispose();
    _exchangeWishController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tradeType = widget.tradeType;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppLabeledChoiceRow<TradeType>(
          label: l10n.tradeTypeLabel,
          selected: tradeType,
          items: [
            AppChoiceItem(TradeType.sell, l10n.tradeSell),
            AppChoiceItem(TradeType.exchange, l10n.tradeExchange),
            AppChoiceItem(TradeType.sellOrExchange, l10n.tradeSellOrExchange),
          ],
          onSelected: (value) => _bloc.add(TradeTypeChanged(value)),
        ),
        AnimatedSize(
          duration: AppAnimationDurations.normal,
          curve: AppAnimationDurations.enterCurve,
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (tradeType.requiresPrice) ...[
                const SizedBox(height: 16),
                _buildPriceField(l10n),
                const SizedBox(height: 12),
                AppSwitchTile(
                  label: l10n.negotiable,
                  subtitle: l10n.negotiableHint,
                  value: widget.isNegotiable,
                  onChanged: (value) => _bloc.add(NegotiableChanged(value)),
                ),
              ],
              if (tradeType.allowsExchange) ...[
                const SizedBox(height: 16),
                AppLabeledTextField(
                  label: l10n.exchangeWishLabel,
                  controller: _exchangeWishController,
                  hintText: l10n.exchangeWishHint,
                  maxLength: ListingDraft.maxExchangeWishLength,
                  onChanged: (value) => _bloc.add(ExchangeWishChanged(value)),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceField(AppLocalizations l10n) {
    return AppLabeledTextField(
      label: l10n.salePrice,
      isRequired: true,
      controller: _priceController,
      hintText: '0',
      keyboardType: TextInputType.number,
      inputFormatters: [?_priceFormatter],
      helperText: l10n.priceVndHint,
      errorText: widget.hasPriceError ? l10n.priceRequiredError : null,
      suffix: const Text(
        CurrencyFormatter.vndSymbol,
        style: TextStyle(
          fontSize: 16,
          color: AppColors.textPrimary,
          decoration: TextDecoration.underline,
        ),
      ),
      onChanged: (value) => _bloc.add(
        PriceChanged(ThousandsSeparatorInputFormatter.parse(value)),
      ),
    );
  }
}
