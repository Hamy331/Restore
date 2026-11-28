import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:restore/modules/location/models/address_info.dart';
import 'package:restore/modules/location/repositories/location_repository.dart';
import 'package:restore/modules/location/widgets/address_picker_sheet.dart';
import 'package:restore/services/device_location_service.dart';
import '../../repositories/chat_repository.dart';
import '../../widgets/chat_attachment.dart';
import 'chat_info_view.dart';
import 'package:flutter/material.dart';
import 'package:restore/shared/widgets/loading/app_loading_indicator.dart';
import 'package:restore/shared/utils/app_image_provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import '../../bloc/conversation/conversation_cubit.dart';
import '../../bloc/conversation/conversation_state.dart';
import '../../models/chat_models.dart';
import '../../widgets/trade_panel.dart';
import '../../widgets/chat_product_preview.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/listings/repositories/product_detail_repository.dart';
import 'package:restore/modules/listings/views/product_detail/widgets/product_detail_offer_sheet.dart';

/// Chỉ giữ controller của ô soạn tin và danh sách; dữ liệu nằm ở cubit.
class LiveChatConversationMobileView extends StatefulWidget {
  const LiveChatConversationMobileView({super.key, this.onBack});

  /// Nhúng trong cửa sổ chat nổi: quay về danh sách thay vì đóng trang
  final VoidCallback? onBack;

  @override
  State<LiveChatConversationMobileView> createState() =>
      _LiveChatConversationMobileViewState();
}

class _LiveChatConversationMobileViewState
    extends State<LiveChatConversationMobileView> {
  final composer = TextEditingController();
  final scrollController = ScrollController();
  bool openingOffer = false;
  bool uploading = false;
  XFile? attachment;
  String? attachmentId;
  ChatProduct? quoted;
  final focus = FocusNode();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ModalRoute.isCurrentOf(context) ?? true) {
      context.read<ConversationCubit>().markVisible();
    }
  }

  void notice(String value) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(value)));

  Future<void> manage(ChatConversation chat) async {
    final result = await Navigator.push<ChatInfoResult>(
      context,
      MaterialPageRoute(builder: (_) => ChatInfoView(chat: chat)),
    );
    if (!mounted) return;
    if (result?.hidden == true) {
      context.go('/messages');
      return;
    }
    final cubit = context.read<ConversationCubit>();
    final selected = result?.selection;
    if (selected == null) {
      await cubit.load(silent: true);
      return;
    }
    await cubit.selectProduct(selected.contextId);
    if (mounted) {
      setState(() => quoted = selected.product);
      focus.requestFocus();
    }
  }

  Future<void> choose(String action) async {
    final cubit = context.read<ConversationCubit>();
    try {
      if (action == 'address') {
        const storage = FlutterSecureStorage();
        final key = 'chat_address_${cubit.state.selfId}';
        AddressInfo? initial;
        try {
          final value = await storage.read(key: key);
          if (value != null) {
            initial = AddressInfo.fromJson(
              jsonDecode(value) as Map<String, dynamic>,
            );
          }
        } catch (_) {
          /* A saved address is optional. */
        }
        if (!mounted) return;
        final address = await showAddressPickerSheet(
          context,
          initial: initial,
          locationRepository: ApiLocationRepository(),
          deviceLocationService: DeviceLocationService(),
        );
        if (!mounted || address == null) return;
        composer.value = TextEditingValue(
          text: [
            if (composer.text.trim().isNotEmpty) composer.text.trim(),
            address.fullLabel,
          ].join('\n'),
        );
        focus.requestFocus();
        try {
          await storage.write(key: key, value: jsonEncode(address.toJson()));
        } catch (_) {
          /* The draft is already available. */
        }
        return;
      }
      final file = await ImagePicker().pickMedia(
        maxWidth: 1920,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (file == null || !mounted) return;
      final video =
          file.mimeType?.startsWith('video/') == true ||
          RegExp(
            r'\.(mp4|mov|webm)$',
            caseSensitive: false,
          ).hasMatch(file.name);
      final limit = video ? 25 : 5;
      if (await file.length() > limit * 1024 * 1024) {
        if (mounted) notice('Tệp vượt quá $limit MB.');
        return;
      }
      if (mounted) {
        setState(() {
          attachment = file;
          attachmentId = newChatClientId();
        });
      }
    } catch (_) {
      if (mounted) notice('Không mở được tệp hoặc địa chỉ. Vui lòng thử lại.');
    }
  }

  Future<void> offer(ChatProduct product) async {
    if (openingOffer) return;
    setState(() => openingOffer = true);
    try {
      final detail = await ApiProductDetailRepository().getDetail(product.id);
      if (!mounted) return;
      if (!detail.isAvailable || !detail.canMakeOffer || detail.isOwner) {
        throw StateError('Offer unavailable');
      }
      final id = await showProductOfferSheet(context, detail);
      if (mounted && id != null) {
        await context.read<ConversationCubit>().load(silent: true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.productActionFailed),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => openingOffer = false);
    }
  }

  @override
  void dispose() {
    focus.dispose();
    composer.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> send() async {
    final cubit = context.read<ConversationCubit>();
    if (uploading || cubit.state.conversation?.blocked == true) {
      return;
    }
    final file = attachment;
    if (file != null) {
      setState(() => uploading = true);
      try {
        final message = await ApiChatRepository().upload(
          cubit.conversationId,
          attachmentId!,
          await file.readAsBytes(),
        );
        if (!mounted) return;
        setState(() => attachment = null);
        cubit.acceptMessage(message);
      } catch (error) {
        if (mounted) {
          notice(
            error is DioException && error.response?.statusCode == 415
                ? 'Chọn ảnh JPEG, PNG, WebP hoặc video MP4, MOV, WebM.'
                : 'Gửi tệp thất bại. Bấm gửi để thử lại.',
          );
        }
        return;
      } finally {
        if (mounted) setState(() => uploading = false);
      }
    }
    if (!mounted) return;
    final text = composer.text;
    if (text.trim().isNotEmpty) {
      final listingId = quoted?.id;
      composer.clear();
      setState(() => quoted = null);
      await cubit.send(text, listingId: listingId);
    }
    if (scrollController.hasClients) scrollController.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ConversationCubit>();
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: BlocConsumer<ConversationCubit, ConversationState>(
          listenWhen: (previous, current) => current.sendFailed,
          listener: (context, state) {
            if (state.sendFailed) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Không gửi được tin nhắn. Thử lại nhé.'),
                ),
              );
            }
          },
          builder: (context, state) {
            final person = state.conversation?.otherUser;
            final trade = state.conversation?.trade;
            // Tin cuối mình gửi: hiện trạng thái Đã gửi / Đã xem
            final lastMine = state.messages.where(state.isMine).lastOrNull;
            return Column(
              children: [
                Material(
                  color: AppColors.surface,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: kToolbarHeight,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Quay lại',
                          onPressed:
                              widget.onBack ??
                              () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go('/messages');
                                }
                              },
                          icon: const Icon(AppIcons.back),
                        ),
                        if (person != null) _Header(person: person),
                        if (state.conversation case final chat?)
                          IconButton(
                            tooltip: 'Thông tin hội thoại',
                            icon: const Icon(Icons.format_list_bulleted),
                            onPressed: () => manage(chat),
                          ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF0F2F5)),
                if (trade?.product case final product?)
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ChatProductPreview(
                            product: product,
                            onTap: () =>
                                context.push('/listings/${product.id}'),
                          ),
                        ),
                        if (trade!.canOffer &&
                            state.conversation?.blocked == false) ...[
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: openingOffer
                                ? null
                                : () => offer(product),
                            child: Text(
                              AppLocalizations.of(context)!.productOfferTitle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                if (state.conversation?.blocked == false &&
                    state.conversation?.trade != null)
                  TradePanel(
                    trade: trade!,
                    conversation: state.conversation!,
                    refresh: () => cubit.load(silent: true),
                  ),
                if (state.loading)
                  const Expanded(child: Center(child: AppLoadingIndicator()))
                else if (state.failed)
                  Expanded(
                    child: Center(
                      child: TextButton(
                        onPressed: cubit.load,
                        child: const Text(
                          'Không tải được cuộc trò chuyện. Thử lại',
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ListView.builder(
                        shrinkWrap: true,
                        controller: scrollController,
                        padding: const EdgeInsets.all(14),
                        reverse: true,
                        itemCount:
                            state.messages.length + (state.hasOlder ? 1 : 0),
                        itemBuilder: (_, offset) {
                          if (offset == state.messages.length) {
                            return TextButton(
                              onPressed: () async {
                                try {
                                  await cubit.older();
                                } catch (_) {
                                  if (mounted) {
                                    notice('Không tải được tin nhắn cũ.');
                                  }
                                }
                              },
                              child: const Text('Xem tin nhắn trước'),
                            );
                          }
                          final index = state.messages.length - 1 - offset;
                          final message = state.messages[index];
                          final first =
                              index == 0 ||
                              !DateUtils.isSameDay(
                                message.createdAt,
                                state.messages[index - 1].createdAt,
                              );
                          return Column(
                            key: ValueKey(message.id),
                            children: [
                              if (first)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  child: Text(
                                    DateFormat(
                                      'EEEE, dd/MM/yyyy',
                                      Localizations.localeOf(
                                        context,
                                      ).languageCode,
                                    ).format(message.createdAt),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ),
                              _MessageBubble(
                                message: message,
                                thread: cubit.conversationId,
                                mine: state.isMine(message),
                                // Tin cuối mình gửi: Đã gửi / Đã xem
                                seen:
                                    message.delivery == null &&
                                        message.id == lastMine?.id
                                    ? (message.sequence ?? 0) <=
                                          (state
                                                  .conversation
                                                  ?.otherReadSequence ??
                                              0)
                                    : null,
                                onOpenProduct: message.product == null
                                    ? null
                                    : () => context.push(
                                        '/listings/${message.product!.id}',
                                      ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                if (state.conversation?.blocked == true)
                  const SafeArea(
                    top: false,
                    child: Padding(
                      padding: EdgeInsets.all(14),
                      child: Text('Nhắn tin đã bị chặn.'),
                    ),
                  )
                else ...[
                  if (quoted case final product?)
                    ListTile(
                      title: ChatProductPreview(
                        product: product,
                        compact: true,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => quoted = null),
                      ),
                    ),
                  if (attachment case final file?)
                    ListTile(
                      leading: const Icon(Icons.attachment),
                      title: Text(
                        file.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: uploading
                            ? null
                            : () => setState(() => attachment = null),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                    child: Row(
                      children: [
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.add_circle_outline),
                          tooltip: 'Đính kèm',
                          enabled: !uploading && person != null,
                          onSelected: choose,
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'media',
                              child: Text('Hình và video'),
                            ),
                            PopupMenuItem(
                              value: 'address',
                              child: Text('Gửi địa chỉ'),
                            ),
                          ],
                        ),
                        Expanded(
                          child: TextField(
                            focusNode: focus,
                            controller: composer,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => send(),
                            decoration: const InputDecoration(
                              hintText: 'Nhắn tin...',
                              fillColor: AppColors.surface,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(8),
                                ),
                                borderSide: BorderSide(
                                  color: Color(0xFFE5E7EB),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(8),
                                ),
                                borderSide: BorderSide(
                                  color: AppColors.actionPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Gửi tin nhắn',
                          onPressed: uploading || person == null ? null : send,
                          icon: uploading
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(AppIcons.send),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.person});
  final ChatPerson person;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Row(
      children: [
        CircleAvatar(
          radius: 19,
          backgroundImage: person.avatarUrl != null
              ? appImageProvider(person.avatarUrl!)
              : null,
          child: person.avatarUrl == null
              ? Text(person.fullName.isEmpty ? '?' : person.fullName[0])
              : null,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                person.fullName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                activityLabel(person),
                style: TextStyle(
                  fontSize: 11,
                  color: person.isOnline
                      ? const Color(0xFF22A06B)
                      : const Color(0xFF70695F),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.mine,
    required this.thread,
    this.onOpenProduct,
    this.seen,
  });
  final ChatMessage message;
  final bool mine;
  final String thread;
  final VoidCallback? onOpenProduct;

  /// Chỉ có ở tin cuối mình gửi: true "Đã xem", false "Đã gửi"
  final bool? seen;

  @override
  Widget build(BuildContext context) {
    final time = message.createdAt;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 285),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: mine ? AppColors.actionSoft : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (message.delivery case final status?)
              TextButton(
                onPressed: message.retryable
                    ? () => context.read<ConversationCubit>().retry(message.id)
                    : null,
                child: Text(status),
              ),
            if (message.product case final product?) ...[
              ChatProductPreview(
                product: product,
                compact: true,
                onTap: onOpenProduct,
              ),
              const SizedBox(height: 8),
            ],
            if (message.mediaName != null)
              ChatAttachment(thread: thread, message: message)
            else if (message.product != null)
              Align(alignment: Alignment.centerLeft, child: Text(message.text))
            else
              Text(message.text),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  [
                    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                    if ((seen, AppLocalizations.of(context)) case (
                      final seen?,
                      final l?,
                    ))
                      seen ? l.chatSeen : l.chatSent,
                  ].join(' | '),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF70695F),
                  ),
                ),
                if (seen == true) ...[
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.check_circle,
                    size: 11,
                    color: Color(0xFF70695F),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
