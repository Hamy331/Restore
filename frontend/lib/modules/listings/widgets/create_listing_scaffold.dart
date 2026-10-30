import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/utils/helpers/t_snackbar_helper.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/animations/fade_slide_in.dart';
import 'package:restore/shared/widgets/app_size_reporter.dart';
import 'package:restore/shared/widgets/app_step_indicator.dart';
import 'package:restore/shared/widgets/glass/app_glass_background.dart';
import 'package:restore/shared/widgets/glass/app_glass_scroll_header.dart';
import 'package:restore/core/constants/app_icons.dart';
import '../bloc/create_listing/create_listing_bloc.dart';
import '../bloc/create_listing/create_listing_event.dart';
import '../bloc/create_listing/create_listing_state.dart';
import '../models/create_listing_step.dart';

/// Khung chung cho các bước đăng tin: nền kính mờ, AppBar, nút Lưu nháp,
/// thanh tiến trình cố định phía trên, nội dung cuộn (xuất hiện lần lượt)
/// và thanh nút cuối trang.
///
/// Đầu trang (AppBar + thanh bước) nổi trên nội dung: khi cuộn, nội dung
/// trượt xuống dưới lớp kính mờ thay vì bị một khối đặc che đi, đồng thời
/// thanh bước thu gọn lại cho đỡ chiếm chỗ.
class CreateListingScaffold extends StatefulWidget {
  final String title;
  final CreateListingStep step;
  final List<Widget> children;
  final Widget? bottomBar;
  final bool showSaveDraft;
  final EdgeInsetsGeometry contentPadding;

  const CreateListingScaffold({
    super.key,
    required this.title,
    required this.step,
    required this.children,
    this.bottomBar,
    this.showSaveDraft = true,
    this.contentPadding = const EdgeInsets.fromLTRB(16, 4, 16, 24),
  });

  @override
  State<CreateListingScaffold> createState() => _CreateListingScaffoldState();
}

class _CreateListingScaffoldState extends State<CreateListingScaffold> {
  /// Quãng cuộn (px) để lớp kính đầu trang hiện rõ hoàn toàn
  static const double _glassFadeDistance = 32;

  /// Ngưỡng thu gọn / mở lại thanh bước (khác nhau để không bị nhấp nháy)
  static const double _compactAt = 56;
  static const double _expandAt = 16;

  final _scrollController = ScrollController();
  final _glassProgress = ValueNotifier<double>(0);
  bool _compact = false;

  /// Chiều cao đầu trang lúc mở rộng, dùng làm khoảng đệm trên của nội dung
  double? _headerHeight;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _glassProgress.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    _glassProgress.value = (offset / _glassFadeDistance).clamp(0.0, 1.0);
    final compact = _compact ? offset > _expandAt : offset > _compactAt;
    if (compact != _compact) setState(() => _compact = compact);
  }

  void _onHeaderSize(Size size) {
    // Chỉ lấy chiều cao lớn nhất lúc mở rộng (bỏ qua lúc đang thu gọn hay
    // đang chạy animation) để khoảng đệm của nội dung không bị giật
    if (!mounted || _compact) return;
    if (_headerHeight != null && size.height <= _headerHeight!) return;
    setState(() => _headerHeight = size.height);
  }

  void _onBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  void _onSaveDraftChanged(BuildContext context, CreateListingState state) {
    // Nhiều bước cùng nằm trong stack nên chỉ trang đang hiển thị báo kết quả
    if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;
    final l10n = AppLocalizations.of(context)!;
    if (state.saveDraftStatus == RequestStatus.success) {
      TSnackBarHelper.showSuccess(context, message: l10n.draftSaved);
    } else if (state.saveDraftStatus == RequestStatus.failure) {
      TSnackBarHelper.showError(context, message: l10n.draftSaveFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final step = widget.step;
    final media = MediaQuery.of(context);
    // Ước lượng cho khung hình đầu tiên, sau đó dùng chiều cao đo được
    final headerHeight =
        _headerHeight ?? media.padding.top + kToolbarHeight + 120;

    return BlocListener<CreateListingBloc, CreateListingState>(
      listenWhen: (previous, current) =>
          previous.saveDraftStatus != current.saveDraftStatus,
      listener: _onSaveDraftChanged,
      child: AppGlassBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          body: Stack(
            children: [
              // Builder để lấy padding dưới đã tính cả thanh nút kính mờ
              // (extendBody cho nội dung cuộn xuyên qua thanh nút)
              Positioned.fill(
                child: Builder(
                  builder: (context) => ListView(
                    controller: _scrollController,
                    padding: widget.contentPadding.add(
                      EdgeInsets.only(
                        top: headerHeight,
                        bottom: MediaQuery.paddingOf(context).bottom,
                      ),
                    ),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    children: [
                      for (var i = 0; i < widget.children.length; i++)
                        FadeSlideIn(index: i, child: widget.children[i]),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AppGlassScrollHeader(
                  progress: _glassProgress,
                  child: AppSizeReporter(
                    onSize: _onHeaderSize,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppBar(
                          backgroundColor: Colors.transparent,
                          surfaceTintColor: Colors.transparent,
                          elevation: 0,
                          scrolledUnderElevation: 0,
                          centerTitle: false,
                          leading: IconButton(
                            icon: const Icon(
                              AppIcons.back,
                              color: AppColors.textPrimary,
                            ),
                            tooltip: MaterialLocalizations.of(
                              context,
                            ).backButtonTooltip,
                            onPressed: () => _onBack(context),
                          ),
                          title: Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          actions: [
                            if (widget.showSaveDraft)
                              _SaveDraftButton(label: l10n.saveDraft),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: AppStepIndicator(
                            currentStep: step.number,
                            stepTitle: step.title(l10n),
                            stepLabels: CreateListingStep.shortTitles(l10n),
                            compact: _compact,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: widget.bottomBar,
        ),
      ),
    );
  }
}

/// Báo kích thước của [child] sau mỗi lần layout (khi thay đổi)
class _SaveDraftButton extends StatelessWidget {
  final String label;
  const _SaveDraftButton({required this.label});

  @override
  Widget build(BuildContext context) {
    final isSaving = context.select(
      (CreateListingBloc bloc) =>
          bloc.state.saveDraftStatus == RequestStatus.loading,
    );
    // Nút nổi bật: nền trắng đặc, viền ấm, icon lưu và bóng nhẹ
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextButton.icon(
          onPressed: isSaving
              ? null
              : () => context.read<CreateListingBloc>().add(
                  const DraftSaveRequested(),
                ),
          style: TextButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primaryDark,
            disabledForegroundColor: AppColors.primaryDark,
            shape: StadiumBorder(
              side: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.45),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            minimumSize: const Size(0, 38),
          ),
          icon: isSaving
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryDark,
                  ),
                )
              : const Icon(AppIcons.saveDraft, size: 17),
          label: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
