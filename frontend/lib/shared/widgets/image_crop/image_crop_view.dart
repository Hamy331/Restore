import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_bottom_action_bar.dart';
import 'package:restore/shared/widgets/loading/app_loading_indicator.dart';

import 'image_crop.dart';
import 'image_crop_area.dart';

/// Màn cắt ảnh dùng chung (poster, ảnh đại diện...): khung cố định theo
/// [frame], kéo để di chuyển, chụm hai ngón / cuộn chuột / thanh trượt để thu
/// phóng, hai nút căn tự động (lấp đầy khung hoặc vừa toàn ảnh với nền mờ).
/// Trả về ảnh PNG cỡ [CropFrame.output].
class ImageCropView extends StatefulWidget {
  const ImageCropView({
    super.key,
    required this.bytes,
    required this.frame,
    required this.title,
  });

  /// Ảnh gốc người dùng chọn
  final Uint8List bytes;
  final CropFrame frame;
  final String title;

  /// Mở màn cắt, trả về ảnh đã cắt (null nếu đóng)
  static Future<Uint8List?> open(
    BuildContext context,
    Uint8List bytes, {
    required CropFrame frame,
    required String title,
  }) => Navigator.of(context).push<Uint8List>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => ImageCropView(bytes: bytes, frame: frame, title: title),
    ),
  );

  @override
  State<ImageCropView> createState() => _ImageCropViewState();
}

/// Cách tô phần trống khi ảnh không phủ kín khung
enum _Background { blur, auto, white, black }

class _ImageCropViewState extends State<ImageCropView> {
  ui.Image? _image;
  ImageCropTransform? _transform;

  /// Logo thường có nền trơn: khung tròn mặc định lấy màu viền ảnh làm nền
  late _Background _background = widget.frame.shape == CropShape.circle
      ? _Background.auto
      : _Background.blur;
  Color? _edgeColor;

  /// Ảnh gốc và vùng nội dung khi bỏ dải viền một màu ở mép (nếu có).
  /// Khi đang bỏ viền, [_image] là ảnh đã cắt còn [_original] giữ ảnh gốc.
  ui.Image? _original;
  Rect? _trimRect;
  bool _busy = false;
  bool _failed = false, _saving = false;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  Future<void> _decode() async {
    try {
      final image = await decodeImageFromList(widget.bytes);
      if (!mounted) {
        image.dispose();
        return;
      }
      setState(() {
        _image = image;
        // tự căn: phủ kín khung, lấy phần giữa ảnh
        _transform = ImageCropTransform.cover(_size(image), widget.frame);
      });
      final edge = await sampleEdgeColor(image);
      final trim = await detectUniformBorders(image);
      if (mounted) {
        setState(() {
          _edgeColor = edge;
          _trimRect = trim;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  /// Bật / tắt bỏ viền thừa. Bỏ viền xong thì căn vừa toàn ảnh để thấy hết
  /// nội dung (VD logo), tắt thì quay về ảnh gốc phủ kín khung.
  Future<void> _toggleTrim() async {
    final rect = _trimRect, image = _image;
    if (rect == null || image == null || _busy) return;
    setState(() => _busy = true);
    final original = _original;
    final ui.Image next;
    if (original == null) {
      next = await cropImage(image, rect);
    } else {
      image.dispose();
      next = original;
    }
    final edge = await sampleEdgeColor(next);
    if (!mounted) {
      if (original == null) next.dispose();
      return;
    }
    setState(() {
      _original = original == null ? image : null;
      _image = next;
      _edgeColor = edge;
      // khung tròn: chừa thêm chút lề quanh logo
      _transform = original == null
          ? ImageCropTransform(
              scale:
                  ImageCropTransform.containScale(_size(next), widget.frame) *
                  (widget.frame.shape == CropShape.circle ? 0.85 : 1),
            )
          : ImageCropTransform.cover(_size(next), widget.frame);
      _busy = false;
    });
  }

  @override
  void dispose() {
    _original?.dispose();
    _image?.dispose();
    super.dispose();
  }

  static Size _size(ui.Image image) =>
      Size(image.width.toDouble(), image.height.toDouble());

  void _update(ImageCropTransform transform) {
    final image = _image;
    if (image == null) return;
    setState(() => _transform = transform.clamped(_size(image), widget.frame));
  }

  Future<void> _done() async {
    final image = _image, transform = _transform;
    if (image == null || transform == null || _saving) return;
    setState(() => _saving = true);
    try {
      final bytes = await renderImageCrop(
        image,
        transform,
        widget.frame,
        background: _backgroundColor,
      );
      if (mounted) Navigator.of(context).pop(bytes);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Color? get _backgroundColor => switch (_background) {
    _Background.blur => null,
    _Background.auto => _edgeColor ?? Colors.white,
    _Background.white => Colors.white,
    _Background.black => Colors.black,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final image = _image, transform = _transform;
    final size = image == null ? null : _size(image);
    final frame = widget.frame;
    final lowRes = transform != null && transform.lowRes(frame);
    return Scaffold(
      backgroundColor: const Color(0xFF15120E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF15120E),
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          icon: const Icon(AppIcons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(widget.title),
      ),
      bottomNavigationBar: AppBottomActionBar(
        key: const ValueKey('image-crop-done'),
        primaryLabel: l.cropDone,
        primaryIcon: AppIcons.check,
        isLoading: _saving,
        onPrimary: image == null || _saving ? null : _done,
      ),
      body: _failed
          ? Center(
              child: Text(
                l.cropLoadError,
                style: const TextStyle(color: Colors.white70),
              ),
            )
          : image == null || transform == null || size == null
          ? const Center(child: AppLoadingIndicator())
          : Column(
              children: [
                Expanded(
                  child: ImageCropArea(
                    image: image,
                    frame: frame,
                    background: _backgroundColor,
                    transform: transform,
                    onChanged: _update,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            AppIcons.minus,
                            size: 18,
                            color: Colors.white70,
                          ),
                          Expanded(
                            child: Slider(
                              key: const ValueKey('image-crop-zoom'),
                              value: transform.scale,
                              min: ImageCropTransform.minScale(size, frame),
                              max: ImageCropTransform.maxScale(size, frame),
                              activeColor: AppColors.primary,
                              inactiveColor: Colors.white24,
                              semanticFormatterCallback: (_) => l.cropZoom,
                              onChanged: (value) =>
                                  _update(transform.copyWith(scale: value)),
                            ),
                          ),
                          const Icon(
                            AppIcons.add,
                            size: 18,
                            color: Colors.white70,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _AutoButton(
                              key: const ValueKey('image-crop-fill'),
                              icon: AppIcons.expand,
                              label: l.cropFill,
                              onTap: () => _update(
                                ImageCropTransform.cover(size, frame),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _AutoButton(
                              key: const ValueKey('image-crop-fit'),
                              icon: AppIcons.image,
                              label: l.cropFit,
                              onTap: () => _update(
                                ImageCropTransform.contain(size, frame),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_trimRect != null) ...[
                        const SizedBox(height: 10),
                        _TrimToggle(
                          on: _original != null,
                          onTap: _busy ? null : _toggleTrim,
                        ),
                      ],
                      if (transform.leavesGap(size, frame)) ...[
                        const SizedBox(height: 12),
                        _BackgroundPicker(
                          value: _background,
                          autoColor: _edgeColor ?? Colors.white,
                          onChanged: (value) =>
                              setState(() => _background = value),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        lowRes ? l.cropLowRes : l.cropHint,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: lowRes ? AppColors.primary : Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _AutoButton extends StatelessWidget {
  const _AutoButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 16),
    label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      side: const BorderSide(color: Colors.white30),
      padding: const EdgeInsets.symmetric(vertical: 12),
      shape: const StadiumBorder(),
    ),
  );
}

/// Chọn nền cho phần trống: mờ theo ảnh, màu viền ảnh, trắng hoặc đen
class _BackgroundPicker extends StatelessWidget {
  const _BackgroundPicker({
    required this.value,
    required this.autoColor,
    required this.onChanged,
  });

  final _Background value;
  final Color autoColor;
  final ValueChanged<_Background> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    Widget option(_Background option, String label, Widget swatch) {
      final selected = option == value;
      return Expanded(
        child: GestureDetector(
          key: ValueKey('image-crop-bg-${option.name}'),
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(option),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 34,
                height: 34,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.primary : Colors.white24,
                    width: 2,
                  ),
                ),
                child: ClipOval(child: swatch),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? Colors.white : Colors.white60,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 18),
          child: Text(
            l.cropBackground,
            style: const TextStyle(fontSize: 12.5, color: Colors.white70),
          ),
        ),
        option(
          _Background.blur,
          l.cropBgBlur,
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8A7F70), Color(0xFF3A342C)],
              ),
            ),
          ),
        ),
        option(_Background.auto, l.cropBgAuto, ColoredBox(color: autoColor)),
        option(
          _Background.white,
          l.cropBgWhite,
          const ColoredBox(color: Colors.white),
        ),
        option(
          _Background.black,
          l.cropBgBlack,
          const ColoredBox(color: Colors.black),
        ),
      ],
    );
  }
}

/// Nút bật / tắt "Bỏ viền thừa" (dải một màu ở mép ảnh)
class _TrimToggle extends StatelessWidget {
  const _TrimToggle({required this.on, required this.onTap});

  final bool on;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return OutlinedButton.icon(
      key: const ValueKey('image-crop-trim'),
      onPressed: onTap,
      icon: Icon(on ? AppIcons.check : AppIcons.scissors, size: 16),
      label: Text(on ? l.cropTrimOn : l.cropTrim),
      style: OutlinedButton.styleFrom(
        foregroundColor: on ? AppColors.textPrimary : Colors.white,
        backgroundColor: on ? AppColors.primary : Colors.transparent,
        side: BorderSide(color: on ? AppColors.primary : Colors.white30),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: const StadiumBorder(),
      ),
    );
  }
}
