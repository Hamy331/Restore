import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

void feedNotice(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

String feedTime(AppLocalizations l, DateTime date) {
  final elapsed = DateTime.now().difference(date);
  if (elapsed.inMinutes < 1) return l.feedNow;
  if (elapsed.inHours < 1) return l.feedMinutes(elapsed.inMinutes);
  if (elapsed.inDays < 1) return l.feedHours(elapsed.inHours);
  return l.feedDays(elapsed.inDays);
}

class FeedAvatar extends StatelessWidget {
  const FeedAvatar({
    super.key,
    required this.name,
    this.size = 32,
    this.avatarUrl,
  });
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
