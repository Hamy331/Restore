import 'package:flutter/material.dart';
import 'package:restore/shared/widgets/desktop/desktop_layout.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/network/api_client.dart';
import 'package:restore/core/utils/formatters/currency_formatter.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/auth/bloc/auth/auth_context.dart';
import 'package:restore/modules/chat/widgets/review_stars.dart';
import 'package:restore/modules/chat/widgets/trade_panel.dart';
import 'package:restore/shared/widgets/app_local_image.dart';
import 'package:restore/shared/widgets/app_page_header.dart';
import 'package:restore/shared/widgets/loading/app_loading_indicator.dart';

import '../../models/profile_models.dart';
import '../public_profile/profile_reviews.dart';

class MyReviewsView extends StatelessWidget {
  const MyReviewsView({super.key, this.received = false});

  static const path = '/account/my-reviews';
  static const ratingsPath = '/account/ratings';

  final bool received;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final user = context.watchUser();
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: isDesktopLayout(context)
                  ? EdgeInsets.zero
                  : const EdgeInsets.symmetric(vertical: 8),
              child: AppPageTitleRow(
                title: received ? l.accReceivedRatings : l.accMyReviews,
                onBack: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/account');
                  }
                },
              ),
            ),
            // Desktop: tiêu đề đã có đường kẻ riêng
            if (!isDesktopLayout(context)) const Divider(height: 1),
            Expanded(
              child: received
                  ? ProfileReviews(
                      key: ValueKey(user.id),
                      showTitle: false,
                      profile: ProfileData(
                        id: user.id,
                        fullName: user.fullName,
                        username: user.username,
                        avatarUrl: user.avatarUrl,
                        followerCount: 0,
                        followingCount: 0,
                        ratingAverage: user.ratingAverage,
                        ratingCount: user.ratingCount,
                      ),
                    )
                  : _OutgoingReviews(key: ValueKey(user.id)),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ReviewStatus { pending, submitted }

class _OutgoingReviews extends StatefulWidget {
  const _OutgoingReviews({super.key});

  @override
  State<_OutgoingReviews> createState() => _OutgoingReviewsState();
}

class _OutgoingReviewsState extends State<_OutgoingReviews> {
  final _items = <_ReviewItem>[];
  _ReviewStatus _status = _ReviewStatus.pending;
  int _page = 0;
  int _request = 0;
  bool _loading = false;
  bool _failed = false;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading && !reset) return;
    final request = ++_request;
    final page = reset ? 1 : _page + 1;
    setState(() {
      _loading = true;
      _failed = false;
      if (reset) {
        _page = 0;
        _items.clear();
        _hasMore = false;
      }
    });
    try {
      final response = await ApiClient().dio.get<Map<String, dynamic>>(
        '/users/me/reviews',
        queryParameters: {'status': _status.name, 'page': page},
      );
      final data = response.data!['data'] as Map<String, dynamic>;
      final items = (data['items'] as List)
          .cast<Map<String, dynamic>>()
          .map(_ReviewItem.fromJson)
          .toList();
      if (!mounted || request != _request) return;
      setState(() {
        _items.addAll(items);
        _page = page;
        _hasMore = data['hasMore'] == true;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || request != _request) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  Future<void> _review(_ReviewItem item) async {
    final sent = await TradeReviewForm.show(
      context,
      conversationId: item.conversationId,
      title: item.title,
      recipientName: item.recipientName,
      isSeller: item.isSeller,
    );
    if (sent == true && mounted) await _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SegmentedButton<_ReviewStatus>(
            segments: [
              ButtonSegment(
                value: _ReviewStatus.pending,
                label: Text(l.accPendingReviews),
              ),
              ButtonSegment(
                value: _ReviewStatus.submitted,
                label: Text(l.accSubmittedReviews),
              ),
            ],
            selected: {_status},
            showSelectedIcon: false,
            onSelectionChanged: (selected) {
              if (selected.single == _status) return;
              _status = selected.single;
              _load(reset: true);
            },
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _load(reset: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                for (final item in _items)
                  _ReviewCard(item: item, onReview: () => _review(item)),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: AppLoadingIndicator()),
                  )
                else if (_failed || _hasMore)
                  Center(
                    child: TextButton(
                      onPressed: _load,
                      child: Text(_failed ? l.retry : l.tradeMore),
                    ),
                  )
                else if (_items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _status == _ReviewStatus.pending
                          ? l.accNoPendingReviews
                          : l.accNoSubmittedReviews,
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewItem {
  const _ReviewItem({
    required this.conversationId,
    required this.title,
    required this.price,
    required this.image,
    required this.recipientName,
    required this.isSeller,
    required this.date,
    required this.review,
  });

  factory _ReviewItem.fromJson(Map<String, dynamic> json) {
    final review = json['review'] as Map<String, dynamic>?;
    return _ReviewItem(
      conversationId: json['conversationId'] as String,
      title: json['title'] as String,
      price: num.tryParse(json['price'].toString()),
      image: json['image'] as String?,
      recipientName: json['recipientName'] as String?,
      isSeller: json['isSeller'] == true,
      date: DateTime.tryParse(
        (review?['createdAt'] ?? json['confirmedAt']).toString(),
      ),
      review: review == null
          ? null
          : (
              stars: (review['stars'] as num).toDouble(),
              comment: review['comment'] as String,
              tags: (review['tags'] as List).cast<String>(),
            ),
    );
  }

  final String conversationId, title;
  final num? price;
  final String? image, recipientName;
  final bool isSeller;
  final DateTime? date;
  final ({double stars, String comment, List<String> tags})? review;
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.item, required this.onReview});

  final _ReviewItem item;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final labels = reviewTags(l);
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (item.image case final image?) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AppLocalImage(path: image, width: 56, height: 56),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: theme.textTheme.titleSmall),
                      if (item.recipientName case final name?) Text(name),
                      if (item.price case final price?)
                        Text(
                          CurrencyFormatter.formatVnd(
                            price,
                            locale: l.localeName,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (item.date case final date?) ...[
              const SizedBox(height: 8),
              Text(
                MaterialLocalizations.of(
                  context,
                ).formatCompactDate(date.toLocal()),
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (item.review case final review?) ...[
              const SizedBox(height: 8),
              ReviewStars(review.stars),
              if (review.comment.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(review.comment),
                ),
              if (review.tags.isNotEmpty)
                Wrap(
                  spacing: 6,
                  children: [
                    for (final tag in review.tags)
                      if (labels[tag] case final label?)
                        Chip(label: Text(label)),
                  ],
                ),
            ] else
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: onReview,
                  child: Text(
                    item.isSeller ? l.tradeBuyerReview : l.tradeSellerReview,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
