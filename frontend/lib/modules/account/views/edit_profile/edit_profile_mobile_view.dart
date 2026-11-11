import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/utils/helpers/t_snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/media_picker_service.dart';
import '../../../../shared/widgets/app_bottom_action_bar.dart';
import '../../../../shared/widgets/app_labeled_text_field.dart';
import '../../../../shared/widgets/image_crop/image_crop.dart';
import '../../../../shared/widgets/image_crop/image_crop_view.dart';
import '../../bloc/user_profile/user_profile_cubit.dart';
import '../../bloc/user_profile/user_profile_state.dart';
import '../../models/profile_models.dart';
import '../../widgets/profile_header.dart';
import 'edit_profile_view.dart';
import 'widgets/edit_profile_avatar.dart';
import 'widgets/edit_profile_section.dart';

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
    });
  }

  void _remove() => setState(() {
    _avatarUrl = null;
    _avatarBytes = null;
    _sourceBytes = null;
  });

  void _error(String message) =>
      TSnackBarHelper.showError(context, message: message);

  bool get _nameValid => _name.text.trim().isNotEmpty;
  bool get _usernameValid => _usernamePattern.hasMatch(_username.text.trim());

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<UserProfileCubit>();
    setState(() {
      _showErrors = true;
      _usernameError = null;
    });
    if (!_nameValid || !_usernameValid) return;
    setState(() => _saving = true);
    // Chỉ gửi avatarUrl khi đổi hoặc xoá ảnh: URL đang hiển thị đã được ghép
    // origin nên không gửi ngược lại server.
    final changes = <String, dynamic>{
      'fullName': _name.text.trim(),
      'username': _username.text.trim(),
      'bio': _bio.text.trim(),
    };
    final bytes = _avatarBytes;
    if (bytes != null) {
      try {
        changes['avatarUrl'] = await cubit.uploadAvatar(bytes);
      } catch (_) {
        if (!mounted) return;
        setState(() => _saving = false);
        _error(l.accAvatarUploadError);
        return;
      }
    } else if (_avatarUrl == null && _profile?.avatarUrl != null) {
      changes['avatarUrl'] = null;
    }
    final result = await cubit.update(changes);
    if (!mounted) return;
    switch (result) {
      case ProfileSaveResult.saved:
        TSnackBarHelper.showSuccess(context, message: l.accSaved);
        context.pop();
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final hasAvatar = _avatarBytes != null || _avatarUrl != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
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
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      bottomNavigationBar: AppBottomActionBar(
        key: const ValueKey('edit-profile-save'),
        primaryLabel: l.accSave,
        primaryIcon: AppIcons.check,
        isLoading: _saving,
        onPrimary: _saving || _loadingAvatar ? null : _save,
      ),
      body: ListView(
        key: const ValueKey('edit-profile-list'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          EditProfileSection(
            title: l.accAvatarSection,
            child: EditProfileAvatar(
              initials: ProfileHeader.initials(
                _name.text.isEmpty ? (_profile?.fullName ?? '') : _name.text,
              ),
              bytes: _avatarBytes,
              url: _avatarUrl,
              busy: _loadingAvatar,
              onPick: _pick,
              onAdjust: hasAvatar ? _adjust : null,
              onRemove: hasAvatar ? _remove : null,
            ),
          ),
          EditProfileSection(
            title: l.accInfoSection,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppLabeledTextField(
                  key: const ValueKey('edit-profile-name'),
                  label: l.accDisplayName,
                  isRequired: true,
                  controller: _name,
                  maxLength: 80,
                  hintText: l.accDisplayNameHint,
                  errorText: _showErrors && !_nameValid
                      ? l.accNameRequired
                      : null,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                AppLabeledTextField(
                  key: const ValueKey('edit-profile-username'),
                  label: l.accUsername,
                  isRequired: true,
                  controller: _username,
                  maxLength: 30,
                  prefixText: '@',
                  helperText: l.accUsernameHelper,
                  errorText:
                      _usernameError ??
                      (_showErrors && !_usernameValid
                          ? l.accUsernameInvalid
                          : null),
                  onChanged: (_) => setState(() => _usernameError = null),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                AppLabeledTextField(
                  key: const ValueKey('edit-profile-bio'),
                  label: l.accBio,
                  controller: _bio,
                  maxLength: 300,
                  minLines: 3,
                  maxLines: 5,
                  hintText: l.accBioHint,
                  helperText: '${_bio.text.length}/300',
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
