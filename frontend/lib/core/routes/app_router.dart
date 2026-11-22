import 'package:restore/modules/content/views/community_content_view.dart';
import 'package:restore/modules/credits/views/credit_bonus/credit_bonus_view.dart';
import 'package:restore/modules/credits/views/credit_history/credit_history_view.dart';
import 'package:restore/modules/notifications/views/notifications/notifications_view.dart';
import 'package:restore/modules/credits/views/credit_topup/credit_topup_view.dart';
import 'package:restore/modules/credits/views/credit_wallet/credit_wallet_view.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/modules/feeds/views/feeds/feeds_view.dart';
import 'package:restore/modules/account/models/profile_models.dart';
import 'package:restore/modules/account/views/follow_list/follow_list_view.dart';
import 'package:restore/modules/account/views/language_settings/language_settings_view.dart';
import 'package:restore/modules/account/views/my_reviews/my_reviews_view.dart';
import 'package:restore/modules/account/views/public_profile/public_profile_view.dart';
import 'package:restore/modules/account/views/account/account_view.dart';
import 'package:restore/modules/account/bloc/user_profile/user_profile_cubit.dart';
import 'package:restore/modules/account/views/edit_profile/edit_profile_view.dart';
import 'package:restore/modules/my_shop/views/my_shop/my_shop_view.dart';
import 'package:restore/modules/my_shop/views/shop_followers/shop_followers_view.dart';
import 'package:restore/modules/following/views/following_hub/following_hub_view.dart';
import 'package:restore/modules/trusted_shop/views/following_shops/following_shops_view.dart';
import 'package:restore/modules/chat/views/messages/messages_view.dart';
import 'package:restore/modules/chat/views/messages/live_messages_view.dart';
import 'package:restore/modules/home/views/home/home_view.dart';

import 'package:restore/modules/feed/views/post_composer/post_composer_view.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/modules/listings/bloc/create_listing/create_listing_bloc.dart';
import 'package:restore/modules/listings/bloc/create_listing/create_listing_event.dart';
import 'package:restore/modules/listings/repositories/category_repository.dart';
import 'package:restore/modules/listings/models/create_listing_step.dart';
import 'package:restore/modules/listings/repositories/listings_repository.dart';
import 'package:restore/modules/listings/repositories/posting_quota_repository.dart';
import 'package:restore/modules/listings/views/basic_info/basic_info_view.dart';
import 'package:restore/modules/listings/views/choose_category/choose_category_view.dart';
import 'package:restore/modules/listings/views/listing_details/listing_details_view.dart';
import 'package:restore/modules/listings/views/listing_preview/listing_preview_view.dart';
import 'package:restore/modules/listings/views/listing_drafts/listing_drafts_view.dart';
import 'package:restore/modules/listings/views/edit_listing/edit_listing_view.dart';
import 'package:restore/modules/listings/views/product_detail/product_detail_view.dart';
import 'package:restore/data/models/listing_model.dart';
import 'package:restore/modules/location/repositories/location_repository.dart';
import 'package:restore/modules/location/views/area_search/area_search_view.dart';
import 'package:restore/modules/category_detail/views/category_detail/category_detail_view.dart';
import 'package:restore/modules/hot_sale/views/hot_sale/hot_sale_view.dart';
import 'package:restore/modules/saved_listings/views/saved_listings_view.dart';
import 'package:restore/data/models/category_model.dart';
import 'package:restore/modules/nearby/views/nearby/nearby_view.dart';
import 'package:restore/modules/search/views/search/search_view.dart';
import 'package:restore/modules/search/views/search_results/search_results_view.dart';
import 'package:restore/modules/trusted_shop/models/trusted_shop_item.dart';
import 'package:restore/modules/trusted_shop/views/shop_detail/shop_detail_view.dart';
import 'package:restore/modules/trusted_shop/views/trusted_shops/trusted_shops_view.dart';
import 'package:restore/modules/wanted_alert/models/wanted_alert_item.dart';
import 'package:restore/modules/wanted_alert/views/wanted_alert_create/wanted_alert_create_view.dart';
import 'package:restore/modules/wanted_alert/views/wanted_alert_detail/wanted_alert_detail_view.dart';
import 'package:restore/modules/wanted_alert/views/wanted_alerts/wanted_alerts_view.dart';
import 'package:restore/services/device_location_service.dart';
import 'package:restore/services/media_picker_service.dart';
import 'package:restore/core/utils/animations/app_page_transitions.dart';
import 'package:restore/modules/shell/views/main_shell.dart';
import 'package:restore/modules/shell/views/desktop_frame.dart';
import '../../modules/ai/bloc/ai_assistant_cubit.dart';
import '../../modules/ai/views/ai_assistant_view.dart';
import '../../modules/auth/bloc/login/login_bloc.dart';
import '../../modules/auth/bloc/register/register_bloc.dart';
import '../../modules/auth/repositories/auth_repository.dart';
import '../../modules/auth/views/login/login_view.dart';
import '../../modules/auth/views/forgot_password_otp/forgot_password_otp_view.dart';
import '../../modules/auth/views/forgot_password/forgot_password_view.dart';
import '../../modules/auth/views/reset_password/reset_password_view.dart';
import '../../modules/auth/views/register/register_view.dart';
import '../../modules/auth/views/auth_success/auth_success_view.dart';
import '../../modules/auth/views/email_verification/email_verification_view.dart';
import '../../modules/auth/views/welcome/welcome_view.dart';
import '../../modules/chat/views/conversation/chat_conversation_view.dart';
import '../../modules/boost/views/boost_listing/boost_listing_view.dart';
import '../../modules/boost/views/promotion_hub/promotion_hub_view.dart';
import '../../modules/insights/views/insights/insights_view.dart';
import '../../modules/shop_posters/views/poster_editor/poster_editor_view.dart';
import '../../modules/shop_posters/views/shop_posters/shop_posters_view.dart';
import '../../modules/auth/bloc/auth/auth_bloc.dart';
import '../../modules/auth/utils/auth_route_guard.dart';
import '../../modules/auth/views/splash/splash_view.dart';
import '../../modules/plans/views/plans/plans_view.dart';
import 'router_refresh_stream.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Navigator của các trang sau khi vào app, nằm trong [DesktopFrame]
/// (web desktop có header + cửa sổ chat nổi; điện thoại giữ nguyên).
final _frameNavigatorKey = GlobalKey<NavigatorState>();

/// Router của app. Chạy lại `redirect` mỗi khi [authBloc] đổi trạng thái,
/// nên mọi chuyển trang theo đăng nhập / đăng xuất / hết phiên nằm ở
/// [authRouteRedirect], các trang không tự `go` sau khi đăng nhập.
/// Repository của luồng đăng tin; app dùng API, test truyền bản mock.
class CreateListingRepositories {
  const CreateListingRepositories({
    this.listings,
    this.categories,
    this.postingQuota,
    this.location,
  });
  final ListingsRepository? listings;
  final CategoryRepository? categories;
  final PostingQuotaRepository? postingQuota;
  final LocationRepository? location;
}

GoRouter createAppRouter(
  AuthBloc authBloc, {
  AiAssistantCubit Function()? assistant,
  CreateListingRepositories createListing = const CreateListingRepositories(),
}) => GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: splashPath,
  refreshListenable: RouterRefreshStream(authBloc.stream),
  // Đường dẫn chưa có trang (VD tính năng chưa làm) thì đưa về trang chủ;
  // bộ chặn đăng nhập sẽ tự chuyển sang /login nếu chưa đăng nhập
  onException: (_, _, router) => router.go('/home'),
  redirect: (_, state) => authRouteRedirect(authBloc.state, state.uri),
  routes: [
    GoRoute(path: splashPath, builder: (_, _) => const SplashView()),
    GoRoute(
      path: '/blog',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, _) => const CommunityContentView(blog: true),
    ),
    GoRoute(
      path: '/support',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, _) => const CommunityContentView(),
    ),
    GoRoute(path: '/welcome', builder: (_, _) => const WelcomeView()),
    GoRoute(
      path: '/login',
      builder: (_, _) => BlocProvider(
        create: (_) => LoginBloc(AuthRepository()),
        child: const LoginView(),
      ),
    ),
    GoRoute(
      path: '/register',
      builder: (_, _) => BlocProvider(
        create: (_) => RegisterBloc(AuthRepository()),
        child: const RegisterView(),
      ),
    ),
    GoRoute(
      path: '/verify-email',
      builder: (_, state) => EmailVerificationView(
        email: state.uri.queryParameters['email'] ?? '',
      ),
    ),
    GoRoute(
      path: '/email-verified',
      builder: (_, _) => const AuthSuccessView(
        title: 'Email đã được xác minh',
        description:
            'Tài khoản ReStore của bạn đã sẵn sàng. Tìm đồ hay, nhắn người bán hoặc đăng tin của riêng bạn.',
        actionLabel: 'Tiếp tục khám phá',
        destination: '/home',
        note: 'Một tài khoản cho cả mua và bán',
        authenticateOnContinue: true,
      ),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (_, _) => const ForgotPasswordView(),
    ),
    GoRoute(
      path: '/forgot-password/otp',
      builder: (_, state) => ForgotPasswordOtpView(
        email: state.uri.queryParameters['email'] ?? '',
      ),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (_, state) => ResetPasswordView(
        resetToken: state.extra is String ? state.extra! as String : '',
      ),
    ),
    GoRoute(
      path: '/password-reset-success',
      builder: (_, _) => const AuthSuccessView(
        title: 'Đã đặt lại mật khẩu',
        description: 'Bạn có thể đăng nhập vào ReStore bằng mật khẩu mới.',
        actionLabel: 'Đăng nhập',
        destination: '/login',
      ),
    ),
    ShellRoute(
      navigatorKey: _frameNavigatorKey,
      builder: (_, state, child) => DesktopFrame(
        location: state.uri.path,
        selectedConversationId: LiveMessagesView.selectedConversation(state.uri),
        listingSearchQuery: state.uri.path == SearchResultsView.path
            ? state.uri.queryParameters['q'] ?? ''
            : null,
        assistant: assistant,
        child: child,
      ),
      routes: [
    // Luồng đăng tin: các bước dùng chung một CreateListingBloc
    ShellRoute(
      builder: (context, state, child) => MultiRepositoryProvider(
        providers: [
          RepositoryProvider(create: (_) => MediaPickerService()),
          RepositoryProvider(create: (_) => DeviceLocationService()),
          RepositoryProvider<LocationRepository>(
            create: (_) => createListing.location ?? ApiLocationRepository(),
          ),
        ],
        child: BlocProvider(
          create: (_) =>
              CreateListingBloc(
                  listingsRepository:
                      createListing.listings ?? ApiListingsRepository(),
                  categoryRepository:
                      createListing.categories ?? ApiCategoryRepository(),
                  postingQuotaRepository:
                      createListing.postingQuota ?? ApiPostingQuotaRepository(),
                )
                ..add(const CategoriesRequested())
                ..add(const PostingQuotaRequested())
                ..add(const DraftsRequested()),
          child: child,
        ),
      ),
      routes: [
        GoRoute(
          path: CreateListingStep.category.path,
          pageBuilder: (_, state) => AppPageTransitions.fadeSlide(
            state: state,
            child: const ChooseCategoryView(),
          ),
        ),
        GoRoute(
          path: CreateListingStep.basicInfo.path,
          pageBuilder: (_, state) => AppPageTransitions.fadeSlide(
            state: state,
            child: const BasicInfoView(),
          ),
        ),
        GoRoute(
          path: CreateListingStep.details.path,
          pageBuilder: (_, state) => AppPageTransitions.fadeSlide(
            state: state,
            child: const ListingDetailsView(),
          ),
        ),
        // Tin nháp: soạn tiếp tin đã lưu (mở từ bước 1 hoặc trang Tài khoản)
        GoRoute(
          path: ListingDraftsView.path,
          pageBuilder: (_, state) => AppPageTransitions.fadeSlide(
            state: state,
            child: const ListingDraftsView(),
          ),
        ),
        // Sửa tin đã đăng: tải tin rồi vào bước 2 (giữ chuyên mục)
        GoRoute(
          path: EditListingView.path,
          pageBuilder: (_, state) => AppPageTransitions.fadeSlide(
            state: state,
            child: EditListingView(listingId: state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: createListingPreviewPath,
          pageBuilder: (_, state) => AppPageTransitions.fadeSlide(
            state: state,
            child: const ListingPreviewView(),
          ),
        ),
      ],
    ),
    StatefulShellRoute.indexedStack(
      // ShellBadgesCubit (số tin chưa đọc) do DesktopFrame cấp
      builder: (_, state, navigationShell) => MainShell(
        navigationShell: navigationShell,
        hideNavigation: LiveMessagesView.selectedConversation(state.uri) != null,
      ),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: '/home', builder: (_, _) => const HomeView())],
        ),
        StatefulShellBranch(
          routes: [
            // ?post=<id>: mở sẵn bình luận của bài (bấm từ thông báo)
            GoRoute(
              path: FeedsView.path,
              builder: (_, state) =>
                  FeedsView(openPostId: state.uri.queryParameters['post']),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: LiveMessagesView.path,
              builder: (_, state) => AppEnvironment.useMockData
                  ? const MessagesView()
                  : LiveMessagesView(
                      conversationId: LiveMessagesView.selectedConversation(state.uri),
                    ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/account', builder: (_, _) => const AccountView()),
          ],
        ),
      ],
    ),
    // Viết bài lên Bảng tin; panel=photos mở sẵn lưới ảnh
    GoRoute(
      path: PostComposerView.path,
      parentNavigatorKey: _frameNavigatorKey,
      pageBuilder: (_, state) => AppPageTransitions.fadeSlide<String>(
        state: state,
        child: PostComposerView(
          openPhotos: state.uri.queryParameters['panel'] == 'photos',
        ),
      ),
    ),
    GoRoute(
      path: '/messages/:id',
      parentNavigatorKey: _frameNavigatorKey,
      builder: (_, state) => AppEnvironment.useMockData
          ? const ChatConversationView()
          : LiveMessagesView(
              key: ValueKey(state.pathParameters['id']),
              conversationId: state.pathParameters['id']!,
            ),
    ),
    GoRoute(
      path: '/messages/:id/offer/:stage',
      parentNavigatorKey: _frameNavigatorKey,
      builder: (_, state) => ChatConversationView(
        stage: switch (state.pathParameters['stage']) {
          'seller-review' => ChatOfferStage.sellerReview,
          'buyer-review' => ChatOfferStage.buyerReview,
          'agreed' => ChatOfferStage.agreed,
          _ => ChatOfferStage.conversation,
        },
      ),
    ),
    GoRoute(
      path: '/ai-assistant',
      parentNavigatorKey: _frameNavigatorKey,
      builder: (_, _) => assistant != null
          ? BlocProvider.value(value: assistant(), child: const AiAssistantView())
          : BlocProvider(
        create: (_) => AiAssistantCubit(),
        child: const AiAssistantView(),
      ),
    ),
    // Chi tiết sản phẩm; extra là ListingModel của thẻ vừa bấm (tuỳ chọn)
    GoRoute(
      path: '/settings',
      parentNavigatorKey: _frameNavigatorKey,
      builder: (_, _) => const LanguageSettingsView(),
    ),
    GoRoute(
      path: MyReviewsView.path,
      parentNavigatorKey: _frameNavigatorKey,
      builder: (_, _) => const MyReviewsView(),
    ),
    GoRoute(
      path: MyReviewsView.ratingsPath,
      parentNavigatorKey: _frameNavigatorKey,
      builder: (_, _) => const MyReviewsView(received: true),
    ),
    GoRoute(
      path: MyReviewsView.transactionsPath,
      parentNavigatorKey: _frameNavigatorKey,
      builder: (_, _) => const MyReviewsView(transactions: true),
    ),
    // Chỉnh sửa hồ sơ, mở từ tab Tài khoản (extra = UserProfileCubit);
    // thiếu extra (VD mở lại từ link) thì về tab Tài khoản
    GoRoute(
      path: EditProfileView.path,
      parentNavigatorKey: _frameNavigatorKey,
      redirect: (_, state) =>
          state.extra is UserProfileCubit ? null : '/account',
        pageBuilder: (_, state) => AppPageTransitions.fadeSlide<bool>(
        state: state,
        child: EditProfileView(cubit: state.extra! as UserProfileCubit),
      ),
    ),
    // Hồ sơ công khai và danh sách theo dõi (?tab=followers|following|shops)
    GoRoute(
      path: '/users/:id',
      parentNavigatorKey: _frameNavigatorKey,
      pageBuilder: (_, state) => AppPageTransitions.fadeSlide(
        state: state,
        child: PublicProfileView(userId: state.pathParameters['id']!, openReviews: state.uri.queryParameters['tab'] == 'reviews'),
      ),
      routes: [
        GoRoute(
          path: 'follows',
          parentNavigatorKey: _frameNavigatorKey,
          pageBuilder: (_, state) => AppPageTransitions.fadeSlide(
            state: state,
            child: FollowListView(
              userId: state.pathParameters['id']!,
              initial: state.uri.queryParameters['tab'] == 'following'
                  ? FollowListKind.following
                  : FollowListKind.followers,
              // me=1: hồ sơ của mình, có thêm tab Shop (tab=shops mở sẵn)
              showShops:
                  state.uri.queryParameters['me'] == '1' ||
                  state.uri.queryParameters['tab'] == 'shops',
              openShops: state.uri.queryParameters['tab'] == 'shops',
            ),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/listings/:id',
      parentNavigatorKey: _frameNavigatorKey,
      pageBuilder: (_, state) => AppPageTransitions.fadeSlide<bool>(
        state: state,
        child: ProductDetailView(
          listingId: state.pathParameters['id']!,
          preview: state.extra is ListingModel
              ? state.extra! as ListingModel
              : null,
        ),
      ),
    ),
    // Tin đăng quanh vị trí người dùng (lối tắt "Gần bạn" ở trang chủ)
    GoRoute(
      path: '/nearby',
      parentNavigatorKey: _frameNavigatorKey,
      pageBuilder: (_, state) =>
          AppPageTransitions.fadeSlide(state: state, child: const NearbyView()),
    ),
    // Tất cả tin Hot sale (tin ưu tiên), mở từ dải danh mục và mục Hot sale
    GoRoute(
      path: HotSaleView.path,
      parentNavigatorKey: _frameNavigatorKey,
      pageBuilder: (_, state) => AppPageTransitions.fadeSlide(
        state: state,
        child: const HotSaleView(),
      ),
    ),
    // Tin đã lưu, mở từ Tài khoản → Đã lưu
    GoRoute(
      path: SavedListingsView.path,
      parentNavigatorKey: _frameNavigatorKey,
      pageBuilder: (_, state) => AppPageTransitions.fadeSlide(
        state: state,
        child: const SavedListingsView(),
      ),
    ),
    // Tin vừa mở xem, mở từ Tài khoản → Xem gần đây
    GoRoute(
      path: SavedListingsView.recentPath,
      parentNavigatorKey: _frameNavigatorKey,
      pageBuilder: (_, state) => AppPageTransitions.fadeSlide(
        state: state,
        child: const SavedListingsView(recent: true),
      ),
    ),
    // Tin của một danh mục; extra là CategoryModel vừa bấm (tuỳ chọn)
    GoRoute(
      path: CategoryDetailView.path,
      parentNavigatorKey: _frameNavigatorKey,
      pageBuilder: (_, state) => AppPageTransitions.fadeSlide(
        state: state,
        child: CategoryDetailView(
          categoryId: state.pathParameters['id']!,
          subcategoryId: state.uri.queryParameters['sub'],
          fromSearch: state.uri.queryParameters['from'] == 'search',
          category: state.extra is CategoryModel
              ? state.extra! as CategoryModel
              : null,
        ),
      ),
    ),
    // Chọn khu vực (Gần bạn, thông báo Báo khi có hàng), trả về AreaPickResult
    GoRoute(
      path: AreaSearchView.path,
      parentNavigatorKey: _frameNavigatorKey,
      pageBuilder: (_, state) => AppPageTransitions.fadeSlide(
        state: state,
        child: AreaSearchView(
          allowNationwide: state.uri.queryParameters['nationwide'] == '1',
        ),
      ),
    ),
    // Tìm kiếm tin; q là từ khoá điền sẵn (tuỳ chọn)
    GoRoute(
      path: '/search',
      parentNavigatorKey: _frameNavigatorKey,
      pageBuilder: (_, state) => AppPageTransitions.fadeSlide(
        state: state,
        child: SearchView(initialQuery: state.uri.queryParameters['q'] ?? ''),
      ),
    ),
    // Kết quả tìm kiếm; from=search khi mở từ trang tìm kiếm
    GoRoute(
      path: SearchResultsView.path,
      parentNavigatorKey: _frameNavigatorKey,
      pageBuilder: (_, state) => AppPageTransitions.fadeSlide(
        state: state,
        child: SearchResultsView(
          query: state.uri.queryParameters['q'] ?? '',
          fromSearch: state.uri.queryParameters['from'] == 'search',
        ),
      ),
    ),
    // Báo khi có hàng: quản lý thông báo của người dùng
    GoRoute(
      path: WantedAlertsView.path,
      parentNavigatorKey: _frameNavigatorKey,
      pageBuilder: (_, state) => AppPageTransitions.fadeSlide(
        state: state,
        child: const WantedAlertsView(),
      ),
    ),
    GoRoute(
      path: PlansView.path,
      parentNavigatorKey: _frameNavigatorKey,
      pageBuilder: (_, state) =>
          AppPageTransitions.fadeSlide(state: state, child: const PlansView()),
    ),
    GoRoute(
      path: CreditWalletView.path,
      parentNavigatorKey: _frameNavigatorKey,
      pageBuilder: (_, state) => AppPageTransitions.fadeSlide(
        state: state,
        child: const CreditWalletView(),
      ),
    ),
    GoRoute(
      path: CreditTopupView.path,
      parentNavigatorKey: _frameNavigatorKey,
      pageBuilder: (_, state) => AppPageTransitions.fadeSlide(
        state: state,
        child: CreditTopupView(
          preselectId: state.uri.queryParameters['package'],
          need: int.tryParse(state.uri.queryParameters['need'] ?? ''),
        ),
      ),
    ),
    GoRoute(
      path: CreditBonusView.path,
      parentNavigatorKey: _frameNavigatorKey,
      pageBuilder: (_, state) => AppPageTransitions.fadeSlide(
        state: state,
        child: const CreditBonusView(),
      ),
    ),
    GoRoute(
      path: CreditHistoryView.path,
      parentNavigatorKey: _frameNavigatorKey,
      pageBuilder: (_, state) => AppPageTransitions.fadeSlide(
        state: state,
        child: const CreditHistoryView(),
      ),
    ),
    // Thông báo trong app (chuông ở trang chủ)
    GoRoute(
      path: NotificationsView.path,
      parentNavigatorKey: _frameNavigatorKey,
      pageBuilder: (_, state) => AppPageTransitions.fadeSlide(
        state: state,
        child: const NotificationsView(),
      ),
    ),
    // Tạo thông báo; q là món cần tìm điền sẵn, from=alerts khi mở từ trang
    // quản lý (tạo xong thì trả về WantedAlertItem)
    GoRoute(
      path: WantedAlertCreateView.path,
      parentNavigatorKey: _frameNavigatorKey,
      pageBuilder: (_, state) => AppPageTransitions.fadeSlide(
        state: state,
        child: WantedAlertCreateView(
          initialKeywords: state.uri.queryParameters['q'] ?? '',
          fromAlerts: state.uri.queryParameters['from'] == 'alerts',
        ),
      ),
    ),
    // Tin đã khớp một thông báo; extra là WantedAlertItem vừa bấm (tuỳ chọn)
    GoRoute(
      path: WantedAlertDetailView.path,
      parentNavigatorKey: _frameNavigatorKey,
      pageBuilder: (_, state) => AppPageTransitions.fadeSlide<bool>(
        state: state,
        child: WantedAlertDetailView(
          alertId: state.pathParameters['id']!,
          alert: state.extra is WantedAlertItem
              ? state.extra! as WantedAlertItem
              : null,
        ),
      ),
    ),
    // Shop uy tín: shop đã xác minh và sản phẩm của các shop đó
    GoRoute(
      path: TrustedShopsView.path,
      parentNavigatorKey: _frameNavigatorKey,
      pageBuilder: (_, state) => AppPageTransitions.fadeSlide(
        state: state,
        // ?shop=<id>: mở trang rồi vào thẳng shop đó (VD bấm banner trang chủ)
        child: TrustedShopsView(openShopId: state.uri.queryParameters['shop']),
      ),
    ),
    // Trang của một shop; extra là TrustedShopItem vừa bấm (tuỳ chọn),
    // đóng trang trả về trạng thái theo dõi mới nếu đã đổi
    GoRoute(
      path: ShopDetailView.path,
      parentNavigatorKey: _frameNavigatorKey,
      pageBuilder: (_, state) => AppPageTransitions.fadeSlide<bool>(
        state: state,
        child: ShopDetailView(
          catalog: state.uri.queryParameters['catalog'] == '1',
          shopId: state.pathParameters['id']!,
          shop: state.extra is TrustedShopItem
              ? state.extra! as TrustedShopItem
              : null,
        ),
      ),
    ),
    // Quản lý poster shop (nút Shop poster ở menu xoè, gói Cửa hàng)
    GoRoute(
      path: ShopPostersView.path,
      parentNavigatorKey: _frameNavigatorKey,
      pageBuilder: (_, state) => AppPageTransitions.fadeSlide(
        state: state,
        child: const ShopPostersView(),
      ),
    ),
    // Tạo / sửa poster; thiếu extra (VD mở lại từ link) thì về trang quản lý
    GoRoute(
      path: PosterEditorView.path,
      parentNavigatorKey: _frameNavigatorKey,
      redirect: (_, state) =>
          state.extra is PosterEditorArgs ? null : ShopPostersView.path,
      pageBuilder: (_, state) => AppPageTransitions.fadeSlide<bool>(
        state: state,
        child: PosterEditorView(args: state.extra! as PosterEditorArgs),
      ),
    ),
    // Quản lý shop (nút Quản lý shop ở menu xoè của gói Cửa hàng)
    GoRoute(
      path: MyShopView.path,
      parentNavigatorKey: _frameNavigatorKey,
      pageBuilder: (_, state) =>
          AppPageTransitions.fadeSlide(state: state, child: const MyShopView()),
    ),
    // Người theo dõi shop của mình (ô Người theo dõi ở Quản lý shop)
    GoRoute(
      path: ShopFollowersView.path,
      parentNavigatorKey: _frameNavigatorKey,
      pageBuilder: (_, state) => AppPageTransitions.fadeSlide(
        state: state,
        child: const ShopFollowersView(),
      ),
    ),
    // Trang Đang theo dõi (lối tắt ở trang chủ)
    GoRoute(
      path: FollowingHubView.path,
      parentNavigatorKey: _frameNavigatorKey,
      pageBuilder: (_, state) => AppPageTransitions.fadeSlide(
        state: state,
        child: const FollowingHubView(),
      ),
    ),
    // Shop uy tín đang theo dõi và tin mới của họ
    GoRoute(
      path: FollowingShopsView.path,
      parentNavigatorKey: _frameNavigatorKey,
      pageBuilder: (_, state) => AppPageTransitions.fadeSlide(
        state: state,
        child: const FollowingShopsView(),
      ),
    ),
    // Thống kê của người bán (nút Thống kê ở menu xoè)
    GoRoute(
      path: InsightsView.path,
      parentNavigatorKey: _frameNavigatorKey,
      pageBuilder: (_, state) => AppPageTransitions.fadeSlide(
        state: state,
        child: const InsightsView(),
      ),
    ),
    // Trang Boost của tôi: tin đang quảng bá, sắp hết hạn, chưa quảng bá
    GoRoute(
      path: PromotionHubView.path,
      parentNavigatorKey: _frameNavigatorKey,
      pageBuilder: (_, state) => AppPageTransitions.fadeSlide(
        state: state,
        child: const PromotionHubView(),
      ),
    ),
    // Quảng bá một tin của tôi: đẩy tin 24 giờ, Hot sale 1/3/7 ngày bằng xu.
    // Đóng trang trả về true khi đã đẩy / mua.
    GoRoute(
      path: BoostListingView.path,
      parentNavigatorKey: _frameNavigatorKey,
      pageBuilder: (_, state) => AppPageTransitions.fadeSlide<bool>(
        state: state,
        child: BoostListingView(listingId: state.pathParameters['id']!),
      ),
    ),
      ],
    ),
  ],
);
