import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../modules/account/bloc/account_ui_cubit.dart';
import '../../modules/account/views/account_detail_views.dart';
import '../../modules/account/views/account_view.dart';
import '../../modules/account/views/seller_trust_views.dart';
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
import '../../modules/chat/views/messages_view.dart';
import '../../modules/boost/bloc/boost_listing_cubit.dart';
import '../../modules/boost/views/boost_listing_view.dart';
import '../../modules/home/views/home_view.dart';
import '../../modules/listings/presentation/views/create_listing_view.dart';
import '../../modules/listings/presentation/views/manage_listings_view.dart';
import '../../modules/listings/presentation/views/product_detail_view.dart';
import '../../modules/listings/presentation/views/search_view.dart';
import '../../modules/listings/presentation/bloc/listing_form_cubit.dart';
import '../../modules/listings/presentation/bloc/manage_listings_cubit.dart';
import '../../modules/shell/views/main_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/welcome',
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
      builder: (_, _) => const ResetPasswordView(),
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
    StatefulShellRoute.indexedStack(
      builder: (_, _, navigationShell) =>
          MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/home', builder: (_, _) => const HomeView()),
            GoRoute(path: '/search', builder: (_, _) => const SearchView()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/manage-listings',
              builder: (_, _) => BlocProvider(
                create: (_) => ManageListingsCubit(),
                child: const ManageListingsView(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/create-listing',
              builder: (_, _) => BlocProvider(
                create: (_) => ListingFormCubit(editing: false),
                child: const CreateListingView(),
              ),
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
      path: '/listings/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) =>
          ProductDetailView(listingId: state.pathParameters['id']!),
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
      path: '/create-listing/preview',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) => ProductDetailView(
        listingId: 'camera',
        isPreview: true,
        previewSource: state.uri.queryParameters['source'] ?? 'create',
      ),
    ),
    GoRoute(
      path: '/edit-listing',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, _) => BlocProvider(
        create: (_) => ListingFormCubit(editing: true),
        child: const CreateListingView(),
      ),
    ),
    GoRoute(
      path: '/edit-listing/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, _) => BlocProvider(
        create: (_) => ListingFormCubit(editing: true),
        child: const CreateListingView(),
      ),
    ),
    GoRoute(
      path: '/account/edit',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, _) => BlocProvider(
        create: (_) => EditProfileCubit(),
        child: const EditProfileView(),
      ),
    ),
    GoRoute(
      path: '/settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, _) => BlocProvider(
        create: (_) => SettingsCubit(),
        child: const SettingsView(),
      ),
    ),
    GoRoute(
      path: '/favorites',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, _) => const FavoritesView(),
    ),
    GoRoute(
      path: '/notifications',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, _) => const NotificationsView(),
    ),
    GoRoute(
      path: '/seller/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, _) => const SellerProfileView(),
    ),
    GoRoute(
      path: '/seller/:id/reviews',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, _) => const RatingsView(),
    ),
    GoRoute(
      path: '/seller/:id/review',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, _) => BlocProvider(
        create: (_) => ReviewCubit(),
        child: const LeaveReviewView(),
      ),
    ),
    GoRoute(
      path: '/report/listing/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, _) => BlocProvider(
        create: (_) => ReportCubit(),
        child: const ReportView(target: ReportTarget.listing),
      ),
    ),
    GoRoute(
      path: '/report/user/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, _) => BlocProvider(
        create: (_) => ReportCubit(),
        child: const ReportView(target: ReportTarget.user),
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
