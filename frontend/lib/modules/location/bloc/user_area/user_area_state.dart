import 'package:equatable/equatable.dart';

import '../../models/area_option.dart';

enum UserAreaStatus {
  /// Đang xin quyền vị trí / đổi GPS thành tỉnh
  locating,

  /// Đã có khu vực ([UserAreaState.area])
  ready,

  /// Không có quyền, không lấy được GPS, GPS ngoài Việt Nam hoặc người dùng
  /// chọn "Toàn quốc"
  nationwide,
}

/// Khu vực người dùng đang xem ở cả app (nút khu vực trên trang chủ)
class UserAreaState extends Equatable {
  final UserAreaStatus status;

  /// Tỉnh/thành theo GPS, hoặc khu vực người dùng tự chọn
  final AreaOption? area;

  /// true khi khu vực do người dùng tự chọn (không tự đổi theo GPS nữa)
  final bool isManual;

  const UserAreaState({
    this.status = UserAreaStatus.locating,
    this.area,
    this.isManual = false,
  });

  const UserAreaState.nationwide({this.isManual = false})
    : status = UserAreaStatus.nationwide,
      area = null;

  bool get isLocating => status == UserAreaStatus.locating;

  @override
  List<Object?> get props => [status, area, isManual];
}
