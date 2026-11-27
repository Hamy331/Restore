import 'package:flutter/material.dart';
import 'package:restore/core/config/app_environment.dart';

import '../../models/trusted_shop_item.dart';
import '../../repositories/trusted_shop_repository.dart';
import 'package:restore/modules/account/views/public_profile/public_profile_view.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/core/routes/slug.dart';

/// Route `/shops/:id`: mở hồ sơ của chủ shop (ảnh bìa, tin đang bán, đánh giá).
/// [shop] là thẻ shop vừa bấm (tuỳ chọn); có chủ shop thì mở hồ sơ ngay,
/// thiếu thì tra shop trước. Đóng trang trả về trạng thái theo dõi mới (bool)
/// nếu đã đổi.
class ShopDetailView extends StatelessWidget {
  final String shopId;
  final TrustedShopItem? shop;

  const ShopDetailView({super.key, required this.shopId, this.shop});

  static const String path = '/shops/:id';

  /// Đường dẫn mở trang của shop [shopId]
  static String location(String shopId, {String? name}) =>
      slugPath('/shops', shopId, name);

  @override
  Widget build(BuildContext context) {
    final ownerId = shop?.shop.ownerId;
    if (ownerId != null && ownerId.isNotEmpty) {
      return PublicProfileView(userId: ownerId, returnShopFollow: true);
    }
    return _ShopOwnerLookup(key: ValueKey(shopId), id: shopId);
  }
}

class _ShopOwnerLookup extends StatefulWidget {
  const _ShopOwnerLookup({super.key, required this.id});
  final String id;
  @override
  State<_ShopOwnerLookup> createState() => _ShopOwnerLookupState();
}

class _ShopOwnerLookupState extends State<_ShopOwnerLookup> {
  late Future<TrustedShopItem> shop = _fetch();

  Future<TrustedShopItem> _fetch() =>
      (AppEnvironment.useMockData
              ? MockTrustedShopRepository()
              : ApiTrustedShopRepository())
          .getShop(widget.id);

  @override
  Widget build(BuildContext context) => FutureBuilder<TrustedShopItem>(
    future: shop,
    builder: (context, snapshot) {
      final item = snapshot.data;
      if (item != null) {
        return PublicProfileView(
          userId: item.shop.ownerId,
          returnShopFollow: true,
        );
      }
      final l = AppLocalizations.of(context)!;
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: snapshot.hasError
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l.accUserNotFound),
                    TextButton(
                      onPressed: () => setState(() => shop = _fetch()),
                      child: Text(l.retry),
                    ),
                  ],
                )
              : const CircularProgressIndicator(),
        ),
      );
    },
  );
}
