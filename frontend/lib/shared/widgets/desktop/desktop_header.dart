import 'package:restore/shared/widgets/search/app_listing_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/blocs/language/language_bloc.dart';
import 'package:restore/core/blocs/language/language_event.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_dimesions.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/constants/app_images.dart' show AppImages;
import 'package:restore/core/theme/app_header_palette.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/account/views/account/widgets/account_menu.dart'
    show confirmLogout;
import 'package:restore/modules/account/widgets/profile_header.dart';
import 'package:restore/modules/auth/bloc/auth/auth_bloc.dart';
import 'package:restore/modules/auth/bloc/auth/auth_context.dart';
import 'package:restore/modules/auth/bloc/auth/auth_event.dart';
import 'package:restore/modules/notifications/bloc/notification_badge/notification_badge_cubit.dart';
import 'package:restore/shared/widgets/app_count_badge.dart';
import 'package:restore/modules/auth/utils/auth_route_guard.dart';
import 'package:restore/modules/listings/models/create_listing_step.dart';
import 'package:restore/modules/location/bloc/user_area/user_area_cubit.dart';
import 'package:restore/modules/location/bloc/user_area/user_area_state.dart';
import 'package:restore/shared/widgets/filter/area_filter_panel.dart';
import 'package:restore/data/models/category_model.dart';
import 'package:restore/modules/category_detail/views/category_detail/category_detail_view.dart';
import 'package:restore/modules/search/bloc/search_cubit.dart';
import 'package:restore/modules/search/bloc/search_state.dart';
import 'package:restore/modules/search/models/search_user_item.dart';
import 'package:restore/modules/search/repositories/search_repository.dart';
import 'package:restore/modules/search/utils/category_matches.dart';
import 'package:restore/modules/search/utils/open_listing_search.dart';
import 'package:restore/modules/search/views/search/widgets/search_idle_content.dart';
import 'package:restore/modules/search/views/search/widgets/search_suggestion_list.dart';
import 'package:restore/modules/search/views/search_results/search_results_view.dart';
import 'package:restore/modules/trusted_shop/models/trusted_shop_item.dart';
import 'package:restore/modules/trusted_shop/views/shop_detail/shop_detail_view.dart';
import 'package:restore/shared/utils/filter_categories.dart';

/// Đầu trang web desktop nền trắng (giống đầu trang trên điện thoại), hai hàng:
/// - Hàng 1: logo, lối tắt (Bảng tin, Hot sale, Shop uy tín), ảnh đại diện +
///   tên mở menu tài khoản, Tin đã lưu, Thông báo, Tin nhắn, nút Đăng tin.
/// - Hàng 2: ô tìm kiếm rộng (kèm khung gợi ý), ô khu vực, nút Tìm.
/// Danh mục không đặt trên đầu trang vì trang chủ đã có hàng danh mục.
/// Nền trải hết màn hình, nội dung nằm trong khung 1200px ở giữa.
class DesktopHeader extends StatefulWidget {
  const DesktopHeader({
    super.key,
    required this.location,
    required this.unreadMessages,
    required this.onMessagesTap,
    this.listingSearchQuery,
  });

  /// Đường dẫn hiện tại, để tô đậm mục đang mở
  final String location;
  final String? listingSearchQuery;
  final int unreadMessages;
  final VoidCallback onMessagesTap;

  /// Trang tìm kiếm riêng không dùng trên desktop: nơi khác gọi hàm này để mở
  /// ô tìm kiếm trên header (kèm khung gợi ý) thay vì mở trang `/search`
  static final searchRequests = ValueNotifier(0);
  static void requestSearch() => searchRequests.value++;

  @override
  State<DesktopHeader> createState() => _DesktopHeaderState();
}

class _DesktopHeaderState extends State<DesktopHeader> {
  static const _onBar = AppColors.textPrimary;
  static const _onNav = AppColors.textPrimary;

  late final _query = TextEditingController(text: widget.listingSearchQuery);
  final _searchFocus = FocusNode();

  /// Khung gợi ý thả xuống dưới ô tìm kiếm: chưa gõ thì "Gần
  /// tôi", gợi ý tìm nhanh, lịch sử; đang gõ thì danh mục khớp, shop, người
  /// dùng và từ khoá gợi ý (cùng nội dung trang tìm kiếm trên điện thoại)
  final _suggestLink = LayerLink();
  final _suggestions = OverlayPortalController();
  final _tapGroup = Object();
  SearchCubit? _searchCubit;
  List<CategoryModel> _categories = const [];
  double _boxWidth = 480;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(_onSearchFocus);
    DesktopHeader.searchRequests.addListener(_searchFocus.requestFocus);
  }

  SearchCubit get _cubit => _searchCubit ??= SearchCubit(
    searchRepository: AppEnvironment.useMockData
        ? MockSearchRepository()
        : ApiSearchRepository(),
    query: _query.text,
    showHistory: context.isSignedIn,
  )..start();

  void _onSearchFocus() {
    if (!_searchFocus.hasFocus) return;
    if (_categories.isEmpty) {
      loadFilterCategories().then((categories) {
        if (mounted) setState(() => _categories = categories);
      });
    }
    final cubit = _searchCubit;
    if (cubit == null) {
      _cubit;
    } else {
      cubit
        ..loadHistory()
        ..queryChanged(_query.text);
    }
    _suggestions.show();
  }

  void _closeSuggestions() {
    _suggestions.hide();
    _searchFocus.unfocus();
  }

  /// Đưa gợi ý lên ô để gõ tiếp
  void _fill(String text) {
    _query.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _cubit.queryChanged(text);
    _searchFocus.requestFocus();
  }

  /// Danh mục khớp tên: mở trang danh mục, ô tìm kiếm để trống
  void _openCategory(CategoryMatch match) {
    _closeSuggestions();
    _query.clear();
    context.push(
      CategoryDetailView.location(
        match.parent.id,
        subcategoryId: match.sub?.id,
      ),
      extra: match.parent,
    );
  }

  void _openShop(TrustedShopItem item) {
    _closeSuggestions();
    context.push(ShopDetailView.location(item.shop.id), extra: item);
  }

  void _openUser(SearchUserItem user) {
    _closeSuggestions();
    context.push('/users/${user.id}');
  }

  Widget _suggestionPanel(BuildContext context) => CompositedTransformFollower(
    link: _suggestLink,
    targetAnchor: Alignment.bottomLeft,
    offset: const Offset(0, 6),
    child: Align(
      alignment: Alignment.topLeft,
      child: TapRegion(
        groupId: _tapGroup,
        onTapOutside: (_) => _closeSuggestions(),
        child: SizedBox(
          width: _boxWidth,
          child: Material(
            color: AppColors.surface,
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 480),
              child: BlocProvider.value(
                value: _cubit,
                child: BlocBuilder<SearchCubit, SearchState>(
                  builder: (context, state) => state.isTyping
                      ? SearchSuggestionList(
                          state: state,
                          shrinkWrap: true,
                          onSubmit: (text) => _search(text),
                          onFill: _fill,
                          onRemoveHistory: _cubit.removeHistory,
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
                          state: state,
                          shrinkWrap: true,
                          onSubmit: (text) => _search(text),
                          onNearMe: () {
                            _closeSuggestions();
                            context.push('/nearby');
                          },
                          onRemoveHistory: _cubit.removeHistory,
                          onClearHistory: _cubit.clearHistory,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  @override
  void didUpdateWidget(DesktopHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    final query = widget.listingSearchQuery;
    if (query != null &&
        query != oldWidget.listingSearchQuery &&
        query != _query.text) {
      _query.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    }
  }

  @override
  void dispose() {
    DesktopHeader.searchRequests.removeListener(_searchFocus.requestFocus);
    _searchFocus.removeListener(_onSearchFocus);
    _searchCubit?.close();
    _query.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  /// Tìm [text] (bấm gợi ý / lịch sử) hoặc chữ đang gõ trên ô
  Future<void> _search([String? text]) async {
    if (text != null) _query.text = text;
    final q = _query.text.trim();
    if (q.isEmpty) {
      _searchFocus.requestFocus();
      return;
    }
    _closeSuggestions();
    final onResults = widget.location == SearchResultsView.path;
    if (onResults && q == widget.listingSearchQuery) return;
    // Tên danh mục thì mở trang danh mục (ô tìm kiếm để trống);
    // đang ở trang kết quả hay trang danh mục thì thay trang để nút quay lại
    // không phải bấm qua từng lần tìm
    final replace = onResults || widget.location.startsWith('/categories/');
    final target = await listingSearchDestination(context, q);
    if (!mounted) return;
    if (target.extra != null) _query.clear();
    if (replace) {
      context.pushReplacement(target.location, extra: target.extra);
    } else {
      context.push(target.location, extra: target.extra);
    }
  }

  /// Bảng Khu vực mở dưới [anchor] (ô khu vực); đổi khu vực của cả app
  Future<void> _pickArea(BuildContext anchor) async {
    final userArea = context.read<UserAreaCubit>();
    final result = await showAreaPicker(anchor, current: userArea.state.area);
    if (result == null) return;
    if (result.nationwide) {
      userArea.selectNationwide();
    } else if (result.area case final area?) {
      userArea.select(area);
    } else if (result.useMyLocation) {
      await userArea.locate();
    }
  }

  void _requireLogin(VoidCallback action) {
    if (context.isSignedIn) {
      action();
    } else {
      context.go(loginPath(from: widget.location));
    }
  }

  Widget _centered({required double height, required Widget child}) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: AppDimesions.desktopContentWidth,
      ),
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: child,
        ),
      ),
    ),
  );

  /// Nút icon trên thanh chính (Tin đã lưu, Thông báo, Tin nhắn) kèm số
  /// chưa đọc; chưa đăng nhập thì mở trang đăng nhập
  Widget _iconAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    int count = 0,
  }) => _BarButton(
    tooltip: tooltip,
    onTap: () => _requireLogin(onTap),
    child: AppCountBadge(
      count: count,
      max: 99,
      offset: const Offset(6, -4),
      child: Icon(icon, size: 24, color: _onBar),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vi = Localizations.localeOf(context).languageCode == 'vi';
    String t(String vn, String en) => vi ? vn : en;
    final user = context.watchUser();
    NotificationBadgeCubit? notifications;
    try {
      notifications = context.read<NotificationBadgeCubit>();
    } catch (_) {
      // Màn hình test không cấp cubit: chuông không có số
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Hàng 1: logo, lối tắt, tài khoản, các nút icon, Đăng tin
        ColoredBox(
          color: AppColors.surface,
          child: _centered(
            height: 60,
            child: Row(
              children: [
                _BarButton(
                  padding: const EdgeInsets.only(right: 8),
                  onTap: () => context.go('/home'),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          AppImages.appLogos.appLogo,
                          width: 36,
                          height: 36,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Restore',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          color: AppHeaderPalette.top,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                for (final (label, path, go) in [
                  (l10n.feedsTitle, '/feeds', true),
                  (l10n.hotSaleTitle, '/hot-sale', false),
                  (l10n.homeQuickTrustedShops, '/trusted-shops', false),
                ])
                  _NavLink(
                    label: label,
                    active:
                        widget.location == path ||
                        widget.location.startsWith('$path/'),
                    onTap: () => go ? context.go(path) : context.push(path),
                    color: _onNav,
                  ),
                const Spacer(),
                _AccountMenu(location: widget.location),
                const SizedBox(width: 4),
                _iconAction(
                  icon: AppIcons.favorite,
                  tooltip: t('Tin đã lưu', 'Saved'),
                  onTap: () => context.push('/saved'),
                ),
                if (notifications == null)
                  _iconAction(
                    icon: AppIcons.notification,
                    tooltip: t('Thông báo', 'Notifications'),
                    onTap: () => context.push('/notifications'),
                  )
                else
                  BlocBuilder<NotificationBadgeCubit, int>(
                    bloc: notifications,
                    builder: (context, count) => _iconAction(
                      icon: AppIcons.notification,
                      tooltip: t('Thông báo', 'Notifications'),
                      count: user == null ? 0 : count,
                      onTap: () => context.push('/notifications'),
                    ),
                  ),
                _iconAction(
                  icon: AppIcons.chat,
                  tooltip: l10n.messagesTitle,
                  count: widget.unreadMessages,
                  onTap: widget.onMessagesTap,
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: () => _requireLogin(
                    () => context.push(CreateListingStep.category.path),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.actionPrimary,
                    foregroundColor: AppColors.onAction,
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  icon: const Icon(AppIcons.add, size: 18),
                  label: Text(t('Đăng tin', 'Post')),
                ),
              ],
            ),
          ),
        ),
        // Hàng 2: ô tìm kiếm rộng, ô khu vực, nút Tìm; kẻ mảnh ngăn với nội dung
        DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: _centered(
            height: 60,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: AppListingSearchBar.height,
                    decoration: const ShapeDecoration(
                      color: AppListingSearchBar.fillColor,
                      shape: StadiumBorder(),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Row(
                      children: [
                        Expanded(
                          child: OverlayPortal(
                            controller: _suggestions,
                            overlayChildBuilder: _suggestionPanel,
                            child: CompositedTransformTarget(
                              link: _suggestLink,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  _boxWidth = constraints.maxWidth;
                                  return TapRegion(
                                    groupId: _tapGroup,
                                    child: _SearchBox(
                                      controller: _query,
                                      focusNode: _searchFocus,
                                      groupId: _tapGroup,
                                      onChanged: (text) {
                                        _cubit.queryChanged(text);
                                        _suggestions.show();
                                      },
                                      onSearch: _search,
                                      onEscape: _closeSuggestions,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const VerticalDivider(
                          width: 1,
                          indent: 10,
                          endIndent: 10,
                          color: AppColors.border,
                        ),
                        _AreaField(onPickArea: _pickArea),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: _search,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.actionPrimary,
                    foregroundColor: AppColors.onAction,
                    minimumSize: const Size(96, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text(t('Tìm', 'Search')),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Ảnh đại diện + tên ▾ trên thanh chính: bấm mở menu tài khoản (hồ sơ, ví
/// xu, gói thành viên, đang theo dõi, báo khi có hàng, ngôn ngữ, đăng xuất).
/// Chưa đăng nhập thì là nút Đăng nhập.
class _AccountMenu extends StatelessWidget {
  const _AccountMenu({required this.location});
  final String location;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vi = Localizations.localeOf(context).languageCode == 'vi';
    String t(String vn, String en) => vi ? vn : en;
    final user = context.watchUser();
    if (user == null) {
      return _BarButton(
        onTap: () => context.go(loginPath(from: location)),
        child: Row(
          children: [
            const Icon(AppIcons.user, size: 20, color: AppColors.textPrimary),
            const SizedBox(width: 6),
            Text(
              l10n.signIn,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      );
    }
    MenuItemButton item(IconData icon, String label, VoidCallback onTap) =>
        MenuItemButton(
          leadingIcon: Icon(icon, size: 20),
          onPressed: onTap,
          style: MenuItemButton.styleFrom(
            minimumSize: const Size(240, 44),
            textStyle: const TextStyle(fontSize: 14),
          ),
          child: Text(label),
        );
    return MenuAnchor(
      alignmentOffset: const Offset(0, 6),
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(AppColors.surface),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: 6),
        ),
      ),
      menuChildren: [
        item(
          AppIcons.user,
          t('Hồ sơ của tôi', 'My profile'),
          () => context.push('/users/${user.id}'),
        ),
        item(
          AppIcons.settings,
          l10n.accountTitle,
          () => context.go('/account'),
        ),
        item(
          AppIcons.wallet,
          t('Ví xu', 'Coin wallet'),
          () => context.push('/credits'),
        ),
        item(
          AppIcons.star,
          t('Gói thành viên', 'Membership'),
          () => context.push('/plans'),
        ),
        item(
          AppIcons.following,
          l10n.homeQuickFollowing,
          () => context.push('/following'),
        ),
        item(
          AppIcons.notification,
          l10n.homeQuickWanted,
          () => context.push('/wanted-alerts'),
        ),
        const Divider(height: 9),
        item(
          AppIcons.globe,
          vi ? 'English' : 'Tiếng Việt',
          () => context.read<LanguageBloc>().add(
            ChangeLanguage(Locale(vi ? 'en' : 'vi')),
          ),
        ),
        item(AppIcons.logout, l10n.accLogout, () async {
          if (await confirmLogout(context) && context.mounted) {
            context.read<AuthBloc>().add(LoggedOut());
          }
        }),
      ],
      builder: (context, controller, _) => _BarButton(
        tooltip: l10n.accountTitle,
        onTap: () => controller.isOpen ? controller.close() : controller.open(),
        child: Row(
          children: [
            ProfileAvatar(
              radius: 15,
              url: user.avatarUrl,
              initials: ProfileHeader.initials(user.fullName),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(
                user.givenName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.expand_more,
              size: 20,
              color: AppColors.textPrimary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Ô khu vực bên phải ô tìm kiếm: hiện khu vực đang xem, bấm mở bảng
/// "Khu vực" (cùng bảng với điện thoại) ngay dưới ô
class _AreaField extends StatelessWidget {
  const _AreaField({required this.onPickArea});
  final Future<void> Function(BuildContext anchor) onPickArea;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () => onPickArea(context),
        child: SizedBox(
          width: 240,
          height: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(
                  AppIcons.location,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: BlocBuilder<UserAreaCubit, UserAreaState>(
                    builder: (context, state) => Text(
                      switch (state.status) {
                        UserAreaStatus.locating => l10n.homeAreaLocating,
                        UserAreaStatus.nationwide => l10n.areaNationwide,
                        UserAreaStatus.ready =>
                          state.area?.displayName ?? l10n.areaNationwide,
                      },
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const Icon(
                  Icons.expand_more,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Vùng bấm trên thanh chính: nền xám nhạt khi rê chuột
class _BarButton extends StatefulWidget {
  const _BarButton({
    required this.child,
    required this.onTap,
    this.tooltip,
    this.padding = const EdgeInsets.symmetric(horizontal: 8),
  });
  final Widget child;
  final VoidCallback onTap;
  final String? tooltip;

  /// Lề trong; logo không có lề trái để thẳng mép với ô tìm kiếm bên dưới
  final EdgeInsets padding;

  @override
  State<_BarButton> createState() => _BarButtonState();
}

class _BarButtonState extends State<_BarButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final button = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 48,
          padding: widget.padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: _hover ? AppColors.fill : Colors.transparent,
          ),
          alignment: Alignment.center,
          child: widget.child,
        ),
      ),
    );
    final tooltip = widget.tooltip;
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }
}

class _NavLink extends StatefulWidget {
  const _NavLink({
    required this.label,
    required this.onTap,
    required this.color,
    this.active = false,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool active;

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _hover = true),
    onExit: (_) => setState(() => _hover = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: _hover ? AppColors.fill : Colors.transparent,
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            fontSize: 14,
            color: widget.active ? AppColors.actionPrimary : widget.color,
            fontWeight: widget.active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    ),
  );
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({
    required this.controller,
    required this.focusNode,
    required this.groupId,
    required this.onSearch,
    required this.onChanged,
    required this.onEscape,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  /// Cùng nhóm với khung gợi ý: bấm vào khung không làm ô mất focus
  final Object groupId;
  final VoidCallback onSearch;
  final ValueChanged<String> onChanged;
  final VoidCallback onEscape;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: AppListingSearchBar.height,
    child: Row(
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 14),
          child: Icon(
            AppIcons.search,
            size: 20,
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.escape): onEscape,
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: ListingSearchInput(
                controller: controller,
                focusNode: focusNode,
                groupId: groupId,
                onChanged: onChanged,
                onSubmitted: (_) => onSearch(),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
