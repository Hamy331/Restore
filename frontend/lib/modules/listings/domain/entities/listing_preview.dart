import 'package:intl/intl.dart';
import '../../../../core/config/app_environment.dart';

class ListingPreview {
  const ListingPreview({
    required this.id,
    required this.title,
    required this.price,
    required this.location,
    this.imageAsset = '',
    this.imageUrl,
    this.images = const [],
    this.condition = 'Đã qua sử dụng',
    this.description = '',
    this.sellerName = '',
    this.sellerId = '',
    this.imageCount = 1,
    this.isNegotiable = false,
    this.categoryId = '',
    this.categoryName = '',
    this.status = 'AVAILABLE',
    this.rawPrice = '',
    this.conditionCode = 'USED_GOOD',
  });

  final String id;
  final String title;
  final String price;
  final String location;
  final String imageAsset;
  final String? imageUrl;
  final List<String> images;
  final String condition;
  final String description;
  final String sellerName;
  final String sellerId;
  final int imageCount;
  final bool isNegotiable;
  final String categoryId;
  final String categoryName;
  final String status;
  final String rawPrice;
  final String conditionCode;

  static String resolveImage(String url) => url.startsWith('/')
      ? '${Uri.parse(AppEnvironment.apiBaseUrl).origin}$url'
      : url;

  factory ListingPreview.fromJson(Map<String, dynamic> json) {
    final images = (json['images'] as List).whereType<String>().toList();
    final owner = json['owner'] as Map<String, dynamic>;
    final category = json['category'] as Map<String, dynamic>?;
    final amount = num.parse(json['price'] as String);
    final createdAt = DateTime.parse(json['createdAt'] as String).toLocal();
    final status = json['status'] as String? ?? 'AVAILABLE';
    final publishedAt = json['publishedAt'] == null
        ? createdAt
        : DateTime.parse(json['publishedAt'] as String).toLocal();
    final isUnpricedDraft = status == 'DRAFT' && amount == 0;
    return ListingPreview(
      id: json['id'] as String,
      title: json['title'] as String,
      price: isUnpricedDraft
          ? 'Chưa có giá'
          : '${NumberFormat.decimalPattern('vi').format(amount)} đ',
      location: status == 'DRAFT'
          ? 'Lưu nháp ${DateFormat('dd/MM/yyyy').format(createdAt)}'
          : 'Đăng ${DateFormat('dd/MM/yyyy').format(publishedAt)}',
      imageUrl: images.isEmpty ? null : resolveImage(images.first),
      images: images.map(resolveImage).toList(),
      imageCount: images.length,
      isNegotiable: json['isNegotiable'] == true,
      categoryId: category?['id'] as String? ?? '',
      categoryName: category?['name'] as String? ?? '',
      status: status,
      rawPrice: isUnpricedDraft ? '' : json['price'] as String,
      conditionCode: json['condition'] as String,
      condition: switch (json['condition'] as String) {
        'NEW' => 'Mới',
        'LIKE_NEW' => 'Như mới',
        'USED_GOOD' => 'Đã sử dụng, còn tốt',
        'USED_FAIR' => 'Đã sử dụng',
        'FOR_PARTS' => 'Dùng lấy linh kiện',
        _ => 'Chưa rõ',
      },
      description: json['description'] as String,
      sellerName: owner['fullName'] as String,
      sellerId: owner['id'] as String,
    );
  }
}
