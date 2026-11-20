import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/constants/app_images.dart' show AppImages;
import 'package:restore/core/theme/app_header_palette.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/ai/bloc/ai_assistant_cubit.dart';
import 'package:restore/modules/ai/views/ai_assistant_view.dart';
import 'package:restore/modules/auth/bloc/auth/auth_context.dart';
import 'package:restore/modules/auth/utils/auth_route_guard.dart';
import 'package:restore/modules/chat/bloc/conversations/conversations_cubit.dart';
import 'package:restore/modules/chat/repositories/chat_repository.dart';
import 'package:restore/modules/chat/views/conversation/live_chat_conversation_view.dart';
import 'package:restore/modules/chat/widgets/desktop_conversation_list.dart';

import 'desktop_chat_controller.dart';

/// Cửa sổ chat nổi góc phải dưới (web desktop), kiểu Shopee:
/// - Đóng: bong bóng ReStore AI ở trên, tab "Tin nhắn" dính mép dưới.
/// - Mở: một cửa sổ chia đôi, trái là danh sách (ReStore AI ghim đầu),
///   phải là cuộc trò chuyện đang chọn hoặc ReStore AI.
class DesktopChatDock extends StatefulWidget {
  const DesktopChatDock({
    super.key,
    required this.controller,
    required this.location,
    required this.unread,
  });

  final DesktopChatController controller;
  final String location;
  final int unread;

  static const double windowWidth = 720;
  static const double windowHeight = 580;

  @override
  State<DesktopChatDock> createState() => _DesktopChatDockState();
}

class _DesktopChatDockState extends State<DesktopChatDock> {
  ConversationsCubit? _conversations;
  String? _owner;

  ChatRepository get _repository =>
      AppEnvironment.useMockData ? MockChatRepository() : ApiChatRepository();

  DesktopChatController get _chat => widget.controller;

  /// Danh sách hội thoại theo người đang đăng nhập; đổi tài khoản thì tạo lại
  ConversationsCubit? _conversationsFor(String? userId) {
    if (_owner != userId) {
      _conversations?.close();
      _conversations = null;
      _owner = userId;
    }
    if (userId == null) return null;
    return _conversations ??= ConversationsCubit(_repository)..start();
  }

  AiAssistantCubit _assistant() => _chat.assistantCubit();

  @override
  void dispose() {
    _conversations?.close();
    super.dispose();
  }

  void _openMessages() {
    if (!context.isSignedIn) {
      context.go(loginPath(from: widget.location));
      return;
    }
    _chat.openList();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watchUser();
    final conversations = _chat.isOpen ? _conversationsFor(user?.id) : null;
    if (!_chat.isOpen) {
      // Đổi tài khoản lúc cửa sổ đóng: bỏ danh sách cũ
      if (_owner != user?.id) _conversationsFor(user?.id);
      return Positioned(
        right: 24,
        bottom: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _AiLauncher(onTap: _chat.openAssistant),
            const SizedBox(height: 14),
            _MessagesTab(unread: widget.unread, onTap: _openMessages),
          ],
        ),
      );
    }

    final height = (MediaQuery.sizeOf(context).height - 140).clamp(
      360.0,
      DesktopChatDock.windowHeight,
    );
    return Positioned(
      right: 24,
      bottom: 0,
      width: DesktopChatDock.windowWidth,
      height: height,
      child: Material(
        color: AppColors.surface,
        elevation: 18,
        shadowColor: const Color(0x55291D0B),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
          side: BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _WindowHeader(
              unread: widget.unread,
              onExpand: () {
                _chat.close();
                final id = _chat.conversationId;
                context.go(id == null ? '/messages' : '/messages/$id');
              },
              onClose: _chat.close,
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 260,
                    child: conversations == null
                        ? const SizedBox.shrink()
                        : BlocProvider.value(
                            value: conversations,
                            child: DesktopConversationList(
                              compact: true,
                              selectedId: _chat.conversationId,
                              assistantSelected:
                                  _chat.pane == DesktopChatPane.assistant,
                              onSelect: (chat) =>
                                  _chat.openConversation(chat.id),
                              onAssistant: _chat.openAssistant,
                            ),
                          ),
                  ),
                  const VerticalDivider(width: 1, color: AppColors.border),
                  Expanded(child: _pane()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pane() => switch (_chat.pane) {
    DesktopChatPane.conversation => LiveChatConversationView(
      key: ValueKey(_chat.conversationId),
      conversationId: _chat.conversationId!,
      repository: AppEnvironment.useMockData ? MockChatRepository() : null,
      onBack: _chat.clearSelection,
    ),
    DesktopChatPane.assistant => BlocProvider.value(
      value: _assistant(),
      child: const AiAssistantView(),
    ),
    DesktopChatPane.none => _Welcome(onAssistant: _chat.openAssistant),
  };
}

class _WindowHeader extends StatelessWidget {
  const _WindowHeader({
    required this.unread,
    required this.onExpand,
    required this.onClose,
  });

  final int unread;
  final VoidCallback onExpand;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vi = Localizations.localeOf(context).languageCode == 'vi';
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          const SizedBox(width: 16),
          Text(
            l10n.messagesTitle,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppHeaderPalette.desktopBar,
            ),
          ),
          if (unread > 0) ...[
            const SizedBox(width: 8),
            Text(
              vi ? '($unread chưa đọc)' : '($unread unread)',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const Spacer(),
          IconButton(
            tooltip: vi ? 'Mở trang Tin nhắn' : 'Open messages page',
            onPressed: onExpand,
            icon: const Icon(AppIcons.expand, size: 18),
          ),
          IconButton(
            tooltip: vi ? 'Thu nhỏ' : 'Minimize',
            onPressed: onClose,
            icon: const Icon(AppIcons.chevronDown, size: 20),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.onAssistant});
  final VoidCallback onAssistant;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vi = Localizations.localeOf(context).languageCode == 'vi';
    return ColoredBox(
      color: AppColors.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: Color(0xFFEEF2FC),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  AppIcons.chat,
                  size: 44,
                  color: AppHeaderPalette.desktopBar,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                vi ? 'Chào mừng đến Tin nhắn Restore' : 'Welcome to Restore chat',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                vi
                    ? 'Chọn một cuộc trò chuyện để nhắn với người bán, hoặc hỏi ReStore AI để tìm món phù hợp.'
                    : 'Pick a conversation, or ask ReStore AI to find something for you.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onAssistant,
                icon: Image.asset(AppImages.uiIcons.ai, width: 18, height: 18),
                label: Text(l10n.aiBubbleTooltip),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppHeaderPalette.desktopBar,
                  side: const BorderSide(color: AppHeaderPalette.desktopBar),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bong bóng ReStore AI khi cửa sổ chat đang đóng
class _AiLauncher extends StatefulWidget {
  const _AiLauncher({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_AiLauncher> createState() => _AiLauncherState();
}

class _AiLauncherState extends State<_AiLauncher> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: _hover ? 1 : 0,
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.aiBubbleTooltip,
                  style: const TextStyle(color: Colors.white, fontSize: 12.5),
                ),
              ),
            ),
            AnimatedScale(
              duration: const Duration(milliseconds: 150),
              scale: _hover ? 1.06 : 1,
              child: Container(
                width: 60,
                height: 60,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: Color(0xFFDDE4F7), width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x47213A9D),
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Image.asset(AppImages.uiIcons.ai),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tab "Tin nhắn" dính mép dưới khi cửa sổ chat đang đóng
class _MessagesTab extends StatelessWidget {
  const _MessagesTab({required this.unread, required this.onTap});
  final int unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: AppHeaderPalette.desktopBar,
      elevation: 8,
      shadowColor: const Color(0x66213A9D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        child: SizedBox(
          height: 48,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(AppIcons.chat, size: 20, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  l10n.messagesTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (unread > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    constraints: const BoxConstraints(minWidth: 20),
                    height: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      unread > 99 ? '99+' : '$unread',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error,
                      ),
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
