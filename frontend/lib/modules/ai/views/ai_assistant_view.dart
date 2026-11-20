import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/ui/responsive/responsive_content.dart';
import '../../../l10n/app_localizations.dart';
import '../bloc/ai_assistant_cubit.dart';
import '../models/assistant_reply.dart';

class AiAssistantView extends StatefulWidget {
  const AiAssistantView({super.key});
  @override
  State<AiAssistantView> createState() => _AiAssistantViewState();
}

class _AiAssistantViewState extends State<AiAssistantView> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _awayFromEnd = false;
  late int _historyLoads;

  @override
  void initState() {
    super.initState();
    _historyLoads = context.read<AiAssistantCubit>().historyLoads;
    WidgetsBinding.instance.addPostFrameCallback((_) => _showFirstTurn());
    _scroll.addListener(() {
      final away = _scroll.position.extentAfter > 120;
      if (away != _awayFromEnd) setState(() => _awayFromEnd = away);
    });
  }

  void _showFirstTurn() {
    if (!mounted || !_scroll.hasClients) return;
    _scroll.jumpTo(0);
    final away = _scroll.position.extentAfter > 120;
    if (away != _awayFromEnd) setState(() => _awayFromEnd = away);
  }

  void _scrollToEnd() {
    if (mounted && _scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final cubit = context.read<AiAssistantCubit>();
    if (_input.text.trim().isEmpty ||
        cubit.state.busy ||
        cubit.state.canRetry) {
      return;
    }
    cubit.submitted(_input.text);
    _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<AiAssistantCubit>();
    return BlocConsumer<AiAssistantCubit, AiAssistantState>(
      listener: (_, state) {
        if (_historyLoads != cubit.historyLoads) {
          _historyLoads = cubit.historyLoads;
          WidgetsBinding.instance.addPostFrameCallback((_) => _showFirstTurn());
        } else if (!_awayFromEnd) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
        }
      },
      builder: (context, state) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          foregroundColor: Colors.black87,
          elevation: 0,
          centerTitle: true,
          title: Column(
            children: [
              Text(
                l10n.restoreAi,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                l10n.aiByline,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: l10n.aiStartOver,
              icon: const Icon(Icons.edit_note_outlined),
              onPressed: state.busy
                  ? null
                  : () {
                      _input.clear();
                      cubit.startOver();
                      FocusScope.of(context).unfocus();
                    },
            ),
          ],
        ),
        body: SafeArea(
          child: ResponsiveContent(
            maxWidth: 720,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ListView(
                          controller: _scroll,
                          padding: const EdgeInsets.all(16),
                          children: [
                            if (cubit.startedAt != null) ...[
                              Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: Text(
                                  MaterialLocalizations.of(
                                    context,
                                  ).formatMediumDate(cubit.startedAt!),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              _Bubble(child: Text(l10n.aiWelcome)),
                              _Bubble(child: Text(l10n.aiOpeningQuestion)),
                            ],
                            for (final turn in state.turns) ...[
                              _Bubble(outgoing: true, child: Text(turn.input)),
                              if (turn.reply != null)
                                _Answer(
                                  reply: turn.reply!,
                                  state: state,
                                  latest: identical(turn, state.turns.last),
                                ),
                            ],
                            if (state.busy) ...[
                              if (state.partialText.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _Bubble(
                                    child: SelectableText(state.partialText),
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Text(switch (state.stage) {
                                        'searching_listings' =>
                                          l10n.aiSearchingListings,
                                        'reading_listings' =>
                                          l10n.aiReadingListings,
                                        'searching_knowledge' =>
                                          l10n.aiSearchingKnowledge,
                                        'reading_quota' => l10n.aiReadingQuota,
                                        'preparing_draft' =>
                                          l10n.aiPreparingDraft,
                                        _ =>
                                          state.partialText.isEmpty
                                              ? l10n.aiProcessing
                                              : l10n.aiAnswering,
                                      }),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (state.error != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                color: AppColors.errorBg,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      state.error!,
                                      style: const TextStyle(
                                        color: AppColors.error,
                                      ),
                                    ),
                                    if (state.canRetry)
                                      TextButton(
                                        onPressed: state.busy
                                            ? null
                                            : cubit.retry,
                                        child: Text(l10n.retry),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (_awayFromEnd)
                        Positioned(
                          bottom: 6,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Material(
                              color: Colors.white,
                              shape: const CircleBorder(),
                              elevation: 2,
                              child: IconButton(
                                tooltip: MaterialLocalizations.of(
                                  context,
                                ).lastPageTooltip,
                                icon: const Icon(
                                  Icons.arrow_downward,
                                  size: 20,
                                ),
                                onPressed: _scrollToEnd,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      for (final (icon, label, prompt) in [
                        (
                          Icons.phone_iphone,
                          l10n.aiPhoneShortcut,
                          l10n.aiSampleIphoneQuery,
                        ),
                        (
                          Icons.laptop_mac,
                          l10n.aiLaptopShortcut,
                          l10n.aiSampleStudentLaptopQuery,
                        ),
                        (
                          Icons.photo_camera_outlined,
                          l10n.aiCameraShortcut,
                          l10n.aiSampleCameraQuery,
                        ),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black87,
                              side: const BorderSide(color: Color(0xFFE8E8E8)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: state.busy || state.canRetry
                                ? null
                                : () {
                                    _input.value = TextEditingValue(
                                      text: prompt,
                                      selection: TextSelection.collapsed(
                                        offset: prompt.length,
                                      ),
                                    );
                                  },
                            icon: Icon(icon, size: 17),
                            label: Text(label),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: const Color(0xFFF0F0F0)),
                    boxShadow: const [
                      BoxShadow(color: Color(0x0D000000), blurRadius: 14),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: l10n.aiRecentChats,
                        icon: const Icon(Icons.history, color: Colors.black87),
                        onPressed: state.busy
                            ? null
                            : () async {
                                final id = await showModalBottomSheet<String>(
                                  context: context,
                                  builder: (_) => _RecentChats(cubit: cubit),
                                );
                                if (id == null || !mounted) return;
                                await cubit.openConversation(id);
                                if (mounted && cubit.state.error == null) {
                                  _input.clear();
                                }
                              },
                      ),
                      Expanded(
                        child: TextField(
                          controller: _input,
                          enabled: !state.busy && !state.canRetry,
                          maxLength: 2000,
                          minLines: 1,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: l10n.aiComposerHint,
                            counterText: '',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.listingSend,
                        icon: const Icon(Icons.send_outlined),
                        onPressed: state.busy || state.canRetry ? null : _send,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.child, this.outgoing = false});
  final Widget child;
  final bool outgoing;

  @override
  Widget build(BuildContext context) => Align(
    alignment: outgoing ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      margin: EdgeInsets.only(bottom: 16, left: outgoing ? 32 : 0),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: outgoing ? const Color(0xFF007AFF) : const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(18),
      ),
      child: DefaultTextStyle(
        style: TextStyle(
          fontSize: 16,
          height: 1.42,
          color: outgoing ? Colors.white : const Color(0xFF202020),
        ),
        child: child,
      ),
    ),
  );
}

class _Answer extends StatelessWidget {
  const _Answer({
    required this.reply,
    required this.state,
    required this.latest,
  });
  final AssistantReply reply;
  final AiAssistantState state;
  final bool latest;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Bubble(child: SelectableText(reply.text)),
          if (latest && reply.suggestions.isNotEmpty)
            Wrap(
              spacing: 8,
              children: [
                for (final suggestion in reply.suggestions)
                  ActionChip(
                    label: Text(suggestion),
                    onPressed: state.busy || state.canRetry
                        ? null
                        : () => context.read<AiAssistantCubit>().submitted(
                            suggestion,
                          ),
                  ),
              ],
            ),
          for (final listing in reply.listings)
            Card(
              child: ListTile(
                title: Text(listing['title'] as String),
                subtitle: Text(
                  '${listing['price']} đ · ${listing['areaLabel']}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(
                  '/listings/${Uri.encodeComponent(listing['id'] as String)}',
                ),
              ),
            ),
          for (final source in reply.sources)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                'Nguồn: ${source['title']}',
                style: const TextStyle(fontSize: 13),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SelectableText(source['text'] as String),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _RecentChats extends StatefulWidget {
  const _RecentChats({required this.cubit});
  final AiAssistantCubit cubit;

  @override
  State<_RecentChats> createState() => _RecentChatsState();
}

class _RecentChatsState extends State<_RecentChats> {
  final _chats = <({String id, String title})>[];
  String? _after;
  bool _loading = false;
  bool _failed = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted || _loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final page = await widget.cubit.listRecent(after: _after);
      if (!mounted) return;
      final ids = _chats.map((chat) => chat.id).toSet();
      setState(() {
        _hasMore = page.isNotEmpty && page.last.id != _after;
        if (page.isNotEmpty) _after = page.last.id;
        _chats.addAll(page.where((chat) => ids.add(chat.id)));
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: _chats.isEmpty && !_hasMore
          ? Center(child: Text(l10n.aiNoRecentChats))
          : ListView.builder(
              itemCount: _chats.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _chats.length) {
                  if (_failed) {
                    return Center(
                      child: TextButton(
                        onPressed: _load,
                        child: Text(l10n.retry),
                      ),
                    );
                  }
                  if (!_loading) {
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => _load(),
                    );
                  }
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final chat = _chats[index];
                return ListTile(
                  title: Text(
                    chat.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => Navigator.pop(context, chat.id),
                );
              },
            ),
    );
  }
}
