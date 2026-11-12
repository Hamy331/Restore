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

  /// No description provided for @feedForYou.
  ///
  /// In en, this message translates to:
  /// **'For you'**
  String get feedForYou;

  /// No description provided for @feedFollowing.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get feedFollowing;

  /// No description provided for @feedCompose.
  ///
  /// In en, this message translates to:
  /// **'Share a find or a story…'**
  String get feedCompose;

  /// No description provided for @feedFollow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get feedFollow;

  /// No description provided for @feedUnfollow.
  ///
  /// In en, this message translates to:
  /// **'Unfollow'**
  String get feedUnfollow;

  /// No description provided for @feedPost.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get feedPost;

  /// No description provided for @feedNewPost.
  ///
  /// In en, this message translates to:
  /// **'Create a community post'**
  String get feedNewPost;

  /// No description provided for @feedTextHint.
  ///
  /// In en, this message translates to:
  /// **'What would you like to share?'**
  String get feedTextHint;

  /// No description provided for @feedAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get feedAddPhoto;

  /// No description provided for @feedTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get feedTakePhoto;

  /// No description provided for @feedRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get feedRemovePhoto;

  /// No description provided for @feedComments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get feedComments;

  /// No description provided for @feedCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Write a comment…'**
  String get feedCommentHint;

  /// No description provided for @feedSend.
  ///
  /// In en, this message translates to:
  /// **'Send comment'**
  String get feedSend;

  /// No description provided for @feedLike.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get feedLike;

  /// No description provided for @feedUnlike.
  ///
  /// In en, this message translates to:
  /// **'Unlike'**
  String get feedUnlike;

  /// No description provided for @feedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No posts yet'**
  String get feedEmpty;

  /// No description provided for @feedFollowingEmpty.
  ///
  /// In en, this message translates to:
  /// **'Follow an author to see their posts here.'**
  String get feedFollowingEmpty;

  /// No description provided for @feedLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the feed.'**
  String get feedLoadError;

  /// No description provided for @feedActionError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get feedActionError;

  /// No description provided for @feedPublishError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t publish your post. Please try again.'**
  String get feedPublishError;

  /// No description provided for @feedPhotoError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t select a photo. Please try again.'**
  String get feedPhotoError;

  /// No description provided for @feedYourName.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get feedYourName;

  /// No description provided for @feedNoComments.
  ///
  /// In en, this message translates to:
  /// **'Be the first to comment.'**
  String get feedNoComments;

  /// No description provided for @feedNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications are coming soon.'**
  String get feedNotifications;

  /// No description provided for @feedNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get feedNow;

  /// No description provided for @feedMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute ago} other{{count} minutes ago}}'**
  String feedMinutes(int count);

  /// No description provided for @feedHours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String feedHours(int count);

  /// No description provided for @feedDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String feedDays(int count);

  /// No description provided for @feedLikes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 like} other{{count} likes}}'**
  String feedLikes(int count);

  /// No description provided for @feedCommentCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 comment} other{{count} comments}}'**
  String feedCommentCount(int count);

  /// No description provided for @settingsPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsPageTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageHint.
  ///
  /// In en, this message translates to:
  /// **'Choose the interface language. User posts keep their original language.'**
  String get settingsLanguageHint;

  /// No description provided for @settingsLanguageError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your language preference.'**
  String get settingsLanguageError;

  /// No description provided for @feedRequired.
  ///
  /// In en, this message translates to:
  /// **'Add text or a photo before posting.'**
  String get feedRequired;

  /// No description provided for @feedDraftLimit.
  ///
  /// In en, this message translates to:
  /// **'Up to 2,000 characters'**
  String get feedDraftLimit;

  /// No description provided for @feedDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete post'**
  String get feedDelete;

  /// No description provided for @feedDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this post? This can\'t be undone.'**
  String get feedDeleteConfirm;

  /// No description provided for @feedDeleted.
  ///
  /// In en, this message translates to:
  /// **'Post deleted'**
  String get feedDeleted;

  /// No description provided for @feedReport.
  ///
  /// In en, this message translates to:
  /// **'Report post'**
  String get feedReport;

  /// No description provided for @feedReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Why are you reporting this post?'**
  String get feedReportTitle;

  /// No description provided for @feedReportSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam or advertising'**
  String get feedReportSpam;

  /// No description provided for @feedReportScam.
  ///
  /// In en, this message translates to:
  /// **'Scam or fraud'**
  String get feedReportScam;

  /// No description provided for @feedReportOffensive.
  ///
  /// In en, this message translates to:
  /// **'Offensive content'**
  String get feedReportOffensive;

  /// No description provided for @feedReportOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get feedReportOther;

  /// No description provided for @feedReported.
  ///
  /// In en, this message translates to:
  /// **'Report sent. Thank you!'**
  String get feedReported;

  /// No description provided for @feedViewProfile.
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get feedViewProfile;

  /// No description provided for @feedLoadMoreError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load more posts.'**
  String get feedLoadMoreError;

  /// No description provided for @feedDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard post?'**
  String get feedDiscardTitle;

  /// No description provided for @feedDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'What you\'ve written will be lost.'**
  String get feedDiscardBody;

  /// No description provided for @feedDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get feedDiscard;

  /// No description provided for @feedKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get feedKeepEditing;

  /// No description provided for @feedCharCount.
  ///
  /// In en, this message translates to:
  /// **'{count}/2,000'**
  String feedCharCount(int count);

  /// No description provided for @feedCloseImage.
  ///
  /// In en, this message translates to:
  /// **'Close image'**
  String get feedCloseImage;

  /// No description provided for @accEditPage.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get accEditPage;

  /// No description provided for @accMenu.
  ///
  /// In en, this message translates to:
  /// **'Menu and settings'**
  String get accMenu;

  /// No description provided for @accLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your profile. Tap to retry'**
  String get accLoadError;

  /// No description provided for @accLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get accLoading;

  /// No description provided for @accFollowing.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get accFollowing;

  /// No description provided for @accFollowers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get accFollowers;

  /// No description provided for @accListings.
  ///
  /// In en, this message translates to:
  /// **'Listings'**
  String get accListings;

  /// No description provided for @accPosts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get accPosts;

  /// No description provided for @accAddBio.
  ///
  /// In en, this message translates to:
  /// **'＋  Add a bio'**
  String get accAddBio;

  /// No description provided for @accRating.
  ///
  /// In en, this message translates to:
  /// **'{rating} ({count} reviews)'**
  String accRating(String rating, int count);

  /// No description provided for @accNoRating.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get accNoRating;

  /// No description provided for @accTabVisible.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE ({count})'**
  String accTabVisible(int count);

  /// No description provided for @accTabPending.
  ///
  /// In en, this message translates to:
  /// **'PENDING ({count})'**
  String accTabPending(int count);

  /// No description provided for @accTabHidden.
  ///
  /// In en, this message translates to:
  /// **'HIDDEN ({count})'**
  String accTabHidden(int count);

  /// No description provided for @accEmptyVisible.
  ///
  /// In en, this message translates to:
  /// **'You have no active listings'**
  String get accEmptyVisible;

  /// No description provided for @accEmptyPending.
  ///
  /// In en, this message translates to:
  /// **'No listings awaiting review'**
  String get accEmptyPending;

  /// No description provided for @accEmptyHidden.
  ///
  /// In en, this message translates to:
  /// **'No hidden listings'**
  String get accEmptyHidden;

  /// No description provided for @accPostListing.
  ///
  /// In en, this message translates to:
  /// **'Post a listing'**
  String get accPostListing;

  /// No description provided for @accPosted.
  ///
  /// In en, this message translates to:
  /// **'Posted {time}'**
  String accPosted(String time);

  /// No description provided for @accViews.
  ///
  /// In en, this message translates to:
  /// **'{count} views'**
  String accViews(int count);

  /// No description provided for @accHide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get accHide;

  /// No description provided for @accShow.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get accShow;

  /// No description provided for @accBoost.
  ///
  /// In en, this message translates to:
  /// **'Boost'**
  String get accBoost;

  /// No description provided for @accLoadListingsError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your listings.'**
  String get accLoadListingsError;

  /// No description provided for @accUpdateListingError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update the listing.'**
  String get accUpdateListingError;

  /// No description provided for @accLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get accLogout;

  /// No description provided for @accLogoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Log out of ReStore?'**
  String get accLogoutConfirm;

  /// No description provided for @accCloseMenu.
  ///
  /// In en, this message translates to:
  /// **'Close menu'**
  String get accCloseMenu;

  /// No description provided for @accEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get accEditTitle;

  /// No description provided for @accDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get accDisplayName;

  /// No description provided for @accUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get accUsername;

  /// No description provided for @accBio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get accBio;

  /// No description provided for @accSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get accSave;

  /// No description provided for @accChangeAvatar.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get accChangeAvatar;

  /// No description provided for @accRemoveAvatar.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get accRemoveAvatar;

  /// No description provided for @accNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a display name.'**
  String get accNameRequired;

  /// No description provided for @accUsernameInvalid.
  ///
  /// In en, this message translates to:
  /// **'3–30 characters: lowercase letters, numbers, dots or underscores.'**
  String get accUsernameInvalid;

  /// No description provided for @accUsernameTaken.
  ///
  /// In en, this message translates to:
  /// **'This username is already taken.'**
  String get accUsernameTaken;

  /// No description provided for @accSaveError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your profile. Please try again.'**
  String get accSaveError;

  /// No description provided for @accAvatarUploadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t upload the photo. Please try again.'**
  String get accAvatarUploadError;

  /// No description provided for @accUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found.'**
  String get accUserNotFound;

  /// No description provided for @accFollowListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No one here yet'**
  String get accFollowListEmpty;

  /// No description provided for @accComingSoon.
  ///
  /// In en, this message translates to:
  /// **'This feature is under development'**
  String get accComingSoon;

  /// No description provided for @accActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get accActivity;

  /// No description provided for @accProPlan.
  ///
  /// In en, this message translates to:
  /// **'Account plan'**
  String get accProPlan;

  /// No description provided for @accCreateStore.
  ///
  /// In en, this message translates to:
  /// **'Create a store'**
  String get accCreateStore;

  /// No description provided for @accCoins.
  ///
  /// In en, this message translates to:
  /// **'ReStore Points'**
  String get accCoins;

  /// No description provided for @accSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get accSaved;

  /// No description provided for @accSavedSearches.
  ///
  /// In en, this message translates to:
  /// **'Saved searches'**
  String get accSavedSearches;

  /// No description provided for @accRecentlyViewed.
  ///
  /// In en, this message translates to:
  /// **'Recently viewed'**
  String get accRecentlyViewed;

  /// No description provided for @accMyReviews.
  ///
  /// In en, this message translates to:
  /// **'My reviews'**
  String get accMyReviews;

  /// No description provided for @accTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transaction history'**
  String get accTransactions;

  /// No description provided for @accStores.
  ///
  /// In en, this message translates to:
  /// **'Stores / brand pages'**
  String get accStores;

  /// No description provided for @accHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get accHelp;

  /// No description provided for @accFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get accFeedback;

  /// No description provided for @accEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get accEdit;

  /// No description provided for @accMoreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get accMoreOptions;

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

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since {year}'**
  String memberSince(String year);

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

  /// No description provided for @feedsTitle.
  ///
  /// In en, this message translates to:
  /// **'Feeds'**
  String get feedsTitle;

  /// No description provided for @feedsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Feeds are coming soon'**
  String get feedsComingSoon;

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

  /// No description provided for @streetSuggestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Suggested addresses'**
  String get streetSuggestionsTitle;

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

  /// No description provided for @aiBubbleTooltip.
  ///
  /// In en, this message translates to:
  /// **'Chat with ReStore AI'**
  String get aiBubbleTooltip;

  /// No description provided for @unreadMessagesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} unread messages'**
  String unreadMessagesCount(int count);

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi there 👋'**
  String get homeGreeting;

  /// No description provided for @homeHeadline.
  ///
  /// In en, this message translates to:
  /// **'What are you hunting for today?'**
  String get homeHeadline;

  /// No description provided for @homeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search pre-loved and swap items...'**
  String get homeSearchHint;

  /// No description provided for @homeChangeArea.
  ///
  /// In en, this message translates to:
  /// **'Change area'**
  String get homeChangeArea;

  /// No description provided for @homeAreaLocating.
  ///
  /// In en, this message translates to:
  /// **'Locating...'**
  String get homeAreaLocating;

  /// No description provided for @homeForYouTitle.
  ///
  /// In en, this message translates to:
  /// **'Picked for you'**
  String get homeForYouTitle;

  /// No description provided for @homeLatestTitle.
  ///
  /// In en, this message translates to:
  /// **'Fresh listings'**
  String get homeLatestTitle;

  /// No description provided for @homeSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get homeSeeAll;

  /// No description provided for @homeFeaturedTag.
  ///
  /// In en, this message translates to:
  /// **'Hot'**
  String get homeFeaturedTag;

  /// No description provided for @homeExchangeTag.
  ///
  /// In en, this message translates to:
  /// **'Swappable'**
  String get homeExchangeTag;

  /// No description provided for @homeExchangeOnly.
  ///
  /// In en, this message translates to:
  /// **'Swap only'**
  String get homeExchangeOnly;

  /// No description provided for @homeSaveListing.
  ///
  /// In en, this message translates to:
  /// **'Save listing'**
  String get homeSaveListing;

  /// No description provided for @homeUnsaveListing.
  ///
  /// In en, this message translates to:
  /// **'Remove from saved'**
  String get homeUnsaveListing;

  /// No description provided for @homeLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the home page'**
  String get homeLoadErrorTitle;

  /// No description provided for @homeLoadErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get homeLoadErrorBody;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String timeMinutesAgo(int count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} h ago'**
  String timeHoursAgo(int count);

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} d ago'**
  String timeDaysAgo(int count);

  /// No description provided for @featureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'This feature is coming soon'**
  String get featureComingSoon;

  /// No description provided for @homeGreetingName.
  ///
  /// In en, this message translates to:
  /// **'Hi there, {name} 👋'**
  String homeGreetingName(String name);

  /// No description provided for @homeLatestEmpty.
  ///
  /// In en, this message translates to:
  /// **'No listings here yet'**
  String get homeLatestEmpty;

  /// No description provided for @homeEndOfList.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up'**
  String get homeEndOfList;

  /// No description provided for @homeQuickNearby.
  ///
  /// In en, this message translates to:
  /// **'Near me'**
  String get homeQuickNearby;

  /// No description provided for @homeQuickNearbyDesc.
  ///
  /// In en, this message translates to:
  /// **'Within 5 km'**
  String get homeQuickNearbyDesc;

  /// No description provided for @homeQuickWanted.
  ///
  /// In en, this message translates to:
  /// **'Wanted alerts'**
  String get homeQuickWanted;

  /// No description provided for @homeQuickWantedDesc.
  ///
  /// In en, this message translates to:
  /// **'Get notified when listed'**
  String get homeQuickWantedDesc;

  /// No description provided for @homeQuickTrustedShops.
  ///
  /// In en, this message translates to:
  /// **'Trusted shops'**
  String get homeQuickTrustedShops;

  /// No description provided for @homeQuickTrustedShopsDesc.
  ///
  /// In en, this message translates to:
  /// **'Verified and top rated'**
  String get homeQuickTrustedShopsDesc;

  /// No description provided for @homeQuickFollowing.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get homeQuickFollowing;

  /// No description provided for @homeQuickFollowingDesc.
  ///
  /// In en, this message translates to:
  /// **'Shops and people you follow'**
  String get homeQuickFollowingDesc;

  /// No description provided for @homeBannerTooltip.
  ///
  /// In en, this message translates to:
  /// **'Promotion banner'**
  String get homeBannerTooltip;

  /// No description provided for @productDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Product details'**
  String get productDetailTitle;

  /// No description provided for @productLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this listing'**
  String get productLoadErrorTitle;

  /// No description provided for @productLoadErrorBody.
  ///
  /// In en, this message translates to:
  /// **'The listing may have been removed, or your connection is unstable. Please try again.'**
  String get productLoadErrorBody;

  /// No description provided for @productViewCount.
  ///
  /// In en, this message translates to:
  /// **'{count} views'**
  String productViewCount(int count);

  /// No description provided for @productUnavailableHint.
  ///
  /// In en, this message translates to:
  /// **'This item can no longer be bought.'**
  String get productUnavailableHint;

  /// No description provided for @listingStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get listingStatusDraft;

  /// No description provided for @listingStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending review'**
  String get listingStatusPending;

  /// No description provided for @listingStatusAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get listingStatusAvailable;

  /// No description provided for @listingStatusReserved.
  ///
  /// In en, this message translates to:
  /// **'Reserved'**
  String get listingStatusReserved;

  /// No description provided for @listingStatusSold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get listingStatusSold;

  /// No description provided for @listingStatusExchanged.
  ///
  /// In en, this message translates to:
  /// **'Exchanged'**
  String get listingStatusExchanged;

  /// No description provided for @listingStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get listingStatusExpired;

  /// No description provided for @listingStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get listingStatusRejected;

  /// No description provided for @listingStatusHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get listingStatusHidden;

  /// No description provided for @productSellerTitle.
  ///
  /// In en, this message translates to:
  /// **'Seller'**
  String get productSellerTitle;

  /// No description provided for @productSellerVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get productSellerVerified;

  /// No description provided for @productSellerNoReviews.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get productSellerNoReviews;

  /// No description provided for @productSellerJoined.
  ///
  /// In en, this message translates to:
  /// **'Joined {date}'**
  String productSellerJoined(String date);

  /// No description provided for @productSellerListings.
  ///
  /// In en, this message translates to:
  /// **'{count} listings'**
  String productSellerListings(int count);

  /// No description provided for @productSellerProfile.
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get productSellerProfile;

  /// No description provided for @productReadMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get productReadMore;

  /// No description provided for @productReadLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get productReadLess;

  /// No description provided for @productSafetyTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop safely'**
  String get productSafetyTitle;

  /// No description provided for @productSafetyBody.
  ///
  /// In en, this message translates to:
  /// **'Meet in a public place, check the item before paying and never send a deposit to someone you don\'t know.'**
  String get productSafetyBody;

  /// No description provided for @productReport.
  ///
  /// In en, this message translates to:
  /// **'Report listing'**
  String get productReport;

  /// No description provided for @productChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get productChat;

  /// No description provided for @productMakeOffer.
  ///
  /// In en, this message translates to:
  /// **'Make offer'**
  String get productMakeOffer;

  /// No description provided for @productBuyNow.
  ///
  /// In en, this message translates to:
  /// **'Buy now'**
  String get productBuyNow;

  /// No description provided for @productProposeExchange.
  ///
  /// In en, this message translates to:
  /// **'Propose a swap'**
  String get productProposeExchange;

  /// No description provided for @productEditListing.
  ///
  /// In en, this message translates to:
  /// **'Edit listing'**
  String get productEditListing;

  /// No description provided for @productBoost.
  ///
  /// In en, this message translates to:
  /// **'Boost'**
  String get productBoost;

  /// No description provided for @productOfferTitle.
  ///
  /// In en, this message translates to:
  /// **'Make an offer'**
  String get productOfferTitle;

  /// No description provided for @productOfferSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Listed at {price}'**
  String productOfferSubtitle(String price);

  /// No description provided for @productOfferAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Your offer'**
  String get productOfferAmountLabel;

  /// No description provided for @productOfferAmountHint.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount'**
  String get productOfferAmountHint;

  /// No description provided for @productOfferInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount greater than 0'**
  String get productOfferInvalid;

  /// No description provided for @productOfferTooHigh.
  ///
  /// In en, this message translates to:
  /// **'Your offer can be at most twice the asking price'**
  String get productOfferTooHigh;

  /// No description provided for @productOfferSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send offer'**
  String get productOfferSubmit;

  /// No description provided for @productOfferSent.
  ///
  /// In en, this message translates to:
  /// **'Offer sent. Continue the conversation with the seller here.'**
  String get productOfferSent;

  /// No description provided for @productOfferBelow.
  ///
  /// In en, this message translates to:
  /// **'{percent} below the asking price (-{difference})'**
  String productOfferBelow(String percent, String difference);

  /// No description provided for @productOfferAbove.
  ///
  /// In en, this message translates to:
  /// **'{percent} above the asking price (+{difference})'**
  String productOfferAbove(String percent, String difference);

  /// No description provided for @productOfferEqual.
  ///
  /// In en, this message translates to:
  /// **'Same as the asking price'**
  String get productOfferEqual;

  /// No description provided for @productLiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Listing just updated'**
  String get productLiveTitle;

  /// No description provided for @productLiveUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This item is now {status} and can no longer be ordered.'**
  String productLiveUnavailable(String status);

  /// No description provided for @productLiveAvailable.
  ///
  /// In en, this message translates to:
  /// **'This item is available again.'**
  String get productLiveAvailable;

  /// No description provided for @productLivePrice.
  ///
  /// In en, this message translates to:
  /// **'The seller changed the price from {previous} to {current}.'**
  String productLivePrice(String previous, String current);

  /// No description provided for @productLivePriceGeneric.
  ///
  /// In en, this message translates to:
  /// **'The seller updated the price, please review before sending.'**
  String get productLivePriceGeneric;

  /// No description provided for @productLiveInfo.
  ///
  /// In en, this message translates to:
  /// **'The seller just edited this listing.'**
  String get productLiveInfo;

  /// No description provided for @productLiveIndicator.
  ///
  /// In en, this message translates to:
  /// **'Live updates on'**
  String get productLiveIndicator;

  /// No description provided for @productBuyTitle.
  ///
  /// In en, this message translates to:
  /// **'Request to buy'**
  String get productBuyTitle;

  /// No description provided for @productBuySubtitle.
  ///
  /// In en, this message translates to:
  /// **'The seller confirms and arranges the handover with you in chat.'**
  String get productBuySubtitle;

  /// No description provided for @productBuyPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get productBuyPriceLabel;

  /// No description provided for @productBuyNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note for the seller'**
  String get productBuyNoteLabel;

  /// No description provided for @productBuyNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. I can pick it up this evening'**
  String get productBuyNoteHint;

  /// No description provided for @productBuySubmit.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get productBuySubmit;

  /// No description provided for @productBuySent.
  ///
  /// In en, this message translates to:
  /// **'Purchase request sent. The seller will reply in chat.'**
  String get productBuySent;

  /// No description provided for @productActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send. Please try again.'**
  String get productActionFailed;

  /// No description provided for @galleryOpenFullscreen.
  ///
  /// In en, this message translates to:
  /// **'View photos full screen'**
  String get galleryOpenFullscreen;

  /// No description provided for @nearbyTitle.
  ///
  /// In en, this message translates to:
  /// **'Near me'**
  String get nearbyTitle;

  /// No description provided for @nearbySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pre-loved finds around you, meet up and grab them'**
  String get nearbySubtitle;

  /// No description provided for @nearbyCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current location'**
  String get nearbyCurrentLocation;

  /// No description provided for @nearbyLocating.
  ///
  /// In en, this message translates to:
  /// **'Finding your location...'**
  String get nearbyLocating;

  /// No description provided for @nearbyChangeLocation.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get nearbyChangeLocation;

  /// No description provided for @nearbyRelocate.
  ///
  /// In en, this message translates to:
  /// **'Update location'**
  String get nearbyRelocate;

  /// No description provided for @nearbyFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get nearbyFilters;

  /// No description provided for @nearbyRadiusChip.
  ///
  /// In en, this message translates to:
  /// **'Within {distance}'**
  String nearbyRadiusChip(String distance);

  /// No description provided for @nearbyRadiusTitle.
  ///
  /// In en, this message translates to:
  /// **'Search radius'**
  String get nearbyRadiusTitle;

  /// No description provided for @nearbyRadiusOption.
  ///
  /// In en, this message translates to:
  /// **'Within {distance}'**
  String nearbyRadiusOption(String distance);

  /// No description provided for @listingDealBuy.
  ///
  /// In en, this message translates to:
  /// **'Buy now'**
  String get listingDealBuy;

  /// No description provided for @listingDealExchange.
  ///
  /// In en, this message translates to:
  /// **'Swap'**
  String get listingDealExchange;

  /// No description provided for @listingSortTitle.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get listingSortTitle;

  /// No description provided for @listingSortNearest.
  ///
  /// In en, this message translates to:
  /// **'Nearest'**
  String get listingSortNearest;

  /// No description provided for @listingSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get listingSortNewest;

  /// No description provided for @listingSortPriceLow.
  ///
  /// In en, this message translates to:
  /// **'Price: low to high'**
  String get listingSortPriceLow;

  /// No description provided for @listingSortPriceHigh.
  ///
  /// In en, this message translates to:
  /// **'Price: high to low'**
  String get listingSortPriceHigh;

  /// No description provided for @nearbyFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Showing listings around your default area'**
  String get nearbyFallbackTitle;

  /// No description provided for @nearbyUseMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get nearbyUseMyLocation;

  /// No description provided for @nearbyOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get nearbyOpenSettings;

  /// No description provided for @nearbyEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing nearby yet'**
  String get nearbyEmptyTitle;

  /// No description provided for @nearbyEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Try a wider radius or fewer filters.'**
  String get nearbyEmptyBody;

  /// No description provided for @nearbyExpandRadius.
  ///
  /// In en, this message translates to:
  /// **'Expand to {distance}'**
  String nearbyExpandRadius(String distance);

  /// No description provided for @nearbyLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load nearby listings'**
  String get nearbyLoadErrorTitle;

  /// No description provided for @nearbyLoadErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get nearbyLoadErrorBody;

  /// No description provided for @nearbyEndOfList.
  ///
  /// In en, this message translates to:
  /// **'You\'ve seen everything nearby'**
  String get nearbyEndOfList;

  /// No description provided for @distanceMeters.
  ///
  /// In en, this message translates to:
  /// **'{meters} m'**
  String distanceMeters(int meters);

  /// No description provided for @distanceKm.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String distanceKm(String km);

  /// No description provided for @listingSortRelevance.
  ///
  /// In en, this message translates to:
  /// **'Most relevant'**
  String get listingSortRelevance;

  /// No description provided for @searchNearMe.
  ///
  /// In en, this message translates to:
  /// **'Near me'**
  String get searchNearMe;

  /// No description provided for @searchNearMeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse pre-loved items around you'**
  String get searchNearMeSubtitle;

  /// No description provided for @searchTipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick search ideas'**
  String get searchTipsTitle;

  /// No description provided for @searchHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get searchHistoryTitle;

  /// No description provided for @searchClearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get searchClearHistory;

  /// No description provided for @searchRemoveHistory.
  ///
  /// In en, this message translates to:
  /// **'Remove from list'**
  String get searchRemoveHistory;

  /// No description provided for @searchFillQuery.
  ///
  /// In en, this message translates to:
  /// **'Use in search box'**
  String get searchFillQuery;

  /// No description provided for @searchClearInput.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get searchClearInput;

  /// No description provided for @searchForQuery.
  ///
  /// In en, this message translates to:
  /// **'Search “{query}”'**
  String searchForQuery(String query);

  /// No description provided for @searchEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No results for “{query}”'**
  String searchEmptyTitle(String query);

  /// No description provided for @searchEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Try a shorter or different keyword, or remove some filters.'**
  String get searchEmptyBody;

  /// No description provided for @searchTryAnother.
  ///
  /// In en, this message translates to:
  /// **'Change keyword'**
  String get searchTryAnother;

  /// No description provided for @searchLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load results'**
  String get searchLoadErrorTitle;

  /// No description provided for @searchLoadErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get searchLoadErrorBody;

  /// No description provided for @searchEndOfList.
  ///
  /// In en, this message translates to:
  /// **'You\'ve seen all results'**
  String get searchEndOfList;

  /// No description provided for @areaSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search ward or province...'**
  String get areaSearchHint;

  /// No description provided for @areaMyLocationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use your current GPS location'**
  String get areaMyLocationSubtitle;

  /// No description provided for @areaRecentTitle.
  ///
  /// In en, this message translates to:
  /// **'Recently chosen areas'**
  String get areaRecentTitle;

  /// No description provided for @areaWholeProvince.
  ///
  /// In en, this message translates to:
  /// **'Whole province / city'**
  String get areaWholeProvince;

  /// No description provided for @areaNoResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching area'**
  String get areaNoResultsTitle;

  /// No description provided for @areaNoResultsBody.
  ///
  /// In en, this message translates to:
  /// **'Try another ward or province name.'**
  String get areaNoResultsBody;

  /// No description provided for @areaSearchErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t search areas'**
  String get areaSearchErrorTitle;

  /// No description provided for @listingFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get listingFilterTitle;

  /// No description provided for @listingFilterCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get listingFilterCategory;

  /// No description provided for @listingFilterAllCategories.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get listingFilterAllCategories;

  /// No description provided for @listingFilterCategoryError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load categories'**
  String get listingFilterCategoryError;

  /// No description provided for @listingFilterPrice.
  ///
  /// In en, this message translates to:
  /// **'Price range'**
  String get listingFilterPrice;

  /// No description provided for @listingFilterPriceMin.
  ///
  /// In en, this message translates to:
  /// **'Min price'**
  String get listingFilterPriceMin;

  /// No description provided for @listingFilterPriceMax.
  ///
  /// In en, this message translates to:
  /// **'Max price'**
  String get listingFilterPriceMax;

  /// No description provided for @listingFilterPriceAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get listingFilterPriceAny;

  /// No description provided for @listingFilterPriceHelper.
  ///
  /// In en, this message translates to:
  /// **'Exchange-only listings (no price) are hidden when filtering by price.'**
  String get listingFilterPriceHelper;

  /// No description provided for @listingFilterPriceInvalid.
  ///
  /// In en, this message translates to:
  /// **'Min price is higher than max price.'**
  String get listingFilterPriceInvalid;

  /// No description provided for @listingFilterPriceUnder.
  ///
  /// In en, this message translates to:
  /// **'Under {price}'**
  String listingFilterPriceUnder(String price);

  /// No description provided for @listingFilterPriceOver.
  ///
  /// In en, this message translates to:
  /// **'Over {price}'**
  String listingFilterPriceOver(String price);

  /// No description provided for @listingFilterPriceBetween.
  ///
  /// In en, this message translates to:
  /// **'{min} – {max}'**
  String listingFilterPriceBetween(String min, String max);

  /// No description provided for @listingFilterCondition.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get listingFilterCondition;

  /// No description provided for @listingFilterDeal.
  ///
  /// In en, this message translates to:
  /// **'Deal type'**
  String get listingFilterDeal;

  /// No description provided for @listingFilterDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get listingFilterDistance;

  /// No description provided for @listingFilterReset.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get listingFilterReset;

  /// No description provided for @listingFilterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get listingFilterApply;

  /// No description provided for @listingFilterApplyCount.
  ///
  /// In en, this message translates to:
  /// **'Apply ({count})'**
  String listingFilterApplyCount(int count);

  /// No description provided for @priceThousands.
  ///
  /// In en, this message translates to:
  /// **'{value}K'**
  String priceThousands(String value);

  /// No description provided for @priceMillions.
  ///
  /// In en, this message translates to:
  /// **'{value}M'**
  String priceMillions(String value);

  /// No description provided for @categoryDetailSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get categoryDetailSearch;

  /// No description provided for @categoryDetailEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No listings in this category yet'**
  String get categoryDetailEmptyTitle;

  /// No description provided for @categoryDetailEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Be the first to post something in this category.'**
  String get categoryDetailEmptyBody;

  /// No description provided for @categoryDetailPostListing.
  ///
  /// In en, this message translates to:
  /// **'Post a listing'**
  String get categoryDetailPostListing;

  /// No description provided for @categoryDetailFilteredEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No listings match your filters'**
  String get categoryDetailFilteredEmptyTitle;

  /// No description provided for @categoryDetailFilteredEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Try removing some filters to see more listings.'**
  String get categoryDetailFilteredEmptyBody;

  /// No description provided for @categoryDetailLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this category'**
  String get categoryDetailLoadErrorTitle;

  /// No description provided for @categoryDetailLoadErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get categoryDetailLoadErrorBody;

  /// No description provided for @categoryDetailEndOfList.
  ///
  /// In en, this message translates to:
  /// **'You\'ve seen every listing in this category'**
  String get categoryDetailEndOfList;

  /// No description provided for @wantedAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'Wanted alerts'**
  String get wantedAlertTitle;

  /// No description provided for @wantedAlertSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reserve what you need, get notified when it is posted'**
  String get wantedAlertSubtitle;

  /// No description provided for @wantedAlertActiveCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 active alert} other{{count} active alerts}}'**
  String wantedAlertActiveCount(int count);

  /// No description provided for @wantedAlertCreate.
  ///
  /// In en, this message translates to:
  /// **'Create alert'**
  String get wantedAlertCreate;

  /// No description provided for @wantedAlertNew.
  ///
  /// In en, this message translates to:
  /// **'New alert'**
  String get wantedAlertNew;

  /// No description provided for @wantedAlertEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No alerts yet'**
  String get wantedAlertEmptyTitle;

  /// No description provided for @wantedAlertEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Tell us what you are looking for and ReStore will notify you as soon as something similar is posted.'**
  String get wantedAlertEmptyBody;

  /// No description provided for @wantedAlertLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your alerts'**
  String get wantedAlertLoadErrorTitle;

  /// No description provided for @wantedAlertLoadErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get wantedAlertLoadErrorBody;

  /// No description provided for @wantedAlertNewMatches.
  ///
  /// In en, this message translates to:
  /// **'{count} new'**
  String wantedAlertNewMatches(int count);

  /// No description provided for @wantedAlertMatchCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 match} other{{count} matches}}'**
  String wantedAlertMatchCount(int count);

  /// No description provided for @wantedAlertNoMatchYet.
  ///
  /// In en, this message translates to:
  /// **'No matches yet'**
  String get wantedAlertNoMatchYet;

  /// No description provided for @wantedAlertLastMatched.
  ///
  /// In en, this message translates to:
  /// **'Last match {time}'**
  String wantedAlertLastMatched(String time);

  /// No description provided for @wantedAlertCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Created {time}'**
  String wantedAlertCreatedAt(String time);

  /// No description provided for @wantedAlertWatching.
  ///
  /// In en, this message translates to:
  /// **'Watching'**
  String get wantedAlertWatching;

  /// No description provided for @wantedAlertAnyCategory.
  ///
  /// In en, this message translates to:
  /// **'Any category'**
  String get wantedAlertAnyCategory;

  /// No description provided for @wantedAlertNationwide.
  ///
  /// In en, this message translates to:
  /// **'Nationwide'**
  String get wantedAlertNationwide;

  /// No description provided for @wantedAlertAnyPrice.
  ///
  /// In en, this message translates to:
  /// **'Any price'**
  String get wantedAlertAnyPrice;

  /// No description provided for @wantedAlertAnyCondition.
  ///
  /// In en, this message translates to:
  /// **'Any condition'**
  String get wantedAlertAnyCondition;

  /// No description provided for @wantedAlertAnyDeal.
  ///
  /// In en, this message translates to:
  /// **'Buy or exchange'**
  String get wantedAlertAnyDeal;

  /// No description provided for @wantedAlertPriceFrom.
  ///
  /// In en, this message translates to:
  /// **'From {price}'**
  String wantedAlertPriceFrom(String price);

  /// No description provided for @wantedAlertPriceUpTo.
  ///
  /// In en, this message translates to:
  /// **'Up to {price}'**
  String wantedAlertPriceUpTo(String price);

  /// No description provided for @wantedAlertPriceRange.
  ///
  /// In en, this message translates to:
  /// **'{min} – {max}'**
  String wantedAlertPriceRange(String min, String max);

  /// No description provided for @wantedAlertDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete alert'**
  String get wantedAlertDelete;

  /// No description provided for @wantedAlertDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this alert?'**
  String get wantedAlertDeleteTitle;

  /// No description provided for @wantedAlertDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'ReStore will stop notifying you about “{keywords}”. You can create it again anytime.'**
  String wantedAlertDeleteBody(String keywords);

  /// No description provided for @wantedAlertKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get wantedAlertKeep;

  /// No description provided for @wantedAlertDeleted.
  ///
  /// In en, this message translates to:
  /// **'Alert deleted. You won\'t get new matches for it anymore.'**
  String get wantedAlertDeleted;

  /// No description provided for @wantedAlertDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete the alert. Please try again.'**
  String get wantedAlertDeleteError;

  /// No description provided for @wantedAlertSearchHint.
  ///
  /// In en, this message translates to:
  /// **'What are you looking for?'**
  String get wantedAlertSearchHint;

  /// No description provided for @wantedAlertIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Search first, get alerted later'**
  String get wantedAlertIntroTitle;

  /// No description provided for @wantedAlertIntroStep1.
  ///
  /// In en, this message translates to:
  /// **'Type what you need and ReStore shows similar listings right away.'**
  String get wantedAlertIntroStep1;

  /// No description provided for @wantedAlertIntroStep2.
  ///
  /// In en, this message translates to:
  /// **'Found a good one? Open it now, no need to wait.'**
  String get wantedAlertIntroStep2;

  /// No description provided for @wantedAlertIntroStep3.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet? Create an alert and get a link as soon as a similar listing appears.'**
  String get wantedAlertIntroStep3;

  /// No description provided for @wantedAlertSkipToCompose.
  ///
  /// In en, this message translates to:
  /// **'Skip, write the alert'**
  String get wantedAlertSkipToCompose;

  /// No description provided for @wantedAlertSuggestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 similar listing available} other{{count} similar listings available}}'**
  String wantedAlertSuggestionsTitle(int count);

  /// No description provided for @wantedAlertSuggestionsHint.
  ///
  /// In en, this message translates to:
  /// **'None of these? Create an alert to hear about new ones.'**
  String get wantedAlertSuggestionsHint;

  /// No description provided for @wantedAlertSuggestionsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing similar yet'**
  String get wantedAlertSuggestionsEmptyTitle;

  /// No description provided for @wantedAlertSuggestionsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Create an alert and ReStore will tell you as soon as someone posts it.'**
  String get wantedAlertSuggestionsEmptyBody;

  /// No description provided for @wantedAlertSuggestionsErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load suggestions'**
  String get wantedAlertSuggestionsErrorTitle;

  /// No description provided for @wantedAlertSuggestionsErrorBody.
  ///
  /// In en, this message translates to:
  /// **'You can still create the alert now.'**
  String get wantedAlertSuggestionsErrorBody;

  /// No description provided for @wantedAlertMatchPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% match'**
  String wantedAlertMatchPercent(int percent);

  /// No description provided for @wantedAlertNotRightCta.
  ///
  /// In en, this message translates to:
  /// **'Not it? Create an alert'**
  String get wantedAlertNotRightCta;

  /// No description provided for @wantedAlertComposeTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your alert'**
  String get wantedAlertComposeTitle;

  /// No description provided for @wantedAlertComposeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When a similar listing is posted, ReStore sends you a link to it.'**
  String get wantedAlertComposeSubtitle;

  /// No description provided for @wantedAlertKeywordsLabel.
  ///
  /// In en, this message translates to:
  /// **'What you want'**
  String get wantedAlertKeywordsLabel;

  /// No description provided for @wantedAlertKeywordsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Canon AE-1 film camera'**
  String get wantedAlertKeywordsHint;

  /// No description provided for @wantedAlertKeywordsHelper.
  ///
  /// In en, this message translates to:
  /// **'Name, brand or model. It doesn\'t have to be exact, similar listings count too.'**
  String get wantedAlertKeywordsHelper;

  /// No description provided for @wantedAlertKeywordsError.
  ///
  /// In en, this message translates to:
  /// **'Enter at least {min} characters'**
  String wantedAlertKeywordsError(int min);

  /// No description provided for @wantedAlertCriteriaTitle.
  ///
  /// In en, this message translates to:
  /// **'Criteria (optional)'**
  String get wantedAlertCriteriaTitle;

  /// No description provided for @wantedAlertCriteriaCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get wantedAlertCriteriaCategory;

  /// No description provided for @wantedAlertCriteriaPrice.
  ///
  /// In en, this message translates to:
  /// **'Price range'**
  String get wantedAlertCriteriaPrice;

  /// No description provided for @wantedAlertCriteriaCondition.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get wantedAlertCriteriaCondition;

  /// No description provided for @wantedAlertCriteriaDeal.
  ///
  /// In en, this message translates to:
  /// **'Deal type'**
  String get wantedAlertCriteriaDeal;

  /// No description provided for @wantedAlertCriteriaArea.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get wantedAlertCriteriaArea;

  /// No description provided for @wantedAlertEditCriteria.
  ///
  /// In en, this message translates to:
  /// **'Edit criteria'**
  String get wantedAlertEditCriteria;

  /// No description provided for @wantedAlertLevelTitle.
  ///
  /// In en, this message translates to:
  /// **'How close'**
  String get wantedAlertLevelTitle;

  /// No description provided for @wantedAlertLevelBroad.
  ///
  /// In en, this message translates to:
  /// **'Broad'**
  String get wantedAlertLevelBroad;

  /// No description provided for @wantedAlertLevelBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get wantedAlertLevelBalanced;

  /// No description provided for @wantedAlertLevelStrict.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get wantedAlertLevelStrict;

  /// No description provided for @wantedAlertLevelBroadDesc.
  ///
  /// In en, this message translates to:
  /// **'Includes loosely similar listings, so you get more alerts.'**
  String get wantedAlertLevelBroadDesc;

  /// No description provided for @wantedAlertLevelBalancedDesc.
  ///
  /// In en, this message translates to:
  /// **'Most keywords must match, small typos are fine.'**
  String get wantedAlertLevelBalancedDesc;

  /// No description provided for @wantedAlertLevelStrictDesc.
  ///
  /// In en, this message translates to:
  /// **'Only listings that are almost exactly what you typed.'**
  String get wantedAlertLevelStrictDesc;

  /// No description provided for @wantedAlertPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Listings matching right now'**
  String get wantedAlertPreviewTitle;

  /// No description provided for @wantedAlertPreviewEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches right now. You\'ll be notified when something is posted.'**
  String get wantedAlertPreviewEmpty;

  /// No description provided for @wantedAlertPreviewNeedKeywords.
  ///
  /// In en, this message translates to:
  /// **'Enter what you want to preview matching listings.'**
  String get wantedAlertPreviewNeedKeywords;

  /// No description provided for @wantedAlertSave.
  ///
  /// In en, this message translates to:
  /// **'Turn on alert'**
  String get wantedAlertSave;

  /// No description provided for @wantedAlertCreated.
  ///
  /// In en, this message translates to:
  /// **'Alert on for “{keywords}”. ReStore will notify you when something similar is posted.'**
  String wantedAlertCreated(String keywords);

  /// No description provided for @wantedAlertCreateError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the alert. Please try again.'**
  String get wantedAlertCreateError;

  /// No description provided for @wantedAlertNewTag.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get wantedAlertNewTag;

  /// No description provided for @wantedAlertMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'Matched listings'**
  String get wantedAlertMatchesTitle;

  /// No description provided for @wantedAlertMatchesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No matches yet'**
  String get wantedAlertMatchesEmptyTitle;

  /// No description provided for @wantedAlertMatchesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'When someone posts something similar, ReStore notifies you and it shows up here.'**
  String get wantedAlertMatchesEmptyBody;

  /// No description provided for @wantedAlertEndOfList.
  ///
  /// In en, this message translates to:
  /// **'You\'ve seen every match'**
  String get wantedAlertEndOfList;

  /// No description provided for @wantedAlertPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Not finding it?'**
  String get wantedAlertPromptTitle;

  /// No description provided for @wantedAlertPromptBody.
  ///
  /// In en, this message translates to:
  /// **'Set an alert for “{query}” and ReStore will tell you when something similar is posted.'**
  String wantedAlertPromptBody(String query);

  /// No description provided for @areaNationwide.
  ///
  /// In en, this message translates to:
  /// **'Nationwide'**
  String get areaNationwide;

  /// No description provided for @areaNationwideSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Any area, listings from anywhere'**
  String get areaNationwideSubtitle;

  /// No description provided for @trustedShopsTitle.
  ///
  /// In en, this message translates to:
  /// **'Trusted shops'**
  String get trustedShopsTitle;

  /// No description provided for @trustedShopsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Genuine stores verified by ReStore'**
  String get trustedShopsSubtitle;

  /// No description provided for @trustedShopsAllCategories.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get trustedShopsAllCategories;

  /// No description provided for @trustedShopsOfficialTitle.
  ///
  /// In en, this message translates to:
  /// **'Official brands'**
  String get trustedShopsOfficialTitle;

  /// No description provided for @trustedShopsCertifiedTitle.
  ///
  /// In en, this message translates to:
  /// **'ReStore certified'**
  String get trustedShopsCertifiedTitle;

  /// No description provided for @trustedShopsShowcaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop by brand'**
  String get trustedShopsShowcaseTitle;

  /// No description provided for @trustedShopsShowcaseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Picks from the most followed shops'**
  String get trustedShopsShowcaseSubtitle;

  /// No description provided for @trustedShopsViewShop.
  ///
  /// In en, this message translates to:
  /// **'View shop'**
  String get trustedShopsViewShop;

  /// No description provided for @trustedShopsAllProductsTitle.
  ///
  /// In en, this message translates to:
  /// **'All products'**
  String get trustedShopsAllProductsTitle;

  /// No description provided for @trustedShopsAllProductsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'From every verified shop'**
  String get trustedShopsAllProductsSubtitle;

  /// No description provided for @trustedShopsEndOfList.
  ///
  /// In en, this message translates to:
  /// **'You\'ve seen every product from trusted shops'**
  String get trustedShopsEndOfList;

  /// No description provided for @trustedShopsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No trusted shops here yet'**
  String get trustedShopsEmptyTitle;

  /// No description provided for @trustedShopsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Verified shops in this category will show up here.'**
  String get trustedShopsEmptyBody;

  /// No description provided for @trustedShopsLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load trusted shops'**
  String get trustedShopsLoadErrorTitle;

  /// No description provided for @trustedShopsLoadErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get trustedShopsLoadErrorBody;

  /// No description provided for @trustedShopsFamousTitle.
  ///
  /// In en, this message translates to:
  /// **'Famous brands'**
  String get trustedShopsFamousTitle;

  /// No description provided for @trustedShopsFamousSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Official stores of big-name brands'**
  String get trustedShopsFamousSubtitle;

  /// No description provided for @trustedShopsDealsTitle.
  ///
  /// In en, this message translates to:
  /// **'Luxury for less'**
  String get trustedShopsDealsTitle;

  /// No description provided for @trustedShopsDealsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Genuine brand products, now on sale'**
  String get trustedShopsDealsSubtitle;

  /// No description provided for @trustedShopsDealsUpTo.
  ///
  /// In en, this message translates to:
  /// **'Up to -{percent}%'**
  String trustedShopsDealsUpTo(int percent);

  /// No description provided for @trustedShopsNewReleasesTitle.
  ///
  /// In en, this message translates to:
  /// **'Hot new releases'**
  String get trustedShopsNewReleasesTitle;

  /// No description provided for @trustedShopsNewReleasesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fresh launches from famous brands'**
  String get trustedShopsNewReleasesSubtitle;

  /// No description provided for @trustedShopsNewReleaseTag.
  ///
  /// In en, this message translates to:
  /// **'Just launched'**
  String get trustedShopsNewReleaseTag;

  /// No description provided for @trustedShopsLaunchedDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Launched today} =1{Launched yesterday} other{Launched {count} days ago}}'**
  String trustedShopsLaunchedDaysAgo(int count);

  /// No description provided for @trustedShopsNewShopsTitle.
  ///
  /// In en, this message translates to:
  /// **'New stores'**
  String get trustedShopsNewShopsTitle;

  /// No description provided for @trustedShopsNewShopsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Shops ReStore verified recently'**
  String get trustedShopsNewShopsSubtitle;

  /// No description provided for @trustedShopsNavFamous.
  ///
  /// In en, this message translates to:
  /// **'Brands'**
  String get trustedShopsNavFamous;

  /// No description provided for @trustedShopsNavDeals.
  ///
  /// In en, this message translates to:
  /// **'Deals'**
  String get trustedShopsNavDeals;

  /// No description provided for @trustedShopsNavNewReleases.
  ///
  /// In en, this message translates to:
  /// **'New releases'**
  String get trustedShopsNavNewReleases;

  /// No description provided for @trustedShopsNavNewShops.
  ///
  /// In en, this message translates to:
  /// **'New stores'**
  String get trustedShopsNavNewShops;

  /// No description provided for @trustedShopsNavShowcases.
  ///
  /// In en, this message translates to:
  /// **'By brand'**
  String get trustedShopsNavShowcases;

  /// No description provided for @trustedShopsNavAll.
  ///
  /// In en, this message translates to:
  /// **'All products'**
  String get trustedShopsNavAll;

  /// No description provided for @trustedShopsSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get trustedShopsSeeAll;

  /// No description provided for @trustedShopsOnSaleFilter.
  ///
  /// In en, this message translates to:
  /// **'On sale'**
  String get trustedShopsOnSaleFilter;

  /// No description provided for @shopDetailEventsTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop events'**
  String get shopDetailEventsTitle;

  /// No description provided for @shopDetailEventsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Promotions approved by ReStore'**
  String get shopDetailEventsSubtitle;

  /// No description provided for @shopVerificationOfficial.
  ///
  /// In en, this message translates to:
  /// **'Official'**
  String get shopVerificationOfficial;

  /// No description provided for @shopVerificationCertified.
  ///
  /// In en, this message translates to:
  /// **'Certified'**
  String get shopVerificationCertified;

  /// No description provided for @shopVerificationOfficialDesc.
  ///
  /// In en, this message translates to:
  /// **'The brand\'s own store or its authorised distributor, selling genuine goods with brand warranty.'**
  String get shopVerificationOfficialDesc;

  /// No description provided for @shopVerificationCertifiedDesc.
  ///
  /// In en, this message translates to:
  /// **'ReStore checked this shop\'s business licence, address and trading history before certifying it.'**
  String get shopVerificationCertifiedDesc;

  /// No description provided for @shopVerificationSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'About verified shops'**
  String get shopVerificationSheetTitle;

  /// No description provided for @shopVerificationSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only shops that pass one of these checks appear in Trusted shops'**
  String get shopVerificationSheetSubtitle;

  /// No description provided for @shopVerificationSheetNote.
  ///
  /// In en, this message translates to:
  /// **'ReStore reviews verified shops regularly and removes the badge if a shop breaks the rules or gets repeated complaints.'**
  String get shopVerificationSheetNote;

  /// No description provided for @shopCertificateTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop certificate'**
  String get shopCertificateTitle;

  /// No description provided for @shopCertificateCode.
  ///
  /// In en, this message translates to:
  /// **'Certificate no.'**
  String get shopCertificateCode;

  /// No description provided for @shopVerifiedSince.
  ///
  /// In en, this message translates to:
  /// **'Verified on'**
  String get shopVerifiedSince;

  /// No description provided for @shopVerifiedSinceShort.
  ///
  /// In en, this message translates to:
  /// **'Verified {date}'**
  String shopVerifiedSinceShort(String date);

  /// No description provided for @shopFollow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get shopFollow;

  /// No description provided for @shopFollowing.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get shopFollowing;

  /// No description provided for @shopFollowerCount.
  ///
  /// In en, this message translates to:
  /// **'{count} followers'**
  String shopFollowerCount(String count);

  /// No description provided for @shopListingCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 product} other{{count} products}}'**
  String shopListingCount(int count);

  /// No description provided for @shopRatingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} reviews'**
  String shopRatingCount(String count);

  /// No description provided for @shopFollowersLabel.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get shopFollowersLabel;

  /// No description provided for @shopProductsLabel.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get shopProductsLabel;

  /// No description provided for @shopDescriptionMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get shopDescriptionMore;

  /// No description provided for @shopDescriptionLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get shopDescriptionLess;

  /// No description provided for @shopDetailProductsTitle.
  ///
  /// In en, this message translates to:
  /// **'Products for sale'**
  String get shopDetailProductsTitle;

  /// No description provided for @shopDetailEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No products yet'**
  String get shopDetailEmptyTitle;

  /// No description provided for @shopDetailEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Follow this shop to hear about new products first.'**
  String get shopDetailEmptyBody;

  /// No description provided for @shopDetailEndOfList.
  ///
  /// In en, this message translates to:
  /// **'You\'ve seen every product from this shop'**
  String get shopDetailEndOfList;

  /// No description provided for @shopDetailLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this shop'**
  String get shopDetailLoadErrorTitle;

  /// No description provided for @shopDetailLoadErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get shopDetailLoadErrorBody;

  /// No description provided for @postingQuotaPersonalTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal account'**
  String get postingQuotaPersonalTitle;

  /// No description provided for @postingQuotaBannerMessage.
  ///
  /// In en, this message translates to:
  /// **'Free listings per category: {min} to {max} active at a time. Each listing stays up for {days} days.'**
  String postingQuotaBannerMessage(int min, int max, int days);

  /// No description provided for @postingRulesAction.
  ///
  /// In en, this message translates to:
  /// **'View rules'**
  String get postingRulesAction;

  /// No description provided for @postingQuotaUsage.
  ///
  /// In en, this message translates to:
  /// **'{used}/{limit} used'**
  String postingQuotaUsage(int used, int limit);

  /// No description provided for @postingQuotaFull.
  ///
  /// In en, this message translates to:
  /// **'Limit of {limit} reached'**
  String postingQuotaFull(int limit);

  /// No description provided for @postingQuotaLastSlot.
  ///
  /// In en, this message translates to:
  /// **'1 slot left'**
  String get postingQuotaLastSlot;

  /// No description provided for @postingQuotaRemainingInCategory.
  ///
  /// In en, this message translates to:
  /// **'{remaining}/{limit} slots left in this category'**
  String postingQuotaRemainingInCategory(int remaining, int limit);

  /// No description provided for @postingLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'Category limit reached'**
  String get postingLimitTitle;

  /// No description provided for @postingLimitMessage.
  ///
  /// In en, this message translates to:
  /// **'Personal accounts can have up to {limit} active listings in {category}. Free up a slot to post a new one.'**
  String postingLimitMessage(int limit, String category);

  /// No description provided for @postingLimitWaysTitle.
  ///
  /// In en, this message translates to:
  /// **'How to free a slot'**
  String get postingLimitWaysTitle;

  /// No description provided for @postingLimitTipSold.
  ///
  /// In en, this message translates to:
  /// **'Mark items you have sold as Sold'**
  String get postingLimitTipSold;

  /// No description provided for @postingLimitTipHide.
  ///
  /// In en, this message translates to:
  /// **'Hide listings you no longer want to sell'**
  String get postingLimitTipHide;

  /// No description provided for @postingLimitTipExpire.
  ///
  /// In en, this message translates to:
  /// **'Listings expire after {days} days and free their slot'**
  String postingLimitTipExpire(int days);

  /// No description provided for @manageMyListings.
  ///
  /// In en, this message translates to:
  /// **'Manage my listings'**
  String get manageMyListings;

  /// No description provided for @chooseAnotherCategory.
  ///
  /// In en, this message translates to:
  /// **'Other category'**
  String get chooseAnotherCategory;

  /// No description provided for @postingRulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Posting rules'**
  String get postingRulesTitle;

  /// No description provided for @postingRulesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'For personal sellers'**
  String get postingRulesSubtitle;

  /// No description provided for @postingRuleLimit.
  ///
  /// In en, this message translates to:
  /// **'{min} to {max} free active listings per category, depending on the category. High-value items such as phones and vehicles get 1.'**
  String postingRuleLimit(int min, int max);

  /// No description provided for @postingRuleCounted.
  ///
  /// In en, this message translates to:
  /// **'Only active and pending listings count. Sold, hidden or expired listings do not.'**
  String get postingRuleCounted;

  /// No description provided for @postingRuleDuration.
  ///
  /// In en, this message translates to:
  /// **'Each listing is shown for {days} days after it is approved.'**
  String postingRuleDuration(int days);

  /// No description provided for @postingRuleFree.
  ///
  /// In en, this message translates to:
  /// **'Posting is free. Every listing is reviewed before it goes live.'**
  String get postingRuleFree;

  /// No description provided for @postingRulePersonalUse.
  ///
  /// In en, this message translates to:
  /// **'Personal accounts are for selling your own used items. If you post many items regularly like a business, ReStore may move you to a business account.'**
  String get postingRulePersonalUse;

  /// No description provided for @postingRuleBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business plan (coming soon): up to {limit} listings per category. Shop plan: your own shop page.'**
  String postingRuleBusiness(int limit);

  /// No description provided for @homeGreetingPro.
  ///
  /// In en, this message translates to:
  /// **'Hi pro seller {name} 👋'**
  String homeGreetingPro(String name);

  /// No description provided for @homeGreetingShop.
  ///
  /// In en, this message translates to:
  /// **'Hi shop owner {name} 👋'**
  String homeGreetingShop(String name);

  /// No description provided for @planPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get planPersonal;

  /// No description provided for @planPro.
  ///
  /// In en, this message translates to:
  /// **'Pro seller'**
  String get planPro;

  /// No description provided for @planShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get planShop;

  /// No description provided for @devPlanTag.
  ///
  /// In en, this message translates to:
  /// **'TEST'**
  String get devPlanTag;

  /// No description provided for @devPlanSwitchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Switch plan to test the UI (in-app only)'**
  String get devPlanSwitchTooltip;

  /// No description provided for @quickMenuOpen.
  ///
  /// In en, this message translates to:
  /// **'Open quick menu'**
  String get quickMenuOpen;

  /// No description provided for @quickMenuClose.
  ///
  /// In en, this message translates to:
  /// **'Close quick menu'**
  String get quickMenuClose;

  /// No description provided for @quickActionPost.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get quickActionPost;

  /// No description provided for @quickActionPoster.
  ///
  /// In en, this message translates to:
  /// **'Shop poster'**
  String get quickActionPoster;

  /// No description provided for @quickActionBoost.
  ///
  /// In en, this message translates to:
  /// **'Boost'**
  String get quickActionBoost;

  /// No description provided for @quickActionStats.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get quickActionStats;

  /// No description provided for @quickActionShopManage.
  ///
  /// In en, this message translates to:
  /// **'Manage shop'**
  String get quickActionShopManage;

  /// No description provided for @trustedShopsFamousEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Official'**
  String get trustedShopsFamousEyebrow;

  /// No description provided for @trustedShopsDealsEyebrow.
  ///
  /// In en, this message translates to:
  /// **'On sale'**
  String get trustedShopsDealsEyebrow;

  /// No description provided for @trustedShopsNewReleasesEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Just launched'**
  String get trustedShopsNewReleasesEyebrow;

  /// No description provided for @trustedShopsNewShopsEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Newly verified'**
  String get trustedShopsNewShopsEyebrow;

  /// No description provided for @trustedShopsShowcaseEyebrow.
  ///
  /// In en, this message translates to:
  /// **'By brand'**
  String get trustedShopsShowcaseEyebrow;

  /// No description provided for @trustedShopsAllProductsEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get trustedShopsAllProductsEyebrow;

  /// No description provided for @feedsComposePrompt.
  ///
  /// In en, this message translates to:
  /// **'What\'s on your mind? Share an item or ask the community'**
  String get feedsComposePrompt;

  /// No description provided for @postAudienceTitle.
  ///
  /// In en, this message translates to:
  /// **'Who can see this post?'**
  String get postAudienceTitle;

  /// No description provided for @postAudienceEveryone.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get postAudienceEveryone;

  /// No description provided for @postAudienceEveryoneDesc.
  ///
  /// In en, this message translates to:
  /// **'Anyone on ReStore can see it'**
  String get postAudienceEveryoneDesc;

  /// No description provided for @postAudienceFollowers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get postAudienceFollowers;

  /// No description provided for @postAudienceFollowersDesc.
  ///
  /// In en, this message translates to:
  /// **'Only people who follow you'**
  String get postAudienceFollowersDesc;

  /// No description provided for @postAudienceOnlyMe.
  ///
  /// In en, this message translates to:
  /// **'Only me'**
  String get postAudienceOnlyMe;

  /// No description provided for @postAudienceOnlyMeDesc.
  ///
  /// In en, this message translates to:
  /// **'Saved privately on your page'**
  String get postAudienceOnlyMeDesc;

  /// No description provided for @postComposerSubmit.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get postComposerSubmit;

  /// No description provided for @postComposerHint.
  ///
  /// In en, this message translates to:
  /// **'Share an item, a buying tip or ask the community...'**
  String get postComposerHint;

  /// No description provided for @postComposerRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get postComposerRemovePhoto;

  /// No description provided for @postComposerCover.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get postComposerCover;

  /// No description provided for @postComposerListingTag.
  ///
  /// In en, this message translates to:
  /// **'Your listing'**
  String get postComposerListingTag;

  /// No description provided for @postComposerRemoveAttachment.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get postComposerRemoveAttachment;

  /// No description provided for @postComposerWithOne.
  ///
  /// In en, this message translates to:
  /// **'With {name}'**
  String postComposerWithOne(String name);

  /// No description provided for @postComposerWithMany.
  ///
  /// In en, this message translates to:
  /// **'With {name} and {count} others'**
  String postComposerWithMany(String name, int count);

  /// No description provided for @postComposerBackground.
  ///
  /// In en, this message translates to:
  /// **'Background colour'**
  String get postComposerBackground;

  /// No description provided for @postComposerBackgroundDisabled.
  ///
  /// In en, this message translates to:
  /// **'Background colours are for short posts without photos'**
  String get postComposerBackgroundDisabled;

  /// No description provided for @postComposerNoBackground.
  ///
  /// In en, this message translates to:
  /// **'No background'**
  String get postComposerNoBackground;

  /// No description provided for @postComposerAttachListing.
  ///
  /// In en, this message translates to:
  /// **'Attach listing'**
  String get postComposerAttachListing;

  /// No description provided for @postComposerAttachListingHint.
  ///
  /// In en, this message translates to:
  /// **'Show one of your listings in this post'**
  String get postComposerAttachListingHint;

  /// No description provided for @postComposerTopic.
  ///
  /// In en, this message translates to:
  /// **'Topic'**
  String get postComposerTopic;

  /// No description provided for @postComposerTopicHint.
  ///
  /// In en, this message translates to:
  /// **'Helps the right people find your post'**
  String get postComposerTopicHint;

  /// No description provided for @postComposerTagFriends.
  ///
  /// In en, this message translates to:
  /// **'Tag people'**
  String get postComposerTagFriends;

  /// No description provided for @postComposerTagFriendsHint.
  ///
  /// In en, this message translates to:
  /// **'People you follow'**
  String get postComposerTagFriendsHint;

  /// No description provided for @postComposerTaggedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} tagged'**
  String postComposerTaggedCount(int count);

  /// No description provided for @postComposerEmoji.
  ///
  /// In en, this message translates to:
  /// **'Emoji'**
  String get postComposerEmoji;

  /// No description provided for @postComposerPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get postComposerPhoto;

  /// No description provided for @postComposerVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get postComposerVideo;

  /// No description provided for @postComposerLink.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get postComposerLink;

  /// No description provided for @postComposerLinkHint.
  ///
  /// In en, this message translates to:
  /// **'Paste a web link to share'**
  String get postComposerLinkHint;

  /// No description provided for @postComposerLinkInvalid.
  ///
  /// In en, this message translates to:
  /// **'This link doesn\'t look right'**
  String get postComposerLinkInvalid;

  /// No description provided for @postComposerLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get postComposerLocation;

  /// No description provided for @postComposerTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get postComposerTakePhoto;

  /// No description provided for @postComposerOpenGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get postComposerOpenGallery;

  /// No description provided for @postComposerDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get postComposerDone;

  /// No description provided for @postComposerLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load post options, trying again'**
  String get postComposerLoadError;

  /// No description provided for @postComposerDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard this post?'**
  String get postComposerDiscardTitle;

  /// No description provided for @postComposerDiscardMessage.
  ///
  /// In en, this message translates to:
  /// **'What you\'ve written won\'t be saved'**
  String get postComposerDiscardMessage;

  /// No description provided for @postComposerKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep writing'**
  String get postComposerKeepEditing;

  /// No description provided for @postComposerDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard post'**
  String get postComposerDiscard;

  /// No description provided for @postComposerPhotoLimit.
  ///
  /// In en, this message translates to:
  /// **'You can add up to {count} photos'**
  String postComposerPhotoLimit(int count);

  /// No description provided for @postComposerPhotoPermission.
  ///
  /// In en, this message translates to:
  /// **'ReStore needs photo access. Please allow it in Settings.'**
  String get postComposerPhotoPermission;

  /// No description provided for @postComposerNoListings.
  ///
  /// In en, this message translates to:
  /// **'You have no active listings to attach yet'**
  String get postComposerNoListings;

  /// No description provided for @postComposerError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t publish your post, please try again'**
  String get postComposerError;

  /// No description provided for @postComposerPosted.
  ///
  /// In en, this message translates to:
  /// **'Your post is live on the feed'**
  String get postComposerPosted;

  /// No description provided for @authSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get authSessionExpired;

  /// No description provided for @draftsTitle.
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get draftsTitle;

  /// No description provided for @draftsBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Continue a draft'**
  String get draftsBannerTitle;

  /// No description provided for @draftsBannerMessage.
  ///
  /// In en, this message translates to:
  /// **'Unpublished listings: {count}'**
  String draftsBannerMessage(String count);

  /// No description provided for @draftsBannerAction.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get draftsBannerAction;

  /// No description provided for @draftUntitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get draftUntitled;

  /// No description provided for @draftNoCategory.
  ///
  /// In en, this message translates to:
  /// **'No category yet'**
  String get draftNoCategory;

  /// No description provided for @draftEditedAt.
  ///
  /// In en, this message translates to:
  /// **'Edited {time}'**
  String draftEditedAt(String time);

  /// No description provided for @draftPhotoCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 photo} other{{count} photos}}'**
  String draftPhotoCount(int count);

  /// No description provided for @draftsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No drafts yet'**
  String get draftsEmptyTitle;

  /// No description provided for @draftsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'While posting, tap Save draft to finish it later.'**
  String get draftsEmptyMessage;

  /// No description provided for @draftsLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load drafts'**
  String get draftsLoadFailedTitle;

  /// No description provided for @draftsLoadFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get draftsLoadFailedMessage;

  /// No description provided for @draftOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open this draft. It may have been published or deleted'**
  String get draftOpenFailed;

  /// No description provided for @draftDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete draft?'**
  String get draftDeleteTitle;

  /// No description provided for @draftDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'The draft and its uploaded photos will be deleted permanently.'**
  String get draftDeleteMessage;

  /// No description provided for @draftDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete draft'**
  String get draftDeleteConfirm;

  /// No description provided for @draftDeleted.
  ///
  /// In en, this message translates to:
  /// **'Draft deleted'**
  String get draftDeleted;

  /// No description provided for @draftDeletedNamed.
  ///
  /// In en, this message translates to:
  /// **'Deleted draft “{title}”'**
  String draftDeletedNamed(String title);

  /// No description provided for @draftDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete the draft, please try again'**
  String get draftDeleteFailed;

  /// No description provided for @leaveDraftTitle.
  ///
  /// In en, this message translates to:
  /// **'Save before leaving?'**
  String get leaveDraftTitle;

  /// No description provided for @leaveDraftMessage.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Save a draft to finish it later.'**
  String get leaveDraftMessage;

  /// No description provided for @leaveDraftSave.
  ///
  /// In en, this message translates to:
  /// **'Save draft and leave'**
  String get leaveDraftSave;

  /// No description provided for @leaveDraftDiscard.
  ///
  /// In en, this message translates to:
  /// **'Leave without saving'**
  String get leaveDraftDiscard;

  /// No description provided for @draftLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'{limit} drafts reached'**
  String draftLimitTitle(int limit);

  /// No description provided for @draftLimitTitleUnknown.
  ///
  /// In en, this message translates to:
  /// **'Draft limit reached'**
  String get draftLimitTitleUnknown;

  /// No description provided for @draftLimitMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account can keep up to {limit} drafts. Publish or delete an old draft to save this one.'**
  String draftLimitMessage(int limit);

  /// No description provided for @draftLimitMessageUnknown.
  ///
  /// In en, this message translates to:
  /// **'Your account has reached its draft limit. Publish or delete an old draft to save this one.'**
  String get draftLimitMessageUnknown;

  /// No description provided for @draftLimitViewDrafts.
  ///
  /// In en, this message translates to:
  /// **'View drafts'**
  String get draftLimitViewDrafts;

  /// No description provided for @draftsQuota.
  ///
  /// In en, this message translates to:
  /// **'{used}/{limit} drafts'**
  String draftsQuota(int used, int limit);

  /// No description provided for @listingImageTooLarge.
  ///
  /// In en, this message translates to:
  /// **'A photo is too large (max 5 MB). Remove it or pick another one.'**
  String get listingImageTooLarge;

  /// No description provided for @listingImageUnsupported.
  ///
  /// In en, this message translates to:
  /// **'A photo has an unsupported format (JPEG, PNG or WebP only). Remove it or pick another one.'**
  String get listingImageUnsupported;

  /// No description provided for @listingImageMissing.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 photo is no longer on this device and was removed} other{{count} photos are no longer on this device and were removed}}. Pick them again, then save.'**
  String listingImageMissing(int count);

  /// No description provided for @listingSaveNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach the server. What was saved is kept, please try again.'**
  String get listingSaveNetworkError;

  /// No description provided for @feedReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get feedReply;

  /// No description provided for @feedHideReplies.
  ///
  /// In en, this message translates to:
  /// **'Hide replies'**
  String get feedHideReplies;

  /// No description provided for @feedViewReplies.
  ///
  /// In en, this message translates to:
  /// **'View {count} replies'**
  String feedViewReplies(int count);

  /// No description provided for @feedReplyTo.
  ///
  /// In en, this message translates to:
  /// **'Replying to {name}'**
  String feedReplyTo(String name);

  /// No description provided for @feedCancelReply.
  ///
  /// In en, this message translates to:
  /// **'Cancel reply'**
  String get feedCancelReply;

  /// No description provided for @feedMoreComments.
  ///
  /// In en, this message translates to:
  /// **'Load more comments'**
  String get feedMoreComments;

  /// No description provided for @creditTitle.
  ///
  /// In en, this message translates to:
  /// **'ReStore Points'**
  String get creditTitle;

  /// No description provided for @creditAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available points'**
  String get creditAvailable;

  /// No description provided for @creditPoints.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{amount} point} other{{amount} points}}'**
  String creditPoints(int count, String amount);

  /// No description provided for @creditUnit.
  ///
  /// In en, this message translates to:
  /// **'points'**
  String get creditUnit;

  /// No description provided for @creditPaidLabel.
  ///
  /// In en, this message translates to:
  /// **'Purchased'**
  String get creditPaidLabel;

  /// No description provided for @creditBonusLabel.
  ///
  /// In en, this message translates to:
  /// **'Bonus'**
  String get creditBonusLabel;

  /// No description provided for @creditHeldLabel.
  ///
  /// In en, this message translates to:
  /// **'On hold'**
  String get creditHeldLabel;

  /// No description provided for @creditBonusExpiry.
  ///
  /// In en, this message translates to:
  /// **'Bonus points start expiring on {date}.'**
  String creditBonusExpiry(String date);

  /// No description provided for @creditHeldHint.
  ///
  /// In en, this message translates to:
  /// **'Points on hold belong to listings awaiting review and come back if a listing is rejected.'**
  String get creditHeldHint;

  /// No description provided for @creditTopupAction.
  ///
  /// In en, this message translates to:
  /// **'Buy points'**
  String get creditTopupAction;

  /// No description provided for @creditUsesTitle.
  ///
  /// In en, this message translates to:
  /// **'Use points to'**
  String get creditUsesTitle;

  /// No description provided for @creditUsePostMore.
  ///
  /// In en, this message translates to:
  /// **'Post more'**
  String get creditUsePostMore;

  /// No description provided for @creditUseBoost.
  ///
  /// In en, this message translates to:
  /// **'Boost a listing'**
  String get creditUseBoost;

  /// No description provided for @creditUseUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade plan'**
  String get creditUseUpgrade;

  /// No description provided for @creditRecentTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get creditRecentTitle;

  /// No description provided for @creditSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get creditSeeAll;

  /// No description provided for @creditEmptyHistory.
  ///
  /// In en, this message translates to:
  /// **'No point activity yet'**
  String get creditEmptyHistory;

  /// No description provided for @creditLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your points'**
  String get creditLoadError;

  /// No description provided for @creditHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Points history'**
  String get creditHistoryTitle;

  /// No description provided for @creditFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get creditFilterAll;

  /// No description provided for @creditFilterTopup.
  ///
  /// In en, this message translates to:
  /// **'Purchases'**
  String get creditFilterTopup;

  /// No description provided for @creditFilterSpend.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get creditFilterSpend;

  /// No description provided for @creditFilterRefund.
  ///
  /// In en, this message translates to:
  /// **'Refunds'**
  String get creditFilterRefund;

  /// No description provided for @creditTxnTopup.
  ///
  /// In en, this message translates to:
  /// **'Points purchase'**
  String get creditTxnTopup;

  /// No description provided for @creditTxnBonus.
  ///
  /// In en, this message translates to:
  /// **'Bonus points'**
  String get creditTxnBonus;

  /// No description provided for @creditTxnSpend.
  ///
  /// In en, this message translates to:
  /// **'Points spent'**
  String get creditTxnSpend;

  /// No description provided for @creditTxnRefund.
  ///
  /// In en, this message translates to:
  /// **'Points refunded'**
  String get creditTxnRefund;

  /// No description provided for @creditTxnExpire.
  ///
  /// In en, this message translates to:
  /// **'Points expired'**
  String get creditTxnExpire;

  /// No description provided for @creditTxnAdjust.
  ///
  /// In en, this message translates to:
  /// **'Adjustment'**
  String get creditTxnAdjust;

  /// No description provided for @creditTxnOrder.
  ///
  /// In en, this message translates to:
  /// **'Order {code}'**
  String creditTxnOrder(String code);

  /// No description provided for @creditTopupTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a pack'**
  String get creditTopupTitle;

  /// No description provided for @creditRate.
  ///
  /// In en, this message translates to:
  /// **'1 point = 1,000 VND. Bigger packs include bonus points.'**
  String get creditRate;

  /// No description provided for @creditPopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get creditPopular;

  /// No description provided for @creditBonusTag.
  ///
  /// In en, this message translates to:
  /// **'+{amount} bonus'**
  String creditBonusTag(String amount);

  /// No description provided for @creditNoBonus.
  ///
  /// In en, this message translates to:
  /// **'No bonus'**
  String get creditNoBonus;

  /// No description provided for @creditTerms.
  ///
  /// In en, this message translates to:
  /// **'Points can only be used in ReStore. They can\'t be cashed out or transferred to anyone. Bonus points are used first and expire after 90 days.'**
  String get creditTerms;

  /// No description provided for @creditContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue · {price}'**
  String creditContinue(String price);

  /// No description provided for @creditConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm purchase'**
  String get creditConfirmTitle;

  /// No description provided for @creditSummaryPack.
  ///
  /// In en, this message translates to:
  /// **'Pack'**
  String get creditSummaryPack;

  /// No description provided for @creditSummaryReceive.
  ///
  /// In en, this message translates to:
  /// **'You get'**
  String get creditSummaryReceive;

  /// No description provided for @creditSummaryTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get creditSummaryTotal;

  /// No description provided for @creditReceiveWithBonus.
  ///
  /// In en, this message translates to:
  /// **'{total} points ({bonus} bonus)'**
  String creditReceiveWithBonus(String total, String bonus);

  /// No description provided for @creditPayMethodTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get creditPayMethodTitle;

  /// No description provided for @creditMethodZalopay.
  ///
  /// In en, this message translates to:
  /// **'ZaloPay'**
  String get creditMethodZalopay;

  /// No description provided for @creditMethodZalopayDesc.
  ///
  /// In en, this message translates to:
  /// **'ZaloPay wallet, local ATM card or international card.'**
  String get creditMethodZalopayDesc;

  /// No description provided for @creditMethodVietqr.
  ///
  /// In en, this message translates to:
  /// **'VietQR bank transfer'**
  String get creditMethodVietqr;

  /// No description provided for @creditMethodVietqrDesc.
  ///
  /// In en, this message translates to:
  /// **'Scan with any banking app. Points arrive when the money does.'**
  String get creditMethodVietqrDesc;

  /// No description provided for @creditSandboxNote.
  ///
  /// In en, this message translates to:
  /// **'Test mode (sandbox): no real money is charged.'**
  String get creditSandboxNote;

  /// No description provided for @creditAgree.
  ///
  /// In en, this message translates to:
  /// **'I agree that points can\'t be exchanged back for cash, unless a payment fails or is charged twice.'**
  String get creditAgree;

  /// No description provided for @creditPayAction.
  ///
  /// In en, this message translates to:
  /// **'Pay {price}'**
  String creditPayAction(String price);

  /// No description provided for @creditPayZalopayTitle.
  ///
  /// In en, this message translates to:
  /// **'Pay with ZaloPay'**
  String get creditPayZalopayTitle;

  /// No description provided for @creditPayBankTitle.
  ///
  /// In en, this message translates to:
  /// **'Bank transfer'**
  String get creditPayBankTitle;

  /// No description provided for @creditOrderCode.
  ///
  /// In en, this message translates to:
  /// **'Order code'**
  String get creditOrderCode;

  /// No description provided for @creditGatewayNotConnected.
  ///
  /// In en, this message translates to:
  /// **'ZaloPay is skipped (debug mode or no server keys). Use the buttons below to simulate the result.'**
  String get creditGatewayNotConnected;

  /// No description provided for @creditOpenGateway.
  ///
  /// In en, this message translates to:
  /// **'Open ZaloPay checkout'**
  String get creditOpenGateway;

  /// No description provided for @creditWaitingGateway.
  ///
  /// In en, this message translates to:
  /// **'Finish paying on the ZaloPay page, then come back here. Your points update automatically.'**
  String get creditWaitingGateway;

  /// No description provided for @creditSimulateTitle.
  ///
  /// In en, this message translates to:
  /// **'Simulate the payment result (test mode only)'**
  String get creditSimulateTitle;

  /// No description provided for @creditSimulateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get creditSimulateSuccess;

  /// No description provided for @creditSimulateFail.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get creditSimulateFail;

  /// No description provided for @creditScanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan with any banking app'**
  String get creditScanQr;

  /// No description provided for @creditAccountNo.
  ///
  /// In en, this message translates to:
  /// **'Account number'**
  String get creditAccountNo;

  /// No description provided for @creditAccountName.
  ///
  /// In en, this message translates to:
  /// **'Account name'**
  String get creditAccountName;

  /// No description provided for @creditTransferContent.
  ///
  /// In en, this message translates to:
  /// **'Transfer note'**
  String get creditTransferContent;

  /// No description provided for @creditQrExpires.
  ///
  /// In en, this message translates to:
  /// **'Code expires at {time}'**
  String creditQrExpires(String time);

  /// No description provided for @creditWaitingTransfer.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your transfer. Keep the transfer note as is so the points arrive automatically.'**
  String get creditWaitingTransfer;

  /// No description provided for @creditVietQrUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The receiving bank account isn\'t set up on the server yet.'**
  String get creditVietQrUnavailable;

  /// No description provided for @creditCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get creditCopied;

  /// No description provided for @creditCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get creditCopy;

  /// No description provided for @creditCancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel order'**
  String get creditCancelOrder;

  /// No description provided for @creditResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get creditResultTitle;

  /// No description provided for @creditSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Purchase complete'**
  String get creditSuccessTitle;

  /// No description provided for @creditSuccessAmount.
  ///
  /// In en, this message translates to:
  /// **'+{amount} points'**
  String creditSuccessAmount(String amount);

  /// No description provided for @creditSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'The points are in your wallet.'**
  String get creditSuccessBody;

  /// No description provided for @creditPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for confirmation'**
  String get creditPendingTitle;

  /// No description provided for @creditPendingBody.
  ///
  /// In en, this message translates to:
  /// **'Your points will arrive as soon as the payment is confirmed. You can leave this page.'**
  String get creditPendingBody;

  /// No description provided for @creditFailTitle.
  ///
  /// In en, this message translates to:
  /// **'Purchase not completed'**
  String get creditFailTitle;

  /// No description provided for @creditFailBody.
  ///
  /// In en, this message translates to:
  /// **'The payment was cancelled or expired. You haven\'t been charged.'**
  String get creditFailBody;

  /// No description provided for @creditCheckAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get creditCheckAgain;

  /// No description provided for @creditTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get creditTryAgain;

  /// No description provided for @creditDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get creditDone;

  /// No description provided for @creditBackToWallet.
  ///
  /// In en, this message translates to:
  /// **'Back to wallet'**
  String get creditBackToWallet;

  /// No description provided for @creditErrorTooManyPending.
  ///
  /// In en, this message translates to:
  /// **'You have too many unpaid orders. Wait 15 minutes for them to expire or cancel one.'**
  String get creditErrorTooManyPending;

  /// No description provided for @creditErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong, please try again.'**
  String get creditErrorGeneric;

  /// No description provided for @creditPackagesError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load point packs'**
  String get creditPackagesError;

  /// No description provided for @postingLimitTotalTitle.
  ///
  /// In en, this message translates to:
  /// **'Free listings used up'**
  String get postingLimitTotalTitle;

  /// No description provided for @postingLimitTotalMessage.
  ///
  /// In en, this message translates to:
  /// **'A personal account can have at most {limit} free listings at once across all categories.'**
  String postingLimitTotalMessage(int limit);

  /// No description provided for @postingLimitRecentMessage.
  ///
  /// In en, this message translates to:
  /// **'You have posted for free in {category} many times in the last {days} days. Each category allows up to twice its free slots every {days} days.'**
  String postingLimitRecentMessage(String category, int days);

  /// No description provided for @postingPayTitle.
  ///
  /// In en, this message translates to:
  /// **'Post this listing for {credits} points'**
  String postingPayTitle(int credits);

  /// No description provided for @postingPayBalance.
  ///
  /// In en, this message translates to:
  /// **'Your wallet: {available} points'**
  String postingPayBalance(int available);

  /// No description provided for @postingPayNote.
  ///
  /// In en, this message translates to:
  /// **'Points are held when you submit and only spent once the listing is approved. Rejected listings get their points back.'**
  String get postingPayNote;

  /// No description provided for @postingPayMissing.
  ///
  /// In en, this message translates to:
  /// **'You need {missing} more points.'**
  String postingPayMissing(int missing);

  /// No description provided for @postingPayContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue · {credits} points'**
  String postingPayContinue(int credits);

  /// No description provided for @postingPayPublish.
  ///
  /// In en, this message translates to:
  /// **'Post · {credits} points'**
  String postingPayPublish(int credits);

  /// No description provided for @postingTopUp.
  ///
  /// In en, this message translates to:
  /// **'Buy points'**
  String get postingTopUp;

  /// No description provided for @postingFreeWaysTitle.
  ///
  /// In en, this message translates to:
  /// **'Or free up a free slot'**
  String get postingFreeWaysTitle;

  /// No description provided for @postingQuotaTotalUsage.
  ///
  /// In en, this message translates to:
  /// **'{used}/{limit} free listings used on your account'**
  String postingQuotaTotalUsage(int used, int limit);

  /// No description provided for @postingQuotaPaidHint.
  ///
  /// In en, this message translates to:
  /// **'Out of slots? Post more with points, from {credits} points per listing.'**
  String postingQuotaPaidHint(int credits);

  /// No description provided for @accExpiresIn.
  ///
  /// In en, this message translates to:
  /// **'{days} days left'**
  String accExpiresIn(int days);

  /// No description provided for @accExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get accExpired;

  /// No description provided for @accReactivate.
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get accReactivate;

  /// No description provided for @accReactivated.
  ///
  /// In en, this message translates to:
  /// **'Listing reactivated'**
  String get accReactivated;

  /// No description provided for @accExtend.
  ///
  /// In en, this message translates to:
  /// **'Extend listing'**
  String get accExtend;

  /// No description provided for @accExtendMessage.
  ///
  /// In en, this message translates to:
  /// **'Show this listing for {days} more days for {credits} points. Points are spent right away, no new review needed.'**
  String accExtendMessage(int days, int credits);

  /// No description provided for @accExtendPay.
  ///
  /// In en, this message translates to:
  /// **'Extend · {credits} points'**
  String accExtendPay(int credits);

  /// No description provided for @accExtendTooEarly.
  ///
  /// In en, this message translates to:
  /// **'You can extend once {days} days or fewer are left.'**
  String accExtendTooEarly(int days);

  /// No description provided for @accExtended.
  ///
  /// In en, this message translates to:
  /// **'Listing extended'**
  String get accExtended;

  /// No description provided for @postingPayReactivate.
  ///
  /// In en, this message translates to:
  /// **'Reactivate · {credits} points'**
  String postingPayReactivate(int credits);

  /// No description provided for @postingLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get postingLater;

  /// No description provided for @duplicateActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'You already posted this'**
  String get duplicateActiveTitle;

  /// No description provided for @duplicateActiveMessage.
  ///
  /// In en, this message translates to:
  /// **'A matching listing of yours is live or waiting for review, so there is no need to post it again.'**
  String get duplicateActiveMessage;

  /// No description provided for @duplicateInactiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Reuse your old listing?'**
  String get duplicateInactiveTitle;

  /// No description provided for @duplicateInactiveMessage.
  ///
  /// In en, this message translates to:
  /// **'You have a matching listing that is hidden or expired. Reactivate it to keep its views and saves.'**
  String get duplicateInactiveMessage;

  /// No description provided for @duplicateOpenOld.
  ///
  /// In en, this message translates to:
  /// **'See old listing'**
  String get duplicateOpenOld;

  /// No description provided for @duplicatePostNew.
  ///
  /// In en, this message translates to:
  /// **'Post new anyway'**
  String get duplicatePostNew;

  /// No description provided for @postingPayReactivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Show this listing again for {credits} points'**
  String postingPayReactivateTitle(int credits);

  /// No description provided for @postingPayNowNote.
  ///
  /// In en, this message translates to:
  /// **'Points are spent as soon as the listing is shown again, no new review needed.'**
  String get postingPayNowNote;

  /// No description provided for @boostSheetMessage.
  ///
  /// In en, this message translates to:
  /// **'Your listing moves to the top of the list for 24 hours.'**
  String get boostSheetMessage;

  /// No description provided for @boostFreeNote.
  ///
  /// In en, this message translates to:
  /// **'Uses 1 free boost from your plan, {left}/{perMonth} left this month.'**
  String boostFreeNote(int left, int perMonth);

  /// No description provided for @boostPayNote.
  ///
  /// In en, this message translates to:
  /// **'Costs {credits} points, spent right away.'**
  String boostPayNote(int credits);

  /// No description provided for @boostDiscountNote.
  ///
  /// In en, this message translates to:
  /// **'Your plan gets {percent}% off.'**
  String boostDiscountNote(int percent);

  /// No description provided for @boostUseFree.
  ///
  /// In en, this message translates to:
  /// **'Boost for free'**
  String get boostUseFree;

  /// No description provided for @boostPay.
  ///
  /// In en, this message translates to:
  /// **'Boost · {credits} points'**
  String boostPay(int credits);

  /// No description provided for @boostDone.
  ///
  /// In en, this message translates to:
  /// **'Listing boosted to the top'**
  String get boostDone;

  /// No description provided for @boostTooSoon.
  ///
  /// In en, this message translates to:
  /// **'This listing was just boosted. You can boost it again in {hours} hours.'**
  String boostTooSoon(int hours);

  /// No description provided for @plansTitle.
  ///
  /// In en, this message translates to:
  /// **'Account plans'**
  String get plansTitle;

  /// No description provided for @plansSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Paid with points, 30 days each time'**
  String get plansSubtitle;

  /// No description provided for @plansCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current plan'**
  String get plansCurrent;

  /// No description provided for @plansCurrentUntil.
  ///
  /// In en, this message translates to:
  /// **'Active until {date}'**
  String plansCurrentUntil(String date);

  /// No description provided for @plansFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get plansFree;

  /// No description provided for @plansPersonalBenefitFree.
  ///
  /// In en, this message translates to:
  /// **'1 to 3 free listings per category, up to 5 in total'**
  String get plansPersonalBenefitFree;

  /// No description provided for @plansPersonalBenefitPay.
  ///
  /// In en, this message translates to:
  /// **'Out of slots? Post more with points'**
  String get plansPersonalBenefitPay;

  /// No description provided for @plansPrice.
  ///
  /// In en, this message translates to:
  /// **'{price} points / 30 days'**
  String plansPrice(int price);

  /// No description provided for @plansBenefitActive.
  ///
  /// In en, this message translates to:
  /// **'{count} active listings at a time'**
  String plansBenefitActive(int count);

  /// No description provided for @plansBenefitDaily.
  ///
  /// In en, this message translates to:
  /// **'{count} new listings per day'**
  String plansBenefitDaily(int count);

  /// No description provided for @plansBenefitDrafts.
  ///
  /// In en, this message translates to:
  /// **'Keep {count} drafts'**
  String plansBenefitDrafts(int count);

  /// No description provided for @plansBenefitBoosts.
  ///
  /// In en, this message translates to:
  /// **'{count} free boosts every month'**
  String plansBenefitBoosts(int count);

  /// No description provided for @plansBenefitBoostDiscount.
  ///
  /// In en, this message translates to:
  /// **'{percent}% off boosts'**
  String plansBenefitBoostDiscount(int percent);

  /// No description provided for @plansBenefitPriority.
  ///
  /// In en, this message translates to:
  /// **'Shown first in your main category'**
  String get plansBenefitPriority;

  /// No description provided for @plansBenefitShopPage.
  ///
  /// In en, this message translates to:
  /// **'Your own shop page (coming soon)'**
  String get plansBenefitShopPage;

  /// No description provided for @plansBuy.
  ///
  /// In en, this message translates to:
  /// **'Get this plan'**
  String get plansBuy;

  /// No description provided for @plansRenew.
  ///
  /// In en, this message translates to:
  /// **'Renew'**
  String get plansRenew;

  /// No description provided for @plansUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get plansUpgrade;

  /// No description provided for @plansInUse.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get plansInUse;

  /// No description provided for @plansLowerLocked.
  ///
  /// In en, this message translates to:
  /// **'Available when your current plan ends'**
  String get plansLowerLocked;

  /// No description provided for @plansNote.
  ///
  /// In en, this message translates to:
  /// **'Upgrading mid-period credits the unused part of your old plan. Renewing adds 30 days. Points are spent right away and the plan starts immediately.'**
  String get plansNote;

  /// No description provided for @plansCheckoutPrice.
  ///
  /// In en, this message translates to:
  /// **'Plan price'**
  String get plansCheckoutPrice;

  /// No description provided for @plansCheckoutCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit for unused days'**
  String get plansCheckoutCredit;

  /// No description provided for @plansCheckoutTotal.
  ///
  /// In en, this message translates to:
  /// **'To pay'**
  String get plansCheckoutTotal;

  /// No description provided for @plansCheckoutUntil.
  ///
  /// In en, this message translates to:
  /// **'Active until'**
  String get plansCheckoutUntil;

  /// No description provided for @plansCheckoutCategory.
  ///
  /// In en, this message translates to:
  /// **'Main category'**
  String get plansCheckoutCategory;

  /// No description provided for @plansCheckoutCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'Listings in this category are shown first.'**
  String get plansCheckoutCategoryHint;

  /// No description provided for @plansCredits.
  ///
  /// In en, this message translates to:
  /// **'{count} points'**
  String plansCredits(int count);

  /// No description provided for @plansPay.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount} points'**
  String plansPay(int amount);

  /// No description provided for @plansActivated.
  ///
  /// In en, this message translates to:
  /// **'{name} plan activated'**
  String plansActivated(String name);

  /// No description provided for @plansLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load plans.'**
  String get plansLoadError;

  /// No description provided for @plansActionError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get plansActionError;

  /// No description provided for @plansUpgradeAction.
  ///
  /// In en, this message translates to:
  /// **'Upgrade plan'**
  String get plansUpgradeAction;

  /// No description provided for @postingUpgradeHint.
  ///
  /// In en, this message translates to:
  /// **'Need more listings? Upgrade your plan'**
  String get postingUpgradeHint;

  /// No description provided for @hotSaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Hot sale'**
  String get hotSaleTitle;

  /// No description provided for @featureAction.
  ///
  /// In en, this message translates to:
  /// **'Put on Hot sale'**
  String get featureAction;

  /// No description provided for @featureSheetMessage.
  ///
  /// In en, this message translates to:
  /// **'Your listing shows in Hot sale on the home page and at the top of its category, above other listings, for the time you choose.'**
  String get featureSheetMessage;

  /// No description provided for @featureDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String featureDays(int days);

  /// No description provided for @featurePay.
  ///
  /// In en, this message translates to:
  /// **'Buy · {credits} points'**
  String featurePay(int credits);

  /// No description provided for @featureDone.
  ///
  /// In en, this message translates to:
  /// **'Your listing is on Hot sale'**
  String get featureDone;

  /// No description provided for @featureRunning.
  ///
  /// In en, this message translates to:
  /// **'This listing is on Hot sale until {date}.'**
  String featureRunning(String date);

  /// No description provided for @featureUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Only visible listings can go on Hot sale.'**
  String get featureUnavailable;

  /// No description provided for @featureNoOptions.
  ///
  /// In en, this message translates to:
  /// **'No Hot sale packages are on sale right now.'**
  String get featureNoOptions;

  /// No description provided for @accExpiresOn.
  ///
  /// In en, this message translates to:
  /// **'Expires {date} · {days} days left'**
  String accExpiresOn(String date, int days);

  /// No description provided for @accExpiredOn.
  ///
  /// In en, this message translates to:
  /// **'Expired {date}'**
  String accExpiredOn(String date);

  /// No description provided for @previewDisplayDays.
  ///
  /// In en, this message translates to:
  /// **'Your listing shows for {days} days after approval. You can extend it near the end, or reactivate it once it expires.'**
  String previewDisplayDays(int days);

  /// No description provided for @hotSaleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Listings sellers are promoting right now, updated all the time.'**
  String get hotSaleSubtitle;

  /// No description provided for @hotSaleLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load Hot sale listings'**
  String get hotSaleLoadError;

  /// No description provided for @hotSaleEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No Hot sale listings yet'**
  String get hotSaleEmptyTitle;

  /// No description provided for @hotSaleEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Listings that sellers put on Hot sale will show up here.'**
  String get hotSaleEmptyBody;

  /// No description provided for @hotSaleEnd.
  ///
  /// In en, this message translates to:
  /// **'You\'ve seen all Hot sale listings'**
  String get hotSaleEnd;

  /// No description provided for @displayDaysTitle.
  ///
  /// In en, this message translates to:
  /// **'Display time'**
  String get displayDaysTitle;

  /// No description provided for @displayDaysFree.
  ///
  /// In en, this message translates to:
  /// **'Free · {days} days'**
  String displayDaysFree(int days);

  /// No description provided for @displayDaysPlus.
  ///
  /// In en, this message translates to:
  /// **'+{days} days'**
  String displayDaysPlus(int days);

  /// No description provided for @displayDaysRange.
  ///
  /// In en, this message translates to:
  /// **'{start} → {end} · {days} days'**
  String displayDaysRange(String start, String end, int days);

  /// No description provided for @displayDaysStart.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get displayDaysStart;

  /// No description provided for @displayDaysEnd.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get displayDaysEnd;

  /// No description provided for @displayDaysToday.
  ///
  /// In en, this message translates to:
  /// **'Today, once approved'**
  String get displayDaysToday;

  /// No description provided for @displayDaysCount.
  ///
  /// In en, this message translates to:
  /// **'Days on display'**
  String get displayDaysCount;

  /// No description provided for @displayDaysExtraCount.
  ///
  /// In en, this message translates to:
  /// **'Extra days'**
  String get displayDaysExtraCount;

  /// No description provided for @displayDaysIncluded.
  ///
  /// In en, this message translates to:
  /// **'Includes {free} free days for this category'**
  String displayDaysIncluded(int free);

  /// No description provided for @displayDaysExtraPrice.
  ///
  /// In en, this message translates to:
  /// **'{days} extra days: {credits} points'**
  String displayDaysExtraPrice(int days, int credits);

  /// No description provided for @displayDaysNoCharge.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get displayDaysNoCharge;

  /// No description provided for @displayDaysPackSave.
  ///
  /// In en, this message translates to:
  /// **'{days}-day pack price, you save {credits} points'**
  String displayDaysPackSave(int days, int credits);

  /// No description provided for @displayDaysSuggest.
  ///
  /// In en, this message translates to:
  /// **'Get {days} days for {credits} points'**
  String displayDaysSuggest(int days, int credits);

  /// No description provided for @displayDaysMax.
  ///
  /// In en, this message translates to:
  /// **'This category can be shown for up to {days} days.'**
  String displayDaysMax(int days);

  /// No description provided for @displayDaysPayNote.
  ///
  /// In en, this message translates to:
  /// **'Points are held when you post, charged on approval and refunded if rejected.'**
  String get displayDaysPayNote;

  /// No description provided for @displayDaysDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get displayDaysDone;

  /// No description provided for @displayDaysCardHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to change the start date or add days'**
  String get displayDaysCardHint;

  /// No description provided for @displayDaysScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled from {date}'**
  String displayDaysScheduled(String date);

  /// No description provided for @extendNewEnd.
  ///
  /// In en, this message translates to:
  /// **'New end date: {date}'**
  String extendNewEnd(String date);

  /// No description provided for @extendCurrentEnd.
  ///
  /// In en, this message translates to:
  /// **'Showing until {date}'**
  String extendCurrentEnd(String date);

  /// No description provided for @extendAddable.
  ///
  /// In en, this message translates to:
  /// **'You can add up to {days} more days'**
  String extendAddable(int days);

  /// No description provided for @extendLimitReached.
  ///
  /// In en, this message translates to:
  /// **'This listing is already at the {days}-day maximum.'**
  String extendLimitReached(int days);

  /// No description provided for @extendChargeNote.
  ///
  /// In en, this message translates to:
  /// **'Points are charged now, no new review needed.'**
  String get extendChargeNote;

  /// No description provided for @autoExtendTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-extend 30 days'**
  String get autoExtendTitle;

  /// No description provided for @autoExtendBody.
  ///
  /// In en, this message translates to:
  /// **'When less than a day is left, {credits} points are charged if your wallet has enough.'**
  String autoExtendBody(int credits);

  /// No description provided for @autoExtendOn.
  ///
  /// In en, this message translates to:
  /// **'Auto-extend is on'**
  String get autoExtendOn;

  /// No description provided for @autoExtendOff.
  ///
  /// In en, this message translates to:
  /// **'Auto-extend is off'**
  String get autoExtendOff;

  /// No description provided for @accExtendedDays.
  ///
  /// In en, this message translates to:
  /// **'Extended by {days} days'**
  String accExtendedDays(int days);

  /// No description provided for @displayDaysTodayShort.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get displayDaysTodayShort;

  /// No description provided for @displayDaysShortTitle.
  ///
  /// In en, this message translates to:
  /// **'Not enough points for extra days'**
  String get displayDaysShortTitle;

  /// No description provided for @displayDaysShortBody.
  ///
  /// In en, this message translates to:
  /// **'You need {missing} more points for the extra days. Top up, or post with the free days.'**
  String displayDaysShortBody(int missing);

  /// No description provided for @displayDaysUseFree.
  ///
  /// In en, this message translates to:
  /// **'Post with {days} free days'**
  String displayDaysUseFree(int days);

  /// No description provided for @originalPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Original price (before discount)'**
  String get originalPriceLabel;

  /// No description provided for @originalPricePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Leave empty if not on sale'**
  String get originalPricePlaceholder;

  /// No description provided for @originalPriceHint.
  ///
  /// In en, this message translates to:
  /// **'For shops: buyers see the original price struck through and the % off. It cannot be raised after posting.'**
  String get originalPriceHint;

  /// No description provided for @originalPriceDiscount.
  ///
  /// In en, this message translates to:
  /// **'{percent}% off the original price'**
  String originalPriceDiscount(int percent);

  /// No description provided for @originalPriceError.
  ///
  /// In en, this message translates to:
  /// **'Original price must be higher than the sale price'**
  String get originalPriceError;

  /// No description provided for @promoTitle.
  ///
  /// In en, this message translates to:
  /// **'Promote listing'**
  String get promoTitle;

  /// No description provided for @promoNotPromotable.
  ///
  /// In en, this message translates to:
  /// **'This listing isn\'t visible, so it can\'t be promoted. Show it again in Manage listings, then come back.'**
  String get promoNotPromotable;

  /// No description provided for @promoBoostRunning.
  ///
  /// In en, this message translates to:
  /// **'At the top of the list until {date}'**
  String promoBoostRunning(String date);

  /// No description provided for @promoBoostAgainAt.
  ///
  /// In en, this message translates to:
  /// **'Boost again after {date}'**
  String promoBoostAgainAt(String date);

  /// No description provided for @promoRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get promoRunning;

  /// No description provided for @promoHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent promotions'**
  String get promoHistoryTitle;

  /// No description provided for @promoHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'This listing hasn\'t been promoted yet.'**
  String get promoHistoryEmpty;

  /// No description provided for @promoHistoryFeature.
  ///
  /// In en, this message translates to:
  /// **'Hot sale {days} days'**
  String promoHistoryFeature(int days);

  /// No description provided for @promoFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get promoFree;

  /// No description provided for @promoEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get promoEnded;

  /// No description provided for @promoLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load promotion info'**
  String get promoLoadError;

  /// No description provided for @promoBalanceAfter.
  ///
  /// In en, this message translates to:
  /// **'{left} points left in your wallet after paying.'**
  String promoBalanceAfter(int left);

  /// No description provided for @promoPickTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a listing to promote'**
  String get promoPickTitle;

  /// No description provided for @promoPickSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only visible listings can be boosted or put on Hot sale'**
  String get promoPickSubtitle;

  /// No description provided for @promoPickEmpty.
  ///
  /// In en, this message translates to:
  /// **'You have no visible listings yet.'**
  String get promoPickEmpty;

  /// No description provided for @hubTitle.
  ///
  /// In en, this message translates to:
  /// **'Promotions'**
  String get hubTitle;

  /// No description provided for @hubFreeBoosts.
  ///
  /// In en, this message translates to:
  /// **'{left}/{perMonth} free boosts left'**
  String hubFreeBoosts(int left, int perMonth);

  /// No description provided for @hubThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month: {boosts} boosts · {features} Hot sale'**
  String hubThisMonth(int boosts, int features);

  /// No description provided for @hubFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get hubFilterAll;

  /// No description provided for @hubFilterRunning.
  ///
  /// In en, this message translates to:
  /// **'Promoted'**
  String get hubFilterRunning;

  /// No description provided for @hubFilterExpiring.
  ///
  /// In en, this message translates to:
  /// **'Expiring soon'**
  String get hubFilterExpiring;

  /// No description provided for @hubFilterIdle.
  ///
  /// In en, this message translates to:
  /// **'Not promoted'**
  String get hubFilterIdle;

  /// No description provided for @hubBoostedFor.
  ///
  /// In en, this message translates to:
  /// **'Boosted · {time} left'**
  String hubBoostedFor(String time);

  /// No description provided for @hubFeaturedFor.
  ///
  /// In en, this message translates to:
  /// **'Hot sale · {time} left'**
  String hubFeaturedFor(String time);

  /// No description provided for @hubExpiresIn.
  ///
  /// In en, this message translates to:
  /// **'Expires in {time}'**
  String hubExpiresIn(String time);

  /// No description provided for @hubHours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour} other{{count} hours}}'**
  String hubHours(int count);

  /// No description provided for @hubDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String hubDays(int count);

  /// No description provided for @hubAutoExtend.
  ///
  /// In en, this message translates to:
  /// **'Auto-extend'**
  String get hubAutoExtend;

  /// No description provided for @hubDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get hubDetails;

  /// No description provided for @hubEmptyRunning.
  ///
  /// In en, this message translates to:
  /// **'No listing is boosted or on Hot sale right now.'**
  String get hubEmptyRunning;

  /// No description provided for @hubEmptyExpiring.
  ///
  /// In en, this message translates to:
  /// **'No listing expires in the next 7 days.'**
  String get hubEmptyExpiring;

  /// No description provided for @hubEmptyIdle.
  ///
  /// In en, this message translates to:
  /// **'All your listings are being promoted.'**
  String get hubEmptyIdle;

  /// No description provided for @hubExpiringTip.
  ///
  /// In en, this message translates to:
  /// **'{count} listings expiring soon: extend them so they stay visible.'**
  String hubExpiringTip(int count);

  /// No description provided for @insTitle.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insTitle;

  /// No description provided for @insRangeDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String insRangeDays(int days);

  /// No description provided for @insViews.
  ///
  /// In en, this message translates to:
  /// **'Views'**
  String get insViews;

  /// No description provided for @insSaves.
  ///
  /// In en, this message translates to:
  /// **'Saves'**
  String get insSaves;

  /// No description provided for @insChats.
  ///
  /// In en, this message translates to:
  /// **'People who messaged'**
  String get insChats;

  /// No description provided for @insUp.
  ///
  /// In en, this message translates to:
  /// **'Up {percent}% vs previous period'**
  String insUp(int percent);

  /// No description provided for @insDown.
  ///
  /// In en, this message translates to:
  /// **'Down {percent}% vs previous period'**
  String insDown(int percent);

  /// No description provided for @insSame.
  ///
  /// In en, this message translates to:
  /// **'Same as previous period'**
  String get insSame;

  /// No description provided for @insNew.
  ///
  /// In en, this message translates to:
  /// **'None in previous period'**
  String get insNew;

  /// No description provided for @insChartTitle.
  ///
  /// In en, this message translates to:
  /// **'Views per day'**
  String get insChartTitle;

  /// No description provided for @insChartEmpty.
  ///
  /// In en, this message translates to:
  /// **'No views in this period yet.'**
  String get insChartEmpty;

  /// No description provided for @insChartDay.
  ///
  /// In en, this message translates to:
  /// **'{date}: {views} views · {saves} saves'**
  String insChartDay(String date, int views, int saves);

  /// No description provided for @insChartHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a bar to see that day'**
  String get insChartHint;

  /// No description provided for @insListingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Listings'**
  String get insListingsTitle;

  /// No description provided for @insActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get insActive;

  /// No description provided for @insPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get insPending;

  /// No description provided for @insHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get insHidden;

  /// No description provided for @insSold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get insSold;

  /// No description provided for @insTopTitle.
  ///
  /// In en, this message translates to:
  /// **'Most viewed listings'**
  String get insTopTitle;

  /// No description provided for @insTopStats.
  ///
  /// In en, this message translates to:
  /// **'{views} views · {saves} saves'**
  String insTopStats(int views, int saves);

  /// No description provided for @insTopEmpty.
  ///
  /// In en, this message translates to:
  /// **'No visible listings yet.'**
  String get insTopEmpty;

  /// No description provided for @insTipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tips'**
  String get insTipsTitle;

  /// No description provided for @insTipBoost.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" is your most viewed listing. Boost it to stay on top.'**
  String insTipBoost(String title);

  /// No description provided for @insTipExpiring.
  ///
  /// In en, this message translates to:
  /// **'{count} listings expire within 7 days. Extend them so they stay visible.'**
  String insTipExpiring(int count);

  /// No description provided for @insTipNoViews.
  ///
  /// In en, this message translates to:
  /// **'No views yet: clear photos, a specific title and a fair price help people notice your listings.'**
  String get insTipNoViews;

  /// No description provided for @insPromotions.
  ///
  /// In en, this message translates to:
  /// **'This period: {boosts} boosts · {features} Hot sale'**
  String insPromotions(int boosts, int features);

  /// No description provided for @insLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load insights'**
  String get insLoadError;

  /// No description provided for @insViewsNote.
  ///
  /// In en, this message translates to:
  /// **'Daily views are recorded from 11/11/2026.'**
  String get insViewsNote;

  /// No description provided for @spTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop posters'**
  String get spTitle;

  /// No description provided for @spCreate.
  ///
  /// In en, this message translates to:
  /// **'New poster'**
  String get spCreate;

  /// No description provided for @spLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load posters'**
  String get spLoadError;

  /// No description provided for @spNoShopTitle.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have a shop page yet'**
  String get spNoShopTitle;

  /// No description provided for @spNoShopBody.
  ///
  /// In en, this message translates to:
  /// **'Posters appear on your shop page and on Trusted shops, so you need a shop page first.'**
  String get spNoShopBody;

  /// No description provided for @spPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Posters are part of the Store plan'**
  String get spPlanTitle;

  /// No description provided for @spPlanBody.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to the Store plan to run posters on your shop page and on Trusted shops.'**
  String get spPlanBody;

  /// No description provided for @spSeePlans.
  ///
  /// In en, this message translates to:
  /// **'See plans'**
  String get spSeePlans;

  /// No description provided for @spSlots.
  ///
  /// In en, this message translates to:
  /// **'Posters at once'**
  String get spSlots;

  /// No description provided for @spMonthly.
  ///
  /// In en, this message translates to:
  /// **'Sent this month'**
  String get spMonthly;

  /// No description provided for @spUnverified.
  ///
  /// In en, this message translates to:
  /// **'Your shop isn\'t verified yet, so approved posters aren\'t shown publicly.'**
  String get spUnverified;

  /// No description provided for @spCooldown.
  ///
  /// In en, this message translates to:
  /// **'You can\'t send posters until {date} because several were rejected.'**
  String spCooldown(String date);

  /// No description provided for @spRules.
  ///
  /// In en, this message translates to:
  /// **'1200×600 image (2:1), runs {min} to {max} days. Reviewed within about 24 hours.'**
  String spRules(int min, int max);

  /// No description provided for @spMonthlyFull.
  ///
  /// In en, this message translates to:
  /// **'You\'ve sent all {limit} posters for this month.'**
  String spMonthlyFull(int limit);

  /// No description provided for @spFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get spFilterAll;

  /// No description provided for @spFilterRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get spFilterRunning;

  /// No description provided for @spFilterPending.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get spFilterPending;

  /// No description provided for @spFilterScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get spFilterScheduled;

  /// No description provided for @spFilterRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get spFilterRejected;

  /// No description provided for @spFilterEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get spFilterEnded;

  /// No description provided for @spStateStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get spStateStopped;

  /// No description provided for @spEmpty.
  ///
  /// In en, this message translates to:
  /// **'No posters yet'**
  String get spEmpty;

  /// No description provided for @spEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Create your first poster to promote a shop campaign.'**
  String get spEmptyBody;

  /// No description provided for @spEmptyFilter.
  ///
  /// In en, this message translates to:
  /// **'No posters here.'**
  String get spEmptyFilter;

  /// No description provided for @spDates.
  ///
  /// In en, this message translates to:
  /// **'{start} – {end} · {days} days'**
  String spDates(String start, String end, int days);

  /// No description provided for @spOpensShop.
  ///
  /// In en, this message translates to:
  /// **'Opens your shop page'**
  String get spOpensShop;

  /// No description provided for @spOpensListing.
  ///
  /// In en, this message translates to:
  /// **'Opens listing: {title}'**
  String spOpensListing(String title);

  /// No description provided for @spRejectedReason.
  ///
  /// In en, this message translates to:
  /// **'Rejected: {reason}'**
  String spRejectedReason(String reason);

  /// No description provided for @spReasonWrongSize.
  ///
  /// In en, this message translates to:
  /// **'Wrong image size'**
  String get spReasonWrongSize;

  /// No description provided for @spReasonMisleadingPrice.
  ///
  /// In en, this message translates to:
  /// **'Misleading price or offer'**
  String get spReasonMisleadingPrice;

  /// No description provided for @spReasonBrandMisuse.
  ///
  /// In en, this message translates to:
  /// **'Uses a brand or logo that isn\'t yours'**
  String get spReasonBrandMisuse;

  /// No description provided for @spReasonProhibited.
  ///
  /// In en, this message translates to:
  /// **'Prohibited content'**
  String get spReasonProhibited;

  /// No description provided for @spReasonTooMuchText.
  ///
  /// In en, this message translates to:
  /// **'Too much text on the image'**
  String get spReasonTooMuchText;

  /// No description provided for @spReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other reason'**
  String get spReasonOther;

  /// No description provided for @spEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get spEdit;

  /// No description provided for @spResubmit.
  ///
  /// In en, this message translates to:
  /// **'Edit and resend'**
  String get spResubmit;

  /// No description provided for @spStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get spStop;

  /// No description provided for @spCancel.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get spCancel;

  /// No description provided for @spStopTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop this poster?'**
  String get spStopTitle;

  /// No description provided for @spStopBody.
  ///
  /// In en, this message translates to:
  /// **'The poster stops showing right away and can\'t be restarted.'**
  String get spStopBody;

  /// No description provided for @spCancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdraw this poster?'**
  String get spCancelTitle;

  /// No description provided for @spCancelBody.
  ///
  /// In en, this message translates to:
  /// **'It still counts toward this month\'s posters.'**
  String get spCancelBody;

  /// No description provided for @spConfirmStop.
  ///
  /// In en, this message translates to:
  /// **'Stop poster'**
  String get spConfirmStop;

  /// No description provided for @spConfirmCancel.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get spConfirmCancel;

  /// No description provided for @spKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get spKeep;

  /// No description provided for @spStopped.
  ///
  /// In en, this message translates to:
  /// **'Poster stopped'**
  String get spStopped;

  /// No description provided for @spNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New poster'**
  String get spNewTitle;

  /// No description provided for @spEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit poster'**
  String get spEditTitle;

  /// No description provided for @spImage.
  ///
  /// In en, this message translates to:
  /// **'Poster image'**
  String get spImage;

  /// No description provided for @spPickImage.
  ///
  /// In en, this message translates to:
  /// **'Choose a 1200×600 image'**
  String get spPickImage;

  /// No description provided for @spChangeImage.
  ///
  /// In en, this message translates to:
  /// **'Change image'**
  String get spChangeImage;

  /// No description provided for @spImageHint.
  ///
  /// In en, this message translates to:
  /// **'Pick any image, then drag and zoom it into the 2:1 frame. Put the text in the image itself.'**
  String get spImageHint;

  /// No description provided for @spImageRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a poster image.'**
  String get spImageRequired;

  /// No description provided for @spName.
  ///
  /// In en, this message translates to:
  /// **'Campaign name'**
  String get spName;

  /// No description provided for @spNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Galaxy Week up to 20% off'**
  String get spNameHint;

  /// No description provided for @spNameHelper.
  ///
  /// In en, this message translates to:
  /// **'Not drawn on the image; used by screen readers and to keep track.'**
  String get spNameHelper;

  /// No description provided for @spNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a campaign name.'**
  String get spNameRequired;

  /// No description provided for @spOpens.
  ///
  /// In en, this message translates to:
  /// **'When people tap the poster'**
  String get spOpens;

  /// No description provided for @spOpenShop.
  ///
  /// In en, this message translates to:
  /// **'Open shop page'**
  String get spOpenShop;

  /// No description provided for @spOpenListing.
  ///
  /// In en, this message translates to:
  /// **'Open a listing'**
  String get spOpenListing;

  /// No description provided for @spChooseListing.
  ///
  /// In en, this message translates to:
  /// **'Choose listing'**
  String get spChooseListing;

  /// No description provided for @spNoListings.
  ///
  /// In en, this message translates to:
  /// **'Your shop has no active listings.'**
  String get spNoListings;

  /// No description provided for @spListingRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a listing.'**
  String get spListingRequired;

  /// No description provided for @spStart.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get spStart;

  /// No description provided for @spStartNow.
  ///
  /// In en, this message translates to:
  /// **'As soon as approved'**
  String get spStartNow;

  /// No description provided for @spStartOn.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get spStartOn;

  /// No description provided for @spDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get spDuration;

  /// No description provided for @spDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String spDays(int days);

  /// No description provided for @spEndsOn.
  ///
  /// In en, this message translates to:
  /// **'Ends around {date}'**
  String spEndsOn(String date);

  /// No description provided for @spEditRunningNote.
  ///
  /// In en, this message translates to:
  /// **'A running poster is hidden until it\'s approved again.'**
  String get spEditRunningNote;

  /// No description provided for @spSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send for review'**
  String get spSubmit;

  /// No description provided for @spSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Poster sent. It\'s usually reviewed within 24 hours.'**
  String get spSubmitted;

  /// No description provided for @spErrSlotFull.
  ///
  /// In en, this message translates to:
  /// **'That time already has the most posters you can run at once. Pick another date or stop a poster.'**
  String get spErrSlotFull;

  /// No description provided for @spErrMonthly.
  ///
  /// In en, this message translates to:
  /// **'You\'ve sent all your posters for this month.'**
  String get spErrMonthly;

  /// No description provided for @spErrCooldown.
  ///
  /// In en, this message translates to:
  /// **'Sending posters is paused for your shop.'**
  String get spErrCooldown;

  /// No description provided for @spErrPlan.
  ///
  /// In en, this message translates to:
  /// **'Only the Store plan can run posters.'**
  String get spErrPlan;

  /// No description provided for @spErrShop.
  ///
  /// In en, this message translates to:
  /// **'You need a shop page to run posters.'**
  String get spErrShop;

  /// No description provided for @spErrListing.
  ///
  /// In en, this message translates to:
  /// **'That listing isn\'t for sale anymore. Choose another.'**
  String get spErrListing;

  /// No description provided for @spErrStartLate.
  ///
  /// In en, this message translates to:
  /// **'The start date can be at most 14 days ahead.'**
  String get spErrStartLate;

  /// No description provided for @spErrImage.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t upload the image. Try another one.'**
  String get spErrImage;

  /// No description provided for @spErrNotEditable.
  ///
  /// In en, this message translates to:
  /// **'This poster has ended. Create a new one.'**
  String get spErrNotEditable;

  /// No description provided for @spErrGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get spErrGeneric;

  /// No description provided for @spSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get spSchedule;

  /// No description provided for @spCropTitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust poster'**
  String get spCropTitle;

  /// No description provided for @spAdjust.
  ///
  /// In en, this message translates to:
  /// **'Adjust again'**
  String get spAdjust;

  /// No description provided for @cropDone.
  ///
  /// In en, this message translates to:
  /// **'Use this image'**
  String get cropDone;

  /// No description provided for @cropFill.
  ///
  /// In en, this message translates to:
  /// **'Fill frame'**
  String get cropFill;

  /// No description provided for @cropFit.
  ///
  /// In en, this message translates to:
  /// **'Show whole image'**
  String get cropFit;

  /// No description provided for @cropZoom.
  ///
  /// In en, this message translates to:
  /// **'Zoom'**
  String get cropZoom;

  /// No description provided for @cropHint.
  ///
  /// In en, this message translates to:
  /// **'Drag to move; pinch or use the slider to zoom. Empty space is filled with the background you pick.'**
  String get cropHint;

  /// No description provided for @cropLowRes.
  ///
  /// In en, this message translates to:
  /// **'The image is small for this frame and may look blurry. Zoom out or pick a larger image.'**
  String get cropLowRes;

  /// No description provided for @cropLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open this image. Try another one.'**
  String get cropLoadError;

  /// No description provided for @accAvatarSection.
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get accAvatarSection;

  /// No description provided for @accAvatarHint.
  ///
  /// In en, this message translates to:
  /// **'Shown in a circle on your profile, listings and messages. Tap Adjust to choose which part shows.'**
  String get accAvatarHint;

  /// No description provided for @accAdjustAvatar.
  ///
  /// In en, this message translates to:
  /// **'Adjust'**
  String get accAdjustAvatar;

  /// No description provided for @accAvatarCropTitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust profile photo'**
  String get accAvatarCropTitle;

  /// No description provided for @accInfoSection.
  ///
  /// In en, this message translates to:
  /// **'Profile details'**
  String get accInfoSection;

  /// No description provided for @accDisplayNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Jane Doe or your shop name'**
  String get accDisplayNameHint;

  /// No description provided for @accUsernameHelper.
  ///
  /// In en, this message translates to:
  /// **'3–30 characters: lowercase letters, numbers, dots or underscores.'**
  String get accUsernameHelper;

  /// No description provided for @accBioHint.
  ///
  /// In en, this message translates to:
  /// **'A few lines about you or your shop'**
  String get accBioHint;

  /// No description provided for @cropBackground.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get cropBackground;

  /// No description provided for @cropBgBlur.
  ///
  /// In en, this message translates to:
  /// **'Blur'**
  String get cropBgBlur;

  /// No description provided for @cropBgAuto.
  ///
  /// In en, this message translates to:
  /// **'Match'**
  String get cropBgAuto;

  /// No description provided for @cropBgWhite.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get cropBgWhite;

  /// No description provided for @cropBgBlack.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get cropBgBlack;

  /// No description provided for @cropTrim.
  ///
  /// In en, this message translates to:
  /// **'Remove plain borders'**
  String get cropTrim;

  /// No description provided for @cropTrimOn.
  ///
  /// In en, this message translates to:
  /// **'Plain borders removed'**
  String get cropTrimOn;

  /// No description provided for @msTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage shop'**
  String get msTitle;

  /// No description provided for @msLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your shop'**
  String get msLoadError;

  /// No description provided for @msPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop pages come with the Store plan'**
  String get msPlanTitle;

  /// No description provided for @msPlanBody.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to the Store plan to open your own shop page with a logo, cover and posters, and get verified for Trusted shops.'**
  String get msPlanBody;

  /// No description provided for @msCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Open your shop page'**
  String get msCreateTitle;

  /// No description provided for @msCreateBody.
  ///
  /// In en, this message translates to:
  /// **'Name your shop first, then add a logo, cover and description.'**
  String get msCreateBody;

  /// No description provided for @msCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Open shop'**
  String get msCreateAction;

  /// No description provided for @msCreated.
  ///
  /// In en, this message translates to:
  /// **'Your shop page is open'**
  String get msCreated;

  /// No description provided for @msName.
  ///
  /// In en, this message translates to:
  /// **'Shop name'**
  String get msName;

  /// No description provided for @msNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Cozy Home Decor'**
  String get msNameHint;

  /// No description provided for @msNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Shop name must be 2 to 60 characters.'**
  String get msNameRequired;

  /// No description provided for @msNameLocked.
  ///
  /// In en, this message translates to:
  /// **'Verified shops can\'t change their name. Contact ReStore if you need to.'**
  String get msNameLocked;

  /// No description provided for @msTagline.
  ///
  /// In en, this message translates to:
  /// **'Short tagline'**
  String get msTagline;

  /// No description provided for @msTaglineHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Handmade decor, fast local delivery'**
  String get msTaglineHint;

  /// No description provided for @msDescription.
  ///
  /// In en, this message translates to:
  /// **'About the shop'**
  String get msDescription;

  /// No description provided for @msDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'What you sell, quality promise, return policy...'**
  String get msDescriptionHint;

  /// No description provided for @msAddress.
  ///
  /// In en, this message translates to:
  /// **'Display address'**
  String get msAddress;

  /// No description provided for @msAddressHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. District 1, Ho Chi Minh City'**
  String get msAddressHint;

  /// No description provided for @msInfoSection.
  ///
  /// In en, this message translates to:
  /// **'Shop details'**
  String get msInfoSection;

  /// No description provided for @msColorSection.
  ///
  /// In en, this message translates to:
  /// **'Brand colour'**
  String get msColorSection;

  /// No description provided for @msColorHint.
  ///
  /// In en, this message translates to:
  /// **'Used for the letter logo, the default cover and accents on your shop page.'**
  String get msColorHint;

  /// No description provided for @msColorAuto.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get msColorAuto;

  /// No description provided for @msChangeCover.
  ///
  /// In en, this message translates to:
  /// **'Change cover'**
  String get msChangeCover;

  /// No description provided for @msChangeLogo.
  ///
  /// In en, this message translates to:
  /// **'Change logo'**
  String get msChangeLogo;

  /// No description provided for @msImageNew.
  ///
  /// In en, this message translates to:
  /// **'Choose a new image'**
  String get msImageNew;

  /// No description provided for @msImageAdjust.
  ///
  /// In en, this message translates to:
  /// **'Adjust again'**
  String get msImageAdjust;

  /// No description provided for @msImageRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove image'**
  String get msImageRemove;

  /// No description provided for @msCoverCropTitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust cover'**
  String get msCoverCropTitle;

  /// No description provided for @msLogoCropTitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust logo'**
  String get msLogoCropTitle;

  /// No description provided for @msStatFollowers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get msStatFollowers;

  /// No description provided for @msStatListings.
  ///
  /// In en, this message translates to:
  /// **'Listings'**
  String get msStatListings;

  /// No description provided for @msStatPostersRunning.
  ///
  /// In en, this message translates to:
  /// **'Posters live'**
  String get msStatPostersRunning;

  /// No description provided for @msStatPostersPending.
  ///
  /// In en, this message translates to:
  /// **'Posters pending'**
  String get msStatPostersPending;

  /// No description provided for @msVerifiedTitle.
  ///
  /// In en, this message translates to:
  /// **'Verified shop'**
  String get msVerifiedTitle;

  /// No description provided for @msVerifiedBody.
  ///
  /// In en, this message translates to:
  /// **'Your shop appears in Trusted shops.'**
  String get msVerifiedBody;

  /// No description provided for @msCertificate.
  ///
  /// In en, this message translates to:
  /// **'Certificate: {code}.'**
  String msCertificate(String code);

  /// No description provided for @msUnverifiedTitle.
  ///
  /// In en, this message translates to:
  /// **'Not verified yet'**
  String get msUnverifiedTitle;

  /// No description provided for @msUnverifiedBody.
  ///
  /// In en, this message translates to:
  /// **'Your shop isn\'t in Trusted shops yet and posters can\'t run. Contact ReStore to get verified.'**
  String get msUnverifiedBody;

  /// No description provided for @msPlanExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Store plan expired'**
  String get msPlanExpiredTitle;

  /// No description provided for @msPlanExpiredBody.
  ///
  /// In en, this message translates to:
  /// **'Your posters are hidden for now. Renew the plan to run them again.'**
  String get msPlanExpiredBody;

  /// No description provided for @msViewPublic.
  ///
  /// In en, this message translates to:
  /// **'View shop page'**
  String get msViewPublic;

  /// No description provided for @msPosters.
  ///
  /// In en, this message translates to:
  /// **'Shop posters'**
  String get msPosters;

  /// No description provided for @msPostersBody.
  ///
  /// In en, this message translates to:
  /// **'Promote your shop with posters on your shop page and Trusted shops.'**
  String get msPostersBody;

  /// No description provided for @msSave.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get msSave;

  /// No description provided for @msSaved.
  ///
  /// In en, this message translates to:
  /// **'Shop details saved'**
  String get msSaved;

  /// No description provided for @msErrExists.
  ///
  /// In en, this message translates to:
  /// **'You already have a shop page.'**
  String get msErrExists;

  /// No description provided for @msErrImage.
  ///
  /// In en, this message translates to:
  /// **'That image is not valid. Try another one.'**
  String get msErrImage;

  /// No description provided for @msErrGeneric.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save. Please try again.'**
  String get msErrGeneric;

  /// No description provided for @followShopsTab.
  ///
  /// In en, this message translates to:
  /// **'Shops'**
  String get followShopsTab;

  /// No description provided for @followShopsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You\'re not following any shops yet'**
  String get followShopsEmpty;

  /// No description provided for @followShopsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Follow trusted shops to see their new listings in one place.'**
  String get followShopsEmptyHint;

  /// No description provided for @followShopsBrowse.
  ///
  /// In en, this message translates to:
  /// **'Explore trusted shops'**
  String get followShopsBrowse;

  /// No description provided for @followShopsNewCount.
  ///
  /// In en, this message translates to:
  /// **'{count} new'**
  String followShopsNewCount(int count);

  /// No description provided for @followShopsFollowerCount.
  ///
  /// In en, this message translates to:
  /// **'{count} followers'**
  String followShopsFollowerCount(int count);

  /// No description provided for @followShopsFeedTitle.
  ///
  /// In en, this message translates to:
  /// **'Shops you follow'**
  String get followShopsFeedTitle;

  /// No description provided for @followShopsFeedCta.
  ///
  /// In en, this message translates to:
  /// **'See new listings'**
  String get followShopsFeedCta;

  /// No description provided for @followShopsFeedNew.
  ///
  /// In en, this message translates to:
  /// **'{count} new listings in the last 7 days'**
  String followShopsFeedNew(int count);

  /// No description provided for @followShopsCount.
  ///
  /// In en, this message translates to:
  /// **'Following {count} shops'**
  String followShopsCount(int count);

  /// No description provided for @followShopsStripHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a shop to open its page'**
  String get followShopsStripHint;

  /// No description provided for @followShopsLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest listings'**
  String get followShopsLatest;

  /// No description provided for @followShopsLatestHint.
  ///
  /// In en, this message translates to:
  /// **'Newly posted by the shops you follow'**
  String get followShopsLatestHint;

  /// No description provided for @followShopsListingsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No listings yet'**
  String get followShopsListingsEmpty;

  /// No description provided for @followShopsListingsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'The shops you follow have no active listings.'**
  String get followShopsListingsEmptyHint;

  /// No description provided for @followShopsEnd.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up'**
  String get followShopsEnd;

  /// No description provided for @followShopsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the shops you follow'**
  String get followShopsLoadError;

  /// No description provided for @msFollowersTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop followers'**
  String get msFollowersTitle;

  /// No description provided for @msFollowersTitleCount.
  ///
  /// In en, this message translates to:
  /// **'Followers ({count})'**
  String msFollowersTitleCount(int count);

  /// No description provided for @msFollowersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No one follows your shop yet'**
  String get msFollowersEmpty;

  /// No description provided for @msFollowersEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Buyers who follow your shop will show up here.'**
  String get msFollowersEmptyHint;

  /// No description provided for @msFollowedSince.
  ///
  /// In en, this message translates to:
  /// **'Since {date}'**
  String msFollowedSince(String date);
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
