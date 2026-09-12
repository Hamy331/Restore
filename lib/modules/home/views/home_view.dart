import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/blocs/language/language_bloc.dart';
import '../../../core/blocs/language/language_event.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final currentLang = context.watch<LanguageBloc>().state.locale.languageCode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ (Test)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: 'Đổi ngôn ngữ',
            onPressed: () {
              final newLocale = currentLang == 'en'
                  ? const Locale('vi')
                  : const Locale('en');
              context.read<LanguageBloc>().add(ChangeLanguage(newLocale));
            },
          ),

          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () {
              context.read<AuthBloc>().add(LoggedOut());
              context.go('/login');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Chào mừng bạn đến với ReStore!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Ngôn ngữ hiện tại đang là: ${currentLang.toUpperCase()}',
              style: const TextStyle(fontSize: 16, color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }
}
