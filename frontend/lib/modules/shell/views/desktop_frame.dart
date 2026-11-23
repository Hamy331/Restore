import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_dimesions.dart';
import 'package:restore/modules/account/views/account/account_desktop_shell.dart';
import 'package:restore/modules/ai/bloc/ai_assistant_cubit.dart';
import 'package:restore/modules/auth/bloc/auth/auth_context.dart';
import 'package:restore/modules/chat/repositories/chat_repository.dart';
import 'package:restore/modules/chat/views/messages/live_messages_view.dart';
import 'package:restore/modules/my_shop/utils/shop_session.dart';
import 'package:restore/modules/plans/utils/plan_session.dart';
import 'package:restore/shared/widgets/desktop/desktop_header.dart';

import '../bloc/shell_badges_cubit.dart';
import '../widgets/desktop_chat_controller.dart';
import '../widgets/desktop_chat_dock.dart';

/// Bố cục trang của một đường dẫn trên web desktop
enum DesktopPageKind {
  /// Trang đã có bố cục desktop riêng (tự căn giữa 1200px, có footer)
  wide,

  /// Nhóm Tài khoản: menu trái + nội dung phải
  account,

  /// Trang chưa có bố cục desktop: đặt giữa màn hình, rộng tối đa 960px
  narrow,
}

DesktopPageKind desktopPageKindOf(String path, {String? userId}) {
  if (path == '/home' ||
      path == '/feeds' ||
      path.startsWith('/categories/') ||
      path.startsWith('/listings/')) {
    return DesktopPageKind.wide;
  }
  if (isAccountSectionPath(path, userId: userId)) {
    return DesktopPageKind.account;
  }
  return DesktopPageKind.narrow;
}

/// Khung chung cho mọi trang sau khi vào app (bọc navigator của router).
///
/// Điện thoại / máy tính bảng: trả nguyên [child], giao diện như cũ.
/// Desktop (≥ 1024px): header trên cùng, nội dung trang theo
/// [desktopPageKindOf], cửa sổ chat nổi + ReStore AI ở góc phải dưới.
class DesktopFrame extends StatefulWidget {
  const DesktopFrame({
    super.key,
    required this.location,
    required this.child,
    this.listingSearchQuery,
    this.selectedConversationId,
    this.assistant,
  });

  final String location;
  final String? listingSearchQuery;
  final String? selectedConversationId;
  final Widget child;
  final AiAssistantCubit Function()? assistant;

  @override
  State<DesktopFrame> createState() => _DesktopFrameState();
}

class _DesktopFrameState extends State<DesktopFrame> {
  late final _repository = AppEnvironment.useMockData
      ? MockChatRepository()
      : ApiChatRepository();
  late final _chat = DesktopChatController(
    assistantFactory: widget.assistant,
    chatRepository: _repository,
  );
  late final ShellBadgesCubit _badges;
  late final AppLifecycleListener _lifecycle;
  bool _desktop = false;
  bool _inboxUpdateScheduled = false;
  AppLifecycleState? _appState;

  @override
  void initState() {
    super.initState();
    // Gói thật và trạng thái cửa hàng của tài khoản cho menu nút giữa
    unawaited(PlanSession.refresh());
    unawaited(ShopSession.refresh());
    _badges = ShellBadgesCubit(chatRepository: _repository)..refresh();
    _appState = WidgetsBinding.instance.lifecycleState;
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        _appState = state;
        if (_appVisible) {
          _scheduleInboxUpdate();
        } else {
          _syncInbox();
        }
      },
    );
    _chat.addListener(_scheduleInboxUpdate);
  }

  bool get _appVisible => switch (_appState) {
    null || AppLifecycleState.resumed || AppLifecycleState.inactive => true,
    _ => false,
  };

  void _syncInbox() {
    final path = widget.location;
    final onMessagesPage = path == LiveMessagesView.path;
    final inMessages = onMessagesPage || path.startsWith('/messages/');
    final onLegacyConversation = inMessages && path.split('/').length == 3;
    final listVisible = onMessagesPage
        ? _desktop || widget.selectedConversationId == null
        : _desktop && (onLegacyConversation || (!inMessages && _chat.isOpen));
    _chat.updateInboxVisibility(
      context.currentUser?.id,
      visible: _appVisible && listVisible,
    );
  }

  // Navigation and the dock can both change in the same frame.
  void _scheduleInboxUpdate() {
    if (_inboxUpdateScheduled) return;
    _inboxUpdateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inboxUpdateScheduled = false;
      if (mounted) _syncInbox();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void didUpdateWidget(DesktopFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location &&
        widget.location.startsWith('/messages')) {
      // Đã sang trang Tin nhắn đầy đủ thì thu cửa sổ nổi lại
      _chat.close();
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _chat.removeListener(_scheduleInboxUpdate);
    _chat.dispose();
    _badges.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watchUser()?.id;
    return BlocProvider.value(
      value: _badges,
      child: DesktopChatScope(
        controller: _chat,
        child: LayoutBuilder(
          builder: (context, constraints) {
            _desktop = constraints.maxWidth >= AppDimesions.desktopWidth;
            _scheduleInboxUpdate();
            if (!_desktop) return widget.child;
            final location = widget.location;
            final kind = desktopPageKindOf(location, userId: userId);
            final body = switch (kind) {
              DesktopPageKind.wide => widget.child,
              DesktopPageKind.account => AccountDesktopShell(
                location: location,
                child: widget.child,
              ),
              DesktopPageKind.narrow => _NarrowPage(
                maxWidth:
                    location == '/messages' || location.startsWith('/messages/')
                    ? AppDimesions.desktopContentWidth
                    : AppDimesions.desktopNarrowWidth,
                child: widget.child,
              ),
            };
            return Material(
              color: AppColors.fill,
              child: Column(
                children: [
                  BlocBuilder<ShellBadgesCubit, int>(
                    builder: (context, unread) => DesktopHeader(
                      location: location,
                      listingSearchQuery: widget.listingSearchQuery,
                      unreadMessages: unread,
                      onMessagesTap: _chat.toggle,
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(child: body),
                        if (!location.startsWith('/messages'))
                          ListenableBuilder(
                            listenable: _chat,
                            builder: (context, _) =>
                                BlocBuilder<ShellBadgesCubit, int>(
                                  builder: (context, unread) => DesktopChatDock(
                                    controller: _chat,
                                    location: location,
                                    unread: unread,
                                  ),
                                ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Trang chưa có bố cục desktop riêng: khối trắng rộng tối đa 960px ở giữa,
/// hai bên để trống, trang tự cuộn bên trong.
class _NarrowPage extends StatelessWidget {
  const _NarrowPage({required this.child, required this.maxWidth});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.fill,
    child: Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          // Lề 24 hai bên như đầu trang để mép nội dung thẳng hàng
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}
