import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/ui/layouts/t_foundation_placeholder_layout.dart';
import 'package:restore/modules/account/views/account_view.dart';
import 'package:restore/modules/chat/views/messages_view.dart';
import 'package:restore/modules/home/views/home_view.dart';
import 'package:restore/modules/listings/bloc/create_listing/create_listing_bloc.dart';
import 'package:restore/modules/listings/views/choose_category/choose_category_view.dart';
import 'package:restore/modules/listings/views/upload_photos/upload_photos_view.dart';
import 'package:restore/modules/shell/views/main_shell.dart';
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
    ShellRoute(
      builder: (context, state, child) =>
          BlocProvider(create: (_) => CreateListingBloc(), child: child),
      routes: [
        GoRoute(
          path: '/create-listing/choose-category',
          builder: (_, _) => const ChooseCategoryView(),
        ),
        GoRoute(
          path: '/create-listing/upload-photos',
          builder: (_, _) => const UploadPhotosView(),
        ),
      ],
    ),
    StatefulShellRoute.indexedStack(
      builder: (_, _, navigationShell) =>
          MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: '/home', builder: (_, _) => const HomeView())],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/manage-listings',
              builder: (_, _) => const TFoundationPlaceholderLayout(
                title: 'Quản lý tin',
                message: 'Tính năng đang được phát triển',
                icon: Icons.inventory_2_outlined,
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
