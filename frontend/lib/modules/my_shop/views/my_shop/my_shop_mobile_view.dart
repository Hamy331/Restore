import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/utils/helpers/t_snackbar_helper.dart';
import 'package:restore/data/models/shop_model.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/plans/views/plans/plans_view.dart';
import 'package:restore/modules/shop_posters/views/shop_posters/shop_posters_view.dart';
import 'package:restore/modules/trusted_shop/widgets/shop_logo.dart';
import 'package:restore/services/media_picker_service.dart';
import 'package:restore/shared/widgets/app_bottom_action_bar.dart';
import 'package:restore/shared/widgets/app_labeled_text_field.dart';
import 'package:restore/shared/widgets/app_option_sheet.dart';
import 'package:restore/shared/widgets/feedback_view.dart';
import 'package:restore/shared/widgets/image_crop/image_crop.dart';
import 'package:restore/shared/widgets/image_crop/image_crop_view.dart';
import 'package:restore/shared/widgets/loading/app_loading_indicator.dart';

import '../../bloc/my_shop_cubit.dart';
import '../../models/my_shop_overview.dart';
import 'my_shop_view.dart';
import 'widgets/my_shop_color_field.dart';
import 'widgets/my_shop_header.dart';
import 'widgets/my_shop_section.dart';
import 'widgets/my_shop_stats.dart';
import 'widgets/my_shop_status_card.dart';

/// Lời báo lỗi theo mã backend khi mở shop / lưu
String myShopError(AppLocalizations l, String code) => switch (code) {
  'SHOP_NAME_LOCKED' => l.msNameLocked,
  'SHOP_PLAN_REQUIRED' => l.msPlanTitle,
  'SHOP_EXISTS' => l.msErrExists,
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
                ? FeedbackView(
                    icon: AppIcons.offline,
                    title: l.msLoadError,
                    message: l.categoryDetailLoadErrorBody,
                    action: FilledButton(
                      onPressed: cubit.load,
                      child: Text(l.retry),
                    ),
                  )
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
        if (overview.canCreate) return _CreateShop(saving: state.saving);
        return _MyShopScaffold(
          body: FeedbackView(
            icon: AppIcons.store,
            title: l.msPlanTitle,
            message: l.msPlanBody,
            action: FilledButton(
              onPressed: () => context.push(PlansView.path),
              child: Text(l.spSeePlans),
            ),
          ),
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
    appBar: AppBar(
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

/// Chưa có shop nhưng đang dùng gói Cửa hàng: đặt tên để mở shop
class _CreateShop extends StatefulWidget {
  const _CreateShop({required this.saving});

  final bool saving;

  @override
  State<_CreateShop> createState() => _CreateShopState();
}

class _CreateShopState extends State<_CreateShop> {
  final _name = TextEditingController();
  final _tagline = TextEditingController();
  final _address = TextEditingController();
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

  Future<void> _create() async {
    final l = AppLocalizations.of(context)!;
    setState(() => _showErrors = true);
    if (!_nameValid) return;
    final error = await context.read<MyShopCubit>().create(
      name: _name.text.trim(),
      tagline: _tagline.text.trim(),
      address: _address.text.trim(),
    );
    if (!mounted) return;
    if (error == null) {
      TSnackBarHelper.showSuccess(context, message: l.msCreated);
    } else {
      TSnackBarHelper.showError(context, message: myShopError(l, error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return _MyShopScaffold(
      bottom: AppBottomActionBar(
        key: const ValueKey('my-shop-create'),
        primaryLabel: l.msCreateAction,
        primaryIcon: AppIcons.store,
        isLoading: widget.saving,
        onPrimary: widget.saving ? null : _create,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          MyShopSection(
            title: l.msCreateTitle,
            subtitle: l.msCreateBody,
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
        ],
      ),
    );
  }
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
    };
  }

  bool get _dirty =>
      _changes.isNotEmpty || _logoBytes != null || _coverBytes != null;

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    setState(() => _showErrors = true);
    if (!_nameValid) return;
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
        if (shop.isVerified)
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
        onPrimary: widget.saving || _loadingImage || !_dirty ? null : _save,
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
            MyShopStatsRow(stats: stats),
            const SizedBox(height: 16),
          ],
          if (!overview.storePlan)
            MyShopStatusCard(
              icon: AppIcons.warning,
              title: l.msPlanExpiredTitle,
              body: l.msPlanExpiredBody,
              color: AppColors.warning,
              background: AppColors.warningBg,
              action: TextButton(
                onPressed: () => context.push(PlansView.path),
                child: Text(l.spSeePlans),
              ),
            ),
          if (shop.isVerified)
            MyShopStatusCard(
              title: l.msVerifiedTitle,
              body: code == null
                  ? l.msVerifiedBody
                  : '${l.msVerifiedBody} ${l.msCertificate(code)}',
              color: AppColors.success,
              background: AppColors.successBg,
            )
          else
            MyShopStatusCard(
              icon: AppIcons.info,
              title: l.msUnverifiedTitle,
              body: l.msUnverifiedBody,
              color: AppColors.info,
              background: AppColors.infoBg,
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
