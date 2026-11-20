import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/constants/app_images.dart' show AppImages;
import 'package:restore/core/theme/app_header_palette.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/utils/app_image_provider.dart';
import 'package:restore/shared/widgets/loading/app_loading_indicator.dart';

import '../bloc/conversations/conversations_cubit.dart';
import '../bloc/conversations/conversations_state.dart';
import '../models/chat_models.dart';

/// Danh sách hội thoại cho web desktop (cửa sổ chat nổi và trang Tin nhắn):
/// ReStore AI ghim ở đầu, sau đó là các cuộc trò chuyện với người bán/mua.
/// Đọc [ConversationsCubit] từ cây widget.
class DesktopConversationList extends StatefulWidget {
  const DesktopConversationList({
    super.key,
    required this.onSelect,
    required this.onAssistant,
    this.selectedId,
    this.assistantSelected = false,
    this.compact = false,
  });

  final ValueChanged<ChatConversation> onSelect;
  final VoidCallback onAssistant;
  final String? selectedId;
  final bool assistantSelected;

  /// Cửa sổ nổi: chữ và ảnh nhỏ hơn
  final bool compact;

  @override
  State<DesktopConversationList> createState() =>
      _DesktopConversationListState();
}

class _DesktopConversationListState extends State<DesktopConversationList> {
  final _query = TextEditingController();
  bool _unreadOnly = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vi = Localizations.localeOf(context).languageCode == 'vi';
    String t(String vn, String en) => vi ? vn : en;
    final compact = widget.compact;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(compact ? 10 : 14),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: compact ? 34 : 40,
                  child: TextField(
                    controller: _query,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: t('Tìm theo tên', 'Search by name'),
                      hintStyle: const TextStyle(fontSize: 13),
                      prefixIcon: const Icon(AppIcons.search, size: 16),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 36,
                      ),
                      fillColor: AppColors.background,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: Text(t('Chưa đọc', 'Unread')),
                selected: _unreadOnly,
                onSelected: (value) => setState(() => _unreadOnly = value),
                labelStyle: const TextStyle(fontSize: 12),
                visualDensity: VisualDensity.compact,
                selectedColor: const Color(0xFFDDE4F7),
                side: const BorderSide(color: AppColors.border),
                showCheckmark: false,
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: BlocBuilder<ConversationsCubit, ConversationsState>(
            builder: (context, state) {
              final query = _query.text.trim().toLowerCase();
              final items = state.conversations.where((chat) {
                if (_unreadOnly && chat.unreadCount == 0) return false;
                return query.isEmpty ||
                    chat.otherUser.fullName.toLowerCase().contains(query);
              }).toList();
              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  _AssistantTile(
                    selected: widget.assistantSelected,
                    compact: compact,
                    onTap: widget.onAssistant,
                  ),
                  if (state.loading)
                    const Padding(
                      padding: EdgeInsets.all(28),
                      child: Center(child: AppLoadingIndicator()),
                    )
                  else if (state.failed && state.conversations.isEmpty)
                    Center(
                      child: TextButton(
                        onPressed: context.read<ConversationsCubit>().load,
                        child: Text(
                          t(
                            'Không tải được tin nhắn. Thử lại',
                            'Could not load messages. Retry',
                          ),
                        ),
                      ),
                    )
                  else if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(28),
                      child: Text(
                        t(
                          'Chưa có cuộc trò chuyện nào',
                          'No conversations yet',
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  else
                    for (final chat in items)
                      _ConversationTile(
                        conversation: chat,
                        compact: compact,
                        selected: chat.id == widget.selectedId,
                        onTap: () => widget.onSelect(chat),
                      ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AssistantTile extends StatelessWidget {
  const _AssistantTile({
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = compact ? 38.0 : 46.0;
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          // Màu trơn: xanh nhạt theo logo, đậm hơn khi đang chọn
          color: selected ? const Color(0xFFDDE4F7) : const Color(0xFFEEF2FC),
          border: Border(
            left: BorderSide(
              color: selected ? AppHeaderPalette.desktopBar : Colors.transparent,
              width: 3,
            ),
            bottom: const BorderSide(color: Color(0xFFF5F1EA)),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 14,
              vertical: compact ? 9 : 12,
            ),
            child: Row(
              children: [
                Container(
                  width: size,
                  height: size,
                  padding: EdgeInsets.all(size * 0.16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFC9D3F0)),
                  ),
                  child: Image.asset(AppImages.uiIcons.ai),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            l10n.restoreAi,
                            style: TextStyle(
                              fontSize: compact ? 13 : 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppHeaderPalette.desktopBar,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'AI',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.aiBubbleTooltip,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: compact ? 12 : 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.push_pin_outlined,
                  size: 15,
                  color: AppHeaderPalette.desktopBar,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.compact,
    required this.selected,
    required this.onTap,
  });

  final ChatConversation conversation;
  final bool compact;
  final bool selected;
  final VoidCallback onTap;

  String _time(BuildContext context) {
    final at = conversation.lastMessage?.createdAt;
    if (at == null) return '';
    final now = DateTime.now();
    final locale = Localizations.localeOf(context).toLanguageTag();
    if (at.year == now.year && at.month == now.month && at.day == now.day) {
      return DateFormat.Hm(locale).format(at);
    }
    return DateFormat('dd/MM', locale).format(at);
  }

  @override
  Widget build(BuildContext context) {
    final person = conversation.otherUser;
    final initial = person.fullName.isNotEmpty
        ? person.fullName[0].toUpperCase()
        : '?';
    final radius = compact ? 19.0 : 23.0;
    final unread = conversation.unreadCount;
    final product = conversation.trade?.product;
    return Material(
      color: selected ? const Color(0xFFEEF2FC) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: selected ? AppHeaderPalette.desktopBar : Colors.transparent,
                width: 3,
              ),
              bottom: const BorderSide(color: Color(0xFFF5F1EA)),
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 14,
            vertical: compact ? 9 : 12,
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: radius,
                    backgroundColor: const Color(0xFFEEF2FC),
                    foregroundImage: person.avatarUrl != null
                        ? appImageProvider(person.avatarUrl!)
                        : null,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: AppHeaderPalette.desktopBar,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (person.isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22A06B),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 13 : 14,
                        fontWeight: unread > 0
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      conversation.lastMessage?.text ?? activityLabel(person),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 12 : 12.5,
                        color: unread > 0
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _time(context),
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  if (unread > 0)
                    Container(
                      constraints: const BoxConstraints(minWidth: 17),
                      height: 17,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        '$unread',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 17),
                ],
              ),
              if (!compact && product?.image != null) ...[
                const SizedBox(width: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image(
                    image: appImageProvider(product!.image!),
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox(
                      width: 40,
                      height: 40,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
