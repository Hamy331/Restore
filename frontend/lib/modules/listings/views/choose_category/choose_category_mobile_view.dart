import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/l10n/app_localizations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../bloc/create_listing/create_listing_bloc.dart';
import '../../bloc/create_listing/create_listing_event.dart';
import '../../bloc/create_listing/create_listing_state.dart';
import '../../widgets/category_card.dart';

class ChooseCategoryMobileView extends StatefulWidget {
  const ChooseCategoryMobileView({super.key});

  @override
  State<ChooseCategoryMobileView> createState() =>
      _ChooseCategoryMobileViewState();
}

class _ChooseCategoryMobileViewState extends State<ChooseCategoryMobileView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    // Tạo hiệu ứng Bounce chạy trong 800ms
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.cream, // Nền ngoài cùng là Cream
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
      body: BlocListener<CreateListingBloc, CreateListingState>(
        listenWhen: (previous, current) =>
            previous.categoryId != current.categoryId,
        listener: (context, state) {
          if (state.categoryId.isNotEmpty) {
            context.push('/create-listing/upload-photos');
          }
        },
        child: Column(
          children: [
            const SizedBox(height: 12.0),
            Expanded(
              child: Container(
                width: double.infinity,
                // Cách đều 2 bên một chút để tạo viền cho khối nội dung
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  color: AppColors.surface, // Màu trắng của thẻ chứa danh sách
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32.0),
                    topRight: Radius.circular(32.0),
                  ),
                  // Viền cam/xám mỏng bao quanh phần thẻ trắng
                  border: Border.all(color: AppColors.border, width: 1.0),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32.0),
                    topRight: Radius.circular(32.0),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.only(top: 32.0, bottom: 24.0),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          l10n.chooseCategoryTitle,
                          style: const TextStyle(
                            fontSize: 28.0,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          l10n.chooseCategorySubtitle,
                          style: const TextStyle(
                            fontSize: 15.0,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24.0),
                      const Divider(height: 1, color: AppColors.border),

                      // Bọc các item vào Animation để tạo hiệu ứng nảy
                      _buildAnimatedCard(
                        index: 0,
                        child: CategoryCard(
                          title: l10n.categoryElectronicsTitle,
                          description: l10n.categoryElectronicsDesc,
                          fallbackIcon: Icons.devices,
                          onTap: () => context.read<CreateListingBloc>().add(
                            SelectCategoryEvent(
                              'electronics',
                              l10n.categoryElectronicsTitle,
                            ),
                          ),
                        ),
                      ),
                      _buildAnimatedCard(
                        index: 1,
                        child: CategoryCard(
                          title: l10n.categoryVehiclesTitle,
                          description: l10n.categoryVehiclesDesc,
                          fallbackIcon: Icons.two_wheeler,
                          onTap: () => context.read<CreateListingBloc>().add(
                            SelectCategoryEvent(
                              'vehicles',
                              l10n.categoryVehiclesTitle,
                            ),
                          ),
                        ),
                      ),
                      _buildAnimatedCard(
                        index: 2,
                        child: CategoryCard(
                          title: l10n.categoryFashionTitle,
                          description: l10n.categoryFashionDesc,
                          fallbackIcon: Icons.checkroom,
                          onTap: () => context.read<CreateListingBloc>().add(
                            SelectCategoryEvent(
                              'fashion',
                              l10n.categoryFashionTitle,
                            ),
                          ),
                        ),
                      ),
                      _buildAnimatedCard(
                        index: 3,
                        child: CategoryCard(
                          title: l10n.categoryHomeTitle,
                          description: l10n.categoryHomeDesc,
                          fallbackIcon: Icons.chair,
                          showBottomBorder: false,
                          onTap: () => context.read<CreateListingBloc>().add(
                            SelectCategoryEvent('home', l10n.categoryHomeTitle),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Hàm tạo hiệu ứng trượt từ dưới lên kèm theo Bounce
  Widget _buildAnimatedCard({required int index, required Widget child}) {
    // Delay theo thứ tự index để tạo hiệu ứng chạy nối tiếp nhau (Staggered Animation)
    final delay = index * 0.1;
    final animation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        delay,
        1.0,
        curve: Curves.elasticOut,
      ), // Curve elasticOut tạo độ "nảy" (bounce)
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, childWidget) {
        return Transform.translate(
          // Trượt từ vị trí 100px ở dưới lên 0
          offset: Offset(0, 100 * (1 - animation.value)),
          child: Opacity(
            // Tăng dần độ mờ từ 0 lên 1
            opacity: animation.value.clamp(0.0, 1.0),
            child: childWidget,
          ),
        );
      },
      child: child,
    );
  }
}
