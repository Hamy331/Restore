import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/utils/helpers/t_snackbar_helper.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/credits/views/credit_topup/credit_topup_view.dart';
import 'package:restore/shared/widgets/app_bottom_action_bar.dart';
import 'package:restore/shared/widgets/app_labeled_text_field.dart';

import '../../../bloc/my_shop_cubit.dart';
import '../../../models/shop_terms.dart';
import '../my_shop_mobile_view.dart' show myShopError;
import 'my_shop_section.dart';

/// Gắn vào form xác minh của trang Quản lý shop: đăng ký xong bấm "Xác minh"
/// thì cuộn tới đó
final myShopVerifyKey = GlobalKey(debugLabel: 'my-shop-verify');

/// Lên Cửa hàng (chưa có shop): giới thiệu → quyền lợi → đăng ký (tên, hợp
/// đồng, phí xu). Xong thì trang Quản lý shop hiện shop mới và màn hình chúc
/// mừng mời xác minh giấy phép (làm sau cũng được).
class BecomeShopFlow extends StatefulWidget {
  const BecomeShopFlow({
    super.key,
    required this.saving,
    required this.fee,
    this.categories = const [],
  });

  final bool saving;

  /// Danh mục để chọn: tin của cửa hàng chỉ đăng trong một danh mục
  final List<({String id, String name})> categories;

  /// Phí đăng ký (xu)
  final int fee;

  @override
  State<BecomeShopFlow> createState() => _BecomeShopFlowState();
}

class _BecomeShopFlowState extends State<BecomeShopFlow> {
  final _name = TextEditingController();
  final _tagline = TextEditingController();
  final _address = TextEditingController();
  int _step = 0;
  String? _categoryId;
  bool _agreed = false;
  bool _showErrors = false;

  @override
  void dispose() {
    _name.dispose();
    _tagline.dispose();
    _address.dispose();
    super.dispose();
  }

  bool get _nameValid {
    final length = _name.text.trim().length;
    return length >= 2 && length <= 60;
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      context.pop();
    }
  }

  void _openTerms() => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => ShopTermsPage(fee: widget.fee)),
  );

  Future<void> _register() async {
    final l = AppLocalizations.of(context)!;
    setState(() => _showErrors = true);
    if (!_nameValid || _categoryId == null || !_agreed) return;
    // Tạo xong trang này bị thay bằng trang Quản lý shop: giữ navigator để
    // hiện màn hình chúc mừng
    final navigator = Navigator.of(context);
    final error = await context.read<MyShopCubit>().create(
      name: _name.text.trim(),
      categoryId: _categoryId!,
      tagline: _tagline.text.trim(),
      address: _address.text.trim(),
    );
    if (error == null) {
      if (!navigator.mounted) return;
      final verify = await showBecomeShopDone(navigator.context);
      if (verify == true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final target = myShopVerifyKey.currentContext;
          if (target != null && target.mounted) {
            Scrollable.ensureVisible(
              target,
              duration: const Duration(milliseconds: 350),
            );
          }
        });
      }
      return;
    }
    if (!mounted) return;
    if (error == 'NOT_ENOUGH_CREDITS') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.bsNotEnoughCredits(widget.fee)),
          action: SnackBarAction(
            label: l.bsTopUp,
            onPressed: () => context.push(CreditTopupView.path),
          ),
        ),
      );
    } else {
      TSnackBarHelper.showError(context, message: myShopError(l, error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final (body, bottom) = switch (_step) {
      0 => (
        _intro(l),
        AppBottomActionBar(
          key: const ValueKey('become-shop-next'),
          primaryLabel: l.bsIntroAction,
          onPrimary: () => setState(() => _step = 1),
        ),
      ),
      1 => (
        _benefits(l),
        AppBottomActionBar(
          key: const ValueKey('become-shop-switch'),
          primaryLabel: l.bsSwitchAction,
          primaryIcon: AppIcons.store,
          onPrimary: () => setState(() => _step = 2),
        ),
      ),
      _ => (
        _form(l),
        AppBottomActionBar(
          key: const ValueKey('my-shop-create'),
          primaryLabel: l.bsPayAction(widget.fee),
          primaryIcon: AppIcons.store,
          isLoading: widget.saving,
          onPrimary: widget.saving ? null : _register,
        ),
      ),
    };
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: Icon(
              _step == 0 ? AppIcons.close : AppIcons.back,
              color: AppColors.textPrimary,
            ),
            onPressed: _back,
          ),
        ),
        bottomNavigationBar: bottom,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: body,
          ),
        ),
      ),
    );
  }

  Widget _title(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 24,
      height: 1.25,
      fontWeight: FontWeight.w800,
      color: AppColors.textPrimary,
    ),
  );

  Widget _intro(AppLocalizations l) => ListView(
    key: const ValueKey('become-shop-intro'),
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
    children: [
      _title(l.bsIntroTitle),
      const SizedBox(height: 24),
      const Center(child: _StoreArt()),
      const SizedBox(height: 28),
      Text(
        l.bsIntroLead,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 12),
      for (final item in [
        l.bsIntroResell,
        l.bsIntroNew,
        l.bsIntroVolume,
        l.bsIntroService,
        l.bsIntroBusiness,
        l.bsIntroStore,
      ])
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                AppIcons.checkCircle,
                size: 22,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 15, height: 1.35),
                ),
              ),
            ],
          ),
        ),
    ],
  );

  Widget _benefits(AppLocalizations l) => ListView(
    key: const ValueKey('become-shop-benefits'),
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
    children: [
      _title(l.bsBenefitsTitle),
      const SizedBox(height: 12),
      _Benefit(
        icon: AppIcons.store,
        title: l.bsBenefitPageTitle,
        body: l.bsBenefitPageBody,
      ),
      _Benefit(
        icon: AppIcons.verified,
        title: l.bsBenefitBadgeTitle,
        body: l.bsBenefitBadgeBody,
      ),
      _Benefit(
        icon: AppIcons.post,
        title: l.bsBenefitFeedTitle,
        body: l.bsBenefitFeedBody,
      ),
      _Benefit(
        icon: AppIcons.posterPromo,
        title: l.bsBenefitPosterTitle,
        body: l.bsBenefitPosterBody,
      ),
      const SizedBox(height: 8),
      Text.rich(
        TextSpan(
          children: [
            TextSpan(text: l.bsAgreeLead),
            TextSpan(
              text: l.bsTermsLink,
              style: const TextStyle(
                color: AppColors.actionPrimary,
                fontWeight: FontWeight.w600,
              ),
              recognizer: TapGestureRecognizer()..onTap = _openTerms,
            ),
            TextSpan(text: l.bsAgreeTail),
          ],
        ),
        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
      ),
    ],
  );

  Widget _form(AppLocalizations l) => ListView(
    key: const ValueKey('become-shop-form'),
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
    children: [
      MyShopSection(
        title: l.bsRegisterTitle,
        subtitle: l.bsRegisterBody,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppLabeledTextField(
              key: const ValueKey('my-shop-name'),
              label: l.msName,
              isRequired: true,
              controller: _name,
              maxLength: 60,
              hintText: l.msNameHint,
              errorText: _showErrors && !_nameValid ? l.msNameRequired : null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            Text(
              '${l.bsCategory} *',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              l.bsCategoryHint,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final category in widget.categories)
                  ChoiceChip(
                    key: ValueKey('shop-category-${category.id}'),
                    label: Text(category.name),
                    selected: _categoryId == category.id,
                    onSelected: (_) =>
                        setState(() => _categoryId = category.id),
                  ),
              ],
            ),
            if (_showErrors && _categoryId == null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  l.bsCategoryRequired,
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ),
            const SizedBox(height: 14),
            AppLabeledTextField(
              key: const ValueKey('my-shop-tagline'),
              label: l.msTagline,
              controller: _tagline,
              maxLength: 80,
              hintText: l.msTaglineHint,
            ),
            const SizedBox(height: 14),
            AppLabeledTextField(
              key: const ValueKey('my-shop-address'),
              label: l.msAddress,
              controller: _address,
              maxLength: 120,
              hintText: l.msAddressHint,
            ),
          ],
        ),
      ),
      MyShopSection(
        title: l.bsFeeTitle,
        subtitle: l.bsFeeBody(widget.fee),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Material riêng: khung MyShopSection có nền màu che hiệu ứng chạm
            Material(
              type: MaterialType.transparency,
              child: CheckboxListTile(
                key: const ValueKey('become-shop-agree'),
                value: _agreed,
                onChanged: (value) => setState(() => _agreed = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Text(l.bsAgree, style: const TextStyle(fontSize: 14)),
                subtitle: _showErrors && !_agreed
                    ? Text(
                        l.bsAgreeRequired,
                        style: const TextStyle(color: AppColors.error),
                      )
                    : null,
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const ValueKey('become-shop-terms'),
                onPressed: _openTerms,
                icon: const Icon(AppIcons.info, size: 18),
                label: Text(l.bsTermsLink),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _StoreArt extends StatelessWidget {
  const _StoreArt();

  @override
  Widget build(BuildContext context) => Container(
    width: 120,
    height: 120,
    decoration: const BoxDecoration(
      color: AppColors.fill,
      shape: BoxShape.circle,
    ),
    child: const Icon(AppIcons.store, size: 64, color: AppColors.primaryDark),
  );
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: AppColors.fill,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 36, color: AppColors.primaryDark),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            height: 1.4,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    ),
  );
}

/// Màn hình chúc mừng sau khi lên Cửa hàng; trả về true nếu chọn xác minh ngay
Future<bool?> showBecomeShopDone(BuildContext context) => showDialog<bool>(
  context: context,
  builder: (context) {
    final l = AppLocalizations.of(context)!;
    Widget feature(IconData icon, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: AppColors.primaryDark),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, height: 1.35),
            ),
          ),
        ],
      ),
    );
    return Dialog.fullscreen(
      key: const ValueKey('become-shop-done'),
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                icon: const Icon(AppIcons.close),
                onPressed: () => Navigator.pop(context, false),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                children: [
                  Text(
                    l.bsDoneTitle,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Center(child: _StoreArt()),
                  const SizedBox(height: 14),
                  Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        child: Text(
                          l.bsDoneBadge,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    l.bsDoneFeatures,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  feature(AppIcons.store, l.bsDonePage),
                  feature(AppIcons.verified, l.bsBenefitBadgeBody),
                  feature(AppIcons.clock, l.bsDoneReview),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.successBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l.bsDoneSuccess,
                      style: const TextStyle(color: AppColors.success),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    key: const ValueKey('become-shop-verify'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(
                        AppBottomActionBar.buttonHeight,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(l.bsVerifyAction),
                  ),
                  TextButton(
                    key: const ValueKey('become-shop-later'),
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(l.bsLater),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  },
);

/// Toàn văn Hợp đồng Cửa hàng
class ShopTermsPage extends StatelessWidget {
  const ShopTermsPage({super.key, required this.fee});

  final int fee;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final sections = shopTerms(l.localeName, fee);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text(l.bsTermsTitle),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            key: const ValueKey('shop-terms'),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Text(
                l.bsTermsVersion(shopTermsVersion),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              for (final section in sections) ...[
                const SizedBox(height: 18),
                Text(
                  section.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                for (final paragraph in section.body)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      paragraph,
                      style: const TextStyle(fontSize: 14, height: 1.45),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
