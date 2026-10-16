import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_local_image.dart';

/// Mở trình xem ảnh toàn màn hình: vuốt ngang đổi ảnh, chụm hoặc chạm hai
/// lần để phóng to, chạm một lần để ẩn/hiện thanh điều khiển, kéo dọc để đóng.
/// Trả về vị trí ảnh đang xem khi đóng.
///
/// [heroTag] trùng với [AppImageGallery.heroTag] để ảnh bay mượt giữa hai màn.
/// [onPageChanged] báo vị trí mới ngay khi vuốt để thư viện bên dưới nhảy
/// theo trước khi đóng, nhờ vậy ảnh bay về đúng chỗ.
Future<int?> showAppPhotoViewer(
  BuildContext context, {
  required List<String> images,
  int initialIndex = 0,
  String? heroTag,
  ValueChanged<int>? onPageChanged,
}) {
  return Navigator.of(context, rootNavigator: true).push<int>(
    PageRouteBuilder<int>(
      opaque: false,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      // Nền đen và thanh điều khiển tự mờ theo animation của route,
      // còn ảnh do Hero lo nên không bọc thêm hiệu ứng ở đây
      pageBuilder: (_, animation, _) => AppPhotoViewer(
        images: images,
        initialIndex: initialIndex,
        heroTag: heroTag,
        routeAnimation: animation,
        onPageChanged: onPageChanged,
      ),
    ),
  );
}

/// Tag Hero của ảnh thứ [index], dùng chung cho thư viện và trình xem ảnh
String appGalleryHeroTag(String prefix, int index) => '$prefix-photo-$index';

/// Ảnh khi đang bay giữa thư viện (cắt vuông, cover) và trình xem
/// (vừa khung, contain): hoà dần hai kiểu để không bị giật lúc hạ cánh.
/// [animation] = 0 ở thư viện, 1 ở trình xem (cả lúc mở và lúc đóng).
Widget appGalleryHeroShuttle(String path, Animation<double> animation) {
  final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
  return Stack(
    fit: StackFit.expand,
    children: [
      FadeTransition(
        opacity: ReverseAnimation(curved),
        child: AppLocalImage(path: path),
      ),
      FadeTransition(
        opacity: curved,
        child: AppLocalImage(path: path, fit: BoxFit.contain),
      ),
    ],
  );
}

class AppPhotoViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String? heroTag;
  final Animation<double>? routeAnimation;
  final ValueChanged<int>? onPageChanged;

  const AppPhotoViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.heroTag,
    this.routeAnimation,
    this.onPageChanged,
  });

  @override
  State<AppPhotoViewer> createState() => _AppPhotoViewerState();
}

class _AppPhotoViewerState extends State<AppPhotoViewer>
    with SingleTickerProviderStateMixin {
  static const double _thumbSize = 56;

  /// Kéo quá khoảng này (hoặc vuốt nhanh) thì đóng trình xem
  static const double _dismissDistance = 120;
  static const double _dismissVelocity = 700;

  /// Độ lệch dọc khi kéo để đóng; nền đen nhạt dần theo
  final _drag = ValueNotifier<double>(0);
  late final AnimationController _dragReset;
  double _dragResetFrom = 0;

  late final PageController _pageController;
  late final ScrollController _thumbController;
  late int _current;

  /// Ảnh đang phóng to thì khoá vuốt ngang để kéo xem chi tiết
  bool _zoomed = false;
  bool _showChrome = true;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex.clamp(0, widget.images.length - 1);
    _pageController = PageController(initialPage: _current);
    _thumbController = ScrollController();
    _dragReset =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 220),
        )..addListener(() {
          final t = Curves.easeOutCubic.transform(_dragReset.value);
          _drag.value = _dragResetFrom * (1 - t);
        });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollThumbIntoView());
  }

  @override
  void dispose() {
    _pageController.dispose();
    _thumbController.dispose();
    _dragReset.dispose();
    _drag.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop(_current);

  void _onPageChanged(int index) {
    setState(() {
      _current = index;
      _zoomed = false;
    });
    widget.onPageChanged?.call(index);
    _scrollThumbIntoView();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _dragReset.stop();
    _drag.value += details.delta.dy;
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dy.abs();
    if (_drag.value.abs() > _dismissDistance || velocity > _dismissVelocity) {
      _close();
      return;
    }
    _dragResetFrom = _drag.value;
    _dragReset.forward(from: 0);
  }

  /// Độ đậm nền: theo animation mở/đóng và nhạt dần khi kéo
  double get _backdropOpacity {
    final route = widget.routeAnimation?.value ?? 1;
    final drag = (1 - _drag.value.abs() / 400).clamp(0.0, 1.0);
    return route * drag;
  }

  void _scrollThumbIntoView() {
    if (!_thumbController.hasClients) return;
    final viewport = _thumbController.position.viewportDimension;
    final target = _current * (_thumbSize + 8) - (viewport - _thumbSize) / 2;
    _thumbController.animateTo(
      target.clamp(0, _thumbController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final images = widget.images;
    final padding = MediaQuery.paddingOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _close();
        },
        child: Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_drag, ?widget.routeAnimation]),
                  builder: (_, _) => ColoredBox(
                    color: Colors.black.withValues(alpha: _backdropOpacity),
                  ),
                ),
              ),
              GestureDetector(
                // Đang phóng to thì nhường thao tác kéo cho việc xem ảnh
                onVerticalDragUpdate: _zoomed ? null : _onDragUpdate,
                onVerticalDragEnd: _zoomed ? null : _onDragEnd,
                child: ValueListenableBuilder<double>(
                  valueListenable: _drag,
                  builder: (_, offset, child) => Transform.translate(
                    offset: Offset(0, offset),
                    child: Transform.scale(
                      scale: 1 - (offset.abs() / 2000).clamp(0.0, 0.15),
                      child: child,
                    ),
                  ),
                  child: PageView.builder(
                    controller: _pageController,
                    physics: _zoomed
                        ? const NeverScrollableScrollPhysics()
                        : const BouncingScrollPhysics(),
                    itemCount: images.length,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (_, index) => _ZoomablePhoto(
                      path: images[index],
                      heroTag: widget.heroTag == null
                          ? null
                          : appGalleryHeroTag(widget.heroTag!, index),
                      onTap: () => setState(() => _showChrome = !_showChrome),
                      onZoomChanged: (zoomed) {
                        if (index == _current && zoomed != _zoomed) {
                          setState(() => _zoomed = zoomed);
                        }
                      },
                    ),
                  ),
                ),
              ),
              // Thanh trên: nút đóng + vị trí ảnh
              _Chrome(
                visible: _showChrome,
                top: true,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(8, padding.top + 4, 16, 8),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).closeButtonTooltip,
                        onPressed: _close,
                        icon: const Icon(AppIcons.close, color: Colors.white),
                      ),
                      const Spacer(),
                      if (images.length > 1)
                        Text(
                          l10n.galleryPosition(_current + 1, images.length),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (images.length > 1)
                _Chrome(
                  visible: _showChrome && !_zoomed,
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: 12,
                      bottom: padding.bottom + 16,
                    ),
                    child: SizedBox(
                      height: _thumbSize,
                      child: ListView.separated(
                        controller: _thumbController,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: images.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (_, index) => _Thumbnail(
                          path: images[index],
                          size: _thumbSize,
                          selected: index == _current,
                          onTap: () => _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                          ),
                        ),
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

/// Thanh điều khiển mờ dần khi ẩn, nền gradient tối để chữ trắng dễ đọc
class _Chrome extends StatelessWidget {
  final bool visible;
  final bool top;
  final Widget child;

  const _Chrome({
    required this.visible,
    required this.top,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      top: top ? 0 : null,
      bottom: top ? null : 0,
      child: IgnorePointer(
        ignoring: !visible,
        child: _RouteFade(
          child: AnimatedOpacity(
            opacity: visible ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: top ? Alignment.topCenter : Alignment.bottomCenter,
                  end: top ? Alignment.bottomCenter : Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0),
                  ],
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Thanh điều khiển hiện/ẩn theo animation mở/đóng trình xem
class _RouteFade extends StatelessWidget {
  final Widget child;

  const _RouteFade({required this.child});

  @override
  Widget build(BuildContext context) {
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null) return child;
    return FadeTransition(opacity: animation, child: child);
  }
}

class _Thumbnail extends StatelessWidget {
  final String path;
  final double size;
  final bool selected;
  final VoidCallback onTap;

  const _Thumbnail({
    required this.path,
    required this.size,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: selected ? 1 : 0.55,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: AppLocalImage(path: path, cacheWidth: 160),
          ),
        ),
      ),
    );
  }
}

/// Một ảnh có thể chụm để phóng to (tối đa 4x) và chạm hai lần để
/// phóng to đúng chỗ chạm / thu về như cũ
class _ZoomablePhoto extends StatefulWidget {
  final String path;
  final String? heroTag;
  final VoidCallback onTap;
  final ValueChanged<bool> onZoomChanged;

  const _ZoomablePhoto({
    required this.path,
    required this.heroTag,
    required this.onTap,
    required this.onZoomChanged,
  });

  @override
  State<_ZoomablePhoto> createState() => _ZoomablePhotoState();
}

class _ZoomablePhotoState extends State<_ZoomablePhoto>
    with SingleTickerProviderStateMixin {
  static const double _doubleTapScale = 2.5;

  final _transform = TransformationController();
  late final AnimationController _animation;
  Animation<Matrix4>? _zoomAnimation;
  Offset _doubleTapPosition = Offset.zero;
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _animation =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 240),
        )..addListener(() {
          final value = _zoomAnimation?.value;
          if (value != null) _transform.value = value;
        });
    _transform.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _animation.dispose();
    _transform.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    final zoomed = _transform.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed == _zoomed) return;
    _zoomed = zoomed;
    widget.onZoomChanged(zoomed);
  }

  void _onDoubleTap() {
    final position = _doubleTapPosition;
    final end = _zoomed
        ? Matrix4.identity()
        : (Matrix4.identity()
            ..translateByDouble(
              -position.dx * (_doubleTapScale - 1),
              -position.dy * (_doubleTapScale - 1),
              0,
              1,
            )
            ..scaleByDouble(_doubleTapScale, _doubleTapScale, 1, 1));
    _zoomAnimation = Matrix4Tween(
      begin: _transform.value,
      end: end,
    ).animate(CurvedAnimation(parent: _animation, curve: Curves.easeOutCubic));
    _animation.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    Widget image = AppLocalImage(path: widget.path, fit: BoxFit.contain);
    if (widget.heroTag != null) {
      image = Hero(
        tag: widget.heroTag!,
        flightShuttleBuilder: (_, animation, _, _, _) =>
            appGalleryHeroShuttle(widget.path, animation),
        child: image,
      );
    }

    return GestureDetector(
      onTap: widget.onTap,
      onDoubleTapDown: (details) => _doubleTapPosition = details.localPosition,
      onDoubleTap: _onDoubleTap,
      child: InteractiveViewer(
        transformationController: _transform,
        minScale: 1,
        maxScale: 4,
        child: SizedBox.expand(child: image),
      ),
    );
  }
}
