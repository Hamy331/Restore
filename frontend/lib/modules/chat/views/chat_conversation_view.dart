import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';

enum ChatOfferStage { conversation, sellerReview, buyerReview, agreed }

class ChatConversationView extends StatelessWidget {
  const ChatConversationView({
    this.stage = ChatOfferStage.conversation,
    super.key,
  });

  final ChatOfferStage stage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                _ConversationHeader(onBack: () => context.pop()),
                const _RelatedProduct(),
                Expanded(child: _ConversationBody(stage: stage)),
                _MessageComposer(onOffer: () => showMakeOfferSheet(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showMakeOfferSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * .82,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 9,
            bottom: 12 + MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Gửi đề nghị giá',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close, size: 22),
                  ),
                ],
              ),
              const _OfferProductSummary(size: 56),
              const Divider(height: 20),
              const Text(
                'Giá bạn đề nghị',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 7),
              const TextField(
                controller: null,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '2.200.000',
                  suffixText: 'đ',
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Lời nhắn (không bắt buộc)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 7),
              const TextField(
                minLines: 2,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Mình có thể xem máy tối nay không?',
                  fillColor: AppColors.background,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Đây chỉ là đề nghị giá. Giao nhận và thanh toán do hai bên tự thỏa thuận.',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    context.push('/messages/minh-anh/offer/seller-review');
                  },
                  child: const Text('Gửi đề nghị'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ConversationHeader extends StatelessWidget {
  const _ConversationHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 58,
    child: Row(
      children: [
        IconButton(
          tooltip: 'Quay lại',
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back, size: 23),
        ),
        const CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.infoBg,
          child: Text(
            'MA',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E3A8A),
            ),
          ),
        ),
        const SizedBox(width: 9),
        const Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Minh Anh',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              Text(
                'Hoạt động 10 phút trước',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Tùy chọn',
          onPressed: () {},
          icon: const Icon(Icons.more_vert, size: 23),
        ),
      ],
    ),
  );
}

class _RelatedProduct extends StatelessWidget {
  const _RelatedProduct();

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => context.push('/listings/camera'),
    child: Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border.symmetric(
          horizontal: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Image.asset(
              'assets/images/marketplace/listing-camera.png',
              width: 62,
              height: 62,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Máy ảnh film Canon AE-1 + lens 50mm',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 2),
                Text(
                  '2.450.000 đ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
                Text(
                  '●  Đang bán',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF32805A),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    ),
  );
}

class _ConversationBody extends StatelessWidget {
  const _ConversationBody({required this.stage});

  final ChatOfferStage stage;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      const Center(
        child: Text(
          'Hôm nay',
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ),
      const SizedBox(height: 10),
    ];

    if (stage == ChatOfferStage.conversation) {
      children.addAll(const [
        _MessageBubble(
          text:
              'Máy vẫn hoạt động tốt, đo sáng chuẩn. Bạn muốn xem trực tiếp không?',
          time: '09:41',
        ),
        _MessageBubble(
          text: 'Mình muốn xem máy ở Quận 1. Lens có trầy không ạ?',
          time: '09:43',
          mine: true,
        ),
        _MessageBubble(
          text: 'Lens sạch, mình gửi thêm ảnh nhé.',
          time: '09:44',
        ),
        _InlinePhoto(),
        _MessageBubble(
          text: 'Cảm ơn bạn! Mình muốn đề nghị giá.',
          time: '09:47',
          mine: true,
        ),
        _MessageBubble(
          text:
              'Mình có thể gặp ở Nguyễn Huệ tối nay. Nếu cần giao hàng, mình và bạn sẽ tự sắp xếp nhé.',
          time: '09:49',
        ),
        _MessageBubble(
          text:
              'Mình muốn xem trực tiếp. Nếu ưng máy, mình thanh toán cho bạn khi gặp.',
          time: '09:50',
          mine: true,
        ),
      ]);
    } else if (stage == ChatOfferStage.sellerReview) {
      children.addAll([
        const _MessageBubble(
          text: 'Mình muốn đề nghị giá cho máy ảnh này.',
          time: '09:47',
          mine: true,
        ),
        _OfferCard(
          label: 'ĐỀ NGHỊ GIÁ',
          proposedPrice: '2.200.000 đ',
          onAgree: () => context.push('/messages/minh-anh/offer/agreed'),
        ),
        const _CounterOfferEditor(),
      ]);
    } else if (stage == ChatOfferStage.buyerReview) {
      children.addAll([
        const _MessageBubble(
          text: 'Mình đề nghị 2.200.000 đ cho máy.',
          time: '09:47',
          mine: true,
        ),
        const _MessageBubble(
          text: 'Mình có thể để giá 2.300.000 đ nhé.',
          time: '09:52',
        ),
        _OfferCard(
          label: 'ĐỀ NGHỊ GIÁ KHÁC',
          proposedPrice: '2.300.000 đ',
          onAgree: () => context.push('/messages/minh-anh/offer/agreed'),
        ),
        const _InfoNote(
          text:
              'Người mua có thể đồng ý, từ chối hoặc đề nghị một mức giá khác.',
        ),
      ]);
    } else {
      children.addAll(const [
        _MessageBubble(
          text: 'Mình đồng ý mức 2.300.000 đ.',
          time: '09:54',
          mine: true,
        ),
        _AgreedPriceNotice(),
        _MessageBubble(
          text: 'Mình gặp nhau ở Nguyễn Huệ lúc 19:00 nhé.',
          time: '09:55',
        ),
        _MessageBubble(
          text: 'Được ạ, mình sẽ mang tiền và kiểm tra máy trực tiếp.',
          time: '09:56',
          mine: true,
        ),
      ]);
    }

    return ColoredBox(
      color: AppColors.background,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: children,
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.text,
    required this.time,
    this.mine = false,
  });

  final String text;
  final String time;
  final bool mine;

  @override
  Widget build(BuildContext context) => Align(
    alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      constraints: const BoxConstraints(maxWidth: 270),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(11, 8, 11, 7),
      decoration: BoxDecoration(
        color: mine ? AppColors.primarySoft : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            time,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    ),
  );
}

class _InlinePhoto extends StatelessWidget {
  const _InlinePhoto();

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Image.asset(
          'assets/images/marketplace/listing-camera.png',
          width: 100,
          height: 90,
          fit: BoxFit.cover,
        ),
      ),
    ),
  );
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.label,
    required this.proposedPrice,
    required this.onAgree,
  });

  final String label;
  final String proposedPrice;
  final VoidCallback onAgree;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 7),
        const _OfferProductSummary(size: 38, compact: true),
        const SizedBox(height: 7),
        const _PriceRow(label: 'Giá đăng', value: '2.450.000 đ'),
        _PriceRow(label: 'Giá đề nghị', value: proposedPrice, prominent: true),
        const SizedBox(height: 7),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 38,
                child: ElevatedButton(
                  onPressed: onAgree,
                  child: const Text('Đồng ý', style: TextStyle(fontSize: 11)),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _OfferAction(label: 'Từ chối', onTap: () {}),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _OfferAction(
                label: 'Đề nghị giá khác',
                fontSize: 10,
                onTap: () =>
                    context.push('/messages/minh-anh/offer/buyer-review'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _OfferAction extends StatelessWidget {
  const _OfferAction({
    required this.label,
    required this.onTap,
    this.fontSize = 11,
  });

  final String label;
  final VoidCallback onTap;
  final double fontSize;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 38,
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 1,
        style: TextStyle(fontSize: fontSize, color: AppColors.primaryDark),
      ),
    ),
  );
}

class _OfferProductSummary extends StatelessWidget {
  const _OfferProductSummary({required this.size, this.compact = false});

  final double size;
  final bool compact;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.asset(
          'assets/images/marketplace/listing-camera.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              compact ? 'Canon AE-1' : 'Máy ảnh film Canon AE-1 + lens 50mm',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            if (!compact) ...[
              const SizedBox(height: 4),
              const Text(
                'Giá đăng: 2.450.000 đ',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    ],
  );
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.prominent = false,
  });

  final String label;
  final String value;
  final bool prominent;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: prominent ? 27 : 20,
    child: Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: prominent ? FontWeight.w500 : FontWeight.w400,
            color: prominent ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: prominent ? 18 : 12,
            fontWeight: prominent ? FontWeight.w700 : FontWeight.w500,
            color: prominent ? AppColors.primaryDark : AppColors.textPrimary,
          ),
        ),
      ],
    ),
  );
}

class _CounterOfferEditor extends StatelessWidget {
  const _CounterOfferEditor();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(9),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Đề nghị giá khác',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 7),
        SizedBox(
          height: 39,
          child: TextField(
            decoration: InputDecoration(hintText: '2.300.000 đ'),
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Gửi giá khác  →',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    ),
  );
}

class _InfoNote extends StatelessWidget {
  const _InfoNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
    ),
  );
}

class _AgreedPriceNotice extends StatelessWidget {
  const _AgreedPriceNotice();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ĐÃ THỐNG NHẤT GIÁ',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
        SizedBox(height: 8),
        Text(
          '2.300.000 đ',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 8),
        Text(
          'Hãy tiếp tục trao đổi với người bán để thống nhất giao nhận và thanh toán.',
          style: TextStyle(fontSize: 12),
        ),
      ],
    ),
  );
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({required this.onOffer});

  final VoidCallback onOffer;

  @override
  Widget build(BuildContext context) => Container(
    height: 67,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
    decoration: const BoxDecoration(
      color: AppColors.surface,
      border: Border(top: BorderSide(color: AppColors.border)),
    ),
    child: Row(
      children: [
        IconButton(
          tooltip: 'Thêm ảnh',
          visualDensity: VisualDensity.compact,
          onPressed: () {},
          icon: const Icon(
            Icons.add_photo_alternate_outlined,
            color: AppColors.textSecondary,
          ),
        ),
        const Expanded(
          child: SizedBox(
            height: 43,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Nhắn tin...',
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(21)),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(21)),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: onOffer,
          style: TextButton.styleFrom(
            backgroundColor: AppColors.primarySoft,
            foregroundColor: AppColors.primaryDark,
            minimumSize: const Size(68, 36),
            padding: const EdgeInsets.symmetric(horizontal: 7),
          ),
          child: const Text(
            'Trả giá',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          tooltip: 'Gửi',
          visualDensity: VisualDensity.compact,
          onPressed: () {},
          icon: const Icon(
            Icons.send_outlined,
            size: 22,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    ),
  );
}
