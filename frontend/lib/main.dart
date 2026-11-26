import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:device_preview/device_preview.dart';
import 'core/blocs/language/language_bloc.dart';
import 'core/blocs/language/language_state.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'core/theme/theme.dart';
import 'core/routes/app_router.dart';
import 'modules/auth/bloc/auth/auth_bloc.dart';
import 'modules/auth/bloc/auth/auth_state.dart';
import 'modules/ai/bloc/ai_assistant_cubit.dart';
import 'modules/auth/bloc/auth/auth_event.dart';
import 'modules/auth/repositories/auth_repository.dart';
import 'modules/chat/widgets/presence_reporter.dart';
import 'modules/location/bloc/user_area/user_area_cubit.dart';
import 'modules/location/repositories/location_repository.dart';
import 'modules/notifications/bloc/notification_badge/notification_badge_cubit.dart';
import 'modules/notifications/repositories/notification_repository.dart';
import 'modules/notifications/services/push_messaging_service.dart';
import 'modules/notifications/views/notifications/notifications_view.dart';
import 'modules/notifications/widgets/push_notification_listener.dart';
import 'core/config/app_environment.dart';
import 'core/network/api_client.dart';
import 'shared/utils/image_cache/app_image_disk_cache.dart';
import 'shared/widgets/app_system_nav_bar_guard.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Xong khi Firebase khởi tạo (hoặc bỏ qua vì lỗi); push FCM chờ cái này
late final Future<void> _firebaseReady;

bool get _isWebOrDesktop =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.windows ||
    defaultTargetPlatform == TargetPlatform.macOS ||
    defaultTargetPlatform == TargetPlatform.linux;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // URL sạch kiểu domain/home thay vì domain/#/home (chỉ có tác dụng trên web)
  usePathUrlStrategy();
  // App mở trang bằng context.push; mặc định go_router không đổi URL khi push
  GoRouter.optionURLReflectsImperativeAPIs = true;

  runApp(
    DevicePreview(
      enabled: !kReleaseMode && _isWebOrDesktop,
      builder: (context) => const MyApp(),
    ),
  );

  _firebaseReady = _initializeFirebase();

  // Dọn cache ảnh trên đĩa sau khi app đã hiện, không tranh tài nguyên với
  // khung hình đầu
  Future<void>.delayed(
    const Duration(seconds: 5),
    AppImageDiskCache.instance.prune,
  );
}

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 8));
  } catch (error) {
    debugPrint('Firebase initialization skipped: $error');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthBloc _authBloc = AuthBloc(
    AuthRepository(),
    sessionExpired: ApiClient().sessionExpired,
  )..add(const AuthCheckRequested());
  AiAssistantCubit? _assistant;
  String? _assistantOwner;
  late final StreamSubscription<AuthState> _authChanges;
  late final GoRouter _router = createAppRouter(_authBloc, assistant: _openAssistant);
  final NotificationRepository _notificationRepository =
      NotificationsView.createRepository();
  late final PushMessagingService _push = PushMessagingService(
    repository: _notificationRepository,
    firebaseReady: _firebaseReady,
  );

  @override
  void initState() {
    super.initState();
    _authChanges = _authBloc.stream.listen(_syncAssistantOwner);
  }

  void _syncAssistantOwner(AuthState state) {
    final owner = state is AuthAuthenticated ? state.user.id : null;
    if (_assistantOwner == owner) return;
    _assistant?.close();
    _assistant = null;
    _assistantOwner = owner;
  }

  AiAssistantCubit _openAssistant() {
    _syncAssistantOwner(_authBloc.state);
    if (_assistant != null) return _assistant!;
    final assistant = AiAssistantCubit();
    _assistant = assistant;
    if (_assistantOwner != null) unawaited(assistant.restoreLatest());
    return assistant;
  }

  @override
  void dispose() {
    _push.dispose();
    _authChanges.cancel();
    _assistant?.close();
    _router.dispose();
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _notificationRepository),
        RepositoryProvider.value(value: _push),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _authBloc),
          BlocProvider(create: (context) => LanguageBloc()),
          // Mở app là xin quyền vị trí để hiện tỉnh/thành của người dùng
          BlocProvider(
            lazy: false,
            create: (context) => UserAreaCubit(
              locationRepository: AppEnvironment.useMockData
                  ? MockLocationRepository()
                  : ApiLocationRepository(),
            )..locate(),
          ),
          // Số thông báo chưa đọc (chuông ở trang chủ)
          BlocProvider(
            create: (context) =>
                NotificationBadgeCubit(repository: _notificationRepository),
          ),
        ],
        child: BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) =>
              previous.runtimeType != current.runtimeType,
          listener: (context, state) {
            final badge = context.read<NotificationBadgeCubit>();
            if (state is AuthAuthenticated && !state.isAdmin) {
              badge.refresh();
              unawaited(_push.start());
            } else {
              badge.clear();
              unawaited(_push.stop());
            }
          },
          child: PushNotificationListener(
            router: _router,
            child: PresenceReporter(
              child: ScreenUtilInit(
                designSize: const Size(375, 812),
                minTextAdapt: true,
                splitScreenMode: false,
                builder: (context, child) {
                  return BlocBuilder<LanguageBloc, LanguageState>(
                    builder: (context, languageState) {
                      return MaterialApp.router(
                        debugShowCheckedModeBanner: false,
                        locale: languageState.locale,
                        localizationsDelegates: const [
                          AppLocalizations.delegate,
                          GlobalMaterialLocalizations.delegate,
                          GlobalWidgetsLocalizations.delegate,
                          GlobalCupertinoLocalizations.delegate,
                        ],
                        supportedLocales: const [Locale('en'), Locale('vi')],
                        theme: AppTheme.lightTheme,
                        routerConfig: _router,
                        // Máy Android thanh 3 nút: chừa dải trắng ở đáy để
                        // thanh không che nội dung cuối trang
                        builder: (context, child) =>
                            AppSystemNavBarGuard(child: child!),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
