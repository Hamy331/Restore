import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/utils/formatters/currency_formatter.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/chat/repositories/chat_repository.dart';
import 'package:restore/modules/shell/widgets/desktop_chat_controller.dart';
import 'package:restore/shared/widgets/app_local_image.dart';
import 'package:toastification/toastification.dart';
import '../../../models/product_detail.dart';

void openListingConversation(BuildContext context, String id) {
  DesktopChatScope.maybeOf(context)?.invalidateInbox();
  if (!openDesktopChat(context, conversationId: id)) {
    context.push('/messages/$id');
  }
}

/// Sau khi trả giá: toast nổi "Trả giá thành công · Đi tới trò chuyện" thay
/// vì tự mở cuộc trò chuyện, để người mua xem tiếp tin. 4 giây đủ đọc và bấm
/// nút mà không che màn hình lâu. Hộp thư được làm mới để số tin cập nhật.
///
/// Dùng toastification (overlay của app) vì trang chi tiết tin trên desktop
/// không nằm trong Scaffold nên SnackBar không hiện được.
void showOfferSentToast(BuildContext context, String conversationId) {
  final l = AppLocalizations.of(context)!;
  DesktopChatScope.maybeOf(context)?.invalidateInbox();
  toastification.showCustom(
    context: context,
    // Giữa phía dưới: không che header / ô tìm kiếm trên desktop
    alignment: Alignment.bottomCenter,
    autoCloseDuration: const Duration(seconds: 4),
    builder: (_, item) => Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.fromLTRB(18, 6, 6, 6),
        decoration: BoxDecoration(
          color: const Color(0xFF333333),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                l.offerSentToast,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                toastification.dismiss(item);
                if (context.mounted) {
                  openListingConversation(context, conversationId);
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFFC107),
              ),
              child: Text(
                l.offerSentGoToChat,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

List<String> productQuestions(ProductDetail detail, AppLocalizations l) {
  final fields = {
    ...detail.listing.attributes.keys,
    ...?detail.category?.attributes.map((a) => a.key),
  };
  return [
    if (fields.contains('battery_health') ||
        fields.contains('has_accessories')) ...[
      l.listingAccessories,
      l.listingRepaired,
    ],
    if (fields.contains('warranty') &&
        detail.listing.attributes['warranty'] != 'none')
      l.listingWarranty,
    if (fields.contains('mileage')) l.listingService,
    // Chó, mèo: câu hỏi riêng (không còn ô "Đã tiêm phòng" khi đăng)
    if (const {'cho', 'meo'}.contains(
      detail.category?.subcategory?.id ?? detail.listing.subcategoryId,
    )) ...[
      l.listingVaccines,
      l.listingPetPurebred,
      l.listingPetPapers,
      l.listingPetSupplies,
    ],
    if (detail.listing.allowExchange) l.listingExchange,
    if (detail.canMakeOffer) l.listingNegotiate,
    l.listingMeet,
    l.listingPhotos,
  ];
}

class ListingMessageSender {
  final _repository = ApiChatRepository();
  String? _previousBody;
  String _clientId = '';
  Future<String> send(
    ProductDetail detail,
    String body, {
    int? offerPrice,
  }) async {
    if (body.length > 2000) throw const FormatException('Message too long');
    if (_previousBody != body) {
      _previousBody = body;
      _clientId = newChatClientId();
    }
    final id = await _repository.startConversation(
      detail.seller.id,
      listingId: detail.listing.id,
    );
    await _repository.sendMessage(
      id,
      _clientId,
      body,
      listingId: detail.listing.id,
      offerPrice: offerPrice,
    );
    _previousBody = null;
    return id;
  }
}

Future<String?> showProductChatSheet(
  BuildContext context,
  ProductDetail detail,
) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  backgroundColor: Colors.white,
  builder: (_) => _Composer(detail: detail),
);

class _Composer extends StatefulWidget {
  const _Composer({required this.detail});
  final ProductDetail detail;
  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final _questions = <String>{};
  final _text = TextEditingController();
  final _sender = ListingMessageSender();
  bool _busy = false, _failed = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  String get _body => [
    ..._questions,
    if (_text.text.trim().isNotEmpty) _text.text.trim(),
  ].join('\n');

  Future<void> _send() async {
    if (_busy || (_text.text.trim().isEmpty && _questions.isEmpty)) return;
    final body = _body;
    if (body.length > 2000) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      final id = await _sender.send(widget.detail, body);
      if (mounted) Navigator.pop(context, id);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final listing = widget.detail.listing;
    final suggestions = productQuestions(widget.detail, l);
    Widget chip(String question) => FilterChip(
      label: Text(question),
      selected: _questions.contains(question),
      onSelected: _busy
          ? null
          : (selected) => setState(() {
              if (selected) {
                _questions.add(question);
              } else {
                _questions.remove(question);
              }
            }),
    );
    final remaining = 2000 - _body.length;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (listing.coverImage case final image?) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: AppLocalImage(
                        path: image,
                        width: 46,
                        height: 46,
                        cacheWidth: 144,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
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
                          listing.price == null
                              ? l.homeExchangeOnly
                              : CurrencyFormatter.formatVnd(
                                  listing.price!,
                                  locale: Localizations.localeOf(
                                    context,
                                  ).toLanguageTag(),
                                ),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black26),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.listingAsk,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Wrap(
                      spacing: 6,
                      children: suggestions.take(3).map(chip).toList(),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _text,
                            autofocus: true,
                            readOnly: _busy,
                            minLines: 1,
                            maxLines: 3,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: l.listingMessageHint,
                            ),
                          ),
                        ),
                        IconButton.filled(
                          tooltip: l.listingSend,
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.actionPrimary,
                            foregroundColor: AppColors.onAction,
                          ),
                          onPressed:
                              _busy ||
                                  remaining < 0 ||
                                  (_questions.isEmpty &&
                                      _text.text.trim().isEmpty)
                              ? null
                              : _send,
                          icon: _busy
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.onAction,
                                  ),
                                )
                              : const Icon(Icons.send_outlined),
                        ),
                      ],
                    ),
                    if (remaining < 0)
                      Text(
                        '${_body.length}/2000',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    if (_failed) Text(l.productActionFailed),
                  ],
                ),
              ),
              if (suggestions.length > 3)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Text(l.listingAskMore),
                      for (final question in suggestions.skip(3))
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: chip(question),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
