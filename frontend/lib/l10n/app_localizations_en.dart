// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'ReStore';

  @override
  String get loginTitle => 'Login to your Account';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get signIn => 'Sign in';

  @override
  String get orSignInWith => 'Or sign in with';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get signUp => 'Sign up';

  @override
  String get successTitle => 'Success';

  @override
  String get errorTitle => 'Error occurred';

  @override
  String get warningTitle => 'Warning';

  @override
  String get infoTitle => 'Information';

  @override
  String get deviceNotSupported => 'Device not supported';

  @override
  String get deviceNotSupportedDesc =>
      'The ReStore application is currently designed and optimized exclusively for mobile handheld experiences.';

  @override
  String get loginSuccessMsg => 'Successfully logged into the system.';

  @override
  String get loginErrorMsg => 'Invalid email or password.';

  @override
  String get verifyOtpTitle => 'Verify OTP';

  @override
  String get checkYourEmail => 'Check your email';

  @override
  String otpSentToEmail(String email) {
    return 'An OTP has been sent to $email. Enter the 6 digits to continue.';
  }

  @override
  String otpValidFor(String time) {
    return 'You can resend the code in $time';
  }

  @override
  String get verifyEmailTitle => 'Verify Email';

  @override
  String get enterVerificationCode => 'Enter verification code';

  @override
  String get verifyOtpButton => 'Verify OTP';

  @override
  String get verifyEmailButton => 'Verify email';

  @override
  String get resendOtp => 'Didn\'t receive code? Resend OTP';

  @override
  String get otpExpireInfo =>
      'The code is for one-time use and expires in 5 minutes.';

  @override
  String get emailVerifyInfo =>
      'You can continue browsing after verifying your email.';

  @override
  String get invalidOtpError => 'Invalid OTP. Please check and try again.';

  @override
  String get accountTitle => 'Account';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get profileName => 'Ngo Tuong Phat';

  @override
  String get memberSince2022 => 'Member since 2022';

  @override
  String get maskedPhoneArea => '090 ••• 1234 · District 1, HCMC';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get activeListings => 'Active listings';

  @override
  String get soldListings => 'Sold listings';

  @override
  String get myAccount => 'My account';

  @override
  String get savedListings => 'Saved listings';

  @override
  String get reviews => 'Reviews';

  @override
  String get notifications => 'Notifications';

  @override
  String get addressArea => 'Address / Area';

  @override
  String get restoreAi => 'ReStore AI';

  @override
  String get help => 'Help';

  @override
  String get logout => 'Log out';

  @override
  String newCount(int count) {
    return '$count new';
  }

  @override
  String get editProfileTitle => 'Edit profile';

  @override
  String get changeAvatar => 'Change profile photo';

  @override
  String get fullName => 'Full name';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get birthday => 'Date of birth';

  @override
  String get gender => 'Gender';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get other => 'Other';

  @override
  String get district1Hcm => 'District 1, Ho Chi Minh City';

  @override
  String get thuDucHcm => 'Thu Duc, Ho Chi Minh City';

  @override
  String get district3Hcm => 'District 3, Ho Chi Minh City';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get options => 'Options';

  @override
  String get receiveNotifications => 'Receive notifications';

  @override
  String get privacy => 'Privacy';

  @override
  String get changePassword => 'Change password';

  @override
  String get helpSupport => 'Help / Support';

  @override
  String get termsPolicies => 'Terms & policies';

  @override
  String savedCount(int count) {
    return '$count saved listings';
  }

  @override
  String get tapHeartToRemove => 'Tap ♡ to remove';

  @override
  String get emptySavedTitle => 'No saved listings yet';

  @override
  String get emptySavedDescription =>
      'Save listings you like to find them faster later.';

  @override
  String get exploreProducts => 'Explore products';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get earlier => 'Earlier';

  @override
  String get newMessage => 'New message';

  @override
  String get newMessageDescription =>
      'Minh Anh sent another photo of the Canon AE-1.';

  @override
  String get newOffer => 'New price offer';

  @override
  String get newOfferDescription =>
      'There is a 2,200,000 đ offer for the Canon AE-1 listing.';

  @override
  String get offerResponse => 'Offer response';

  @override
  String get offerResponseDescription =>
      'Minh Anh proposed another price: 2,300,000 đ.';

  @override
  String get listingApproved => 'Listing approved';

  @override
  String get listingApprovedDescription =>
      'The vintage brass desk lamp listing is now visible.';

  @override
  String get listingNeedsEdit => 'Listing needs changes';

  @override
  String get listingNeedsEditDescription =>
      'Please add photos to the oak chair listing.';

  @override
  String get listingSavedNotification => 'Your listing was saved';

  @override
  String get listingSavedDescription =>
      '3 people saved your Canon AE-1 listing.';

  @override
  String get sellerTitle => 'Seller';

  @override
  String get sellerName => 'Minh Anh';

  @override
  String get sellerArea => 'District 1, Ho Chi Minh City';

  @override
  String get sellerMemberSince => 'Member since 2022';

  @override
  String get ratingValue => '★ 4.9';

  @override
  String ratingCount(int count) {
    return '$count ratings';
  }

  @override
  String get sellingListings => 'Listings for sale';

  @override
  String get chat => 'Chat';

  @override
  String get viewListings => 'View listings';

  @override
  String listingCountShort(int count) {
    return '$count listings ›';
  }

  @override
  String get reportSeller => 'Report seller';

  @override
  String get sellerRatingsTitle => 'Seller ratings';

  @override
  String get communityReviews => 'Community reviews';

  @override
  String reviewCount(int count) {
    return '$count reviews';
  }

  @override
  String get writeReview => 'Write a review';

  @override
  String get leaveReviewTitle => 'Write review';

  @override
  String get sellerRoleArea => 'Seller · District 1, HCMC';

  @override
  String get reviewQuestion => 'How would you rate the seller?';

  @override
  String starSelection(int count, String label) {
    return '$count stars · $label';
  }

  @override
  String get veryGood => 'Very good';

  @override
  String get selected => 'Selected';

  @override
  String get optionalReview => 'Review (optional)';

  @override
  String get reviewHint => 'Share your exchange experience...';

  @override
  String get reviewGuidance =>
      'Reviews help the community understand sellers. Please share your exchange experience.';

  @override
  String get submitReview => 'Submit review';

  @override
  String get reportListing => 'Report listing';

  @override
  String get reportUser => 'Report user';

  @override
  String get report => 'Report';

  @override
  String get reportReason => 'Report reason';

  @override
  String get inappropriateContent => 'Inappropriate content';

  @override
  String get suspectedFraud => 'Suspected fraud';

  @override
  String get prohibitedProduct => 'Prohibited product';

  @override
  String get misleadingInformation => 'Misleading information';

  @override
  String get spam => 'Spam';

  @override
  String get otherReason => 'Other reason';

  @override
  String get optionalDescription => 'Additional description (optional)';

  @override
  String get reportDescriptionHint => 'Add information to help us review...';

  @override
  String get submitReport => 'Submit report';

  @override
  String get reportSuccessTitle => 'Report submitted';

  @override
  String get reportSuccessDescription =>
      'Thank you for helping keep ReStore safe. Our moderation team will review this content.';

  @override
  String get goBack => 'Go back';

  @override
  String get reportedListingTitle => 'Canon AE-1 camera + 50mm lens';

  @override
  String get reportedListingMeta => 'Listing by Minh Anh · District 1';

  @override
  String get aiSampleCameraQuery => 'Find a film camera under 4 million';

  @override
  String get aiSampleGamingQuery => 'Find a gaming laptop under 15 million';

  @override
  String get aiSampleIphoneQuery => 'Find an old iPhone under 10 million';

  @override
  String get aiSampleStudentLaptopQuery => 'Find a laptop for students';

  @override
  String get aiStartOver => 'Start over';

  @override
  String get aiEmptyStateMenu => 'View empty state';

  @override
  String get aiErrorStateMenu => 'View error state';

  @override
  String get aiInputHint => 'Ask about products, price, area...';

  @override
  String get askRestoreAi => 'Ask ReStore AI';

  @override
  String get aiIntro =>
      'Describe what you need. AI will find and compare suitable ReStore listings.';

  @override
  String get quickPrompts => 'Quick prompts';

  @override
  String get sellerOwnsListings => 'Listings belong to sellers';

  @override
  String get sellerOwnsListingsDescription =>
      'Open a listing and contact the seller directly when interested.';

  @override
  String get continueConversation =>
      'You can continue asking in the same conversation';

  @override
  String get continueConversationTips =>
      '• Limit price and area\n• Choose brand or condition\n• Compare listing information';

  @override
  String get aiDefaultQuery => 'Find a film camera under 4 million in HCMC';

  @override
  String get aiResultsMessage =>
      'I found 2 matching film camera listings. Open either listing to see more.';

  @override
  String get aiFilteredMessage =>
      'I updated the results using your new request.';

  @override
  String get matchingListingsDemo => 'MATCHING LISTINGS · DEMO DATA';

  @override
  String get canonListingTitle => 'Canon AE-1 + 50mm lens';

  @override
  String get canonPrice => '2,450,000 đ';

  @override
  String get canonLocationTime => 'District 1 · 2 hours ago';

  @override
  String get nikonListingTitle => 'Nikon FM2 camera';

  @override
  String get nikonPrice => '3,800,000 đ';

  @override
  String get nikonLocationTime => 'District 10 · Yesterday';

  @override
  String get sellerDataCaveat =>
      'Price and condition are based on seller-provided information.';

  @override
  String get youCanAskNext => 'You can ask next:';

  @override
  String get canonOnly => 'Canon only';

  @override
  String get compareTheseTwo => 'Compare these two';

  @override
  String get comparisonMessage =>
      'I compared the information in these two ReStore listings.';

  @override
  String get canonVsNikon => 'Canon AE-1 and Nikon FM2';

  @override
  String get listing => 'Listing';

  @override
  String get price => 'Price';

  @override
  String get condition => 'Condition';

  @override
  String get area => 'Area';

  @override
  String get posted => 'Posted';

  @override
  String get goodCondition => 'Good';

  @override
  String get notSpecified => 'Not specified';

  @override
  String get twoHoursAgo => '2 hours ago';

  @override
  String get sellerInfoOnly => 'Based only on information provided by sellers.';

  @override
  String get viewCanon => 'View Canon →';

  @override
  String get viewNikon => 'View Nikon →';

  @override
  String get aiEmptyTitle => 'No matching listings';

  @override
  String get aiEmptyDescription =>
      'Try a wider area, a higher price range, or a shorter product description.';

  @override
  String get adjustRequest => 'Adjust request';

  @override
  String get aiErrorTitle => 'Unable to answer right now';

  @override
  String get aiErrorDescription =>
      'Your conversation is preserved. You can retry without entering it again.';

  @override
  String get retry => 'Retry';

  @override
  String featureApiPending(String action) {
    return '$action will be connected in the API phase.';
  }

  @override
  String get createListing => 'Create listing';

  @override
  String get editListing => 'Edit listing';

  @override
  String get close => 'Close';

  @override
  String get back => 'Back';

  @override
  String stepCount(int current, int total) {
    return '$current/$total';
  }

  @override
  String productPhotosCount(int count) {
    return 'Product photos · $count/10';
  }

  @override
  String get addPhotos => 'Add photos';

  @override
  String get firstPhotoHint =>
      'The first photo is the cover · Hold and drag to reorder';

  @override
  String get productName => 'Product name';

  @override
  String get category => 'Category';

  @override
  String get electronicsCamera => 'Electronics › Camera';

  @override
  String get newCondition => 'New';

  @override
  String get usedCondition => 'Used';

  @override
  String get photoTip =>
      'Tip: clear photos from multiple angles make your listing more trustworthy.';

  @override
  String get salePrice => 'Sale price';

  @override
  String get priceVndHint => 'Enter price in VND';

  @override
  String get negotiable => 'Negotiable';

  @override
  String get description => 'Description';

  @override
  String get location => 'Location';

  @override
  String get contactPreference => 'Preferred contact';

  @override
  String get phone => 'Phone';

  @override
  String get directArrangementNote =>
      'Buyers and sellers arrange delivery and payment themselves.';

  @override
  String get continueAction => 'Continue';

  @override
  String get preview => 'Preview';

  @override
  String get publishListing => 'Publish listing';

  @override
  String get boostListing => 'Boost listing';

  @override
  String get boostVisibilityTitle => 'Increase visibility';

  @override
  String get boostVisibilityDescription =>
      'Your listing is prioritized during the selected period. This does not guarantee a buyer.';

  @override
  String get selectBoostDuration => 'Choose boost duration';

  @override
  String get boost24Hours => 'Boost for 24 hours';

  @override
  String get boost3Days => 'Boost for 3 days';

  @override
  String get boost7Days => 'Boost for 7 days';

  @override
  String get visible24Hours => 'Priority visibility for 24 hours';

  @override
  String get visible3Days => 'Continuous priority visibility for 3 days';

  @override
  String get visible7Days => 'Continuous priority visibility for 7 days';

  @override
  String get boostPrice24 => '19,000 đ';

  @override
  String get boostPrice3Days => '49,000 đ';

  @override
  String get boostPrice7Days => '99,000 đ';

  @override
  String get boostDemoPriceNote =>
      'Demo service price · official pricing will be confirmed later.';

  @override
  String get confirmPromotionService => 'Confirm promotion service';

  @override
  String get currentListing => 'Current listing';

  @override
  String get listingVisibilityStatus => 'Visible · Current listing';

  @override
  String get boostPackage => 'Boost package';

  @override
  String get duration => 'Duration';

  @override
  String get serviceFee => 'Service fee';

  @override
  String get totalServiceFee => 'Total service fee';

  @override
  String get threeDays => '3 days';

  @override
  String get seventyTwoHours => '72 hours';

  @override
  String get restoreServiceFee => 'ReStore service fee';

  @override
  String get boostServiceBoundary =>
      'You are paying to promote your listing, not paying for the product. ReStore does not collect buyer-seller payments.';

  @override
  String get continuePayment => 'Continue to payment';

  @override
  String get servicePayment => 'Service payment';

  @override
  String get vnpay => 'VNPay';

  @override
  String get vnpayDescription => 'Pay the listing promotion fee through VNPay';

  @override
  String get confirmPayment => 'Confirm payment';

  @override
  String get paymentResult => 'Payment result';

  @override
  String get paymentSuccess => 'Payment successful';

  @override
  String get boostActivatedDescription =>
      'Your listing was boosted successfully';

  @override
  String get transactionDetails => 'Transaction details';

  @override
  String get transactionCode => 'Transaction code';

  @override
  String get transactionCodeValue => 'RST-BST-260925-0842';

  @override
  String get amount => 'Amount';

  @override
  String get boostPeriod => 'Boost period';

  @override
  String get paymentMethod => 'Payment method';

  @override
  String get viewListing => 'View listing';

  @override
  String get backToManageListings => 'Back to manage listings';

  @override
  String get activeBoost => 'Boost active';

  @override
  String get activeBoostDescription =>
      'This listing is being prioritized until the promotion ends.';

  @override
  String get expiredBoost => 'Boost expired';

  @override
  String get expiredBoostDescription =>
      'The promotion ended. Your listing remains publicly visible.';

  @override
  String get boostUnavailable => 'Boost unavailable';

  @override
  String get boostUnavailableDescription =>
      'Only active, approved listings can be boosted.';

  @override
  String get boostAgain => 'Boost again';

  @override
  String get boostPaymentFailed => 'Payment failed';

  @override
  String get boostPaymentCancelled => 'Payment cancelled';

  @override
  String get boostPaymentPending => 'Payment verification pending';

  @override
  String get tryPaymentAgain => 'Try payment again';

  @override
  String get manageListings => 'Manage listings';

  @override
  String get newListing => 'New listing';

  @override
  String get visibleStatus => 'Visible';

  @override
  String get pendingStatus => 'Pending';

  @override
  String get hiddenStatus => 'Hidden';

  @override
  String get soldStatus => 'Sold';

  @override
  String listingStatusCount(int count, String status) {
    return '$count $status';
  }

  @override
  String get editAction => 'Edit';

  @override
  String get hideListing => 'Hide';

  @override
  String get markAsSold => 'Mark as sold';

  @override
  String get deleteListing => 'Delete';

  @override
  String get showAgain => 'Show again';

  @override
  String get pendingStatusNote =>
      'This listing is being reviewed before it becomes visible.';

  @override
  String get hiddenStatusNote =>
      'This listing is hidden and buyers cannot find it in search results.';

  @override
  String get soldStatusNote =>
      'Sold listings no longer appear in search results.';

  @override
  String get markSoldTitle => 'Mark listing as sold?';

  @override
  String get markSoldDescription =>
      'The listing will no longer be available to buyers.';

  @override
  String get platformNoOrderPayment =>
      'This action does not create an order or transaction. ReStore does not process payment.';

  @override
  String get cancel => 'Cancel';

  @override
  String get homeTitle => 'Home';

  @override
  String get messagesTitle => 'Messages';

  @override
  String get listingDetailTitle => 'Listing details';

  @override
  String get listingPreviewTitle => 'Listing preview';

  @override
  String galleryPosition(int current, int total) {
    return '$current / $total';
  }

  @override
  String get listingLocationMeta =>
      '⌖ District 1, Ho Chi Minh City · Posted 2 hours ago';

  @override
  String get usedGoodCondition => 'Used · Good condition';

  @override
  String get productDescription => 'Product description';

  @override
  String get canonDescription =>
      'Canon AE-1 works well with an accurate light meter. Includes an FD 50mm f/1.8 lens, strap, and leather case. Available to inspect in District 1.';

  @override
  String get sellerRatingMeta => '★ 4.9 · 48 ratings · Quick response';

  @override
  String get similarListings => 'Similar listings';

  @override
  String get seeMore => 'See more ›';

  @override
  String get makeOffer => 'Make offer';

  @override
  String get chooseCategoryTitle => 'Choose category';

  @override
  String get chooseCategorySubtitle => 'What do you want to sell?';

  @override
  String get categoryElectronicsTitle => 'Electronics';

  @override
  String get categoryElectronicsDesc => 'Phones, Laptops, Cameras,...';

  @override
  String get categoryVehiclesTitle => 'Vehicles';

  @override
  String get categoryVehiclesDesc => 'Motorbikes, Bicycles, Cars, Parts,...';

  @override
  String get categoryFashionTitle => 'Fashion';

  @override
  String get categoryFashionDesc => 'Clothes, Shoes, Bags,...';

  @override
  String get categoryHomeTitle => 'Home Appliances';

  @override
  String get categoryHomeDesc => 'Furniture, Lighting, Kitchenware, Decor,...';

  @override
  String get step1Title => 'Photos & Product';

  @override
  String productPhotosInfo(int count) {
    return 'Product photos · $count/10';
  }

  @override
  String get coverImageHint =>
      'First photo is cover · Tap a photo to set as cover';

  @override
  String get productNameLabel => 'Product name';

  @override
  String get productNameMinLengthError =>
      'Product name must be at least 5 characters';

  @override
  String get categoryLabel => 'Category';

  @override
  String get conditionLabel => 'Condition';

  @override
  String get continueBtn => 'Continue';
}
