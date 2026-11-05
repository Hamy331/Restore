import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_icons.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../services/media_picker_service.dart';
import '../../../../../shared/widgets/app_local_image.dart';
import '../../../bloc/user_profile/user_profile_cubit.dart';
import '../../../bloc/user_profile/user_profile_state.dart';
import '../../../models/profile_models.dart';
import '../../../widgets/profile_header.dart';

/// Khớp `usernamePattern` ở backend (auth.validation.ts).
final _usernamePattern = RegExp(r'^[a-z0-9._]{3,30}$');

Future<void> showEditProfileDialog(
  BuildContext context,
  UserProfileCubit cubit,
) async {
  final profile = cubit.state.profile;
  if (profile == null) return;
  await showDialog<void>(
    context: context,
    builder: (_) => EditProfileDialog(profile: profile, cubit: cubit),
  );
}

class EditProfileDialog extends StatefulWidget {
  const EditProfileDialog({
    super.key,
    required this.profile,
    required this.cubit,
    this.picker,
  });
  final ProfileData profile;
  final UserProfileCubit cubit;
  final MediaPickerService? picker;

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final form = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.profile.fullName);
  late final username = TextEditingController(text: widget.profile.username);
  late final bio = TextEditingController(text: widget.profile.bio ?? '');

  /// URL đã có trên server; ảnh mới chọn nằm ở [localAvatar] cho tới khi lưu.
  late String? avatarUrl = widget.profile.avatarUrl;
  String? localAvatar;
  bool saving = false;
  String? usernameError;

  @override
  void dispose() {
    name.dispose();
    username.dispose();
    bio.dispose();
    super.dispose();
  }

  Future<void> pickAvatar() async {
    try {
      final images = await (widget.picker ?? MediaPickerService()).pickImages(
        source: MediaSource.gallery,
        limit: 1,
      );
      if (mounted && images.isNotEmpty) {
        setState(() => localAvatar = images.first);
      }
    } catch (_) {
      if (mounted) _notice(AppLocalizations.of(context)!.feedPhotoError);
    }
  }

  void _notice(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> save() async {
    final l = AppLocalizations.of(context)!;
    setState(() => usernameError = null);
    if (!form.currentState!.validate()) return;
    setState(() => saving = true);
    // Chỉ gửi avatarUrl khi đổi ảnh hoặc xoá ảnh: URL đang hiển thị đã được
    // ghép origin nên không gửi ngược lại server.
    final changes = <String, dynamic>{
      'fullName': name.text.trim(),
      'username': username.text.trim(),
      'bio': bio.text.trim(),
    };
    if (localAvatar != null) {
      try {
        changes['avatarUrl'] = await widget.cubit.uploadAvatar(localAvatar!);
      } catch (_) {
        if (!mounted) return;
        setState(() => saving = false);
        _notice(l.accAvatarUploadError);
        return;
      }
    } else if (avatarUrl == null && widget.profile.avatarUrl != null) {
      changes['avatarUrl'] = null;
    }
    final result = await widget.cubit.update(changes);
    if (!mounted) return;
    switch (result) {
      case ProfileSaveResult.saved:
        Navigator.pop(context);
      case ProfileSaveResult.usernameTaken:
        setState(() {
          saving = false;
          usernameError = l.accUsernameTaken;
        });
      case ProfileSaveResult.invalidUsername:
        setState(() {
          saving = false;
          usernameError = l.accUsernameInvalid;
        });
      case ProfileSaveResult.failed:
        setState(() => saving = false);
        _notice(l.accSaveError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final hasAvatar = localAvatar != null || avatarUrl != null;
    return AlertDialog(
      title: Text(l.accEditTitle),
      content: Form(
        key: form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.background,
                child: ClipOval(
                  child: localAvatar != null
                      ? AppLocalImage(path: localAvatar!, width: 80, height: 80)
                      : avatarUrl != null
                      ? AppLocalImage(path: avatarUrl!, width: 80, height: 80)
                      : Text(
                          ProfileHeader.initials(widget.profile.fullName),
                          style: const TextStyle(
                            fontSize: 24,
                            color: AppColors.textSecondary,
                          ),
                        ),
                ),
              ),
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: saving ? null : pickAvatar,
                    icon: const Icon(AppIcons.addPhoto, size: 18),
                    label: Text(l.accChangeAvatar),
                  ),
                  if (hasAvatar)
                    TextButton(
                      onPressed: saving
                          ? null
                          : () => setState(() {
                              localAvatar = null;
                              avatarUrl = null;
                            }),
                      child: Text(l.accRemoveAvatar),
                    ),
                ],
              ),
              TextFormField(
                controller: name,
                maxLength: 80,
                decoration: InputDecoration(labelText: l.accDisplayName),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? l.accNameRequired : null,
              ),
              TextFormField(
                controller: username,
                maxLength: 30,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: l.accUsername,
                  prefixText: '@',
                  errorText: usernameError,
                  errorMaxLines: 2,
                ),
                validator: (value) =>
                    _usernamePattern.hasMatch((value ?? '').trim())
                    ? null
                    : l.accUsernameInvalid,
              ),
              TextFormField(
                controller: bio,
                maxLength: 300,
                maxLines: 3,
                decoration: InputDecoration(labelText: l.accBio),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        TextButton(
          onPressed: saving ? null : save,
          child: saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l.accSave),
        ),
      ],
    );
  }
}
