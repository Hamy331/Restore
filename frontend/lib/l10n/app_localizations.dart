import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'ReStore'**
  String get appName;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login to your Account'**
  String get loginTitle;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @orSignInWith.
  ///
  /// In en, this message translates to:
  /// **'Or sign in with'**
  String get orSignInWith;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @successTitle.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get successTitle;

  /// No description provided for @errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Error occurred'**
  String get errorTitle;

  /// No description provided for @warningTitle.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warningTitle;

  /// No description provided for @infoTitle.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get infoTitle;

  /// No description provided for @deviceNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Device not supported'**
  String get deviceNotSupported;

  /// No description provided for @deviceNotSupportedDesc.
  ///
  /// In en, this message translates to:
  /// **'The ReStore application is currently designed and optimized exclusively for mobile handheld experiences.'**
  String get deviceNotSupportedDesc;

  /// No description provided for @loginSuccessMsg.
  ///
  /// In en, this message translates to:
  /// **'Successfully logged into the system.'**
  String get loginSuccessMsg;

  /// No description provided for @loginErrorMsg.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password.'**
  String get loginErrorMsg;

  /// No description provided for @verifyOtpTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verifyOtpTitle;

  /// No description provided for @checkYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get checkYourEmail;

  /// No description provided for @otpSentToEmail.
  ///
  /// In en, this message translates to:
  /// **'An OTP has been sent to {email}. Enter the 6 digits to continue.'**
  String otpSentToEmail(String email);

  /// No description provided for @otpValidFor.
  ///
  /// In en, this message translates to:
  /// **'You can resend the code in {time}'**
  String otpValidFor(String time);

  /// No description provided for @verifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Email'**
  String get verifyEmailTitle;

  /// No description provided for @enterVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Enter verification code'**
  String get enterVerificationCode;

  /// No description provided for @verifyOtpButton.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verifyOtpButton;

  /// No description provided for @verifyEmailButton.
  ///
  /// In en, this message translates to:
  /// **'Verify email'**
  String get verifyEmailButton;

  /// No description provided for @resendOtp.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive code? Resend OTP'**
  String get resendOtp;

  /// No description provided for @otpExpireInfo.
  ///
  /// In en, this message translates to:
  /// **'The code is for one-time use and expires in 5 minutes.'**
  String get otpExpireInfo;

  /// No description provided for @emailVerifyInfo.
  ///
  /// In en, this message translates to:
  /// **'You can continue browsing after verifying your email.'**
  String get emailVerifyInfo;

  /// No description provided for @invalidOtpError.
  ///
  /// In en, this message translates to:
  /// **'Invalid OTP. Please check and try again.'**
  String get invalidOtpError;

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @profileName.
  ///
  /// In en, this message translates to:
  /// **'Ngo Tuong Phat'**
  String get profileName;

  /// No description provided for @memberSince2022.
  ///
  /// In en, this message translates to:
  /// **'Member since 2022'**
  String get memberSince2022;

  /// No description provided for @maskedPhoneArea.
  ///
  /// In en, this message translates to:
  /// **'090 ••• 1234 · District 1, HCMC'**
  String get maskedPhoneArea;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @activeListings.
  ///
  /// In en, this message translates to:
  /// **'Active listings'**
  String get activeListings;

  /// No description provided for @soldListings.
  ///
  /// In en, this message translates to:
  /// **'Sold listings'**
  String get soldListings;

  /// No description provided for @myAccount.
  ///
  /// In en, this message translates to:
  /// **'My account'**
  String get myAccount;

  /// No description provided for @savedListings.
  ///
  /// In en, this message translates to:
  /// **'Saved listings'**
  String get savedListings;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @addressArea.
  ///
  /// In en, this message translates to:
  /// **'Address / Area'**
  String get addressArea;

  /// No description provided for @restoreAi.
  ///
  /// In en, this message translates to:
  /// **'ReStore AI'**
  String get restoreAi;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @newCount.
  ///
  /// In en, this message translates to:
  /// **'{count} new'**
  String newCount(int count);

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfileTitle;

  /// No description provided for @changeAvatar.
  ///
  /// In en, this message translates to:
  /// **'Change profile photo'**
  String get changeAvatar;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @birthday.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get birthday;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @district1Hcm.
  ///
  /// In en, this message translates to:
  /// **'District 1, Ho Chi Minh City'**
  String get district1Hcm;

  /// No description provided for @thuDucHcm.
  ///
  /// In en, this message translates to:
  /// **'Thu Duc, Ho Chi Minh City'**
  String get thuDucHcm;

  /// No description provided for @district3Hcm.
  ///
  /// In en, this message translates to:
  /// **'District 3, Ho Chi Minh City'**
  String get district3Hcm;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @options.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get options;

  /// No description provided for @receiveNotifications.
  ///
  /// In en, this message translates to:
  /// **'Receive notifications'**
  String get receiveNotifications;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help / Support'**
  String get helpSupport;

  /// No description provided for @termsPolicies.
  ///
  /// In en, this message translates to:
  /// **'Terms & policies'**
  String get termsPolicies;

  /// No description provided for @savedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} saved listings'**
  String savedCount(int count);

  /// No description provided for @tapHeartToRemove.
  ///
  /// In en, this message translates to:
  /// **'Tap ♡ to remove'**
  String get tapHeartToRemove;

  /// No description provided for @emptySavedTitle.
  ///
  /// In en, this message translates to:
  /// **'No saved listings yet'**
  String get emptySavedTitle;

  /// No description provided for @emptySavedDescription.
  ///
  /// In en, this message translates to:
  /// **'Save listings you like to find them faster later.'**
  String get emptySavedDescription;

  /// No description provided for @exploreProducts.
  ///
  /// In en, this message translates to:
  /// **'Explore products'**
  String get exploreProducts;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @earlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get earlier;

  /// No description provided for @newMessage.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get newMessage;

  /// No description provided for @newMessageDescription.
  ///
  /// In en, this message translates to:
  /// **'Minh Anh sent another photo of the Canon AE-1.'**
  String get newMessageDescription;

  /// No description provided for @newOffer.
  ///
  /// In en, this message translates to:
  /// **'New price offer'**
  String get newOffer;

  /// No description provided for @newOfferDescription.
  ///
  /// In en, this message translates to:
  /// **'There is a 2,200,000 đ offer for the Canon AE-1 listing.'**
  String get newOfferDescription;

  /// No description provided for @offerResponse.
  ///
  /// In en, this message translates to:
  /// **'Offer response'**
  String get offerResponse;

  /// No description provided for @offerResponseDescription.
  ///
  /// In en, this message translates to:
  /// **'Minh Anh proposed another price: 2,300,000 đ.'**
  String get offerResponseDescription;

  /// No description provided for @listingApproved.
  ///
  /// In en, this message translates to:
  /// **'Listing approved'**
  String get listingApproved;

  /// No description provided for @listingApprovedDescription.
  ///
  /// In en, this message translates to:
  /// **'The vintage brass desk lamp listing is now visible.'**
  String get listingApprovedDescription;

  /// No description provided for @listingNeedsEdit.
  ///
  /// In en, this message translates to:
  /// **'Listing needs changes'**
  String get listingNeedsEdit;

  /// No description provided for @listingNeedsEditDescription.
  ///
  /// In en, this message translates to:
  /// **'Please add photos to the oak chair listing.'**
  String get listingNeedsEditDescription;

  /// No description provided for @listingSavedNotification.
  ///
  /// In en, this message translates to:
  /// **'Your listing was saved'**
  String get listingSavedNotification;

  /// No description provided for @listingSavedDescription.
  ///
  /// In en, this message translates to:
  /// **'3 people saved your Canon AE-1 listing.'**
  String get listingSavedDescription;

  /// No description provided for @sellerTitle.
  ///
  /// In en, this message translates to:
  /// **'Seller'**
  String get sellerTitle;

  /// No description provided for @sellerName.
  ///
  /// In en, this message translates to:
  /// **'Minh Anh'**
  String get sellerName;

  /// No description provided for @sellerArea.
  ///
  /// In en, this message translates to:
  /// **'District 1, Ho Chi Minh City'**
  String get sellerArea;

  /// No description provided for @sellerMemberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since 2022'**
  String get sellerMemberSince;

  /// No description provided for @ratingValue.
  ///
  /// In en, this message translates to:
  /// **'★ 4.9'**
  String get ratingValue;

  /// No description provided for @ratingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} ratings'**
  String ratingCount(int count);

  /// No description provided for @sellingListings.
  ///
  /// In en, this message translates to:
  /// **'Listings for sale'**
  String get sellingListings;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @viewListings.
  ///
  /// In en, this message translates to:
  /// **'View listings'**
  String get viewListings;

  /// No description provided for @listingCountShort.
  ///
  /// In en, this message translates to:
  /// **'{count} listings ›'**
  String listingCountShort(int count);

  /// No description provided for @reportSeller.
  ///
  /// In en, this message translates to:
  /// **'Report seller'**
  String get reportSeller;

  /// No description provided for @sellerRatingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Seller ratings'**
  String get sellerRatingsTitle;

  /// No description provided for @communityReviews.
  ///
  /// In en, this message translates to:
  /// **'Community reviews'**
  String get communityReviews;

  /// No description provided for @reviewCount.
  ///
  /// In en, this message translates to:
  /// **'{count} reviews'**
  String reviewCount(int count);

  /// No description provided for @writeReview.
  ///
  /// In en, this message translates to:
  /// **'Write a review'**
  String get writeReview;

  /// No description provided for @leaveReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Write review'**
  String get leaveReviewTitle;

  /// No description provided for @sellerRoleArea.
  ///
  /// In en, this message translates to:
  /// **'Seller · District 1, HCMC'**
  String get sellerRoleArea;

  /// No description provided for @reviewQuestion.
  ///
  /// In en, this message translates to:
  /// **'How would you rate the seller?'**
  String get reviewQuestion;

  /// No description provided for @starSelection.
  ///
  /// In en, this message translates to:
  /// **'{count} stars · {label}'**
  String starSelection(int count, String label);

  /// No description provided for @veryGood.
  ///
  /// In en, this message translates to:
  /// **'Very good'**
  String get veryGood;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// No description provided for @optionalReview.
  ///
  /// In en, this message translates to:
  /// **'Review (optional)'**
  String get optionalReview;

  /// No description provided for @reviewHint.
  ///
  /// In en, this message translates to:
  /// **'Share your exchange experience...'**
  String get reviewHint;

  /// No description provided for @reviewGuidance.
  ///
  /// In en, this message translates to:
  /// **'Reviews help the community understand sellers. Please share your exchange experience.'**
  String get reviewGuidance;

  /// No description provided for @submitReview.
  ///
  /// In en, this message translates to:
  /// **'Submit review'**
  String get submitReview;

  /// No description provided for @reportListing.
  ///
  /// In en, this message translates to:
  /// **'Report listing'**
  String get reportListing;

  /// No description provided for @reportUser.
  ///
  /// In en, this message translates to:
  /// **'Report user'**
  String get reportUser;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @reportReason.
  ///
  /// In en, this message translates to:
  /// **'Report reason'**
  String get reportReason;

  /// No description provided for @inappropriateContent.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate content'**
  String get inappropriateContent;

  /// No description provided for @suspectedFraud.
  ///
  /// In en, this message translates to:
  /// **'Suspected fraud'**
  String get suspectedFraud;

  /// No description provided for @prohibitedProduct.
  ///
  /// In en, this message translates to:
  /// **'Prohibited product'**
  String get prohibitedProduct;

  /// No description provided for @misleadingInformation.
  ///
  /// In en, this message translates to:
  /// **'Misleading information'**
  String get misleadingInformation;

  /// No description provided for @spam.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get spam;

  /// No description provided for @otherReason.
  ///
  /// In en, this message translates to:
  /// **'Other reason'**
  String get otherReason;

  /// No description provided for @optionalDescription.
  ///
  /// In en, this message translates to:
  /// **'Additional description (optional)'**
  String get optionalDescription;

  /// No description provided for @reportDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Add information to help us review...'**
  String get reportDescriptionHint;

  /// No description provided for @submitReport.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get submitReport;

  /// No description provided for @reportSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Report submitted'**
  String get reportSuccessTitle;

  /// No description provided for @reportSuccessDescription.
  ///
  /// In en, this message translates to:
  /// **'Thank you for helping keep ReStore safe. Our moderation team will review this content.'**
  String get reportSuccessDescription;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get goBack;

  /// No description provided for @reportedListingTitle.
  ///
  /// In en, this message translates to:
  /// **'Canon AE-1 camera + 50mm lens'**
  String get reportedListingTitle;

  /// No description provided for @reportedListingMeta.
  ///
  /// In en, this message translates to:
  /// **'Listing by Minh Anh · District 1'**
  String get reportedListingMeta;

  /// No description provided for @aiSampleCameraQuery.
  ///
  /// In en, this message translates to:
  /// **'Find a film camera under 4 million'**
  String get aiSampleCameraQuery;

  /// No description provided for @aiSampleGamingQuery.
  ///
  /// In en, this message translates to:
  /// **'Find a gaming laptop under 15 million'**
  String get aiSampleGamingQuery;

  /// No description provided for @aiSampleIphoneQuery.
  ///
  /// In en, this message translates to:
  /// **'Find an old iPhone under 10 million'**
  String get aiSampleIphoneQuery;

  /// No description provided for @aiSampleStudentLaptopQuery.
  ///
  /// In en, this message translates to:
  /// **'Find a laptop for students'**
  String get aiSampleStudentLaptopQuery;

  /// No description provided for @aiStartOver.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get aiStartOver;

  /// No description provided for @aiEmptyStateMenu.
  ///
  /// In en, this message translates to:
  /// **'View empty state'**
  String get aiEmptyStateMenu;

  /// No description provided for @aiErrorStateMenu.
  ///
  /// In en, this message translates to:
  /// **'View error state'**
  String get aiErrorStateMenu;

  /// No description provided for @aiInputHint.
  ///
  /// In en, this message translates to:
  /// **'Ask about products, price, area...'**
  String get aiInputHint;

  /// No description provided for @askRestoreAi.
  ///
  /// In en, this message translates to:
  /// **'Ask ReStore AI'**
  String get askRestoreAi;

  /// No description provided for @aiIntro.
  ///
  /// In en, this message translates to:
  /// **'Describe what you need. AI will find and compare suitable ReStore listings.'**
  String get aiIntro;

  /// No description provided for @quickPrompts.
  ///
  /// In en, this message translates to:
  /// **'Quick prompts'**
  String get quickPrompts;

  /// No description provided for @sellerOwnsListings.
  ///
  /// In en, this message translates to:
  /// **'Listings belong to sellers'**
  String get sellerOwnsListings;

  /// No description provided for @sellerOwnsListingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Open a listing and contact the seller directly when interested.'**
  String get sellerOwnsListingsDescription;

  /// No description provided for @continueConversation.
  ///
  /// In en, this message translates to:
  /// **'You can continue asking in the same conversation'**
  String get continueConversation;

  /// No description provided for @continueConversationTips.
  ///
  /// In en, this message translates to:
  /// **'• Limit price and area\n• Choose brand or condition\n• Compare listing information'**
  String get continueConversationTips;

  /// No description provided for @aiDefaultQuery.
  ///
  /// In en, this message translates to:
  /// **'Find a film camera under 4 million in HCMC'**
  String get aiDefaultQuery;

  /// No description provided for @aiResultsMessage.
  ///
  /// In en, this message translates to:
  /// **'I found 2 matching film camera listings. Open either listing to see more.'**
  String get aiResultsMessage;

  /// No description provided for @aiFilteredMessage.
  ///
  /// In en, this message translates to:
  /// **'I updated the results using your new request.'**
  String get aiFilteredMessage;

  /// No description provided for @matchingListingsDemo.
  ///
  /// In en, this message translates to:
  /// **'MATCHING LISTINGS · DEMO DATA'**
  String get matchingListingsDemo;

  /// No description provided for @canonListingTitle.
  ///
  /// In en, this message translates to:
  /// **'Canon AE-1 + 50mm lens'**
  String get canonListingTitle;

  /// No description provided for @canonPrice.
  ///
  /// In en, this message translates to:
  /// **'2,450,000 đ'**
  String get canonPrice;

  /// No description provided for @canonLocationTime.
  ///
  /// In en, this message translates to:
  /// **'District 1 · 2 hours ago'**
  String get canonLocationTime;

  /// No description provided for @nikonListingTitle.
  ///
  /// In en, this message translates to:
  /// **'Nikon FM2 camera'**
  String get nikonListingTitle;

  /// No description provided for @nikonPrice.
  ///
  /// In en, this message translates to:
  /// **'3,800,000 đ'**
  String get nikonPrice;

  /// No description provided for @nikonLocationTime.
  ///
  /// In en, this message translates to:
  /// **'District 10 · Yesterday'**
  String get nikonLocationTime;

  /// No description provided for @sellerDataCaveat.
  ///
  /// In en, this message translates to:
  /// **'Price and condition are based on seller-provided information.'**
  String get sellerDataCaveat;

  /// No description provided for @youCanAskNext.
  ///
  /// In en, this message translates to:
  /// **'You can ask next:'**
  String get youCanAskNext;

  /// No description provided for @canonOnly.
  ///
  /// In en, this message translates to:
  /// **'Canon only'**
  String get canonOnly;

  /// No description provided for @compareTheseTwo.
  ///
  /// In en, this message translates to:
  /// **'Compare these two'**
  String get compareTheseTwo;

  /// No description provided for @comparisonMessage.
  ///
  /// In en, this message translates to:
  /// **'I compared the information in these two ReStore listings.'**
  String get comparisonMessage;

  /// No description provided for @canonVsNikon.
  ///
  /// In en, this message translates to:
  /// **'Canon AE-1 and Nikon FM2'**
  String get canonVsNikon;

  /// No description provided for @listing.
  ///
  /// In en, this message translates to:
  /// **'Listing'**
  String get listing;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @condition.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get condition;

  /// No description provided for @area.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get area;

  /// No description provided for @posted.
  ///
  /// In en, this message translates to:
  /// **'Posted'**
  String get posted;

  /// No description provided for @goodCondition.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get goodCondition;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// No description provided for @twoHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'2 hours ago'**
  String get twoHoursAgo;

  /// No description provided for @sellerInfoOnly.
  ///
  /// In en, this message translates to:
  /// **'Based only on information provided by sellers.'**
  String get sellerInfoOnly;

  /// No description provided for @viewCanon.
  ///
  /// In en, this message translates to:
  /// **'View Canon →'**
  String get viewCanon;

  /// No description provided for @viewNikon.
  ///
  /// In en, this message translates to:
  /// **'View Nikon →'**
  String get viewNikon;

  /// No description provided for @aiEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching listings'**
  String get aiEmptyTitle;

  /// No description provided for @aiEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Try a wider area, a higher price range, or a shorter product description.'**
  String get aiEmptyDescription;

  /// No description provided for @adjustRequest.
  ///
  /// In en, this message translates to:
  /// **'Adjust request'**
  String get adjustRequest;

  /// No description provided for @aiErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to answer right now'**
  String get aiErrorTitle;

  /// No description provided for @aiErrorDescription.
  ///
  /// In en, this message translates to:
  /// **'Your conversation is preserved. You can retry without entering it again.'**
  String get aiErrorDescription;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @featureApiPending.
  ///
  /// In en, this message translates to:
  /// **'{action} will be connected in the API phase.'**
  String featureApiPending(String action);

  /// No description provided for @createListing.
  ///
  /// In en, this message translates to:
  /// **'Create listing'**
  String get createListing;

  /// No description provided for @editListing.
  ///
  /// In en, this message translates to:
  /// **'Edit listing'**
  String get editListing;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @stepCount.
  ///
  /// In en, this message translates to:
  /// **'{current}/{total}'**
  String stepCount(int current, int total);

  /// No description provided for @productPhotosCount.
  ///
  /// In en, this message translates to:
  /// **'Product photos · {count}/10'**
  String productPhotosCount(int count);

  /// No description provided for @addPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add photos'**
  String get addPhotos;

  /// No description provided for @firstPhotoHint.
  ///
  /// In en, this message translates to:
  /// **'The first photo is the cover · Hold and drag to reorder'**
  String get firstPhotoHint;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get productName;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @electronicsCamera.
  ///
  /// In en, this message translates to:
  /// **'Electronics › Camera'**
  String get electronicsCamera;

  /// No description provided for @newCondition.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newCondition;

  /// No description provided for @usedCondition.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get usedCondition;

  /// No description provided for @photoTip.
  ///
  /// In en, this message translates to:
  /// **'Tip: clear photos from multiple angles make your listing more trustworthy.'**
  String get photoTip;

  /// No description provided for @salePrice.
  ///
  /// In en, this message translates to:
  /// **'Sale price'**
  String get salePrice;

  /// No description provided for @priceVndHint.
  ///
  /// In en, this message translates to:
  /// **'Enter price in VND'**
  String get priceVndHint;

  /// No description provided for @negotiable.
  ///
  /// In en, this message translates to:
  /// **'Negotiable'**
  String get negotiable;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @contactPreference.
  ///
  /// In en, this message translates to:
  /// **'Preferred contact'**
  String get contactPreference;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @directArrangementNote.
  ///
  /// In en, this message translates to:
  /// **'Buyers and sellers arrange delivery and payment themselves.'**
  String get directArrangementNote;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @publishListing.
  ///
  /// In en, this message translates to:
  /// **'Publish listing'**
  String get publishListing;

  /// No description provided for @boostListing.
  ///
  /// In en, this message translates to:
  /// **'Boost listing'**
  String get boostListing;

  /// No description provided for @boostVisibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Increase visibility'**
  String get boostVisibilityTitle;

  /// No description provided for @boostVisibilityDescription.
  ///
  /// In en, this message translates to:
  /// **'Your listing is prioritized during the selected period. This does not guarantee a buyer.'**
  String get boostVisibilityDescription;

  /// No description provided for @selectBoostDuration.
  ///
  /// In en, this message translates to:
  /// **'Choose boost duration'**
  String get selectBoostDuration;

  /// No description provided for @boost24Hours.
  ///
  /// In en, this message translates to:
  /// **'Boost for 24 hours'**
  String get boost24Hours;

  /// No description provided for @boost3Days.
  ///
  /// In en, this message translates to:
  /// **'Boost for 3 days'**
  String get boost3Days;

  /// No description provided for @boost7Days.
  ///
  /// In en, this message translates to:
  /// **'Boost for 7 days'**
  String get boost7Days;

  /// No description provided for @visible24Hours.
  ///
  /// In en, this message translates to:
  /// **'Priority visibility for 24 hours'**
  String get visible24Hours;

  /// No description provided for @visible3Days.
  ///
  /// In en, this message translates to:
  /// **'Continuous priority visibility for 3 days'**
  String get visible3Days;

  /// No description provided for @visible7Days.
  ///
  /// In en, this message translates to:
  /// **'Continuous priority visibility for 7 days'**
  String get visible7Days;

  /// No description provided for @boostPrice24.
  ///
  /// In en, this message translates to:
  /// **'19,000 đ'**
  String get boostPrice24;

  /// No description provided for @boostPrice3Days.
  ///
  /// In en, this message translates to:
  /// **'49,000 đ'**
  String get boostPrice3Days;

  /// No description provided for @boostPrice7Days.
  ///
  /// In en, this message translates to:
  /// **'99,000 đ'**
  String get boostPrice7Days;

  /// No description provided for @boostDemoPriceNote.
  ///
  /// In en, this message translates to:
  /// **'Demo service price · official pricing will be confirmed later.'**
  String get boostDemoPriceNote;

  /// No description provided for @confirmPromotionService.
  ///
  /// In en, this message translates to:
  /// **'Confirm promotion service'**
  String get confirmPromotionService;

  /// No description provided for @currentListing.
  ///
  /// In en, this message translates to:
  /// **'Current listing'**
  String get currentListing;

  /// No description provided for @listingVisibilityStatus.
  ///
  /// In en, this message translates to:
  /// **'Visible · Current listing'**
  String get listingVisibilityStatus;

  /// No description provided for @boostPackage.
  ///
  /// In en, this message translates to:
  /// **'Boost package'**
  String get boostPackage;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @serviceFee.
  ///
  /// In en, this message translates to:
  /// **'Service fee'**
  String get serviceFee;

  /// No description provided for @totalServiceFee.
  ///
  /// In en, this message translates to:
  /// **'Total service fee'**
  String get totalServiceFee;

  /// No description provided for @threeDays.
  ///
  /// In en, this message translates to:
  /// **'3 days'**
  String get threeDays;

  /// No description provided for @seventyTwoHours.
  ///
  /// In en, this message translates to:
  /// **'72 hours'**
  String get seventyTwoHours;

  /// No description provided for @restoreServiceFee.
  ///
  /// In en, this message translates to:
  /// **'ReStore service fee'**
  String get restoreServiceFee;

  /// No description provided for @boostServiceBoundary.
  ///
  /// In en, this message translates to:
  /// **'You are paying to promote your listing, not paying for the product. ReStore does not collect buyer-seller payments.'**
  String get boostServiceBoundary;

  /// No description provided for @continuePayment.
  ///
  /// In en, this message translates to:
  /// **'Continue to payment'**
  String get continuePayment;

  /// No description provided for @servicePayment.
  ///
  /// In en, this message translates to:
  /// **'Service payment'**
  String get servicePayment;

  /// No description provided for @vnpay.
  ///
  /// In en, this message translates to:
  /// **'VNPay'**
  String get vnpay;

  /// No description provided for @vnpayDescription.
  ///
  /// In en, this message translates to:
  /// **'Pay the listing promotion fee through VNPay'**
  String get vnpayDescription;

  /// No description provided for @confirmPayment.
  ///
  /// In en, this message translates to:
  /// **'Confirm payment'**
  String get confirmPayment;

  /// No description provided for @paymentResult.
  ///
  /// In en, this message translates to:
  /// **'Payment result'**
  String get paymentResult;

  /// No description provided for @paymentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Payment successful'**
  String get paymentSuccess;

  /// No description provided for @boostActivatedDescription.
  ///
  /// In en, this message translates to:
  /// **'Your listing was boosted successfully'**
  String get boostActivatedDescription;

  /// No description provided for @transactionDetails.
  ///
  /// In en, this message translates to:
  /// **'Transaction details'**
  String get transactionDetails;

  /// No description provided for @transactionCode.
  ///
  /// In en, this message translates to:
  /// **'Transaction code'**
  String get transactionCode;

  /// No description provided for @transactionCodeValue.
  ///
  /// In en, this message translates to:
  /// **'RST-BST-260925-0842'**
  String get transactionCodeValue;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @boostPeriod.
  ///
  /// In en, this message translates to:
  /// **'Boost period'**
  String get boostPeriod;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get paymentMethod;

  /// No description provided for @viewListing.
  ///
  /// In en, this message translates to:
  /// **'View listing'**
  String get viewListing;

  /// No description provided for @backToManageListings.
  ///
  /// In en, this message translates to:
  /// **'Back to manage listings'**
  String get backToManageListings;

  /// No description provided for @activeBoost.
  ///
  /// In en, this message translates to:
  /// **'Boost active'**
  String get activeBoost;

  /// No description provided for @activeBoostDescription.
  ///
  /// In en, this message translates to:
  /// **'This listing is being prioritized until the promotion ends.'**
  String get activeBoostDescription;

  /// No description provided for @expiredBoost.
  ///
  /// In en, this message translates to:
  /// **'Boost expired'**
  String get expiredBoost;

  /// No description provided for @expiredBoostDescription.
  ///
  /// In en, this message translates to:
  /// **'The promotion ended. Your listing remains publicly visible.'**
  String get expiredBoostDescription;

  /// No description provided for @boostUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Boost unavailable'**
  String get boostUnavailable;

  /// No description provided for @boostUnavailableDescription.
  ///
  /// In en, this message translates to:
  /// **'Only active, approved listings can be boosted.'**
  String get boostUnavailableDescription;

  /// No description provided for @boostAgain.
  ///
  /// In en, this message translates to:
  /// **'Boost again'**
  String get boostAgain;

  /// No description provided for @boostPaymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment failed'**
  String get boostPaymentFailed;

  /// No description provided for @boostPaymentCancelled.
  ///
  /// In en, this message translates to:
  /// **'Payment cancelled'**
  String get boostPaymentCancelled;

  /// No description provided for @boostPaymentPending.
  ///
  /// In en, this message translates to:
  /// **'Payment verification pending'**
  String get boostPaymentPending;

  /// No description provided for @tryPaymentAgain.
  ///
  /// In en, this message translates to:
  /// **'Try payment again'**
  String get tryPaymentAgain;

  /// No description provided for @manageListings.
  ///
  /// In en, this message translates to:
  /// **'Manage listings'**
  String get manageListings;

  /// No description provided for @newListing.
  ///
  /// In en, this message translates to:
  /// **'New listing'**
  String get newListing;

  /// No description provided for @visibleStatus.
  ///
  /// In en, this message translates to:
  /// **'Visible'**
  String get visibleStatus;

  /// No description provided for @pendingStatus.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingStatus;

  /// No description provided for @hiddenStatus.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get hiddenStatus;

  /// No description provided for @soldStatus.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get soldStatus;

  /// No description provided for @listingStatusCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {status}'**
  String listingStatusCount(int count, String status);

  /// No description provided for @editAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editAction;

  /// No description provided for @hideListing.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hideListing;

  /// No description provided for @markAsSold.
  ///
  /// In en, this message translates to:
  /// **'Mark as sold'**
  String get markAsSold;

  /// No description provided for @deleteListing.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteListing;

  /// No description provided for @showAgain.
  ///
  /// In en, this message translates to:
  /// **'Show again'**
  String get showAgain;

  /// No description provided for @pendingStatusNote.
  ///
  /// In en, this message translates to:
  /// **'This listing is being reviewed before it becomes visible.'**
  String get pendingStatusNote;

  /// No description provided for @hiddenStatusNote.
  ///
  /// In en, this message translates to:
  /// **'This listing is hidden and buyers cannot find it in search results.'**
  String get hiddenStatusNote;

  /// No description provided for @soldStatusNote.
  ///
  /// In en, this message translates to:
  /// **'Sold listings no longer appear in search results.'**
  String get soldStatusNote;

  /// No description provided for @markSoldTitle.
  ///
  /// In en, this message translates to:
  /// **'Mark listing as sold?'**
  String get markSoldTitle;

  /// No description provided for @markSoldDescription.
  ///
  /// In en, this message translates to:
  /// **'The listing will no longer be available to buyers.'**
  String get markSoldDescription;

  /// No description provided for @platformNoOrderPayment.
  ///
  /// In en, this message translates to:
  /// **'This action does not create an order or transaction. ReStore does not process payment.'**
  String get platformNoOrderPayment;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @messagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messagesTitle;

  /// No description provided for @listingDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Listing details'**
  String get listingDetailTitle;

  /// No description provided for @listingPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Listing preview'**
  String get listingPreviewTitle;

  /// No description provided for @galleryPosition.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total}'**
  String galleryPosition(int current, int total);

  /// No description provided for @listingLocationMeta.
  ///
  /// In en, this message translates to:
  /// **'⌖ District 1, Ho Chi Minh City · Posted 2 hours ago'**
  String get listingLocationMeta;

  /// No description provided for @usedGoodCondition.
  ///
  /// In en, this message translates to:
  /// **'Used · Good condition'**
  String get usedGoodCondition;

  /// No description provided for @productDescription.
  ///
  /// In en, this message translates to:
  /// **'Product description'**
  String get productDescription;

  /// No description provided for @canonDescription.
  ///
  /// In en, this message translates to:
  /// **'Canon AE-1 works well with an accurate light meter. Includes an FD 50mm f/1.8 lens, strap, and leather case. Available to inspect in District 1.'**
  String get canonDescription;

  /// No description provided for @sellerRatingMeta.
  ///
  /// In en, this message translates to:
  /// **'★ 4.9 · 48 ratings · Quick response'**
  String get sellerRatingMeta;

  /// No description provided for @similarListings.
  ///
  /// In en, this message translates to:
  /// **'Similar listings'**
  String get similarListings;

  /// No description provided for @seeMore.
  ///
  /// In en, this message translates to:
  /// **'See more ›'**
  String get seeMore;

  /// No description provided for @makeOffer.
  ///
  /// In en, this message translates to:
  /// **'Make offer'**
  String get makeOffer;

  /// No description provided for @chooseCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose category'**
  String get chooseCategoryTitle;

  /// No description provided for @chooseCategorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'What do you want to sell?'**
  String get chooseCategorySubtitle;

  /// No description provided for @categoryElectronicsTitle.
  ///
  /// In en, this message translates to:
  /// **'Electronics'**
  String get categoryElectronicsTitle;

  /// No description provided for @categoryElectronicsDesc.
  ///
  /// In en, this message translates to:
  /// **'Laptops, Cameras, Headphones,...'**
  String get categoryElectronicsDesc;

  /// No description provided for @categoryVehiclesTitle.
  ///
  /// In en, this message translates to:
  /// **'Vehicles'**
  String get categoryVehiclesTitle;

  /// No description provided for @categoryVehiclesDesc.
  ///
  /// In en, this message translates to:
  /// **'Motorbikes, Bicycles, Cars, Parts,...'**
  String get categoryVehiclesDesc;

  /// No description provided for @categoryFashionTitle.
  ///
  /// In en, this message translates to:
  /// **'Fashion'**
  String get categoryFashionTitle;

  /// No description provided for @categoryFashionDesc.
  ///
  /// In en, this message translates to:
  /// **'Clothes, Shoes, Bags,...'**
  String get categoryFashionDesc;

  /// No description provided for @categoryHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get categoryHomeTitle;

  /// No description provided for @categoryHomeDesc.
  ///
  /// In en, this message translates to:
  /// **'Furniture, Lighting, Kitchenware, Decor,...'**
  String get categoryHomeDesc;

  /// No description provided for @step1Title.
  ///
  /// In en, this message translates to:
  /// **'Photos & Product'**
  String get step1Title;

  /// No description provided for @productPhotosInfo.
  ///
  /// In en, this message translates to:
  /// **'Product photos · {count}/10'**
  String productPhotosInfo(int count);

  /// No description provided for @coverImageHint.
  ///
  /// In en, this message translates to:
  /// **'First photo is cover · Tap a photo to set as cover'**
  String get coverImageHint;

  /// No description provided for @productNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get productNameLabel;

  /// No description provided for @productNameMinLengthError.
  ///
  /// In en, this message translates to:
  /// **'Product name must be at least 5 characters'**
  String get productNameMinLengthError;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @conditionLabel.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get conditionLabel;

  /// No description provided for @continueBtn.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueBtn;

  /// No description provided for @completeListingTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete listing'**
  String get completeListingTitle;

  /// No description provided for @saveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get saveDraft;

  /// No description provided for @draftSaved.
  ///
  /// In en, this message translates to:
  /// **'Draft saved'**
  String get draftSaved;

  /// No description provided for @listingPhotosLabel.
  ///
  /// In en, this message translates to:
  /// **'Photos (up to {max} photos)'**
  String listingPhotosLabel(int max);

  /// No description provided for @photoCount.
  ///
  /// In en, this message translates to:
  /// **'{count}/{max}'**
  String photoCount(int count, int max);

  /// No description provided for @coverPhotoBadge.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get coverPhotoBadge;

  /// No description provided for @photosRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please add at least 1 photo'**
  String get photosRequiredError;

  /// No description provided for @detailedDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Detailed description'**
  String get detailedDescriptionLabel;

  /// No description provided for @listingDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'- Condition, how long it has been used\n- Included accessories, minor defects if any\n- Reason for selling, delivery method'**
  String get listingDescriptionHint;

  /// No description provided for @characterCount.
  ///
  /// In en, this message translates to:
  /// **'{count}/{max} characters'**
  String characterCount(int count, int max);

  /// No description provided for @descriptionMinLengthError.
  ///
  /// In en, this message translates to:
  /// **'Description must be at least {min} characters'**
  String descriptionMinLengthError(int min);

  /// No description provided for @listingTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Listing title'**
  String get listingTitleLabel;

  /// No description provided for @listingTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Piaggio Vespa Sprint 2024 15,000 km'**
  String get listingTitleHint;

  /// No description provided for @listingTitleMinLengthError.
  ///
  /// In en, this message translates to:
  /// **'Title must be at least {min} characters'**
  String listingTitleMinLengthError(int min);

  /// No description provided for @priceRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a sale price'**
  String get priceRequiredError;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressLabel;

  /// No description provided for @youAreLabel.
  ///
  /// In en, this message translates to:
  /// **'You are'**
  String get youAreLabel;

  /// No description provided for @sellerPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get sellerPersonal;

  /// No description provided for @sellerBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get sellerBusiness;

  /// No description provided for @detailedInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Detailed information'**
  String get detailedInfoTitle;

  /// No description provided for @categoryWithName.
  ///
  /// In en, this message translates to:
  /// **'Category: {name}'**
  String categoryWithName(String name);

  /// No description provided for @fieldRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please fill in this field'**
  String get fieldRequiredError;

  /// No description provided for @fieldSelectRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please select an option'**
  String get fieldSelectRequiredError;

  /// No description provided for @missingRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Please complete all required fields'**
  String get missingRequiredFields;

  /// No description provided for @listingSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Your listing has been submitted and is waiting for review'**
  String get listingSubmitted;

  /// No description provided for @previewNotice.
  ///
  /// In en, this message translates to:
  /// **'This is how buyers will see your listing'**
  String get previewNotice;

  /// No description provided for @noPhotosYet.
  ///
  /// In en, this message translates to:
  /// **'No photos yet'**
  String get noPhotosYet;

  /// No description provided for @stepBasicInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Photos, description & price'**
  String get stepBasicInfoTitle;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @photoLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You can add up to {max} photos'**
  String photoLimitReached(int max);

  /// No description provided for @photoPickFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open your photos. Please check the app\'s photo and camera permissions.'**
  String get photoPickFailed;

  /// No description provided for @draftSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the draft, please try again'**
  String get draftSaveFailed;

  /// No description provided for @publishFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t publish the listing, please try again'**
  String get publishFailed;

  /// No description provided for @tradeTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Trade type'**
  String get tradeTypeLabel;

  /// No description provided for @tradeSell.
  ///
  /// In en, this message translates to:
  /// **'Sell'**
  String get tradeSell;

  /// No description provided for @tradeExchange.
  ///
  /// In en, this message translates to:
  /// **'Exchange'**
  String get tradeExchange;

  /// No description provided for @tradeSellOrExchange.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get tradeSellOrExchange;

  /// No description provided for @tradeExchangeAccepted.
  ///
  /// In en, this message translates to:
  /// **'Open to exchange'**
  String get tradeExchangeAccepted;

  /// No description provided for @exchangeWishLabel.
  ///
  /// In en, this message translates to:
  /// **'Want to exchange for'**
  String get exchangeWishLabel;

  /// No description provided for @exchangeWishHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. iPhone 13 or a tablet'**
  String get exchangeWishHint;

  /// No description provided for @selectAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Choose an area'**
  String get selectAddressHint;

  /// No description provided for @stepShortCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get stepShortCategory;

  /// No description provided for @stepShortBasicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basics'**
  String get stepShortBasicInfo;

  /// No description provided for @stepShortDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get stepShortDetails;

  /// No description provided for @stepProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'Step {current}/{total}'**
  String stepProgressLabel(int current, int total);

  /// No description provided for @nextStepLabel.
  ///
  /// In en, this message translates to:
  /// **'Next: {name}'**
  String nextStepLabel(String name);

  /// No description provided for @conditionSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Item condition'**
  String get conditionSectionTitle;

  /// No description provided for @conditionNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get conditionNew;

  /// No description provided for @conditionLikeNew.
  ///
  /// In en, this message translates to:
  /// **'Like new'**
  String get conditionLikeNew;

  /// No description provided for @conditionUsedGood.
  ///
  /// In en, this message translates to:
  /// **'Used - good'**
  String get conditionUsedGood;

  /// No description provided for @conditionUsedFair.
  ///
  /// In en, this message translates to:
  /// **'Used - fair'**
  String get conditionUsedFair;

  /// No description provided for @conditionForParts.
  ///
  /// In en, this message translates to:
  /// **'For parts / not working'**
  String get conditionForParts;

  /// No description provided for @conditionNewDesc.
  ///
  /// In en, this message translates to:
  /// **'Never used, original packaging'**
  String get conditionNewDesc;

  /// No description provided for @conditionLikeNewDesc.
  ///
  /// In en, this message translates to:
  /// **'Barely used, no visible marks'**
  String get conditionLikeNewDesc;

  /// No description provided for @conditionUsedGoodDesc.
  ///
  /// In en, this message translates to:
  /// **'Works well, minor signs of use'**
  String get conditionUsedGoodDesc;

  /// No description provided for @conditionUsedFairDesc.
  ///
  /// In en, this message translates to:
  /// **'Usable, visible wear or minor faults'**
  String get conditionUsedFairDesc;

  /// No description provided for @conditionForPartsDesc.
  ///
  /// In en, this message translates to:
  /// **'Does not work properly'**
  String get conditionForPartsDesc;

  /// No description provided for @categoryAttributesTitle.
  ///
  /// In en, this message translates to:
  /// **'Category details'**
  String get categoryAttributesTitle;

  /// No description provided for @categoryAttributesHint.
  ///
  /// In en, this message translates to:
  /// **'Fields below depend on the category'**
  String get categoryAttributesHint;

  /// No description provided for @selectOptionHint.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selectOptionHint;

  /// No description provided for @numberRangeError.
  ///
  /// In en, this message translates to:
  /// **'Value must be between {min} and {max}'**
  String numberRangeError(String min, String max);

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @loadCategoriesFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load categories'**
  String get loadCategoriesFailedTitle;

  /// No description provided for @loadCategoriesFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again'**
  String get loadCategoriesFailedMessage;

  /// No description provided for @negotiableHint.
  ///
  /// In en, this message translates to:
  /// **'Buyers can make offers in chat'**
  String get negotiableHint;

  /// No description provided for @addressNearbyHint.
  ///
  /// In en, this message translates to:
  /// **'Helps nearby buyers find your listing'**
  String get addressNearbyHint;

  /// No description provided for @privateStreetAddress.
  ///
  /// In en, this message translates to:
  /// **'{street} (private)'**
  String privateStreetAddress(String street);

  /// No description provided for @addressSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Item location'**
  String get addressSheetTitle;

  /// No description provided for @useCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my current location'**
  String get useCurrentLocation;

  /// No description provided for @useCurrentLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Fill in province and ward automatically'**
  String get useCurrentLocationHint;

  /// No description provided for @locatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Getting your location...'**
  String get locatingLabel;

  /// No description provided for @locationDetected.
  ///
  /// In en, this message translates to:
  /// **'Location detected'**
  String get locationDetected;

  /// No description provided for @orChooseManually.
  ///
  /// In en, this message translates to:
  /// **'or choose manually'**
  String get orChooseManually;

  /// No description provided for @provinceLabel.
  ///
  /// In en, this message translates to:
  /// **'Province/City'**
  String get provinceLabel;

  /// No description provided for @selectProvinceHint.
  ///
  /// In en, this message translates to:
  /// **'Select province/city'**
  String get selectProvinceHint;

  /// No description provided for @wardLabel.
  ///
  /// In en, this message translates to:
  /// **'Ward/Commune'**
  String get wardLabel;

  /// No description provided for @selectWardHint.
  ///
  /// In en, this message translates to:
  /// **'Select ward/commune'**
  String get selectWardHint;

  /// No description provided for @selectProvinceFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a province first'**
  String get selectProvinceFirst;

  /// No description provided for @streetAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'House number, street'**
  String get streetAddressLabel;

  /// No description provided for @streetAddressHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 12 Nguyen Hue'**
  String get streetAddressHint;

  /// No description provided for @streetAddressHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional, never shown publicly'**
  String get streetAddressHelper;

  /// No description provided for @addressPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Buyers only see the ward and province. Your location is used to show listings near you.'**
  String get addressPrivacyNote;

  /// No description provided for @confirmAddress.
  ///
  /// In en, this message translates to:
  /// **'Confirm address'**
  String get confirmAddress;

  /// No description provided for @loadingLocations.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loadingLocations;

  /// No description provided for @loadLocationsFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the list, tap to retry'**
  String get loadLocationsFailed;

  /// No description provided for @locationServiceDisabled.
  ///
  /// In en, this message translates to:
  /// **'Turn on location services to continue'**
  String get locationServiceDisabled;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission was denied'**
  String get locationPermissionDenied;

  /// No description provided for @locationPermissionDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location access is blocked, enable it in Settings'**
  String get locationPermissionDeniedForever;

  /// No description provided for @locationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get your location, please choose manually'**
  String get locationUnavailable;

  /// No description provided for @locationOutOfCoverage.
  ///
  /// In en, this message translates to:
  /// **'Your location didn’t match any ward. Please choose it manually below.'**
  String get locationOutOfCoverage;

  /// No description provided for @searchOptionHint.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchOptionHint;

  /// No description provided for @noMatchingOptions.
  ///
  /// In en, this message translates to:
  /// **'No matching results'**
  String get noMatchingOptions;

  /// No description provided for @locationOutsideVietnamTitle.
  ///
  /// In en, this message translates to:
  /// **'Looks like you’re outside Vietnam'**
  String get locationOutsideVietnamTitle;

  /// No description provided for @locationOutsideVietnamBody.
  ///
  /// In en, this message translates to:
  /// **'ReStore only supports addresses in Vietnam for now. Please pick your province and ward below.'**
  String get locationOutsideVietnamBody;

  /// No description provided for @locationOutOfCoverageTitle.
  ///
  /// In en, this message translates to:
  /// **'We don’t recognise this area yet'**
  String get locationOutOfCoverageTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
