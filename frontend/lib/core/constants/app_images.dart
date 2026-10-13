class AppImages {
  AppImages._();

  // -- IMPORTS CLASS -- //
  static const appLogos = AppLogos();
  static const appIcons = AppIcons();
  static const coreImages = CoreImages();
  static const categoryImages = CategoryImages();
}

class AppLogos {
  const AppLogos();
  final String appLogo = 'assets/logos/app-logo.png';
}

class AppIcons {
  const AppIcons();
  final String gmailLogo = 'assets/icons/gmail-logo.png';
}

class CoreImages {
  const CoreImages();
  final String deviceNotSupported = 'assets/images/device-not-supported.jpg';
}

/// Ảnh minh hoạ cho danh mục đăng tin.
/// TODO: Thay bằng ảnh danh mục chính thức khi có từ Figma (hiện dùng tạm ảnh có sẵn,
/// danh mục nào chưa có ảnh sẽ hiển thị icon dự phòng).
class CategoryImages {
  const CategoryImages();
  final String? phone = null;
  final String electronics = 'assets/images/marketplace/listing-camera.png';
  final String? vehicles = null;
  final String? fashion = null;
  final String? appliances = null;
  final String? pets = null;
  final String home = 'assets/images/marketplace/listing-lamp.png';
}
