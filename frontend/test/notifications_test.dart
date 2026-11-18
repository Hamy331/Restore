import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/notifications/widgets/push_notification_listener.dart';
import 'package:restore/data/models/enums/notification_type.dart';
import 'package:restore/data/models/notification_model.dart';
import 'package:restore/l10n/app_localizations_en.dart';
import 'package:restore/l10n/app_localizations_vi.dart';
import 'package:restore/modules/notifications/bloc/notification_badge/notification_badge_cubit.dart';
import 'package:restore/modules/notifications/bloc/notifications/notifications_cubit.dart';
import 'package:restore/modules/notifications/models/notification_filter.dart';
import 'package:restore/modules/notifications/repositories/notification_repository.dart';
import 'package:restore/modules/notifications/services/push_messaging_service.dart';
import 'package:restore/modules/notifications/utils/notification_presenter.dart';
import 'package:restore/modules/notifications/views/notifications/notifications_view.dart';

import 'feeds_test.dart' show host;

void main() {
  setUp(MockNotificationRepository.reset);

  MockNotificationRepository repo() =>
      MockNotificationRepository(latency: Duration.zero);

  test('model reads API json and unknown types keep server text', () {
    final item = NotificationModel.fromJson({
      'id': 'n1',
      'type': 'SOMETHING_NEW',
      'group': 'wallet',
      'title': 'Tiêu đề',
      'body': 'Nội dung',
      'data': {'amount': 5},
      'readAt': null,
      'createdAt': '2026-11-18T10:00:00.000Z',
    });
    expect(item.type, NotificationType.unknown);
    expect(item.group, NotificationGroup.wallet);
    expect(item.isRead, isFalse);
    expect(item.number('amount'), 5);
    expect(NotificationPresenter.title(AppLocalizationsEn(), item), 'Tiêu đề');
    expect(NotificationPresenter.body(AppLocalizationsEn(), item), 'Nội dung');
  });

  test('presenter localizes known types and appends the admin reason', () {
    final item = NotificationModel.fromJson({
      'id': 'n2',
      'type': 'LISTING_REJECTED',
      'title': 'Tin bị từ chối',
      'body': 'server text',
      'data': {'listingTitle': 'Xe đạp', 'reason': 'Ảnh mờ'},
      'createdAt': '2026-11-18T10:00:00.000Z',
    });
    expect(item.group, NotificationGroup.listing);
    expect(
      NotificationPresenter.body(AppLocalizationsVi(), item),
      'Tin "Xe đạp" không được duyệt. Lý do: Ảnh mờ',
    );
    expect(
      NotificationPresenter.title(AppLocalizationsEn(), item),
      'Listing rejected',
    );
  });

  test('1.7 scheduled listing published is localized', () {
    final item = NotificationModel.fromJson({
      'id': 'n3',
      'type': 'LISTING_PUBLISHED',
      'title': 'Tin đã bắt đầu hiển thị',
      'body': 'server text',
      'data': {'listingId': 'l-9', 'listingTitle': 'Kệ sách'},
      'link': '/listings/l-9',
      'createdAt': '2026-11-18T10:00:00.000Z',
    });
    expect(item.type, NotificationType.listingPublished);
    expect(item.group, NotificationGroup.listing);
    expect(
      NotificationPresenter.title(AppLocalizationsVi(), item),
      'Tin đã bắt đầu hiển thị',
    );
    expect(
      NotificationPresenter.body(AppLocalizationsEn(), item),
      '"Kệ sách" reached its scheduled date and is now visible to buyers.',
    );
  });

  test('1.8 expiring listing shows the days left', () {
    final item = NotificationModel.fromJson({
      'id': 'n4',
      'type': 'LISTING_EXPIRING',
      'title': 'Tin sắp hết hạn',
      'body': 'server text',
      'data': {'listingId': 'l-9', 'listingTitle': 'Kệ sách', 'days': 2},
      'link': '/account',
      'createdAt': '2026-11-18T10:00:00.000Z',
    });
    expect(item.group, NotificationGroup.listing);
    expect(
      NotificationPresenter.body(AppLocalizationsVi(), item),
      'Tin "Kệ sách" còn 2 ngày hiển thị.',
    );
    expect(
      NotificationPresenter.title(AppLocalizationsEn(), item),
      'Listing expiring soon',
    );
  });

  test('1.9 expired and 1.10 auto-renew notifications are localized', () {
    NotificationModel item(String type, Map<String, dynamic> data) =>
        NotificationModel.fromJson({
          'id': type,
          'type': type,
          'title': 't',
          'body': 'server text',
          'data': {'listingId': 'l-9', 'listingTitle': 'Kệ sách', ...data},
          'createdAt': '2026-11-18T10:00:00.000Z',
        });
    final vi = AppLocalizationsVi();
    expect(
      NotificationPresenter.body(vi, item('LISTING_EXPIRED', {})),
      'Tin "Kệ sách" đã hết thời gian hiển thị. Gia hạn để tiếp tục bán.',
    );
    final renewed = item('LISTING_AUTO_EXTENDED', {'days': 30, 'amount': 4});
    expect(renewed.type, NotificationType.listingAutoExtended);
    expect(
      NotificationPresenter.body(AppLocalizationsEn(), renewed),
      '"Kệ sách" was renewed for 30 more days, 4 Points deducted.',
    );
    final failed = item('LISTING_AUTO_EXTEND_FAILED', {});
    expect(failed.group, NotificationGroup.listing);
    expect(
      NotificationPresenter.title(vi, failed),
      'Không đủ Xu để tự gia hạn',
    );
  });

  test('2. wallet, boost, plan and poster notifications are localized', () {
    NotificationModel item(String type, Map<String, dynamic> data) =>
        NotificationModel.fromJson({
          'id': type,
          'type': type,
          'title': 'server title',
          'body': 'server text',
          'data': data,
          'createdAt': '2026-11-18T10:00:00.000Z',
        });
    final vi = AppLocalizationsVi();
    final en = AppLocalizationsEn();
    expect(
      NotificationPresenter.body(
        vi,
        item('CREDIT_TOPUP_SUCCESS', {'amount': 100, 'bonus': 10}),
      ),
      'Bạn đã nhận 100 Xu (tặng thêm 10 Xu).',
    );
    expect(
      NotificationPresenter.body(
        en,
        item('CREDIT_TOPUP_FAILED', {'topupCode': 'RS8F2K1X'}),
      ),
      contains('RS8F2K1X'),
    );
    // 2.3 hoàn xu gộp vào thông báo từ chối tin
    expect(
      NotificationPresenter.body(
        vi,
        item('LISTING_REJECTED', {
          'listingTitle': 'Ghế',
          'reason': 'Ảnh mờ',
          'refunded': 4,
        }),
      ),
      'Tin "Ghế" không được duyệt. Lý do: Ảnh mờ Đã hoàn 4 Xu vào ví.',
    );
    final featured = item('BOOST_STARTED', {
      'listingTitle': 'Tủ sách',
      'kind': 'FEATURED',
      'days': 3,
    });
    expect(NotificationPresenter.title(vi, featured), 'Tin đã lên Hot sale');
    expect(
      NotificationPresenter.body(en, featured),
      '"Tủ sách" is in the Hot sale section for 3 days.',
    );
    expect(
      NotificationPresenter.title(
        vi,
        item('BOOST_ENDED', {'listingTitle': 'Tủ sách', 'kind': 'BUMP'}),
      ),
      'Đã hết thời gian đẩy tin',
    );
    final rejected = item('ORDER_REJECTED', {
      'orderKind': 'PROMOTION_ORDER',
      'packageName': 'Hot sale 3 ngày',
      'listingTitle': 'Tủ sách',
      'reason': 'Chưa nhận được thanh toán',
    });
    expect(rejected.group, NotificationGroup.wallet);
    expect(
      NotificationPresenter.body(vi, rejected),
      'Đơn Hot sale 3 ngày cho tin "Tủ sách" không được xác nhận. '
      'Lý do: Chưa nhận được thanh toán',
    );
    final endsAt = DateTime(2026, 12, 18, 12).toUtc().toIso8601String();
    expect(
      NotificationPresenter.body(
        vi,
        item('STORE_PLAN_EXPIRING', {'planName': 'Cơ bản', 'endsAt': endsAt}),
      ),
      'Gói Cơ bản hết hạn ngày 18/12/2026. Gia hạn để giữ hạn mức đăng tin.',
    );
    expect(
      NotificationPresenter.title(en, item('STORE_PLAN_ACTIVATED', {})),
      'Plan activated',
    );
    expect(
      NotificationPresenter.body(
        en,
        item('SHOP_POSTER_REJECTED', {
          'posterTitle': 'Xả kho',
          'reasonCode': 'TOO_MUCH_TEXT',
          'note': 'Bớt chữ',
        }),
      ),
      'Poster "Xả kho" was not approved. '
      '${en.notifReason('${en.spReasonTooMuchText}: Bớt chữ')}',
    );
  });

  test('push data from FCM becomes a localized notification', () {
    final push = PushNotification.fromData(
      {
        'kind': 'notification',
        'notificationId': 'n-push',
        'type': 'LISTING_APPROVED',
        'group': 'listing',
        'link': '/listings/l-1',
        'payload': '{"listingId":"l-1","listingTitle":"Đèn bàn"}',
        'unreadCount': '4',
        'createdAt': '2026-11-18T10:00:00.000Z',
      },
      'Tin đã được duyệt',
      'server text',
    )!;
    expect(push.unreadCount, 4);
    expect(push.link, '/listings/l-1');
    expect(push.notification.type, NotificationType.listingApproved);
    expect(
      NotificationPresenter.body(AppLocalizationsEn(), push.notification),
      '"Đèn bàn" is now visible to buyers.',
    );
    // Push không phải thông báo (VD chat sau này) hoặc payload hỏng
    expect(PushNotification.fromData({'kind': 'chat'}), isNull);
    final broken = PushNotification.fromData(
      {
        'kind': 'notification',
        'notificationId': 'n2',
        'type': 'LISTING_APPROVED',
        'payload': '{oops',
        'link': '',
      },
      'Tiêu đề',
      'Nội dung',
    )!;
    expect(broken.link, isNull);
    expect(broken.unreadCount, isNull);
    expect(
      NotificationPresenter.body(AppLocalizationsVi(), broken.notification),
      'Nội dung',
    );
  });

  test('a push while the page is open reloads the list', () async {
    final repository = repo();
    final updates = StreamController<Object?>.broadcast();
    final cubit = NotificationsCubit(
      repository: repository,
      updates: updates.stream,
    );
    await cubit.load();
    expect(cubit.state.items, hasLength(9));
    await repository.delete(cubit.state.items.first.id);
    updates.add(null);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.items, hasLength(8));
    await cubit.close();
    await updates.close();
  });

  test(
    'filters, mark read, mark all read and delete keep the badge in sync',
    () async {
      final repository = repo();
      final badge = NotificationBadgeCubit(repository: repository);
      final cubit = NotificationsCubit(repository: repository, badge: badge);

      await cubit.load();
      await badge.refresh();
      expect(cubit.state.items, hasLength(9));
      expect(badge.state, 3);

      await cubit.load(NotificationFilter.wallet);
      expect(
        cubit.state.items.every(
          (item) => item.group == NotificationGroup.wallet,
        ),
        isTrue,
      );

      await cubit.load(NotificationFilter.unread);
      expect(cubit.state.items, hasLength(3));
      await cubit.markRead(cubit.state.items.first);
      expect(badge.state, 2);
      expect(await repository.getUnreadCount(), 2);

      await cubit.markAllRead();
      expect(badge.state, 0);
      expect(await repository.getUnreadCount(), 0);

      await cubit.load(NotificationFilter.all);
      expect(await cubit.delete(cubit.state.items.last), isTrue);
      expect(cubit.state.items, hasLength(8));
      expect((await repository.getNotifications()).items, hasLength(8));
      await cubit.close();
      await badge.close();
    },
  );

  for (final locale in const [Locale('vi'), Locale('en')]) {
    testWidgets('notifications page renders and filters ($locale)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repository = repo();
      final badge = NotificationBadgeCubit(repository: repository);
      addTearDown(badge.close);

      await tester.pumpWidget(
        BlocProvider.value(
          value: badge,
          child: host(locale, NotificationsView(repository: repository)),
        ),
      );
      await tester.pumpAndSettle();
      final vi = locale.languageCode == 'vi';
      expect(find.text(vi ? 'Thông báo' : 'Notifications'), findsWidgets);
      expect(find.text(vi ? 'Hôm nay' : 'Today'), findsOneWidget);
      expect(
        find.text(vi ? 'Tin đã được duyệt' : 'Listing approved'),
        findsOneWidget,
      );
      expect(badge.state, 3);

      final walletChip = find.text(vi ? 'Ví Xu' : 'Point wallet');
      // Ahem trong test rộng hơn font thật: cuộn hàng chip tới "Ví Xu"
      await tester.scrollUntilVisible(
        walletChip,
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(walletChip);
      await tester.pumpAndSettle();
      expect(
        find.text(vi ? 'Nạp Xu thành công' : 'Top-up successful'),
        findsOneWidget,
      );
      expect(
        find.text(vi ? 'Tin đã được duyệt' : 'Listing approved'),
        findsNothing,
      );

      await tester.tap(find.byTooltip(vi ? 'Đọc tất cả' : 'Mark all read'));
      await tester.pumpAndSettle();
      expect(badge.state, 0);
    });
  }

  testWidgets('a push while the app is open shows a banner, updates the bell '
      'and opens its link on tap', (tester) async {
    final repository = repo();
    final badge = NotificationBadgeCubit(repository: repository);
    final push = PushMessagingService(
      repository: repository,
      firebaseReady: Future<void>.value(),
    );
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Text('home')),
        GoRoute(
          path: '/listings/:id',
          builder: (_, state) => Text('listing ${state.pathParameters['id']}'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<NotificationRepository>.value(value: repository),
          RepositoryProvider.value(value: push),
        ],
        child: BlocProvider.value(
          value: badge,
          child: PushNotificationListener(
            router: router,
            child: ScreenUtilInit(
              designSize: const Size(375, 812),
              builder: (_, _) => MaterialApp.router(
                locale: const Locale('en'),
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                routerConfig: router,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    push.addReceivedForTest(
      PushNotification.fromData({
        'kind': 'notification',
        'notificationId': 'n-01',
        'type': 'LISTING_APPROVED',
        'link': '/listings/l-001',
        'payload': '{"listingTitle":"iPhone 17"}',
        'unreadCount': '7',
      })!,
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(badge.state, 7);
    expect(find.text('"iPhone 17" is now visible to buyers.'), findsOneWidget);

    await tester.tap(find.text('Listing approved'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(seconds: 6));
    expect(find.text('listing l-001'), findsOneWidget);
    // n-01 trong dữ liệu mẫu chưa đọc: bấm banner thì đánh dấu đã đọc
    expect(badge.state, 2);
    await push.dispose();
  });
}
