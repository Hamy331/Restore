import 'package:flutter/widgets.dart';
import 'package:restore/core/constants/app_icons.dart';

/// Một câu chữ hai ngôn ngữ
class PolicyText {
  const PolicyText(this.vi, this.en);
  final String vi;
  final String en;

  String of(bool vi) => vi ? this.vi : en;
}

typedef _T = PolicyText;

sealed class PolicyBlock {
  const PolicyBlock();
}

class PolicyParagraph extends PolicyBlock {
  const PolicyParagraph(this.text);
  final PolicyText text;
}

class PolicySubheading extends PolicyBlock {
  const PolicySubheading(this.text);
  final PolicyText text;
}

class PolicyBullets extends PolicyBlock {
  const PolicyBullets(this.items);
  final List<PolicyText> items;
}

class PolicyTable extends PolicyBlock {
  const PolicyTable(this.header, this.rows);
  final (PolicyText, PolicyText) header;
  final List<(PolicyText, PolicyText)> rows;
}

/// Các bước nối tiếp nhau (luồng mua bán, ví dụ đánh giá)
class PolicySteps extends PolicyBlock {
  const PolicySteps(this.steps);
  final List<(PolicyText, PolicyText)> steps;
}

class PolicyNote extends PolicyBlock {
  const PolicyNote(this.text, {this.warning = false});
  final PolicyText text;
  final bool warning;
}

class PolicySection {
  const PolicySection({
    required this.id,
    required this.icon,
    required this.title,
    required this.blocks,
  });

  /// Dùng cho `/policies?section=<id>`
  final String id;
  final IconData icon;
  final PolicyText title;
  final List<PolicyBlock> blocks;
}

const policyEffectiveDate = _T('28/11/2026', '28 Nov 2026');

const policySections = <PolicySection>[
  PolicySection(
    id: 'overview',
    icon: AppIcons.info,
    title: _T('Restore hoạt động thế nào', 'How Restore works'),
    blocks: [
      PolicyParagraph(
        _T(
          'Restore kết nối người mua và người bán đồ cũ. Hai bên tự thỏa thuận gặp mặt, giao hàng và thanh toán. Restore không phải bên bán, không giữ tiền hộ và không bảo đảm chất lượng hàng hóa trong giao dịch giữa các thành viên.',
          'Restore connects people buying and selling pre-loved items. Both sides arrange the meet-up, delivery and payment themselves. Restore is not the seller, does not hold money on anyone\'s behalf and does not guarantee the goods traded between members.',
        ),
      ),
      PolicySteps([
        (
          _T('Xem tin và nhắn tin', 'Browse and chat'),
          _T(
            'Hỏi thêm về sản phẩm trong chat của tin đăng.',
            'Ask about the item in the listing\'s chat.',
          ),
        ),
        (
          _T('Gửi đề nghị giá', 'Make an offer'),
          _T(
            'Người mua đề nghị một mức giá, có thể bằng giá niêm yết.',
            'The buyer offers a price, which can be the listed price.',
          ),
        ),
        (
          _T('Người bán chấp nhận', 'Seller accepts'),
          _T(
            'Restore ghi nhận thỏa thuận và mở quyền đánh giá cho cả hai.',
            'Restore records the agreement and opens reviews for both sides.',
          ),
        ),
        (
          _T('Hai bên tự giao dịch', 'Meet and trade'),
          _T(
            'Gặp mặt, giao hàng và thanh toán theo thỏa thuận riêng.',
            'Meet, hand over and pay as you agreed.',
          ),
        ),
        (
          _T('Đánh giá nhau', 'Review each other'),
          _T(
            'Đánh giá được giữ kín cho đến khi cả hai gửi hoặc đủ 7 ngày.',
            'Reviews stay hidden until both are in or 7 days have passed.',
          ),
        ),
      ]),
      PolicyNote(
        _T(
          'Chấp nhận đề nghị là ghi nhận thỏa thuận về giá để mở quyền đánh giá. Đây không phải hợp đồng mua bán và không xác nhận hàng đã được giao.',
          'Accepting an offer records a price agreement so both sides can review each other. It is not a sales contract and does not confirm the item was handed over.',
        ),
      ),
    ],
  ),
  PolicySection(
    id: 'listings',
    icon: AppIcons.listings,
    title: _T('Đăng tin và quản lý tin', 'Listing and managing items'),
    blocks: [
      PolicyBullets([
        _T(
          'Mỗi tin đăng một sản phẩm hoặc một bộ bán chung. Dùng ảnh thật và mô tả đúng tình trạng.',
          'One item, or one bundle sold together, per listing. Use real photos and describe the actual condition.',
        ),
        _T(
          'Giá niêm yết là giá bán thật. Không đăng giá ảo (0đ, 1đ) để câu lượt xem.',
          'The listed price is the real asking price. No placeholder prices (0 or 1 VND) to attract views.',
        ),
        _T(
          'Không đăng trùng cùng một sản phẩm ở nhiều tin.',
          'Do not post the same item in several listings.',
        ),
        _T(
          'Không đăng hàng cấm, hàng giả, hàng nhái, hàng không rõ nguồn gốc hoặc hàng cần giấy phép mà bạn không có.',
          'No prohibited, counterfeit or untraceable goods, and nothing that needs a licence you do not hold.',
        ),
        _T(
          'Tin hiển thị theo thời hạn đăng. Khi tin hết hạn hoặc bị ẩn, các đề nghị đang chờ của tin tự hết hiệu lực.',
          'Listings run for their display period. When a listing expires or is hidden, its pending offers expire.',
        ),
        _T(
          'Chấp nhận một đề nghị không đóng tin. Nếu còn hàng, bạn tiếp tục nhận đề nghị từ người khác.',
          'Accepting an offer does not close the listing. If you still have stock, you can keep taking offers.',
        ),
        _T(
          'Khi hết hàng hoặc đã bán ngoài Restore, hãy chủ động đánh dấu Đã bán.',
          'When you run out, or sold the item outside Restore, mark the listing as Sold.',
        ),
        _T(
          'Quy định áp dụng như nhau cho tài khoản cá nhân và cửa hàng.',
          'These rules apply equally to personal accounts and shops.',
        ),
      ]),
    ],
  ),
  PolicySection(
    id: 'offers',
    icon: AppIcons.offer,
    title: _T('Trả giá', 'Making offers'),
    blocks: [
      PolicySubheading(_T('Người mua', 'Buyers')),
      PolicyBullets([
        _T(
          'Gửi đề nghị từ trang chi tiết sản phẩm hoặc trong chat. Đề nghị hiện trong chat dưới dạng thẻ sản phẩm kèm mức giá.',
          'Make an offer from the item page or in chat. It shows in the chat as an item card with your price.',
        ),
        _T(
          'Mỗi tin chỉ có một đề nghị đang chờ của bạn. Muốn đổi giá, hãy thu hồi rồi gửi đề nghị mới.',
          'You can have one pending offer per listing. To change the price, withdraw it and send a new one.',
        ),
        _T(
          'Giá đề nghị phải lớn hơn 0 và không cao hơn giá niêm yết.',
          'Offers must be above zero and no higher than the listed price.',
        ),
        _T(
          'Sau khi bị từ chối hoặc thu hồi, bạn có thể gửi đề nghị mới.',
          'After a rejection or withdrawal you may send a new offer.',
        ),
      ]),
      PolicySubheading(_T('Người bán', 'Sellers')),
      PolicyBullets([
        _T(
          'Chấp nhận: Restore ghi nhận thỏa thuận và mở quyền đánh giá.',
          'Accept: Restore records the agreement and opens reviews.',
        ),
        _T(
          'Từ chối: người mua được thông báo và có thể tiếp tục thương lượng.',
          'Reject: the buyer is told and can keep negotiating.',
        ),
        _T(
          'Bạn không thể trả giá tin của chính mình.',
          'You cannot make an offer on your own listing.',
        ),
      ]),
      PolicySubheading(_T('Trạng thái đề nghị', 'Offer status')),
      PolicyTable(
        (_T('Trạng thái', 'Status'), _T('Ý nghĩa', 'Meaning')),
        [
          (
            _T('Đang chờ', 'Pending'),
            _T('Chờ người bán phản hồi', 'Waiting for the seller'),
          ),
          (
            _T('Đã chấp nhận', 'Accepted'),
            _T(
              'Đã ghi nhận thỏa thuận, mở quyền đánh giá',
              'Agreement recorded, reviews open',
            ),
          ),
          (
            _T('Đã từ chối', 'Rejected'),
            _T('Người bán đã từ chối', 'The seller declined'),
          ),
          (
            _T('Đã thu hồi', 'Withdrawn'),
            _T('Người mua đã thu hồi', 'The buyer withdrew it'),
          ),
          (
            _T('Hết hiệu lực', 'Expired'),
            _T(
              'Tin không còn khả dụng hoặc người bán không phản hồi trong 72 giờ',
              'The listing is unavailable, or the seller did not respond within 72 hours',
            ),
          ),
        ],
      ),
      PolicyBullets([
        _T(
          'Giá đã thống nhất được lưu riêng với giá niêm yết. Sửa giá tin sau đó không làm đổi thỏa thuận.',
          'The agreed price is stored apart from the listed price. Editing the listing later does not change the agreement.',
        ),
        _T(
          'Mỗi tin nhận tối đa 5 đề nghị của bạn trong 24 giờ. Cố tình trả giá quá thấp để làm phiền người bán có thể bị tạm khóa tính năng trả giá.',
          'You can send up to 5 offers per listing in 24 hours. Pestering a seller with lowball offers can get offers disabled for you.',
        ),
      ]),
      PolicyNote(
        _T(
          'Đề nghị được chấp nhận là cam kết về giá giữa hai bên. Nếu không thể tiếp tục, hãy báo đối phương trong chat. Trải nghiệm này có thể được phản ánh trong đánh giá.',
          'An accepted offer is a price commitment between both sides. If you cannot go ahead, tell the other person in chat. They may mention it in their review.',
        ),
      ),
    ],
  ),
  PolicySection(
    id: 'safety',
    icon: AppIcons.shield,
    title: _T('Mua bán an toàn', 'Trading safely'),
    blocks: [
      PolicyBullets([
        _T(
          'Gặp ở nơi công cộng, đông người, ban ngày. Kiểm tra hàng trước khi trả tiền.',
          'Meet in a busy public place in daylight. Check the item before you pay.',
        ),
        _T(
          'Hạn chế chuyển cọc cho người chưa gặp. Khi chuyển khoản, đối chiếu đúng tên chủ tài khoản.',
          'Avoid paying deposits to people you have not met. When transferring, check the account holder\'s name.',
        ),
        _T(
          'Giữ trao đổi trong chat Restore. Đây là căn cứ khi bạn cần báo cáo.',
          'Keep the conversation in Restore chat. It is your evidence if you need to report someone.',
        ),
        _T(
          'Restore không bao giờ hỏi mã OTP, mật khẩu hay gửi link thanh toán qua chat.',
          'Restore never asks for OTP codes or passwords, and never sends payment links in chat.',
        ),
        _T(
          'Cẩn thận với giá rẻ bất thường, lời mời chuyển sang ứng dụng khác ngay, hoặc thúc ép thanh toán gấp.',
          'Watch out for prices that are too good, pressure to move to another app, or urgent payment demands.',
        ),
      ]),
      PolicyNote(
        _T(
          'Thấy dấu hiệu lừa đảo: dừng giao dịch, chặn và báo cáo người dùng đó.',
          'If something looks like a scam: stop, block and report the user.',
        ),
        warning: true,
      ),
    ],
  ),
  PolicySection(
    id: 'reviews',
    icon: AppIcons.star,
    title: _T('Đánh giá hai chiều', 'Two-way reviews'),
    blocks: [
      PolicyParagraph(
        _T(
          'Ngay khi người bán chấp nhận đề nghị, cả hai có thể đánh giá nhau từ nút Đánh giá trong chat, mục Đánh giá của tôi hoặc thông báo nhắc đánh giá. Mỗi đánh giá gồm 1–5 sao, các tiêu chí chọn nhanh và nhận xét.',
          'As soon as the seller accepts an offer, both sides can review each other from the Review button in chat, My reviews, or the reminder notification. Each review has 1–5 stars, quick tags and a comment.',
        ),
      ),
      PolicySubheading(
        _T('Người mua đánh giá người bán', 'Buyers rate sellers on'),
      ),
      PolicyBullets([
        _T('Giao tiếp tốt', 'Good communication'),
        _T('Sản phẩm đúng mô tả', 'Item as described'),
        _T('Đúng giờ', 'Punctual'),
        _T('Giữ đúng thỏa thuận', 'Kept the deal'),
        _T('Thái độ nhiệt tình', 'Helpful attitude'),
      ]),
      PolicySubheading(
        _T('Người bán đánh giá người mua', 'Sellers rate buyers on'),
      ),
      PolicyBullets([
        _T('Giao tiếp tốt', 'Good communication'),
        _T('Đúng giờ', 'Punctual'),
        _T('Giữ đúng thỏa thuận', 'Kept the deal'),
        _T('Thanh toán đúng cam kết', 'Paid as agreed'),
        _T('Thái độ lịch sự', 'Polite'),
      ]),
      PolicySubheading(_T('Thời hạn và công khai', 'Deadlines and publishing')),
      PolicyTable(
        (_T('Quy định', 'Rule'), _T('Thời hạn', 'Timing')),
        [
          (
            _T('Bắt đầu đánh giá', 'Start a review'),
            _T(
              'Trong 30 ngày kể từ khi chấp nhận đề nghị',
              'Within 30 days of the accepted offer',
            ),
          ),
          (
            _T('Chờ bên còn lại', 'Wait for the other side'),
            _T(
              '7 ngày kể từ đánh giá đầu tiên',
              '7 days from the first review',
            ),
          ),
          (
            _T('Cả hai đã đánh giá', 'Both reviewed'),
            _T('Công khai ngay', 'Published at once'),
          ),
          (
            _T('Chỉ một bên đánh giá', 'Only one reviewed'),
            _T('Công khai sau đủ 7 ngày', 'Published after 7 days'),
          ),
          (
            _T('Không ai đánh giá trong 30 ngày', 'Nobody reviewed in 30 days'),
            _T('Đóng quyền đánh giá', 'Reviews close'),
          ),
        ],
      ),
      PolicyParagraph(
        _T(
          'Nếu đánh giá đầu tiên được gửi vào ngày thứ 30, bên còn lại vẫn có đủ 7 ngày để đánh giá. Ví dụ:',
          'If the first review lands on day 30, the other side still gets the full 7 days. For example:',
        ),
      ),
      PolicySteps([
        (
          _T('Ngày 1', 'Day 1'),
          _T(
            'Người mua đánh giá người bán 2 sao. Chưa công khai.',
            'The buyer gives the seller 2 stars. Not published yet.',
          ),
        ),
        (
          _T('Ngày 3', 'Day 3'),
          _T(
            'Người bán đánh giá người mua 5 sao. Cả hai được công khai.',
            'The seller gives the buyer 5 stars. Both are published.',
          ),
        ),
        (
          _T('Hoặc ngày 8', 'Or day 8'),
          _T(
            'Nếu người bán chưa đánh giá, đánh giá 2 sao được công khai.',
            'If the seller never reviewed, the 2-star review is published.',
          ),
        ),
      ]),
      PolicySubheading(_T('Quy tắc', 'Rules')),
      PolicyBullets([
        _T(
          'Trong thời gian chờ, bên kia chỉ biết bạn đã đánh giá và thời hạn còn lại. Số sao, tiêu chí và nhận xét được giữ kín.',
          'While waiting, the other side only sees that you reviewed and how long is left. Stars, tags and comment stay hidden.',
        ),
        _T(
          'Bạn có thể sửa đánh giá trước khi công khai. Sau khi công khai, đánh giá không sửa được và lượt đánh giá của thỏa thuận đóng lại.',
          'You can edit your review until it is published. After that it is locked and the agreement\'s reviews close.',
        ),
        _T(
          'Mỗi người chỉ đánh giá một lần cho cùng cặp giao dịch trên một tin, dù đã gửi nhiều đề nghị.',
          'Each person reviews once per pair of members per listing, however many offers were sent.',
        ),
        _T(
          'Người nhận được phản hồi công khai một lần cho mỗi đánh giá.',
          'The person reviewed can post one public reply to each review.',
        ),
        _T(
          'Điểm trung bình chỉ tính các đánh giá đã công khai và chưa bị gỡ.',
          'Average ratings count only published reviews that have not been removed.',
        ),
        _T(
          'Đánh giá lặp lại giữa cùng hai tài khoản trong thời gian ngắn có thể được xem xét trước khi tính vào điểm.',
          'Repeated reviews between the same two accounts in a short time may be checked before they count.',
        ),
      ]),
      PolicySubheading(_T('Trường hợp đặc biệt', 'Special cases')),
      PolicyTable(
        (_T('Trường hợp', 'Case'), _T('Quyền đánh giá', 'Can review?')),
        [
          (
            _T('Chỉ nhắn tin hỏi sản phẩm', 'Only chatted about the item'),
            _T('Chưa có', 'No'),
          ),
          (
            _T('Đề nghị đang chờ hoặc bị từ chối', 'Offer pending or rejected'),
            _T('Chưa có', 'No'),
          ),
          (
            _T('Đã chấp nhận nhưng không gặp mặt', 'Accepted but never met'),
            _T('Có', 'Yes'),
          ),
          (
            _T(
              'Đã chấp nhận nhưng mua bán thất bại',
              'Accepted but the sale fell through',
            ),
            _T('Có', 'Yes'),
          ),
          (
            _T('Một bên chặn người còn lại', 'One side blocked the other'),
            _T('Giữ quyền đã phát sinh', 'Existing right is kept'),
          ),
          (
            _T('Một bên xóa hoặc ẩn hội thoại', 'One side deleted the chat'),
            _T('Vẫn còn trong Đánh giá của tôi', 'Still listed in My reviews'),
          ),
          (
            _T(
              'Hai người giao dịch sản phẩm khác',
              'Same two people, another item',
            ),
            _T('Có lượt đánh giá mới', 'A new review is allowed'),
          ),
        ],
      ),
    ],
  ),
  PolicySection(
    id: 'conduct',
    icon: AppIcons.chat,
    title: _T('Quy tắc nội dung', 'Content rules'),
    blocks: [
      PolicyParagraph(
        _T(
          'Áp dụng cho tin đăng, chat, đánh giá và phản hồi. Đánh giá phải dựa trên trải nghiệm thực tế. Nhận xét tiêu cực nhưng trung thực vẫn được giữ lại.',
          'These apply to listings, chat, reviews and replies. Reviews must reflect what actually happened. Honest negative feedback stays up.',
        ),
      ),
      PolicySubheading(_T('Không được phép', 'Not allowed')),
      PolicyBullets([
        _T(
          'Đánh giá giả, tự đánh giá bằng tài khoản phụ, thông đồng tăng sao.',
          'Fake reviews, reviewing yourself from a second account, or trading stars.',
        ),
        _T(
          'Đổi quà, giảm giá hay tiền để lấy đánh giá tốt; đe dọa để buộc người khác đánh giá hoặc sửa đánh giá.',
          'Offering gifts, discounts or money for good reviews; pressuring someone to leave or change a review.',
        ),
        _T(
          'Xúc phạm, phân biệt đối xử, đe dọa hoặc quấy rối.',
          'Insults, discrimination, threats or harassment.',
        ),
        _T(
          'Công khai thông tin cá nhân của người khác: số điện thoại, địa chỉ, giấy tờ tùy thân, số tài khoản, hình ảnh.',
          'Sharing someone else\'s personal details: phone number, address, ID documents, bank account or photos.',
        ),
        _T(
          'Nội dung không liên quan đến giao dịch như quảng cáo hoặc liên kết ra ngoài.',
          'Content unrelated to the trade, such as ads or outside links.',
        ),
      ]),
    ],
  ),
  PolicySection(
    id: 'reports',
    icon: AppIcons.report,
    title: _T('Báo cáo và kiểm duyệt', 'Reporting and moderation'),
    blocks: [
      PolicyBullets([
        _T(
          'Bạn có thể báo cáo tin đăng, người dùng và đánh giá. Chọn lý do và mô tả thêm nếu cần.',
          'You can report listings, users and reviews. Pick a reason and add details if needed.',
        ),
        _T(
          'Quản trị viên xem xét báo cáo trong vòng 3 ngày làm việc.',
          'Moderators review reports within 3 working days.',
        ),
        _T(
          'Nội dung lộ thông tin cá nhân hoặc vi phạm nghiêm trọng có thể bị tạm ẩn ngay trong lúc chờ xem xét.',
          'Content that exposes personal details or is seriously harmful can be hidden right away while it is reviewed.',
        ),
        _T(
          'Quản trị viên quyết định giữ hoặc gỡ. Người viết được thông báo khi đánh giá bị gỡ.',
          'Moderators decide to keep or remove. The author is told when a review is removed.',
        ),
        _T(
          'Khi một đánh giá bị gỡ, số lượt đánh giá và điểm trung bình được tính lại.',
          'When a review is removed, the review count and average rating are recalculated.',
        ),
        _T(
          'Restore không gỡ đánh giá chỉ vì nó tiêu cực.',
          'Restore does not remove a review just because it is negative.',
        ),
        _T(
          'Bạn được khiếu nại mỗi quyết định một lần qua Trung tâm trợ giúp, trong 14 ngày.',
          'You can appeal each decision once through the Help centre, within 14 days.',
        ),
        _T(
          'Cố ý báo cáo sai sự thật nhiều lần để hạ uy tín người khác cũng là vi phạm.',
          'Repeatedly filing false reports to damage someone\'s reputation is itself a violation.',
        ),
      ]),
    ],
  ),
  PolicySection(
    id: 'violations',
    icon: AppIcons.warning,
    title: _T('Xử lý vi phạm', 'Enforcement'),
    blocks: [
      PolicyTable(
        (_T('Biện pháp', 'Action'), _T('Áp dụng khi', 'Used when')),
        [
          (
            _T('Nhắc nhở', 'Warning'),
            _T('Vi phạm nhẹ lần đầu', 'A first, minor violation'),
          ),
          (
            _T('Gỡ nội dung', 'Removal'),
            _T(
              'Tin đăng, đánh giá hoặc phản hồi vi phạm',
              'A listing, review or reply breaks the rules',
            ),
          ),
          (
            _T('Hạn chế tính năng', 'Feature limits'),
            _T(
              'Tạm khóa trả giá, đánh giá hoặc đăng tin khi lạm dụng',
              'Offers, reviews or posting paused after abuse',
            ),
          ),
          (
            _T('Khóa tạm thời', 'Temporary suspension'),
            _T(
              'Tái phạm, hoặc nghi lừa đảo đang được xác minh',
              'Repeat violations, or suspected fraud under review',
            ),
          ),
          (
            _T('Khóa vĩnh viễn', 'Permanent ban'),
            _T(
              'Lừa đảo, đánh giá giả có tổ chức, mua bán hàng cấm',
              'Fraud, organised fake reviews, prohibited goods',
            ),
          ),
        ],
      ),
      PolicyNote(
        _T(
          'Tài khoản bị khóa vì đánh giá giả sẽ bị gỡ toàn bộ đánh giá liên quan, kể cả đánh giá đã viết cho người khác.',
          'Accounts banned for fake reviews lose every related review, including those they wrote for others.',
        ),
        warning: true,
      ),
    ],
  ),
  PolicySection(
    id: 'privacy',
    icon: AppIcons.lock,
    title: _T('Quyền riêng tư', 'Privacy'),
    blocks: [
      PolicyBullets([
        _T(
          'Hồ sơ công khai gồm tên hiển thị, ảnh đại diện, tin đăng, đánh giá đã công khai và ngày tham gia.',
          'Your public profile shows your display name, photo, listings, published reviews and join date.',
        ),
        _T(
          'Chỉ chia sẻ số điện thoại hoặc địa chỉ trong chat khi bạn đã sẵn sàng giao dịch.',
          'Only share your phone number or address in chat once you are ready to trade.',
        ),
        _T(
          'Quản trị viên chỉ xem nội dung chat liên quan khi xử lý một báo cáo.',
          'Moderators only read the relevant chat when handling a report.',
        ),
        _T(
          'Khi một tài khoản bị khóa, các đánh giá đã công khai vẫn được giữ để không làm mất uy tín của người kia, trừ trường hợp bị khóa vì đánh giá giả.',
          'When an account is suspended, its published reviews stay so the other person keeps their reputation, unless it was banned for fake reviews.',
        ),
      ]),
    ],
  ),
  PolicySection(
    id: 'services',
    icon: AppIcons.wallet,
    title: _T('Xu và dịch vụ trả phí', 'Coins and paid services'),
    blocks: [
      PolicyBullets([
        _T(
          'Restore không thu phí trên giao dịch giữa các thành viên.',
          'Restore charges no fee on trades between members.',
        ),
        _T(
          'Xu và gói thành viên chỉ dùng cho dịch vụ của Restore như đẩy tin, thêm ngày hiển thị, gói cửa hàng. Không dùng xu để trả tiền cho người bán.',
          'Coins and memberships are only for Restore services such as boosts, extra display days and shop plans. They cannot be used to pay a seller.',
        ),
        _T(
          'Điều kiện của từng gói được hiển thị khi bạn mua.',
          'Each package shows its terms when you buy it.',
        ),
      ]),
    ],
  ),
  PolicySection(
    id: 'changes',
    icon: AppIcons.history,
    title: _T('Thay đổi chính sách', 'Policy changes'),
    blocks: [
      PolicyBullets([
        _T(
          'Chính sách được cập nhật trên trang này kèm ngày hiệu lực.',
          'Updates are posted on this page with their effective date.',
        ),
        _T(
          'Thay đổi lớn được thông báo trong ứng dụng ít nhất 7 ngày trước khi áp dụng.',
          'Major changes are announced in the app at least 7 days before they apply.',
        ),
        _T(
          'Đánh giá cũ trước khi áp dụng luồng mới vẫn được giữ trên hồ sơ.',
          'Reviews written before the new flow stay on profiles.',
        ),
      ]),
    ],
  ),
];
