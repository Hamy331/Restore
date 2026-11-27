import 'package:restore/core/constants/app_dimesions.dart';
import 'package:restore/shared/widgets/app_action_buttons.dart';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/bloc/auth/auth_context.dart';
import '../repositories/report_repository.dart';

Future<void> reportListing(BuildContext context, String listingId) async {
  final user = context.currentUser;
  if (user == null) {
    final from = GoRouterState.of(context).uri.toString();
    context.push('/login?from=${Uri.encodeComponent(from)}');
    return;
  }
  final screen = MediaQuery.sizeOf(context);
  final sent = screen.width >= AppDimesions.desktopWidth
      // Desktop: hộp thoại nhỏ giữa màn hình, không phải tờ cao gần hết màn
      ? await showDialog<bool>(
          context: context,
          useRootNavigator: true,
          barrierDismissible: false,
          builder: (_) => Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.all(24),
            child: SizedBox(
              width: 440,
              height: math.min(680, screen.height - 64),
              child: ReportListingSheet(
                listingId: listingId,
                initialEmail: user.email,
                initialPhone: user.phone ?? '',
                dialog: true,
              ),
            ),
          ),
        )
      : await showModalBottomSheet<bool>(
          context: context,
          useRootNavigator: true,
          isScrollControlled: true,
          useSafeArea: true,
          isDismissible: false,
          enableDrag: false,
          backgroundColor: Colors.transparent,
          constraints: const BoxConstraints(maxWidth: 640),
          builder: (_) => ReportListingSheet(
            listingId: listingId,
            initialEmail: user.email,
            initialPhone: user.phone ?? '',
          ),
        );
  if (sent == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.reportSuccess)),
    );
  }
}

class ReportListingSheet extends StatefulWidget {
  const ReportListingSheet({
    required this.listingId,
    this.initialEmail = '',
    this.initialPhone = '',
    this.repository,
    this.dialog = false,
    super.key,
  });

  final String listingId;
  final String initialEmail, initialPhone;
  final ReportRepository? repository;

  /// Desktop: hiện trong hộp thoại nhỏ giữa màn hình (bo đủ bốn góc, cao cố
  /// định) thay vì tờ phủ gần hết màn hình như điện thoại
  final bool dialog;

  @override
  State<ReportListingSheet> createState() => _ReportListingSheetState();
}

class _ReportListingSheetState extends State<ReportListingSheet> {
  static const _ink = Color(0xFF242424);
  static const _line = Color(0xFFF3F3F3);
  late final _phone = TextEditingController(text: widget.initialPhone);
  late final _email = TextEditingController(text: widget.initialEmail);
  late final _repository = widget.repository ?? ReportRepository();
  ListingReportReason? _reason;
  List<ListingReportReason> _reasons = [];
  bool _loadingReasons = true, _reasonsFailed = false, _busy = false;
  String? _error;

  AppLocalizations get l => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _loadReasons();
  }

  Future<void> _loadReasons() async {
    setState(() {
      _loadingReasons = true;
      _reasonsFailed = false;
    });
    try {
      final reasons = await _repository.getReasons();
      if (!mounted) return;
      setState(() {
        _reasons = reasons;
        final selected = reasons.where((item) => item.code == _reason?.code);
        _reason = selected.isEmpty ? null : selected.first;
        _loadingReasons = false;
        _error = reasons.isEmpty ? l.reportReasonsEmpty : null;
      });
    } catch (error) {
      if (!mounted) return;
      final response = error is DioException ? error.response : null;
      final data = response?.data;
      final code = data is Map ? data['code'] : null;
      setState(() {
        _loadingReasons = false;
        _reasonsFailed = true;
        _error = switch (code) {
          'MIGRATION_REQUIRED' => l.reportServiceUnavailable,
          _ when response?.statusCode == 401 => l.reportLoginRequired,
          _ => l.reportReasonsLoadFailed,
        };
      });
    }
  }

  @override
  void dispose() {
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  void _close() {
    if (!_busy) Navigator.of(context).pop();
  }

  void _changed(String _) {
    if (_error != null && !_reasonsFailed && _reasons.isNotEmpty) {
      setState(() => _error = null);
    }
  }

  Future<void> _submit() async {
    if (_busy || _loadingReasons || _reasonsFailed || _reasons.isEmpty) return;
    FocusScope.of(context).unfocus();
    final phone = _phone.text.trim();
    final email = _email.text.trim();
    final validPhone =
        RegExp(r'^\+?[0-9\s().-]+$').hasMatch(phone) &&
        RegExp(
          r'^\+?[0-9]{8,15}$',
        ).hasMatch(phone.replaceAll(RegExp(r'[\s().-]'), ''));
    final error = _reason == null
        ? l.reportReasonRequired
        : !validPhone
        ? l.reportPhoneInvalid
        : !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)
        ? l.reportEmailInvalid
        : null;
    setState(() => _error = error);
    if (error != null) return;
    setState(() => _busy = true);
    try {
      await _repository.submitListing(
        listingId: widget.listingId,
        reason: _reason!,
        phone: phone,
        email: email,
      );
      if (!mounted) return;
      setState(() => _busy = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop(true);
      });
    } catch (error) {
      if (!mounted) return;
      final data = error is DioException ? error.response?.data : null;
      final code = data is Map ? data['code'] : null;
      setState(() {
        _busy = false;
        _error = switch (code) {
          'REPORT_EXISTS' => l.reportExists,
          'TARGET_NOT_FOUND' => l.reportUnavailable,
          'INVALID_REPORT_EMAIL' => l.reportEmailInvalid,
          'INVALID_REPORT_PHONE' => l.reportPhoneInvalid,
          'MIGRATION_REQUIRED' => l.reportServiceUnavailable,
          'REPORT_REASON_UNAVAILABLE' => l.reportReasonsChanged,
          _ when error is DioException && error.response?.statusCode == 401 =>
            l.reportLoginRequired,
          _ => l.reportSendFailed,
        };
      });
      if (code == 'REPORT_REASON_UNAVAILABLE') await _loadReasons();
    }
  }

  Widget _heading(String text, double scale) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.centerLeft,
    child: Text.rich(
      TextSpan(
        text: text,
        children: const [
          TextSpan(
            text: ' *',
            style: TextStyle(color: Color(0xFFB91C1C)),
          ),
        ],
      ),
      style: TextStyle(
        color: _ink,
        fontSize: 13 * scale,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _contactField({
    required String keyName,
    required TextEditingController controller,
    required String hint,
    required TextInputType keyboardType,
    required String autofill,
    required double scale,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12 * scale),
      borderSide: BorderSide(
        color: const Color(0xFFE4E4E4),
        width: 1.5 * scale,
      ),
    );
    return SizedBox(
      height: 44 * scale,
      child: TextFormField(
        key: ValueKey(keyName),
        controller: controller,
        enabled: !_busy,
        maxLines: 1,
        maxLength: keyboardType == TextInputType.phone ? 30 : 254,
        keyboardType: keyboardType,
        autofillHints: [autofill],
        textInputAction: keyboardType == TextInputType.phone
            ? TextInputAction.next
            : TextInputAction.done,
        autocorrect: false,
        onChanged: _changed,
        style: TextStyle(color: _ink, fontSize: 14 * scale),
        decoration: InputDecoration(
          isDense: true,
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 9 * scale,
            vertical: 11 * scale,
          ),
          hint: Text.rich(
            TextSpan(
              text: hint.replaceFirst(RegExp(r'\s*\*$'), ''),
              children: const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: Color(0xFFB91C1C)),
                ),
              ],
            ),
            style: TextStyle(
              fontSize: 14 * scale,
              color: const Color(0xFF969696),
            ),
          ),
          border: border,
          enabledBorder: border,
          disabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: BorderSide(color: _ink, width: 1.5 * scale),
          ),
        ),
      ),
    );
  }

  Widget _reasonRows(double scale) => SizedBox(
    height: 44 * scale * (_loadingReasons ? 1 : _reasons.length),
    child: _loadingReasons
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              for (final reason in _reasons)
                Expanded(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: _line)),
                    ),
                    child: Semantics(
                      checked: _reason?.code == reason.code,
                      inMutuallyExclusiveGroup: true,
                      child: InkWell(
                        key: ValueKey('report-reason-${reason.code}'),
                        onTap: _busy
                            ? null
                            : () => setState(() {
                                _reason = reason;
                                _error = null;
                              }),
                        child: Row(
                          children: [
                            Container(
                              width: 22 * scale,
                              height: 22 * scale,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _reason?.code == reason.code
                                      ? _ink
                                      : const Color(0xFFDDDDDD),
                                  width: 1.8 * scale,
                                ),
                              ),
                              child: _reason?.code == reason.code
                                  ? Center(
                                      child: Container(
                                        width: 11 * scale,
                                        height: 11 * scale,
                                        decoration: const BoxDecoration(
                                          color: _ink,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            SizedBox(width: 12 * scale),
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  reason.label(
                                    Localizations.localeOf(
                                      context,
                                    ).languageCode,
                                  ),
                                  style: TextStyle(
                                    color: _ink,
                                    fontSize: 16 * scale,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
  );

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return PopScope(
      canPop: !_busy,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.only(bottom: keyboard),
        child: FractionallySizedBox(
          heightFactor: widget.dialog ? 1 : .96,
          child: Material(
            color: Colors.white,
            borderRadius: widget.dialog
                ? BorderRadius.circular(20)
                : const BorderRadius.vertical(top: Radius.circular(26)),
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              top: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Fit the reference composition to the available screen. While typing,
                  // keep the contact fields and action visible without adding a scroll view.
                  final scale = math.min(
                    constraints.maxWidth / 393,
                    constraints.maxHeight / (keyboard > 0 ? 320 : 760),
                  );
                  return Column(
                    children: [
                      SizedBox(
                        height: 40 * scale,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 48 * scale,
                              child: IconButton(
                                tooltip: l.reportClose,
                                onPressed: _busy ? null : _close,
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  Icons.close,
                                  size: 27 * scale,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  l.reportTitle,
                                  style: TextStyle(
                                    fontSize: 18 * scale,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 48 * scale),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFCBCBCB)),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            22 * scale,
                            24 * scale,
                            22 * scale,
                            0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (keyboard == 0) ...[
                                SizedBox(
                                  height: 20 * scale,
                                  child: _heading(l.reportQuestion, scale),
                                ),
                                SizedBox(height: 12 * scale),
                                _reasonRows(scale),
                                SizedBox(height: 14 * scale),
                              ],
                              SizedBox(
                                height: 36 * scale,
                                child: Align(
                                  alignment: Alignment.topLeft,
                                  child: _heading(
                                    l.reportContactHeading,
                                    scale,
                                  ),
                                ),
                              ),
                              _contactField(
                                keyName: 'report-phone',
                                controller: _phone,
                                hint: l.reportPhoneHint,
                                keyboardType: TextInputType.phone,
                                autofill: AutofillHints.telephoneNumber,
                                scale: scale,
                              ),
                              SizedBox(height: 12 * scale),
                              _contactField(
                                keyName: 'report-email',
                                controller: _email,
                                hint: l.reportEmailHint,
                                keyboardType: TextInputType.emailAddress,
                                autofill: AutofillHints.email,
                                scale: scale,
                              ),
                              const Spacer(),
                              if (_error != null)
                                Semantics(
                                  liveRegion: true,
                                  child: Text(
                                    _error!,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: const Color(0xFFB91C1C),
                                      fontSize: 12 * scale,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          11 * scale,
                          12 * scale,
                          11 * scale,
                          10 * scale,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: AppCompactActionButton(
                            key: const ValueKey('report-submit'),
                            label: _busy
                                ? l.reportSending
                                : _reasonsFailed
                                ? l.reportRetry
                                : l.reportSubmit,
                            loading: _busy,
                            onPressed: _loadingReasons
                                ? null
                                : _reasonsFailed
                                ? _loadReasons
                                : _reasons.isEmpty
                                ? null
                                : _submit,
                          ),
                        ),
                      ),
                    ],
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
