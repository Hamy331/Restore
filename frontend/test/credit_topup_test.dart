import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/data/models/enums/credit_enums.dart';
import 'package:restore/modules/credits/bloc/credit_history/credit_history_cubit.dart';
import 'package:restore/modules/credits/bloc/credit_topup/credit_topup_cubit.dart';
import 'package:restore/modules/credits/bloc/credit_topup/credit_topup_state.dart';
import 'package:restore/modules/credits/models/credit_history_filter.dart';
import 'package:restore/modules/credits/models/topup_step.dart';
import 'package:restore/modules/credits/repositories/credit_repository.dart';
import 'package:restore/modules/credits/views/credit_topup/credit_topup_view.dart';
import 'package:restore/modules/credits/views/credit_wallet/credit_wallet_view.dart';

import 'feeds_test.dart' show host;

void main() {
  setUp(MockCreditRepository.reset);

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
