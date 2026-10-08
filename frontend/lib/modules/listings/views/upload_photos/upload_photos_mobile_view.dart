import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:dotted_border/dotted_border.dart'; // Import đúng package
import 'package:restore/l10n/app_localizations.dart';

import '../../../../core/constants/app_colors.dart';
import '../../bloc/create_listing/create_listing_bloc.dart';
import '../../bloc/create_listing/create_listing_event.dart';
import '../../bloc/create_listing/create_listing_state.dart';
import '../../widgets/listing_progress_bar.dart';

class UploadPhotosMobileView extends StatefulWidget {
  const UploadPhotosMobileView({super.key});

  @override
  State<UploadPhotosMobileView> createState() => _UploadPhotosMobileViewState();
}

class _UploadPhotosMobileViewState extends State<UploadPhotosMobileView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    // Tạo animation controller cho hiệu ứng nảy (Bounce)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onContinue(BuildContext context, CreateListingState state) {
    context.read<CreateListingBloc>().add(ValidateStep1Event());
    if (state.isTitleValid && state.images.isNotEmpty) {
      // TODO: Điều hướng sang trang Step 2 (Giá & Mô tả)
      // context.push('/create-listing/step-2');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.cream, // Nền cream giống Figma
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (context.canPop()) context.pop();
          },
        ),
        title: Text(
          l10n.createListing,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: BlocBuilder<CreateListingBloc, CreateListingState>(
        builder: (context, state) {
          return Column(
            children: [
              const SizedBox(height: 12.0),
              // Thanh tiến trình nằm ngoài khung trắng
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _buildAnimatedItem(
                  index: 0,
                  child: const ListingProgressBar(
                    currentStep: 1,
                    totalSteps: 2,
                  ),
                ),
              ),
              const SizedBox(height: 16.0),

              // Khối chứa nội dung chính nền trắng bo góc
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32.0),
                      topRight: Radius.circular(32.0),
                    ),
                    border: Border.all(color: AppColors.border, width: 1.0),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32.0),
                      topRight: Radius.circular(32.0),
                    ),
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 32.0,
                      ),
                      children: [
                        // --- PHẦN ẢNH SẢN PHẨM ---
                        _buildAnimatedItem(
                          index: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.productPhotosInfo(state.images.length),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildImageGrid(context, state, l10n),
                              const SizedBox(height: 8),
                              Text(
                                l10n.coverImageHint,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // --- PHẦN TÊN SẢN PHẨM ---
                        _buildAnimatedItem(
                          index: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.productNameLabel,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                initialValue: state.title,
                                onChanged: (val) => context
                                    .read<CreateListingBloc>()
                                    .add(UpdateTitleEvent(val)),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppColors.surface,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: state.title.isNotEmpty
                                          ? AppColors.primary
                                          : AppColors.border,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: AppColors.primary,
                                      width: 2,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: AppColors.error,
                                    ),
                                  ),
                                  errorText:
                                      (state.showError && !state.isTitleValid)
                                      ? l10n.productNameMinLengthError
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // --- PHẦN DANH MỤC (Readonly) ---
                        _buildAnimatedItem(
                          index: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.categoryLabel,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () => context
                                    .pop(), // Nhấn để quay lại đổi danh mục
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        state.categoryName.isEmpty
                                            ? 'Đang tải...'
                                            : state.categoryName,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.keyboard_arrow_down,
                                        color: AppColors.textSecondary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // --- PHẦN TÌNH TRẠNG ---
                        _buildAnimatedItem(
                          index: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.conditionLabel,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _buildConditionBtn(
                                    context,
                                    state,
                                    'NEW',
                                    'Mới',
                                  ),
                                  const SizedBox(width: 12),
                                  _buildConditionBtn(
                                    context,
                                    state,
                                    'USED',
                                    'Đã qua sử dụng',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),

                        // --- NÚT TIẾP TỤC ---
                        _buildAnimatedItem(
                          index: 5,
                          child: ElevatedButton(
                            onPressed: () => _onContinue(context, state),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              l10n.continueBtn,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- HÀM TẠO LƯỚI ẢNH VÀ NÚT THÊM ẢNH ---
  Widget _buildImageGrid(
    BuildContext context,
    CreateListingState state,
    AppLocalizations l10n,
  ) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        // Danh sách ảnh đã chọn
        ...state.images.asMap().entries.map((entry) {
          int idx = entry.key;
          bool isCover = idx == 0;
          return GestureDetector(
            onTap: () =>
                context.read<CreateListingBloc>().add(SetCoverImageEvent(idx)),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCover ? AppColors.primary : AppColors.border,
                      width: isCover ? 2 : 1,
                    ),
                    color: AppColors.cream,
                  ),
                  child: Center(
                    child: Text('Ảnh $idx'), // TODO: Thay bằng Image thật
                  ),
                ),
                if (isCover)
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '1',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: -6,
                  right: -6,
                  child: GestureDetector(
                    onTap: () => context.read<CreateListingBloc>().add(
                      RemoveImageEvent(idx),
                    ),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black87,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),

        // --- FIX LỖI DOTTED BORDER Ở ĐÂY ---
        if (state.images.length < 10)
          GestureDetector(
            onTap: () {
              context.read<CreateListingBloc>().add(
                AddImagesEvent([
                  'mock_image_${DateTime.now().millisecond}.png',
                ]),
              );
            },
            child: DottedBorder(
              // Sử dụng Options theo chuẩn mới của package[cite: 52]
              options: const RoundedRectDottedBorderOptions(
                color: AppColors.primary,
                strokeWidth: 1.5,
                dashPattern: [6, 4],
                radius: Radius.circular(16),
              ),
              child: SizedBox(
                width: 76, // 80 - 4 (độ dày viền)
                height: 76,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_photo_alternate_outlined,
                      color: AppColors.primaryDark,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.addPhotos,
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
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

  // --- HÀM TẠO NÚT TÌNH TRẠNG ---
  Widget _buildConditionBtn(
    BuildContext context,
    CreateListingState state,
    String value,
    String label,
  ) {
    final isSelected = state.condition == value;
    return InkWell(
      onTap: () =>
          context.read<CreateListingBloc>().add(UpdateConditionEvent(value)),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // --- HÀM TẠO HIỆU ỨNG BOUNCE TỪ DƯỚI LÊN ---
  Widget _buildAnimatedItem({required int index, required Widget child}) {
    final delay = index * 0.1;
    final animation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(delay, 1.0, curve: Curves.elasticOut),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, childWidget) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - animation.value)),
          child: Opacity(
            opacity: animation.value.clamp(0.0, 1.0),
            child: childWidget,
          ),
        );
      },
      child: child,
    );
  }
}
