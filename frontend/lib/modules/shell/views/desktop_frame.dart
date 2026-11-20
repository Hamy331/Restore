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
      path == '/messages' ||
      path.startsWith('/messages/') ||
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
    this.assistant,
  });

  final String location;
  final Widget child;
  final AiAssistantCubit Function()? assistant;

  @override
  State<DesktopFrame> createState() => _DesktopFrameState();
}

class _DesktopFrameState extends State<DesktopFrame> {
  late final _chat = DesktopChatController(assistantFactory: widget.assistant);
  late final ShellBadgesCubit _badges;

  @override
  void initState() {
    super.initState();
    // Gói thật của tài khoản cho menu nút giữa và lời chào trang chủ
    unawaited(PlanSession.refresh());
    _badges = ShellBadgesCubit(
      chatRepository: AppEnvironment.useMockData
          ? MockChatRepository()
          : ApiChatRepository(),
    )..refresh();
    _chat.addListener(_onChatChanged);
  }

  /// Mở / đổi cuộc trò chuyện thì cập nhật số tin chưa đọc trên header
  void _onChatChanged() => _badges.refresh();

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
    _chat.removeListener(_onChatChanged);
    _chat.dispose();
    _badges.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _badges,
      child: DesktopChatScope(
        controller: _chat,
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < AppDimesions.desktopWidth) {
              return widget.child;
            }
            final location = widget.location;
            final kind = desktopPageKindOf(
              location,
              userId: context.watchUser()?.id,
            );
            final body = switch (kind) {
              DesktopPageKind.wide => widget.child,
              DesktopPageKind.account => AccountDesktopShell(
                location: location,
                child: widget.child,
              ),
              DesktopPageKind.narrow => _NarrowPage(child: widget.child),
            };
            return Material(
              color: AppColors.background,
              child: Column(
                children: [
                  BlocBuilder<ShellBadgesCubit, int>(
                    builder: (context, unread) => DesktopHeader(
                      location: location,
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
  const _NarrowPage({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.background,
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppDimesions.desktopNarrowWidth,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
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
