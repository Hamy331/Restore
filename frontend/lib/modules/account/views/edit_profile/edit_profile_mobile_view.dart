import 'package:flutter/material.dart';
import 'package:restore/core/ui/responsive/responsive_content.dart';
import 'package:restore/modules/auth/bloc/auth/auth_bloc.dart';
import 'package:restore/modules/auth/bloc/auth/auth_event.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/media_picker_service.dart';
import '../../../../shared/widgets/app_action_buttons.dart';

import '../../../../shared/widgets/image_crop/image_crop.dart';
import '../../../../shared/widgets/image_crop/image_crop_view.dart';
import '../../bloc/user_profile/user_profile_cubit.dart';
import '../../bloc/user_profile/user_profile_state.dart';
import '../../models/profile_models.dart';
import '../../widgets/profile_header.dart';
import 'edit_profile_view.dart';
import 'widgets/edit_profile_avatar.dart';
import 'widgets/email_change_flow.dart';

/// Khớp `usernamePattern` ở backend (auth.validation.ts).
final _usernamePattern = RegExp(r'^[a-z0-9._]{3,30}$');

/// Số di động Việt Nam như backend (parsePhone): bỏ khoảng trắng, dấu chấm,
/// gạch, ngoặc; +84 / 84 thành 0; đủ 10 số bắt đầu 03, 05, 07, 08, 09.
/// Rỗng trả '' (xoá số), sai định dạng trả null.
String? normalizePhone(String text) {
  final digits = text.replaceAll(RegExp(r'[\s.\-()]'), '');
  if (digits.isEmpty) return '';
  final local = digits.replaceFirst(
    RegExp(r'^(\+84|84)(?=[35789]\d{8}$)'),
    '0',
  );
  return RegExp(r'^0[35789]\d{8}$').hasMatch(local) ? local : null;
}

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
  late final _phone = TextEditingController(text: _profile?.phone ?? '');

  /// URL ảnh đang có trên server; `null` khi chưa có hoặc người dùng xoá.
  late String? _avatarUrl = _profile?.avatarUrl;

  /// Ảnh mới đã cắt (chưa lưu) và ảnh gốc của nó để căn chỉnh lại không bị
  /// mất phần đã cắt.
  Uint8List? _avatarBytes, _sourceBytes;
  String? _uploadedAvatar;
  bool _saving = false, _loadingAvatar = false, _showErrors = false;
  String? _usernameError, _phoneError;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _bio.dispose();
    _phone.dispose();
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
  bool get _usernameValid => _usernamePattern.hasMatch(_username.text.trim());
  bool get _phoneValid => normalizePhone(_phone.text) != null;

  Future<void> _save() async {
    if (_saving || _loadingAvatar) return;
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<UserProfileCubit>();
    setState(() {
      _showErrors = true;
      _usernameError = null;
      _phoneError = null;
      // Số điện thoại nằm ở phần thu gọn: mở ra để thấy lỗi
      if (!_phoneValid) _privateOpen = true;
    });
    if (!_nameValid || !_usernameValid || !_phoneValid) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _saving = true);
    // Chỉ gửi avatarUrl khi đổi hoặc xoá ảnh: URL đang hiển thị đã được ghép
    // origin nên không gửi ngược lại server.
    final changes = <String, dynamic>{
      if (_name.text.trim() != _profile?.fullName)
        'fullName': _name.text.trim(),
      if (_username.text.trim() != _profile?.username)
        'username': _username.text.trim(),
      if (_bio.text.trim() != (_profile?.bio ?? '')) 'bio': _bio.text.trim(),
      if (normalizePhone(_phone.text) case final phone?
          when phone != (_profile?.phone ?? ''))
        'phone': phone.isEmpty ? null : phone,
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
      context.pop();
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
      case ProfileSaveResult.invalidPhone:
        setState(() {
          _saving = false;
          _phoneError = _phoneInvalidText;
          _privateOpen = true;
        });
      case ProfileSaveResult.failed:
        setState(() => _saving = false);
        _error(l.accSaveError);
    }
  }

  bool get _hasChanges =>
      _name.text.trim() != (_profile?.fullName ?? '') ||
      _username.text.trim() != (_profile?.username ?? '') ||
      _bio.text.trim() != (_profile?.bio ?? '') ||
      _phone.text.trim() != (_profile?.phone ?? '') ||
      _avatarBytes != null ||
      _avatarUrl != _profile?.avatarUrl;

  /// Thông tin tài khoản mở sẵn; thông tin riêng tư thu gọn
  bool _accountOpen = true, _privateOpen = false;

  bool get _vi => Localizations.localeOf(context).languageCode == 'vi';

  String get _phoneInvalidText => _vi
      ? 'Số điện thoại không hợp lệ (VD 0901234567).'
      : 'Invalid phone number (e.g. 0901234567).';

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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final vi = Localizations.localeOf(context).languageCode == 'vi';
    String t(String vn, String en) => vi ? vn : en;
    final hasAvatar = _avatarBytes != null || _avatarUrl != null;
    final usernameError =
        _usernameError ??
        (_showErrors && !_usernameValid ? l.accUsernameInvalid : null);
    final email = context.watch<UserProfileCubit>().state.profile?.email ?? '';
    final phoneError =
        _phoneError ?? (_showErrors && !_phoneValid ? _phoneInvalidText : null);
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
                // Ảnh đại diện
                _SectionTitle(t('Ảnh đại diện', 'Profile photo')),
                const SizedBox(height: 12),
                Row(
                  children: [
                    EditProfileAvatar(
                      initials: ProfileHeader.initials(_name.text),
                      bytes: _avatarBytes,
                      url: _avatarUrl,
                      busy: _loadingAvatar,
                      onPick: _pick,
                      onAdjust: hasAvatar ? _adjust : null,
                      onRemove: hasAvatar ? _remove : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t(
                              'Ảnh rõ mặt giúp người mua và người bán tin '
                                  'tưởng nhau hơn.',
                              'A clear photo of your face helps buyers and '
                                  'sellers trust each other.',
                            ),
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.45,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton(
                            key: const ValueKey('edit-profile-upload'),
                            onPressed: _loadingAvatar ? null : _pick,
                            child: Text(t('Tải ảnh lên', 'Upload a photo')),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                      helper: l.accUsernameHelper,
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
                      action: TextButton(
                        key: const ValueKey('edit-profile-email-update'),
                        onPressed: _changeEmail,
                        child: Text(t('Cập nhật', 'Update')),
                      ),
                    ),
                    _Field(
                      fieldKey: 'edit-profile-phone',
                      controller: _phone,
                      label: l.phone,
                      hint: t('VD 0901234567', 'e.g. 0901234567'),
                      maxLength: 16,
                      keyboardType: TextInputType.phone,
                      helper: t(
                        'Người mua gọi cho bạn qua số này khi bạn có tin đang bán.',
                        'Buyers can call you on this number while you have listings for sale.',
                      ),
                      error: phoneError,
                      onChanged: (_) => setState(() => _phoneError = null),
                    ),
                  ],
                ),
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
  });

  final String fieldKey, label;
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
          helperMaxLines: 2,
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
