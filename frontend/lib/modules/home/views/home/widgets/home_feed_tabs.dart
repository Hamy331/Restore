import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/l10n/app_localizations.dart';
import '../../../models/home_listing_filter.dart';

/// Tab danh sách tin trang chủ: Mới nhất, Dành cho bạn, Đã xác minh, Gần tôi,
/// Đồ miễn phí, Đang theo dõi. Kéo ngang được khi không đủ chỗ (điện thoại);
/// tab đang chọn đậm, màu hành động và có gạch chân.
class HomeFeedTabs extends StatefulWidget {
  const HomeFeedTabs({
    super.key,
    required this.selected,
    required this.onSelect,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.fontSize = 15,
    this.expand = false,
  });

  final HomeListingFilter selected;
  final ValueChanged<HomeListingFilter> onSelect;
  final EdgeInsetsGeometry padding;
  final double fontSize;
  final bool expand;

  static String label(AppLocalizations l10n, HomeListingFilter filter) =>
      switch (filter) {
        HomeListingFilter.newest => l10n.listingSortNewest,
        HomeListingFilter.forYou => l10n.feedForYou,
        HomeListingFilter.certified => l10n.homeTabCertified,
        HomeListingFilter.nearby => l10n.homeTabNearMe,
        HomeListingFilter.free => l10n.homeTabFreeItems,
        HomeListingFilter.following => l10n.homeTabFollowing,
      };

  @override
  State<HomeFeedTabs> createState() => _HomeFeedTabsState();
}

class _HomeFeedTabsState extends State<HomeFeedTabs> {
  final _keys = {
    for (final filter in HomeListingFilter.values) filter: GlobalKey(),
  };

  @override
  void didUpdateWidget(HomeFeedTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.expand && oldWidget.selected != widget.selected) {
      _reveal(widget.selected);
    }
  }

  /// Kéo tab vừa chọn vào giữa tầm nhìn (tab ở mép bị che một nửa)
  void _reveal(HomeListingFilter filter) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _keys[filter]?.currentContext;
      if (context == null || !context.mounted) return;
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tabs = [
      for (final filter in HomeListingFilter.values)
        _Tab(
          key: _keys[filter],
          label: HomeFeedTabs.label(l10n, filter),
          selected: filter == widget.selected,
          fontSize: widget.fontSize,
          onTap: () => widget.onSelect(filter),
        ),
    ];
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: widget.expand
          ? Padding(
              padding: widget.padding,
              child: Row(
                children: [for (final tab in tabs) Expanded(child: tab)],
              ),
            )
          // Hẹp (điện thoại): kéo ngang. Rộng hơn tổng cỡ các tab (tablet):
          // tab dàn đều hết bề ngang thay vì dồn sát trái
          : LayoutBuilder(
              builder: (context, box) {
                final inset = widget.padding.resolve(Directionality.of(context));
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: widget.padding,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: box.maxWidth - inset.horizontal,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: tabs,
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    super.key,
    required this.label,
    required this.selected,
    required this.fontSize,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final double fontSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppColors.actionPrimary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              color: selected
                  ? AppColors.actionPrimary
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
