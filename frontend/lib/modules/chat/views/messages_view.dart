import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/ui/responsive/responsive_content.dart';

class MessagesView extends StatefulWidget {
  const MessagesView({super.key});

  @override
  State<MessagesView> createState() => _MessagesViewState();
}

class _MessagesViewState extends State<MessagesView> {
  String _tab = 'Tất cả';

  static const _conversations = <_ConversationPreview>[
    _ConversationPreview(
      initials: 'MA',
      name: 'Minh Anh',
      product: 'Canon AE-1 + lens 50mm',
      message: 'Lens sạch, mình gửi thêm ảnh nhé.',
      time: '09:44',
      image: 'assets/images/marketplace/listing-camera.png',
      unread: 2,
      buying: true,
    ),
    _ConversationPreview(
      initials: 'TT',
      name: 'Thanh Tùng',
      product: 'Đèn bàn đồng vintage',
      message: 'Bạn có thể nhận ở Bình Thạnh.',
      time: 'Hôm qua',
      image: 'assets/images/marketplace/listing-lamp.png',
      unread: 1,
      buying: true,
    ),
    _ConversationPreview(
      initials: 'LP',
      name: 'Lan Phương',
      product: 'Ghế gỗ sồi Bắc Âu',
      message: 'Ghế vẫn còn nha bạn.',
      time: 'T2',
      image: 'assets/images/marketplace/listing-chair.png',
      buying: false,
    ),
    _ConversationPreview(
      initials: 'HY',
      name: 'Hải Yến',
      product: 'Máy ảnh Nikon FM2',
      message: 'Cảm ơn bạn, để mình kiểm tra.',
      time: 'T2',
      image: 'assets/images/marketplace/listing-camera.png',
      buying: false,
    ),
    _ConversationPreview(
      initials: 'GB',
      name: 'Gia Bảo',
      product: 'Đèn đọc sách để bàn',
      message: 'Mình gửi bạn thêm hình sản phẩm.',
      time: 'CN',
      image: 'assets/images/marketplace/listing-lamp.png',
      buying: true,
    ),
    _ConversationPreview(
      initials: 'QH',
      name: 'Quốc Hưng',
      product: 'Đèn ngủ để bàn gỗ',
      message: 'Mình có thể giao gần nhà bạn.',
      time: 'T7',
      image: 'assets/images/marketplace/listing-lamp.png',
      buying: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final visible = _conversations.where((item) {
      if (_tab == 'Đang mua') return item.buying;
      if (_tab == 'Đang bán') return !item.buying;
      return true;
    }).toList();

    return SafeArea(
      child: ResponsiveContent(
        maxWidth: 760,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                children: [
                  const Text(
                    'Tin nhắn',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Tìm cuộc trò chuyện',
                    onPressed: () {},
                    icon: const Icon(Icons.search, size: 23),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 42,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                scrollDirection: Axis.horizontal,
                children: ['Tất cả', 'Đang mua', 'Đang bán']
                    .map(
                      (tab) => TextButton(
                        onPressed: () => setState(() => _tab = tab),
                        style: TextButton.styleFrom(
                          foregroundColor: _tab == tab
                              ? AppColors.primaryDark
                              : AppColors.textSecondary,
                        ),
                        child: Text(
                          tab,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: _tab == tab
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: visible.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, index) => _ConversationTile(
                  item: visible[index],
                  onTap: () => context.push('/messages/minh-anh'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.item, required this.onTap});

  final _ConversationPreview item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: SizedBox(
      height: 102,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 9),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.infoBg,
              child: Text(
                item.initials,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        item.time,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.product,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 9),
            SizedBox(
              width: 48,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.asset(
                      item.image,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 5),
                  if (item.unread > 0)
                    Container(
                      width: 17,
                      height: 17,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${item.unread}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ConversationPreview {
  const _ConversationPreview({
    required this.initials,
    required this.name,
    required this.product,
    required this.message,
    required this.time,
    required this.image,
    required this.buying,
    this.unread = 0,
  });

  final String initials;
  final String name;
  final String product;
  final String message;
  final String time;
  final String image;
  final bool buying;
  final int unread;
}
