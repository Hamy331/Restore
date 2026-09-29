import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../modules/admin/presentation/admin_workspace.dart';
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
import '../../modules/home/views/home_view.dart';
import '../../modules/listings/presentation/views/create_listing_view.dart';
import '../../modules/listings/presentation/views/manage_listings_view.dart';
import '../../modules/listings/presentation/views/product_detail_view.dart';
import '../../modules/listings/presentation/views/search_view.dart';
import '../../modules/shell/views/foundation_placeholder_view.dart';
import '../../modules/shell/views/main_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/welcome',
  routes: [
    if (kDebugMode || const bool.fromEnvironment('ENABLE_ADMIN_PREVIEW'))
      GoRoute(
        path: '/admin-preview',
        builder: (context, _) =>
            AdminWorkspace(onExit: () => context.go('/welcome')),
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
              builder: (_, _) => const ManageListingsView(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/create-listing',
              builder: (_, _) => const CreateListingView(),
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
            GoRoute(
              path: '/account',
              builder: (_, _) => const FoundationPlaceholderView(
                title: 'Tài khoản',
                message:
                    'Thông tin hồ sơ và cài đặt sẽ được triển khai ở giai đoạn tính năng.',
                icon: Icons.person_outline,
              ),
            ),
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
      builder: (_, _) =>
          const ProductDetailView(listingId: 'camera', isPreview: true),
    ),
    GoRoute(
      path: '/edit-listing',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, _) => const CreateListingView(editing: true),
    ),
  ],
);
