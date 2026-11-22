import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';

/// Một mục cha trong breadcrumb (VD "Ví xu" → `/credits`)
class BreadcrumbItem {
  const BreadcrumbItem(this.label, this.path);
  final String label;
  final String path;
}

/// Các mục cha của trang đang mở, do khung menu Tài khoản cấp cho trang con
/// (Mua xu, Lịch sử, Tạo thông báo...). Rỗng là trang gốc của menu.
class DesktopBreadcrumbScope extends InheritedWidget {
  const DesktopBreadcrumbScope({
    super.key,
    required this.parents,
    required super.child,
  });

  final List<BreadcrumbItem> parents;

  static List<BreadcrumbItem> of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<DesktopBreadcrumbScope>()
          ?.parents ??
      const [];

  @override
  bool updateShouldNotify(DesktopBreadcrumbScope oldWidget) {
    if (parents.length != oldWidget.parents.length) return true;
    for (var i = 0; i < parents.length; i++) {
      if (parents[i].path != oldWidget.parents[i].path ||
          parents[i].label != oldWidget.parents[i].label) {
        return true;
      }
    }
    return false;
  }
}

/// Tiêu đề của một trang trên web desktop (Hồ sơ, Đánh giá, Ví xu, Đang theo
/// dõi, Mua xu...): tên trang + một dòng mô tả, nút thao tác bên phải, đường
/// kẻ ngăn bên dưới. Mọi mục trong menu Tài khoản dùng chung widget này nên
/// cỡ chữ, chiều cao và đường kẻ giống nhau.
///
/// - Trang gốc của menu bên trái: chỉ có tiêu đề lớn, không có nút quay lại.
/// - Trang con (Mua xu, Lịch sử...): tiêu đề thành breadcrumb kiểu
///   `Tài khoản / Ví xu / Mua xu`, bấm vào mục cha để quay về.
/// - Trang không thuộc menu (không có breadcrumb): nếu truyền [onBack] thì
///   hiện nút quay lại.
class DesktopPageTitle extends StatelessWidget {
  const DesktopPageTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onBack,
  });

  /// Chiều cao phần tiêu đề (chưa gồm đường kẻ), chung cho mọi trang
  static const double height = 80;

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    final trailing = this.trailing;
    final onBack = this.onBack;
    final parents = DesktopBreadcrumbScope.of(context);
    final breadcrumb = parents.isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: height),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            child: Row(
              children: [
                if (!breadcrumb && onBack != null) ...[
                  _BackButton(onTap: onBack),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (breadcrumb)
                        _Breadcrumb(parents: parents, current: title)
                      else
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      if (subtitle != null && subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 12), trailing],
              ],
            ),
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: AppLocalizations.of(context)!.back,
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(
          AppIcons.back,
          size: 18,
          color: AppColors.textPrimary,
        ),
      ),
    ),
  );
}

/// `Tài khoản / Ví xu / Mua xu`: mục cha bấm được (xám), mục cuối là trang
/// hiện tại (đậm)
class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.parents, required this.current});

  final List<BreadcrumbItem> parents;
  final String current;

  @override
  Widget build(BuildContext context) {
    const size = 16.0;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final parent in parents) ...[
          _Crumb(
            label: parent.label,
            onTap: () => context.go(parent.path),
            fontSize: size,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '/',
              style: TextStyle(fontSize: size, color: AppColors.border),
            ),
          ),
        ],
        Text(
          current,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _Crumb extends StatefulWidget {
  const _Crumb({
    required this.label,
    required this.onTap,
    required this.fontSize,
  });

  final String label;
  final VoidCallback onTap;
  final double fontSize;

  @override
  State<_Crumb> createState() => _CrumbState();
}

class _CrumbState extends State<_Crumb> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _hover = true),
    onExit: (_) => setState(() => _hover = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: Text(
        widget.label,
        style: TextStyle(
          fontSize: widget.fontSize,
          color: _hover ? AppColors.primaryDark : AppColors.textSecondary,
          decoration: _hover ? TextDecoration.underline : null,
          decorationColor: AppColors.primaryDark,
        ),
      ),
    ),
  );
}

/// Thanh tiêu đề thay cho `AppBar` của các trang trong menu Tài khoản khi ở
/// bản desktop (Thống kê, Cửa hàng của tôi, Quảng bá, Poster shop, Cài đặt),
/// cùng kiểu với [DesktopPageTitle].
class DesktopSectionBar extends StatelessWidget implements PreferredSizeWidget {
  const DesktopSectionBar({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(DesktopPageTitle.height + 1);

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.surface,
    child: DesktopPageTitle(
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onBack: onBack,
    ),
  );
}
