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
  String get categoryElectronicsDesc => 'Điện thoại, Laptop, Máy ảnh,...';

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
}
