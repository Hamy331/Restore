import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../services/media_picker_service.dart';
import '../../bloc/user_profile/user_profile_cubit.dart';
import 'edit_profile_mobile_view.dart';

/// Tải ảnh đại diện hiện có về để căn chỉnh lại
typedef AvatarLoader = Future<Uint8List> Function(String url);

Future<Uint8List> _loadNetworkImage(String url) async {
  final data = await NetworkAssetBundle(Uri.parse(url)).load(url);
  return data.buffer.asUint8List();
}

/// Trang chỉnh sửa hồ sơ (ảnh đại diện, tên, tên người dùng, giới thiệu).
/// Dùng chung [UserProfileCubit] của tab Tài khoản để lưu xong là cập nhật ngay.
class EditProfileView extends StatelessWidget {
  const EditProfileView({
    super.key,
    required this.cubit,
    this.picker,
    this.avatarLoader,
  });

  static const String path = '/profile/edit';

  final UserProfileCubit cubit;
  final MediaPickerService? picker;
  final AvatarLoader? avatarLoader;

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: cubit,
    child: EditProfileMobileView(
      picker: picker,
      avatarLoader: avatarLoader ?? _loadNetworkImage,
    ),
  );
}
