import 'package:flutter/material.dart';
import 'package:restore/shared/widgets/loading/app_pull_to_refresh.dart';
import 'package:restore/shared/widgets/loading/app_loading_indicator.dart';
import 'package:restore/shared/utils/app_image_provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_page_header.dart';
import 'package:restore/shared/widgets/app_list_search_bar.dart';
import '../../bloc/conversations/conversations_cubit.dart';
import '../../bloc/conversations/conversations_state.dart';
import '../../models/chat_models.dart';
import '../../widgets/conversation_tabs.dart';

class LiveMessagesMobileView extends StatefulWidget {
  const LiveMessagesMobileView({
    super.key,
    required this.onSelect,
    this.selectedId,
    this.bottomPadding = 120,
  });

  final ValueChanged<String> onSelect;
  final String? selectedId;
  final double bottomPadding;

  @override
  State<LiveMessagesMobileView> createState() => _LiveMessagesMobileViewState();
}

class _LiveMessagesMobileViewState extends State<LiveMessagesMobileView> {
  late final _search = TextEditingController(
    text: context.read<ConversationsCubit>().state.searchQuery,
  );
  var _tab = ConversationTab.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ConversationsCubit>();
    final l = AppLocalizations.of(context)!;
    return ColoredBox(
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppTabHeader(title: l.messagesTitle),
            AppListSearchBar(
              controller: _search,
              hintText: l.messagesSearchHint,
              onChanged: cubit.search,
              onSearch: () => cubit.search(_search.text),
            ),
            ConversationTabs(
              selected: _tab,
              onChanged: (tab) => setState(() => _tab = tab),
            ),
            Expanded(
              child: BlocBuilder<ConversationsCubit, ConversationsState>(
                builder: (context, state) {
                  if (state.loading) {
                    return const Center(child: AppLoadingIndicator());
                  }
                  if (state.failed && state.conversations.isEmpty) {
                    return Center(
                      child: TextButton(
                        onPressed: cubit.load,
                        child: Text(l.messagesLoadError),
                      ),
                    );
                  }
                  if (state.conversations.isEmpty) {
                    return Center(child: Text(l.messagesEmpty));
                  }
                  final conversations = state.visibleConversations
                      .where(_tab.matches)
                      .toList();
                  if (conversations.isEmpty) {
                    return Center(child: Text(l.messagesSearchEmpty));
                  }
                  return AppPullToRefresh(
                    onRefresh: cubit.load,
                    child: ListView.separated(
                      padding: EdgeInsets.only(bottom: widget.bottomPadding),
                      itemCount: conversations.length,
                      separatorBuilder: (_, _) => const Divider(
                        height: 1,
                        indent: 80,
                        endIndent: 16,
                        color: Color(0xFFF0F2F5),
                      ),
                      itemBuilder: (context, index) => _ConversationTile(
                        conversation: conversations[index],
                        selected: conversations[index].id == widget.selectedId,
                        onTap: () => widget.onSelect(conversations[index].id),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.selected,
    required this.onTap,
  });
  final ChatConversation conversation;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final person = conversation.otherUser;
    final initial = person.fullName.isNotEmpty
        ? person.fullName[0].toUpperCase()
        : '?';
    return Material(
      color: AppColors.surface,
      child: ListTile(
        selected: selected,
        selectedTileColor: AppColors.actionSoft,
        hoverColor: AppColors.actionSoft,
        selectedColor: AppColors.textPrimary,
        onTap: onTap,
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: person.avatarUrl != null
                  ? appImageProvider(person.avatarUrl!)
                  : null,
              child: person.avatarUrl == null ? Text(initial) : null,
            ),
            if (person.isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22A06B),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          person.fullName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              conversation.lastMessage?.text ?? activityLabel(person),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            if (conversation.negotiating) ...[
              const SizedBox(height: 4),
              const NegotiatingTag(),
            ],
          ],
        ),
        trailing: conversation.unreadCount > 0
            ? CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.actionPrimary,
                child: Text(
                  '${conversation.unreadCount}',
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
              )
            : const Icon(AppIcons.chevronRight, size: 18),
      ),
    );
  }
}
