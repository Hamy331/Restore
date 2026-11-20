import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/blocs/language/language_bloc.dart';
import 'package:restore/core/blocs/language/language_event.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_dimesions.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/constants/app_images.dart' show AppImages;
import 'package:restore/core/theme/app_header_palette.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/auth/bloc/auth/auth_context.dart';
import 'package:restore/modules/auth/utils/auth_route_guard.dart';
import 'package:restore/modules/listings/models/create_listing_step.dart';
import 'package:restore/modules/location/bloc/user_area/user_area_cubit.dart';
import 'package:restore/modules/location/bloc/user_area/user_area_state.dart';
import 'package:restore/modules/location/models/area_option.dart';
import 'package:restore/modules/location/views/area_search/area_search_view.dart';
import 'package:restore/modules/search/views/search_results/search_results_view.dart';

/// Đầu trang web desktop, màu trơn xanh đậm theo logo (bố cục kiểu Amazon):
/// - Thanh chính xanh đậm: logo, khu vực, ô tìm kiếm, ngôn ngữ, tài khoản,
///   tin nhắn, nút Đăng tin.
/// - Thanh phụ xanh sáng hơn: lối tắt tới các trang chính.
/// Nền trải hết màn hình, nội dung nằm trong khung 1200px ở giữa.
class DesktopHeader extends StatefulWidget {
  const DesktopHeader({
    super.key,
    required this.location,
    required this.unreadMessages,
    required this.onMessagesTap,
  });

  /// Đường dẫn hiện tại, để tô đậm mục đang mở
  final String location;
  final int unreadMessages;
  final VoidCallback onMessagesTap;

  @override
  State<DesktopHeader> createState() => _DesktopHeaderState();
}

class _DesktopHeaderState extends State<DesktopHeader> {
  static const _onBar = Colors.white;
  static const _onNav = Colors.white;

  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _search() {
    final q = _query.text.trim();
    if (q.isEmpty) {
      context.push('/search');
      return;
    }
    context.push(
      '${SearchResultsView.path}?q=${Uri.encodeQueryComponent(q)}&from=search',
    );
  }

  Future<void> _pickArea() async {
    final userArea = context.read<UserAreaCubit>();
    final result = await context.push<AreaPickResult>(
      AreaSearchView.location(allowNationwide: true),
    );
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vi = Localizations.localeOf(context).languageCode == 'vi';
    String t(String vn, String en) => vi ? vn : en;
    final user = context.watchUser();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Thanh chính
        ColoredBox(
          color: AppHeaderPalette.desktopBar,
          child: _centered(
            height: 64,
            child: Row(
              children: [
                _BarButton(
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
                          color: _onBar,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                // Khu vực đang xem (theo GPS hoặc tự chọn)
                _BarButton(
                  onTap: _pickArea,
                  child: BlocBuilder<UserAreaCubit, UserAreaState>(
                    builder: (context, area) {
                      final label = switch (area.status) {
                        UserAreaStatus.locating => l10n.homeAreaLocating,
                        UserAreaStatus.nationwide => l10n.areaNationwide,
                        UserAreaStatus.ready =>
                          area.area?.displayName ?? l10n.areaNationwide,
                      };
                      return Row(
                        children: [
                          const Icon(
                            AppIcons.location,
                            size: 18,
                            color: _onBar,
                          ),
                          const SizedBox(width: 4),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t('Khu vực', 'Area'),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xE6FFFFFF),
                                ),
                              ),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 130,
                                ),
                                child: Text(
                                  label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: _onBar,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SearchBox(
                    controller: _query,
                    hint: l10n.homeSearchHint,
                    onSearch: _search,
                  ),
                ),
                const SizedBox(width: 10),
                _BarButton(
                  tooltip: t('Đổi ngôn ngữ', 'Change language'),
                  onTap: () => context.read<LanguageBloc>().add(
                    ChangeLanguage(Locale(vi ? 'en' : 'vi')),
                  ),
                  child: Row(
                    children: [
                      const Icon(AppIcons.globe, size: 17, color: _onBar),
                      const SizedBox(width: 4),
                      Text(
                        vi ? 'VI' : 'EN',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: _onBar,
                        ),
                      ),
                    ],
                  ),
                ),
                _BarButton(
                  onTap: () => user == null
                      ? context.go(loginPath(from: widget.location))
                      : context.go('/account'),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 140),
                        child: Text(
                          user == null
                              ? t('Xin chào, đăng nhập', 'Hello, sign in')
                              : t(
                                  'Xin chào, ${user.givenName}',
                                  'Hello, ${user.givenName}',
                                ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xE6FFFFFF),
                          ),
                        ),
                      ),
                      Text(
                        l10n.accountTitle,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: _onBar,
                        ),
                      ),
                    ],
                  ),
                ),
                _BarButton(
                  tooltip: l10n.messagesTitle,
                  onTap: () => _requireLogin(widget.onMessagesTap),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(AppIcons.chat, size: 25, color: _onBar),
                      ),
                      if (widget.unreadMessages > 0)
                        Positioned(
                          top: -6,
                          right: -6,
                          child: Container(
                            constraints: const BoxConstraints(minWidth: 18),
                            height: 18,
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              widget.unreadMessages > 99
                                  ? '99+'
                                  : '${widget.unreadMessages}',
                              style: const TextStyle(
                                color: AppHeaderPalette.desktopBar,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => _requireLogin(
                    () => context.push(CreateListingStep.category.path),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppHeaderPalette.desktopBar,
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  icon: const Icon(AppIcons.add, size: 18),
                  label: Text(t('Đăng tin', 'Post')),
                ),
              ],
            ),
          ),
        ),
        // Thanh phụ: lối tắt
        ColoredBox(
          color: AppHeaderPalette.desktopNav,
          child: _centered(
            height: 38,
            child: Row(
              children: [
                for (final (label, path, go) in [
                  (l10n.homeTitle, '/home', true),
                  (l10n.feedsTitle, '/feeds', true),
                  (l10n.homeQuickNearby, '/nearby', false),
                  (l10n.hotSaleTitle, '/hot-sale', false),
                  (l10n.homeQuickTrustedShops, '/trusted-shops', false),
                  (l10n.homeQuickWanted, '/wanted-alerts', false),
                  (l10n.homeQuickFollowing, '/following', false),
                  (t('Gói thành viên', 'Membership'), '/plans', false),
                  ('Blog', '/blog', false),
                  (t('Trợ giúp', 'Help'), '/support', false),
                ])
                  _NavLink(
                    label: label,
                    active: widget.location == path ||
                        widget.location.startsWith('$path/'),
                    onTap: () => go ? context.go(path) : context.push(path),
                    color: _onNav,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Vùng bấm trên thanh chính: viền trắng mảnh khi rê chuột (như Amazon)
class _BarButton extends StatefulWidget {
  const _BarButton({required this.child, required this.onTap, this.tooltip});
  final Widget child;
  final VoidCallback onTap;
  final String? tooltip;

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
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _hover ? Colors.white : Colors.transparent,
            ),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: _hover ? widget.color : Colors.transparent,
          ),
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            fontSize: 13.5,
            color: widget.color,
            fontWeight: widget.active ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
    ),
  );
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({
    required this.controller,
    required this.hint,
    required this.onSearch,
  });

  final TextEditingController controller;
  final String hint;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) => Container(
    height: 42,
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(8),
    ),
    clipBehavior: Clip.antiAlias,
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onSubmitted: (_) => onSearch(),
            textInputAction: TextInputAction.search,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              filled: false,
              isDense: true,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
            ),
          ),
        ),
        Material(
          color: const Color(0xFFF3F3F3),
          child: InkWell(
            onTap: onSearch,
            child: const SizedBox(
              width: 52,
              height: double.infinity,
              child: Icon(
                AppIcons.search,
                size: 20,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
