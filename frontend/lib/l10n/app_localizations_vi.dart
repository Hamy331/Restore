// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appName => 'ReStore';

  @override
  String get loginTitle => 'Đăng nhập vào tài khoản';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mật khẩu';

  @override
  String get signIn => 'Đăng nhập';

  @override
  String get orSignInWith => 'Hoặc đăng nhập bằng';

  @override
  String get dontHaveAccount => 'Bạn chưa có tài khoản?';

  @override
  String get signUp => 'Đăng ký';

  @override
  String get successTitle => 'Thành công';

  @override
  String get errorTitle => 'Đã xảy ra lỗi';

  @override
  String get warningTitle => 'Cảnh báo';

  @override
  String get infoTitle => 'Thông tin';

  @override
  String get deviceNotSupported => 'Thiết bị không được hỗ trợ';

  @override
  String get deviceNotSupportedDesc =>
      'Ứng dụng ReStore hiện tại chỉ được thiết kế và tối ưu cho trải nghiệm trên màn hình điện thoại di động cầm tay.';

  @override
  String get loginSuccessMsg => 'Đăng nhập vào hệ thống thành công.';

  @override
  String get loginErrorMsg => 'Sai tài khoản hoặc mật khẩu.';

  @override
  String get verifyOtpTitle => 'Xác minh OTP';

  @override
  String get checkYourEmail => 'Kiểm tra email của bạn';

  @override
  String otpSentToEmail(String email) {
    return 'Mã OTP đã được gửi đến $email. Nhập 6 chữ số để tiếp tục.';
  }

  @override
  String otpValidFor(String time) {
    return 'Có thể gửi lại mã sau $time';
  }

  @override
  String get verifyEmailTitle => 'Xác minh email';

  @override
  String get enterVerificationCode => 'Nhập mã xác minh';

  @override
  String get verifyOtpButton => 'Xác minh OTP';

  @override
  String get verifyEmailButton => 'Xác minh email';

  @override
  String get resendOtp => 'Chưa nhận được mã? Gửi lại OTP';

  @override
  String get otpExpireInfo => 'Mã chỉ dùng một lần và hết hạn sau 5 phút.';

  @override
  String get emailVerifyInfo =>
      'Bạn có thể tiếp tục xem tin sau khi xác minh email.';

  @override
  String get invalidOtpError => 'Mã OTP không đúng. Kiểm tra và thử lại.';

  @override
  String get accountTitle => 'Tài khoản';

  @override
  String get settingsTitle => 'Cài đặt';

  @override
  String get profileName => 'Ngô Tường Phát';

  @override
  String get memberSince2022 => 'Thành viên từ 2022';

  @override
  String get maskedPhoneArea => '090 ••• 1234 · Quận 1, TP.HCM';

  @override
  String get editProfile => 'Chỉnh sửa hồ sơ';

  @override
  String get activeListings => 'Tin đang đăng';

  @override
  String get soldListings => 'Tin đã bán';

  @override
  String get myAccount => 'Tài khoản của tôi';

  @override
  String get savedListings => 'Tin đã lưu';

  @override
  String get reviews => 'Đánh giá';

  @override
  String get notifications => 'Thông báo';

  @override
  String get addressArea => 'Địa chỉ / Khu vực';

  @override
  String get restoreAi => 'ReStore AI';

  @override
  String get help => 'Trợ giúp';

  @override
  String get logout => 'Đăng xuất';

  @override
  String newCount(int count) {
    return '$count mới';
  }

  @override
  String get editProfileTitle => 'Chỉnh sửa hồ sơ';

  @override
  String get changeAvatar => 'Đổi ảnh đại diện';

  @override
  String get fullName => 'Họ và tên';

  @override
  String get phoneNumber => 'Số điện thoại';

  @override
  String get birthday => 'Ngày sinh';

  @override
  String get gender => 'Giới tính';

  @override
  String get male => 'Nam';

  @override
  String get female => 'Nữ';

  @override
  String get other => 'Khác';

  @override
  String get district1Hcm => 'Quận 1, TP. Hồ Chí Minh';

  @override
  String get thuDucHcm => 'Thủ Đức, TP. Hồ Chí Minh';

  @override
  String get district3Hcm => 'Quận 3, TP. Hồ Chí Minh';

  @override
  String get saveChanges => 'Lưu thay đổi';

  @override
  String get options => 'Tùy chọn';

  @override
  String get receiveNotifications => 'Nhận thông báo';

  @override
  String get privacy => 'Quyền riêng tư';

  @override
  String get changePassword => 'Đổi mật khẩu';

  @override
  String get helpSupport => 'Trợ giúp / Hỗ trợ';

  @override
  String get termsPolicies => 'Điều khoản & chính sách';

  @override
  String savedCount(int count) {
    return '$count tin đã lưu';
  }

  @override
  String get tapHeartToRemove => 'Chạm ♡ để bỏ lưu';

  @override
  String get emptySavedTitle => 'Chưa có tin đã lưu';

  @override
  String get emptySavedDescription =>
      'Lưu tin bạn quan tâm để xem lại nhanh hơn.';

  @override
  String get exploreProducts => 'Khám phá sản phẩm';

  @override
  String get today => 'Hôm nay';

  @override
  String get yesterday => 'Hôm qua';

  @override
  String get earlier => 'Trước đó';

  @override
  String get newMessage => 'Tin nhắn mới';

  @override
  String get newMessageDescription =>
      'Minh Anh vừa gửi thêm ảnh máy Canon AE-1.';

  @override
  String get newOffer => 'Đề nghị giá mới';

  @override
  String get newOfferDescription =>
      'Có đề nghị 2.200.000 đ cho tin Canon AE-1.';

  @override
  String get offerResponse => 'Phản hồi đề nghị';

  @override
  String get offerResponseDescription =>
      'Minh Anh đề nghị mức giá khác: 2.300.000 đ.';

  @override
  String get listingApproved => 'Tin đăng đã được duyệt';

  @override
  String get listingApprovedDescription =>
      'Tin Đèn bàn đồng vintage đang hiển thị.';

  @override
  String get listingNeedsEdit => 'Tin cần chỉnh sửa';

  @override
  String get listingNeedsEditDescription =>
      'Vui lòng bổ sung ảnh cho tin Ghế gỗ sồi.';

  @override
  String get listingSavedNotification => 'Tin của bạn được lưu';

  @override
  String get listingSavedDescription =>
      '3 người đã lưu tin Canon AE-1 của bạn.';

  @override
  String get sellerTitle => 'Người bán';

  @override
  String get sellerName => 'Minh Anh';

  @override
  String get sellerArea => 'Quận 1, TP. Hồ Chí Minh';

  @override
  String get sellerMemberSince => 'Thành viên từ 2022';

  @override
  String get ratingValue => '★ 4,9';

  @override
  String ratingCount(int count) {
    return '$count đánh giá';
  }

  @override
  String get sellingListings => 'Tin đang bán';

  @override
  String get chat => 'Chat';

  @override
  String get viewListings => 'Xem tin đăng';

  @override
  String listingCountShort(int count) {
    return '$count tin ›';
  }

  @override
  String get reportSeller => 'Báo cáo người bán';

  @override
  String get sellerRatingsTitle => 'Đánh giá người bán';

  @override
  String get communityReviews => 'Nhận xét từ cộng đồng';

  @override
  String reviewCount(int count) {
    return '$count nhận xét';
  }

  @override
  String get writeReview => 'Viết đánh giá';

  @override
  String get leaveReviewTitle => 'Viết đánh giá';

  @override
  String get sellerRoleArea => 'Người bán · Quận 1, TP.HCM';

  @override
  String get reviewQuestion => 'Bạn đánh giá người bán thế nào?';

  @override
  String starSelection(int count, String label) {
    return '$count sao · $label';
  }

  @override
  String get veryGood => 'Rất tốt';

  @override
  String get selected => 'Đã chọn';

  @override
  String get optionalReview => 'Nhận xét (không bắt buộc)';

  @override
  String get reviewHint => 'Chia sẻ trải nghiệm trao đổi của bạn...';

  @override
  String get reviewGuidance =>
      'Đánh giá giúp cộng đồng hiểu về người bán. Hãy chia sẻ trải nghiệm trao đổi của bạn.';

  @override
  String get submitReview => 'Gửi đánh giá';

  @override
  String get reportListing => 'Báo cáo tin đăng';

  @override
  String get reportUser => 'Báo cáo người dùng';

  @override
  String get report => 'Báo cáo';

  @override
  String get reportReason => 'Lý do báo cáo';

  @override
  String get inappropriateContent => 'Nội dung không phù hợp';

  @override
  String get suspectedFraud => 'Có dấu hiệu lừa đảo';

  @override
  String get prohibitedProduct => 'Sản phẩm bị cấm';

  @override
  String get misleadingInformation => 'Thông tin sai lệch';

  @override
  String get spam => 'Spam';

  @override
  String get otherReason => 'Lý do khác';

  @override
  String get optionalDescription => 'Mô tả thêm (không bắt buộc)';

  @override
  String get reportDescriptionHint => 'Thêm thông tin để chúng tôi kiểm tra...';

  @override
  String get submitReport => 'Gửi báo cáo';

  @override
  String get reportSuccessTitle => 'Đã gửi báo cáo';

  @override
  String get reportSuccessDescription =>
      'Cảm ơn bạn đã giúp ReStore an toàn hơn. Đội ngũ kiểm duyệt sẽ xem xét nội dung này.';

  @override
  String get goBack => 'Quay lại';

  @override
  String get reportedListingTitle => 'Máy ảnh Canon AE-1 + lens 50mm';

  @override
  String get reportedListingMeta => 'Tin đăng của Minh Anh · Quận 1';

  @override
  String get aiSampleCameraQuery => 'Tìm máy ảnh film dưới 4 triệu';

  @override
  String get aiSampleGamingQuery => 'Tìm laptop gaming dưới 15 triệu';

  @override
  String get aiSampleIphoneQuery => 'Tìm iPhone cũ dưới 10 triệu';

  @override
  String get aiSampleStudentLaptopQuery => 'Tìm laptop cho sinh viên';

  @override
  String get aiStartOver => 'Bắt đầu lại';

  @override
  String get aiEmptyStateMenu => 'Xem empty state';

  @override
  String get aiErrorStateMenu => 'Xem error state';

  @override
  String get aiInputHint => 'Hỏi về sản phẩm, giá, khu vực...';

  @override
  String get askRestoreAi => 'Hỏi ReStore AI';

  @override
  String get aiIntro =>
      'Mô tả món đồ bạn cần. AI sẽ tìm và so sánh các tin đăng phù hợp trên ReStore.';

  @override
  String get quickPrompts => 'Thử hỏi nhanh';

  @override
  String get sellerOwnsListings => 'Tin đăng là của người bán';

  @override
  String get sellerOwnsListingsDescription =>
      'Xem chi tiết tin và trao đổi trực tiếp với người bán khi bạn quan tâm.';

  @override
  String get continueConversation => 'Bạn có thể hỏi tiếp trong cùng hội thoại';

  @override
  String get continueConversationTips =>
      '• Giới hạn giá và khu vực\n• Chọn thương hiệu hoặc tình trạng\n• So sánh thông tin giữa các tin đăng';

  @override
  String get aiDefaultQuery => 'Tìm máy ảnh film dưới 4 triệu ở TP.HCM';

  @override
  String get aiResultsMessage =>
      'Mình tìm thấy 2 tin máy ảnh film phù hợp. Bạn có thể mở từng tin để xem thêm.';

  @override
  String get aiFilteredMessage =>
      'Mình đã cập nhật kết quả theo yêu cầu mới của bạn.';

  @override
  String get matchingListingsDemo => 'TIN ĐĂNG PHÙ HỢP · DỮ LIỆU MINH HỌA';

  @override
  String get canonListingTitle => 'Canon AE-1 + lens 50mm';

  @override
  String get canonPrice => '2.450.000 đ';

  @override
  String get canonLocationTime => 'Quận 1 · 2 giờ trước';

  @override
  String get nikonListingTitle => 'Máy ảnh Nikon FM2';

  @override
  String get nikonPrice => '3.800.000 đ';

  @override
  String get nikonLocationTime => 'Quận 10 · Hôm qua';

  @override
  String get sellerDataCaveat =>
      'Giá và tình trạng theo nội dung người bán cung cấp.';

  @override
  String get youCanAskNext => 'Bạn có thể hỏi tiếp:';

  @override
  String get canonOnly => 'Chỉ Canon thôi';

  @override
  String get compareTheseTwo => 'So sánh 2 máy này';

  @override
  String get comparisonMessage =>
      'Mình so sánh theo thông tin có trong hai tin đăng ReStore.';

  @override
  String get canonVsNikon => 'Canon AE-1 và Nikon FM2';

  @override
  String get listing => 'Tin đăng';

  @override
  String get price => 'Giá';

  @override
  String get condition => 'Tình trạng';

  @override
  String get area => 'Khu vực';

  @override
  String get posted => 'Đăng tin';

  @override
  String get goodCondition => 'Còn tốt';

  @override
  String get notSpecified => 'Chưa nêu';

  @override
  String get twoHoursAgo => '2 giờ trước';

  @override
  String get sellerInfoOnly => 'Chỉ dựa trên thông tin người bán đã cung cấp.';

  @override
  String get viewCanon => 'Xem Canon →';

  @override
  String get viewNikon => 'Xem Nikon →';

  @override
  String get aiEmptyTitle => 'Không tìm thấy tin phù hợp';

  @override
  String get aiEmptyDescription =>
      'Thử mở rộng khu vực, tăng khoảng giá hoặc mô tả sản phẩm ngắn gọn hơn.';

  @override
  String get adjustRequest => 'Điều chỉnh yêu cầu';

  @override
  String get aiErrorTitle => 'Chưa thể trả lời lúc này';

  @override
  String get aiErrorDescription =>
      'Nội dung cuộc trò chuyện vẫn được giữ. Bạn có thể thử lại mà không cần nhập lại từ đầu.';

  @override
  String get retry => 'Thử lại';

  @override
  String featureApiPending(String action) {
    return '$action sẽ được kết nối ở bước API.';
  }

  @override
  String get createListing => 'Đăng tin';

  @override
  String get editListing => 'Chỉnh sửa tin';

  @override
  String get close => 'Đóng';

  @override
  String get back => 'Quay lại';

  @override
  String stepCount(int current, int total) {
    return '$current/$total';
  }

  @override
  String productPhotosCount(int count) {
    return 'Ảnh sản phẩm · $count/10';
  }

  @override
  String get addPhotos => 'Thêm ảnh';

  @override
  String get firstPhotoHint => 'Ảnh đầu là ảnh bìa · Giữ và kéo để đổi thứ tự';

  @override
  String get productName => 'Tên sản phẩm';

  @override
  String get category => 'Danh mục';

  @override
  String get electronicsCamera => 'Điện tử › Máy ảnh';

  @override
  String get newCondition => 'Mới';

  @override
  String get usedCondition => 'Đã qua sử dụng';

  @override
  String get photoTip =>
      'Mẹo: ảnh rõ, nhiều góc chụp giúp tin đăng đáng tin hơn.';

  @override
  String get salePrice => 'Giá bán';

  @override
  String get priceVndHint => 'Nhập giá bằng VND';

  @override
  String get negotiable => 'Có thể thương lượng';

  @override
  String get description => 'Mô tả';

  @override
  String get location => 'Địa điểm';

  @override
  String get contactPreference => 'Ưu tiên liên hệ';

  @override
  String get phone => 'Điện thoại';

  @override
  String get directArrangementNote =>
      'Người mua và người bán tự thỏa thuận giao nhận, thanh toán.';

  @override
  String get continueAction => 'Tiếp tục';

  @override
  String get preview => 'Xem trước';

  @override
  String get publishListing => 'Đăng tin';

  @override
  String get boostListing => 'Đẩy tin';

  @override
  String get boostVisibilityTitle => 'Tăng khả năng hiển thị';

  @override
  String get boostVisibilityDescription =>
      'Tin đăng của bạn được ưu tiên hiển thị trong thời gian đã chọn. Không đảm bảo lượt xem hoặc bán được.';

  @override
  String get selectBoostDuration => 'Chọn thời gian đẩy tin';

  @override
  String get boost24Hours => 'Đẩy tin 24 giờ';

  @override
  String get boost3Days => 'Đẩy tin 3 ngày';

  @override
  String get boost7Days => 'Đẩy tin 7 ngày';

  @override
  String get visible24Hours => 'Hiển thị nổi bật trong 24 giờ';

  @override
  String get visible3Days => 'Duy trì hiển thị nổi bật 3 ngày';

  @override
  String get visible7Days => 'Duy trì hiển thị nổi bật 7 ngày';

  @override
  String get boostPrice24 => '19.000 đ';

  @override
  String get boostPrice3Days => '49.000 đ';

  @override
  String get boostPrice7Days => '99.000 đ';

  @override
  String get boostDemoPriceNote =>
      'Giá dịch vụ minh họa · bảng giá chính thức sẽ được xác nhận sau.';

  @override
  String get confirmPromotionService => 'Xác nhận dịch vụ quảng bá';

  @override
  String get currentListing => 'Tin của bạn';

  @override
  String get listingVisibilityStatus => 'Đang hiển thị · Tin của bạn';

  @override
  String get boostPackage => 'Gói đẩy tin';

  @override
  String get duration => 'Thời lượng';

  @override
  String get serviceFee => 'Phí dịch vụ';

  @override
  String get totalServiceFee => 'Tổng phí dịch vụ';

  @override
  String get threeDays => '3 ngày';

  @override
  String get seventyTwoHours => '72 giờ';

  @override
  String get restoreServiceFee => 'Phí dịch vụ ReStore';

  @override
  String get boostServiceBoundary =>
      'Bạn đang trả phí để quảng bá tin đăng, không thanh toán cho sản phẩm. ReStore không xử lý thanh toán mua bán.';

  @override
  String get continuePayment => 'Tiếp tục thanh toán';

  @override
  String get servicePayment => 'Thanh toán dịch vụ';

  @override
  String get vnpay => 'VNPay';

  @override
  String get vnpayDescription => 'Thanh toán phí quảng bá tin đăng qua VNPay';

  @override
  String get confirmPayment => 'Xác nhận thanh toán';

  @override
  String get paymentResult => 'Kết quả thanh toán';

  @override
  String get paymentSuccess => 'Thanh toán thành công';

  @override
  String get boostActivatedDescription => 'Tin của bạn đã được đẩy thành công';

  @override
  String get transactionDetails => 'Chi tiết giao dịch';

  @override
  String get transactionCode => 'Mã giao dịch';

  @override
  String get transactionCodeValue => 'RST-BST-260925-0842';

  @override
  String get amount => 'Số tiền';

  @override
  String get boostPeriod => 'Thời hạn đẩy tin';

  @override
  String get paymentMethod => 'Phương thức';

  @override
  String get viewListing => 'Xem tin';

  @override
  String get backToManageListings => 'Về trang quản lý tin';

  @override
  String get activeBoost => 'Đẩy tin đang hoạt động';

  @override
  String get activeBoostDescription =>
      'Tin này đang được ưu tiên hiển thị cho đến khi hết thời hạn.';

  @override
  String get expiredBoost => 'Đẩy tin đã hết hạn';

  @override
  String get expiredBoostDescription =>
      'Thời gian quảng bá đã kết thúc. Tin đăng vẫn tiếp tục hiển thị.';

  @override
  String get boostUnavailable => 'Không thể đẩy tin';

  @override
  String get boostUnavailableDescription =>
      'Chỉ tin đang hoạt động và đã được duyệt mới có thể đẩy.';

  @override
  String get boostAgain => 'Đẩy tin lại';

  @override
  String get boostPaymentFailed => 'Thanh toán không thành công';

  @override
  String get boostPaymentCancelled => 'Đã hủy thanh toán';

  @override
  String get boostPaymentPending => 'Đang xác nhận phí dịch vụ';

  @override
  String get tryPaymentAgain => 'Thử thanh toán lại';

  @override
  String get manageListings => 'Quản lý tin';

  @override
  String get feedsTitle => 'Bảng tin';

  @override
  String get feedsComingSoon => 'Bảng tin đang được phát triển';

  @override
  String get newListing => 'Đăng tin mới';

  @override
  String get visibleStatus => 'Đang hiển thị';

  @override
  String get pendingStatus => 'Chờ duyệt';

  @override
  String get hiddenStatus => 'Đã ẩn';

  @override
  String get soldStatus => 'Đã bán';

  @override
  String listingStatusCount(int count, String status) {
    return '$count $status';
  }

  @override
  String get editAction => 'Chỉnh sửa';

  @override
  String get hideListing => 'Ẩn tin';

  @override
  String get markAsSold => 'Đánh dấu đã bán';

  @override
  String get deleteListing => 'Xóa tin';

  @override
  String get showAgain => 'Hiện lại';

  @override
  String get pendingStatusNote => 'Tin đang được kiểm tra trước khi hiển thị.';

  @override
  String get hiddenStatusNote =>
      'Tin đang ẩn, người mua không thấy trong kết quả tìm kiếm.';

  @override
  String get soldStatusNote =>
      'Tin đã bán không còn hiển thị trong kết quả tìm kiếm.';

  @override
  String get markSoldTitle => 'Đánh dấu tin đã bán?';

  @override
  String get markSoldDescription => 'Tin sẽ không còn khả dụng với người mua.';

  @override
  String get platformNoOrderPayment =>
      'Thao tác này không tạo đơn hàng hay giao dịch. ReStore không xử lý thanh toán.';

  @override
  String get cancel => 'Hủy';

  @override
  String get homeTitle => 'Trang chủ';

  @override
  String get messagesTitle => 'Tin nhắn';

  @override
  String get listingDetailTitle => 'Chi tiết tin đăng';

  @override
  String get listingPreviewTitle => 'Xem trước tin đăng';

  @override
  String galleryPosition(int current, int total) {
    return '$current / $total';
  }

  @override
  String get listingLocationMeta =>
      '⌖ Quận 1, TP. Hồ Chí Minh · Đăng 2 giờ trước';

  @override
  String get usedGoodCondition => 'Đã qua sử dụng · Còn tốt';

  @override
  String get productDescription => 'Mô tả sản phẩm';

  @override
  String get canonDescription =>
      'Canon AE-1 hoạt động tốt, đo sáng chuẩn. Kèm lens FD 50mm f/1.8, dây đeo và bao da. Có thể xem máy trực tiếp tại Quận 1.';

  @override
  String get sellerRatingMeta => '★ 4,9 · 48 đánh giá · Phản hồi nhanh';

  @override
  String get similarListings => 'Tin tương tự';

  @override
  String get seeMore => 'Xem thêm ›';

  @override
  String get makeOffer => 'Trả giá';

  @override
  String get chooseCategoryTitle => 'Chọn danh mục';

  @override
  String get chooseCategorySubtitle => 'Bạn muốn đăng bán món đồ gì?';

  @override
  String get categoryElectronicsTitle => 'Đồ điện tử';

  @override
  String get categoryElectronicsDesc => 'Laptop, Máy ảnh, Tai nghe,...';

  @override
  String get categoryVehiclesTitle => 'Xe cộ';

  @override
  String get categoryVehiclesDesc => 'Xe máy, Xe đạp, Ô tô, Phụ tùng,...';

  @override
  String get categoryFashionTitle => 'Thời trang';

  @override
  String get categoryFashionDesc => 'Quần áo, Giày dép, Túi xách,...';

  @override
  String get categoryHomeTitle => 'Gia dụng';

  @override
  String get categoryHomeDesc => 'Nội thất, Đèn, Đồ bếp, Trang trí,...';

  @override
  String get step1Title => 'Ảnh & Sản phẩm';

  @override
  String productPhotosInfo(int count) {
    return 'Ảnh sản phẩm · $count/10';
  }

  @override
  String get coverImageHint =>
      'Ảnh đầu là ảnh bìa · Chạm vào ảnh để đặt làm bìa';

  @override
  String get productNameLabel => 'Tên sản phẩm';

  @override
  String get productNameMinLengthError => 'Tên sản phẩm tối thiểu 5 ký tự';

  @override
  String get categoryLabel => 'Danh mục';

  @override
  String get conditionLabel => 'Tình trạng';

  @override
  String get continueBtn => 'Tiếp tục';

  @override
  String get completeListingTitle => 'Hoàn thiện tin đăng';

  @override
  String get saveDraft => 'Lưu nháp';

  @override
  String get draftSaved => 'Đã lưu nháp';

  @override
  String listingPhotosLabel(int max) {
    return 'Hình ảnh (Tối đa $max ảnh)';
  }

  @override
  String photoCount(int count, int max) {
    return '$count/$max';
  }

  @override
  String get coverPhotoBadge => 'Bìa';

  @override
  String get photosRequiredError => 'Vui lòng thêm ít nhất 1 ảnh';

  @override
  String get detailedDescriptionLabel => 'Mô tả chi tiết';

  @override
  String get listingDescriptionHint =>
      '- Tình trạng, thời gian đã sử dụng\n- Phụ kiện đi kèm, lỗi nhỏ nếu có\n- Lý do bán, hình thức giao nhận';

  @override
  String characterCount(int count, int max) {
    return '$count/$max ký tự';
  }

  @override
  String descriptionMinLengthError(int min) {
    return 'Mô tả cần ít nhất $min ký tự';
  }

  @override
  String get listingTitleLabel => 'Tiêu đề tin đăng';

  @override
  String get listingTitleHint => 'VD: Piaggio Vespa Sprint 2024 15.000 km';

  @override
  String listingTitleMinLengthError(int min) {
    return 'Tiêu đề cần ít nhất $min ký tự';
  }

  @override
  String get priceRequiredError => 'Vui lòng nhập giá bán';

  @override
  String get addressLabel => 'Địa chỉ';

  @override
  String get youAreLabel => 'Bạn là';

  @override
  String get sellerPersonal => 'Cá nhân';

  @override
  String get sellerBusiness => 'Bán chuyên';

  @override
  String get detailedInfoTitle => 'Thông tin chi tiết';

  @override
  String categoryWithName(String name) {
    return 'Danh mục: $name';
  }

  @override
  String get fieldRequiredError => 'Vui lòng nhập thông tin này';

  @override
  String get fieldSelectRequiredError => 'Vui lòng chọn một giá trị';

  @override
  String get missingRequiredFields =>
      'Vui lòng điền đầy đủ các thông tin bắt buộc';

  @override
  String get listingSubmitted =>
      'Tin đăng của bạn đã được gửi và đang chờ duyệt';

  @override
  String get previewNotice => 'Đây là cách người mua sẽ thấy tin đăng của bạn';

  @override
  String get noPhotosYet => 'Chưa có ảnh';

  @override
  String get stepBasicInfoTitle => 'Ảnh, mô tả & giá bán';

  @override
  String get takePhoto => 'Chụp ảnh';

  @override
  String get chooseFromGallery => 'Chọn từ thư viện';

  @override
  String photoLimitReached(int max) {
    return 'Bạn chỉ có thể thêm tối đa $max ảnh';
  }

  @override
  String get photoPickFailed =>
      'Không thể mở ảnh. Vui lòng kiểm tra quyền truy cập ảnh và camera của ứng dụng.';

  @override
  String get draftSaveFailed => 'Lưu nháp thất bại, vui lòng thử lại';

  @override
  String get publishFailed => 'Đăng tin thất bại, vui lòng thử lại';

  @override
  String get tradeTypeLabel => 'Hình thức';

  @override
  String get tradeSell => 'Bán';

  @override
  String get tradeExchange => 'Trao đổi';

  @override
  String get tradeSellOrExchange => 'Cả hai';

  @override
  String get tradeExchangeAccepted => 'Nhận trao đổi';

  @override
  String get exchangeWishLabel => 'Muốn đổi lấy';

  @override
  String get exchangeWishHint => 'VD: iPhone 13 hoặc máy tính bảng';

  @override
  String get selectAddressHint => 'Chọn khu vực';

  @override
  String get stepShortCategory => 'Danh mục';

  @override
  String get stepShortBasicInfo => 'Thông tin';

  @override
  String get stepShortDetails => 'Chi tiết';

  @override
  String stepProgressLabel(int current, int total) {
    return 'Bước $current/$total';
  }

  @override
  String nextStepLabel(String name) {
    return 'Tiếp theo: $name';
  }

  @override
  String get conditionSectionTitle => 'Tình trạng sản phẩm';

  @override
  String get conditionNew => 'Mới';

  @override
  String get conditionLikeNew => 'Như mới';

  @override
  String get conditionUsedGood => 'Đã dùng - còn tốt';

  @override
  String get conditionUsedFair => 'Đã dùng - có hao mòn';

  @override
  String get conditionForParts => 'Hỏng / bán lấy linh kiện';

  @override
  String get conditionNewDesc => 'Chưa qua sử dụng, còn nguyên tem hộp';

  @override
  String get conditionLikeNewDesc => 'Dùng rất ít, không trầy xước';

  @override
  String get conditionUsedGoodDesc => 'Hoạt động tốt, có vài vết sử dụng nhỏ';

  @override
  String get conditionUsedFairDesc =>
      'Vẫn dùng được, có trầy xước hoặc lỗi nhỏ';

  @override
  String get conditionForPartsDesc => 'Không còn hoạt động bình thường';

  @override
  String get categoryAttributesTitle => 'Thông tin theo danh mục';

  @override
  String get categoryAttributesHint =>
      'Các trường bên dưới thay đổi theo danh mục';

  @override
  String get selectOptionHint => 'Chọn';

  @override
  String numberRangeError(String min, String max) {
    return 'Giá trị phải từ $min đến $max';
  }

  @override
  String get yes => 'Có';

  @override
  String get no => 'Không';

  @override
  String get loadCategoriesFailedTitle => 'Không tải được danh mục';

  @override
  String get loadCategoriesFailedMessage => 'Kiểm tra kết nối mạng rồi thử lại';

  @override
  String get negotiableHint => 'Người mua có thể trả giá khi nhắn tin';

  @override
  String get addressNearbyHint => 'Giúp người mua gần bạn tìm thấy tin';

  @override
  String privateStreetAddress(String street) {
    return '$street (không công khai)';
  }

  @override
  String get addressSheetTitle => 'Địa chỉ của món đồ';

  @override
  String get useCurrentLocation => 'Dùng vị trí hiện tại';

  @override
  String get useCurrentLocationHint => 'Tự điền tỉnh/thành và phường/xã';

  @override
  String get locatingLabel => 'Đang lấy vị trí...';

  @override
  String get locationDetected => 'Đã lấy vị trí của bạn';

  @override
  String get orChooseManually => 'hoặc chọn thủ công';

  @override
  String get provinceLabel => 'Tỉnh/Thành phố';

  @override
  String get selectProvinceHint => 'Chọn tỉnh/thành phố';

  @override
  String get wardLabel => 'Phường/Xã';

  @override
  String get selectWardHint => 'Chọn phường/xã';

  @override
  String get selectProvinceFirst => 'Chọn tỉnh/thành phố trước';

  @override
  String get streetAddressLabel => 'Số nhà, tên đường';

  @override
  String get streetAddressHint => 'VD: 12 Nguyễn Huệ';

  @override
  String get streetAddressHelper => 'Không bắt buộc, không hiển thị công khai';

  @override
  String get addressPrivacyNote =>
      'Người mua chỉ thấy phường/xã và tỉnh/thành. Vị trí được dùng để gợi ý tin đăng gần bạn.';

  @override
  String get confirmAddress => 'Xác nhận địa chỉ';

  @override
  String get loadingLocations => 'Đang tải danh sách...';

  @override
  String get loadLocationsFailed => 'Không tải được danh sách, chạm để thử lại';

  @override
  String get locationServiceDisabled => 'Hãy bật định vị (GPS) để lấy vị trí';

  @override
  String get locationPermissionDenied => 'Bạn chưa cho phép truy cập vị trí';

  @override
  String get locationPermissionDeniedForever =>
      'Quyền vị trí đã bị chặn, hãy bật lại trong Cài đặt';

  @override
  String get locationUnavailable => 'Không lấy được vị trí, hãy chọn thủ công';

  @override
  String get locationOutOfCoverage =>
      'Vị trí của bạn chưa khớp với phường/xã nào. Bạn chọn thủ công ở bên dưới nhé.';

  @override
  String get searchOptionHint => 'Tìm kiếm (gõ không dấu cũng được)';

  @override
  String get noMatchingOptions => 'Không có kết quả phù hợp';

  @override
  String get locationOutsideVietnamTitle => 'Bạn đang ở ngoài Việt Nam?';

  @override
  String get locationOutsideVietnamBody =>
      'ReStore hiện chỉ hỗ trợ địa chỉ tại Việt Nam. Bạn chọn tỉnh/thành và phường/xã ở bên dưới nhé.';

  @override
  String get locationOutOfCoverageTitle => 'Chưa nhận ra khu vực này';

  @override
  String get aiBubbleTooltip => 'Chat với ReStore AI';

  @override
  String unreadMessagesCount(int count) {
    return '$count tin nhắn chưa đọc';
  }

  @override
  String get homeGreeting => 'Chào bạn 👋';

  @override
  String get homeHeadline => 'Hôm nay bạn muốn săn gì?';

  @override
  String get homeSearchHint => 'Tìm đồ cũ, đồ trao đổi...';

  @override
  String get homeChangeArea => 'Đổi khu vực';

  @override
  String get homeForYouTitle => 'Dành cho bạn';

  @override
  String get homeLatestTitle => 'Tin đăng mới';

  @override
  String get homeSeeAll => 'Xem tất cả';

  @override
  String get homeFeaturedTag => 'Nổi bật';

  @override
  String get homeExchangeTag => 'Đổi được';

  @override
  String get homeExchangeOnly => 'Chỉ trao đổi';

  @override
  String get homeSaveListing => 'Lưu tin';

  @override
  String get homeUnsaveListing => 'Bỏ lưu tin';

  @override
  String get homeLoadErrorTitle => 'Chưa tải được trang chủ';

  @override
  String get homeLoadErrorBody => 'Kiểm tra kết nối mạng rồi thử lại nhé.';

  @override
  String get timeJustNow => 'Vừa xong';

  @override
  String timeMinutesAgo(int count) {
    return '$count phút trước';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count giờ trước';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count ngày trước';
  }

  @override
  String get featureComingSoon => 'Tính năng này đang được phát triển';

  @override
  String homeGreetingName(String name) {
    return 'Chào $name 👋';
  }

  @override
  String get homeLatestEmpty => 'Chưa có tin nào ở mục này';

  @override
  String get homeEndOfList => 'Bạn đã xem hết tin rồi';

  @override
  String get homeQuickNearby => 'Gần bạn';

  @override
  String get homeQuickNearbyDesc => 'Quanh đây trong 5 km';

  @override
  String get homeQuickWanted => 'Báo khi có hàng';

  @override
  String get homeQuickWantedDesc => 'Đặt trước món bạn cần';

  @override
  String get homeQuickTrustedShops => 'Shop uy tín';

  @override
  String get homeQuickTrustedShopsDesc => 'Đã xác minh, đánh giá tốt';

  @override
  String get homeQuickFollowing => 'Đang theo dõi';

  @override
  String get homeQuickFollowingDesc => 'Shop và người bạn theo dõi';

  @override
  String get homeBannerTooltip => 'Banner khuyến mãi';

  @override
  String get productDetailTitle => 'Chi tiết sản phẩm';

  @override
  String get productLoadErrorTitle => 'Không tải được tin đăng';

  @override
  String get productLoadErrorBody =>
      'Tin có thể đã bị gỡ hoặc kết nối mạng chưa ổn định. Vui lòng thử lại.';

  @override
  String productViewCount(int count) {
    return '$count lượt xem';
  }

  @override
  String get productUnavailableHint => 'Sản phẩm này hiện không thể đặt mua.';

  @override
  String get listingStatusDraft => 'Bản nháp';

  @override
  String get listingStatusPending => 'Đang chờ duyệt';

  @override
  String get listingStatusAvailable => 'Đang bán';

  @override
  String get listingStatusReserved => 'Đã có người đặt';

  @override
  String get listingStatusSold => 'Đã bán';

  @override
  String get listingStatusExchanged => 'Đã trao đổi';

  @override
  String get listingStatusExpired => 'Đã hết hạn';

  @override
  String get productSellerTitle => 'Người bán';

  @override
  String get productSellerVerified => 'Đã xác minh';

  @override
  String get productSellerNoReviews => 'Chưa có đánh giá';

  @override
  String productSellerJoined(String date) {
    return 'Tham gia $date';
  }

  @override
  String productSellerListings(int count) {
    return '$count tin đang bán';
  }

  @override
  String get productSellerProfile => 'Xem trang';

  @override
  String get productReadMore => 'Xem thêm';

  @override
  String get productReadLess => 'Thu gọn';

  @override
  String get productSafetyTitle => 'Mua bán an toàn';

  @override
  String get productSafetyBody =>
      'Hẹn gặp ở nơi công cộng, kiểm tra hàng trước khi trả tiền và không chuyển tiền đặt cọc cho người lạ.';

  @override
  String get productReport => 'Báo cáo tin';

  @override
  String get productChat => 'Nhắn tin';

  @override
  String get productMakeOffer => 'Trả giá';

  @override
  String get productBuyNow => 'Mua ngay';

  @override
  String get productProposeExchange => 'Đề nghị đổi';

  @override
  String get productEditListing => 'Sửa tin';

  @override
  String get productBoost => 'Đẩy tin';

  @override
  String get productOfferTitle => 'Trả giá với người bán';

  @override
  String productOfferSubtitle(String price) {
    return 'Giá đang bán: $price';
  }

  @override
  String get productOfferAmountLabel => 'Giá bạn đề nghị';

  @override
  String get productOfferAmountHint => 'Nhập số tiền';

  @override
  String get productOfferInvalid => 'Nhập số tiền lớn hơn 0';

  @override
  String get productOfferTooHigh =>
      'Giá đề nghị không được vượt quá 2 lần giá đang bán';

  @override
  String get productOfferSubmit => 'Gửi đề nghị';

  @override
  String get productOfferSent =>
      'Đã gửi đề nghị, tiếp tục trao đổi với người bán tại đây.';

  @override
  String productOfferBelow(String percent, String difference) {
    return 'Thấp hơn giá gốc $percent (-$difference)';
  }

  @override
  String productOfferAbove(String percent, String difference) {
    return 'Cao hơn giá gốc $percent (+$difference)';
  }

  @override
  String get productOfferEqual => 'Bằng giá gốc';

  @override
  String get productLiveTitle => 'Tin vừa được cập nhật';

  @override
  String productLiveUnavailable(String status) {
    return 'Sản phẩm hiện $status, bạn không thể đặt mua nữa.';
  }

  @override
  String get productLiveAvailable => 'Sản phẩm vừa được mở bán trở lại.';

  @override
  String productLivePrice(String previous, String current) {
    return 'Người bán vừa đổi giá từ $previous thành $current.';
  }

  @override
  String get productLivePriceGeneric =>
      'Người bán vừa cập nhật giá, bạn xem lại trước khi gửi nhé.';

  @override
  String get productLiveInfo => 'Người bán vừa sửa thông tin tin đăng.';

  @override
  String get productLiveIndicator => 'Đang cập nhật trực tiếp';

  @override
  String get productBuyTitle => 'Yêu cầu mua';

  @override
  String get productBuySubtitle =>
      'Người bán sẽ xác nhận và hẹn giao nhận với bạn qua tin nhắn.';

  @override
  String get productBuyPriceLabel => 'Giá';

  @override
  String get productBuyNoteLabel => 'Lời nhắn cho người bán';

  @override
  String get productBuyNoteHint => 'VD: Mình có thể qua lấy vào tối nay';

  @override
  String get productBuySubmit => 'Gửi yêu cầu';

  @override
  String get productBuySent =>
      'Đã gửi yêu cầu mua, người bán sẽ phản hồi qua tin nhắn.';

  @override
  String get productActionFailed => 'Gửi chưa được, vui lòng thử lại.';

  @override
  String get galleryOpenFullscreen => 'Xem ảnh toàn màn hình';

  @override
  String get nearbyTitle => 'Gần bạn';

  @override
  String get nearbySubtitle => 'Đồ cũ quanh đây, hẹn gặp là có ngay';

  @override
  String get nearbyCurrentLocation => 'Vị trí hiện tại';

  @override
  String get nearbyLocating => 'Đang xác định vị trí...';

  @override
  String get nearbyChangeLocation => 'Đổi';

  @override
  String get nearbyRelocate => 'Cập nhật vị trí';

  @override
  String get nearbyFilters => 'Bộ lọc';

  @override
  String nearbyRadiusChip(String distance) {
    return 'Trong $distance';
  }

  @override
  String get nearbyRadiusTitle => 'Tìm trong bán kính';

  @override
  String nearbyRadiusOption(String distance) {
    return 'Trong vòng $distance';
  }

  @override
  String get listingDealBuy => 'Mua trực tiếp';

  @override
  String get listingDealExchange => 'Trao đổi';

  @override
  String get listingSortTitle => 'Sắp xếp theo';

  @override
  String get listingSortNearest => 'Gần nhất';

  @override
  String get listingSortNewest => 'Mới nhất';

  @override
  String get listingSortPriceLow => 'Giá thấp đến cao';

  @override
  String get listingSortPriceHigh => 'Giá cao đến thấp';

  @override
  String get nearbyFallbackTitle => 'Đang xem quanh khu vực mặc định';

  @override
  String get nearbyUseMyLocation => 'Dùng vị trí của tôi';

  @override
  String get nearbyOpenSettings => 'Mở Cài đặt';

  @override
  String get nearbyEmptyTitle => 'Chưa có tin nào quanh đây';

  @override
  String get nearbyEmptyBody => 'Thử mở rộng bán kính hoặc bỏ bớt bộ lọc nhé.';

  @override
  String nearbyExpandRadius(String distance) {
    return 'Mở rộng tới $distance';
  }

  @override
  String get nearbyLoadErrorTitle => 'Chưa tải được tin gần bạn';

  @override
  String get nearbyLoadErrorBody => 'Kiểm tra kết nối mạng rồi thử lại nhé.';

  @override
  String get nearbyEndOfList => 'Bạn đã xem hết tin quanh đây';

  @override
  String distanceMeters(int meters) {
    return '$meters m';
  }

  @override
  String distanceKm(String km) {
    return '$km km';
  }

  @override
  String get listingSortRelevance => 'Phù hợp nhất';

  @override
  String get searchNearMe => 'Gần tôi';

  @override
  String get searchNearMeSubtitle => 'Xem đồ cũ quanh vị trí của bạn';

  @override
  String get searchTipsTitle => 'Gợi ý tìm nhanh';

  @override
  String get searchHistoryTitle => 'Tìm kiếm gần đây';

  @override
  String get searchClearHistory => 'Xoá tất cả';

  @override
  String get searchRemoveHistory => 'Xoá khỏi danh sách';

  @override
  String get searchFillQuery => 'Đưa lên ô tìm kiếm';

  @override
  String get searchClearInput => 'Xoá nội dung';

  @override
  String searchForQuery(String query) {
    return 'Tìm “$query”';
  }

  @override
  String searchEmptyTitle(String query) {
    return 'Không tìm thấy “$query”';
  }

  @override
  String get searchEmptyBody =>
      'Thử từ khoá ngắn hơn, từ khoá khác hoặc bỏ bớt bộ lọc nhé.';

  @override
  String get searchTryAnother => 'Đổi từ khoá';

  @override
  String get searchLoadErrorTitle => 'Chưa tải được kết quả';

  @override
  String get searchLoadErrorBody => 'Kiểm tra kết nối mạng rồi thử lại nhé.';

  @override
  String get searchEndOfList => 'Bạn đã xem hết kết quả';

  @override
  String get areaSearchHint => 'Tìm phường/xã, tỉnh/thành...';

  @override
  String get areaMyLocationSubtitle => 'Dùng vị trí GPS hiện tại của bạn';

  @override
  String get areaRecentTitle => 'Khu vực đã chọn gần đây';

  @override
  String get areaWholeProvince => 'Toàn tỉnh/thành phố';

  @override
  String get areaNoResultsTitle => 'Không tìm thấy khu vực';

  @override
  String get areaNoResultsBody =>
      'Thử gõ tên phường/xã hoặc tỉnh/thành khác nhé.';

  @override
  String get areaSearchErrorTitle => 'Chưa tìm được khu vực';
}
