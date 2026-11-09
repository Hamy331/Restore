import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:restore/core/utils/formatters/currency_formatter.dart';
import 'package:restore/data/models/credit_transaction_model.dart';
import 'package:restore/data/models/enums/credit_enums.dart';
import 'package:restore/l10n/app_localizations.dart';

/// Cách hiển thị số xu, tiền và tên giao dịch dùng chung trong module xu
class CreditFormat {
  CreditFormat._();

  static String _locale(BuildContext context) =>
      Localizations.localeOf(context).toLanguageTag();

  /// Số có dấu phân cách theo ngôn ngữ, VD 1.250
  static String number(BuildContext context, int value) =>
      CurrencyFormatter.formatNumber(value, locale: _locale(context));

  /// "125 xu" / "125 points"
  static String points(BuildContext context, int value) =>
      AppLocalizations.of(context)!.creditPoints(value, number(context, value));

  static String vnd(BuildContext context, int value) =>
      CurrencyFormatter.formatVnd(value, locale: _locale(context));

  static String date(BuildContext context, DateTime value) =>
      DateFormat('dd/MM/yyyy', _locale(context)).format(value);

  static String dateTime(BuildContext context, DateTime value) =>
      DateFormat('HH:mm · dd/MM', _locale(context)).format(value);

  static String time(BuildContext context, DateTime value) =>
      DateFormat('HH:mm', _locale(context)).format(value);

  /// Số xu có dấu: +110 / −5
  static String signed(BuildContext context, int value) =>
      '${value >= 0 ? '+' : '−'}${number(context, value.abs())}';

  static String transactionTitle(AppLocalizations l10n, CreditTxnType type) =>
      switch (type) {
        CreditTxnType.topup => l10n.creditTxnTopup,
        CreditTxnType.bonus => l10n.creditTxnBonus,
        CreditTxnType.spend => l10n.creditTxnSpend,
        CreditTxnType.refund => l10n.creditTxnRefund,
        CreditTxnType.expire => l10n.creditTxnExpire,
        CreditTxnType.adjust => l10n.creditTxnAdjust,
      };

  static String methodName(AppLocalizations l10n, CreditPayMethod method) =>
      switch (method) {
        CreditPayMethod.vnpay => l10n.creditMethodVnpay,
        CreditPayMethod.vietQr => l10n.creditMethodVietqr,
      };

  /// Dòng phụ của giao dịch: ghi chú hoặc mã đơn nạp, kèm thời gian
  static String transactionSubtitle(
    BuildContext context,
    CreditTransactionModel item,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final detail =
        item.note ??
        (item.topupCode == null ? null : l10n.creditTxnOrder(item.topupCode!));
    final when = dateTime(context, item.createdAt);
    return detail == null ? when : '$detail · $when';
  }
}
