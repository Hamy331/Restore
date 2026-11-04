import 'package:equatable/equatable.dart';

/// Tin đăng của chính mình được gắn vào bài viết, hiện thành thẻ nhỏ có
/// ảnh, tên và giá để người xem bấm sang trang chi tiết.
class PostListingRef extends Equatable {
  final String id;
  final String title;
  final double? price;
  final String? imageUrl;

  const PostListingRef({
    required this.id,
    required this.title,
    this.price,
    this.imageUrl,
  });

  factory PostListingRef.fromJson(Map<String, dynamic> json) => PostListingRef(
    id: '${json['id']}',
    title: '${json['title']}',
    price: (json['price'] as num?)?.toDouble(),
    imageUrl: json['imageUrl'] as String?,
  );

  @override
  List<Object?> get props => [id, title, price, imageUrl];
}
