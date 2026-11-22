import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/filter/app_filter_bar.dart';

import '../bloc/conversations/conversations_cubit.dart';
import '../bloc/conversations/conversations_state.dart';
import '../models/chat_models.dart';

/// Tab lọc danh sách trò chuyện: Tất cả / Chưa đọc / Đang thương lượng
enum ConversationTab {
  all,
  unread,
  negotiating;

  bool matches(ChatConversation chat) => switch (this) {
    all => true,
    unread => chat.unreadCount > 0,
    negotiating => chat.negotiating,
  };
}

/// Hàng tab cuộn ngang; số đếm lấy từ [ConversationsCubit] nên tự cập nhật
/// khi có tin mới hoặc vừa trả giá.
class ConversationTabs extends StatelessWidget {
  const ConversationTabs({
    super.key,
    required this.selected,
    required this.onChanged,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 10),
  });

  final ConversationTab selected;
  final ValueChanged<ConversationTab> onChanged;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocBuilder<ConversationsCubit, ConversationsState>(
      buildWhen: (a, b) => a.conversations != b.conversations,
      builder: (context, state) {
        String label(ConversationTab tab) {
          final name = switch (tab) {
            ConversationTab.all => l.chatTabAll,
            ConversationTab.unread => l.chatTabUnread,
            ConversationTab.negotiating => l.chatNegotiating,
          };
          if (tab == ConversationTab.all) return name;
          final count = state.conversations.where(tab.matches).length;
          return count == 0 ? name : '$name ($count)';
        }

        // Column cha có thể căn giữa: ép hàng tab sát trái
        return Align(
          alignment: AlignmentDirectional.centerStart,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: padding,
            child: Row(
              children: [
                for (final tab in ConversationTab.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AppFilterChip(
                      label: label(tab),
                      selected: tab == selected,
                      onTap: () => onChanged(tab),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Nhãn nhỏ "Đang thương lượng" trên dòng trò chuyện
class NegotiatingTag extends StatelessWidget {
  const NegotiatingTag({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF3D6),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      AppLocalizations.of(context)!.chatNegotiating,
      style: const TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
        color: Color(0xFFB25E00),
      ),
    ),
  );
}
