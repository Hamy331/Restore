/// Phiên bản Hợp đồng Cửa hàng; trùng `SHOP_TERMS_VERSION` ở backend
/// (my-shop.validator.ts). Đổi nội dung thì tăng ở cả hai bên.
const shopTermsVersion = '2026-11';

/// Một điều khoản: tiêu đề và các đoạn
typedef ShopTermsSection = ({String title, List<String> body});

/// Nội dung Hợp đồng Cửa hàng theo ngôn ngữ (vi mặc định)
List<ShopTermsSection> shopTerms(String languageCode, int fee) =>
    languageCode == 'en' ? _en(fee) : _vi(fee);

List<ShopTermsSection> _vi(int fee) => [
  (
    title: 'Điều 1. Các bên và phạm vi',
    body: [
      'Hợp đồng này được giao kết giữa ReStore (bên vận hành sàn giao dịch thương mại điện tử ReStore) và người dùng đăng ký tài khoản Cửa hàng (gọi là "Chủ shop").',
      'Hợp đồng quy định việc sử dụng tài khoản Cửa hàng: trang cửa hàng, nhãn Đối tác, xác minh giấy phép và đăng bài lên Bảng tin. Các gói tài khoản (đẩy tin, số tin đăng, tin nổi bật) được mua và tính phí riêng, không thuộc hợp đồng này.',
      'Chủ shop vẫn phải tuân thủ Điều khoản sử dụng và Quy chế hoạt động chung của ReStore.',
    ],
  ),
  (
    title: 'Điều 2. Điều kiện đăng ký',
    body: [
      'Chủ shop là cá nhân từ đủ 18 tuổi có đầy đủ năng lực hành vi dân sự, hoặc hộ kinh doanh, doanh nghiệp được thành lập hợp pháp tại Việt Nam.',
      'Thông tin đăng ký (tên cửa hàng, địa chỉ, giấy tờ xác minh) phải chính xác, trung thực và được cập nhật khi thay đổi.',
      'Chủ shop kinh doanh thường xuyên có trách nhiệm tự đăng ký kinh doanh và kê khai, nộp thuế theo quy định của pháp luật Việt Nam về thuế đối với hoạt động kinh doanh trên nền tảng thương mại điện tử.',
    ],
  ),
  (
    title: 'Điều 3. Phí đăng ký',
    body: [
      'Phí đăng ký tài khoản Cửa hàng là $fee xu (1 xu tương đương 1.000 đồng), thanh toán một lần bằng ví xu ReStore khi gửi đăng ký.',
      'Phí đăng ký không được hoàn lại sau khi cửa hàng đã được duyệt. Nếu ReStore từ chối cửa hàng và Chủ shop không tiếp tục sửa để gửi duyệt lại, Chủ shop có thể liên hệ bộ phận hỗ trợ để được xem xét hoàn xu.',
      'ReStore có thể điều chỉnh mức phí cho các lần đăng ký sau; mức phí mới được thông báo trước khi Chủ shop thanh toán.',
    ],
  ),
  (
    title: 'Điều 4. Duyệt cửa hàng, nhãn Đối tác và xác minh',
    body: [
      'Sau khi đăng ký, cửa hàng ở trạng thái chờ duyệt. ReStore kiểm tra tên và thông tin cửa hàng; tên không được chứa số điện thoại, đường dẫn web, từ ngữ quảng cáo sai sự thật hoặc mạo danh thương hiệu, tổ chức khác.',
      'Cửa hàng được duyệt có nhãn "Đối tác" trên hồ sơ và tin đăng, và được đăng bài lên Bảng tin.',
      'Chủ shop có thể gửi giấy phép kinh doanh và mã số thuế để được xác minh (dấu tick, mã chứng nhận). Việc xác minh là tự nguyện và có thể làm sau khi đăng ký.',
      'ReStore có quyền thu hồi nhãn Đối tác hoặc nhãn xác minh nếu thông tin không còn chính xác hoặc Chủ shop vi phạm hợp đồng này.',
    ],
  ),
  (
    title: 'Điều 5. Nghĩa vụ của Chủ shop',
    body: [
      'Chỉ đăng bán hàng hóa, dịch vụ được phép kinh doanh; không đăng hàng cấm, hàng giả, hàng nhập lậu, hàng xâm phạm quyền sở hữu trí tuệ hoặc hàng không rõ nguồn gốc.',
      'Mô tả trung thực tình trạng, xuất xứ, giá bán của hàng hóa; thực hiện đúng cam kết về giao hàng, bảo hành, đổi trả với người mua.',
      'Tôn trọng quyền lợi người tiêu dùng theo Luật Bảo vệ quyền lợi người tiêu dùng; tiếp nhận và giải quyết khiếu nại của người mua kịp thời.',
      'Bài đăng trên Bảng tin phải đúng sự thật, không spam, không quấy rối, không chứa nội dung vi phạm pháp luật hoặc thuần phong mỹ tục.',
      'Bảo vệ dữ liệu cá nhân của người mua có được qua ReStore và chỉ dùng cho mục đích giao dịch.',
    ],
  ),
  (
    title: 'Điều 6. Quyền và nghĩa vụ của ReStore',
    body: [
      'ReStore duy trì nền tảng, hiển thị trang cửa hàng, nhãn Đối tác và các tính năng dành cho Cửa hàng như mô tả khi đăng ký.',
      'ReStore có quyền kiểm duyệt, ẩn tin đăng, bài viết; tạm khóa hoặc chấm dứt tài khoản Cửa hàng khi Chủ shop vi phạm hợp đồng, quy chế hoạt động hoặc pháp luật, và phối hợp với cơ quan nhà nước có thẩm quyền khi được yêu cầu.',
      'ReStore không phải là bên bán trong giao dịch giữa Chủ shop và người mua.',
    ],
  ),
  (
    title: 'Điều 7. Dữ liệu cá nhân',
    body: [
      'Giấy tờ xác minh được lưu ở khu vực riêng, chỉ Chủ shop và nhân viên kiểm duyệt của ReStore xem được, và chỉ dùng để xác minh cửa hàng.',
      'ReStore xử lý dữ liệu cá nhân của Chủ shop theo quy định của pháp luật Việt Nam về bảo vệ dữ liệu cá nhân và Chính sách quyền riêng tư của ReStore.',
    ],
  ),
  (
    title: 'Điều 8. Hiệu lực và chấm dứt',
    body: [
      'Hợp đồng có hiệu lực từ khi Chủ shop đồng ý và thanh toán phí đăng ký.',
      'Chủ shop có thể yêu cầu đóng tài khoản Cửa hàng bất kỳ lúc nào qua bộ phận hỗ trợ; các nghĩa vụ với người mua phát sinh trước đó vẫn phải được thực hiện.',
      'Khi ReStore sửa đổi hợp đồng, phiên bản mới được thông báo trong ứng dụng; Chủ shop tiếp tục sử dụng tài khoản Cửa hàng nghĩa là đồng ý với phiên bản mới.',
    ],
  ),
  (
    title: 'Điều 9. Luật áp dụng và giải quyết tranh chấp',
    body: [
      'Hợp đồng được điều chỉnh bởi pháp luật nước Cộng hòa xã hội chủ nghĩa Việt Nam.',
      'Tranh chấp được ưu tiên giải quyết bằng thương lượng, hòa giải; nếu không thành, một trong các bên có quyền yêu cầu Tòa án có thẩm quyền tại Việt Nam giải quyết.',
    ],
  ),
];

List<ShopTermsSection> _en(int fee) => [
  (
    title: '1. Parties and scope',
    body: [
      'This agreement is between ReStore (the operator of the ReStore e-commerce marketplace) and the user who registers a Shop account (the "Shop owner").',
      'It covers the Shop account: the shop page, the Partner badge, licence verification and posting on the Feed. Account plans (boosts, listing quota, spotlight) are bought and charged separately and are not part of this agreement.',
      'The Shop owner must also follow the ReStore Terms of Use and operating rules.',
    ],
  ),
  (
    title: '2. Eligibility',
    body: [
      'The Shop owner is an individual aged 18 or over with full legal capacity, or a household business or company lawfully established in Vietnam.',
      'Registration details (shop name, address, verification documents) must be accurate, truthful and kept up to date.',
      'A Shop owner who trades regularly is responsible for registering the business and declaring and paying taxes under Vietnamese law on e-commerce businesses.',
    ],
  ),
  (
    title: '3. Registration fee',
    body: [
      'The Shop account registration fee is $fee credits (1 credit equals VND 1,000), paid once from the ReStore credit wallet when registering.',
      'The fee is non-refundable once the shop is approved. If ReStore rejects the shop and the Shop owner does not resubmit, the Shop owner may contact support to request a refund review.',
      'ReStore may change the fee for future registrations; any new fee is shown before payment.',
    ],
  ),
  (
    title: '4. Review, Partner badge and verification',
    body: [
      'After registering, the shop waits for review. ReStore checks the name and details; names must not contain phone numbers, web links, misleading claims or impersonate other brands or organisations.',
      'An approved shop shows the "Partner" badge on its profile and listings and can post on the Feed.',
      'The Shop owner may send a business licence and tax code to get verified (tick and certificate code). Verification is optional and can be done later.',
      'ReStore may remove the Partner or verification badge if the details are no longer accurate or the Shop owner breaches this agreement.',
    ],
  ),
  (
    title: '5. Shop owner obligations',
    body: [
      'Only sell goods and services that may lawfully be traded; no prohibited, counterfeit, smuggled, infringing or untraceable goods.',
      'Describe condition, origin and price truthfully and honour delivery, warranty and return commitments to buyers.',
      'Respect consumer rights under the Law on Protection of Consumer Rights and handle buyer complaints promptly.',
      'Feed posts must be truthful, not spam or harass, and not contain unlawful or offensive content.',
      'Protect buyers\' personal data obtained through ReStore and use it only for the transaction.',
    ],
  ),
  (
    title: '6. ReStore rights and obligations',
    body: [
      'ReStore keeps the platform running and shows the shop page, Partner badge and Shop features described at registration.',
      'ReStore may moderate or hide listings and posts, and suspend or close a Shop account that breaches this agreement, the operating rules or the law, and cooperates with competent authorities when required.',
      'ReStore is not the seller in transactions between the Shop owner and buyers.',
    ],
  ),
  (
    title: '7. Personal data',
    body: [
      'Verification documents are stored privately, visible only to the Shop owner and ReStore moderators, and used only to verify the shop.',
      'ReStore processes the Shop owner\'s personal data under Vietnamese personal data protection law and the ReStore Privacy Policy.',
    ],
  ),
  (
    title: '8. Term and termination',
    body: [
      'This agreement takes effect when the Shop owner accepts it and pays the registration fee.',
      'The Shop owner may ask support to close the Shop account at any time; obligations to buyers that arose earlier still apply.',
      'When ReStore amends this agreement the new version is announced in the app; continuing to use the Shop account means accepting it.',
    ],
  ),
  (
    title: '9. Governing law and disputes',
    body: [
      'This agreement is governed by the laws of the Socialist Republic of Vietnam.',
      'Disputes are first resolved by negotiation or mediation; failing that, either party may bring the dispute to a competent court in Vietnam.',
    ],
  ),
];
