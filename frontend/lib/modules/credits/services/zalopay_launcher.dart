import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:restore/data/models/credit_topup_model.dart';

enum ZaloPayLaunchResult {
  /// Đã chuyển sang app ZaloPay
  opened,

  /// Máy chưa cài app ZaloPay (bản sandbox khi đơn tạo trên cổng sandbox)
  notInstalled,

  /// Nền tảng chưa hỗ trợ mở app (iOS, web, desktop): dùng trang web
  unsupported,
}

/// Mở thẳng app ZaloPay (app-to-app) bằng kênh native `restore/zalopay`
/// (android MainActivity.kt). Môi trường sandbox hay thật do backend quyết định.
class ZaloPayLauncher {
  const ZaloPayLauncher();

  static const _channel = MethodChannel('restore/zalopay');

  /// Máy dùng để thử (emulator Android, web, desktop): hiện hướng dẫn chế độ
  /// thử và nút thanh toán tạm. Điện thoại thật thì trả qua app ZaloPay.
  Future<bool> isTestDevice() async {
    if (kIsWeb) return true;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        try {
          return await _channel.invokeMethod<bool>('isEmulator') ?? false;
        } on MissingPluginException {
          return false;
        } on PlatformException {
          return false;
        }
      case TargetPlatform.iOS:
        return false;
      default:
        return true;
    }
  }

  Future<ZaloPayLaunchResult> pay(ZaloPayAppInfo info) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return ZaloPayLaunchResult.unsupported;
    }
    try {
      final result = await _channel.invokeMethod<String>('pay', {
        'appId': info.appId,
        'zpTransToken': info.zpTransToken,
        'sandbox': info.sandbox,
      });
      return result == 'opened'
          ? ZaloPayLaunchResult.opened
          : ZaloPayLaunchResult.notInstalled;
    } on MissingPluginException {
      return ZaloPayLaunchResult.unsupported;
    } on PlatformException {
      return ZaloPayLaunchResult.unsupported;
    }
  }
}
