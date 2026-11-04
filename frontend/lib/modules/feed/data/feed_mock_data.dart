/// Dữ liệu mẫu cho màn hình viết bài, cùng dạng JSON với API.
class FeedMockData {
  FeedMockData._();

  static const String _img = 'assets/images';

  static Map<String, dynamic> composerOptions() => {
    'maxPhotos': 10,
    'maxBackgroundLength': 150,
    'backgrounds': [
      {
        'id': 'bg-sunset',
        'colors': ['#F7B733', '#FC4A1A'],
      },
      {
        'id': 'bg-honey',
        'colors': ['#FFE29F', '#FFA99F'],
        'lightText': false,
      },
      {
        'id': 'bg-mint',
        'colors': ['#43E97B', '#38F9D7'],
      },
      {
        'id': 'bg-ocean',
        'colors': ['#4FACFE', '#00C6FB'],
      },
      {
        'id': 'bg-grape',
        'colors': ['#A18CD1', '#FBC2EB'],
      },
      {
        'id': 'bg-night',
        'colors': ['#29323C', '#485563'],
      },
      {
        'id': 'bg-cream',
        'colors': ['#FFF6E4', '#FDEFE3'],
        'lightText': false,
      },
    ],
    'topics': [
      {
        'id': 'topic-ask',
        'name': {'vi': 'Hỏi đáp', 'en': 'Q&A'},
      },
      {
        'id': 'topic-show',
        'name': {'vi': 'Khoe đồ', 'en': 'Show off'},
      },
      {
        'id': 'topic-wanted',
        'name': {'vi': 'Cần mua', 'en': 'Looking to buy'},
      },
      {
        'id': 'topic-review',
        'name': {'vi': 'Đánh giá', 'en': 'Review'},
      },
      {
        'id': 'topic-tips',
        'name': {'vi': 'Kinh nghiệm mua bán', 'en': 'Buying & selling tips'},
      },
    ],
    'mentionable': [
      {'id': 'user-an', 'fullName': 'Nguyễn Minh An'},
      {'id': 'user-binh', 'fullName': 'Trần Thanh Bình'},
      {'id': 'user-chi', 'fullName': 'Lê Bảo Chi'},
      {'id': 'user-duc', 'fullName': 'Phạm Anh Đức'},
    ],
    'myListings': [
      {
        'id': 'listing-camera',
        'title': 'Máy ảnh film Canon AE-1',
        'price': 3200000,
        'imageUrl': '$_img/marketplace/listing-camera.png',
      },
      {
        'id': 'listing-lamp',
        'title': 'Đèn bàn gỗ phong cách Bắc Âu',
        'price': 450000,
        'imageUrl': '$_img/marketplace/listing-lamp.png',
      },
      {
        'id': 'listing-chair',
        'title': 'Ghế gỗ thông còn mới',
        'price': 690000,
        'imageUrl': '$_img/marketplace/listing-chair.png',
      },
    ],
  };

  /// Ảnh gần đây trong máy (dữ liệu mẫu)
  static const List<String> recentPhotos = [
    '$_img/marketplace/listing-camera.png',
    '$_img/banners/banner-kodo-week.jpg',
    '$_img/marketplace/listing-lamp.png',
    '$_img/banners/banner-super-sale.jpg',
    '$_img/marketplace/listing-chair.png',
    '$_img/banners/banner-mocan-sale.jpg',
    '$_img/banners/banner-black-friday.jpg',
  ];
}
