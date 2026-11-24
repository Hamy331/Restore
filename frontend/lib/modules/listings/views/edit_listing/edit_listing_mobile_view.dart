import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/glass/app_glass_background.dart';
import 'package:restore/shared/widgets/loading/app_loading_indicator.dart';
import '../../bloc/create_listing/create_listing_bloc.dart';
import '../../bloc/create_listing/create_listing_event.dart';
import '../../bloc/create_listing/create_listing_state.dart';
import '../../models/create_listing_step.dart';
import 'package:restore/shared/widgets/app_load_error_view.dart';

/// Tải tin cần sửa; xong thì thay trang này bằng bước Thông tin sản phẩm
/// (chuyên mục giữ nguyên nên bỏ qua bước 1), lỗi thì cho thử lại
class EditListingMobileView extends StatefulWidget {
  const EditListingMobileView({super.key, required this.listingId});

  final String listingId;

  @override
  State<EditListingMobileView> createState() => _EditListingMobileViewState();
}

class _EditListingMobileViewState extends State<EditListingMobileView> {
  @override
  void initState() {
    super.initState();
    _open();
  }

  void _open() => context.read<CreateListingBloc>().add(
    ListingEditOpened(widget.listingId),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocConsumer<CreateListingBloc, CreateListingState>(
      listenWhen: (previous, current) =>
          previous.openEditStatus != current.openEditStatus,
      listener: (context, state) {
        if (state.openEditStatus == RequestStatus.success) {
          context.pushReplacement(CreateListingStep.details.path);
        }
      },
      builder: (context, state) => AppGlassBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(AppIcons.back, color: AppColors.textPrimary),
              onPressed: () => context.pop(),
            ),
            title: Text(
              l10n.editListingTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          body: Center(
            child: state.openEditStatus == RequestStatus.failure
                ? AppLoadErrorView(title: l10n.editLoadFailed, onRetry: _open)
                : const AppLoadingIndicator(),
          ),
        ),
      ),
    );
  }
}
