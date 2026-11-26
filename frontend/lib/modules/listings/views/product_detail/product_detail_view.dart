import 'package:flutter/material.dart';
import 'package:restore/core/network/api_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/ui/layouts/t_responsive_layout.dart';
import 'package:restore/data/models/listing_model.dart';

import '../../bloc/product_detail/product_detail_cubit.dart';
import '../../repositories/product_detail_repository.dart';
import 'product_detail_mobile_view.dart';
import 'product_detail_desktop_view.dart';
import 'package:restore/core/routes/slug.dart';

/// Route `/listings/:id`. [preview] là tin từ thẻ vừa bấm (truyền qua
/// `extra`) để hiện ngay ảnh bìa trong lúc tải chi tiết.
class ProductDetailView extends StatelessWidget {
  final String listingId;
  final ListingModel? preview;

  const ProductDetailView({super.key, required this.listingId, this.preview});

  static const String path = '/listings/:id';

  /// Đường dẫn mở tin [id]; có [title] thì URL kèm tên dễ đọc
  static String location(String id, {String? title, int? shortId}) =>
      slugPath('/listings', shortId?.toString() ?? id, title);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductDetailCubit(
        listingId: listingId,
        preview: preview,
        repository: ApiProductDetailRepository(),
      )..load(),
      child: const TResponsiveLayout(
        mobile: ProductDetailMobileView(),
        desktop: ProductDetailDesktopView(),
      ),
    );
  }
}

/// Route `/listings/:id`: `:id` là `<tên>-<mã số ngắn>` (hoặc UUID kiểu cũ).
/// Có [preview] hoặc UUID thì mở thẳng; chỉ có mã số ngắn thì hỏi server đổi
/// sang mã tin (khi mở link trực tiếp / tải lại trang).
class ListingRouteView extends StatefulWidget {
  const ListingRouteView({super.key, required this.param, this.preview});

  final String param;
  final ListingModel? preview;

  @override
  State<ListingRouteView> createState() => _ListingRouteViewState();
}

class _ListingRouteViewState extends State<ListingRouteView> {
  Future<String>? _lookup;

  Future<String> _resolve(int shortId) async {
    final response = await ApiClient().dio.get<Map<String, dynamic>>(
      '/listings/short/$shortId',
    );
    return '${(response.data?['data'] as Map)['id']}';
  }

  @override
  Widget build(BuildContext context) {
    final preview = widget.preview;
    if (preview != null) {
      return ProductDetailView(listingId: preview.id, preview: preview);
    }
    if (hasUuid(widget.param)) {
      return ProductDetailView(listingId: idFromSlug(widget.param));
    }
    final shortId = shortIdFromSlug(widget.param);
    if (shortId == null) return ProductDetailView(listingId: widget.param);
    return FutureBuilder<String>(
      future: _lookup ??= _resolve(shortId),
      builder: (context, snapshot) {
        final id = snapshot.data;
        if (id != null) return ProductDetailView(listingId: id);
        return Scaffold(
          appBar: AppBar(),
          body: Center(
            child: snapshot.hasError
                ? TextButton(
                    onPressed: () => setState(() => _lookup = null),
                    child: const Text('Retry'),
                  )
                : const CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
