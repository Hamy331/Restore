import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_dimesions.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/constants/app_images.dart' show AppImages;
import 'package:restore/core/theme/app_header_palette.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/ai/bloc/ai_assistant_cubit.dart';
import 'package:restore/modules/ai/views/ai_assistant_view.dart';
import 'package:restore/modules/shell/widgets/desktop_chat_controller.dart';

import '../../repositories/chat_repository.dart';
import '../../widgets/desktop_conversation_list.dart';
import '../conversation/live_chat_conversation_view.dart';

/// Trang Tin nhắn đầy đủ trên web desktop: danh sách bên trái (ReStore AI
/// ghim đầu), cuộc trò chuyện đang chọn bên phải, trong khung 1200px.
class MessagesDesktopView extends StatefulWidget {
  const MessagesDesktopView({super.key, this.selectedId, this.repository});

  final String? selectedId;
  final ChatRepository? repository;

  @override
  State<MessagesDesktopView> createState() => _MessagesDesktopViewState();
}

class _MessagesDesktopViewState extends State<MessagesDesktopView> {
  late String? _selectedId = widget.selectedId;
  bool _assistant = false;
  AiAssistantCubit? _ownAssistant;

  @override
  void didUpdateWidget(MessagesDesktopView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedId != oldWidget.selectedId) {
      setState(() {
        _selectedId = widget.selectedId;
        _assistant = false;
      });
    }
  }

  @override
  void dispose() {
    _ownAssistant?.close();
    super.dispose();
  }

  AiAssistantCubit _assistantCubit() =>
      DesktopChatScope.maybeOf(context)?.assistantCubit() ??
      (_ownAssistant ??= AiAssistantCubit());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selected = _selectedId;
    return ColoredBox(
      color: AppColors.background,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppDimesions.desktopContentWidth,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 340,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                            child: Text(
                              l10n.messagesTitle,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Expanded(
                            child: DesktopConversationList(
                              selectedId: _assistant ? null : selected,
                              assistantSelected: _assistant,
                              onSelect: (chat) => setState(() {
                                _selectedId = chat.id;
                                _assistant = false;
                              }),
                              onAssistant: () =>
                                  setState(() => _assistant = true),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const VerticalDivider(width: 1, color: AppColors.border),
                    Expanded(
                      child: _assistant
                          ? BlocProvider.value(
                              value: _assistantCubit(),
                              child: const AiAssistantView(),
                            )
                          : selected == null
                          ? const _Empty()
                          : LiveChatConversationView(
                              key: ValueKey(selected),
                              conversationId: selected,
                              repository: widget.repository,
                              onBack: () =>
                                  setState(() => _selectedId = null),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final vi = Localizations.localeOf(context).languageCode == 'vi';
    return ColoredBox(
      color: AppColors.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: const BoxDecoration(
                color: Color(0xFFEEF2FC),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                AppIcons.chat,
                size: 50,
                color: AppHeaderPalette.desktopBar,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              vi ? 'Chọn một cuộc trò chuyện' : 'Pick a conversation',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              vi
                  ? 'Tin nhắn với người mua, người bán và ReStore AI nằm ở đây.'
                  : 'Chats with buyers, sellers and ReStore AI live here.',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            Image.asset(AppImages.uiIcons.ai, width: 40, height: 40),
          ],
        ),
      ),
    );
  }
}
