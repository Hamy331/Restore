import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../models/feed_models.dart';

void feedNotice(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

/// Thời gian tương đối trong 7 ngày, sau đó hiện ngày cụ thể.
String feedTime(AppLocalizations l, DateTime date) {
  final elapsed = DateTime.now().difference(date);
  if (elapsed.inMinutes < 1) return l.feedNow;
  if (elapsed.inHours < 1) return l.feedMinutes(elapsed.inMinutes);
  if (elapsed.inDays < 1) return l.feedHours(elapsed.inHours);
  if (elapsed.inDays < 7) return l.feedDays(elapsed.inDays);
  final local = date.toLocal();
  return DateFormat(
    local.year == DateTime.now().year ? 'dd/MM' : 'dd/MM/yyyy',
  ).format(local);
}

class FeedAvatar extends StatelessWidget {
  const FeedAvatar({
    super.key,
    required this.name,
    this.size = 32,
    this.avatarUrl,
  });

  /// Avatar của người dùng hiện tại; chưa tải được hồ sơ thì dùng [fallbackName].
  FeedAvatar.me(
    FeedUser? me, {
    super.key,
    required String fallbackName,
    this.size = 32,
  }) : name = me == null || me.name.isEmpty ? fallbackName : me.name,
       avatarUrl = me?.avatarUrl;
  final String name;
  final String? avatarUrl;
  final double size;
  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: size / 2,
    foregroundImage: avatarUrl == null ? null : NetworkImage(avatarUrl!),
    backgroundColor: AppColors.primarySoft,
    child: Text(
      name.isEmpty ? '?' : name.characters.first,
      style: TextStyle(
        color: AppColors.primaryDark,
        fontSize: size * .4,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
