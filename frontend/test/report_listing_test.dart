import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/content/repositories/report_repository.dart';
import 'package:restore/modules/content/views/report_listing_sheet.dart';

const customReason = ListingReportReason(
  code: 'CUSTOM_REASON',
  labelVi: 'Lý do mới từ máy chủ',
  labelEn: 'Custom server reason',
  requiresDescription: false,
);
const detailsReason = ListingReportReason(
  code: 'CUSTOM_DETAILS',
  labelVi: 'Cần mô tả từ cấu hình',
  labelEn: 'Configured details required',
  requiresDescription: true,
);

class PendingReports extends ReportRepository {
  PendingReports({this.reasons = const [customReason, detailsReason]});
  final List<ListingReportReason> reasons;
  bool failReasons = false;
  @override
  Future<List<ListingReportReason>> getReasons() async {
    if (failReasons) throw StateError('Unavailable');
    return reasons;
  }

  final pending = Completer<void>();
  int calls = 0;
  @override
  Future<void> submitListing({
    required String listingId,
    required ListingReportReason reason,
    required String phone,
    required String email,
  }) {
    calls++;
    return pending.future;
  }
}

Future<void> openForm(
  WidgetTester tester,
  ReportRepository repository, {
  Size size = const Size(390, 844),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showModalBottomSheet<bool>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              isDismissible: false,
              enableDrag: false,
              builder: (_) => ReportListingSheet(
                listingId: 'listing-1',
                initialEmail: 'buyer@example.com',
                initialPhone: '0912345678',
                repository: repository,
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'catalog failure blocks submission and retry loads server-defined reasons',
    (tester) async {
      final repository = PendingReports()..failReasons = true;
      await openForm(tester, repository);
      expect(
        find.byKey(const ValueKey('report-reason-CUSTOM_REASON')),
        findsNothing,
      );
      repository.failReasons = false;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.text('Lý do mới từ máy chủ'), findsOneWidget);
      expect(repository.calls, 0);
    },
  );

  test(
    'report reasons are read from API metadata without an enum fallback',
    () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            expect(request.path, '/content/reports/reasons');
            handler.resolve(
              Response(
                requestOptions: request,
                data: {
                  'data': {
                    'items': [
                      {
                        'code': 'ADDED_BY_ADMIN',
                        'labelVi': 'Từ database',
                        'labelEn': 'From database',
                        'requiresDescription': true,
                        'guidanceVi': 'Gợi ý mới',
                      },
                    ],
                  },
                },
              ),
            );
          },
        ),
      );
      final reasons = await ReportRepository(dio: dio).getReasons();
      expect(reasons.single.code, 'ADDED_BY_ADMIN');
      expect(reasons.single.requiresDescription, isTrue);
      expect(reasons.single.label('vi'), 'Từ database');
      expect(reasons.single.guidance('vi'), 'Gợi ý mới');
    },
  );

  testWidgets('short screen keeps the submit action above the keyboard', (
    tester,
  ) async {
    final reasons = List.generate(
      8,
      (index) => ListingReportReason(
        code: 'CHOICE_$index',
        labelVi: 'Lý do báo cáo thứ $index',
        labelEn: 'Report reason $index',
        requiresDescription: false,
      ),
    );
    await openForm(
      tester,
      PendingReports(reasons: reasons),
      size: const Size(390, 700),
    );
    for (final reason in reasons) {
      expect(
        find.byKey(ValueKey('report-reason-${reason.code}')).hitTestable(),
        findsOneWidget,
      );
    }
    expect(
      find.byKey(const ValueKey('report-phone')).hitTestable(),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('report-email')).hitTestable(),
      findsOneWidget,
    );
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    final submit = find.byKey(const ValueKey('report-submit'));
    expect(tester.getRect(submit).bottom, lessThanOrEqualTo(420));
    expect(tester.takeException(), isNull);
  });

  test(
    'report repository sends structured reason and separate contacts',
    () async {
      final dio = Dio();
      Map? submitted;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            expect(request.path, '/content/reports');
            submitted = request.data as Map;
            handler.resolve(Response(requestOptions: request, statusCode: 200));
          },
        ),
      );
      await ReportRepository(dio: dio).submitListing(
        listingId: 'listing-1',
        reason: customReason,
        phone: ' 0912345678 ',
        email: ' buyer@example.com ',
      );
      expect(submitted, {
        'targetType': 'LISTING',
        'targetId': 'listing-1',
        'reasonCode': 'CUSTOM_REASON',
        'evidence': '',
        'contactPhone': '0912345678',
        'contactEmail': 'buyer@example.com',
      });
    },
  );

  testWidgets(
    'reason is required and selecting a reason never adds a description field',
    (tester) async {
      final repository = PendingReports();
      await openForm(tester, repository);
      await tester.tap(find.byKey(const ValueKey('report-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Vui lòng chọn một lý do báo cáo.'), findsOneWidget);
      expect(repository.calls, 0);
      final other = find.byKey(const ValueKey('report-reason-CUSTOM_DETAILS'));
      await tester.ensureVisible(other);
      await tester.tap(other);
      await tester.tap(find.byKey(const ValueKey('report-submit')));
      await tester.pump();
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(repository.calls, 1);
      repository.pending.complete();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'pending submission cannot be sent twice and success closes sheet',
    (tester) async {
      final repository = PendingReports();
      await openForm(tester, repository);
      await tester.tap(
        find.byKey(const ValueKey('report-reason-CUSTOM_REASON')),
      );
      final submit = find.byKey(const ValueKey('report-submit'));
      await tester.tap(submit);
      await tester.pump();
      await tester.tap(submit);
      expect(repository.calls, 1);
      final button = find.descendant(
        of: submit,
        matching: find.byType(FilledButton),
      );
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      repository.pending.complete();
      await tester.pumpAndSettle();
      expect(find.byType(ReportListingSheet), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'network errors retain entries and close dismisses immediately without confirmation',
    (tester) async {
      final repository = PendingReports();
      await openForm(tester, repository, size: const Size(320, 568));
      await tester.tap(
        find.byKey(const ValueKey('report-reason-CUSTOM_REASON')),
      );
      await tester.tap(find.byKey(const ValueKey('report-submit')));
      await tester.pump();
      repository.pending.completeError(
        DioException(requestOptions: RequestOptions(path: '/content/reports')),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Chưa xác nhận được kết quả gửi.'),
        findsOneWidget,
      );
      expect(
        tester
            .widgetList<TextFormField>(find.byType(TextFormField))
            .last
            .controller!
            .text,
        'buyer@example.com',
      );
      await tester.tap(find.byTooltip('Đóng báo cáo'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(ReportListingSheet), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
