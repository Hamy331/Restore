import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/ui/layouts/t_foundation_placeholder_layout.dart';
import 'package:restore/modules/account/views/account_view.dart';
import 'package:restore/modules/chat/views/messages_view.dart';
import 'package:restore/modules/home/views/home/home_view.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/modules/listings/bloc/create_listing/create_listing_bloc.dart';
import 'package:restore/modules/listings/bloc/create_listing/create_listing_event.dart';
import 'package:restore/modules/listings/repositories/category_repository.dart';
import 'package:restore/modules/listings/models/create_listing_step.dart';
import 'package:restore/modules/listings/repositories/listings_repository.dart';
import 'package:restore/modules/listings/views/basic_info/basic_info_view.dart';
import 'package:restore/modules/listings/views/choose_category/choose_category_view.dart';
import 'package:restore/modules/listings/views/listing_details/listing_details_view.dart';
import 'package:restore/modules/listings/views/listing_preview/listing_preview_view.dart';
import 'package:restore/modules/listings/views/product_detail/product_detail_view.dart';
import 'package:restore/data/models/listing_model.dart';
import 'package:restore/modules/location/repositories/location_repository.dart';
import 'package:restore/modules/location/views/area_search/area_search_view.dart';
import 'package:restore/modules/category_detail/views/category_detail/category_detail_view.dart';
import 'package:restore/data/models/category_model.dart';
import 'package:restore/modules/nearby/views/nearby/nearby_view.dart';
import 'package:restore/modules/search/views/search/search_view.dart';
import 'package:restore/modules/search/views/search_results/search_results_view.dart';
import 'package:restore/modules/wanted_alert/models/wanted_alert_item.dart';
import 'package:restore/modules/wanted_alert/views/wanted_alert_create/wanted_alert_create_view.dart';
import 'package:restore/modules/wanted_alert/views/wanted_alert_detail/wanted_alert_detail_view.dart';
import 'package:restore/modules/wanted_alert/views/wanted_alerts/wanted_alerts_view.dart';
import 'package:restore/services/device_location_service.dart';
import 'package:restore/services/media_picker_service.dart';
import 'package:restore/core/utils/animations/app_page_transitions.dart';
import 'package:restore/modules/shell/views/main_shell.dart';
import 'package:restore/modules/shell/bloc/shell_badges_cubit.dart';
import 'package:restore/modules/chat/repositories/chat_repository.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import '../../modules/ai/bloc/ai_assistant_cubit.dart';
import '../../modules/ai/views/ai_assistant_view.dart';
import '../../modules/auth/bloc/login/login_bloc.dart';
import '../../modules/auth/bloc/register/register_bloc.dart';
import '../../modules/auth/repositories/auth_repository.dart';
import '../../modules/auth/views/login/login_view.dart';
import '../../modules/auth/views/recovery/forgot_password_otp_view.dart';
import '../../modules/auth/views/recovery/forgot_password_view.dart';
import '../../modules/auth/views/recovery/reset_password_view.dart';
import '../../modules/auth/views/register/register_view.dart';
import '../../modules/auth/views/verification/auth_success_view.dart';
import '../../modules/auth/views/verification/email_verification_view.dart';
import '../../modules/auth/views/welcome/welcome_view.dart';
import '../../modules/chat/views/chat_conversation_view.dart';
import '../../modules/boost/bloc/boost_listing_cubit.dart';
import '../../modules/boost/views/boost_listing_view.dart';
import '../../modules/auth/bloc/auth_bloc.dart';
import '../../modules/auth/auth_route_guard.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/welcome',
  // Đường dẫn chưa có trang (VD tính năng chưa làm) thì đưa về trang chủ;
  // bộ chặn đăng nhập sẽ tự chuyển sang /login nếu chưa đăng nhập
  onException: (_, _, router) => router.go('/home'),
  redirect: (context, state) {
    final authState = context.read<AuthBloc>().state;
    return authRouteRedirect(authState, state.uri.path);
  },
  routes: [
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
    // Luồng đăng tin: các bước dùng chung một CreateListingBloc
    ShellRoute(
      builder: (context, state, child) => MultiRepositoryProvider(
        providers: [
          RepositoryProvider(create: (_) => MediaPickerService()),
          RepositoryProvider(create: (_) => DeviceLocationService()),
          RepositoryProvider<LocationRepository>(
            create: (_) => AppEnvironment.useMockData
                ? MockLocationRepository()
                : ApiLocationRepository(),
          ),
        ],
        child: BlocProvider(
          create: (_) => CreateListingBloc(
            listingsRepository: AppEnvironment.useMockData
                ? MockListingsRepository()
                : ApiListingsRepository(),
            categoryRepository: AppEnvironment.useMockData
                ? MockCategoryRepository()
                : ApiCategoryRepository(),
          )..add(const CategoriesRequested()),
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
      builder: (_, _, navigationShell) => BlocProvider(
        create: (_) => ShellBadgesCubit(
          chatRepository: AppEnvironment.useMockData
              ? MockChatRepository()
              : ApiChatRepository(),
        )..refresh(),
        child: MainShell(navigationShell: navigationShell),
      ),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: '/home', builder: (_, _) => const HomeView())],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/feeds',
              builder: (context, _) {
                final l10n = AppLocalizations.of(context)!;
                return TFoundationPlaceholderLayout(
                  title: l10n.feedsTitle,
                  message: l10n.feedsComingSoon,
                  icon: AppIcons.feeds,
                );
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/messages', builder: (_, _) => const MessagesView()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/account', builder: (_, _) => const AccountView()),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/messages/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, _) => const ChatConversationView(),
    ),
    GoRoute(
      path: '/messages/:id/offer/:stage',
      parentNavigatorKey: _rootNavigatorKey,
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
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, _) => BlocProvider(
        create: (_) => AiAssistantCubit(),
        child: const AiAssistantView(),
      ),
    ),
    // Chi tiết sản phẩm; extra là ListingModel của thẻ vừa bấm (tuỳ chọn)
    GoRoute(
      path: '/listings/:id',
      parentNavigatorKey: _rootNavigatorKey,
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
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (_, state) =>
          AppPageTransitions.fadeSlide(state: state, child: const NearbyView()),
    ),
    // Tin của một danh mục; extra là CategoryModel vừa bấm (tuỳ chọn)
    GoRoute(
      path: CategoryDetailView.path,
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (_, state) => AppPageTransitions.fadeSlide(
        state: state,
        child: CategoryDetailView(
          categoryId: state.pathParameters['id']!,
          category: state.extra is CategoryModel
              ? state.extra! as CategoryModel
              : null,
        ),
      ),
    ),
    // Chọn khu vực (Gần bạn, thông báo Báo khi có hàng), trả về AreaPickResult
    GoRoute(
      path: AreaSearchView.path,
      parentNavigatorKey: _rootNavigatorKey,
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
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (_, state) => AppPageTransitions.fadeSlide(
        state: state,
        child: SearchView(initialQuery: state.uri.queryParameters['q'] ?? ''),
      ),
    ),
    // Kết quả tìm kiếm; from=search khi mở từ trang tìm kiếm
    GoRoute(
      path: SearchResultsView.path,
      parentNavigatorKey: _rootNavigatorKey,
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
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (_, state) => AppPageTransitions.fadeSlide(
        state: state,
        child: const WantedAlertsView(),
      ),
    ),
    // Tạo thông báo; q là món cần tìm điền sẵn, from=alerts khi mở từ trang
    // quản lý (tạo xong thì trả về WantedAlertItem)
    GoRoute(
      path: WantedAlertCreateView.path,
      parentNavigatorKey: _rootNavigatorKey,
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
      parentNavigatorKey: _rootNavigatorKey,
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
    GoRoute(
      path: '/boost/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, _) => BlocProvider(
        create: (_) => BoostListingCubit(),
        child: const BoostListingView(),
      ),
    ),
  ],
);
