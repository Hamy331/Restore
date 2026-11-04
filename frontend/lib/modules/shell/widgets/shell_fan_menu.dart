import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';

import '../models/shell_quick_action.dart';
import 'shell_glass_ring_button.dart';

/// Nút giữa thanh điều hướng. Gói Cá nhân: dấu + mở luồng đăng tin.
/// Gói tier cao: icon menu, bấm vào thì các nút tròn xoè ra thành hình
/// cánh quạt phía trên nút, nền phía sau tối và mờ đi; bấm ra ngoài, bấm
/// nút X hoặc chọn một nút để thu lại.
class ShellFanMenu extends StatefulWidget {
  final List<ShellQuickAction> actions;
  final double size;
  final VoidCallback onPostTap;
  final ValueChanged<ShellQuickAction> onAction;

  const ShellFanMenu({
    super.key,
    required this.actions,
    required this.onPostTap,
    required this.onAction,
    this.size = 58,
  });

  @override
  State<ShellFanMenu> createState() => _ShellFanMenuState();
}

class _ShellFanMenuState extends State<ShellFanMenu>
    with SingleTickerProviderStateMixin {
  /// Bề rộng cung xoè: từ 160 độ (bên trái) đến 20 độ (bên phải)
  static const double _startAngle = 160 * math.pi / 180;
  static const double _endAngle = 20 * math.pi / 180;
  static const double _itemSize = 50;

  final _link = LayerLink();
  final _portal = OverlayPortalController();
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
    reverseDuration: const Duration(milliseconds: 260),
  );

  bool get _hasMenu => widget.actions.isNotEmpty;

  /// Nhiều nút thì vòng cung rộng hơn để nhãn không chạm nhau
  double get _radius => widget.actions.length > 3 ? 112 : 98;

  @override
  void didUpdateWidget(ShellFanMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Đổi sang gói không có menu khi đang mở thì đóng ngay
    if (!_hasMenu && _portal.isShowing) {
      _controller.value = 0;
      _portal.hide();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _open() {
    HapticFeedback.mediumImpact();
    _portal.show();
    _controller.forward();
  }

  Future<void> _close() async {
    HapticFeedback.selectionClick();
    await _controller.reverse();
    if (mounted && _controller.isDismissed) _portal.hide();
  }

  void _select(ShellQuickAction action) {
    _close();
    widget.onAction(action);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: _buildOverlay,
        child: ShellGlassRingButton(
          icon: _hasMenu ? AppIcons.quickMenu : AppIcons.add,
          label: _hasMenu ? l10n.quickMenuOpen : l10n.createListing,
          size: widget.size,
          onTap: _hasMenu ? _open : widget.onPostTap,
        ),
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final actions = widget.actions;
    final count = actions.length;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeOut.transform(_controller.value);
        return Stack(
          children: [
            // Nền tối và mờ phía sau, bấm vào để đóng
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _close,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4 * t, sigmaY: 4 * t),
                  child: ColoredBox(
                    color: AppColors.textPrimary.withValues(alpha: 0.32 * t),
                  ),
                ),
              ),
            ),
            for (var i = 0; i < count; i++)
              _positioned(
                offset: _itemOffset(i, count),
                child: Opacity(
                  opacity: _progress(i, count),
                  child: Transform.scale(
                    scale: 0.4 + 0.6 * _progress(i, count),
                    child: _FanItem(
                      action: actions[i],
                      label: actions[i].label(l10n),
                      size: _itemSize,
                      onTap: () => _select(actions[i]),
                    ),
                  ),
                ),
              ),
            // Nút X đè đúng lên nút giữa, xoay từ icon menu sang
            _positioned(
              offset: Offset.zero,
              child: Opacity(
                opacity: t,
                child: Transform.rotate(
                  angle: (1 - t) * -math.pi / 2,
                  child: ShellGlassRingButton(
                    icon: AppIcons.closeStrong,
                    label: l10n.quickMenuClose,
                    size: widget.size,
                    onTap: _close,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Tiến độ 0..1 riêng của nút thứ [i], nút sau trễ hơn nút trước
  double _progress(int i, int count) {
    const stagger = 0.22;
    final delay = count == 1 ? 0.0 : stagger * i / (count - 1);
    return ((_controller.value - delay) / (1 - stagger)).clamp(0.0, 1.0);
  }

  /// Vị trí tâm nút thứ [i] so với tâm nút giữa. Mỗi nút xuất phát chồng
  /// lên nhau ở đỉnh cung (90 độ) rồi xoè sang góc của mình như cánh quạt
  /// mở ra; nút sau trễ hơn nút trước một nhịp.
  Offset _itemOffset(int i, int count) {
    final raw = _progress(i, count);
    final spread = _controller.status == AnimationStatus.reverse
        ? Curves.easeIn.transform(raw)
        : Curves.easeOutBack.transform(raw);
    final target = count == 1
        ? math.pi / 2
        : _startAngle + (_endAngle - _startAngle) * i / (count - 1);
    final angle = math.pi / 2 + (target - math.pi / 2) * spread;
    final distance = _radius * Curves.easeOut.transform(raw);
    return Offset(math.cos(angle) * distance, -math.sin(angle) * distance);
  }

  /// Gắn widget vào nút giữa, tâm widget trùng tâm nút cộng [offset]
  Widget _positioned({required Offset offset, required Widget child}) {
    return Positioned(
      left: 0,
      top: 0,
      child: CompositedTransformFollower(
        link: _link,
        showWhenUnlinked: false,
        targetAnchor: Alignment.center,
        followerAnchor: Alignment.center,
        offset: offset,
        child: child,
      ),
    );
  }
}

/// Một nút tròn trong menu xoè: nút kính trắng, nhãn nhỏ phía dưới.
/// Nút nổi bật thì nền cam và icon trắng.
class _FanItem extends StatefulWidget {
  final ShellQuickAction action;
  final String label;
  final double size;
  final VoidCallback onTap;

  const _FanItem({
    required this.action,
    required this.label,
    required this.size,
    required this.onTap,
  });

  @override
  State<_FanItem> createState() => _FanItemState();
}

class _FanItemState extends State<_FanItem> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final highlighted = widget.action.highlighted;

    final circle = AnimatedScale(
      scale: _pressed ? 0.88 : 1,
      duration: _pressed
          ? const Duration(milliseconds: 110)
          : const Duration(milliseconds: 340),
      curve: _pressed ? Curves.easeOut : Curves.easeOutBack,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: highlighted
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFC266), AppColors.primary],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.96),
                    AppColors.primarySoft.withValues(alpha: 0.92),
                  ],
                ),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(
                alpha: _pressed ? 0.45 : 0.28,
              ),
              blurRadius: _pressed ? 18 : 12,
              spreadRadius: -2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          widget.action.icon,
          size: size * 0.44,
          color: highlighted ? Colors.white : AppColors.primaryDark,
        ),
      ),
    );

    // Nhãn nằm dưới nút nhưng không làm lệch tâm: tâm widget luôn là tâm
    // hình tròn để vị trí trên vòng cung chính xác
    return Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: SizedBox(
          width: size + 40,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              circle,
              Positioned(
                top: size + 5,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: ShapeDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
