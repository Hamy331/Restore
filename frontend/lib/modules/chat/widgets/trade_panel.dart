import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/network/api_client.dart';
import 'package:restore/core/utils/formatters/currency_formatter.dart';
import 'package:restore/l10n/app_localizations.dart';
import '../models/chat_models.dart';
import 'review_stars.dart';

/// Câu lỗi server trả về (đã là tiếng Việt), không có thì câu chung
String tradeErrorText(Object error, AppLocalizations l) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['error'] is String) return data['error'] as String;
  }
  return l.tradeError;
}

/// Thanh dưới thẻ sản phẩm trong chat theo tin:
/// - Đề nghị đang chờ: người bán Chấp nhận / Từ chối, người mua Thu hồi.
/// - Đề nghị vừa bị từ chối / thu hồi / hết hạn: dòng trạng thái.
/// - Đã thống nhất: giá đã chốt và trạng thái đánh giá hai chiều (giữ kín
///   tới khi cả hai gửi hoặc đủ 7 ngày), nút Đánh giá / Sửa đánh giá.
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

  String get _contextId => widget.trade.contextId ?? widget.conversation.id;

  String _money(num value) => CurrencyFormatter.formatVnd(
    value,
    locale: AppLocalizations.of(context)!.localeName,
  );

  String _date(DateTime value) {
    final m = MaterialLocalizations.of(context);
    return '${m.formatShortDate(value)} ${m.formatTimeOfDay(TimeOfDay.fromDateTime(value))}';
  }

  Future<void> _respond(ChatOffer offer, String action) async {
    if (busy) return;
    final l = AppLocalizations.of(context)!;
    final price = _money(offer.amount);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(switch (action) {
          'accept' => l.offerAcceptTitle(price),
          'reject' => l.offerRejectTitle(price),
          _ => l.offerWithdrawTitle(price),
        }),
        content: action == 'accept' ? Text(l.offerAcceptBody) : null,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(switch (action) {
              'accept' => l.offerAccept,
              'reject' => l.offerReject,
              _ => l.offerWithdraw,
            }),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true || busy) return;
    setState(() => busy = true);
    try {
      await ApiClient().dio.post(
        '/conversations/${Uri.encodeComponent(_contextId)}/offers/${Uri.encodeComponent(offer.id)}',
        data: {'action': action},
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(tradeErrorText(error, l))));
      }
    } finally {
      if (mounted) await widget.refresh();
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _review() async {
    final agreement = widget.trade.agreement;
    final sent = await TradeReviewForm.show(
      context,
      conversationId: _contextId,
      title: widget.trade.title,
      recipientName: widget.conversation.otherUser.fullName,
      isSeller: widget.trade.seller,
      initial: agreement?.mine,
    );
    if (sent == true && mounted) await widget.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!, t = widget.trade;
    final name = widget.conversation.otherUser.fullName;
    final agreement = t.agreement, offer = t.offer;
    Widget? body;

    if (agreement != null) {
      final reviewed = t.reviewed;
      final deadline = agreement.deadline;
      final date = deadline == null ? '' : _date(deadline);
      final String status;
      Widget? action;
      if (agreement.closed) {
        status = reviewed || agreement.published
            ? l.reviewPublished
            : l.reviewClosed;
      } else if (reviewed) {
        status = l.reviewWaiting(name, date);
        action = TextButton(onPressed: _review, child: Text(l.reviewEdit));
      } else {
        status = agreement.otherReviewed
            ? l.reviewOtherDone(name, date)
            : l.reviewOpenUntil(date);
        action = FilledButton(
          onPressed: _review,
          child: Text(t.seller ? l.tradeBuyerReview : l.tradeSellerReview),
        );
      }
      body = _Row(
        icon: AppIcons.checkCircle,
        color: AppColors.success,
        title: l.offerAgreed(_money(agreement.price)),
        subtitle: status,
        actions: [?action],
      );
    } else if (offer != null && offer.pending) {
      final price = _money(offer.amount);
      final expires = offer.expiresAt == null
          ? null
          : l.offerExpiresAt(_date(offer.expiresAt!));
      body = _Row(
        icon: AppIcons.offer,
        color: AppColors.actionPrimary,
        title: t.seller
            ? l.offerPendingSeller(name, price)
            : l.offerPendingBuyer(price),
        subtitle: expires,
        actions: t.seller
            ? [
                TextButton(
                  onPressed: busy ? null : () => _respond(offer, 'reject'),
                  child: Text(l.offerReject),
                ),
                FilledButton(
                  onPressed: busy ? null : () => _respond(offer, 'accept'),
                  child: Text(l.offerAccept),
                ),
              ]
            : [
                TextButton(
                  onPressed: busy ? null : () => _respond(offer, 'cancel'),
                  child: Text(l.offerWithdraw),
                ),
              ],
      );
    } else if (offer != null) {
      final price = _money(offer.amount);
      final text = switch (offer.status) {
        'REJECTED' => l.offerStatusRejected(price),
        'CANCELLED' => l.offerStatusCancelled(price),
        'EXPIRED' => l.offerStatusExpired(price),
        _ => null,
      };
      if (text != null) {
        body = _Row(
          icon: AppIcons.info,
          color: AppColors.textSecondary,
          title: text,
        );
      }
    }

    if (body == null && t.product != null) return const SizedBox.shrink();
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
          ?body,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 20, color: color),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (subtitle case final text?)
              Text(
                text,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
      for (final action in actions) ...[const SizedBox(width: 6), action],
    ],
  );
}

class TradeReviewForm extends StatefulWidget {
  const TradeReviewForm({
    super.key,
    required this.conversationId,
    required this.title,
    required this.recipientName,
    required this.isSeller,
    this.initial,
  });

  final String conversationId;
  final String title;
  final String? recipientName;
  final bool isSeller;

  /// Đánh giá đã gửi nhưng chưa công khai: mở để sửa
  final ReviewDraft? initial;

  static Future<bool?> show(
    BuildContext context, {
    required String conversationId,
    required String title,
    required String? recipientName,
    required bool isSeller,
    ReviewDraft? initial,
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
      initial: initial,
    ),
  );
  @override
  State<TradeReviewForm> createState() => _TradeReviewFormState();
}

class _TradeReviewFormState extends State<TradeReviewForm> {
  late int stars = widget.initial?.stars ?? 0;
  late final tags = <String>{...?widget.initial?.tags};
  late final note = TextEditingController(text: widget.initial?.comment);
  bool busy = false;
  String? error;
  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || stars == 0) return;
    final l = AppLocalizations.of(context)!;
    setState(() {
      busy = true;
      error = null;
    });
    final allowed = widget.isSeller ? buyerReviewTags : sellerReviewTags;
    try {
      await ApiClient().dio.post(
        '/conversations/${Uri.encodeComponent(widget.conversationId)}/review',
        data: {
          'stars': stars,
          // Bỏ tiêu chí cũ không còn dùng khi sửa đánh giá trước đây
          'tags': tags.where(allowed.contains).toList(),
          'comment': note.text.trim(),
        },
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          error = tradeErrorText(e, l);
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
              widget.initial != null
                  ? l.reviewEdit
                  : seller
                  ? l.tradeBuyerReview
                  : l.tradeSellerReview,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (widget.recipientName case final name?) Text(name),
            Text(widget.title),
            const SizedBox(height: 8),
            ReviewStars(
              stars.toDouble(),
              size: 32,
              onChanged: busy ? null : (v) => setState(() => stars = v),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final k in seller ? buyerReviewTags : sellerReviewTags)
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
            const SizedBox(height: 8),
            TextField(
              controller: note,
              enabled: !busy,
              maxLength: 500,
              maxLines: 3,
              decoration: InputDecoration(labelText: l.tradeNote),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.infoBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(AppIcons.lock, size: 16, color: AppColors.info),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.reviewHiddenNote,
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
            if (error case final text?)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  text,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: busy || stars == 0 ? null : submit,
              child: Text(
                widget.initial != null ? l.reviewEdit : l.tradeSubmit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
