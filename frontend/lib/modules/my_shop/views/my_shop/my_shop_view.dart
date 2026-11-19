import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/network/media_url.dart';
import 'package:restore/services/media_picker_service.dart';

import '../../bloc/my_shop_cubit.dart';
import '../../repositories/my_shop_repository.dart';
import 'my_shop_mobile_view.dart';

/// Tải logo / ảnh bìa đang dùng về để căn chỉnh lại
typedef ShopImageLoader = Future<Uint8List> Function(String path);

Future<Uint8List> _loadImage(String path) async {
  final data = path.startsWith('assets/')
      ? await rootBundle.load(path)
      : await NetworkAssetBundle(
          Uri.parse(resolveMediaUrl(path)!),
        ).load(resolveMediaUrl(path)!);
  return data.buffer.asUint8List();
}

/// Trang Quản lý shop (nút "Quản lý shop" ở menu xoè của gói Cửa hàng): mở
/// shop, sửa tên, giới thiệu, địa chỉ, logo, ảnh bìa, màu nhận diện; xem số
/// liệu nhanh và trạng thái xác minh.
class MyShopView extends StatelessWidget {
  const MyShopView({super.key, this.repository, this.picker, this.imageLoader});

  static const String path = '/my-shop';

  final MyShopRepository? repository;
  final MediaPickerService? picker;
  final ShopImageLoader? imageLoader;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => MyShopCubit(repository ?? MyShopRepository())..load(),
    child: MyShopMobileView(
      picker: picker,
      imageLoader: imageLoader ?? _loadImage,
    ),
  );
}
