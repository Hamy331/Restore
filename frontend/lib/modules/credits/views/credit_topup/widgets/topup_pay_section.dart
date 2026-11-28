import 'package:flutter/material.dart';
import 'package:restore/shared/widgets/loading/app_loading_indicator.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/utils/helpers/t_snackbar_helper.dart';
import 'package:restore/data/models/credit_topup_model.dart';
import 'package:restore/data/models/enums/credit_enums.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_action_buttons.dart';
import 'package:restore/shared/widgets/glass/app_glass_container.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../bloc/credit_topup/credit_topup_cubit.dart';
import '../../../services/zalopay_launcher.dart';
import '../../../utils/credit_format.dart';

/// Bước 3: trả tiền. Điện thoại thật: mở thẳng app ZaloPay (hoặc trang web
/// ZaloPay khi chưa cài app). Máy thử (emulator, web, desktop) ở chế độ
/// sandbox: hiện hướng dẫn và nút thanh toán tạm. Xu chỉ vào khi backend xác nhận.
class TopupPaySection extends StatefulWidget {
  const TopupPaySection({
    super.key,
    this.launcher = const ZaloPayLauncher(),
    this.isTestDevice,
  });

  /// Mở app ZaloPay; truyền bản giả trong test
  final ZaloPayLauncher launcher;

  /// Ép máy thử / máy thật (test); null thì tự nhận biết
  final bool? isTestDevice;

  @override
  State<TopupPaySection> createState() => _TopupPaySectionState();
}

class _TopupPaySectionState extends State<TopupPaySection> {
  late final AppLifecycleListener _lifecycle;

  /// Máy thử (emulator...): null khi chưa biết
  bool? _testDevice;

  /// Đang chuyển sang ZaloPay (app hoặc trang web)
  bool _opening = false;

  /// Lần mở trang web gần nhất thất bại
  bool _openFailed = false;

  /// Máy chưa cài app ZaloPay (đúng bản sandbox/thật theo đơn)
  bool _appMissing = false;

  /// Máy không mở app ZaloPay được (không phải Android): chỉ dùng trang web
  bool _appUnsupported = false;

  @override
  void initState() {
    super.initState();
    // Trả xong trên ZaloPay rồi quay lại app: hỏi ngay, khỏi chờ lượt hỏi kế
    _lifecycle = AppLifecycleListener(
      onResume: () => context.read<CreditTopupCubit>().checkNow(),
    );
    _testDevice = widget.isTestDevice;
    if (_testDevice == null) {
      widget.launcher.isTestDevice().then((value) {
        if (!mounted) return;
        setState(() => _testDevice = value);
        _autoOpen();
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _autoOpen());
    }
  }

  /// Máy thật: chuyển người dùng sang ZaloPay luôn, ưu tiên app ZaloPay.
  /// Máy thử thì không tự mở (thường không có app ZaloPay), dùng nút tạm.
  void _autoOpen() {
    if (!mounted || _testDevice != false) return;
    final order = context.read<CreditTopupCubit>().state.order;
    final zaloPay = order?.zaloPay;
    final payUrl = order?.payUrl;
    if (zaloPay != null) {
      _openApp(zaloPay);
    } else if (payUrl != null) {
      _openGateway(payUrl);
    }
  }

  Future<void> _openApp(ZaloPayAppInfo info) async {
    setState(() {
      _opening = true;
      _openFailed = false;
    });
    final result = await widget.launcher.pay(info);
    if (!mounted) return;
    final payUrl = context.read<CreditTopupCubit>().state.order?.payUrl;
    if (result == ZaloPayLaunchResult.unsupported) {
      _appUnsupported = true;
      if (payUrl != null) return _openGateway(payUrl);
    }
    setState(() {
      _opening = false;
      _appMissing = result == ZaloPayLaunchResult.notInstalled;
    });
  }

  Future<void> _openGateway(String url) async {
    setState(() {
      _opening = true;
      _openFailed = false;
    });
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      opened = false;
    }
    if (!mounted) return;
    // Không mở được thì khung ZaloPay hiện lời báo và nút để thử lại
    setState(() {
      _opening = false;
      _openFailed = !opened;
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.watch<CreditTopupCubit>();
    // Lùi về bước trước thì đơn bị xoá trong lúc trang này còn đang chạy
    // hiệu ứng chuyển trang: không vẽ gì thay vì lỗi
    final order = cubit.state.order;
    if (order == null) return const SizedBox.shrink();
    final busy = cubit.state.busy;
    // Không có cách trả thật nào (backend bỏ qua cổng, VietQR chưa có tài
    // khoản nhận): nút tạm là đường duy nhất, kể cả trên máy thật
    final noRealPayment =
        order.payUrl == null &&
        order.zaloPay == null &&
        (order.method != CreditPayMethod.vietQr || order.vietQr == null);
    // Hướng dẫn + nút thanh toán tạm: chỉ ở sandbox (backend quyết định), trên
    // máy thử; máy thật trả qua ZaloPay
    final showTestTools =
        order.sandbox && (_testDevice == true || noRealPayment);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        if (showTestTools) ...[
          _Hint(
            text: l10n.creditSandboxNote,
            color: AppColors.info,
            background: AppColors.infoBg,
          ),
          const SizedBox(height: 12),
        ],
        if (order.method == CreditPayMethod.vietQr)
          _VietQrPanel(order: order)
        else
          _GatewayPanel(
            order: order,
            busy: busy,
            opening: _opening,
            openFailed: _openFailed,
            appMissing: _appMissing,
            onOpenWeb: _openGateway,
            onOpenApp: order.zaloPay == null || _appUnsupported
                ? null
                : () => _openApp(order.zaloPay!),
          ),
        if (showTestTools) ...[
          const SizedBox(height: 16),
          Text(
            l10n.creditSimulateTitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AppPrimaryActionButton(
                  label: l10n.creditSimulateSuccess,
                  icon: AppIcons.check,
                  isLoading: busy,
                  onPressed: busy ? null : () => cubit.simulate(success: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppSecondaryActionButton(
                  label: l10n.creditSimulateFail,
                  icon: AppIcons.close,
                  onPressed: busy ? null : () => cubit.simulate(success: false),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: busy ? null : cubit.cancel,
            child: Text(
              l10n.creditCancelOrder,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ),
      ],
    );
  }
}

class _GatewayPanel extends StatelessWidget {
  final CreditTopupModel order;
  final bool busy;
  final bool opening;
  final bool openFailed;
  final bool appMissing;
  final ValueChanged<String> onOpenWeb;

  /// Mở thẳng app ZaloPay; null khi không mở app được (không có thông tin
  /// app-to-app, hoặc máy không phải Android)
  final VoidCallback? onOpenApp;

  const _GatewayPanel({
    required this.order,
    required this.busy,
    required this.opening,
    required this.openFailed,
    required this.appMissing,
    required this.onOpenWeb,
    required this.onOpenApp,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final payUrl = order.payUrl;
    final openApp = onOpenApp;
    return AppGlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            CreditFormat.vnd(context, order.amountVnd),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${l10n.creditOrderCode}: ${order.code} · '
            '${CreditFormat.points(context, order.totalCredits)}',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          if (payUrl == null && openApp == null)
            _Hint(
              text: l10n.creditGatewayNotConnected,
              color: AppColors.warning,
              background: AppColors.warningBg,
            )
          else ...[
            if (appMissing || openFailed) ...[
              _Hint(
                text: appMissing
                    ? l10n.creditZaloPayNotInstalled
                    : l10n.creditGatewayOpenFailed,
                color: AppColors.warning,
                background: AppColors.warningBg,
              ),
              const SizedBox(height: 12),
            ],
            if (openApp != null)
              AppPrimaryActionButton(
                label: l10n.creditOpenZaloPayApp,
                icon: AppIcons.wallet,
                isLoading: opening,
                onPressed: opening ? null : openApp,
              )
            else if (payUrl != null)
              AppPrimaryActionButton(
                label: l10n.creditOpenGateway,
                icon: AppIcons.wallet,
                isLoading: opening,
                onPressed: opening ? null : () => onOpenWeb(payUrl),
              ),
            // Có app thì trang web là lối phụ (máy chưa cài app ZaloPay)
            if (openApp != null && payUrl != null && appMissing)
              Center(
                child: TextButton(
                  onPressed: opening ? null : () => onOpenWeb(payUrl),
                  child: Text(l10n.creditOpenGatewayWeb),
                ),
              ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: AppLoadingIndicator(
                    dotSize: 5,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    opening
                        ? l10n.creditGatewayOpening
                        : l10n.creditWaitingGateway,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: busy
                    ? null
                    : context.read<CreditTopupCubit>().checkNow,
                child: Text(l10n.creditCheckAgain),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final String text;
  final Color color;
  final Color background;

  const _Hint({
    required this.text,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppIcons.info, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, height: 1.5, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _VietQrPanel extends StatelessWidget {
  final CreditTopupModel order;

  const _VietQrPanel({required this.order});

  void _copy(BuildContext context, String value) {
    Clipboard.setData(ClipboardData(text: value));
    TSnackBarHelper.showSuccess(
      context,
      message: AppLocalizations.of(context)!.creditCopied,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final qr = order.vietQr;
    // Nội dung chuyển khoản do backend tạo (VD VietinBank cần "SEVQR <mã đơn>"); thiếu thì dùng mã đơn
    final transferNote = qr != null && qr.content.isNotEmpty ? qr.content : order.code;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppGlassContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                l10n.creditScanQr,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: 220,
                height: 220,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: qr != null && qr.imageUrl.isNotEmpty
                    ? Image.network(
                        qr.imageUrl,
                        fit: BoxFit.contain,
                        // Web: máy chủ ảnh VietQR không gửi header CORS nên tải bằng fetch bị chặn.
                        // Hiển thị luôn bằng thẻ <img> của trình duyệt (không cần CORS). App mobile không bị ảnh hưởng.
                        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                        errorBuilder: (_, _, _) => const Icon(
                          AppIcons.imageBroken,
                          color: AppColors.textSecondary,
                        ),
                      )
                    : Center(
                        child: Text(
                          l10n.creditVietQrUnavailable,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              Text(
                CreditFormat.vnd(context, order.amountVnd),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  l10n.creditQrExpires(
                    CreditFormat.time(context, order.expiresAt),
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppGlassContainer(
          showShadow: false,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Column(
            children: [
              if (qr != null) ...[
                _InfoRow(label: l10n.creditAccountName, value: qr.accountName),
                const Divider(height: 1, color: AppColors.border),
                _InfoRow(
                  label: l10n.creditAccountNo,
                  value: qr.accountNo,
                  onCopy: () => _copy(context, qr.accountNo),
                ),
                const Divider(height: 1, color: AppColors.border),
              ],
              _InfoRow(
                label: l10n.creditTransferContent,
                value: transferNote,
                highlight: true,
                onCopy: () => _copy(context, transferNote),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: AppLoadingIndicator(dotSize: 5, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.creditWaitingTransfer,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final VoidCallback? onCopy;

  const _InfoRow({
    required this.label,
    required this.value,
    this.highlight = false,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14,
                fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
                color: highlight
                    ? AppColors.primaryDark
                    : AppColors.textPrimary,
              ),
            ),
          ),
          if (onCopy != null)
            IconButton(
              tooltip: AppLocalizations.of(context)!.creditCopy,
              icon: const Icon(AppIcons.copy, size: 18),
              color: AppColors.textSecondary,
              onPressed: onCopy,
            ),
        ],
      ),
    );
  }
}
