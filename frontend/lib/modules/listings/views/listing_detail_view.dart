import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';

const _ink = Color(0xFF1F1A14);
const _muted = Color(0xFF857663);
const _line = Color(0xFFEBE3D6);
const _paper = Color(0xFFFFFDF9);
const _gold = Color(0xFFB36B00);
const _cream = Color(0xFFFDF1DC);

class _Listing {
  const _Listing(
    this.id,
    this.title,
    this.price,
    this.image,
    this.category,
    this.place,
    this.time,
    this.description,
  );

  final String id;
  final String title;
  final String price;
  final String image;
  final String category;
  final String place;
  final String time;
  final String description;
}

const _listings = <_Listing>[
  _Listing(
    '101',
    'Máy ảnh Fujifilm X-T20 kèm kit',
    '7.900.000 đ',
    'detail-fujifilm.jpg',
    'Điện tử',
    'Quận 1',
    '2 ngày trước',
    'Hàng cá nhân dùng giữ gìn, đầy đủ phụ kiện. Xem hàng tại Quận 1.',
  ),
  _Listing(
    '102',
    'Tai nghe Sony WH-1000XM4',
    '3.200.000 đ',
    'detail-headphones.jpg',
    'Điện tử',
    'Quận 1',
    '4 ngày trước',
    'Tai nghe dùng giữ gìn, âm thanh và chống ồn hoạt động tốt.',
  ),
  _Listing(
    '103',
    'Kệ sách gỗ thông 4 tầng',
    '650.000 đ',
    'detail-bookshelf.jpg',
    'Nội thất',
    'Quận 1',
    '1 tuần trước',
    'Kệ sách gỗ thông chắc chắn, còn tốt.',
  ),
  _Listing(
    '1',
    'Máy ảnh film Canon AE-1 + lens 50mm',
    '2.450.000 đ',
    'detail-canon.jpg',
    'Điện tử',
    'Quận 1',
    '2 giờ trước',
    'Canon AE-1 hoạt động tốt, kèm lens FD 50mm.',
  ),
  _Listing(
    '4',
    'MacBook Pro 13” 2020',
    '14.500.000 đ',
    'detail-macbook.jpg',
    'Điện tử',
    'Quận 3',
    'Hôm qua',
    'Máy còn tốt, đầy đủ sạc.',
  ),
  _Listing(
    '2',
    'Đèn bàn đồng vintage',
    '590.000 đ',
    'detail-lamp.jpg',
    'Nội thất',
    'Bình Thạnh',
    '5 giờ trước',
    'Đèn bàn chân đồng, chụp kim loại.',
  ),
];

String _image(_Listing item) => 'assets/images/marketplace/${item.image}';

class ListingDetailView extends StatefulWidget {
  const ListingDetailView({required this.listingId, super.key});

  final String listingId;

  @override
  State<ListingDetailView> createState() => _ListingDetailViewState();
}

class _ListingDetailViewState extends State<ListingDetailView> {
  final _scrollController = ScrollController();
  bool _saved = false;
  bool _expanded = false;
  bool _showAppBarTitle = false;
  int _photoIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final visible = _scrollController.offset > 330;
      if (visible != _showAppBarTitle) {
        setState(() => _showAppBarTitle = visible);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matches = _listings.where((item) => item.id == widget.listingId);
    if (matches.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Không tìm thấy tin đăng.')),
      );
    }
    final listing = matches.first;
    final photos = [
      listing,
      ..._listings.where((item) => item.id != listing.id).take(4),
    ];
    final others = _listings
        .where(
          (item) => item.id != listing.id && item.category == listing.category,
        )
        .followedBy(
          _listings.where(
            (item) =>
                item.id != listing.id && item.category != listing.category,
          ),
        )
        .take(5)
        .toList();
    final similar = _listings
        .where((item) => item.id != listing.id)
        .take(4)
        .toList();

    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        textTheme: theme.textTheme.apply(fontFamily: 'DM Sans'),
      ),
      child: Scaffold(
        backgroundColor: _paper,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  Container(
                    height: 56,
                    decoration: const BoxDecoration(
                      color: _paper,
                      border: Border(bottom: BorderSide(color: _line)),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Quay lại',
                          onPressed: () => context.canPop()
                              ? context.pop()
                              : context.go('/home'),
                          icon: const Icon(Icons.arrow_back, size: 21),
                        ),
                        Expanded(
                          child: Text(
                            _showAppBarTitle ? listing.title : '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Chia sẻ',
                          onPressed: () => _notice('Chia sẻ tin đăng'),
                          icon: const Icon(Icons.share_outlined, size: 20),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(bottom: 112),
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                _image(photos[_photoIndex]),
                                fit: BoxFit.cover,
                              ),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => setState(
                                    () => _photoIndex =
                                        (_photoIndex + 1) % photos.length,
                                  ),
                                  child: const SizedBox.expand(),
                                ),
                              ),
                              Positioned(
                                right: 12,
                                bottom: 12,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: .6),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    child: Text(
                                      '${_photoIndex + 1}/${photos.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      listing.title,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        height: 1.35,
                                        letterSpacing: -.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        setState(() => _saved = !_saved),
                                    icon: Icon(
                                      _saved
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      size: 17,
                                      color: _saved
                                          ? const Color(0xFFD9480F)
                                          : _ink,
                                    ),
                                    label: Text(_saved ? 'Đã lưu' : 'Lưu'),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(0, 36),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 11,
                                      ),
                                      foregroundColor: _ink,
                                      side: const BorderSide(color: _line),
                                      textStyle: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${listing.category} · Đã qua sử dụng · Còn tốt',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: _muted,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                listing.price,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: _gold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _iconLine(
                                Icons.location_on_outlined,
                                '${listing.place}, TP. Hồ Chí Minh',
                              ),
                              const SizedBox(height: 12),
                              _iconLine(
                                Icons.access_time,
                                'Đăng ${listing.time}',
                              ),
                              const SizedBox(height: 16),
                              const Divider(color: _line, height: 1),
                              const SizedBox(height: 16),
                              InkWell(
                                onTap: () => _notice(
                                  'Trang người bán đang được phát triển',
                                ),
                                child: const Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: _cream,
                                      child: Text(
                                        'NHH',
                                        style: TextStyle(
                                          color: _gold,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Nguyễn Hoàng Huy',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            'Phản hồi: 94% · 48 đánh giá',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: _muted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.star,
                                      color: AppColors.primary,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      '4.9',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              _detailCard(listing),
                              const SizedBox(height: 12),
                              _specCard(listing),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Tin rao khác của Nguyễn Hoàng Huy',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 255,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: others.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 12),
                            itemBuilder: (_, index) =>
                                _sellerCard(others[index], index),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          child: OutlinedButton(
                            onPressed: () =>
                                _notice('Trang người bán đang được phát triển'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(44),
                              side: const BorderSide(color: _line),
                              foregroundColor: _ink,
                            ),
                            child: const Text(
                              'Xem tin từ người bán',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: _cream, width: 8),
                            ),
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Tin đăng tương tự',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => _notice(
                                      'Danh sách tin tương tự đang được phát triển',
                                    ),
                                    child: const Text(
                                      'Xem thêm ›',
                                      style: TextStyle(
                                        color: _gold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: similar.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      mainAxisExtent: 278,
                                    ),
                                itemBuilder: (_, index) =>
                                    _similarCard(similar[index]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconLine(IconData icon, String text) => Row(
    children: [
      Icon(icon, color: _muted, size: 20),
      const SizedBox(width: 12),
      Text(text, style: const TextStyle(fontSize: 14, color: _ink)),
    ],
  );

  Widget _detailCard(_Listing listing) => _CardBox(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mô tả chi tiết',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          '${listing.description}\n- Cam kết đúng tình trạng như mô tả.\n- Xem hàng trực tiếp tại ${listing.place}.\n- Hỗ trợ kiểm tra kỹ trước khi nhận.',
          maxLines: _expanded ? null : 4,
          overflow: _expanded ? null : TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            height: 1.6,
            color: Color(0xFF5A4A36),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _cream,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Wrap(
            spacing: 12,
            children: [
              const Text(
                'SĐT liên hệ: 097998****',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              InkWell(
                onTap: () =>
                    _notice('Số điện thoại đang được ẩn trong bản mẫu'),
                child: const Text(
                  'Gọi ngay',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
        ),
        Center(
          child: TextButton.icon(
            onPressed: () => setState(() => _expanded = !_expanded),
            label: Text(_expanded ? 'Thu gọn' : 'Xem thêm'),
            icon: Icon(
              _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 17,
            ),
            style: TextButton.styleFrom(
              foregroundColor: _muted,
              textStyle: const TextStyle(fontSize: 13),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _specCard(_Listing listing) => _CardBox(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thông tin chi tiết',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        _specRow('Danh mục', listing.category),
        _specRow('Tình trạng', 'Đã qua sử dụng · Còn tốt'),
        _specRow('Chính sách bảo hành', 'Hết bảo hành'),
        _specRow('Xuất xứ', 'Việt Nam', last: true),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _cream.withValues(alpha: .7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Bạn có sản phẩm tương tự?',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              FilledButton(
                onPressed: () =>
                    context.push('/create-listing/choose-category'),
                style: FilledButton.styleFrom(
                  backgroundColor: _ink,
                  foregroundColor: _paper,
                  minimumSize: const Size(0, 36),
                ),
                child: const Text(
                  'Đăng bán',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _specRow(String label, String value, {bool last = false}) => Container(
    padding: const EdgeInsets.symmetric(vertical: 13),
    decoration: BoxDecoration(
      border: last ? null : const Border(bottom: BorderSide(color: _line)),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 148,
          child: Text(
            label,
            style: const TextStyle(color: _muted, fontSize: 14),
          ),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 14, color: _ink)),
        ),
      ],
    ),
  );

  Widget _sellerCard(_Listing item, int index) => SizedBox(
    width: 148,
    child: InkWell(
      onTap: () => _open(item),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Image.asset(_image(item), fit: BoxFit.cover),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(7, 16, 7, 6),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0x99000000)],
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.time,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Text(
                          '${4 + index % 3} ▧',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Positioned(
                  right: 8,
                  top: 8,
                  child: Icon(
                    Icons.favorite_border,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, height: 1.2),
          ),
          const SizedBox(height: 3),
          Text(
            item.price,
            style: const TextStyle(
              fontSize: 14,
              color: _gold,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '♧ ${item.place}',
            style: const TextStyle(fontSize: 11, color: _muted),
          ),
        ],
      ),
    ),
  );

  Widget _similarCard(_Listing item) => InkWell(
    onTap: () => _open(item),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(_image(item), fit: BoxFit.cover),
                const Positioned(
                  right: 8,
                  top: 8,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.favorite_border, color: _ink, size: 20),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 34,
                  child: Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, height: 1.25),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.price,
                  style: const TextStyle(
                    fontSize: 16,
                    color: _gold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.place} · ${item.time}',
                  style: const TextStyle(fontSize: 11, color: _muted),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  void _open(_Listing item) {
    context.push('/listings/${item.id}');
  }

  void _notice(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _CardBox extends StatelessWidget {
  const _CardBox({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _line),
    ),
    child: child,
  );
}
