import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/theme/app_glass.dart';
import 'package:restore/data/models/listing_model.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_local_image.dart';
import 'package:restore/shared/widgets/glass/app_glass_container.dart';
import 'package:restore/shared/widgets/loading/app_loading_indicator.dart';

/// Một tin nháp trong trang Tin nháp: ảnh bìa, tiêu đề, danh mục, số ảnh,
/// lần sửa cuối và nút xóa. Bấm vào thẻ để soạn tiếp.
class DraftCard extends StatelessWidget {
  final ListingModel draft;

  /// Tên danh mục đã dịch, null khi chưa chọn hoặc chưa tải danh mục
  final String? categoryName;
  final bool isOpening;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const DraftCard({
    super.key,
    required this.draft,
    required this.categoryName,
    this.isOpening = false,
    this.onTap,
    this.onDelete,
  });

  static const double _thumbSize = 76;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = draft.title.trim();
    final updatedAt = draft.updatedAt?.toLocal();
    final meta = [
      l10n.draftPhotoCount(draft.images.length),
      if (updatedAt != null)
        l10n.draftEditedAt(DateFormat('HH:mm dd/MM/yyyy').format(updatedAt)),
    ].join(' · ');

    return AppGlassContainer(
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppGlass.radius),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox.square(
                    dimension: _thumbSize,
                    child: ColoredBox(
                      color: AppColors.primarySoft,
                      child: draft.images.isEmpty
                          ? const Icon(
                              AppIcons.image,
                              color: AppColors.primaryDark,
                            )
                          : AppLocalImage(
                              path: draft.images.first,
                              cacheWidth: 240,
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.isEmpty ? l10n.draftUntitled : title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.3,
                          fontWeight: FontWeight.w700,
                          color: title.isEmpty
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        categoryName ?? l10n.draftNoCategory,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox.square(
                  dimension: 44,
                  child: isOpening
                      ? const Center(child: AppLoadingIndicator(dotSize: 6))
                      : IconButton(
                          tooltip: l10n.draftDeleteConfirm,
                          onPressed: onDelete,
                          icon: const Icon(
                            AppIcons.delete,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
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
