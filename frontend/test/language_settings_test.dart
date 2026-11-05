import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:restore/core/blocs/language/language_bloc.dart';
import 'package:restore/core/blocs/language/language_state.dart';
import 'package:restore/modules/account/views/language_settings/language_settings_view.dart';
import 'feeds_test.dart' show host;

void main() {
  testWidgets('settings switches both locales and restores persisted choice', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final bloc = LanguageBloc();
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: BlocBuilder<LanguageBloc, LanguageState>(
          builder: (_, state) =>
              host(state.locale, const LanguageSettingsView()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếng Việt'));
    await tester.pumpAndSettle();
    expect(find.text('Cài đặt'), findsOneWidget);
    expect(
      (await SharedPreferences.getInstance()).getString('app_language'),
      'vi',
    );
    final restored = LanguageBloc();
    await tester.pumpAndSettle();
    expect(restored.state.locale.languageCode, 'vi');
    await tester.runAsync(restored.close);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(
      (await SharedPreferences.getInstance()).getString('app_language'),
      'en',
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(bloc.close);
  });
}
