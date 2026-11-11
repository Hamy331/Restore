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
  final String zaloPay = 'assets/logos/zalopay.png';
  final String vietQr = 'assets/logos/vietqr.png';
}

class AppIcons {
  const AppIcons();
  final String gmailLogo = 'assets/icons/gmail-logo.png';
}

class CoreImages {
  const CoreImages();
  final String deviceNotSupported = 'assets/images/device-not-supported.jpg';
  final String hotSale = 'assets/images/hot-sale.png';
  final String hotFlame = 'assets/images/hot-flame.png';
}

/// Ảnh minh hoạ cho danh mục đăng tin.
/// TODO: Thay bằng ảnh danh mục chính thức khi có từ Figma (hiện dùng tạm ảnh có sẵn,
/// danh mục nào chưa có ảnh sẽ hiển thị icon dự phòng).
class CategoryImages {
  const CategoryImages();
  static const _dir = 'assets/images/categories';
  final String phone = '$_dir/phones.png';
  final String electronics = '$_dir/electronics.png';
  final String vehicles = '$_dir/vehicles.png';
  final String fashion = '$_dir/fashion.png';
  final String appliances = '$_dir/appliances.png';
  final String pets = '$_dir/pets.png';
  final String home = '$_dir/furniture.png';
  final String books = '$_dir/books.png';
  final String sports = '$_dir/sports.png';
  final String other = '$_dir/other.png';
}
