import 'package:flutter/material.dart';
import 'package:restore/core/ui/responsive/responsive_content.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:restore/core/config/dev_plan_override.dart';
import 'package:restore/data/models/enums/subscription_plan.dart';
import 'package:restore/modules/my_shop/views/my_shop/my_shop_view.dart';

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
import 'widgets/edit_profile_field_page.dart';

/// Khớp `usernamePattern` ở backend (auth.validation.ts).
final _usernamePattern = RegExp(r'^[a-z0-9._]{3,30}$');

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

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _bio.dispose();
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

  Future<void> _save() async {
    if (_saving || _loadingAvatar) return;
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<UserProfileCubit>();
    setState(() {
      _showErrors = true;
      _usernameError = null;
    });
    if (!_nameValid || !_usernameValid) return;
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
      case ProfileSaveResult.failed:
        setState(() => _saving = false);
        _error(l.accSaveError);
    }
  }

  Future<void> _editField({
    required TextEditingController controller,
    required String title,
    required String fieldKey,
    required int maxLength,
    String? hint,
    String? helper,
    String? Function(String)? validator,
    bool multiline = false,
  }) async {
    final value = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => EditProfileFieldPage(
          title: title,
          value: controller.text,
          fieldKey: fieldKey,
          maxLength: maxLength,
          hint: hint,
          helper: helper,
          validator: validator,
          multiline: multiline,
        ),
      ),
    );
    if (value == null || !mounted) return;
    setState(() {
      controller.text = value;
      if (controller == _username) _usernameError = null;
    });
  }

  bool get _hasChanges =>
      _name.text.trim() != (_profile?.fullName ?? '') ||
      _username.text.trim() != (_profile?.username ?? '') ||
      _bio.text.trim() != (_profile?.bio ?? '') ||
      _avatarBytes != null ||
      _avatarUrl != _profile?.avatarUrl;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final hasAvatar = _avatarBytes != null || _avatarUrl != null;
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
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  child: EditProfileAvatar(
                    initials: ProfileHeader.initials(_name.text),
                    bytes: _avatarBytes,
                    url: _avatarUrl,
                    busy: _loadingAvatar,
                    onPick: _pick,
                    onAdjust: hasAvatar ? _adjust : null,
                    onRemove: hasAvatar ? _remove : null,
                  ),
                ),
                _ProfileInfoRow(
                  fieldKey: 'edit-profile-name-row',
                  icon: AppIcons.user,
                  label: l.accDisplayName,
                  value: _name.text,
                  placeholder: l.accDisplayNameHint,
                  error: _showErrors && !_nameValid ? l.accNameRequired : null,
                  onTap: () => _editField(
                    controller: _name,
                    title: l.accDisplayName,
                    fieldKey: 'edit-profile-name',
                    maxLength: 80,
                    hint: l.accDisplayNameHint,
                    validator: (value) =>
                        value.isEmpty ? l.accNameRequired : null,
                  ),
                ),
                _ProfileInfoRow(
                  fieldKey: 'edit-profile-username-row',
                  icon: AppIcons.followUser,
                  label: l.accUsername,
                  value: _username.text.isEmpty ? '' : '@${_username.text}',
                  placeholder: l.accUsername,
                  error:
                      _usernameError ??
                      (_showErrors && !_usernameValid
                          ? l.accUsernameInvalid
                          : null),
                  onTap: () => _editField(
                    controller: _username,
                    title: l.accUsername,
                    fieldKey: 'edit-profile-username',
                    maxLength: 30,
                    helper: l.accUsernameHelper,
                    validator: (value) => _usernamePattern.hasMatch(value)
                        ? null
                        : l.accUsernameInvalid,
                  ),
                ),
                _ProfileInfoRow(
                  fieldKey: 'edit-profile-bio-row',
                  icon: AppIcons.edit,
                  label: l.accBio,
                  value: _bio.text,
                  placeholder: l.accBioHint,
                  onTap: () => _editField(
                    controller: _bio,
                    title: l.accBio,
                    fieldKey: 'edit-profile-bio',
                    maxLength: 300,
                    hint: l.accBioHint,
                    multiline: true,
                  ),
                ),
                _ProfileInfoRow(
                  fieldKey: 'edit-profile-email-row',
                  icon: AppIcons.mail,
                  label: l.email,
                  value: _profile?.email ?? '',
                  placeholder: l.accNotProvided,
                  caption: l.accRegisteredEmailHint,
                ),
                _ProfileInfoRow(
                  fieldKey: 'edit-profile-phone-row',
                  icon: AppIcons.categoryPhone,
                  label: l.phone,
                  value: _profile?.phone ?? '',
                  placeholder: l.accNotProvided,
                  caption: l.accContactReadOnly,
                ),
                ValueListenableBuilder<SubscriptionPlan>(
                  valueListenable: DevPlanOverride.plan,
                  builder: (context, plan, _) => Column(
                    children: [
                      _ProfileInfoRow(
                        fieldKey: 'edit-profile-plan-row',
                        icon: AppIcons.pro,
                        label: l.plansCurrent,
                        value: plan.label(l),
                        placeholder: '',
                      ),
                      if (plan == SubscriptionPlan.shop)
                        _ProfileInfoRow(
                          fieldKey: 'edit-profile-shop-row',
                          icon: AppIcons.shop,
                          label: l.quickActionShopManage,
                          value: _profile?.storefront.name ?? '',
                          placeholder: l.accShopDetailsHint,
                          onTap: () => context.push(MyShopView.path),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.fieldKey,
    required this.icon,
    required this.label,
    required this.value,
    required this.placeholder,
    this.caption,
    this.error,
    this.onTap,
  });

  final String fieldKey;
  final IconData icon;
  final String label, value, placeholder;
  final String? caption, error;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const SizedBox(
        height: 6,
        width: double.infinity,
        child: ColoredBox(color: Color(0xFFF6F7F9)),
      ),
      Material(
        color: AppColors.surface,
        child: InkWell(
          key: ValueKey(fieldKey),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(icon, size: 22, color: const Color(0xFF9CA3AF)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        value.isEmpty ? placeholder : value,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: value.isEmpty
                              ? const Color(0xFF9CA3AF)
                              : AppColors.textSecondary,
                        ),
                      ),
                      if (caption != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          caption!,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      if (error != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          error!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Icon(
                    onTap == null ? AppIcons.lock : AppIcons.chevronRight,
                    size: 18,
                    color: const Color(0xFFB6BCC5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
