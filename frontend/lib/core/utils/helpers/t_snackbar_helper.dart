import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import 'package:toastification/toastification.dart';

class TSnackBarHelper {
  TSnackBarHelper._();

  static void showSuccess(
    BuildContext context, {
    String? title,
    required String message,
  }) {
    final l10n = AppLocalizations.of(context)!;
    _showToast(
      context: context,
      title: title ?? l10n.successTitle,
      message: message,
      type: ToastificationType.success,
      primaryColor: AppColors.success,
      backgroundColor: AppColors.successBg,
      icon: Icons.check_rounded,
    );
  }

  static void showError(
    BuildContext context, {
    String? title,
    required String message,
  }) {
    final l10n = AppLocalizations.of(context)!;
    _showToast(
      context: context,
      title: title ?? l10n.errorTitle,
      message: message,
      type: ToastificationType.error,
      primaryColor: AppColors.error,
      backgroundColor: AppColors.errorBg,
      icon: Icons.error_outline_rounded,
    );
  }

  static void showWarning(
    BuildContext context, {
    String? title,
    required String message,
  }) {
    final l10n = AppLocalizations.of(context)!;
    _showToast(
      context: context,
      title: title ?? l10n.warningTitle,
      message: message,
      type: ToastificationType.warning,
      primaryColor: AppColors.warning,
      backgroundColor: AppColors.warningBg,
      icon: Icons.warning_amber_rounded,
    );
  }

  static void showInfo(
    BuildContext context, {
    String? title,
    required String message,
  }) {
    final l10n = AppLocalizations.of(context)!;
    _showToast(
      context: context,
      title: title ?? l10n.infoTitle,
      message: message,
      type: ToastificationType.info,
      primaryColor: AppColors.info,
      backgroundColor: AppColors.infoBg,
      icon: Icons.info_outline_rounded,
    );
  }

  static void _showToast({
    required BuildContext context,
    required String title,
    required String message,
    required ToastificationType type,
    required Color primaryColor,
    required Color backgroundColor,
    required IconData icon,
  }) {
    toastification.show(
      context: context,
      type: type,
      style: ToastificationStyle.flat,
      primaryColor: primaryColor,
      backgroundColor: backgroundColor,
      foregroundColor: primaryColor,
      icon: Icon(icon, size: 24.w),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
      ),
      description: Text(message, style: TextStyle(fontSize: 13.sp)),
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 3),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      borderRadius: BorderRadius.circular(12.r),
      boxShadow: const [
        BoxShadow(
          color: AppColors.shadow,
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
      showProgressBar: false,
      // ignore: deprecated_member_use
      closeButtonShowType: CloseButtonShowType.always,
      closeOnClick: true,
      animationBuilder: (context, animation, alignment, child) {
        return SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(0, -1.5),
                end: const Offset(0, 0),
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutBack,
                  reverseCurve: Curves.easeIn,
                ),
              ),
          child: child,
        );
      },
    );
  }
}
