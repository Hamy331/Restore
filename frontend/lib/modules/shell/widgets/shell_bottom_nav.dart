import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';

import 'shell_glass_ring_button.dart';

/// Thanh điều hướng kính mờ bám đáy màn hình, mép trên lồi cong ở giữa
/// để ôm nút Đăng tin tròn (index 2).
/// Nội dung cuộn phía sau được làm mờ qua mặt kính (MainShell bật extendBody).
class ShellBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final int unreadMessages;

  const ShellBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    this.unreadMessages = 0,
  });

  /// Độ cao phần lồi phía trên mép thanh
  static const double _bumpHeight = 18;
  static const double _barHeight = 64;
  static const double _centerButtonSize = 58;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    void select(int index) {
      if (index != selectedIndex) HapticFeedback.selectionClick();
      onSelected(index);
    }

    Widget item(
      int index,
      IconData icon,
      IconData activeIcon,
      String label, {
      int badge = 0,
    }) {
      return Expanded(
        child: _NavItem(
          icon: icon,
          activeIcon: activeIcon,
          label: label,
          semanticLabel: badge > 0
              ? '$label, ${l10n.unreadMessagesCount(badge)}'
              : label,
          badge: badge,
          selected: index == selectedIndex,
          onTap: () => select(index),
        ),
      );
    }

    return SizedBox(
      height: _bumpHeight + _barHeight + bottomInset,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned.fill(
            child: _GlassCurvedBar(bumpHeight: _bumpHeight),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: _bumpHeight,
            height: _barHeight,
            child: Row(
              children: [
                item(0, AppIcons.home, AppIcons.homeActive, l10n.homeTitle),
                item(
                  1,
                  AppIcons.listings,
                  AppIcons.listingsActive,
                  l10n.manageListings,
                ),
                // Chừa chỗ cho nút Đăng tin nằm trong phần lồi
                const Expanded(child: SizedBox()),
                item(
                  3,
                  AppIcons.chat,
                  AppIcons.chatActive,
                  l10n.messagesTitle,
                  badge: unreadMessages,
                ),
                item(4, AppIcons.user, AppIcons.userActive, l10n.accountTitle),
              ],
            ),
          ),
          Positioned(
            top: 6,
            left: 0,
            right: 0,
            child: Center(
              child: ShellGlassRingButton(
                icon: AppIcons.add,
                label: l10n.createListing,
                size: _centerButtonSize,
                onTap: () => select(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mặt kính của thanh: đường viền trên cong lên ở giữa, blur nội dung phía
/// sau, nền trắng trong mờ và một đường sáng mảnh chạy theo mép cong.
class _GlassCurvedBar extends StatelessWidget {
  final double bumpHeight;

  const _GlassCurvedBar({required this.bumpHeight});

  @override
  Widget build(BuildContext context) {
    final clipper = _CurvedTopClipper(bumpHeight: bumpHeight);
    return CustomPaint(
      // Bóng mềm phía trên mép cong để thanh tách khỏi nội dung
      painter: _CurvedShadowPainter(clipper),
      foregroundPainter: _CurvedStrokePainter(clipper),
      child: ClipPath(
        clipper: clipper,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.80),
                  Colors.white.withValues(alpha: 0.90),
                ],
              ),
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _CurvedTopClipper extends CustomClipper<Path> {
  final double bumpHeight;

  const _CurvedTopClipper({required this.bumpHeight});

  /// Nửa bề rộng phần lồi
  static const double _halfWidth = 74;

  /// Chỉ đường mép trên (dùng chung cho clip, viền sáng và bóng)
  Path topEdge(Size size) {
    final cx = size.width / 2;
    final base = bumpHeight;
    return Path()
      ..moveTo(0, base)
      ..lineTo(cx - _halfWidth, base)
      ..cubicTo(cx - _halfWidth * 0.5, base, cx - _halfWidth * 0.55, 0, cx, 0)
      ..cubicTo(
        cx + _halfWidth * 0.55,
        0,
        cx + _halfWidth * 0.5,
        base,
        cx + _halfWidth,
        base,
      )
      ..lineTo(size.width, base);
  }

  @override
  Path getClip(Size size) => topEdge(size)
    ..lineTo(size.width, size.height)
    ..lineTo(0, size.height)
    ..close();

  @override
  bool shouldReclip(_CurvedTopClipper oldClipper) =>
      oldClipper.bumpHeight != bumpHeight;
}

class _CurvedStrokePainter extends CustomPainter {
  final _CurvedTopClipper clipper;

  const _CurvedStrokePainter(this.clipper);

  @override
  void paint(Canvas canvas, Size size) {
    final edge = clipper.topEdge(size);
    // Viền sáng như mép kính, thêm một nét cam rất nhạt để bắt màu app
    canvas.drawPath(
      edge,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColors.primary.withValues(alpha: 0.28),
    );
    canvas.drawPath(
      edge.shift(const Offset(0, 1)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_CurvedStrokePainter oldDelegate) => false;
}

class _CurvedShadowPainter extends CustomPainter {
  final _CurvedTopClipper clipper;

  const _CurvedShadowPainter(this.clipper);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawShadow(
      clipper.getClip(size),
      AppColors.primaryDark.withValues(alpha: 0.35),
      6,
      false,
    );
  }

  @override
  bool shouldRepaint(_CurvedShadowPainter oldDelegate) => false;
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String semanticLabel;
  final int badge;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.semanticLabel,
    required this.badge,
    required this.selected,
    required this.onTap,
  });

  static const _duration = Duration(milliseconds: 320);

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primaryDark : AppColors.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 34,
              height: 30,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Đốm kính màu cam lấp ló sau icon khi được chọn
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: AnimatedScale(
                      scale: selected ? 1 : 0,
                      duration: _duration,
                      curve: selected ? Curves.easeOutBack : Curves.easeIn,
                      alignment: Alignment.bottomRight,
                      child: const _GlassDot(size: 18),
                    ),
                  ),
                  Positioned(
                    left: 2,
                    top: 1,
                    child: AnimatedSlide(
                      offset: selected ? const Offset(0, -0.06) : Offset.zero,
                      duration: _duration,
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        selected ? activeIcon : icon,
                        size: 24,
                        color: color,
                      ),
                    ),
                  ),
                  if (badge > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: _CountBadge(count: badge),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: AnimatedDefaultTextStyle(
                  duration: _duration,
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 0.2,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: color,
                    fontFamily: DefaultTextStyle.of(context).style.fontFamily,
                  ),
                  child: Text(label, maxLines: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Đốm tròn gradient cam trong mờ với viền sáng, như viên kính màu
class _GlassDot extends StatelessWidget {
  final double size;

  const _GlassDot({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFD27A).withValues(alpha: 0.95),
            AppColors.primary.withValues(alpha: 0.75),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
          width: 1.2,
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFD93F11),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Text(
        count > 9 ? '9+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9.5,
          height: 1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
