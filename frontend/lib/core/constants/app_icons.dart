import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Bộ icon duy nhất của app (Lucide Icons, nét bo tròn).
///
/// Mọi nơi trong app chỉ dùng `AppIcons.xxx`, không gọi thẳng `Icons.xxx`
/// hay `LucideIcons.xxx`. Muốn đổi sang bộ icon khác chỉ cần sửa file này.
///
/// Quy ước:
/// - Tên theo ý nghĩa (back, search, location...), không theo hình vẽ.
/// - Nét mặc định mảnh 1.5 (hậu tố 300 của Lucide) cho hợp phong cách kính mờ.
/// - Hậu tố `Active` cho trạng thái đang chọn: cùng hình, nét đậm hơn (500).
class AppIcons {
  AppIcons._();

  // Điều hướng
  static const IconData back = LucideIcons.arrowLeft300;
  static const IconData close = LucideIcons.x300;
  static const IconData closeStrong = LucideIcons.x500;
  static const IconData chevronRight = LucideIcons.chevronRight300;
  static const IconData chevronDown = LucideIcons.chevronDown300;
  static const IconData arrowUp = LucideIcons.arrowUp400;
  static const IconData more = LucideIcons.ellipsisVertical300;
  static const IconData menu = LucideIcons.menu300;
  static const IconData activity = LucideIcons.footprints300;
  static const IconData followUser = LucideIcons.userRoundPlus300;
  static const IconData filter = LucideIcons.slidersHorizontal300;

  // Thanh điều hướng chính
  static const IconData home = LucideIcons.house300;
  static const IconData homeActive = LucideIcons.house500;
  static const IconData chat = LucideIcons.messageCircleMore300;
  static const IconData chatActive = LucideIcons.messageCircleMore500;
  static const IconData listings = LucideIcons.package300;
  static const IconData listingsActive = LucideIcons.package500;
  static const IconData feeds = LucideIcons.galleryVerticalEnd300;
  static const IconData feedsActive = LucideIcons.galleryVerticalEnd500;
  static const IconData post = LucideIcons.squarePlus300;
  static const IconData postActive = LucideIcons.squarePlus500;
  static const IconData user = LucideIcons.userRound300;
  static const IconData userActive = LucideIcons.userRound500;

  // Hành động
  static const IconData add = LucideIcons.plus300;
  static const IconData saveDraft = LucideIcons.save400;
  static const IconData search = LucideIcons.search300;
  static const IconData searchEmpty = LucideIcons.searchX300;
  static const IconData history = LucideIcons.history300;
  static const IconData delete = LucideIcons.trash2300;

  /// Đưa gợi ý lên ô tìm kiếm để sửa tiếp (mũi tên chéo lên trái)
  static const IconData fillQuery = LucideIcons.arrowUpLeft300;
  static const IconData send = LucideIcons.send300;
  static const IconData refresh = LucideIcons.rotateCw300;
  static const IconData renew = LucideIcons.refreshCw300;
  static const IconData swap = LucideIcons.arrowLeftRight300;
  static const IconData logout = LucideIcons.logOut300;
  static const IconData settings = LucideIcons.settings300;
  static const IconData notification = LucideIcons.bell300;
  static const IconData favorite = LucideIcons.heart300;
  static const IconData favoriteActive = LucideIcons.heart500;
  static const IconData star = LucideIcons.star300;
  static const IconData visible = LucideIcons.eye300;
  static const IconData hidden = LucideIcons.eyeOff300;
  static const IconData block = LucideIcons.ban300;
  static const IconData report = LucideIcons.flag300;
  static const IconData edit = LucideIcons.squarePen300;
  static const IconData boost = LucideIcons.rocket300;

  // Mua bán
  static const IconData buy = LucideIcons.shoppingBag300;
  static const IconData offer = LucideIcons.handCoins300;
  static const IconData shop = LucideIcons.store300;
  static const IconData calendar = LucideIcons.calendar300;
  static const IconData priceUp = LucideIcons.trendingUp300;
  static const IconData priceDown = LucideIcons.trendingDown300;
  static const IconData priceEqual = LucideIcons.equal300;
  static const IconData live = LucideIcons.radio300;
  static const IconData sale = LucideIcons.badgePercent300;

  // Shop uy tín
  static const IconData brand = LucideIcons.crown300;
  static const IconData hot = LucideIcons.flame300;
  static const IconData event = LucideIcons.megaphone300;

  // AI / nổi bật
  static const IconData sparkle = LucideIcons.sparkles300;
  static const IconData sparkleActive = LucideIcons.sparkles500;
  static const IconData trendUp = LucideIcons.trendingUp300;
  static const IconData wallet = LucideIcons.wallet300;
  static const IconData pro = LucideIcons.crown300;
  static const IconData store = LucideIcons.store300;

  // Ảnh
  static const IconData addPhoto = LucideIcons.imagePlus300;
  static const IconData camera = LucideIcons.camera300;
  static const IconData gallery = LucideIcons.images300;
  static const IconData image = LucideIcons.image300;
  static const IconData imageBroken = LucideIcons.imageOff300;
  static const IconData zoomIn = LucideIcons.zoomIn300;
  static const IconData expand = LucideIcons.maximize300;

  // Vị trí
  static const IconData location = LucideIcons.mapPin300;
  static const IconData locationArea = LucideIcons.mapPinned300;
  static const IconData myLocation = LucideIcons.locateFixed300;
  static const IconData province = LucideIcons.building2300;
  static const IconData ward = LucideIcons.mapPinHouse300;
  static const IconData globe = LucideIcons.earth300;
  static const IconData locationUnknown = LucideIcons.mapPinOff300;

  // Trạng thái
  static const IconData check = LucideIcons.check500;
  static const IconData checkCircle = LucideIcons.circleCheck300;
  static const IconData checkCircleActive = LucideIcons.circleCheck500;
  static const IconData radioOn = LucideIcons.circleDot500;
  static const IconData radioOff = LucideIcons.circle300;
  static const IconData dot = LucideIcons.circle600;
  static const IconData info = LucideIcons.info300;
  static const IconData help = LucideIcons.circleQuestionMark300;
  static const IconData warning = LucideIcons.triangleAlert300;
  static const IconData error = LucideIcons.circleAlert300;
  static const IconData offline = LucideIcons.cloudOff300;
  static const IconData clock = LucideIcons.clock300;
  static const IconData shield = LucideIcons.shieldCheck300;
  static const IconData verified = LucideIcons.badgeCheck300;
  static const IconData wantedAlert = LucideIcons.bellPlus300;
  static const IconData following = LucideIcons.userRoundCheck300;
  static const IconData nearby = LucideIcons.radar300;

  // Tài khoản / xác thực
  static const IconData mail = LucideIcons.mail300;
  static const IconData mailOpen = LucideIcons.mailOpen300;
  static const IconData lock = LucideIcons.lockKeyhole300;
  static const IconData password = LucideIcons.rectangleEllipsis300;

  // Danh mục
  static const IconData category = LucideIcons.layoutGrid300;
  static const IconData categoryPhone = LucideIcons.smartphone300;
  static const IconData categoryElectronics = LucideIcons.laptop300;
  static const IconData categoryVehicle = LucideIcons.motorbike300;
  static const IconData categoryFashion = LucideIcons.shirt300;
  static const IconData categoryAppliance = LucideIcons.refrigerator300;
  static const IconData categoryPet = LucideIcons.pawPrint300;
  static const IconData categoryHome = LucideIcons.sofa300;
  static const IconData categoryBook = LucideIcons.bookOpen300;
  static const IconData categorySport = LucideIcons.volleyball300;
  static const IconData categoryBaby = LucideIcons.baby300;
  static const IconData categoryOther = LucideIcons.package300;

  static const Map<String, IconData> _categoryIcons = {
    'phone': categoryPhone,
    'electronics': categoryElectronics,
    'vehicle': categoryVehicle,
    'fashion': categoryFashion,
    'appliance': categoryAppliance,
    'pet': categoryPet,
    'home': categoryHome,
    'book': categoryBook,
    'sport': categorySport,
    'baby': categoryBaby,
    'other': categoryOther,
  };

  /// Icon theo khoá `icon` của danh mục từ API (VD "phone"); khoá lạ dùng
  /// icon chung. Backend thêm danh mục mới chỉ cần dùng một khoá có ở đây.
  static IconData forCategory(String? key) => _categoryIcons[key] ?? category;

  static const Map<String, IconData> _bannerIcons = {
    'post': post,
    'swap': swap,
    'ai': sparkle,
  };

  /// Icon minh hoạ banner trang chủ theo khoá `icon` từ API
  static IconData forBanner(String? key) => _bannerIcons[key] ?? sparkle;
}
