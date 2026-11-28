import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/network/api_client.dart';
import 'package:restore/core/network/media_url.dart';
import 'package:restore/core/utils/formatters/currency_formatter.dart';
import 'package:restore/core/utils/formatters/time_ago_formatter.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/auth/bloc/auth/auth_context.dart';
import 'package:restore/modules/chat/widgets/review_stars.dart';
import 'package:restore/modules/chat/widgets/trade_panel.dart'
    show tradeErrorText;
import 'package:restore/modules/content/repositories/report_repository.dart';
import 'package:restore/shared/widgets/app_local_image.dart';
import 'package:restore/shared/widgets/app_dropdown_menu.dart';
import 'package:restore/shared/widgets/app_option_sheet.dart';
import '../../models/profile_models.dart';
import '../../widgets/profile_header.dart';

/// Cách sắp xếp đánh giá (tham số `sort` của GET /users/:id/reviews)
enum ReviewSort {
  newest,
  oldest,
  highest,
  lowest;

  String label(AppLocalizations l) => switch (this) {
    newest => l.revSortNewest,
    oldest => l.revSortOldest,
    highest => l.revSortHighest,
    lowest => l.revSortLowest,
  };
}

/// Icon + màu của từng lời khen (tag) trong khối tổng quan
const _tagStyles = <String, (IconData, Color)>{
  'friendly': (Icons.emoji_emotions_outlined, Color(0xffe8590c)),
  'punctual': (Icons.schedule, Color(0xff2b63c6)),
  'reliable': (Icons.verified_user_outlined, Color(0xff0e7c70)),
  'accurate': (Icons.fact_check_outlined, Color(0xff7048e8)),
  'quality': (Icons.workspace_premium_outlined, Color(0xffd6336c)),
  'fairPrice': (Icons.sell_outlined, Color(0xff2f9e44)),
  'communication': (Icons.forum_outlined, Color(0xff1971c2)),
  'asDescribed': (Icons.fact_check_outlined, Color(0xff7048e8)),
  'keptDeal': (Icons.handshake_outlined, Color(0xff0e7c70)),
  'paidAsAgreed': (Icons.payments_outlined, Color(0xff2f9e44)),
  'polite': (Icons.sentiment_satisfied_alt_outlined, Color(0xffe8590c)),
};

/// Tab Đánh giá: chip Tất cả / Từ người mua / Từ người bán, khối tổng quan
/// (điểm lớn, sao, số đánh giá, dải lời khen cuộn ngang), tiêu đề "Đánh giá"
/// kèm nút sắp xếp, rồi danh sách thẻ đánh giá. Dùng chung cho trang đánh giá
/// và tab Đánh giá ở hồ sơ, cả điện thoại lẫn desktop.
class ProfileReviews extends StatefulWidget {
  const ProfileReviews({super.key, required this.profile});
  final ProfileData profile;
  @override
  State<ProfileReviews> createState() => _ProfileReviewsState();
}

class _ProfileReviewsState extends State<ProfileReviews>
    with AutomaticKeepAliveClientMixin {
  final rows = <Map>[];
  List tags = [];
  String role = 'all';
  ReviewSort sort = ReviewSort.newest;
  int page = 0, generation = 0, sellers = 0;
  late int count = widget.profile.ratingCount;
  late double average = widget.profile.ratingAverage.toDouble();
  bool busy = false, more = false, failed = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    fetch(reset: true);
  }

  Future<void> fetch({bool reset = false}) async {
    if (!reset && busy) return;
    final request = ++generation;
    final next = reset ? 1 : page + 1;
    setState(() {
      busy = true;
      failed = false;
      if (reset) {
        rows.clear();
        page = 0;
        more = false;
      }
    });
    try {
      final response = await ApiClient().dio.get(
        '/users/${widget.profile.id}/reviews',
        queryParameters: {'page': next, 'role': role, 'sort': sort.name},
      );
      final data = response.data['data'] as Map;
      if (!mounted || request != generation) return;
      setState(() {
        rows.addAll((data['items'] as List).cast<Map>());
        tags = data['tags'] as List;
        page = next;
        count = data['count'] as int;
        sellers = data['sellers'] as int;
        average = (data['average'] as num).toDouble();
        more = data['hasMore'] == true;
        busy = false;
      });
    } catch (_) {
      if (mounted && request == generation) {
        setState(() {
          busy = false;
          failed = true;
        });
      }
    }
  }

  void _setRole(String value) {
    if (role == value) return;
    role = value;
    fetch(reset: true);
  }

  Future<void> _pickSort(BuildContext anchor) async {
    final l = AppLocalizations.of(context)!;
    final picked = await showAppDropdown<ReviewSort>(
      anchor,
      selected: sort,
      options: [
        for (final value in ReviewSort.values)
          AppSheetOption(value, value.label(l)),
      ],
    );
    if (picked == null || picked == sort) return;
    sort = picked;
    fetch(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = AppLocalizations.of(context)!;
    return RefreshIndicator(
      onRefresh: () => fetch(reset: true),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.extentAfter < 300 && more && !busy && !failed) {
            fetch();
          }
          return false;
        },
        child: ListView.builder(
          key: const PageStorageKey('profile-reviews'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          itemCount: rows.length + 2,
          itemBuilder: (context, index) {
            if (index == 0) return _header(l);
            if (index <= rows.length) {
              return ReviewCard(
                key: ValueKey(rows[index - 1]['id']),
                row: rows[index - 1],
                ownerName: widget.profile.fullName,
                isOwner: context.currentUser?.id == widget.profile.id,
                onChanged: () => fetch(reset: true),
              );
            }
            if (busy) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (failed) {
              return TextButton(onPressed: fetch, child: Text(l.retry));
            }
            return rows.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        l.productSellerNoReviews,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                : const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _header(AppLocalizations l) {
    final theme = Theme.of(context).textTheme;
    final counts = {
      for (final tag in tags) '${tag['tag']}': (tag['count'] as num).toInt(),
    };
    final labels = reviewTags(l);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Lọc theo người viết
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final entry in {
                'all': l.tradeAll,
                'buyer': l.tradeFromBuyer,
                'seller': l.tradeFromSeller,
              }.entries)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _RoleChip(
                    key: ValueKey('reviews-role-${entry.key}'),
                    label: entry.value,
                    selected: role == entry.key,
                    onTap: () => _setRole(entry.key),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Tổng quan: điểm + sao + số đánh giá | dải lời khen
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                key: const ValueKey('reviews-summary'),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    count > 0 ? average.toStringAsFixed(1) : '—',
                    style: theme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  ReviewStars(average, size: 17),
                  const SizedBox(height: 4),
                  Text(
                    l.reviewCount(count),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
              const VerticalDivider(width: 28, color: Color(0xffe6e6e6)),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final entry in _tagStyles.entries)
                        _TagBadge(
                          key: ValueKey('reviews-tag-${entry.key}'),
                          icon: entry.value.$1,
                          color: entry.value.$2,
                          label: labels[entry.key] ?? entry.key,
                          count: counts[entry.key] ?? 0,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                l.reviews,
                style: theme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Builder(
              builder: (anchor) => OutlinedButton.icon(
                key: const ValueKey('reviews-sort'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: const BorderSide(color: Color(0xffcccccc)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => _pickSort(anchor),
                iconAlignment: IconAlignment.end,
                icon: const Icon(AppIcons.chevronDown, size: 16),
                label: Text(sort.label(l)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? const Color(0xffededed) : Colors.transparent,
    shape: const StadiumBorder(),
    child: InkWell(
      customBorder: const StadiumBorder(),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    ),
  );
}

/// Huy hiệu lời khen: icon tròn màu, số lượt, tên lời khen
class _TagBadge extends StatelessWidget {
  const _TagBadge({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
  });
  final IconData icon;
  final Color color;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: SizedBox(
      width: 74,
      child: Opacity(
        opacity: count > 0 ? 1 : 0.45,
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 6),
            Text('$count', style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Một đánh giá: người viết, sao · "Đánh giá từ người mua/bán" · thời gian,
/// nội dung, lời khen, món đồ đã giao dịch
class ReviewCard extends StatelessWidget {
  const ReviewCard({
    super.key,
    required this.row,
    this.ownerName = '',
    this.isOwner = false,
    this.onChanged,
  });
  final Map row;

  /// Tên chủ hồ sơ (người được đánh giá), hiện ở phần phản hồi
  final String ownerName;

  /// Chủ hồ sơ đang xem: được phản hồi một lần; người khác: được báo cáo
  final bool isOwner;
  final VoidCallback? onChanged;

  Future<void> _reply(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l.reviewReply),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 500,
          maxLines: 4,
          decoration: InputDecoration(hintText: l.reviewReplyHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, controller.text.trim()),
            child: Text(l.reviewReply),
          ),
        ],
      ),
    );
    controller.dispose();
    if (text == null || text.isEmpty || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ApiClient().dio.post(
        '/users/me/reviews/${Uri.encodeComponent('${row['id']}')}/reply',
        data: {'text': text},
      );
      onChanged?.call();
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(tradeErrorText(error, l))));
    }
  }

  Future<void> _report(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    if (context.currentUser == null) return;
    final reason = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      constraints: const BoxConstraints(maxWidth: 520),
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Text(
              l.reviewReport,
              style: Theme.of(sheet).textTheme.titleMedium,
            ),
          ),
          for (final reason in [
            l.reviewReportFake,
            l.feedReportOffensive,
            l.reviewReportPrivate,
            l.feedReportSpam,
            l.feedReportOther,
          ])
            ListTile(
              title: Text(reason),
              onTap: () => Navigator.pop(sheet, reason),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
    if (reason == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ReportRepository().submitReview(
        reviewId: '${row['id']}',
        reason: reason,
      );
      messenger.showSnackBar(SnackBar(content: Text(l.feedReported)));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(tradeErrorText(error, l))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!,
        labels = reviewTags(l),
        author = row['author'] as Map,
        trade = row['trade'] as Map;
    final name = author['fullName'] as String,
        amount = num.tryParse('${trade['price']}'),
        comment = (row['comment'] as String? ?? '').trim(),
        fromSeller = row['fromSeller'] == true;
    const muted = TextStyle(color: AppColors.textSecondary, fontSize: 13);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xffeeeeee))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProfileAvatar(
                radius: 20,
                url: resolveMediaUrl(author['avatarUrl'] as String?),
                initials: ProfileHeader.initials(name),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              if (!isOwner && context.currentUser != null)
                IconButton(
                  tooltip: l.reviewReport,
                  icon: const Icon(AppIcons.report, size: 18),
                  color: AppColors.textSecondary,
                  onPressed: () => _report(context),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              ReviewStars((row['stars'] as num).toDouble(), size: 17),
              Text(
                '· ${fromSeller ? l.revFromSeller : l.revFromBuyer} · '
                '${TimeAgoFormatter.format(DateTime.parse(row['createdAt']), l)}',
                style: muted,
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(comment, style: const TextStyle(fontSize: 15, height: 1.4)),
          ],
          if ((row['tags'] as List? ?? const []).isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final key in row['tags'] as List)
                  if (labels.containsKey(key))
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xfff3f3f3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        labels[key]!,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
              ],
            ),
          ],
          if ((row['reply'] as String?)?.trim() case final reply?
              when reply.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.fill,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.reviewReplyFrom(ownerName),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(reply, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ] else if (isOwner)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _reply(context),
                icon: const Icon(AppIcons.chat, size: 16),
                label: Text(l.reviewReply),
              ),
            ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xffeeeeee)),
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  color: const Color(0xfff6f6f6),
                  child: trade['image'] == null
                      ? const Icon(Icons.image_outlined)
                      : AppLocalImage(path: trade['image'], cacheWidth: 160),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${trade['title']}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (amount != null)
                        Text(
                          CurrencyFormatter.formatVnd(
                            amount,
                            locale: l.localeName,
                          ),
                          style: const TextStyle(
                            color: Color(0xffce2854),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
