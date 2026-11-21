import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/data/models/administrative_unit_model.dart';
import 'package:restore/shared/models/listing_filter.dart';

import '../bloc/user_area/user_area_cubit.dart';
import '../bloc/user_area/user_area_state.dart';
import '../models/area_option.dart';
import '../views/area_search/area_search_view.dart';

extension ListingFilterAreaOption on ListingFilter {
  /// Lọc theo [area] (tỉnh/thành hoặc phường/xã), null là toàn quốc
  ListingFilter withAreaOption(AreaOption? area) => withArea(
    area?.code,
    isWard: area?.level == AdministrativeLevel.ward,
    label: area?.displayName,
  );

  /// Khu vực người dùng đã tự chọn trong app thành khu vực mặc định của
  /// trang. Khu vực đoán từ GPS lúc mở app không tự áp vào để danh sách không
  /// bị thu hẹp khi người dùng chưa chọn gì.
  ListingFilter withUserArea(BuildContext context) {
    final UserAreaState userArea;
    try {
      userArea = context.read<UserAreaCubit>().state;
    } catch (_) {
      // Trang dựng riêng không có UserAreaCubit (VD widget test)
      return this;
    }
    return userArea.isManual ? withAreaOption(userArea.area) : this;
  }
}

/// Mở trang chọn khu vực cho một trang danh sách tin và đổi luôn khu vực của
/// cả app như nút khu vực ở trang chủ. "Gần tôi" lấy tỉnh/thành theo GPS
/// (không định vị được thì về toàn quốc). Trả bộ lọc mới, null nếu đóng trang.
Future<ListingFilter?> pickListingArea(
  BuildContext context,
  ListingFilter filter,
) async {
  final userArea = context.read<UserAreaCubit>();
  final result = await context.push<AreaPickResult>(
    AreaSearchView.location(allowNationwide: true),
  );
  if (result == null) return null;
  if (result.nationwide) {
    userArea.selectNationwide();
    return filter.withAreaOption(null);
  }
  if (result.area case final area?) {
    userArea.select(area);
    return filter.withAreaOption(area);
  }
  await userArea.locate();
  return filter.withAreaOption(userArea.state.area);
}
