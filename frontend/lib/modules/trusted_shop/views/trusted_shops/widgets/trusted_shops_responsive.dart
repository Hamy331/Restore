import 'package:restore/core/constants/app_dimesions.dart';

/// Số cột lưới của trang Shop uy tín theo bề ngang [available] của khu.
///
/// Dưới [AppDimesions.mobileWidth] (điện thoại) trả null: khu giữ hàng cuộn
/// ngang. Từ tablet trở lên là lưới nhiều cột, mỗi ô rộng ít nhất
/// [minWidth] và không cột nào bị bóp hẹp; luôn từ 2 đến 4 cột.
int? shopGridColumns(double available, {required double minWidth}) {
  // [available] đã trừ lề trái phải của khu; so với mốc điện thoại bằng
  // bề ngang gồm lề
  if (available + 32 < AppDimesions.mobileWidth) return null;
  const gap = 14.0;
  return ((available + gap) / (minWidth + gap)).floor().clamp(2, 4);
}
