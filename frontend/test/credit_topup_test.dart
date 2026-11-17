import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/data/models/credit_topup_model.dart';
import 'package:restore/data/models/enums/credit_enums.dart';
import 'package:restore/modules/credits/bloc/credit_history/credit_history_cubit.dart';
import 'package:restore/modules/credits/bloc/credit_topup/credit_topup_cubit.dart';
import 'package:restore/modules/credits/bloc/credit_topup/credit_topup_state.dart';
import 'package:restore/modules/credits/models/credit_history_filter.dart';
import 'package:restore/modules/credits/models/topup_step.dart';
import 'package:restore/modules/credits/repositories/credit_repository.dart';
import 'package:restore/modules/credits/services/zalopay_launcher.dart';
import 'package:restore/modules/credits/views/credit_topup/credit_topup_view.dart';
import 'package:restore/modules/credits/views/credit_topup/widgets/topup_pay_section.dart';
import 'package:restore/modules/credits/views/credit_wallet/credit_wallet_view.dart';

import 'feeds_test.dart' show host;

void main() {
  setUp(MockCreditRepository.reset);
  gatewayFlowTests();
  appToAppTests();

  MockCreditRepository repo() => MockCreditRepository(latency: Duration.zero);

  test('topup credits the wallet only after the sandbox confirms', () async {
    final repository = repo();
    expect((await repository.getWallet()).available, 125);

    final cubit = CreditTopupCubit(repository: repository);
    await cubit.load(preselectId: 'p20');
    expect(cubit.state.selectedId, 'p20');
    cubit.selectPackage('p100');
    cubit.next();
    expect(cubit.state.step, TopupStep.confirm);

    // Chưa đồng ý điều khoản thì không tạo đơn
    await cubit.pay();
    expect(cubit.state.order, isNull);

    cubit.toggleAgreed();
    await cubit.pay();
    expect(cubit.state.step, TopupStep.pay);
    expect(cubit.state.order!.status, TopupStatus.pending);
    expect((await repository.getWallet()).available, 125);

    await cubit.simulate(success: true);
    expect(cubit.state.step, TopupStep.result);
    expect(cubit.state.outcome, TopupOutcome.success);
    final wallet = await repository.getWallet();
    expect(wallet.available, 235);
    expect(wallet.bonus, 40);
    await cubit.close();
  });

  test('failed or cancelled topup adds nothing and can be retried', () async {
    final repository = repo();
    final cubit = CreditTopupCubit(repository: repository);
    await cubit.load();
    expect(cubit.state.selectedId, 'p100', reason: 'chọn sẵn gói phổ biến');
    cubit
      ..next()
      ..selectMethod(CreditPayMethod.vietQr)
      ..toggleAgreed();
    await cubit.pay();
    expect(cubit.state.order!.vietQr, isNotNull);
    await cubit.cancel();
    expect(cubit.state.outcome, TopupOutcome.failed);
    expect((await repository.getWallet()).available, 125);
    cubit.retry();
    expect(cubit.state.step, TopupStep.confirm);
    expect(cubit.state.order, isNull);
    await cubit.close();
  });

  test(
    'topup preselects the smallest pack that covers the missing points',
    () async {
      final cubit = CreditTopupCubit(repository: repo());
      await cubit.load(need: 40);
      expect(cubit.state.selectedId, 'p50');
      await cubit.load(need: 5);
      expect(cubit.state.selectedId, 'p20');
      await cubit.close();
    },
  );

  test('history filters by type', () async {
    final cubit = CreditHistoryCubit(repository: repo());
    await cubit.load();
    expect(cubit.state.items, hasLength(5));
    await cubit.load(CreditHistoryFilter.refund);
    expect(cubit.state.items, hasLength(1));
    await cubit.load(CreditHistoryFilter.spend);
    expect(cubit.state.items.every((t) => t.amount < 0), isTrue);
    await cubit.close();
  });

  for (final locale in const [Locale('vi'), Locale('en')]) {
    testWidgets('wallet and topup screens render in ${locale.languageCode}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        host(locale, CreditWalletView(repository: repo())),
      );
      await tester.pumpAndSettle();
      expect(find.text('125'), findsOneWidget);
      expect(
        find.text(locale.languageCode == 'vi' ? 'Nạp xu' : 'Buy points'),
        findsWidgets,
      );

      await tester.pumpWidget(
        host(locale, CreditTopupView(repository: repo())),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(locale.languageCode == 'vi' ? 'Phổ biến' : 'Popular'),
        findsOneWidget,
      );
      await tester.tap(
        find.text(
          locale.languageCode == 'vi'
              ? 'Tiếp tục · 100.000 đ'
              : 'Continue · 100,000 đ',
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(
          locale.languageCode == 'vi'
              ? 'Chuyển khoản VietQR'
              : 'VietQR bank transfer',
        ),
        findsOneWidget,
      );
      final vi = locale.languageCode == 'vi';
      await tester.ensureVisible(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(vi ? 'Thanh toán 100.000 đ' : 'Pay 100,000 đ'),
      );
      await tester.pumpAndSettle();
      // Đơn mẫu có sandbox = true (backend quyết định) nên hiện ghi chú chế độ thử
      expect(
        find.text(
          vi
              ? 'Chế độ thử (sandbox): không trừ tiền thật.'
              : 'Test mode (sandbox): no real money is charged.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text(vi ? 'Đã trả tiền' : 'Paid'));
      await tester.pumpAndSettle();
      expect(
        find.text(vi ? 'Nạp thành công' : 'Purchase complete'),
        findsOneWidget,
      );
      expect(find.text(vi ? '+110 xu' : '+110 points'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

/// Đơn có trang ZaloPay (backend không bỏ qua cổng)
class _GatewayRepository extends MockCreditRepository {
  _GatewayRepository({this.withApp = false}) : super(latency: Duration.zero);

  final bool withApp;

  @override
  Future<CreditTopupModel> createTopup(
    String packageId,
    CreditPayMethod method,
  ) async {
    final order = await super.createTopup(packageId, method);
    return CreditTopupModel(
      id: order.id,
      code: order.code,
      status: order.status,
      method: order.method,
      amountVnd: order.amountVnd,
      credits: order.credits,
      bonusCredits: order.bonusCredits,
      expiresAt: order.expiresAt,
      sandbox: true,
      payUrl: 'https://qcgateway.zalopay.vn/openinapp?order=test',
      zaloPay: withApp
          ? const ZaloPayAppInfo(
              appId: 2554,
              zpTransToken: 'ACtest',
              sandbox: true,
            )
          : null,
    );
  }
}

void gatewayFlowTests() {
  testWidgets('ZaloPay order opens the gateway and hides simulate buttons', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      host(
        const Locale('vi'),
        CreditTopupView(repository: _GatewayRepository()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếp tục · 100.000 đ'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thanh toán 100.000 đ'));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    // Có cổng thật (sandbox): không còn nút giả lập
    expect(find.text('Đã trả tiền'), findsNothing);
    // Trong test không có app nào mở được link: báo lỗi để người dùng thử lại
    // Nhận biết máy (kênh native) rồi mở link: chờ thật vài lượt cho xong
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 300));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
    }
    await tester.pump(const Duration(milliseconds: 300));
    // Mở lỗi xong thì nút mở lại ZaloPay hiện ra để thử lại
    expect(find.text('Mở trang thanh toán ZaloPay'), findsOneWidget);
    expect(find.textContaining('Không mở được ZaloPay'), findsWidgets);
    // Đóng trang để dừng hỏi trạng thái định kỳ
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}

/// Launcher giả: ghi lại lần mở app, trả kết quả định sẵn
class _FakeLauncher extends ZaloPayLauncher {
  _FakeLauncher(this.result);

  final ZaloPayLaunchResult result;
  final opened = <ZaloPayAppInfo>[];

  @override
  Future<bool> isTestDevice() async => false;

  @override
  Future<ZaloPayLaunchResult> pay(ZaloPayAppInfo info) async {
    opened.add(info);
    return result;
  }
}

void appToAppTests() {
  /// Cubit đã tạo đơn ZaloPay có thông tin app-to-app (bước trả tiền)
  Future<CreditTopupCubit> payingCubit() async {
    final cubit = CreditTopupCubit(
      repository: _GatewayRepository(withApp: true),
      pollInterval: const Duration(hours: 1),
    );
    await cubit.load();
    cubit
      ..next()
      ..toggleAgreed();
    await cubit.pay();
    return cubit;
  }

  Future<void> pumpSection(
    WidgetTester tester,
    CreditTopupCubit cubit,
    ZaloPayLauncher launcher, {
    bool? isTestDevice,
  }) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      host(
        const Locale('vi'),
        BlocProvider.value(
          value: cubit,
          child: TopupPaySection(
            launcher: launcher,
            isTestDevice: isTestDevice,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('real phone opens the ZaloPay app and hides test tools', (
    tester,
  ) async {
    final cubit = await tester.runAsync(payingCubit);
    final launcher = _FakeLauncher(ZaloPayLaunchResult.opened);
    await pumpSection(tester, cubit!, launcher, isTestDevice: false);

    expect(launcher.opened.single.zpTransToken, 'ACtest');
    expect(find.text('Mở app ZaloPay'), findsOneWidget);
    expect(find.text('Đã trả tiền'), findsNothing);
    expect(
      find.text('Chế độ thử (sandbox): không trừ tiền thật.'),
      findsNothing,
    );
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(cubit.close);
  });

  testWidgets('real phone without ZaloPay shows a notice and the web option', (
    tester,
  ) async {
    final cubit = await tester.runAsync(payingCubit);
    await pumpSection(
      tester,
      cubit!,
      _FakeLauncher(ZaloPayLaunchResult.notInstalled),
      isTestDevice: false,
    );

    expect(find.textContaining('Máy chưa cài app ZaloPay'), findsOneWidget);
    expect(find.text('Trả trên trang web ZaloPay'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(cubit.close);
  });

  testWidgets('emulator does not open ZaloPay and shows the test tools', (
    tester,
  ) async {
    final cubit = await tester.runAsync(payingCubit);
    final launcher = _FakeLauncher(ZaloPayLaunchResult.opened);
    await pumpSection(tester, cubit!, launcher, isTestDevice: true);

    expect(launcher.opened, isEmpty);
    expect(
      find.text('Chế độ thử (sandbox): không trừ tiền thật.'),
      findsOneWidget,
    );
    expect(find.text('Đã trả tiền'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(cubit.close);
  });
}
