import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_action_buttons.dart';
import 'package:restore/shared/widgets/glass/app_glass_background.dart';
import 'package:restore/shared/widgets/loading/app_loading_indicator.dart';
import '../../bloc/create_listing/create_listing_bloc.dart';
import '../../bloc/create_listing/create_listing_event.dart';
import '../../bloc/create_listing/create_listing_state.dart';
import '../../models/create_listing_step.dart';

/// Tải tin cần sửa; xong thì thay trang này bằng bước 2 (chuyên mục giữ
/// nguyên nên bỏ qua bước 1), lỗi thì cho thử lại
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
          context.pushReplacement(CreateListingStep.basicInfo.path);
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
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          AppIcons.error,
                          size: 40,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.editLoadFailed,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        AppPrimaryActionButton(
                          label: l10n.retry,
                          icon: AppIcons.refresh,
                          onPressed: _open,
                        ),
                      ],
                    ),
                  )
                : const AppLoadingIndicator(),
          ),
        ),
      ),
    );
  }
}
