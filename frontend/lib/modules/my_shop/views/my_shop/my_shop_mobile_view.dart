import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:restore/shared/widgets/desktop/desktop_page_title.dart';
import 'package:restore/shared/widgets/desktop/desktop_layout.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/utils/helpers/t_snackbar_helper.dart';
import 'package:restore/data/models/shop_model.dart';
import 'package:restore/data/models/shop_opening_hours.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/shop_posters/views/shop_posters/shop_posters_view.dart';
import 'package:restore/modules/trusted_shop/widgets/shop_logo.dart';
import 'package:restore/services/media_picker_service.dart';
import 'package:restore/shared/widgets/app_bottom_action_bar.dart';
import 'package:restore/shared/widgets/app_labeled_text_field.dart';
import 'package:restore/shared/widgets/app_option_sheet.dart';
import 'package:restore/shared/widgets/app_load_error_view.dart';
import 'package:restore/shared/widgets/image_crop/image_crop.dart';
import 'package:restore/shared/widgets/image_crop/image_crop_view.dart';
import 'package:restore/shared/widgets/loading/app_loading_indicator.dart';

import '../../bloc/my_shop_cubit.dart';
import '../../models/my_shop_overview.dart';
import 'my_shop_view.dart';
import 'widgets/become_shop_flow.dart';
import 'widgets/my_shop_color_field.dart';
import 'widgets/my_shop_header.dart';
import 'widgets/my_shop_hours_field.dart';
import 'widgets/my_shop_section.dart';
import 'widgets/my_shop_stats.dart';
import 'widgets/my_shop_status_card.dart';
import 'widgets/my_shop_verification_form.dart';
import '../shop_followers/shop_followers_view.dart';

/// Lời báo lỗi theo mã backend khi mở shop / lưu
String myShopError(AppLocalizations l, String code) => switch (code) {
  'SHOP_NAME_LOCKED' => l.msNameLocked,
  'SHOP_EXISTS' => l.msErrExists,
  'SHOP_NAME_NOT_ALLOWED' => l.msErrNameNotAllowed,
  'VERIFICATION_PENDING' => l.msVerifyPendingTitle,
  'SHOP_ALREADY_VERIFIED' => l.msVerifiedTitle,
  'SHOP_NOT_APPROVED' => l.msPendingTitle,
  'INVALID_IMAGE_URL' || 'INVALID_IMAGE' || 'IMAGE_TOO_LARGE' => l.msErrImage,
  'VALIDATION_ERROR' => l.msNameRequired,
  _ => l.msErrGeneric,
};

class MyShopMobileView extends StatelessWidget {
  const MyShopMobileView({super.key, required this.imageLoader, this.picker});

  final ShopImageLoader imageLoader;
  final MediaPickerService? picker;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocBuilder<MyShopCubit, MyShopState>(
      builder: (context, state) {
        final cubit = context.read<MyShopCubit>();
        final overview = state.overview;
        if (overview == null) {
          return _MyShopScaffold(
            body: state.status == MyShopStatus.failure
                ? AppLoadErrorView(title: l.msLoadError, onRetry: cubit.load)
                : const Center(child: AppLoadingIndicator()),
          );
        }
        final shop = overview.shop;
        if (shop != null) {
          return _MyShopEditor(
            // lưu xong shop đổi thì dựng lại form theo dữ liệu mới
            key: ValueKey(shop),
            overview: overview,
            shop: shop,
            saving: state.saving,
            picker: picker,
            imageLoader: imageLoader,
          );
        }
        // Chưa lên Cửa hàng: luồng giới thiệu → quyền lợi → đăng ký (không cần gói tài khoản)
        return BecomeShopFlow(
          saving: state.saving,
          fee: overview.registrationFee,
        );
      },
    );
  }
}

class _MyShopScaffold extends StatelessWidget {
  const _MyShopScaffold({required this.body, this.bottom, this.actions});

  final Widget body;
  final Widget? bottom;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: isDesktopLayout(context)
        ? DesktopSectionBar(title: AppLocalizations.of(context)!.msTitle)
        : AppBar(
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              icon: const Icon(AppIcons.back, color: AppColors.textPrimary),
              onPressed: () => context.pop(),
            ),
            centerTitle: true,
            title: Text(
              AppLocalizations.of(context)!.msTitle,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            actions: actions,
          ),
    bottomNavigationBar: bottom,
    body: body,
  );
}

enum _ImageAction { pick, adjust, remove }

enum _ShopImage { logo, cover }

/// Sửa shop đã có: ảnh bìa, logo, số liệu, trạng thái, thông tin, màu
class _MyShopEditor extends StatefulWidget {
  const _MyShopEditor({
    super.key,
    required this.overview,
    required this.shop,
    required this.saving,
    required this.imageLoader,
    this.picker,
  });

  final MyShopOverview overview;
  final ShopModel shop;
  final bool saving;
  final ShopImageLoader imageLoader;
  final MediaPickerService? picker;

  @override
  State<_MyShopEditor> createState() => _MyShopEditorState();
}

class _MyShopEditorState extends State<_MyShopEditor> {
  late final _name = TextEditingController(text: widget.shop.name);
  late final _tagline = TextEditingController(text: widget.shop.tagline);
  late final _description = TextEditingController(
    text: widget.shop.description,
  );
  late final _address = TextEditingController(text: widget.shop.address);
  late String? _accent = widget.shop.accentColor;

  /// Giờ mở cửa: các thứ đã chọn dùng chung một khung giờ (lấy theo ngày đầu)
  late Set<int> _days = {for (final item in widget.shop.openingHours) item.day};
  late TimeOfDay _open = _time(widget.shop.openingHours.firstOrNull?.open, 8);
  late TimeOfDay _close = _time(
    widget.shop.openingHours.firstOrNull?.close,
    21,
  );
  bool _hoursTouched = false;

  static TimeOfDay _time(String? value, int fallbackHour) {
    final parts = value?.split(':');
    if (parts == null || parts.length != 2) {
      return TimeOfDay(hour: fallbackHour, minute: 0);
    }
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  /// Giờ mở cửa sẽ lưu, rỗng = xoá
  List<ShopOpeningDay> get _hours => [
    for (final day in _days.toList()..sort())
      ShopOpeningDay(
        day: day,
        open: MyShopHoursField.format(_open),
        close: MyShopHoursField.format(_close),
      ),
  ];

  bool get _hoursValid =>
      _days.isEmpty || MyShopHoursField.valid(_open, _close);

  /// Ảnh trên server (null khi chưa có hoặc người dùng xoá) và ảnh mới đã
  /// cắt chưa lưu kèm ảnh gốc để căn chỉnh lại
  late String? _logoUrl = widget.shop.logoUrl, _coverUrl = widget.shop.coverUrl;
  Uint8List? _logoBytes, _logoSource, _coverBytes, _coverSource;
  bool _showErrors = false, _loadingImage = false;

  @override
  void dispose() {
    _name.dispose();
    _tagline.dispose();
    _description.dispose();
    _address.dispose();
    super.dispose();
  }

  bool get _nameValid {
    final length = _name.text.trim().length;
    return length >= 2 && length <= 60;
  }

  /// Trường đã đổi so với shop đang lưu (ảnh mới gửi riêng qua cubit)
  Map<String, dynamic> get _changes {
    final shop = widget.shop;
    String? orNull(String text) => text.trim().isEmpty ? null : text.trim();
    return {
      if (_name.text.trim() != shop.name) 'name': _name.text.trim(),
      if (_tagline.text.trim() != shop.tagline) 'tagline': _tagline.text.trim(),
      if (_description.text.trim() != shop.description)
        'description': _description.text.trim(),
      if (orNull(_address.text) != shop.address)
        'address': orNull(_address.text),
      if (_accent != shop.accentColor) 'accentColor': _accent,
      if (_logoBytes == null && _logoUrl != shop.logoUrl) 'logoUrl': null,
      if (_coverBytes == null && _coverUrl != shop.coverUrl) 'coverUrl': null,
      if (_hoursTouched && !listEquals(_hours, shop.openingHours))
        'openingHours': _days.isEmpty
            ? null
            : [for (final item in _hours) item.toJson()],
    };
  }

  bool get _dirty =>
      _changes.isNotEmpty || _logoBytes != null || _coverBytes != null;

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    setState(() => _showErrors = true);
    if (!_nameValid || !_hoursValid) return;
    final error = await context.read<MyShopCubit>().save(
      _changes,
      logo: _logoBytes,
      cover: _coverBytes,
    );
    if (!mounted) return;
    if (error == null) {
      TSnackBarHelper.showSuccess(context, message: l.msSaved);
    } else {
      TSnackBarHelper.showError(context, message: myShopError(l, error));
    }
  }

  Future<bool> _requestVerification(
    String businessName,
    String taxCode,
    List<Uint8List> documents,
  ) async {
    final l = AppLocalizations.of(context)!;
    final error = await context.read<MyShopCubit>().requestVerification(
      businessName: businessName,
      taxCode: taxCode,
      documents: documents,
    );
    if (!mounted) return false;
    if (error == null) {
      TSnackBarHelper.showSuccess(context, message: l.msVerifySent);
    } else {
      TSnackBarHelper.showError(context, message: myShopError(l, error));
    }
    return error == null;
  }

  Future<void> _editImage(_ShopImage which) async {
    final l = AppLocalizations.of(context)!;
    final logo = which == _ShopImage.logo;
    final hasImage = logo
        ? _logoBytes != null || _logoUrl != null
        : _coverBytes != null || _coverUrl != null;
    final action = hasImage
        ? await showAppOptionSheet<_ImageAction>(
            context,
            title: logo ? l.msChangeLogo : l.msChangeCover,
            options: [
              AppSheetOption(
                _ImageAction.pick,
                l.msImageNew,
                icon: AppIcons.addPhoto,
              ),
              AppSheetOption(
                _ImageAction.adjust,
                l.msImageAdjust,
                icon: AppIcons.zoomIn,
              ),
              AppSheetOption(
                _ImageAction.remove,
                l.msImageRemove,
                icon: AppIcons.delete,
              ),
            ],
          )
        : _ImageAction.pick;
    if (!mounted || action == null) return;
    switch (action) {
      case _ImageAction.pick:
        await _pick(which);
      case _ImageAction.adjust:
        await _adjust(which);
      case _ImageAction.remove:
        setState(() {
          if (logo) {
            _logoUrl = _logoBytes = _logoSource = null;
          } else {
            _coverUrl = _coverBytes = _coverSource = null;
          }
        });
    }
  }

  Future<void> _pick(_ShopImage which) async {
    try {
      final paths = await (widget.picker ?? MediaPickerService()).pickImages(
        source: MediaSource.gallery,
        limit: 1,
      );
      if (paths.isEmpty || !mounted) return;
      final source = await XFile(paths.first).readAsBytes();
      if (mounted) await _crop(which, source);
    } on PlatformException {
      // người dùng từ chối quyền truy cập ảnh: giữ nguyên
    } catch (_) {
      if (mounted) {
        TSnackBarHelper.showError(
          context,
          message: AppLocalizations.of(context)!.feedPhotoError,
        );
      }
    }
  }

  Future<void> _adjust(_ShopImage which) async {
    final logo = which == _ShopImage.logo;
    var source = logo ? _logoSource : _coverSource;
    final url = logo ? _logoUrl : _coverUrl;
    if (source == null && url != null) {
      setState(() => _loadingImage = true);
      try {
        source = await widget.imageLoader(url);
      } catch (_) {
        if (mounted) {
          TSnackBarHelper.showError(
            context,
            message: AppLocalizations.of(context)!.cropLoadError,
          );
        }
      }
      if (!mounted) return;
      setState(() => _loadingImage = false);
    }
    if (source != null) await _crop(which, source);
  }

  Future<void> _crop(_ShopImage which, Uint8List source) async {
    final l = AppLocalizations.of(context)!;
    final logo = which == _ShopImage.logo;
    final cropped = await ImageCropView.open(
      context,
      source,
      frame: logo ? CropFrame.shopLogo : CropFrame.shopCover,
      title: logo ? l.msLogoCropTitle : l.msCoverCropTitle,
    );
    if (cropped == null || !mounted) return;
    setState(() {
      if (logo) {
        _logoBytes = cropped;
        _logoSource = source;
      } else {
        _coverBytes = cropped;
        _coverSource = source;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final overview = widget.overview;
    final shop = widget.shop;
    final preview = ShopModel(
      id: shop.id,
      name: _name.text.trim().isEmpty ? shop.name : _name.text.trim(),
      accentColor: _accent,
      verificationType: shop.verificationType,
    );
    final accent = ShopLogo.accentOf(preview);
    final stats = overview.stats;
    final code = shop.certificateCode;
    return _MyShopScaffold(
      actions: [
        if (overview.isPublic)
          IconButton(
            key: const ValueKey('my-shop-view-public'),
            tooltip: l.msViewPublic,
            icon: const Icon(AppIcons.visible, color: AppColors.textPrimary),
            onPressed: () => context.push('/shops/${shop.id}'),
          ),
      ],
      bottom: AppBottomActionBar(
        key: const ValueKey('my-shop-save'),
        primaryLabel: l.msSave,
        primaryIcon: AppIcons.check,
        isLoading: widget.saving,
        onPrimary: widget.saving || _loadingImage || !_dirty || !_hoursValid
            ? null
            : _save,
      ),
      body: ListView(
        key: const ValueKey('my-shop-list'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          MyShopHeader(
            shop: preview,
            accent: accent,
            coverUrl: _coverUrl,
            logoUrl: _logoUrl,
            coverBytes: _coverBytes,
            logoBytes: _logoBytes,
            onCoverTap: () => _editImage(_ShopImage.cover),
            onLogoTap: () => _editImage(_ShopImage.logo),
          ),
          if (_loadingImage) ...[
            const SizedBox(height: 8),
            const Center(child: AppLoadingIndicator(dotSize: 6)),
          ],
          const SizedBox(height: 16),
          if (stats != null) ...[
            MyShopStatsRow(
              stats: stats,
              onFollowersTap: () => context.push(ShopFollowersView.path),
            ),
            const SizedBox(height: 16),
          ],
          if (overview.reviewStatus == 'PENDING' && !shop.isVerified)
            MyShopStatusCard(
              key: const ValueKey('my-shop-pending'),
              icon: AppIcons.clock,
              title: l.msPendingTitle,
              body: l.msPendingBody,
              color: AppColors.warning,
              background: AppColors.warningBg,
            )
          else if (overview.reviewStatus == 'REJECTED' && !shop.isVerified)
            MyShopStatusCard(
              key: const ValueKey('my-shop-rejected'),
              icon: AppIcons.block,
              title: l.msRejectedTitle,
              body: l.msRejectedBody(overview.rejectNote ?? ''),
              color: AppColors.error,
              background: AppColors.errorBg,
            )
          else if (shop.isVerified)
            MyShopStatusCard(
              key: const ValueKey('my-shop-verified'),
              title: l.msVerifiedTitle,
              body: code == null
                  ? l.msVerifiedBody
                  : '${l.msVerifiedBody} ${l.msCertificate(code)}',
              color: AppColors.success,
              background: AppColors.successBg,
            )
          else if (overview.verificationStatus == 'PENDING')
            MyShopStatusCard(
              key: const ValueKey('my-shop-verify-pending'),
              icon: AppIcons.clock,
              title: l.msVerifyPendingTitle,
              body: l.msVerifyPendingBody,
              color: AppColors.info,
              background: AppColors.infoBg,
            )
          else if (overview.verificationStatus == 'REJECTED')
            MyShopStatusCard(
              key: const ValueKey('my-shop-verify-rejected'),
              icon: AppIcons.block,
              title: l.msVerifyRejectedTitle,
              body: l.msVerifyRejectedBody(overview.verificationNote ?? ''),
              color: AppColors.error,
              background: AppColors.errorBg,
            )
          else
            MyShopStatusCard(
              icon: AppIcons.info,
              title: l.msUnverifiedTitle,
              body: l.msUnverifiedBody,
              color: AppColors.info,
              background: AppColors.infoBg,
            ),
          if (overview.canRequestVerification)
            MyShopVerificationForm(
              key: myShopVerifyKey,
              saving: widget.saving,
              picker: widget.picker,
              onSubmit: _requestVerification,
            ),
          MyShopSection(
            title: l.msInfoSection,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppLabeledTextField(
                  key: const ValueKey('my-shop-name'),
                  label: l.msName,
                  isRequired: true,
                  enabled: !overview.nameLocked,
                  controller: _name,
                  maxLength: 60,
                  hintText: l.msNameHint,
                  helperText: overview.nameLocked ? l.msNameLocked : null,
                  errorText: _showErrors && !_nameValid
                      ? l.msNameRequired
                      : null,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 14),
                AppLabeledTextField(
                  key: const ValueKey('my-shop-tagline'),
                  label: l.msTagline,
                  controller: _tagline,
                  maxLength: 80,
                  hintText: l.msTaglineHint,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 14),
                AppLabeledTextField(
                  key: const ValueKey('my-shop-description'),
                  label: l.msDescription,
                  controller: _description,
                  maxLength: 1000,
                  minLines: 3,
                  maxLines: 6,
                  hintText: l.msDescriptionHint,
                  helperText: '${_description.text.length}/1000',
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 14),
                AppLabeledTextField(
                  key: const ValueKey('my-shop-address'),
                  label: l.msAddress,
                  controller: _address,
                  maxLength: 120,
                  hintText: l.msAddressHint,
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          MyShopSection(
            key: const ValueKey('my-shop-hours'),
            title: l.msHoursSection,
            subtitle: l.msHoursHint,
            child: MyShopHoursField(
              days: _days,
              open: _open,
              close: _close,
              onDaysChanged: (days) => setState(() {
                _days = days;
                _hoursTouched = true;
              }),
              onOpenChanged: (time) => setState(() {
                _open = time;
                _hoursTouched = true;
              }),
              onCloseChanged: (time) => setState(() {
                _close = time;
                _hoursTouched = true;
              }),
            ),
          ),
          MyShopSection(
            title: l.msColorSection,
            subtitle: l.msColorHint,
            child: MyShopColorField(
              value: _accent,
              onChanged: (value) => setState(() => _accent = value),
            ),
          ),
          _LinkTile(
            key: const ValueKey('my-shop-posters'),
            icon: AppIcons.posterPromo,
            title: l.msPosters,
            subtitle: l.msPostersBody,
            onTap: () => context.push(ShopPostersView.path),
          ),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: AppColors.primaryDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.35,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              AppIcons.chevronRight,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    ),
  );
}
