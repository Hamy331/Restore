import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/utils/formatters/currency_formatter.dart';
import 'package:restore/core/utils/formatters/thousands_separator_input_formatter.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_local_image.dart';
import '../../../models/product_detail.dart';
import 'product_chat_sheet.dart';
import 'product_detail_section.dart';

Future<String?> showProductOfferSheet(
  BuildContext context,
  ProductDetail detail, {
  String initial = '',
}) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.white,
  builder: (_) => _OfferForm(detail: detail, initial: initial),
);

class ProductDealSection extends StatefulWidget {
  final ProductDetail detail;
  final bool Function() signedIn;
  const ProductDealSection({
    super.key,
    required this.detail,
    required this.signedIn,
  });
  @override
  State<ProductDealSection> createState() => _DealState();
}

class _DealState extends State<ProductDealSection> {
  final _amount = TextEditingController();
  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    if (!widget.signedIn()) return;
    final id = await showProductOfferSheet(
      context,
      widget.detail,
      initial: _amount.text,
    );
    if (mounted && id != null) {
      _amount.clear();
      showOfferSentToast(context, id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!,
        locale = Localizations.localeOf(context).toLanguageTag();
    return ProductDetailSection(
      title: l.sellerDeal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _amount,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    ThousandsSeparatorInputFormatter(locale: locale),
                  ],
                  decoration: InputDecoration(
                    hintText: l.productOfferAmountHint,
                    suffixText: 'đ',
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xfff4f4f4),
                  foregroundColor: Colors.black87,
                ),
                onPressed: _open,
                child: Text(l.productOfferTitle),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l.productOfferSubtitle(
              CurrencyFormatter.formatVnd(
                widget.detail.listing.price!,
                locale: locale,
              ),
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _OfferForm extends StatefulWidget {
  final ProductDetail detail;
  final String initial;
  const _OfferForm({required this.detail, required this.initial});
  @override
  State<_OfferForm> createState() => _OfferState();
}

class _OfferState extends State<_OfferForm> {
  late final _amount = TextEditingController(text: widget.initial);
  final _note = TextEditingController();
  final _sender = ListingMessageSender();
  bool _initialized = false, _busy = false, _failed = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _note.text = AppLocalizations.of(context)!.sellerOfferNote;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!,
        listing = widget.detail.listing,
        locale = Localizations.localeOf(context).toLanguageTag();
    final price = listing.price!,
        amount = ThousandsSeparatorInputFormatter.parse(_amount.text);
    final valid =
        amount != null &&
        amount > 0 &&
        amount <= price * 2 &&
        _note.text.trim().isNotEmpty;
    String money(int n) => CurrencyFormatter.formatVnd(n, locale: locale);
    return PopScope(
      canPop: !_busy,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: CloseButton(
                        onPressed: _busy ? () {} : () => Navigator.pop(context),
                      ),
                    ),
                    Text(
                      l.productOfferTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  children: [
                    if (listing.coverImage case final image?)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: AppLocalImage(
                            path: image,
                            width: 44,
                            height: 44,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            listing.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            money(price),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _note,
                  enabled: !_busy,
                  maxLength: 50,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: l.listingMessageHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
                TextField(
                  controller: _amount,
                  autofocus: true,
                  enabled: !_busy,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    ThousandsSeparatorInputFormatter(locale: locale),
                  ],
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: l.productOfferAmountLabel,
                    suffixText: 'đ',
                    errorText: amount != null && amount > price * 2
                        ? l.productOfferTooHigh
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final percent in [5, 10, 15])
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            label: Text(
                              '${money((price * (100 - percent) / 100).round())} (-$percent%)',
                            ),
                            onPressed: _busy
                                ? null
                                : () {
                                    final text = CurrencyFormatter.formatNumber(
                                      (price * (100 - percent) / 100).round(),
                                      locale: locale,
                                    );
                                    setState(
                                      () => _amount.value = TextEditingValue(
                                        text: text,
                                        selection: TextSelection.collapsed(
                                          offset: text.length,
                                        ),
                                      ),
                                    );
                                  },
                          ),
                        ),
                    ],
                  ),
                ),
                if (_failed) Text(l.productActionFailed),
                const SizedBox(height: 10),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.actionPrimary,
                    foregroundColor: AppColors.onAction,
                  ),
                  onPressed: !valid || _busy
                      ? null
                      : () async {
                          setState(() {
                            _busy = true;
                            _failed = false;
                          });
                          try {
                            final id = await _sender.send(
                              widget.detail,
                              '${l.productOfferAmountLabel}: ${money(amount)}\n${_note.text.trim()}',
                            );
                            if (context.mounted) Navigator.pop(context, id);
                          } catch (_) {
                            if (mounted) {
                              setState(() {
                                _failed = true;
                                _busy = false;
                              });
                            }
                          }
                        },
                  child: Text(l.listingSend),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
