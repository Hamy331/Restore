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
  String get feedsTitle => 'Feeds';

  @override
  String get feedsComingSoon => 'Feeds are coming soon';

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
  String get categoryElectronicsDesc => 'Laptops, Cameras, Headphones,...';

  @override
  String get categoryVehiclesTitle => 'Vehicles';

  @override
  String get categoryVehiclesDesc => 'Motorbikes, Bicycles, Cars, Parts,...';

  @override
  String get categoryFashionTitle => 'Fashion';

  @override
  String get categoryFashionDesc => 'Clothes, Shoes, Bags,...';

  @override
  String get categoryHomeTitle => 'Household';

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

  @override
  String get completeListingTitle => 'Complete listing';

  @override
  String get saveDraft => 'Save draft';

  @override
  String get draftSaved => 'Draft saved';

  @override
  String listingPhotosLabel(int max) {
    return 'Photos (up to $max photos)';
  }

  @override
  String photoCount(int count, int max) {
    return '$count/$max';
  }

  @override
  String get coverPhotoBadge => 'Cover';

  @override
  String get photosRequiredError => 'Please add at least 1 photo';

  @override
  String get detailedDescriptionLabel => 'Detailed description';

  @override
  String get listingDescriptionHint =>
      '- Condition, how long it has been used\n- Included accessories, minor defects if any\n- Reason for selling, delivery method';

  @override
  String characterCount(int count, int max) {
    return '$count/$max characters';
  }

  @override
  String descriptionMinLengthError(int min) {
    return 'Description must be at least $min characters';
  }

  @override
  String get listingTitleLabel => 'Listing title';

  @override
  String get listingTitleHint => 'e.g. Piaggio Vespa Sprint 2024 15,000 km';

  @override
  String listingTitleMinLengthError(int min) {
    return 'Title must be at least $min characters';
  }

  @override
  String get priceRequiredError => 'Please enter a sale price';

  @override
  String get addressLabel => 'Address';

  @override
  String get youAreLabel => 'You are';

  @override
  String get sellerPersonal => 'Personal';

  @override
  String get sellerBusiness => 'Business';

  @override
  String get detailedInfoTitle => 'Detailed information';

  @override
  String categoryWithName(String name) {
    return 'Category: $name';
  }

  @override
  String get fieldRequiredError => 'Please fill in this field';

  @override
  String get fieldSelectRequiredError => 'Please select an option';

  @override
  String get missingRequiredFields => 'Please complete all required fields';

  @override
  String get listingSubmitted =>
      'Your listing has been submitted and is waiting for review';

  @override
  String get previewNotice => 'This is how buyers will see your listing';

  @override
  String get noPhotosYet => 'No photos yet';

  @override
  String get stepBasicInfoTitle => 'Photos, description & price';

  @override
  String get takePhoto => 'Take a photo';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String photoLimitReached(int max) {
    return 'You can add up to $max photos';
  }

  @override
  String get photoPickFailed =>
      'Couldn\'t open your photos. Please check the app\'s photo and camera permissions.';

  @override
  String get draftSaveFailed => 'Couldn\'t save the draft, please try again';

  @override
  String get publishFailed => 'Couldn\'t publish the listing, please try again';

  @override
  String get tradeTypeLabel => 'Trade type';

  @override
  String get tradeSell => 'Sell';

  @override
  String get tradeExchange => 'Exchange';

  @override
  String get tradeSellOrExchange => 'Both';

  @override
  String get tradeExchangeAccepted => 'Open to exchange';

  @override
  String get exchangeWishLabel => 'Want to exchange for';

  @override
  String get exchangeWishHint => 'e.g. iPhone 13 or a tablet';

  @override
  String get selectAddressHint => 'Choose an area';

  @override
  String get stepShortCategory => 'Category';

  @override
  String get stepShortBasicInfo => 'Basics';

  @override
  String get stepShortDetails => 'Details';

  @override
  String stepProgressLabel(int current, int total) {
    return 'Step $current/$total';
  }

  @override
  String nextStepLabel(String name) {
    return 'Next: $name';
  }

  @override
  String get conditionSectionTitle => 'Item condition';

  @override
  String get conditionNew => 'New';

  @override
  String get conditionLikeNew => 'Like new';

  @override
  String get conditionUsedGood => 'Used - good';

  @override
  String get conditionUsedFair => 'Used - fair';

  @override
  String get conditionForParts => 'For parts / not working';

  @override
  String get conditionNewDesc => 'Never used, original packaging';

  @override
  String get conditionLikeNewDesc => 'Barely used, no visible marks';

  @override
  String get conditionUsedGoodDesc => 'Works well, minor signs of use';

  @override
  String get conditionUsedFairDesc => 'Usable, visible wear or minor faults';

  @override
  String get conditionForPartsDesc => 'Does not work properly';

  @override
  String get categoryAttributesTitle => 'Category details';

  @override
  String get categoryAttributesHint => 'Fields below depend on the category';

  @override
  String get selectOptionHint => 'Select';

  @override
  String numberRangeError(String min, String max) {
    return 'Value must be between $min and $max';
  }

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get loadCategoriesFailedTitle => 'Couldn\'t load categories';

  @override
  String get loadCategoriesFailedMessage =>
      'Check your connection and try again';

  @override
  String get negotiableHint => 'Buyers can make offers in chat';

  @override
  String get addressNearbyHint => 'Helps nearby buyers find your listing';

  @override
  String privateStreetAddress(String street) {
    return '$street (private)';
  }

  @override
  String get addressSheetTitle => 'Item location';

  @override
  String get useCurrentLocation => 'Use my current location';

  @override
  String get useCurrentLocationHint =>
      'Fill in province and ward automatically';

  @override
  String get locatingLabel => 'Getting your location...';

  @override
  String get locationDetected => 'Location detected';

  @override
  String get orChooseManually => 'or choose manually';

  @override
  String get provinceLabel => 'Province/City';

  @override
  String get selectProvinceHint => 'Select province/city';

  @override
  String get wardLabel => 'Ward/Commune';

  @override
  String get selectWardHint => 'Select ward/commune';

  @override
  String get selectProvinceFirst => 'Select a province first';

  @override
  String get streetAddressLabel => 'House number, street';

  @override
  String get streetAddressHint => 'e.g. 12 Nguyen Hue';

  @override
  String get streetAddressHelper => 'Optional, never shown publicly';

  @override
  String get addressPrivacyNote =>
      'Buyers only see the ward and province. Your location is used to show listings near you.';

  @override
  String get confirmAddress => 'Confirm address';

  @override
  String get loadingLocations => 'Loading...';

  @override
  String get loadLocationsFailed => 'Couldn\'t load the list, tap to retry';

  @override
  String get locationServiceDisabled => 'Turn on location services to continue';

  @override
  String get locationPermissionDenied => 'Location permission was denied';

  @override
  String get locationPermissionDeniedForever =>
      'Location access is blocked, enable it in Settings';

  @override
  String get locationUnavailable =>
      'Couldn\'t get your location, please choose manually';

  @override
  String get locationOutOfCoverage =>
      'Your location didn’t match any ward. Please choose it manually below.';

  @override
  String get searchOptionHint => 'Search';

  @override
  String get noMatchingOptions => 'No matching results';

  @override
  String get locationOutsideVietnamTitle => 'Looks like you’re outside Vietnam';

  @override
  String get locationOutsideVietnamBody =>
      'ReStore only supports addresses in Vietnam for now. Please pick your province and ward below.';

  @override
  String get locationOutOfCoverageTitle => 'We don’t recognise this area yet';

  @override
  String get aiBubbleTooltip => 'Chat with ReStore AI';

  @override
  String unreadMessagesCount(int count) {
    return '$count unread messages';
  }

  @override
  String get homeGreeting => 'Hi there 👋';

  @override
  String get homeHeadline => 'What are you hunting for today?';

  @override
  String get homeSearchHint => 'Search pre-loved and swap items...';

  @override
  String get homeChangeArea => 'Change area';

  @override
  String get homeForYouTitle => 'Picked for you';

  @override
  String get homeLatestTitle => 'Fresh listings';

  @override
  String get homeSeeAll => 'See all';

  @override
  String get homeFeaturedTag => 'Featured';

  @override
  String get homeExchangeTag => 'Swappable';

  @override
  String get homeExchangeOnly => 'Swap only';

  @override
  String get homeSaveListing => 'Save listing';

  @override
  String get homeUnsaveListing => 'Remove from saved';

  @override
  String get homeLoadErrorTitle => 'Couldn\'t load the home page';

  @override
  String get homeLoadErrorBody => 'Check your connection and try again.';

  @override
  String get timeJustNow => 'Just now';

  @override
  String timeMinutesAgo(int count) {
    return '$count min ago';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count h ago';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count d ago';
  }

  @override
  String get featureComingSoon => 'This feature is coming soon';

  @override
  String homeGreetingName(String name) {
    return 'Hi there, $name 👋';
  }

  @override
  String get homeLatestEmpty => 'No listings here yet';

  @override
  String get homeEndOfList => 'You\'re all caught up';

  @override
  String get homeQuickNearby => 'Near me';

  @override
  String get homeQuickNearbyDesc => 'Within 5 km';

  @override
  String get homeQuickWanted => 'Wanted alerts';

  @override
  String get homeQuickWantedDesc => 'Get notified when listed';

  @override
  String get homeQuickTrustedShops => 'Trusted shops';

  @override
  String get homeQuickTrustedShopsDesc => 'Verified and top rated';

  @override
  String get homeQuickFollowing => 'Following';

  @override
  String get homeQuickFollowingDesc => 'Shops and people you follow';

  @override
  String get homeBannerTooltip => 'Promotion banner';

  @override
  String get productDetailTitle => 'Product details';

  @override
  String get productLoadErrorTitle => 'Couldn\'t load this listing';

  @override
  String get productLoadErrorBody =>
      'The listing may have been removed, or your connection is unstable. Please try again.';

  @override
  String productViewCount(int count) {
    return '$count views';
  }

  @override
  String get productUnavailableHint => 'This item can no longer be bought.';

  @override
  String get listingStatusDraft => 'Draft';

  @override
  String get listingStatusPending => 'Pending review';

  @override
  String get listingStatusAvailable => 'Available';

  @override
  String get listingStatusReserved => 'Reserved';

  @override
  String get listingStatusSold => 'Sold';

  @override
  String get listingStatusExchanged => 'Exchanged';

  @override
  String get listingStatusExpired => 'Expired';

  @override
  String get listingStatusRejected => 'Rejected';

  @override
  String get listingStatusHidden => 'Hidden';

  @override
  String get productSellerTitle => 'Seller';

  @override
  String get productSellerVerified => 'Verified';

  @override
  String get productSellerNoReviews => 'No reviews yet';

  @override
  String productSellerJoined(String date) {
    return 'Joined $date';
  }

  @override
  String productSellerListings(int count) {
    return '$count listings';
  }

  @override
  String get productSellerProfile => 'View profile';

  @override
  String get productReadMore => 'Show more';

  @override
  String get productReadLess => 'Show less';

  @override
  String get productSafetyTitle => 'Shop safely';

  @override
  String get productSafetyBody =>
      'Meet in a public place, check the item before paying and never send a deposit to someone you don\'t know.';

  @override
  String get productReport => 'Report listing';

  @override
  String get productChat => 'Chat';

  @override
  String get productMakeOffer => 'Make offer';

  @override
  String get productBuyNow => 'Buy now';

  @override
  String get productProposeExchange => 'Propose a swap';

  @override
  String get productEditListing => 'Edit listing';

  @override
  String get productBoost => 'Boost';

  @override
  String get productOfferTitle => 'Make an offer';

  @override
  String productOfferSubtitle(String price) {
    return 'Listed at $price';
  }

  @override
  String get productOfferAmountLabel => 'Your offer';

  @override
  String get productOfferAmountHint => 'Enter an amount';

  @override
  String get productOfferInvalid => 'Enter an amount greater than 0';

  @override
  String get productOfferTooHigh =>
      'Your offer can be at most twice the asking price';

  @override
  String get productOfferSubmit => 'Send offer';

  @override
  String get productOfferSent =>
      'Offer sent. Continue the conversation with the seller here.';

  @override
  String productOfferBelow(String percent, String difference) {
    return '$percent below the asking price (-$difference)';
  }

  @override
  String productOfferAbove(String percent, String difference) {
    return '$percent above the asking price (+$difference)';
  }

  @override
  String get productOfferEqual => 'Same as the asking price';

  @override
  String get productLiveTitle => 'Listing just updated';

  @override
  String productLiveUnavailable(String status) {
    return 'This item is now $status and can no longer be ordered.';
  }

  @override
  String get productLiveAvailable => 'This item is available again.';

  @override
  String productLivePrice(String previous, String current) {
    return 'The seller changed the price from $previous to $current.';
  }

  @override
  String get productLivePriceGeneric =>
      'The seller updated the price, please review before sending.';

  @override
  String get productLiveInfo => 'The seller just edited this listing.';

  @override
  String get productLiveIndicator => 'Live updates on';

  @override
  String get productBuyTitle => 'Request to buy';

  @override
  String get productBuySubtitle =>
      'The seller confirms and arranges the handover with you in chat.';

  @override
  String get productBuyPriceLabel => 'Price';

  @override
  String get productBuyNoteLabel => 'Note for the seller';

  @override
  String get productBuyNoteHint => 'e.g. I can pick it up this evening';

  @override
  String get productBuySubmit => 'Send request';

  @override
  String get productBuySent =>
      'Purchase request sent. The seller will reply in chat.';

  @override
  String get productActionFailed => 'Couldn\'t send. Please try again.';

  @override
  String get galleryOpenFullscreen => 'View photos full screen';

  @override
  String get nearbyTitle => 'Near me';

  @override
  String get nearbySubtitle =>
      'Pre-loved finds around you, meet up and grab them';

  @override
  String get nearbyCurrentLocation => 'Current location';

  @override
  String get nearbyLocating => 'Finding your location...';

  @override
  String get nearbyChangeLocation => 'Change';

  @override
  String get nearbyRelocate => 'Update location';

  @override
  String get nearbyFilters => 'Filters';

  @override
  String nearbyRadiusChip(String distance) {
    return 'Within $distance';
  }

  @override
  String get nearbyRadiusTitle => 'Search radius';

  @override
  String nearbyRadiusOption(String distance) {
    return 'Within $distance';
  }

  @override
  String get listingDealBuy => 'Buy now';

  @override
  String get listingDealExchange => 'Swap';

  @override
  String get listingSortTitle => 'Sort by';

  @override
  String get listingSortNearest => 'Nearest';

  @override
  String get listingSortNewest => 'Newest';

  @override
  String get listingSortPriceLow => 'Price: low to high';

  @override
  String get listingSortPriceHigh => 'Price: high to low';

  @override
  String get nearbyFallbackTitle => 'Showing listings around your default area';

  @override
  String get nearbyUseMyLocation => 'Use my location';

  @override
  String get nearbyOpenSettings => 'Open Settings';

  @override
  String get nearbyEmptyTitle => 'Nothing nearby yet';

  @override
  String get nearbyEmptyBody => 'Try a wider radius or fewer filters.';

  @override
  String nearbyExpandRadius(String distance) {
    return 'Expand to $distance';
  }

  @override
  String get nearbyLoadErrorTitle => 'Couldn\'t load nearby listings';

  @override
  String get nearbyLoadErrorBody => 'Check your connection and try again.';

  @override
  String get nearbyEndOfList => 'You\'ve seen everything nearby';

  @override
  String distanceMeters(int meters) {
    return '$meters m';
  }

  @override
  String distanceKm(String km) {
    return '$km km';
  }

  @override
  String get listingSortRelevance => 'Most relevant';

  @override
  String get searchNearMe => 'Near me';

  @override
  String get searchNearMeSubtitle => 'Browse pre-loved items around you';

  @override
  String get searchTipsTitle => 'Quick search ideas';

  @override
  String get searchHistoryTitle => 'Recent searches';

  @override
  String get searchClearHistory => 'Clear all';

  @override
  String get searchRemoveHistory => 'Remove from list';

  @override
  String get searchFillQuery => 'Use in search box';

  @override
  String get searchClearInput => 'Clear';

  @override
  String searchForQuery(String query) {
    return 'Search “$query”';
  }

  @override
  String searchEmptyTitle(String query) {
    return 'No results for “$query”';
  }

  @override
  String get searchEmptyBody =>
      'Try a shorter or different keyword, or remove some filters.';

  @override
  String get searchTryAnother => 'Change keyword';

  @override
  String get searchLoadErrorTitle => 'Couldn\'t load results';

  @override
  String get searchLoadErrorBody => 'Check your connection and try again.';

  @override
  String get searchEndOfList => 'You\'ve seen all results';

  @override
  String get areaSearchHint => 'Search ward or province...';

  @override
  String get areaMyLocationSubtitle => 'Use your current GPS location';

  @override
  String get areaRecentTitle => 'Recently chosen areas';

  @override
  String get areaWholeProvince => 'Whole province / city';

  @override
  String get areaNoResultsTitle => 'No matching area';

  @override
  String get areaNoResultsBody => 'Try another ward or province name.';

  @override
  String get areaSearchErrorTitle => 'Couldn\'t search areas';

  @override
  String get listingFilterTitle => 'Filters';

  @override
  String get listingFilterCategory => 'Category';

  @override
  String get listingFilterAllCategories => 'All';

  @override
  String get listingFilterCategoryError => 'Couldn\'t load categories';

  @override
  String get listingFilterPrice => 'Price range';

  @override
  String get listingFilterPriceMin => 'Min price';

  @override
  String get listingFilterPriceMax => 'Max price';

  @override
  String get listingFilterPriceAny => 'Any';

  @override
  String get listingFilterPriceHelper =>
      'Exchange-only listings (no price) are hidden when filtering by price.';

  @override
  String get listingFilterPriceInvalid => 'Min price is higher than max price.';

  @override
  String listingFilterPriceUnder(String price) {
    return 'Under $price';
  }

  @override
  String listingFilterPriceOver(String price) {
    return 'Over $price';
  }

  @override
  String listingFilterPriceBetween(String min, String max) {
    return '$min – $max';
  }

  @override
  String get listingFilterCondition => 'Condition';

  @override
  String get listingFilterDeal => 'Deal type';

  @override
  String get listingFilterDistance => 'Distance';

  @override
  String get listingFilterReset => 'Clear all';

  @override
  String get listingFilterApply => 'Apply';

  @override
  String listingFilterApplyCount(int count) {
    return 'Apply ($count)';
  }

  @override
  String priceThousands(String value) {
    return '${value}K';
  }

  @override
  String priceMillions(String value) {
    return '${value}M';
  }

  @override
  String get categoryDetailSearch => 'Search';

  @override
  String get categoryDetailEmptyTitle => 'No listings in this category yet';

  @override
  String get categoryDetailEmptyBody =>
      'Be the first to post something in this category.';

  @override
  String get categoryDetailPostListing => 'Post a listing';

  @override
  String get categoryDetailFilteredEmptyTitle =>
      'No listings match your filters';

  @override
  String get categoryDetailFilteredEmptyBody =>
      'Try removing some filters to see more listings.';

  @override
  String get categoryDetailLoadErrorTitle => 'Couldn\'t load this category';

  @override
  String get categoryDetailLoadErrorBody =>
      'Check your connection and try again.';

  @override
  String get categoryDetailEndOfList =>
      'You\'ve seen every listing in this category';

  @override
  String get wantedAlertTitle => 'Wanted alerts';

  @override
  String get wantedAlertSubtitle =>
      'Reserve what you need, get notified when it is posted';

  @override
  String wantedAlertActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count active alerts',
      one: '1 active alert',
    );
    return '$_temp0';
  }

  @override
  String get wantedAlertCreate => 'Create alert';

  @override
  String get wantedAlertNew => 'New alert';

  @override
  String get wantedAlertEmptyTitle => 'No alerts yet';

  @override
  String get wantedAlertEmptyBody =>
      'Tell us what you are looking for and ReStore will notify you as soon as something similar is posted.';

  @override
  String get wantedAlertLoadErrorTitle => 'Couldn\'t load your alerts';

  @override
  String get wantedAlertLoadErrorBody => 'Check your connection and try again.';

  @override
  String wantedAlertNewMatches(int count) {
    return '$count new';
  }

  @override
  String wantedAlertMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matches',
      one: '1 match',
    );
    return '$_temp0';
  }

  @override
  String get wantedAlertNoMatchYet => 'No matches yet';

  @override
  String wantedAlertLastMatched(String time) {
    return 'Last match $time';
  }

  @override
  String wantedAlertCreatedAt(String time) {
    return 'Created $time';
  }

  @override
  String get wantedAlertWatching => 'Watching';

  @override
  String get wantedAlertAnyCategory => 'Any category';

  @override
  String get wantedAlertNationwide => 'Nationwide';

  @override
  String get wantedAlertAnyPrice => 'Any price';

  @override
  String get wantedAlertAnyCondition => 'Any condition';

  @override
  String get wantedAlertAnyDeal => 'Buy or exchange';

  @override
  String wantedAlertPriceFrom(String price) {
    return 'From $price';
  }

  @override
  String wantedAlertPriceUpTo(String price) {
    return 'Up to $price';
  }

  @override
  String wantedAlertPriceRange(String min, String max) {
    return '$min – $max';
  }

  @override
  String get wantedAlertDelete => 'Delete alert';

  @override
  String get wantedAlertDeleteTitle => 'Delete this alert?';

  @override
  String wantedAlertDeleteBody(String keywords) {
    return 'ReStore will stop notifying you about “$keywords”. You can create it again anytime.';
  }

  @override
  String get wantedAlertKeep => 'Keep';

  @override
  String get wantedAlertDeleted =>
      'Alert deleted. You won\'t get new matches for it anymore.';

  @override
  String get wantedAlertDeleteError =>
      'Couldn\'t delete the alert. Please try again.';

  @override
  String get wantedAlertSearchHint => 'What are you looking for?';

  @override
  String get wantedAlertIntroTitle => 'Search first, get alerted later';

  @override
  String get wantedAlertIntroStep1 =>
      'Type what you need and ReStore shows similar listings right away.';

  @override
  String get wantedAlertIntroStep2 =>
      'Found a good one? Open it now, no need to wait.';

  @override
  String get wantedAlertIntroStep3 =>
      'Nothing yet? Create an alert and get a link as soon as a similar listing appears.';

  @override
  String get wantedAlertSkipToCompose => 'Skip, write the alert';

  @override
  String wantedAlertSuggestionsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count similar listings available',
      one: '1 similar listing available',
    );
    return '$_temp0';
  }

  @override
  String get wantedAlertSuggestionsHint =>
      'None of these? Create an alert to hear about new ones.';

  @override
  String get wantedAlertSuggestionsEmptyTitle => 'Nothing similar yet';

  @override
  String get wantedAlertSuggestionsEmptyBody =>
      'Create an alert and ReStore will tell you as soon as someone posts it.';

  @override
  String get wantedAlertSuggestionsErrorTitle => 'Couldn\'t load suggestions';

  @override
  String get wantedAlertSuggestionsErrorBody =>
      'You can still create the alert now.';

  @override
  String wantedAlertMatchPercent(int percent) {
    return '$percent% match';
  }

  @override
  String get wantedAlertNotRightCta => 'Not it? Create an alert';

  @override
  String get wantedAlertComposeTitle => 'Set up your alert';

  @override
  String get wantedAlertComposeSubtitle =>
      'When a similar listing is posted, ReStore sends you a link to it.';

  @override
  String get wantedAlertKeywordsLabel => 'What you want';

  @override
  String get wantedAlertKeywordsHint => 'e.g. Canon AE-1 film camera';

  @override
  String get wantedAlertKeywordsHelper =>
      'Name, brand or model. It doesn\'t have to be exact, similar listings count too.';

  @override
  String wantedAlertKeywordsError(int min) {
    return 'Enter at least $min characters';
  }

  @override
  String get wantedAlertCriteriaTitle => 'Criteria (optional)';

  @override
  String get wantedAlertCriteriaCategory => 'Category';

  @override
  String get wantedAlertCriteriaPrice => 'Price range';

  @override
  String get wantedAlertCriteriaCondition => 'Condition';

  @override
  String get wantedAlertCriteriaDeal => 'Deal type';

  @override
  String get wantedAlertCriteriaArea => 'Area';

  @override
  String get wantedAlertEditCriteria => 'Edit criteria';

  @override
  String get wantedAlertLevelTitle => 'How close';

  @override
  String get wantedAlertLevelBroad => 'Broad';

  @override
  String get wantedAlertLevelBalanced => 'Balanced';

  @override
  String get wantedAlertLevelStrict => 'Close';

  @override
  String get wantedAlertLevelBroadDesc =>
      'Includes loosely similar listings, so you get more alerts.';

  @override
  String get wantedAlertLevelBalancedDesc =>
      'Most keywords must match, small typos are fine.';

  @override
  String get wantedAlertLevelStrictDesc =>
      'Only listings that are almost exactly what you typed.';

  @override
  String get wantedAlertPreviewTitle => 'Listings matching right now';

  @override
  String get wantedAlertPreviewEmpty =>
      'Nothing matches right now. You\'ll be notified when something is posted.';

  @override
  String get wantedAlertPreviewNeedKeywords =>
      'Enter what you want to preview matching listings.';

  @override
  String get wantedAlertSave => 'Turn on alert';

  @override
  String wantedAlertCreated(String keywords) {
    return 'Alert on for “$keywords”. ReStore will notify you when something similar is posted.';
  }

  @override
  String get wantedAlertCreateError =>
      'Couldn\'t create the alert. Please try again.';

  @override
  String get wantedAlertNewTag => 'New';

  @override
  String get wantedAlertMatchesTitle => 'Matched listings';

  @override
  String get wantedAlertMatchesEmptyTitle => 'No matches yet';

  @override
  String get wantedAlertMatchesEmptyBody =>
      'When someone posts something similar, ReStore notifies you and it shows up here.';

  @override
  String get wantedAlertEndOfList => 'You\'ve seen every match';

  @override
  String get wantedAlertPromptTitle => 'Not finding it?';

  @override
  String wantedAlertPromptBody(String query) {
    return 'Set an alert for “$query” and ReStore will tell you when something similar is posted.';
  }

  @override
  String get areaNationwide => 'Nationwide';

  @override
  String get areaNationwideSubtitle => 'Any area, listings from anywhere';

  @override
  String get trustedShopsTitle => 'Trusted shops';

  @override
  String get trustedShopsSubtitle => 'Genuine stores verified by ReStore';

  @override
  String get trustedShopsAllCategories => 'All';

  @override
  String get trustedShopsOfficialTitle => 'Official brands';

  @override
  String get trustedShopsCertifiedTitle => 'ReStore certified';

  @override
  String get trustedShopsShowcaseTitle => 'Shop by brand';

  @override
  String get trustedShopsShowcaseSubtitle =>
      'Picks from the most followed shops';

  @override
  String get trustedShopsViewShop => 'View shop';

  @override
  String get trustedShopsAllProductsTitle => 'All products';

  @override
  String get trustedShopsAllProductsSubtitle => 'From every verified shop';

  @override
  String get trustedShopsEndOfList =>
      'You\'ve seen every product from trusted shops';

  @override
  String get trustedShopsEmptyTitle => 'No trusted shops here yet';

  @override
  String get trustedShopsEmptyBody =>
      'Verified shops in this category will show up here.';

  @override
  String get trustedShopsLoadErrorTitle => 'Couldn\'t load trusted shops';

  @override
  String get trustedShopsLoadErrorBody =>
      'Check your connection and try again.';

  @override
  String get trustedShopsFamousTitle => 'Famous brands';

  @override
  String get trustedShopsFamousSubtitle => 'Official stores of big-name brands';

  @override
  String get trustedShopsDealsTitle => 'Luxury for less';

  @override
  String get trustedShopsDealsSubtitle => 'Genuine brand products, now on sale';

  @override
  String trustedShopsDealsUpTo(int percent) {
    return 'Up to -$percent%';
  }

  @override
  String get trustedShopsNewReleasesTitle => 'Hot new releases';

  @override
  String get trustedShopsNewReleasesSubtitle =>
      'Fresh launches from famous brands';

  @override
  String get trustedShopsNewReleaseTag => 'Just launched';

  @override
  String trustedShopsLaunchedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Launched $count days ago',
      one: 'Launched yesterday',
      zero: 'Launched today',
    );
    return '$_temp0';
  }

  @override
  String get trustedShopsNewShopsTitle => 'New stores';

  @override
  String get trustedShopsNewShopsSubtitle => 'Shops ReStore verified recently';

  @override
  String get trustedShopsNavFamous => 'Brands';

  @override
  String get trustedShopsNavDeals => 'Deals';

  @override
  String get trustedShopsNavNewReleases => 'New releases';

  @override
  String get trustedShopsNavNewShops => 'New stores';

  @override
  String get trustedShopsNavShowcases => 'By brand';

  @override
  String get trustedShopsNavAll => 'All products';

  @override
  String get trustedShopsSeeAll => 'See all';

  @override
  String get trustedShopsOnSaleFilter => 'On sale';

  @override
  String get shopDetailEventsTitle => 'Shop events';

  @override
  String get shopDetailEventsSubtitle => 'Promotions approved by ReStore';

  @override
  String get shopVerificationOfficial => 'Official';

  @override
  String get shopVerificationCertified => 'Certified';

  @override
  String get shopVerificationOfficialDesc =>
      'The brand\'s own store or its authorised distributor, selling genuine goods with brand warranty.';

  @override
  String get shopVerificationCertifiedDesc =>
      'ReStore checked this shop\'s business licence, address and trading history before certifying it.';

  @override
  String get shopVerificationSheetTitle => 'About verified shops';

  @override
  String get shopVerificationSheetSubtitle =>
      'Only shops that pass one of these checks appear in Trusted shops';

  @override
  String get shopVerificationSheetNote =>
      'ReStore reviews verified shops regularly and removes the badge if a shop breaks the rules or gets repeated complaints.';

  @override
  String get shopCertificateTitle => 'Shop certificate';

  @override
  String get shopCertificateCode => 'Certificate no.';

  @override
  String get shopVerifiedSince => 'Verified on';

  @override
  String shopVerifiedSinceShort(String date) {
    return 'Verified $date';
  }

  @override
  String get shopFollow => 'Follow';

  @override
  String get shopFollowing => 'Following';

  @override
  String shopFollowerCount(String count) {
    return '$count followers';
  }

  @override
  String shopListingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count products',
      one: '1 product',
    );
    return '$_temp0';
  }

  @override
  String shopRatingCount(String count) {
    return '$count reviews';
  }

  @override
  String get shopFollowersLabel => 'Followers';

  @override
  String get shopProductsLabel => 'Products';

  @override
  String get shopDescriptionMore => 'Show more';

  @override
  String get shopDescriptionLess => 'Show less';

  @override
  String get shopDetailProductsTitle => 'Products for sale';

  @override
  String get shopDetailEmptyTitle => 'No products yet';

  @override
  String get shopDetailEmptyBody =>
      'Follow this shop to hear about new products first.';

  @override
  String get shopDetailEndOfList => 'You\'ve seen every product from this shop';

  @override
  String get shopDetailLoadErrorTitle => 'Couldn\'t load this shop';

  @override
  String get shopDetailLoadErrorBody => 'Check your connection and try again.';
}
