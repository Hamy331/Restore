import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/filter/app_filter_bar.dart';
import 'package:restore/shared/widgets/glass/app_pinned_header_surface.dart';

/// Các khu của trang Shop uy tín, theo thứ tự từ trên xuống
enum TrustedShopsSection {
  famous,
  deals,
  newReleases,
  newShops,
  showcases,
  allProducts;

  String label(AppLocalizations l10n) => switch (this) {
    famous => l10n.trustedShopsNavFamous,
    deals => l10n.trustedShopsNavDeals,
    newReleases => l10n.trustedShopsNavNewReleases,
    newShops => l10n.trustedShopsNavNewShops,
    showcases => l10n.trustedShopsNavShowcases,
    allProducts => l10n.trustedShopsNavAll,
  };

  IconData get icon => switch (this) {
    famous => AppIcons.brand,
    deals => AppIcons.sale,
    newReleases => AppIcons.hot,
    newShops => AppIcons.sparkle,
    showcases => AppIcons.shop,
    allProducts => AppIcons.listings,
  };
}

/// Thanh mục ngay dưới banner: bấm một mục để cuộn nhanh tới khu đó, mục
/// đang xem được tô đậm. Cuộn qua thì ghim dưới tiêu đề trang; chưa ghim nền
/// trắng liền phần nội dung, đã ghim thành kính mờ ([AppPinnedHeaderSurface]).
class TrustedSectionBarDelegate extends SliverPersistentHeaderDelegate {
  final List<TrustedShopsSection> sections;

  /// Khu đang xem, null khi đang ở phần banner phía trên
  final TrustedShopsSection? active;
  final ValueChanged<TrustedShopsSection> onTap;

  TrustedSectionBarDelegate({
    required this.sections,
    required this.active,
    required this.onTap,
  });

  static const double _verticalPadding = 10;
  static const double height = _verticalPadding * 2 + AppFilterChip.height;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: _verticalPadding),
      child: _SectionChips(sections: sections, active: active, onTap: onTap),
    );
    return overlapsContent || shrinkOffset > 0
        ? AppPinnedHeaderSurface(pinned: true, child: content)
        : ColoredBox(color: AppColors.surface, child: content);
  }

  @override
  bool shouldRebuild(TrustedSectionBarDelegate oldDelegate) =>
      oldDelegate.active != active || oldDelegate.sections != sections;
}

/// Hàng chip các khu; mục đang xem đổi thì tự cuộn ngang cho chip đó vào giữa
class _SectionChips extends StatefulWidget {
  final List<TrustedShopsSection> sections;
  final TrustedShopsSection? active;
  final ValueChanged<TrustedShopsSection> onTap;

  const _SectionChips({
    required this.sections,
    required this.active,
    required this.onTap,
  });

  @override
  State<_SectionChips> createState() => _SectionChipsState();
}

class _SectionChipsState extends State<_SectionChips> {
  final _chipKeys = {
    for (final section in TrustedShopsSection.values) section: GlobalKey(),
  };

  @override
  void didUpdateWidget(_SectionChips oldWidget) {
    super.didUpdateWidget(oldWidget);
    final active = widget.active;
    if (active == null || active == oldWidget.active) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chip = _chipKeys[active]?.currentContext;
      final box = chip?.findRenderObject();
      if (chip == null || !chip.mounted || box == null) return;
      // Chỉ cuộn hàng chip; Scrollable.ensureVisible sẽ kéo cả trang dọc
      Scrollable.maybeOf(chip)?.position.ensureVisible(
        box,
        alignment: 0.5,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppFilterBar(
      children: [
        for (final section in widget.sections)
          AppFilterChip(
            key: _chipKeys[section],
            label: section.label(l10n),
            icon: section.icon,
            selected: section == widget.active,
            onTap: () => widget.onTap(section),
          ),
      ],
    );
  }
}
