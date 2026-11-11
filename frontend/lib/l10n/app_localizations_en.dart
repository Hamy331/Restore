// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get feedForYou => 'For you';

  @override
  String get feedFollowing => 'Following';

  @override
  String get feedCompose => 'Share a find or a story…';

  @override
  String get feedFollow => 'Follow';

  @override
  String get feedUnfollow => 'Unfollow';

  @override
  String get feedPost => 'Post';

  @override
  String get feedNewPost => 'Create a community post';

  @override
  String get feedTextHint => 'What would you like to share?';

  @override
  String get feedAddPhoto => 'Add photo';

  @override
  String get feedTakePhoto => 'Take photo';

  @override
  String get feedRemovePhoto => 'Remove photo';

  @override
  String get feedComments => 'Comments';

  @override
  String get feedCommentHint => 'Write a comment…';

  @override
  String get feedSend => 'Send comment';

  @override
  String get feedLike => 'Like';

  @override
  String get feedUnlike => 'Unlike';

  @override
  String get feedEmpty => 'No posts yet';

  @override
  String get feedFollowingEmpty => 'Follow an author to see their posts here.';

  @override
  String get feedLoadError => 'Couldn\'t load the feed.';

  @override
  String get feedActionError => 'Something went wrong. Please try again.';

  @override
  String get feedPublishError =>
      'Couldn\'t publish your post. Please try again.';

  @override
  String get feedPhotoError => 'Couldn\'t select a photo. Please try again.';

  @override
  String get feedYourName => 'You';

  @override
  String get feedNoComments => 'Be the first to comment.';

  @override
  String get feedNotifications => 'Notifications are coming soon.';

  @override
  String get feedNow => 'Just now';

  @override
  String feedMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String feedHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String feedDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String feedLikes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count likes',
      one: '1 like',
    );
    return '$_temp0';
  }

  @override
  String feedCommentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comments',
      one: '1 comment',
    );
    return '$_temp0';
  }

  @override
  String get settingsPageTitle => 'Settings';

  @override
  String get settingsLanguage => 'App language';

  @override
  String get settingsLanguageHint =>
      'Choose the interface language. User posts keep their original language.';

  @override
  String get settingsLanguageError =>
      'Couldn\'t save your language preference.';

  @override
  String get feedRequired => 'Add text or a photo before posting.';

  @override
  String get feedDraftLimit => 'Up to 2,000 characters';

  @override
  String get feedDelete => 'Delete post';

  @override
  String get feedDeleteConfirm => 'Delete this post? This can\'t be undone.';

  @override
  String get feedDeleted => 'Post deleted';

  @override
  String get feedReport => 'Report post';

  @override
  String get feedReportTitle => 'Why are you reporting this post?';

  @override
  String get feedReportSpam => 'Spam or advertising';

  @override
  String get feedReportScam => 'Scam or fraud';

  @override
  String get feedReportOffensive => 'Offensive content';

  @override
  String get feedReportOther => 'Something else';

  @override
  String get feedReported => 'Report sent. Thank you!';

  @override
  String get feedViewProfile => 'View profile';

  @override
  String get feedLoadMoreError => 'Couldn\'t load more posts.';

  @override
  String get feedDiscardTitle => 'Discard post?';

  @override
  String get feedDiscardBody => 'What you\'ve written will be lost.';

  @override
  String get feedDiscard => 'Discard';

  @override
  String get feedKeepEditing => 'Keep editing';

  @override
  String feedCharCount(int count) {
    return '$count/2,000';
  }

  @override
  String get feedCloseImage => 'Close image';

  @override
  String get accEditPage => 'Edit profile';

  @override
  String get accMenu => 'Menu and settings';

  @override
  String get accLoadError => 'Couldn\'t load your profile. Tap to retry';

  @override
  String get accLoading => 'Loading…';

  @override
  String get accFollowing => 'Following';

  @override
  String get accFollowers => 'Followers';

  @override
  String get accListings => 'Listings';

  @override
  String get accPosts => 'Posts';

  @override
  String get accAddBio => '＋  Add a bio';

  @override
  String accRating(String rating, int count) {
    return '$rating ($count reviews)';
  }

  @override
  String get accNoRating => 'No reviews yet';

  @override
  String accTabVisible(int count) {
    return 'ACTIVE ($count)';
  }

  @override
  String accTabPending(int count) {
    return 'PENDING ($count)';
  }

  @override
  String accTabHidden(int count) {
    return 'HIDDEN ($count)';
  }

  @override
  String get accEmptyVisible => 'You have no active listings';

  @override
  String get accEmptyPending => 'No listings awaiting review';

  @override
  String get accEmptyHidden => 'No hidden listings';

  @override
  String get accPostListing => 'Post a listing';

  @override
  String accPosted(String time) {
    return 'Posted $time';
  }

  @override
  String accViews(int count) {
    return '$count views';
  }

  @override
  String get accHide => 'Hide';

  @override
  String get accShow => 'Show';

  @override
  String get accBoost => 'Boost';

  @override
  String get accLoadListingsError => 'Couldn\'t load your listings.';

  @override
  String get accUpdateListingError => 'Couldn\'t update the listing.';

  @override
  String get accLogout => 'Log out';

  @override
  String get accLogoutConfirm => 'Log out of ReStore?';

  @override
  String get accCloseMenu => 'Close menu';

  @override
  String get accEditTitle => 'Edit profile';

  @override
  String get accDisplayName => 'Display name';

  @override
  String get accUsername => 'Username';

  @override
  String get accBio => 'Bio';

  @override
  String get accSave => 'Save';

  @override
  String get accChangeAvatar => 'Change photo';

  @override
  String get accRemoveAvatar => 'Remove photo';

  @override
  String get accNameRequired => 'Enter a display name.';

  @override
  String get accUsernameInvalid =>
      '3–30 characters: lowercase letters, numbers, dots or underscores.';

  @override
  String get accUsernameTaken => 'This username is already taken.';

  @override
  String get accSaveError => 'Couldn\'t save your profile. Please try again.';

  @override
  String get accAvatarUploadError =>
      'Couldn\'t upload the photo. Please try again.';

  @override
  String get accUserNotFound => 'User not found.';

  @override
  String get accFollowListEmpty => 'No one here yet';

  @override
  String get accComingSoon => 'This feature is under development';

  @override
  String get accActivity => 'Activity';

  @override
  String get accProPlan => 'Account plan';

  @override
  String get accCreateStore => 'Create a store';

  @override
  String get accCoins => 'ReStore Points';

  @override
  String get accSaved => 'Profile saved';

  @override
  String get accSavedSearches => 'Saved searches';

  @override
  String get accRecentlyViewed => 'Recently viewed';

  @override
  String get accMyReviews => 'My reviews';

  @override
  String get accTransactions => 'Transaction history';

  @override
  String get accStores => 'Stores / brand pages';

  @override
  String get accHelp => 'Help';

  @override
  String get accFeedback => 'Send feedback';

  @override
  String get accEdit => 'Edit';

  @override
  String get accMoreOptions => 'More options';

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
  String memberSince(String year) {
    return 'Member since $year';
  }

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
  String get streetSuggestionsTitle => 'Suggested addresses';

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
  String get homeAreaLocating => 'Locating...';

  @override
  String get homeForYouTitle => 'Picked for you';

  @override
  String get homeLatestTitle => 'Fresh listings';

  @override
  String get homeSeeAll => 'See all';

  @override
  String get homeFeaturedTag => 'Hot';

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

  @override
  String get postingQuotaPersonalTitle => 'Personal account';

  @override
  String postingQuotaBannerMessage(int min, int max, int days) {
    return 'Free listings per category: $min to $max active at a time. Each listing stays up for $days days.';
  }

  @override
  String get postingRulesAction => 'View rules';

  @override
  String postingQuotaUsage(int used, int limit) {
    return '$used/$limit used';
  }

  @override
  String postingQuotaFull(int limit) {
    return 'Limit of $limit reached';
  }

  @override
  String get postingQuotaLastSlot => '1 slot left';

  @override
  String postingQuotaRemainingInCategory(int remaining, int limit) {
    return '$remaining/$limit slots left in this category';
  }

  @override
  String get postingLimitTitle => 'Category limit reached';

  @override
  String postingLimitMessage(int limit, String category) {
    return 'Personal accounts can have up to $limit active listings in $category. Free up a slot to post a new one.';
  }

  @override
  String get postingLimitWaysTitle => 'How to free a slot';

  @override
  String get postingLimitTipSold => 'Mark items you have sold as Sold';

  @override
  String get postingLimitTipHide => 'Hide listings you no longer want to sell';

  @override
  String postingLimitTipExpire(int days) {
    return 'Listings expire after $days days and free their slot';
  }

  @override
  String get manageMyListings => 'Manage my listings';

  @override
  String get chooseAnotherCategory => 'Other category';

  @override
  String get postingRulesTitle => 'Posting rules';

  @override
  String get postingRulesSubtitle => 'For personal sellers';

  @override
  String postingRuleLimit(int min, int max) {
    return '$min to $max free active listings per category, depending on the category. High-value items such as phones and vehicles get 1.';
  }

  @override
  String get postingRuleCounted =>
      'Only active and pending listings count. Sold, hidden or expired listings do not.';

  @override
  String postingRuleDuration(int days) {
    return 'Each listing is shown for $days days after it is approved.';
  }

  @override
  String get postingRuleFree =>
      'Posting is free. Every listing is reviewed before it goes live.';

  @override
  String get postingRulePersonalUse =>
      'Personal accounts are for selling your own used items. If you post many items regularly like a business, ReStore may move you to a business account.';

  @override
  String postingRuleBusiness(int limit) {
    return 'Business plan (coming soon): up to $limit listings per category. Shop plan: your own shop page.';
  }

  @override
  String homeGreetingPro(String name) {
    return 'Hi pro seller $name 👋';
  }

  @override
  String homeGreetingShop(String name) {
    return 'Hi shop owner $name 👋';
  }

  @override
  String get planPersonal => 'Personal';

  @override
  String get planPro => 'Pro seller';

  @override
  String get planShop => 'Shop';

  @override
  String get devPlanTag => 'TEST';

  @override
  String get devPlanSwitchTooltip => 'Switch plan to test the UI (in-app only)';

  @override
  String get quickMenuOpen => 'Open quick menu';

  @override
  String get quickMenuClose => 'Close quick menu';

  @override
  String get quickActionPost => 'Post';

  @override
  String get quickActionPoster => 'Shop poster';

  @override
  String get quickActionBoost => 'Boost';

  @override
  String get quickActionStats => 'Insights';

  @override
  String get quickActionShopManage => 'Manage shop';

  @override
  String get trustedShopsFamousEyebrow => 'Official';

  @override
  String get trustedShopsDealsEyebrow => 'On sale';

  @override
  String get trustedShopsNewReleasesEyebrow => 'Just launched';

  @override
  String get trustedShopsNewShopsEyebrow => 'Newly verified';

  @override
  String get trustedShopsShowcaseEyebrow => 'By brand';

  @override
  String get trustedShopsAllProductsEyebrow => 'Explore';

  @override
  String get feedsComposePrompt =>
      'What\'s on your mind? Share an item or ask the community';

  @override
  String get postAudienceTitle => 'Who can see this post?';

  @override
  String get postAudienceEveryone => 'Everyone';

  @override
  String get postAudienceEveryoneDesc => 'Anyone on ReStore can see it';

  @override
  String get postAudienceFollowers => 'Followers';

  @override
  String get postAudienceFollowersDesc => 'Only people who follow you';

  @override
  String get postAudienceOnlyMe => 'Only me';

  @override
  String get postAudienceOnlyMeDesc => 'Saved privately on your page';

  @override
  String get postComposerSubmit => 'Post';

  @override
  String get postComposerHint =>
      'Share an item, a buying tip or ask the community...';

  @override
  String get postComposerRemovePhoto => 'Remove photo';

  @override
  String get postComposerCover => 'Cover';

  @override
  String get postComposerListingTag => 'Your listing';

  @override
  String get postComposerRemoveAttachment => 'Remove';

  @override
  String postComposerWithOne(String name) {
    return 'With $name';
  }

  @override
  String postComposerWithMany(String name, int count) {
    return 'With $name and $count others';
  }

  @override
  String get postComposerBackground => 'Background colour';

  @override
  String get postComposerBackgroundDisabled =>
      'Background colours are for short posts without photos';

  @override
  String get postComposerNoBackground => 'No background';

  @override
  String get postComposerAttachListing => 'Attach listing';

  @override
  String get postComposerAttachListingHint =>
      'Show one of your listings in this post';

  @override
  String get postComposerTopic => 'Topic';

  @override
  String get postComposerTopicHint => 'Helps the right people find your post';

  @override
  String get postComposerTagFriends => 'Tag people';

  @override
  String get postComposerTagFriendsHint => 'People you follow';

  @override
  String postComposerTaggedCount(int count) {
    return '$count tagged';
  }

  @override
  String get postComposerEmoji => 'Emoji';

  @override
  String get postComposerPhoto => 'Photos';

  @override
  String get postComposerVideo => 'Video';

  @override
  String get postComposerLink => 'Link';

  @override
  String get postComposerLinkHint => 'Paste a web link to share';

  @override
  String get postComposerLinkInvalid => 'This link doesn\'t look right';

  @override
  String get postComposerLocation => 'Location';

  @override
  String get postComposerTakePhoto => 'Take photo';

  @override
  String get postComposerOpenGallery => 'Gallery';

  @override
  String get postComposerDone => 'Done';

  @override
  String get postComposerLoadError =>
      'Couldn\'t load post options, trying again';

  @override
  String get postComposerDiscardTitle => 'Discard this post?';

  @override
  String get postComposerDiscardMessage =>
      'What you\'ve written won\'t be saved';

  @override
  String get postComposerKeepEditing => 'Keep writing';

  @override
  String get postComposerDiscard => 'Discard post';

  @override
  String postComposerPhotoLimit(int count) {
    return 'You can add up to $count photos';
  }

  @override
  String get postComposerPhotoPermission =>
      'ReStore needs photo access. Please allow it in Settings.';

  @override
  String get postComposerNoListings =>
      'You have no active listings to attach yet';

  @override
  String get postComposerError =>
      'Couldn\'t publish your post, please try again';

  @override
  String get postComposerPosted => 'Your post is live on the feed';

  @override
  String get authSessionExpired =>
      'Your session has expired. Please sign in again.';

  @override
  String get draftsTitle => 'Drafts';

  @override
  String get draftsBannerTitle => 'Continue a draft';

  @override
  String draftsBannerMessage(String count) {
    return 'Unpublished listings: $count';
  }

  @override
  String get draftsBannerAction => 'View';

  @override
  String get draftUntitled => 'Untitled';

  @override
  String get draftNoCategory => 'No category yet';

  @override
  String draftEditedAt(String time) {
    return 'Edited $time';
  }

  @override
  String draftPhotoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
    );
    return '$_temp0';
  }

  @override
  String get draftsEmptyTitle => 'No drafts yet';

  @override
  String get draftsEmptyMessage =>
      'While posting, tap Save draft to finish it later.';

  @override
  String get draftsLoadFailedTitle => 'Couldn\'t load drafts';

  @override
  String get draftsLoadFailedMessage => 'Check your connection and try again.';

  @override
  String get draftOpenFailed =>
      'Couldn\'t open this draft. It may have been published or deleted';

  @override
  String get draftDeleteTitle => 'Delete draft?';

  @override
  String get draftDeleteMessage =>
      'The draft and its uploaded photos will be deleted permanently.';

  @override
  String get draftDeleteConfirm => 'Delete draft';

  @override
  String get draftDeleted => 'Draft deleted';

  @override
  String draftDeletedNamed(String title) {
    return 'Deleted draft “$title”';
  }

  @override
  String get draftDeleteFailed =>
      'Couldn\'t delete the draft, please try again';

  @override
  String get leaveDraftTitle => 'Save before leaving?';

  @override
  String get leaveDraftMessage =>
      'You have unsaved changes. Save a draft to finish it later.';

  @override
  String get leaveDraftSave => 'Save draft and leave';

  @override
  String get leaveDraftDiscard => 'Leave without saving';

  @override
  String draftLimitTitle(int limit) {
    return '$limit drafts reached';
  }

  @override
  String get draftLimitTitleUnknown => 'Draft limit reached';

  @override
  String draftLimitMessage(int limit) {
    return 'Your account can keep up to $limit drafts. Publish or delete an old draft to save this one.';
  }

  @override
  String get draftLimitMessageUnknown =>
      'Your account has reached its draft limit. Publish or delete an old draft to save this one.';

  @override
  String get draftLimitViewDrafts => 'View drafts';

  @override
  String draftsQuota(int used, int limit) {
    return '$used/$limit drafts';
  }

  @override
  String get listingImageTooLarge =>
      'A photo is too large (max 5 MB). Remove it or pick another one.';

  @override
  String get listingImageUnsupported =>
      'A photo has an unsupported format (JPEG, PNG or WebP only). Remove it or pick another one.';

  @override
  String listingImageMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos are no longer on this device and were removed',
      one: '1 photo is no longer on this device and was removed',
    );
    return '$_temp0. Pick them again, then save.';
  }

  @override
  String get listingSaveNetworkError =>
      'Couldn\'t reach the server. What was saved is kept, please try again.';

  @override
  String get feedReply => 'Reply';

  @override
  String get feedHideReplies => 'Hide replies';

  @override
  String feedViewReplies(int count) {
    return 'View $count replies';
  }

  @override
  String feedReplyTo(String name) {
    return 'Replying to $name';
  }

  @override
  String get feedCancelReply => 'Cancel reply';

  @override
  String get feedMoreComments => 'Load more comments';

  @override
  String get creditTitle => 'ReStore Points';

  @override
  String get creditAvailable => 'Available points';

  @override
  String creditPoints(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount points',
      one: '$amount point',
    );
    return '$_temp0';
  }

  @override
  String get creditUnit => 'points';

  @override
  String get creditPaidLabel => 'Purchased';

  @override
  String get creditBonusLabel => 'Bonus';

  @override
  String get creditHeldLabel => 'On hold';

  @override
  String creditBonusExpiry(String date) {
    return 'Bonus points start expiring on $date.';
  }

  @override
  String get creditHeldHint =>
      'Points on hold belong to listings awaiting review and come back if a listing is rejected.';

  @override
  String get creditTopupAction => 'Buy points';

  @override
  String get creditUsesTitle => 'Use points to';

  @override
  String get creditUsePostMore => 'Post more';

  @override
  String get creditUseBoost => 'Boost a listing';

  @override
  String get creditUseUpgrade => 'Upgrade plan';

  @override
  String get creditRecentTitle => 'Recent activity';

  @override
  String get creditSeeAll => 'See all';

  @override
  String get creditEmptyHistory => 'No point activity yet';

  @override
  String get creditLoadError => 'Couldn\'t load your points';

  @override
  String get creditHistoryTitle => 'Points history';

  @override
  String get creditFilterAll => 'All';

  @override
  String get creditFilterTopup => 'Purchases';

  @override
  String get creditFilterSpend => 'Spent';

  @override
  String get creditFilterRefund => 'Refunds';

  @override
  String get creditTxnTopup => 'Points purchase';

  @override
  String get creditTxnBonus => 'Bonus points';

  @override
  String get creditTxnSpend => 'Points spent';

  @override
  String get creditTxnRefund => 'Points refunded';

  @override
  String get creditTxnExpire => 'Points expired';

  @override
  String get creditTxnAdjust => 'Adjustment';

  @override
  String creditTxnOrder(String code) {
    return 'Order $code';
  }

  @override
  String get creditTopupTitle => 'Choose a pack';

  @override
  String get creditRate =>
      '1 point = 1,000 VND. Bigger packs include bonus points.';

  @override
  String get creditPopular => 'Popular';

  @override
  String creditBonusTag(String amount) {
    return '+$amount bonus';
  }

  @override
  String get creditNoBonus => 'No bonus';

  @override
  String get creditTerms =>
      'Points can only be used in ReStore. They can\'t be cashed out or transferred to anyone. Bonus points are used first and expire after 90 days.';

  @override
  String creditContinue(String price) {
    return 'Continue · $price';
  }

  @override
  String get creditConfirmTitle => 'Confirm purchase';

  @override
  String get creditSummaryPack => 'Pack';

  @override
  String get creditSummaryReceive => 'You get';

  @override
  String get creditSummaryTotal => 'Total';

  @override
  String creditReceiveWithBonus(String total, String bonus) {
    return '$total points ($bonus bonus)';
  }

  @override
  String get creditPayMethodTitle => 'Payment method';

  @override
  String get creditMethodZalopay => 'ZaloPay';

  @override
  String get creditMethodZalopayDesc =>
      'ZaloPay wallet, local ATM card or international card.';

  @override
  String get creditMethodVietqr => 'VietQR bank transfer';

  @override
  String get creditMethodVietqrDesc =>
      'Scan with any banking app. Points arrive when the money does.';

  @override
  String get creditSandboxNote =>
      'Test mode (sandbox): no real money is charged.';

  @override
  String get creditAgree =>
      'I agree that points can\'t be exchanged back for cash, unless a payment fails or is charged twice.';

  @override
  String creditPayAction(String price) {
    return 'Pay $price';
  }

  @override
  String get creditPayZalopayTitle => 'Pay with ZaloPay';

  @override
  String get creditPayBankTitle => 'Bank transfer';

  @override
  String get creditOrderCode => 'Order code';

  @override
  String get creditGatewayNotConnected =>
      'ZaloPay is skipped (debug mode or no server keys). Use the buttons below to simulate the result.';

  @override
  String get creditOpenGateway => 'Open ZaloPay checkout';

  @override
  String get creditWaitingGateway =>
      'Finish paying on the ZaloPay page, then come back here. Your points update automatically.';

  @override
  String get creditSimulateTitle =>
      'Simulate the payment result (test mode only)';

  @override
  String get creditSimulateSuccess => 'Paid';

  @override
  String get creditSimulateFail => 'Failed';

  @override
  String get creditScanQr => 'Scan with any banking app';

  @override
  String get creditAccountNo => 'Account number';

  @override
  String get creditAccountName => 'Account name';

  @override
  String get creditTransferContent => 'Transfer note';

  @override
  String creditQrExpires(String time) {
    return 'Code expires at $time';
  }

  @override
  String get creditWaitingTransfer =>
      'Waiting for your transfer. Keep the transfer note as is so the points arrive automatically.';

  @override
  String get creditVietQrUnavailable =>
      'The receiving bank account isn\'t set up on the server yet.';

  @override
  String get creditCopied => 'Copied';

  @override
  String get creditCopy => 'Copy';

  @override
  String get creditCancelOrder => 'Cancel order';

  @override
  String get creditResultTitle => 'Result';

  @override
  String get creditSuccessTitle => 'Purchase complete';

  @override
  String creditSuccessAmount(String amount) {
    return '+$amount points';
  }

  @override
  String get creditSuccessBody => 'The points are in your wallet.';

  @override
  String get creditPendingTitle => 'Waiting for confirmation';

  @override
  String get creditPendingBody =>
      'Your points will arrive as soon as the payment is confirmed. You can leave this page.';

  @override
  String get creditFailTitle => 'Purchase not completed';

  @override
  String get creditFailBody =>
      'The payment was cancelled or expired. You haven\'t been charged.';

  @override
  String get creditCheckAgain => 'Check again';

  @override
  String get creditTryAgain => 'Try again';

  @override
  String get creditDone => 'Done';

  @override
  String get creditBackToWallet => 'Back to wallet';

  @override
  String get creditErrorTooManyPending =>
      'You have too many unpaid orders. Wait 15 minutes for them to expire or cancel one.';

  @override
  String get creditErrorGeneric => 'Something went wrong, please try again.';

  @override
  String get creditPackagesError => 'Couldn\'t load point packs';

  @override
  String get postingLimitTotalTitle => 'Free listings used up';

  @override
  String postingLimitTotalMessage(int limit) {
    return 'A personal account can have at most $limit free listings at once across all categories.';
  }

  @override
  String postingLimitRecentMessage(String category, int days) {
    return 'You have posted for free in $category many times in the last $days days. Each category allows up to twice its free slots every $days days.';
  }

  @override
  String postingPayTitle(int credits) {
    return 'Post this listing for $credits points';
  }

  @override
  String postingPayBalance(int available) {
    return 'Your wallet: $available points';
  }

  @override
  String get postingPayNote =>
      'Points are held when you submit and only spent once the listing is approved. Rejected listings get their points back.';

  @override
  String postingPayMissing(int missing) {
    return 'You need $missing more points.';
  }

  @override
  String postingPayContinue(int credits) {
    return 'Continue · $credits points';
  }

  @override
  String postingPayPublish(int credits) {
    return 'Post · $credits points';
  }

  @override
  String get postingTopUp => 'Buy points';

  @override
  String get postingFreeWaysTitle => 'Or free up a free slot';

  @override
  String postingQuotaTotalUsage(int used, int limit) {
    return '$used/$limit free listings used on your account';
  }

  @override
  String postingQuotaPaidHint(int credits) {
    return 'Out of slots? Post more with points, from $credits points per listing.';
  }

  @override
  String accExpiresIn(int days) {
    return '$days days left';
  }

  @override
  String get accExpired => 'Expired';

  @override
  String get accReactivate => 'Reactivate';

  @override
  String get accReactivated => 'Listing reactivated';

  @override
  String get accExtend => 'Extend listing';

  @override
  String accExtendMessage(int days, int credits) {
    return 'Show this listing for $days more days for $credits points. Points are spent right away, no new review needed.';
  }

  @override
  String accExtendPay(int credits) {
    return 'Extend · $credits points';
  }

  @override
  String accExtendTooEarly(int days) {
    return 'You can extend once $days days or fewer are left.';
  }

  @override
  String get accExtended => 'Listing extended';

  @override
  String postingPayReactivate(int credits) {
    return 'Reactivate · $credits points';
  }

  @override
  String get postingLater => 'Later';

  @override
  String get duplicateActiveTitle => 'You already posted this';

  @override
  String get duplicateActiveMessage =>
      'A matching listing of yours is live or waiting for review, so there is no need to post it again.';

  @override
  String get duplicateInactiveTitle => 'Reuse your old listing?';

  @override
  String get duplicateInactiveMessage =>
      'You have a matching listing that is hidden or expired. Reactivate it to keep its views and saves.';

  @override
  String get duplicateOpenOld => 'See old listing';

  @override
  String get duplicatePostNew => 'Post new anyway';

  @override
  String postingPayReactivateTitle(int credits) {
    return 'Show this listing again for $credits points';
  }

  @override
  String get postingPayNowNote =>
      'Points are spent as soon as the listing is shown again, no new review needed.';

  @override
  String get boostSheetMessage =>
      'Your listing moves to the top of the list for 24 hours.';

  @override
  String boostFreeNote(int left, int perMonth) {
    return 'Uses 1 free boost from your plan, $left/$perMonth left this month.';
  }

  @override
  String boostPayNote(int credits) {
    return 'Costs $credits points, spent right away.';
  }

  @override
  String boostDiscountNote(int percent) {
    return 'Your plan gets $percent% off.';
  }

  @override
  String get boostUseFree => 'Boost for free';

  @override
  String boostPay(int credits) {
    return 'Boost · $credits points';
  }

  @override
  String get boostDone => 'Listing boosted to the top';

  @override
  String boostTooSoon(int hours) {
    return 'This listing was just boosted. You can boost it again in $hours hours.';
  }

  @override
  String get plansTitle => 'Account plans';

  @override
  String get plansSubtitle => 'Paid with points, 30 days each time';

  @override
  String get plansCurrent => 'Current plan';

  @override
  String plansCurrentUntil(String date) {
    return 'Active until $date';
  }

  @override
  String get plansFree => 'Free';

  @override
  String get plansPersonalBenefitFree =>
      '1 to 3 free listings per category, up to 5 in total';

  @override
  String get plansPersonalBenefitPay => 'Out of slots? Post more with points';

  @override
  String plansPrice(int price) {
    return '$price points / 30 days';
  }

  @override
  String plansBenefitActive(int count) {
    return '$count active listings at a time';
  }

  @override
  String plansBenefitDaily(int count) {
    return '$count new listings per day';
  }

  @override
  String plansBenefitDrafts(int count) {
    return 'Keep $count drafts';
  }

  @override
  String plansBenefitBoosts(int count) {
    return '$count free boosts every month';
  }

  @override
  String plansBenefitBoostDiscount(int percent) {
    return '$percent% off boosts';
  }

  @override
  String get plansBenefitPriority => 'Shown first in your main category';

  @override
  String get plansBenefitShopPage => 'Your own shop page (coming soon)';

  @override
  String get plansBuy => 'Get this plan';

  @override
  String get plansRenew => 'Renew';

  @override
  String get plansUpgrade => 'Upgrade';

  @override
  String get plansInUse => 'Current';

  @override
  String get plansLowerLocked => 'Available when your current plan ends';

  @override
  String get plansNote =>
      'Upgrading mid-period credits the unused part of your old plan. Renewing adds 30 days. Points are spent right away and the plan starts immediately.';

  @override
  String get plansCheckoutPrice => 'Plan price';

  @override
  String get plansCheckoutCredit => 'Credit for unused days';

  @override
  String get plansCheckoutTotal => 'To pay';

  @override
  String get plansCheckoutUntil => 'Active until';

  @override
  String get plansCheckoutCategory => 'Main category';

  @override
  String get plansCheckoutCategoryHint =>
      'Listings in this category are shown first.';

  @override
  String plansCredits(int count) {
    return '$count points';
  }

  @override
  String plansPay(int amount) {
    return 'Pay $amount points';
  }

  @override
  String plansActivated(String name) {
    return '$name plan activated';
  }

  @override
  String get plansLoadError => 'Couldn\'t load plans.';

  @override
  String get plansActionError => 'Something went wrong. Please try again.';

  @override
  String get plansUpgradeAction => 'Upgrade plan';

  @override
  String get postingUpgradeHint => 'Need more listings? Upgrade your plan';

  @override
  String get hotSaleTitle => 'Hot sale';

  @override
  String get featureAction => 'Put on Hot sale';

  @override
  String get featureSheetMessage =>
      'Your listing shows in Hot sale on the home page and at the top of its category, above other listings, for the time you choose.';

  @override
  String featureDays(int days) {
    return '$days days';
  }

  @override
  String featurePay(int credits) {
    return 'Buy · $credits points';
  }

  @override
  String get featureDone => 'Your listing is on Hot sale';

  @override
  String featureRunning(String date) {
    return 'This listing is on Hot sale until $date.';
  }

  @override
  String get featureUnavailable => 'Only visible listings can go on Hot sale.';

  @override
  String get featureNoOptions => 'No Hot sale packages are on sale right now.';

  @override
  String accExpiresOn(String date, int days) {
    return 'Expires $date · $days days left';
  }

  @override
  String accExpiredOn(String date) {
    return 'Expired $date';
  }

  @override
  String previewDisplayDays(int days) {
    return 'Your listing shows for $days days after approval. You can extend it near the end, or reactivate it once it expires.';
  }

  @override
  String get hotSaleSubtitle =>
      'Listings sellers are promoting right now, updated all the time.';

  @override
  String get hotSaleLoadError => 'Couldn\'t load Hot sale listings';

  @override
  String get hotSaleEmptyTitle => 'No Hot sale listings yet';

  @override
  String get hotSaleEmptyBody =>
      'Listings that sellers put on Hot sale will show up here.';

  @override
  String get hotSaleEnd => 'You\'ve seen all Hot sale listings';

  @override
  String get displayDaysTitle => 'Display time';

  @override
  String displayDaysFree(int days) {
    return 'Free · $days days';
  }

  @override
  String displayDaysPlus(int days) {
    return '+$days days';
  }

  @override
  String displayDaysRange(String start, String end, int days) {
    return '$start → $end · $days days';
  }

  @override
  String get displayDaysStart => 'Starts';

  @override
  String get displayDaysEnd => 'Ends';

  @override
  String get displayDaysToday => 'Today, once approved';

  @override
  String get displayDaysCount => 'Days on display';

  @override
  String get displayDaysExtraCount => 'Extra days';

  @override
  String displayDaysIncluded(int free) {
    return 'Includes $free free days for this category';
  }

  @override
  String displayDaysExtraPrice(int days, int credits) {
    return '$days extra days: $credits points';
  }

  @override
  String get displayDaysNoCharge => 'Free';

  @override
  String displayDaysPackSave(int days, int credits) {
    return '$days-day pack price, you save $credits points';
  }

  @override
  String displayDaysSuggest(int days, int credits) {
    return 'Get $days days for $credits points';
  }

  @override
  String displayDaysMax(int days) {
    return 'This category can be shown for up to $days days.';
  }

  @override
  String get displayDaysPayNote =>
      'Points are held when you post, charged on approval and refunded if rejected.';

  @override
  String get displayDaysDone => 'Done';

  @override
  String get displayDaysCardHint => 'Tap to change the start date or add days';

  @override
  String displayDaysScheduled(String date) {
    return 'Scheduled from $date';
  }

  @override
  String extendNewEnd(String date) {
    return 'New end date: $date';
  }

  @override
  String extendCurrentEnd(String date) {
    return 'Showing until $date';
  }

  @override
  String extendAddable(int days) {
    return 'You can add up to $days more days';
  }

  @override
  String extendLimitReached(int days) {
    return 'This listing is already at the $days-day maximum.';
  }

  @override
  String get extendChargeNote =>
      'Points are charged now, no new review needed.';

  @override
  String get autoExtendTitle => 'Auto-extend 30 days';

  @override
  String autoExtendBody(int credits) {
    return 'When less than a day is left, $credits points are charged if your wallet has enough.';
  }

  @override
  String get autoExtendOn => 'Auto-extend is on';

  @override
  String get autoExtendOff => 'Auto-extend is off';

  @override
  String accExtendedDays(int days) {
    return 'Extended by $days days';
  }

  @override
  String get displayDaysTodayShort => 'Today';

  @override
  String get displayDaysShortTitle => 'Not enough points for extra days';

  @override
  String displayDaysShortBody(int missing) {
    return 'You need $missing more points for the extra days. Top up, or post with the free days.';
  }

  @override
  String displayDaysUseFree(int days) {
    return 'Post with $days free days';
  }

  @override
  String get originalPriceLabel => 'Original price (before discount)';

  @override
  String get originalPricePlaceholder => 'Leave empty if not on sale';

  @override
  String get originalPriceHint =>
      'For shops: buyers see the original price struck through and the % off. It cannot be raised after posting.';

  @override
  String originalPriceDiscount(int percent) {
    return '$percent% off the original price';
  }

  @override
  String get originalPriceError =>
      'Original price must be higher than the sale price';

  @override
  String get promoTitle => 'Promote listing';

  @override
  String get promoNotPromotable =>
      'This listing isn\'t visible, so it can\'t be promoted. Show it again in Manage listings, then come back.';

  @override
  String promoBoostRunning(String date) {
    return 'At the top of the list until $date';
  }

  @override
  String promoBoostAgainAt(String date) {
    return 'Boost again after $date';
  }

  @override
  String get promoRunning => 'Running';

  @override
  String get promoHistoryTitle => 'Recent promotions';

  @override
  String get promoHistoryEmpty => 'This listing hasn\'t been promoted yet.';

  @override
  String promoHistoryFeature(int days) {
    return 'Hot sale $days days';
  }

  @override
  String get promoFree => 'Free';

  @override
  String get promoEnded => 'Ended';

  @override
  String get promoLoadError => 'Couldn\'t load promotion info';

  @override
  String promoBalanceAfter(int left) {
    return '$left points left in your wallet after paying.';
  }

  @override
  String get promoPickTitle => 'Pick a listing to promote';

  @override
  String get promoPickSubtitle =>
      'Only visible listings can be boosted or put on Hot sale';

  @override
  String get promoPickEmpty => 'You have no visible listings yet.';

  @override
  String get hubTitle => 'Promotions';

  @override
  String hubFreeBoosts(int left, int perMonth) {
    return '$left/$perMonth free boosts left';
  }

  @override
  String hubThisMonth(int boosts, int features) {
    return 'This month: $boosts boosts · $features Hot sale';
  }

  @override
  String get hubFilterAll => 'All';

  @override
  String get hubFilterRunning => 'Promoted';

  @override
  String get hubFilterExpiring => 'Expiring soon';

  @override
  String get hubFilterIdle => 'Not promoted';

  @override
  String hubBoostedFor(String time) {
    return 'Boosted · $time left';
  }

  @override
  String hubFeaturedFor(String time) {
    return 'Hot sale · $time left';
  }

  @override
  String hubExpiresIn(String time) {
    return 'Expires in $time';
  }

  @override
  String hubHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String hubDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get hubAutoExtend => 'Auto-extend';

  @override
  String get hubDetails => 'Details';

  @override
  String get hubEmptyRunning =>
      'No listing is boosted or on Hot sale right now.';

  @override
  String get hubEmptyExpiring => 'No listing expires in the next 7 days.';

  @override
  String get hubEmptyIdle => 'All your listings are being promoted.';

  @override
  String hubExpiringTip(int count) {
    return '$count listings expiring soon: extend them so they stay visible.';
  }

  @override
  String get insTitle => 'Insights';

  @override
  String insRangeDays(int days) {
    return '$days days';
  }

  @override
  String get insViews => 'Views';

  @override
  String get insSaves => 'Saves';

  @override
  String get insChats => 'People who messaged';

  @override
  String insUp(int percent) {
    return 'Up $percent% vs previous period';
  }

  @override
  String insDown(int percent) {
    return 'Down $percent% vs previous period';
  }

  @override
  String get insSame => 'Same as previous period';

  @override
  String get insNew => 'None in previous period';

  @override
  String get insChartTitle => 'Views per day';

  @override
  String get insChartEmpty => 'No views in this period yet.';

  @override
  String insChartDay(String date, int views, int saves) {
    return '$date: $views views · $saves saves';
  }

  @override
  String get insChartHint => 'Tap a bar to see that day';

  @override
  String get insListingsTitle => 'Listings';

  @override
  String get insActive => 'Active';

  @override
  String get insPending => 'Pending';

  @override
  String get insHidden => 'Hidden';

  @override
  String get insSold => 'Sold';

  @override
  String get insTopTitle => 'Most viewed listings';

  @override
  String insTopStats(int views, int saves) {
    return '$views views · $saves saves';
  }

  @override
  String get insTopEmpty => 'No visible listings yet.';

  @override
  String get insTipsTitle => 'Tips';

  @override
  String insTipBoost(String title) {
    return '\"$title\" is your most viewed listing. Boost it to stay on top.';
  }

  @override
  String insTipExpiring(int count) {
    return '$count listings expire within 7 days. Extend them so they stay visible.';
  }

  @override
  String get insTipNoViews =>
      'No views yet: clear photos, a specific title and a fair price help people notice your listings.';

  @override
  String insPromotions(int boosts, int features) {
    return 'This period: $boosts boosts · $features Hot sale';
  }

  @override
  String get insLoadError => 'Couldn\'t load insights';

  @override
  String get insViewsNote => 'Daily views are recorded from 11/11/2026.';

  @override
  String get spTitle => 'Shop posters';

  @override
  String get spCreate => 'New poster';

  @override
  String get spLoadError => 'Couldn\'t load posters';

  @override
  String get spNoShopTitle => 'You don\'t have a shop page yet';

  @override
  String get spNoShopBody =>
      'Posters appear on your shop page and on Trusted shops, so you need a shop page first.';

  @override
  String get spPlanTitle => 'Posters are part of the Store plan';

  @override
  String get spPlanBody =>
      'Upgrade to the Store plan to run posters on your shop page and on Trusted shops.';

  @override
  String get spSeePlans => 'See plans';

  @override
  String get spSlots => 'Posters at once';

  @override
  String get spMonthly => 'Sent this month';

  @override
  String get spUnverified =>
      'Your shop isn\'t verified yet, so approved posters aren\'t shown publicly.';

  @override
  String spCooldown(String date) {
    return 'You can\'t send posters until $date because several were rejected.';
  }

  @override
  String spRules(int min, int max) {
    return '1200×600 image (2:1), runs $min to $max days. Reviewed within about 24 hours.';
  }

  @override
  String spMonthlyFull(int limit) {
    return 'You\'ve sent all $limit posters for this month.';
  }

  @override
  String get spFilterAll => 'All';

  @override
  String get spFilterRunning => 'Running';

  @override
  String get spFilterPending => 'In review';

  @override
  String get spFilterScheduled => 'Scheduled';

  @override
  String get spFilterRejected => 'Rejected';

  @override
  String get spFilterEnded => 'Ended';

  @override
  String get spStateStopped => 'Stopped';

  @override
  String get spEmpty => 'No posters yet';

  @override
  String get spEmptyBody =>
      'Create your first poster to promote a shop campaign.';

  @override
  String get spEmptyFilter => 'No posters here.';

  @override
  String spDates(String start, String end, int days) {
    return '$start – $end · $days days';
  }

  @override
  String get spOpensShop => 'Opens your shop page';

  @override
  String spOpensListing(String title) {
    return 'Opens listing: $title';
  }

  @override
  String spRejectedReason(String reason) {
    return 'Rejected: $reason';
  }

  @override
  String get spReasonWrongSize => 'Wrong image size';

  @override
  String get spReasonMisleadingPrice => 'Misleading price or offer';

  @override
  String get spReasonBrandMisuse => 'Uses a brand or logo that isn\'t yours';

  @override
  String get spReasonProhibited => 'Prohibited content';

  @override
  String get spReasonTooMuchText => 'Too much text on the image';

  @override
  String get spReasonOther => 'Other reason';

  @override
  String get spEdit => 'Edit';

  @override
  String get spResubmit => 'Edit and resend';

  @override
  String get spStop => 'Stop';

  @override
  String get spCancel => 'Withdraw';

  @override
  String get spStopTitle => 'Stop this poster?';

  @override
  String get spStopBody =>
      'The poster stops showing right away and can\'t be restarted.';

  @override
  String get spCancelTitle => 'Withdraw this poster?';

  @override
  String get spCancelBody => 'It still counts toward this month\'s posters.';

  @override
  String get spConfirmStop => 'Stop poster';

  @override
  String get spConfirmCancel => 'Withdraw';

  @override
  String get spKeep => 'Keep';

  @override
  String get spStopped => 'Poster stopped';

  @override
  String get spNewTitle => 'New poster';

  @override
  String get spEditTitle => 'Edit poster';

  @override
  String get spImage => 'Poster image';

  @override
  String get spPickImage => 'Choose a 1200×600 image';

  @override
  String get spChangeImage => 'Change image';

  @override
  String get spImageHint =>
      'Pick any image, then drag and zoom it into the 2:1 frame. Put the text in the image itself.';

  @override
  String get spImageRequired => 'Choose a poster image.';

  @override
  String get spName => 'Campaign name';

  @override
  String get spNameHint => 'e.g. Galaxy Week up to 20% off';

  @override
  String get spNameHelper =>
      'Not drawn on the image; used by screen readers and to keep track.';

  @override
  String get spNameRequired => 'Enter a campaign name.';

  @override
  String get spOpens => 'When people tap the poster';

  @override
  String get spOpenShop => 'Open shop page';

  @override
  String get spOpenListing => 'Open a listing';

  @override
  String get spChooseListing => 'Choose listing';

  @override
  String get spNoListings => 'Your shop has no active listings.';

  @override
  String get spListingRequired => 'Choose a listing.';

  @override
  String get spStart => 'Start date';

  @override
  String get spStartNow => 'As soon as approved';

  @override
  String get spStartOn => 'Pick a date';

  @override
  String get spDuration => 'Duration';

  @override
  String spDays(int days) {
    return '$days days';
  }

  @override
  String spEndsOn(String date) {
    return 'Ends around $date';
  }

  @override
  String get spEditRunningNote =>
      'A running poster is hidden until it\'s approved again.';

  @override
  String get spSubmit => 'Send for review';

  @override
  String get spSubmitted =>
      'Poster sent. It\'s usually reviewed within 24 hours.';

  @override
  String get spErrSlotFull =>
      'That time already has the most posters you can run at once. Pick another date or stop a poster.';

  @override
  String get spErrMonthly => 'You\'ve sent all your posters for this month.';

  @override
  String get spErrCooldown => 'Sending posters is paused for your shop.';

  @override
  String get spErrPlan => 'Only the Store plan can run posters.';

  @override
  String get spErrShop => 'You need a shop page to run posters.';

  @override
  String get spErrListing =>
      'That listing isn\'t for sale anymore. Choose another.';

  @override
  String get spErrStartLate => 'The start date can be at most 14 days ahead.';

  @override
  String get spErrImage => 'Couldn\'t upload the image. Try another one.';

  @override
  String get spErrNotEditable => 'This poster has ended. Create a new one.';

  @override
  String get spErrGeneric => 'Something went wrong. Please try again.';

  @override
  String get spSchedule => 'Schedule';

  @override
  String get spCropTitle => 'Adjust poster';

  @override
  String get spAdjust => 'Adjust again';

  @override
  String get cropDone => 'Use this image';

  @override
  String get cropFill => 'Fill frame';

  @override
  String get cropFit => 'Show whole image';

  @override
  String get cropZoom => 'Zoom';

  @override
  String get cropHint =>
      'Drag to move; pinch or use the slider to zoom. Empty space is filled with the background you pick.';

  @override
  String get cropLowRes =>
      'The image is small for this frame and may look blurry. Zoom out or pick a larger image.';

  @override
  String get cropLoadError => 'Couldn\'t open this image. Try another one.';

  @override
  String get accAvatarSection => 'Profile photo';

  @override
  String get accAvatarHint =>
      'Shown in a circle on your profile, listings and messages. Tap Adjust to choose which part shows.';

  @override
  String get accAdjustAvatar => 'Adjust';

  @override
  String get accAvatarCropTitle => 'Adjust profile photo';

  @override
  String get accInfoSection => 'Profile details';

  @override
  String get accDisplayNameHint => 'e.g. Jane Doe or your shop name';

  @override
  String get accUsernameHelper =>
      '3–30 characters: lowercase letters, numbers, dots or underscores.';

  @override
  String get accBioHint => 'A few lines about you or your shop';

  @override
  String get cropBackground => 'Background';

  @override
  String get cropBgBlur => 'Blur';

  @override
  String get cropBgAuto => 'Match';

  @override
  String get cropBgWhite => 'White';

  @override
  String get cropBgBlack => 'Black';

  @override
  String get cropTrim => 'Remove plain borders';

  @override
  String get cropTrimOn => 'Plain borders removed';

  @override
  String get msTitle => 'Manage shop';

  @override
  String get msLoadError => 'Couldn\'t load your shop';

  @override
  String get msPlanTitle => 'Shop pages come with the Store plan';

  @override
  String get msPlanBody =>
      'Upgrade to the Store plan to open your own shop page with a logo, cover and posters, and get verified for Trusted shops.';

  @override
  String get msCreateTitle => 'Open your shop page';

  @override
  String get msCreateBody =>
      'Name your shop first, then add a logo, cover and description.';

  @override
  String get msCreateAction => 'Open shop';

  @override
  String get msCreated => 'Your shop page is open';

  @override
  String get msName => 'Shop name';

  @override
  String get msNameHint => 'e.g. Cozy Home Decor';

  @override
  String get msNameRequired => 'Shop name must be 2 to 60 characters.';

  @override
  String get msNameLocked =>
      'Verified shops can\'t change their name. Contact ReStore if you need to.';

  @override
  String get msTagline => 'Short tagline';

  @override
  String get msTaglineHint => 'e.g. Handmade decor, fast local delivery';

  @override
  String get msDescription => 'About the shop';

  @override
  String get msDescriptionHint =>
      'What you sell, quality promise, return policy...';

  @override
  String get msAddress => 'Display address';

  @override
  String get msAddressHint => 'e.g. District 1, Ho Chi Minh City';

  @override
  String get msInfoSection => 'Shop details';

  @override
  String get msColorSection => 'Brand colour';

  @override
  String get msColorHint =>
      'Used for the letter logo, the default cover and accents on your shop page.';

  @override
  String get msColorAuto => 'Default';

  @override
  String get msChangeCover => 'Change cover';

  @override
  String get msChangeLogo => 'Change logo';

  @override
  String get msImageNew => 'Choose a new image';

  @override
  String get msImageAdjust => 'Adjust again';

  @override
  String get msImageRemove => 'Remove image';

  @override
  String get msCoverCropTitle => 'Adjust cover';

  @override
  String get msLogoCropTitle => 'Adjust logo';

  @override
  String get msStatFollowers => 'Followers';

  @override
  String get msStatListings => 'Listings';

  @override
  String get msStatPostersRunning => 'Posters live';

  @override
  String get msStatPostersPending => 'Posters pending';

  @override
  String get msVerifiedTitle => 'Verified shop';

  @override
  String get msVerifiedBody => 'Your shop appears in Trusted shops.';

  @override
  String msCertificate(String code) {
    return 'Certificate: $code.';
  }

  @override
  String get msUnverifiedTitle => 'Not verified yet';

  @override
  String get msUnverifiedBody =>
      'Your shop isn\'t in Trusted shops yet and posters can\'t run. Contact ReStore to get verified.';

  @override
  String get msPlanExpiredTitle => 'Store plan expired';

  @override
  String get msPlanExpiredBody =>
      'Your posters are hidden for now. Renew the plan to run them again.';

  @override
  String get msViewPublic => 'View shop page';

  @override
  String get msPosters => 'Shop posters';

  @override
  String get msPostersBody =>
      'Promote your shop with posters on your shop page and Trusted shops.';

  @override
  String get msSave => 'Save changes';

  @override
  String get msSaved => 'Shop details saved';

  @override
  String get msErrExists => 'You already have a shop page.';

  @override
  String get msErrImage => 'That image is not valid. Try another one.';

  @override
  String get msErrGeneric => 'Couldn\'t save. Please try again.';
}
