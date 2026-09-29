class ListingPreview {
  const ListingPreview({
    required this.id,
    required this.title,
    required this.price,
    required this.location,
    required this.imageAsset,
    this.condition = 'Đã qua sử dụng',
  });

  final String id;
  final String title;
  final String price;
  final String location;
  final String imageAsset;
  final String condition;
}
