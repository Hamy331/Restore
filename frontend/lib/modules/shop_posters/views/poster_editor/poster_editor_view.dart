import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/ui/layouts/t_responsive_layout.dart';
import 'package:restore/services/media_picker_service.dart';

import '../../bloc/poster_editor_cubit.dart';
import '../../models/shop_poster.dart';
import '../../models/shop_poster_overview.dart';
import '../../repositories/shop_poster_repository.dart';
import 'poster_editor_mobile_view.dart';

/// Dữ liệu mở trang tạo / sửa poster (truyền qua `extra` của go_router)
class PosterEditorArgs {
  const PosterEditorArgs({required this.limits, this.poster, this.repository});

  final PosterLimits limits;

  /// Poster cần sửa; null = tạo mới
  final ShopPoster? poster;
  final ShopPosterRepository? repository;
}

/// Route `/shop-posters/editor`: tạo hoặc sửa poster rồi gửi duyệt.
/// Trả về true khi đã gửi.
class PosterEditorView extends StatelessWidget {
  const PosterEditorView({super.key, required this.args, this.picker});

  final PosterEditorArgs args;

  /// Thay bộ chọn ảnh khi test
  final MediaPickerService? picker;

  static const String path = '/shop-posters/editor';

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => PosterEditorCubit(
      repository: args.repository ?? ShopPosterRepository(),
      limits: args.limits,
      poster: args.poster,
    ),
    child: TResponsiveLayout(mobile: PosterEditorMobileView(picker: picker)),
  );
}
