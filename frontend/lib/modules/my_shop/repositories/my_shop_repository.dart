import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/network/api_client.dart';
import 'package:restore/data/models/shop_model.dart';
import 'package:restore/services/image_upload_service.dart';

import '../models/my_shop_overview.dart';

/// Lỗi nghiệp vụ backend trả về (SHOP_NAME_LOCKED, SHOP_PLAN_REQUIRED...)
class MyShopException implements Exception {
  const MyShopException(this.code);

  final String code;

  @override
  String toString() => 'MyShopException($code)';
}

/// Trang Quản lý shop: `/shops/me`
abstract class MyShopRepository {
  factory MyShopRepository() => AppEnvironment.useMockData
      ? MockMyShopRepository()
      : ApiMyShopRepository();

  Future<MyShopOverview> load();

  /// Mở shop: name bắt buộc, các trường khác tuỳ chọn
  Future<MyShopOverview> create({
    required String name,
    String? tagline,
    String? address,
  });

  /// Chỉ gửi trường đổi; giá trị null = xoá (logo, ảnh bìa, địa chỉ...)
  Future<MyShopOverview> update(Map<String, dynamic> changes);

  /// Tải logo / ảnh bìa đã cắt lên, trả về đường dẫn để lưu vào shop
  Future<String> uploadImage(Uint8List bytes);
}

class ApiMyShopRepository implements MyShopRepository {
  ApiMyShopRepository({ApiClient? apiClient, ImageUploadService? uploader})
    : _apiClient = apiClient ?? ApiClient(),
      _uploader = uploader;

  final ApiClient _apiClient;
  final ImageUploadService? _uploader;

  Dio get _dio => _apiClient.dio;

  Future<MyShopOverview> _overview(
    Future<Response<Map<String, dynamic>>> Function() request,
  ) => _guard(() async {
    final data = (await request()).data?['data'];
    if (data is! Map) throw const FormatException('Missing shop data');
    return MyShopOverview.fromJson(Map<String, dynamic>.from(data));
  });

  Future<T> _guard<T>(Future<T> Function() work) async {
    try {
      return await work();
    } on DioException catch (error) {
      final body = error.response?.data;
      if (body is Map && body['code'] is String) {
        throw MyShopException(body['code'] as String);
      }
      rethrow;
    }
  }

  @override
  Future<MyShopOverview> load() =>
      _overview(() => _dio.get<Map<String, dynamic>>('/shops/me'));

  @override
  Future<MyShopOverview> create({
    required String name,
    String? tagline,
    String? address,
  }) => _overview(
    () => _dio.post<Map<String, dynamic>>(
      '/shops/me',
      data: {
        'name': name,
        if (tagline != null && tagline.isNotEmpty) 'tagline': tagline,
        if (address != null && address.isNotEmpty) 'address': address,
      },
    ),
  );

  @override
  Future<MyShopOverview> update(Map<String, dynamic> changes) => _overview(
    () => _dio.patch<Map<String, dynamic>>('/shops/me', data: changes),
  );

  @override
  Future<String> uploadImage(Uint8List bytes) => _guard(
    () => (_uploader ?? ImageUploadService(dio: _dio)).uploadBytes(
      bytes,
      purpose: ImagePurpose.shop,
    ),
  );
}

/// Dữ liệu trong bộ nhớ: tài khoản gói Cửa hàng đã có shop chưa xác minh
class MockMyShopRepository implements MyShopRepository {
  MockMyShopRepository({
    MyShopOverview? initial,
    this.latency = const Duration(milliseconds: 300),
  }) : _overview =
           initial ??
           const MyShopOverview(
             storePlan: true,
             shop: ShopModel(
               id: 'shop-mock',
               ownerId: 'me',
               name: 'Góc Nhà Decor',
               tagline: 'Đồ trang trí, đèn ngủ thủ công',
               description:
                   'Chuyên đồ decor handmade, đèn ngủ và kệ gỗ nhỏ. '
                   'Nhận đặt theo yêu cầu.',
               accentColor: '#C2410C',
               address: 'Quận 3, TP. Hồ Chí Minh',
             ),
             stats: MyShopStats(
               followerCount: 128,
               listingCount: 24,
               runningPosters: 1,
               pendingPosters: 1,
             ),
           );

  final Duration latency;
  MyShopOverview _overview;
  int _uploads = 0;

  Future<void> _wait() => Future<void>.delayed(latency);

  @override
  Future<MyShopOverview> load() async {
    await _wait();
    return _overview;
  }

  @override
  Future<MyShopOverview> create({
    required String name,
    String? tagline,
    String? address,
  }) async {
    await _wait();
    if (!_overview.storePlan) throw const MyShopException('SHOP_PLAN_REQUIRED');
    if (_overview.shop != null) throw const MyShopException('SHOP_EXISTS');
    return _overview = MyShopOverview(
      storePlan: true,
      shop: ShopModel(
        id: 'shop-mock',
        ownerId: 'me',
        name: name,
        tagline: tagline ?? '',
        address: address == null || address.isEmpty ? null : address,
      ),
      stats: const MyShopStats(),
    );
  }

  @override
  Future<MyShopOverview> update(Map<String, dynamic> changes) async {
    await _wait();
    final shop = _overview.shop;
    if (shop == null) throw const MyShopException('SHOP_REQUIRED');
    if (_overview.nameLocked &&
        changes.containsKey('name') &&
        changes['name'] != shop.name) {
      throw const MyShopException('SHOP_NAME_LOCKED');
    }
    String? pick(String key, String? old) =>
        changes.containsKey(key) ? changes[key] as String? : old;
    return _overview = MyShopOverview(
      storePlan: _overview.storePlan,
      planEndsAt: _overview.planEndsAt,
      nameLocked: _overview.nameLocked,
      stats: _overview.stats,
      shop: ShopModel(
        id: shop.id,
        ownerId: shop.ownerId,
        name: pick('name', shop.name) ?? shop.name,
        tagline: pick('tagline', shop.tagline) ?? '',
        description: pick('description', shop.description) ?? '',
        address: pick('address', shop.address),
        logoUrl: pick('logoUrl', shop.logoUrl),
        coverUrl: pick('coverUrl', shop.coverUrl),
        accentColor: pick('accentColor', shop.accentColor),
        verificationType: shop.verificationType,
        verifiedAt: shop.verifiedAt,
        certificateCode: shop.certificateCode,
      ),
    );
  }

  @override
  Future<String> uploadImage(Uint8List bytes) async {
    await _wait();
    // chế độ mock không có server: dùng ảnh có sẵn trong app
    _uploads++;
    return _uploads.isOdd
        ? 'assets/images/shops/ikea.png'
        : 'assets/images/banners/banner-kodo-week.jpg';
  }
}
