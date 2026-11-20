import 'package:flutter/material.dart';
import 'package:restore/core/network/api_client.dart';
import 'package:restore/l10n/app_localizations.dart';
import '../models/chat_models.dart';
import 'review_stars.dart';

class TradePanel extends StatefulWidget {
  const TradePanel({
    super.key,
    required this.trade,
    required this.conversation,
    required this.refresh,
  });
  final ChatTrade trade;
  final ChatConversation conversation;
  final Future<void> Function() refresh;
  @override
  State<TradePanel> createState() => _TradePanelState();
}

class _TradePanelState extends State<TradePanel> {
  bool busy = false;
  Future<void> act(String action, String label) async {
    if (busy) return;
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label),
        content: Text(
          '${widget.conversation.otherUser.fullName}\n${widget.trade.title}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.tradeConfirm),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true || busy) return;
    setState(() => busy = true);
    try {
      await ApiClient().dio.post(
        '/conversations/${widget.trade.contextId ?? widget.conversation.id}/trade',
        data: {'action': action},
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.tradeError)));
      }
    } finally {
      if (mounted) await widget.refresh();
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> review() async {
    final sent = await TradeReviewForm.show(
      context,
      conversationId: widget.trade.contextId ?? widget.conversation.id,
      title: widget.trade.title,
      recipientName: widget.conversation.otherUser.fullName,
      isSeller: widget.trade.seller,
    );
    if (sent == true && mounted) await widget.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!, t = widget.trade;
    Widget? action;
    if (t.stage == 'open' && t.seller) {
      action = TextButton(
        onPressed: busy ? null : () => act('sell', l.tradeSellToBuyer),
        child: Text(l.tradeSellToBuyer),
      );
    }
    if (t.stage == 'pending') {
      action = Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (t.seller)
            Text(l.tradeWait)
          else
            FilledButton(
              onPressed: busy ? null : () => act('receive', l.tradeReceive),
              child: Text(l.tradeReceive),
            ),
          TextButton(
            onPressed: busy ? null : () => act('cancel', l.tradeCancel),
            child: Text(l.tradeCancel),
          ),
        ],
      );
    }
    if (t.stage == 'complete') {
      action = t.reviewed
          ? Text(l.tradeReviewed)
          : FilledButton(
              onPressed: review,
              child: Text(t.seller ? l.tradeBuyerReview : l.tradeSellerReview),
            );
    }
    if (action == null && t.product != null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (t.product == null)
            Text(
              t.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          if (action != null) action,
        ],
      ),
    );
  }
}

class TradeReviewForm extends StatefulWidget {
  const TradeReviewForm({
    super.key,
    required this.conversationId,
    required this.title,
    required this.recipientName,
    required this.isSeller,
  });

  final String conversationId;
  final String title;
  final String? recipientName;
  final bool isSeller;

  static Future<bool?> show(
    BuildContext context, {
    required String conversationId,
    required String title,
    required String? recipientName,
    required bool isSeller,
  }) => showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => TradeReviewForm(
      conversationId: conversationId,
      title: title,
      recipientName: recipientName,
      isSeller: isSeller,
    ),
  );
  @override
  State<TradeReviewForm> createState() => _TradeReviewFormState();
}

class _TradeReviewFormState extends State<TradeReviewForm> {
  int stars = 0;
  final tags = <String>{};
  final note = TextEditingController();
  bool busy = false, failed = false;
  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || stars == 0) return;
    setState(() {
      busy = true;
      failed = false;
    });
    try {
      await ApiClient().dio.post(
        '/conversations/${Uri.encodeComponent(widget.conversationId)}/review',
        data: {
          'stars': stars,
          'tags': tags.toList(),
          'comment': note.text.trim(),
        },
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          failed = true;
          busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!, seller = widget.isSeller;
    final labels = reviewTags(l);
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              seller ? l.tradeBuyerReview : l.tradeSellerReview,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (widget.recipientName case final name?) Text(name),
            Text(widget.title),
            ReviewStars(
              stars.toDouble(),
              size: 32,
              onChanged: (v) => setState(() => stars = v),
            ),
            Wrap(
              spacing: 6,
              children: [
                for (final k in [
                  'friendly',
                  'punctual',
                  'reliable',
                  if (seller) 'fairPrice' else ...['accurate', 'quality'],
                ])
                  FilterChip(
                    label: Text(labels[k]!),
                    selected: tags.contains(k),
                    onSelected: busy
                        ? null
                        : (v) => setState(() {
                            if (v) {
                              tags.add(k);
                            } else {
                              tags.remove(k);
                            }
                          }),
                  ),
              ],
            ),
            TextField(
              controller: note,
              enabled: !busy,
              maxLength: 500,
              maxLines: 2,
              decoration: InputDecoration(labelText: l.tradeNote),
            ),
            if (failed) Text(l.tradeError),
            FilledButton(
              onPressed: busy || stars == 0 ? null : submit,
              child: Text(l.tradeSubmit),
            ),
          ],
        ),
      ),
    );
  }
}
