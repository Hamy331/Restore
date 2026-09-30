import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:device_preview/device_preview.dart';
import 'core/blocs/language/language_bloc.dart';
import 'core/blocs/language/language_state.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'core/theme/theme.dart';
import 'core/routes/app_router.dart';
import 'modules/auth/bloc/auth_bloc.dart';
import 'modules/auth/bloc/auth_event.dart';
import 'modules/auth/bloc/auth_state.dart';
import 'modules/auth/repositories/auth_repository.dart';
import 'modules/auth/auth_route_guard.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    DevicePreview(enabled: !kReleaseMode, builder: (context) => const MyApp()),
  );

  unawaited(_initializeFirebase());
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthBloc(AuthRepository())..add(AppStarted()),
        ),
        BlocProvider(create: (context) => LanguageBloc()),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          final path = appRouter.routeInformationProvider.value.uri.path;
          if (state is AuthAuthenticated && isPublicAuthPath(path)) {
            appRouter.go('/home');
          } else if (state is AuthUnauthenticated && !isPublicRoute(path)) {
            appRouter.go('/welcome');
          }
        },
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
                  routerConfig: appRouter,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
