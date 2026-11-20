import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/shell/widgets/shell_ai_bubble.dart';
import 'package:restore/modules/shell/widgets/shell_bottom_nav.dart';
import 'package:restore/shared/widgets/glass/app_pinned_header_surface.dart';

Widget _app(Widget child) => MaterialApp(
  locale: const Locale('vi'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: child,
);

void main() {
  testWidgets('bong bóng AI chỉ nhấp nháy vài nhịp rồi đứng yên', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(Scaffold(body: ShellAiBubble(onTap: () {}))),
    );
    // Lặp mãi thì pumpAndSettle sẽ báo hết giờ
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets(
    'thanh điều hướng và đầu trang ghim dùng chung một nhóm blur, nút giữa không blur lại',
    (tester) async {
      await tester.pumpWidget(
        _app(
          BackdropGroup(
            child: Scaffold(
              extendBody: true,
              body: const Column(
                children: [
                  SizedBox(
                    height: 60,
                    child: AppPinnedHeaderSurface(
                      pinned: true,
                      child: SizedBox.expand(),
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: ShellBottomNav(
                selectedIndex: 0,
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final filters = tester
          .renderObjectList<RenderBackdropFilter>(find.byType(BackdropFilter))
          .where((filter) => filter.enabled)
          .toList();
      // Chỉ còn mặt kính thanh điều hướng + đầu trang ghim (nút giữa đã tắt)
      expect(filters, hasLength(2));
      final key = filters.first.backdropKey;
      expect(key, isNotNull);
      expect(filters.every((filter) => filter.backdropKey == key), isTrue);
      expect(filters.first.filter, filters.last.filter);
    },
  );
}
