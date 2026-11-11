import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/l10n/app_localizations.dart';

import '../models/shop_poster.dart';

/// Nhãn, màu và thông báo lỗi dùng chung cho các trang poster
extension PosterLabels on AppLocalizations {
  String posterState(ShopPosterState state) => switch (state) {
    ShopPosterState.pending => spFilterPending,
    ShopPosterState.scheduled => spFilterScheduled,
    ShopPosterState.running => spFilterRunning,
    ShopPosterState.ended => spFilterEnded,
    ShopPosterState.rejected => spFilterRejected,
    ShopPosterState.stopped => spStateStopped,
  };

  String rejectReason(PosterRejectReason reason) => switch (reason) {
    PosterRejectReason.wrongSize => spReasonWrongSize,
    PosterRejectReason.misleadingPrice => spReasonMisleadingPrice,
    PosterRejectReason.brandMisuse => spReasonBrandMisuse,
    PosterRejectReason.prohibited => spReasonProhibited,
    PosterRejectReason.tooMuchText => spReasonTooMuchText,
    PosterRejectReason.other => spReasonOther,
  };

  /// Thông báo cho mã lỗi backend
  String posterError(String code) => switch (code) {
    'POSTER_SLOT_FULL' => spErrSlotFull,
    'POSTER_MONTHLY_LIMIT' => spErrMonthly,
    'POSTER_COOLDOWN' => spErrCooldown,
    'POSTER_PLAN_REQUIRED' => spErrPlan,
    'SHOP_REQUIRED' => spErrShop,
    'POSTER_LISTING_INVALID' => spErrListing,
    'POSTER_START_TOO_LATE' => spErrStartLate,
    'INVALID_IMAGE_URL' || 'INVALID_IMAGE' || 'IMAGE_TOO_LARGE' => spErrImage,
    'POSTER_NOT_EDITABLE' || 'POSTER_NOT_STOPPABLE' => spErrNotEditable,
    _ => spErrGeneric,
  };
}

/// Màu chữ / nền của nhãn trạng thái
(Color, Color) posterStateColors(ShopPosterState state) => switch (state) {
  ShopPosterState.running => (AppColors.success, AppColors.successBg),
  ShopPosterState.pending => (AppColors.warning, AppColors.warningBg),
  ShopPosterState.scheduled => (AppColors.info, AppColors.infoBg),
  ShopPosterState.rejected => (AppColors.error, AppColors.errorBg),
  ShopPosterState.ended ||
  ShopPosterState.stopped => (AppColors.textSecondary, AppColors.cream),
};

/// Ngày ngắn kiểu 12/11
String posterDay(DateTime date) => DateFormat('dd/MM').format(date);
