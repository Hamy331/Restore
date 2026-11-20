import 'package:flutter/material.dart';
import 'package:restore/core/network/api_client.dart';
import 'package:restore/core/network/media_url.dart';
import 'package:restore/core/utils/formatters/currency_formatter.dart';
import 'package:restore/core/utils/formatters/time_ago_formatter.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/chat/widgets/review_stars.dart';
import 'package:restore/shared/widgets/app_local_image.dart';
import '../../models/profile_models.dart';
import '../../widgets/profile_header.dart';
import 'seller_profile_summary.dart';

class ProfileReviews extends StatefulWidget {
  const ProfileReviews({super.key, required this.profile});
  final ProfileData profile;
  @override
  State<ProfileReviews> createState() => _ProfileReviewsState();
}

class _ProfileReviewsState extends State<ProfileReviews> {
  final rows = <Map>[];
  List tags = [];
  String role = 'all';
  int page = 0, generation = 0, sellers = 0;
  late int count = widget.profile.ratingCount;
  late double average = widget.profile.ratingAverage.toDouble();
  bool busy = false, more = false, failed = false;
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
        queryParameters: {'page': next, 'role': role},
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!,
        p = widget.profile,
        labels = reviewTags(l);
    final name = storefrontName(p);
    return RefreshIndicator(
      onRefresh: () => fetch(reset: true),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        itemCount: rows.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.sellerRatingsTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: ProfileAvatar(
                    radius: 26,
                    url: p.storefront.logo ?? p.avatarUrl,
                    initials: ProfileHeader.initials(name),
                  ),
                  title: Text(name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (count > 0)
                        Row(
                          children: [
                            Text(average.toStringAsFixed(1)),
                            const SizedBox(width: 4),
                            ReviewStars(average),
                          ],
                        ),
                      Text(l.reviewCount(count)),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final tag in tags)
                      if (labels.containsKey(tag['tag']))
                        Chip(
                          label: Text(
                            '${labels[tag['tag']]} (${tag['count']})',
                          ),
                        ),
                  ],
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final entry in {
                        'all': '${l.tradeAll} ($count)',
                        'seller': '${l.tradeFromSeller} ($sellers)',
                        'buyer': '${l.tradeFromBuyer} (${count - sellers})',
                      }.entries)
                        InkWell(
                          onTap: () {
                            if (role != entry.key) {
                              role = entry.key;
                              fetch(reset: true);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: role == entry.key
                                      ? Colors.black
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Text(
                              entry.value,
                              style: TextStyle(
                                fontWeight: role == entry.key
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
              ],
            );
          }
          if (index <= rows.length) return ReviewTile(row: rows[index - 1]);
          if (busy) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (failed || more) {
            return TextButton(
              onPressed: () => fetch(),
              child: Text(failed ? l.retry : l.tradeMore),
            );
          }
          return rows.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(l.productSellerNoReviews),
                )
              : const SizedBox.shrink();
        },
      ),
    );
  }
}

class ReviewTile extends StatelessWidget {
  const ReviewTile({super.key, required this.row});
  final Map row;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!,
        labels = reviewTags(l),
        author = row['author'] as Map,
        trade = row['trade'] as Map;
    final name = author['fullName'] as String,
        amount = num.tryParse(trade['price'].toString());
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileAvatar(
            radius: 17,
            url: resolveMediaUrl(author['avatarUrl'] as String?),
            initials: ProfileHeader.initials(name),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 4,
                  children: [
                    for (final key in row['tags'])
                      if (labels.containsKey(key))
                        Chip(label: Text(labels[key]!)),
                  ],
                ),
                Row(
                  children: [
                    ReviewStars((row['stars'] as num).toDouble()),
                    const SizedBox(width: 8),
                    Text(
                      TimeAgoFormatter.format(
                        DateTime.parse(row['createdAt']),
                        l,
                      ),
                    ),
                  ],
                ),
                if ((row['comment'] as String).isNotEmpty) Text(row['comment']),
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.all(6),
                  color: const Color(0xfff6f6f6),
                  child: Row(
                    children: [
                      if (trade['image'] != null) ...[
                        AppLocalImage(
                          path: trade['image'],
                          width: 40,
                          height: 40,
                          cacheWidth: 100,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trade['title'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (amount != null)
                              Text(
                                CurrencyFormatter.formatVnd(
                                  amount,
                                  locale: l.localeName,
                                ),
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
