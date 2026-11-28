import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:restore/core/ui/responsive/responsive_content.dart';
import 'package:restore/data/models/shop_opening_hours.dart';
import 'package:restore/modules/my_shop/models/my_shop_overview.dart';
import 'package:restore/modules/my_shop/repositories/my_shop_repository.dart';
import 'package:restore/modules/my_shop/views/my_shop/my_shop_view.dart';
import 'package:restore/modules/my_shop/views/my_shop/widgets/my_shop_hours_field.dart';
import 'package:restore/modules/auth/bloc/auth/auth_bloc.dart';
import 'package:restore/modules/auth/bloc/auth/auth_event.dart';
import 'package:restore/modules/auth/utils/auth_validators.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/media_picker_service.dart';
import '../../../../shared/widgets/app_action_buttons.dart';
import '../../../../shared/widgets/app_option_sheet.dart';

import '../../../../shared/widgets/image_crop/image_crop.dart';
import '../../../../shared/widgets/image_crop/image_crop_view.dart';
import '../../bloc/user_profile/user_profile_cubit.dart';
import '../../bloc/user_profile/user_profile_state.dart';
import '../../models/profile_models.dart';
import '../../widgets/profile_header.dart';
import 'edit_profile_view.dart';
import 'widgets/edit_profile_avatar.dart';
import 'widgets/edit_profile_banner.dart';
import 'widgets/email_change_flow.dart';
import 'widgets/phone_verify_flow.dart';
import 'package:restore/core/routes/profile_path.dart';
import 'package:restore/core/utils/helpers/phone_number.dart';
import 'package:restore/services/phone_otp_service.dart';

export 'package:restore/core/utils/helpers/phone_number.dart'
    show normalizePhone;

enum _CoverAction { pick, adjust, remove }

class EditProfileMobileView extends StatefulWidget {
  const EditProfileMobileView({
    super.key,
    required this.avatarLoader,
    this.picker,
  });

  final AvatarLoader avatarLoader;
  final MediaPickerService? picker;

  @override
  State<EditProfileMobileView> createState() => _EditProfileMobileViewState();
}

class _EditProfileMobileViewState extends State<EditProfileMobileView> {
  late final ProfileData? _profile = context
      .read<UserProfileCubit>()
      .state
      .profile;
  late final _name = TextEditingController(text: _profile?.fullName);
  late final _username = TextEditingController(text: _profile?.username);
  late final _bio = TextEditingController(text: _profile?.bio ?? '');

  /// URL ảnh đang có trên server; `null` khi chưa có hoặc người dùng xoá.
  late String? _avatarUrl = _profile?.avatarUrl;

  /// Ảnh mới đã cắt (chưa lưu) và ảnh gốc của nó để căn chỉnh lại không bị
  /// mất phần đã cắt.
  Uint8List? _avatarBytes, _sourceBytes;
  String? _uploadedAvatar;
  bool _saving = false, _loadingAvatar = false, _showErrors = false;
  String? _usernameError;

  // Thông tin doanh nghiệp: chỉ khi đã lên Cửa hàng, tải shop của mình riêng
  late final bool _isShop = _profile?.shopStatus != null;
  MyShopOverview? _shop;
  bool _shopFailed = false;
  final _contactPhone = TextEditingController(),
      _businessEmail = TextEditingController(),
      _website = TextEditingController(),
      _address = TextEditingController();
  // Ảnh bìa: chỉ Cửa hàng đổi được (lưu cùng shop qua PATCH /shops/me)
  String? _coverUrl, _uploadedCover;
  Uint8List? _coverBytes, _coverSource;
  bool _loadingCover = false;
  Set<int> _days = {};
  TimeOfDay _open = const TimeOfDay(hour: 8, minute: 0),
      _close = const TimeOfDay(hour: 21, minute: 0);
  bool _hoursTouched = false, _businessOpen = true;
  String? _contactPhoneError, _businessEmailError, _websiteError;

  @override
  void initState() {
    super.initState();
    if (_isShop) _loadShop();
  }

  Future<void> _loadShop() async {
    setState(() => _shopFailed = false);
    try {
      final overview = await MyShopRepository().load();
      if (!mounted) return;
      final shop = overview.shop;
      setState(() {
        _shop = overview;
        if (shop == null) return;
        _coverUrl = shop.coverUrl;
        _contactPhone.text = shop.contactPhone ?? '';
        _businessEmail.text = shop.businessEmail ?? '';
        _website.text = shop.website ?? '';
        _address.text = shop.address ?? '';
        _days = {for (final item in shop.openingHours) item.day};
        _open = _time(shop.openingHours.firstOrNull?.open, 8);
        _close = _time(shop.openingHours.firstOrNull?.close, 21);
      });
    } catch (_) {
      if (mounted) setState(() => _shopFailed = true);
    }
  }

  static TimeOfDay _time(String? value, int fallbackHour) {
    final parts = value?.split(':');
    if (parts == null || parts.length != 2) {
      return TimeOfDay(hour: fallbackHour, minute: 0);
    }
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  List<ShopOpeningDay> get _hours => [
    for (final day in _days.toList()..sort())
      ShopOpeningDay(
        day: day,
        open: MyShopHoursField.format(_open),
        close: MyShopHoursField.format(_close),
      ),
  ];

  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  /// Website lưu kèm https:// nếu người dùng gõ thiếu
  static String _withScheme(String text) {
    final value = text.trim();
    if (value.isEmpty ||
        RegExp(r'^https?://', caseSensitive: false).hasMatch(value)) {
      return value;
    }
    return 'https://$value';
  }

  bool get _contactPhoneValid => normalizePhone(_contactPhone.text) != null;
  bool get _businessEmailValid =>
      _businessEmail.text.trim().isEmpty ||
      _emailPattern.hasMatch(_businessEmail.text.trim());
  bool get _websiteValid =>
      _website.text.trim().isEmpty ||
      RegExp(
        r'^https?://[^\s.]+\.\S+$',
        caseSensitive: false,
      ).hasMatch(_withScheme(_website.text));
  bool get _hoursValid =>
      _days.isEmpty || MyShopHoursField.valid(_open, _close);
  bool get _businessValid =>
      _contactPhoneValid && _businessEmailValid && _websiteValid && _hoursValid;

  /// Trường doanh nghiệp đã đổi so với shop đang lưu (PATCH /shops/me)
  Map<String, dynamic> get _shopChanges {
    final shop = _shop?.shop;
    if (shop == null) return const {};
    String? orNull(String text) => text.trim().isEmpty ? null : text.trim();
    final phone = normalizePhone(_contactPhone.text);
    final website = orNull(_withScheme(_website.text));
    return {
      if (phone != null && (phone.isEmpty ? null : phone) != shop.contactPhone)
        'contactPhone': phone.isEmpty ? null : phone,
      if (orNull(_businessEmail.text) != shop.businessEmail)
        'businessEmail': orNull(_businessEmail.text),
      if (website != shop.website) 'website': website,
      if (orNull(_address.text) != shop.address)
        'address': orNull(_address.text),
      if (_hoursTouched && !listEquals(_hours, shop.openingHours))
        'openingHours': _days.isEmpty
            ? null
            : [for (final item in _hours) item.toJson()],
    };
  }

  /// Kiểm tra mục doanh nghiệp trước khi lưu; sai thì mở mục ra để thấy lỗi
  bool _checkBusiness() {
    if (_shop?.shop == null) return true;
    final vi = _vi;
    setState(() {
      _contactPhoneError = _contactPhoneValid ? null : _phoneInvalidText;
      _businessEmailError = _businessEmailValid
          ? null
          : (vi ? 'Email không hợp lệ.' : 'Invalid email.');
      _websiteError = _websiteValid
          ? null
          : (vi
                ? 'Website không hợp lệ (VD https://shop.vn).'
                : 'Invalid website (e.g. https://shop.com).');
      if (!_businessValid) _businessOpen = true;
    });
    return _businessValid;
  }

  /// Lưu mục doanh nghiệp; false nếu lỗi (đã báo)
  Future<bool> _saveShop(Map<String, dynamic> changes) async {
    try {
      final repository = MyShopRepository();
      final body = {...changes};
      final cover = _coverBytes;
      if (cover != null) {
        _uploadedCover ??= await repository.uploadImage(cover);
        body['coverUrl'] = _uploadedCover;
      } else if (_coverUrl == null && _shop?.shop?.coverUrl != null) {
        body['coverUrl'] = null;
      }
      if (body.isEmpty) return true;
      final overview = await repository.update(body);
      if (mounted) {
        setState(() {
          _shop = overview;
          _coverUrl = overview.shop?.coverUrl;
          _coverBytes = _coverSource = _uploadedCover = null;
        });
      }
      return true;
    } catch (_) {
      if (mounted) {
        _error(
          _vi
              ? 'Không lưu được thông tin doanh nghiệp, thử lại sau.'
              : 'Could not save business details, try again.',
        );
      }
      return false;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _bio.dispose();
    _contactPhone.dispose();
    _businessEmail.dispose();
    _website.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    if (_loadingAvatar || _saving) return;
    setState(() => _loadingAvatar = true);
    try {
      final paths = await (widget.picker ?? MediaPickerService()).pickImages(
        source: MediaSource.gallery,
        limit: 1,
      );
      if (paths.isEmpty || !mounted) return;
      final source = await XFile(paths.first).readAsBytes();
      if (mounted) await _crop(source);
    } on PlatformException {
      // người dùng từ chối quyền truy cập ảnh: giữ nguyên
    } catch (_) {
      if (mounted) _error(AppLocalizations.of(context)!.feedPhotoError);
    } finally {
      if (mounted) setState(() => _loadingAvatar = false);
    }
  }

  /// Căn chỉnh lại: dùng ảnh gốc vừa chọn, hoặc tải ảnh đang dùng về.
  Future<void> _adjust() async {
    var source = _sourceBytes;
    final url = _avatarUrl;
    if (source == null && url != null) {
      setState(() => _loadingAvatar = true);
      try {
        source = await widget.avatarLoader(url);
      } catch (_) {
        if (mounted) _error(AppLocalizations.of(context)!.cropLoadError);
      }
      if (!mounted) return;
      setState(() => _loadingAvatar = false);
    }
    if (source != null) await _crop(source);
  }

  Future<void> _crop(Uint8List source) async {
    final cropped = await ImageCropView.open(
      context,
      source,
      frame: CropFrame.avatar,
      title: AppLocalizations.of(context)!.accAvatarCropTitle,
    );
    if (cropped == null || !mounted) return;
    setState(() {
      _avatarBytes = cropped;
      _sourceBytes = source;
      _uploadedAvatar = null;
    });
  }

  void _remove() => setState(() {
    _avatarUrl = null;
    _avatarBytes = null;
    _sourceBytes = null;
    _uploadedAvatar = null;
  });

  void _error(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  bool get _nameValid => _name.text.trim().isNotEmpty;
  // Tên đang dùng (có thể đặt trước khi có luật mới) không kiểm lại, chỉ kiểm khi đổi
  bool get _usernameValid =>
      _username.text.trim() == _profile?.username ||
      AuthValidators.usernamePattern.hasMatch(_username.text.trim());

  Future<void> _save() async {
    if (_saving || _loadingAvatar) return;
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<UserProfileCubit>();
    setState(() {
      _showErrors = true;
      _usernameError = null;
    });
    final businessOk = _checkBusiness();
    if (!_nameValid || !_usernameValid || !businessOk) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _saving = true);
    final shopChanges = _shopChanges, coverChanged = _coverDirty;
    if ((shopChanges.isNotEmpty || coverChanged) &&
        !await _saveShop(shopChanges)) {
      if (mounted) setState(() => _saving = false);
      return;
    }
    if (!mounted) return;
    // Chỉ gửi avatarUrl khi đổi hoặc xoá ảnh: URL đang hiển thị đã được ghép
    // origin nên không gửi ngược lại server.
    final changes = <String, dynamic>{
      if (_name.text.trim() != _profile?.fullName)
        'fullName': _name.text.trim(),
      if (_username.text.trim() != _profile?.username)
        'username': _username.text.trim(),
      if (_bio.text.trim() != (_profile?.bio ?? '')) 'bio': _bio.text.trim(),
    };
    final bytes = _avatarBytes;
    if (bytes != null) {
      try {
        _uploadedAvatar ??= await cubit.uploadAvatar(bytes);
        if (!mounted || cubit.isClosed) return;
        changes['avatarUrl'] = _uploadedAvatar;
      } catch (_) {
        if (!mounted) return;
        setState(() => _saving = false);
        _error(l.accAvatarUploadError);
        return;
      }
    } else if (_avatarUrl == null && _profile?.avatarUrl != null) {
      changes['avatarUrl'] = null;
    }
    if (changes.isEmpty) {
      // Chỉ đổi thông tin doanh nghiệp: vẫn báo đã lưu
      context.pop(shopChanges.isNotEmpty || coverChanged ? true : null);
      return;
    }
    final result = await cubit.update(changes);
    if (!mounted) return;
    switch (result) {
      case ProfileSaveResult.saved:
        context.pop(true);
      case ProfileSaveResult.usernameTaken:
        setState(() {
          _saving = false;
          _usernameError = l.accUsernameTaken;
        });
      case ProfileSaveResult.invalidUsername:
        setState(() {
          _saving = false;
          _usernameError = l.accUsernameInvalid;
        });
      case ProfileSaveResult.usernameChangeTooSoon:
        setState(() {
          _saving = false;
          _usernameError = l.accUsernameChangeTooSoon;
        });
      case ProfileSaveResult.invalidPhone || ProfileSaveResult.failed:
        setState(() => _saving = false);
        _error(l.accSaveError);
    }
  }

  bool get _hasChanges =>
      _name.text.trim() != (_profile?.fullName ?? '') ||
      _username.text.trim() != (_profile?.username ?? '') ||
      _bio.text.trim() != (_profile?.bio ?? '') ||
      _avatarBytes != null ||
      _avatarUrl != _profile?.avatarUrl ||
      _shopDirty;

  /// Ảnh bìa shop vừa chọn mới hoặc vừa xoá (chưa lưu)
  bool get _coverDirty =>
      _coverBytes != null ||
      (_coverUrl == null && _shop?.shop?.coverUrl != null);

  String _t(String vn, String en) => _vi ? vn : en;

  /// Bấm ảnh bìa: Cửa hàng đổi / căn chỉnh / xoá; người dùng thường được nhắc
  /// rằng ảnh bìa chỉ dành cho Cửa hàng
  Future<void> _onBannerTap() async {
    if (_saving) return;
    if (!_isShop) {
      final goShop = await showAppOptionSheet<bool>(
        context,
        title: _t('Ảnh bìa dành cho Cửa hàng', 'Cover photo is for Shops'),
        subtitle: _t(
          'Tài khoản thường dùng bìa mặc định. Lên Cửa hàng để đặt ảnh bìa riêng.',
          'Regular accounts use the default cover. Become a Shop to set your own.',
        ),
        icon: Icons.storefront_outlined,
        options: [
          AppSheetOption(
            true,
            AppLocalizations.of(context)!.accCreateStore,
            icon: Icons.storefront_outlined,
          ),
        ],
      );
      if (goShop == true && mounted) context.push(MyShopView.path);
      return;
    }
    if (_shop?.shop == null) {
      if (_shopFailed) await _loadShop();
      return;
    }
    final l = AppLocalizations.of(context)!;
    final hasCover = _coverBytes != null || _coverUrl != null;
    final action = hasCover
        ? await showAppOptionSheet<_CoverAction>(
            context,
            title: l.msChangeCover,
            options: [
              AppSheetOption(
                _CoverAction.pick,
                l.msImageNew,
                icon: AppIcons.addPhoto,
              ),
              AppSheetOption(
                _CoverAction.adjust,
                l.msImageAdjust,
                icon: AppIcons.zoomIn,
              ),
              AppSheetOption(
                _CoverAction.remove,
                l.msImageRemove,
                icon: AppIcons.delete,
              ),
            ],
          )
        : _CoverAction.pick;
    if (!mounted || action == null) return;
    switch (action) {
      case _CoverAction.pick:
        await _pickCover();
      case _CoverAction.adjust:
        await _adjustCover();
      case _CoverAction.remove:
        setState(() => _coverUrl = _coverBytes = _coverSource = null);
    }
  }

  Future<void> _pickCover() async {
    setState(() => _loadingCover = true);
    try {
      final paths = await (widget.picker ?? MediaPickerService()).pickImages(
        source: MediaSource.gallery,
        limit: 1,
      );
      if (paths.isEmpty || !mounted) return;
      final source = await XFile(paths.first).readAsBytes();
      if (mounted) await _cropCover(source);
    } on PlatformException {
      // người dùng từ chối quyền truy cập ảnh: giữ nguyên
    } catch (_) {
      if (mounted) _error(AppLocalizations.of(context)!.feedPhotoError);
    } finally {
      if (mounted) setState(() => _loadingCover = false);
    }
  }

  Future<void> _adjustCover() async {
    var source = _coverSource;
    final url = _coverUrl;
    if (source == null && url != null) {
      setState(() => _loadingCover = true);
      try {
        source = await widget.avatarLoader(url);
      } catch (_) {
        if (mounted) _error(AppLocalizations.of(context)!.cropLoadError);
      }
      if (!mounted) return;
      setState(() => _loadingCover = false);
    }
    if (source != null) await _cropCover(source);
  }

  Future<void> _cropCover(Uint8List source) async {
    final cropped = await ImageCropView.open(
      context,
      source,
      frame: CropFrame.shopCover,
      title: AppLocalizations.of(context)!.msCoverCropTitle,
    );
    if (cropped == null || !mounted) return;
    setState(() {
      _coverBytes = cropped;
      _coverSource = source;
      _uploadedCover = null;
    });
  }

  /// Có đổi ở mục doanh nghiệp (kể cả đang gõ dở / sai định dạng)
  bool get _shopDirty {
    final shop = _shop?.shop;
    if (shop == null) return false;
    return _coverDirty ||
        _contactPhone.text.trim() != (shop.contactPhone ?? '') ||
        _businessEmail.text.trim() != (shop.businessEmail ?? '') ||
        _website.text.trim() != (shop.website ?? '') ||
        _address.text.trim() != (shop.address ?? '') ||
        (_hoursTouched && !listEquals(_hours, shop.openingHours));
  }

  /// Thông tin tài khoản mở sẵn; thông tin riêng tư thu gọn
  bool _accountOpen = true, _privateOpen = false;

  bool get _vi => Localizations.localeOf(context).languageCode == 'vi';

  String get _phoneInvalidText => _vi
      ? 'Số điện thoại không hợp lệ (VD 0901234567).'
      : 'Invalid phone number (e.g. 0901234567).';

  /// Thêm, đổi hoặc xác minh số điện thoại: chỉ lưu số đã xác minh bằng OTP
  /// (lưu ngay, không cần bấm Lưu thay đổi). [phone] là số điền sẵn.
  Future<void> _verifyPhone(String? phone) async {
    final otp = FirebasePhoneOtpService();
    if (!otp.supported) {
      _error(
        _vi
            ? 'Hãy xác minh số điện thoại trên ứng dụng Android hoặc trang web.'
            : 'Verify your phone number in the Android app or on the website.',
      );
      return;
    }
    final cubit = context.read<UserProfileCubit>();
    final verified = await showPhoneVerifyFlow(context, cubit, phone, otp: otp);
    if (verified == null || !mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            _vi ? 'Đã xác minh số $verified' : 'Verified $verified',
          ),
        ),
      );
  }

  /// Dòng số điện thoại (như dòng email): chưa có số thì nút Thêm số; có số
  /// thì hiện số, dấu đã xác minh và nút Cập nhật (chưa xác minh thì Xác minh)
  Widget _phoneRow(
    ProfileData? live,
    AppLocalizations l,
    String Function(String, String) t,
  ) {
    final phone = live?.phone ?? '';
    final verified = live?.phoneVerified == true;
    if (phone.isEmpty) {
      return Padding(
        key: const ValueKey('edit-profile-phone-row'),
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.phone,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Transform.translate(
              // Chữ nút thẳng mép trái với nhãn phía trên
              offset: const Offset(-8, 0),
              child: AppLinkButton(
                key: const ValueKey('edit-profile-phone-add'),
                icon: Icons.add,
                label: t('Thêm số điện thoại', 'Add number'),
                onPressed: _saving ? null : () => _verifyPhone(null),
              ),
            ),
          ],
        ),
      );
    }
    return _ReadOnlyRow(
      fieldKey: 'edit-profile-phone-row',
      label: l.phone,
      value: phone,
      verified: verified,
      caption: verified
          ? t(
              'Người mua gọi cho bạn qua số này khi bạn có tin đang bán.',
              'Buyers can call you on this number while you have listings for sale.',
            )
          : t(
              'Chưa xác minh. Xác minh để nhận huy hiệu đã xác minh.',
              'Not verified. Verify to get the verified badge.',
            ),
      action: AppLinkButton(
        key: const ValueKey('edit-profile-phone-update'),
        label: verified ? t('Cập nhật', 'Update') : t('Xác minh', 'Verify'),
        onPressed: _saving ? null : () => _verifyPhone(phone),
      ),
    );
  }

  /// Đổi email: bảng 2 bước (email mới + mật khẩu, rồi mã OTP gửi tới email
  /// mới). Email đổi ngay trên server nên báo luôn cho phần đăng nhập.
  Future<void> _changeEmail() async {
    final cubit = context.read<UserProfileCubit>();
    final email = await showEmailChangeFlow(context, cubit);
    if (email == null || !mounted) return;
    final profile = cubit.state.profile;
    if (profile != null) {
      try {
        context.read<AuthBloc>().add(
          ProfileIdentityUpdated(
            id: profile.id,
            fullName: profile.fullName,
            username: profile.username,
            avatarUrl: profile.avatarUrl,
            email: email,
            phone: profile.phone,
          ),
        );
      } catch (_) {
        // Trang mở riêng (test) không có AuthBloc
      }
    }
    setState(() {});
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            _vi ? 'Đã đổi email thành $email' : 'Email changed to $email',
          ),
        ),
      );
  }

  /// Mục "Thông tin doanh nghiệp" luôn hiện. Chưa lên Cửa hàng: chỉ có lời
  /// giới thiệu và nút Lên Cửa hàng. Shop: tên + mã số thuế lấy từ hồ sơ xác
  /// minh (chỉ xem), còn lại là liên hệ công khai sửa được
  Widget _businessSection(String Function(String, String) t) {
    final overview = _shop, shop = overview?.shop;
    final verified = shop?.isVerified ?? false;
    // Chưa lên Cửa hàng: vẫn hiện đủ các trường nhưng khoá lại
    final locked = !_isShop;
    final notProvided = t('Chưa có', 'Not provided');
    void clear(VoidCallback reset) => setState(reset);
    return _Section(
      key: const ValueKey('edit-profile-business'),
      title: t('Thông tin doanh nghiệp', 'Business details'),
      icon: verified
          ? Icons.visibility_outlined
          : Icons.visibility_off_outlined,
      caption: locked
          ? t(
              'Lên Cửa hàng để điền và hiện thông tin này cho người mua',
              'Become a Shop to fill in and show these details to buyers',
            )
          : verified
          ? t(
              'Hiện ở mục Liên hệ trên trang shop của bạn',
              'Shown under Contact details on your shop page',
            )
          : t(
              'Người mua chưa thấy thông tin này cho tới khi shop được xác minh',
              "Buyers can't see these details until your shop is verified",
            ),
      open: _businessOpen,
      onToggle: () => setState(() => _businessOpen = !_businessOpen),
      children: [
        if (!locked && overview == null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: _shopFailed
                  ? AppLinkButton(
                      icon: Icons.refresh,
                      label: t(
                        'Không tải được thông tin shop. Thử lại',
                        "Couldn't load your shop. Retry",
                      ),
                      onPressed: _loadShop,
                    )
                  : const CircularProgressIndicator(),
            ),
          )
        else if (locked || shop != null) ...[
          if (locked)
            _Notice(
              icon: Icons.storefront_outlined,
              text: t(
                'Bạn chưa có Cửa hàng. Lên Cửa hàng để điền các thông tin này.',
                "You don't have a shop yet. Become a Shop to fill these in.",
              ),
              action: AppLinkButton(
                key: const ValueKey('edit-profile-become-shop'),
                label: AppLocalizations.of(context)!.accCreateStore,
                onPressed: () => context.push(MyShopView.path),
              ),
            )
          else if (!verified)
            _Notice(
              icon: Icons.verified_outlined,
              text: t(
                'Xác minh shop để người mua thấy các thông tin này.',
                'Verify your shop so buyers can see these details.',
              ),
              action: AppLinkButton(
                key: const ValueKey('edit-profile-verify-shop'),
                label: t('Xác minh shop', 'Verify your shop'),
                onPressed: () => context.push(MyShopView.path),
              ),
            ),
          _ReadOnlyRow(
            fieldKey: 'edit-profile-business-name',
            label: t('Tên doanh nghiệp', 'Company name'),
            value: overview?.businessName ?? notProvided,
            verified: verified && overview?.businessName != null,
          ),
          _ReadOnlyRow(
            fieldKey: 'edit-profile-tax-code',
            label: t(
              'Mã số doanh nghiệp / mã số thuế',
              'Business registration number',
            ),
            value: overview?.taxCode ?? notProvided,
            verified: verified && overview?.taxCode != null,
            caption: locked
                ? null
                : t(
                    'Lấy từ hồ sơ xác minh shop. Muốn đổi, gửi lại hồ sơ xác minh.',
                    'From your shop verification. Resubmit verification to change it.',
                  ),
          ),
          _Field(
            fieldKey: 'edit-profile-contact-phone',
            enabled: !locked,
            controller: _contactPhone,
            label: t('Số điện thoại liên hệ', 'Contact number'),
            hint: t('VD 0901234567', 'e.g. 0901234567'),
            maxLength: 16,
            keyboardType: TextInputType.phone,
            helper: t(
              'Trống thì dùng số điện thoại tài khoản.',
              'Leave empty to use your account phone number.',
            ),
            error: _contactPhoneError,
            onChanged: (_) => clear(() => _contactPhoneError = null),
          ),
          _Field(
            fieldKey: 'edit-profile-business-email',
            enabled: !locked,
            controller: _businessEmail,
            label: t('Email doanh nghiệp', 'Business email'),
            hint: 'shop@example.com',
            maxLength: 120,
            keyboardType: TextInputType.emailAddress,
            error: _businessEmailError,
            onChanged: (_) => clear(() => _businessEmailError = null),
          ),
          _Field(
            fieldKey: 'edit-profile-website',
            enabled: !locked,
            controller: _website,
            label: t('Website', 'Your website'),
            hint: 'https://',
            maxLength: 300,
            keyboardType: TextInputType.url,
            error: _websiteError,
            onChanged: (_) => clear(() => _websiteError = null),
          ),
          _Field(
            fieldKey: 'edit-profile-business-address',
            enabled: !locked,
            controller: _address,
            label: t('Địa chỉ doanh nghiệp', 'Business address'),
            hint: t(
              'VD 12 Lê Lợi, Phường Hải Châu, Đà Nẵng',
              'e.g. 12 Le Loi, Hai Chau, Da Nang',
            ),
            maxLength: 120,
            onChanged: (_) => setState(() {}),
          ),
          Text(
            t('Giờ mở cửa', 'Operating hours'),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          if (locked)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                notProvided,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            MyShopHoursField(
              key: const ValueKey('edit-profile-hours'),
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
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final vi = Localizations.localeOf(context).languageCode == 'vi';
    String t(String vn, String en) => vi ? vn : en;
    final hasAvatar = _avatarBytes != null || _avatarUrl != null;
    final usernameError =
        _usernameError ??
        (_showErrors && !_usernameValid ? l.accUsernameInvalid : null);
    final liveProfile = context.watch<UserProfileCubit>().state.profile;
    final email = liveProfile?.email ?? '';
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: const Icon(AppIcons.back, color: AppColors.textPrimary),
            onPressed: _saving ? null : () => context.pop(),
          ),
          centerTitle: true,
          title: Text(
            l.accEditTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        bottomNavigationBar: ColoredBox(
          color: AppColors.surface,
          child: SafeArea(
            top: false,
            child: Align(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: AppPrimaryActionButton(
                    key: const ValueKey('edit-profile-save'),
                    label: l.saveChanges,
                    isLoading: _saving,
                    onPressed: _saving || _loadingAvatar || !_hasChanges
                        ? null
                        : _save,
                  ),
                ),
              ),
            ),
          ),
        ),
        body: ResponsiveContent(
          maxWidth: 680,
          padding: EdgeInsets.zero,
          child: AbsorbPointer(
            absorbing: _saving,
            child: ListView(
              key: const ValueKey('edit-profile-list'),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                // Ảnh bìa (chỉ Cửa hàng đổi được); ảnh đại diện đè lên mép dưới
                EditProfileBanner(
                  editable: _isShop,
                  url: _coverUrl,
                  bytes: _coverBytes,
                  busy:
                      _loadingCover ||
                      (_isShop && _shop == null && !_shopFailed),
                  onTap: _onBannerTap,
                  changeLabel: l.msChangeCover,
                  lockedLabel: t('Chỉ dành cho Cửa hàng', 'Shops only'),
                  avatar: EditProfileAvatar(
                    initials: ProfileHeader.initials(_name.text),
                    bytes: _avatarBytes,
                    url: _avatarUrl,
                    busy: _loadingAvatar,
                    onPick: _pick,
                    onAdjust: hasAvatar ? _adjust : null,
                    onRemove: hasAvatar ? _remove : null,
                  ),
                ),
                const SizedBox(height: 24),
                // Thông tin tài khoản (hiện trên hồ sơ công khai)
                _Section(
                  key: const ValueKey('edit-profile-account'),
                  title: t('Thông tin tài khoản', 'Account details'),
                  icon: Icons.visibility_outlined,
                  caption: t(
                    'Hiện trên hồ sơ công khai của bạn',
                    'This info appears on your public profile',
                  ),
                  open: _accountOpen,
                  onToggle: () => setState(() => _accountOpen = !_accountOpen),
                  children: [
                    _Field(
                      fieldKey: 'edit-profile-username',
                      controller: _username,
                      label: l.accUsername,
                      prefix: '@',
                      maxLength: 30,
                      helper:
                          '${t('Hồ sơ công khai', 'Public profile')}: '
                          '${kIsWeb ? Uri.base.origin : ''}'
                          '${profilePath(id: _profile?.id ?? '', username: _username.text.trim())}\n'
                          '${l.accUsernameHelper}',
                      error: usernameError,
                      onChanged: (_) => setState(() => _usernameError = null),
                    ),
                    _Field(
                      fieldKey: 'edit-profile-name',
                      controller: _name,
                      label: l.accDisplayName,
                      hint: l.accDisplayNameHint,
                      maxLength: 80,
                      error: _showErrors && !_nameValid
                          ? l.accNameRequired
                          : null,
                      onChanged: (_) => setState(() {}),
                    ),
                    _Field(
                      fieldKey: 'edit-profile-bio',
                      controller: _bio,
                      label: l.accBio,
                      hint: l.accBioHint,
                      maxLength: 300,
                      showCounter: true,
                      multiline: true,
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Thông tin riêng tư (chỉ mình người dùng thấy)
                _Section(
                  key: const ValueKey('edit-profile-private'),
                  title: t('Thông tin riêng tư', 'Private details'),
                  icon: AppIcons.lock,
                  caption: t('Chỉ mình bạn thấy', 'Only you can see this'),
                  open: _privateOpen,
                  onToggle: () => setState(() => _privateOpen = !_privateOpen),
                  children: [
                    _ReadOnlyRow(
                      fieldKey: 'edit-profile-email-row',
                      label: l.email,
                      value: email.isEmpty
                          ? l.accNotProvided
                          : maskEmail(email),
                      verified: email.isNotEmpty,
                      caption: t(
                        'Dùng để đăng nhập. Đổi email cần mã xác nhận gửi tới email mới.',
                        'Used to sign in. Changing it needs a code sent to the new email.',
                      ),
                      action: AppLinkButton(
                        key: const ValueKey('edit-profile-email-update'),
                        label: t('Cập nhật', 'Update'),
                        onPressed: _changeEmail,
                      ),
                    ),
                    _phoneRow(liveProfile, l, t),
                  ],
                ),
                const SizedBox(height: 8),
                _businessSection(t),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Che bớt phần trước @ của email: giữ 2 ký tự đầu và 2 ký tự cuối
/// (VD `22****59@student.edu.vn`), tên quá ngắn thì chỉ giữ ký tự đầu.
String maskEmail(String email) {
  final at = email.indexOf('@');
  if (at <= 0) return email;
  final name = email.substring(0, at), domain = email.substring(at);
  if (name.length <= 4) return '${name[0]}***$domain';
  return '${name.substring(0, 2)}****${name.substring(name.length - 2)}$domain';
}

/// Ô nhắc nền xanh nhạt đầu mục: icon, lời nhắc và nút link
class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text, required this.action});
  final IconData icon;
  final String text;
  final Widget action;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
    decoration: BoxDecoration(
      color: AppColors.actionSoft,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(icon, size: 22, color: AppColors.actionPrimaryDark),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 4),
        action,
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
  );
}

/// Nhóm thông tin thu gọn / mở ra: tiêu đề, một dòng ghi chú có icon (ai thấy
/// được) và mũi tên bên phải
class _Section extends StatelessWidget {
  const _Section({
    super.key,
    required this.title,
    required this.icon,
    required this.caption,
    required this.open,
    required this.onToggle,
    required this.children,
  });

  final String title, caption;
  final IconData icon;
  final bool open;
  final VoidCallback onToggle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(title),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(icon, size: 15, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            caption,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                open ? Icons.expand_less : Icons.expand_more,
                color: AppColors.textPrimary,
              ),
            ],
          ),
        ),
      ),
      if (open) ...[const SizedBox(height: 8), ...children],
    ],
  );
}

/// Ô nhập có nhãn nổi, viền mảnh, lỗi / gợi ý bên dưới
class _Field extends StatelessWidget {
  const _Field({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.maxLength,
    this.hint,
    this.prefix,
    this.helper,
    this.error,
    this.showCounter = false,
    this.multiline = false,
    this.keyboardType,
    this.onChanged,
    this.enabled = true,
  });

  final String fieldKey, label;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextEditingController controller;
  final int maxLength;
  final String? hint, prefix, helper, error;
  final bool showCounter, multiline;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        key: ValueKey(fieldKey),
        controller: controller,
        enabled: enabled,
        onChanged: onChanged,
        maxLength: maxLength,
        minLines: multiline ? 3 : 1,
        maxLines: multiline ? 6 : 1,
        keyboardType: keyboardType,
        textInputAction: multiline
            ? TextInputAction.newline
            : TextInputAction.next,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixText: prefix,
          helperText: error == null ? helper : null,
          helperMaxLines: 4,
          errorText: error,
          errorMaxLines: 2,
          alignLabelWithHint: multiline,
          counterText: showCounter ? null : '',
          filled: false,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: border(AppColors.border),
          enabledBorder: border(AppColors.border),
          focusedBorder: border(AppColors.actionPrimary),
        ),
      ),
    );
  }
}

/// Dòng chỉ xem (email, số điện thoại tài khoản)
class _ReadOnlyRow extends StatelessWidget {
  const _ReadOnlyRow({
    required this.fieldKey,
    required this.label,
    required this.value,
    this.caption,
    this.verified = false,
    this.action,
  });

  final String fieldKey, label, value;
  final String? caption;
  final bool verified;

  /// Nút bên phải dòng (VD Cập nhật email)
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    key: ValueKey(fieldKey),
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            // Giá trị + dấu xác minh bên trái, nút (nếu có) sát mép phải
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (verified) ...[
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.check_circle_outline,
                      size: 17,
                      color: AppColors.success,
                    ),
                  ],
                ],
              ),
            ),
            ?action,
          ],
        ),
        if (caption != null) ...[
          const SizedBox(height: 2),
          Text(
            caption!,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    ),
  );
}
