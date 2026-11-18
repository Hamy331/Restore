import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/utils/formatters/time_ago_formatter.dart';
import 'package:restore/data/models/notification_model.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_local_image.dart';

import '../../../utils/notification_presenter.dart';

/// Một dòng thông báo: icon theo loại (hoặc ảnh tin kèm icon nhỏ), tiêu đề,
/// nội dung 2 dòng, thời gian. Chưa đọc thì nền kem, chữ đậm và chấm cam.
class NotificationTile extends StatelessWidget {
  final NotificationModel item;
  final VoidCallback onTap;

  const NotificationTile({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final unread = !item.isRead;
    return Material(
      color: unread ? AppColors.cream : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NotificationLeading(item: item),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      NotificationPresenter.title(l10n, item),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      NotificationPresenter.body(l10n, item),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      TimeAgoFormatter.format(item.createdAt, l10n),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                        color: unread
                            ? AppColors.primaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: AnimatedOpacity(
                  opacity: unread ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Icon tròn màu theo loại; có ảnh tin thì hiện ảnh, icon nhỏ ở góc
class _NotificationLeading extends StatelessWidget {
  final NotificationModel item;

  const _NotificationLeading({required this.item});

  static const double _size = 46;

  @override
  Widget build(BuildContext context) {
    final color = NotificationPresenter.color(item.type);
    final icon = NotificationPresenter.icon(item.type);
    final image = item.imageUrl;
    if (image == null || image.isEmpty) {
      // Cùng bề rộng với ô có ảnh để chữ các dòng thẳng hàng
      return SizedBox.square(
        dimension: _size + 4,
        child: Align(
          alignment: Alignment.topLeft,
          child: Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: color),
          ),
        ),
      );
    }
    return SizedBox.square(
      dimension: _size + 4,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: _size,
              height: _size,
              color: AppColors.background,
              child: AppLocalImage(
                path: image,
                width: _size,
                height: _size,
                cacheWidth: 160,
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 1.5),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 12, color: color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
