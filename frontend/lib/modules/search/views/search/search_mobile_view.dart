import 'package:restore/core/routes/profile_path.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/data/models/category_model.dart';
import 'package:restore/shared/utils/filter_categories.dart';
import 'package:restore/modules/category_detail/views/category_detail/category_detail_view.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:restore/modules/trusted_shop/models/trusted_shop_item.dart';
import 'package:restore/modules/trusted_shop/views/shop_detail/shop_detail_view.dart';
import 'package:restore/shared/widgets/search/app_listing_search_bar.dart';

import '../../bloc/search_cubit.dart';
import '../../bloc/search_state.dart';
import '../../models/search_user_item.dart';
import '../../utils/category_matches.dart';
import '../../utils/open_listing_search.dart';
import 'widgets/search_idle_content.dart';
import 'widgets/search_suggestion_list.dart';

class SearchMobileView extends StatefulWidget {
  final String initialQuery;

  const SearchMobileView({super.key, this.initialQuery = ''});

  @override
  State<SearchMobileView> createState() => _SearchMobileViewState();
}

class _SearchMobileViewState extends State<SearchMobileView> {
  static const String _nearbyPath = '/nearby';

  late final _controller = TextEditingController(text: widget.initialQuery);
  final _focusNode = FocusNode();

  /// Danh mục để gợi ý khi gõ đúng tên danh mục; tải lỗi thì không gợi ý
  List<CategoryModel> _categories = const [];

  @override
  void initState() {
    super.initState();
    loadFilterCategories().then((categories) {
      if (mounted) setState(() => _categories = categories);
    });
  }

  /// Mở trang danh mục (kèm danh mục con nếu có) từ gợi ý
  void _openCategory(CategoryMatch match) {
    _focusNode.unfocus();
    context.push(
      CategoryDetailView.location(
        match.parent.id,
        subcategoryId: match.sub?.id,
      ),
      extra: match.parent,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _back() => context.canPop() ? context.pop() : context.go('/home');

  /// Mở trang kết quả; quay lại thì giữ từ khoá trên ô để sửa tiếp
  Future<void> _submit(String keyword) async {
    final query = keyword.trim();
    if (query.isEmpty) return;
    final cubit = context.read<SearchCubit>();
    _setText(query);
    cubit.queryChanged(query);
    _focusNode.unfocus();
    // Tên danh mục ("Sở thích") thì vào thẳng trang danh mục
    final category = await openListingSearch(context, query, fromSearch: true);
    if (!mounted) return;
    // Vào danh mục là duyệt chứ không phải tìm: quay lại thì ô trống để gõ mới
    if (category) {
      _setText('');
      cubit.queryChanged('');
    }
    // Từ khoá vừa tìm đã được lưu vào lịch sử
    cubit.loadHistory();
  }

  /// Mở trang shop từ gợi ý khi đang gõ
  void _openShop(TrustedShopItem item) {
    _focusNode.unfocus();
    context.push(ShopDetailView.location(item.shop.id, name: item.shop.name), extra: item);
  }

  /// Mở trang cá nhân từ gợi ý khi đang gõ
  void _openUser(SearchUserItem user) {
    _focusNode.unfocus();
    context.push(profilePath(id: user.id, username: user.username));
  }

  /// Đưa gợi ý lên ô tìm kiếm để gõ tiếp
  void _fill(String keyword) {
    _setText(keyword);
    context.read<SearchCubit>().queryChanged(keyword);
    _focusNode.requestFocus();
  }

  void _setText(String text) => _controller.value = TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: text.length),
  );

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SearchCubit>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: AppListingSearchBar.editable(
                  onBack: _back,
                  onEdit: _focusNode.requestFocus,
                  input: ListingSearchInput(
                    controller: _controller,
                    focusNode: _focusNode,
                    autofocus: widget.initialQuery.isEmpty,
                    onChanged: cubit.queryChanged,
                    onSubmitted: _submit,
                  ),
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<SearchCubit, SearchState>(
                builder: (context, state) => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: state.isTyping
                      ? SearchSuggestionList(
                          key: const ValueKey('suggestions'),
                          state: state,
                          onSubmit: _submit,
                          onFill: _fill,
                          onRemoveHistory: cubit.removeHistory,
                          onOpenShop: _openShop,
                          onOpenUser: _openUser,
                          categories: matchCategories(
                            _categories,
                            state.query,
                            (name) => name.of(context),
                          ),
                          onOpenCategory: _openCategory,
                        )
                      : SearchIdleContent(
                          key: const ValueKey('idle'),
                          state: state,
                          onSubmit: _submit,
                          onNearMe: () => context.push(_nearbyPath),
                          onRemoveHistory: cubit.removeHistory,
                          onClearHistory: cubit.clearHistory,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
