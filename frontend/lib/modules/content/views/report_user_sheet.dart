import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';

import '../../../l10n/app_localizations.dart';
import '../../auth/bloc/auth/auth_context.dart';
import '../repositories/report_repository.dart';

/// Báo cáo một người dùng từ trang hồ sơ: chọn lý do rồi gửi lên admin.
/// Chưa đăng nhập thì chuyển tới trang đăng nhập.
Future<void> reportUser(
  BuildContext context, {
  required String userId,
  required String username,
  ReportRepository? repository,
}) async {
  if (context.currentUser == null) {
    final from = GoRouterState.of(context).uri.toString();
    context.push('/login?from=${Uri.encodeComponent(from)}');
    return;
  }
  final l = AppLocalizations.of(context)!;
  final reason = await showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    useRootNavigator: true,
    backgroundColor: AppColors.surface,
    constraints: const BoxConstraints(maxWidth: 520),
    builder: (sheet) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
          child: Text(
            l.reportUserTitle,
            style: Theme.of(sheet).textTheme.titleMedium,
          ),
        ),
        for (final reason in [
          l.feedReportSpam,
          l.feedReportScam,
          l.feedReportOffensive,
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
    await (repository ?? ReportRepository()).submitUser(
      userId: userId,
      username: username,
      reason: reason,
    );
    messenger.showSnackBar(SnackBar(content: Text(l.feedReported)));
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(l.productActionFailed)));
  }
}
