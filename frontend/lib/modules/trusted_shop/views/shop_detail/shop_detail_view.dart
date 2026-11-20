import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/ui/layouts/t_responsive_layout.dart';

import '../../bloc/shop_detail/shop_detail_cubit.dart';
import '../../models/trusted_shop_item.dart';
import '../../repositories/trusted_shop_repository.dart';
import 'shop_detail_mobile_view.dart';
import 'package:restore/modules/account/views/public_profile/public_profile_view.dart';
import 'package:restore/l10n/app_localizations.dart';

/// Route `/shops/:id`: hồ sơ, chứng nhận và các tin đang bán của một shop.
/// [shop] là thẻ shop vừa bấm (tuỳ chọn) để hiện ngay; thiếu thì trang tự
/// tải. Đóng trang trả về trạng thái theo dõi mới (bool) nếu đã đổi.
class ShopDetailView extends StatelessWidget {
  final String shopId;
  final TrustedShopItem? shop;

  final bool catalog;
  const ShopDetailView({
    super.key,
    required this.shopId,
    this.shop,
    this.catalog = false,
  });

  static const String path = '/shops/:id';

  /// Đường dẫn mở trang của shop [shopId]
  static String location(String shopId) => '/shops/$shopId';

  @override
  Widget build(BuildContext context) {
    if (!catalog && !AppEnvironment.useMockData) {
      final ownerId = shop?.shop.ownerId;
      if (ownerId != null && ownerId.isNotEmpty) {
        return PublicProfileView(userId: ownerId, returnShopFollow: true);
      }
      return _ShopOwnerLookup(key: ValueKey(shopId), id: shopId);
    }
    return BlocProvider(
      create: (_) => ShopDetailCubit(
        repository: AppEnvironment.useMockData
            ? MockTrustedShopRepository()
            : ApiTrustedShopRepository(),
        shopId: shopId,
        shop: shop,
      )..start(),
      child: const TResponsiveLayout(mobile: ShopDetailMobileView()),
    );
  }
}

class _ShopOwnerLookup extends StatefulWidget {
  const _ShopOwnerLookup({super.key, required this.id});
  final String id;
  @override
  State<_ShopOwnerLookup> createState() => _ShopOwnerLookupState();
}

class _ShopOwnerLookupState extends State<_ShopOwnerLookup> {
  late Future<TrustedShopItem> shop = ApiTrustedShopRepository().getShop(
    widget.id,
  );
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
                      onPressed: () => setState(() {
                        shop = ApiTrustedShopRepository().getShop(widget.id);
                      }),
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
