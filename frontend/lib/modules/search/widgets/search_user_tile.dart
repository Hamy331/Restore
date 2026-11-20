import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/utils/app_image_provider.dart';
import 'package:restore/shared/widgets/search/app_search_account_tile.dart';

import '../models/search_user_item.dart';

/// Người dùng trong kết quả / gợi ý tìm kiếm: ảnh đại diện, tên (kèm icon
/// cửa hàng nếu có shop uy tín), @username và số tin đang bán
class SearchUserTile extends StatelessWidget {
  final SearchUserItem user;
  final String? highlight;
  final Widget? trailing;
  final VoidCallback onTap;

  static const double _avatarSize = 44;

  const SearchUserTile({
    super.key,
    required this.user,
    required this.onTap,
    this.highlight,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final avatarUrl = user.avatarUrl;
    return AppSearchAccountTile(
      leading: CircleAvatar(
        radius: _avatarSize / 2,
        backgroundColor: AppColors.primarySoft,
        foregroundImage: avatarUrl == null || avatarUrl.isEmpty
            ? null
            : appImageProvider(avatarUrl),
        child: Text(
          _initial(user.fullName),
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
      ),
      title: user.fullName,
      highlight: highlight,
      badge: user.hasShop
          ? Tooltip(
              message: l10n.searchUserHasShop,
              child: const Icon(
                AppIcons.store,
                size: 15,
                color: AppColors.primaryDark,
              ),
            )
          : null,
      subtitle: l10n.searchUserSubtitle(user.username, user.listingCount),
      trailing: trailing,
      onTap: onTap,
    );
  }

  /// Chữ cái đầu của tên cuối, VD "Nguyễn Văn Bình" → "B"
  static String _initial(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    final last = words.isEmpty ? '' : words.last;
    return last.isEmpty ? '?' : last.characters.first.toUpperCase();
  }
}
