import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import '../bloc/create_listing/create_listing_bloc.dart';

/// Dải thông báo khi sửa tin đã đăng (dùng ở bước 2, bước 3, xem trước):
/// tin đã duyệt vẫn hiện bản cũ tới khi duyệt, quảng bá và ưu đãi giữ
/// nguyên, không đổi chuyên mục; kèm lý do bị từ chối lần trước nếu có.
/// Không sửa tin thì không hiện gì.
class EditListingNotice extends StatelessWidget {
  const EditListingNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final listing = context.select(
      (CreateListingBloc bloc) => bloc.state.editingListing,
    );
    if (listing == null) return const SizedBox.shrink();
    final approved = listing.status.isApproved;
    // Lý do lần trước: bản sửa bị từ chối, hoặc chính tin bị từ chối
    final rejected = approved
        ? (listing.pendingEdit?.isRejected ?? false
              ? listing.pendingEdit!.reviewReason
              : null)
        : listing.reviewReason;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (approved) ...[
            _line(AppIcons.visible, l10n.editNoticeLive),
            const SizedBox(height: 8),
            _line(AppIcons.lock, l10n.editNoticeCategoryLocked),
          ] else
            _line(AppIcons.clock, l10n.editNoticeReview),
          if (rejected != null && rejected.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _line(
              AppIcons.warning,
              l10n.editRejectedReason(rejected.trim()),
              color: AppColors.error,
            ),
          ],
        ],
      ),
    );
  }

  Widget _line(
    IconData icon,
    String text, {
    Color color = AppColors.primaryDark,
  }) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(width: 8),
      Expanded(
        child: Text(text, style: TextStyle(fontSize: 13, color: color)),
      ),
    ],
  );
}
