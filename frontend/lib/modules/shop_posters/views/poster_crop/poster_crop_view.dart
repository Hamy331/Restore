import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_bottom_action_bar.dart';
import 'package:restore/shared/widgets/loading/app_loading_indicator.dart';

import '../../utils/poster_crop.dart';
import 'widgets/poster_crop_area.dart';

/// Màn cắt ảnh poster: khung 2:1 cố định, kéo để di chuyển, chụm hai ngón /
/// cuộn chuột / thanh trượt để thu phóng, hai nút căn tự động (lấp đầy khung
/// hoặc vừa toàn ảnh với nền mờ). Trả về ảnh PNG 1200×600 đã cắt.
class PosterCropView extends StatefulWidget {
  const PosterCropView({super.key, required this.bytes});

  /// Ảnh gốc người dùng chọn
  final Uint8List bytes;

  /// Mở màn cắt, trả về ảnh đã cắt (null nếu đóng)
  static Future<Uint8List?> open(BuildContext context, Uint8List bytes) =>
      Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => PosterCropView(bytes: bytes),
        ),
      );

  @override
  State<PosterCropView> createState() => _PosterCropViewState();
}

class _PosterCropViewState extends State<PosterCropView> {
  ui.Image? _image;
  PosterCropTransform? _transform;
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
        _transform = PosterCropTransform.cover(_size(image));
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  static Size _size(ui.Image image) =>
      Size(image.width.toDouble(), image.height.toDouble());

  void _update(PosterCropTransform transform) {
    final image = _image;
    if (image == null) return;
    setState(() => _transform = transform.clamped(_size(image)));
  }

  Future<void> _done() async {
    final image = _image, transform = _transform;
    if (image == null || transform == null || _saving) return;
    setState(() => _saving = true);
    try {
      final bytes = await renderPosterCrop(image, transform);
      if (mounted) Navigator.of(context).pop(bytes);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final image = _image, transform = _transform;
    final size = image == null ? null : _size(image);
    // mỗi px ảnh gốc bị phóng lên hơn 1,5 px ở poster 1200×600 thì dễ mờ
    final lowRes =
        transform != null && transform.scale * posterOutputSize.width > 1.5;
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
        title: Text(l.spCropTitle),
      ),
      bottomNavigationBar: AppBottomActionBar(
        key: const ValueKey('poster-crop-done'),
        primaryLabel: l.spCropDone,
        primaryIcon: AppIcons.check,
        isLoading: _saving,
        onPrimary: image == null || _saving ? null : _done,
      ),
      body: _failed
          ? Center(
              child: Text(
                l.spErrImage,
                style: const TextStyle(color: Colors.white70),
              ),
            )
          : image == null || transform == null || size == null
          ? const Center(child: AppLoadingIndicator())
          : Column(
              children: [
                Expanded(
                  child: PosterCropArea(
                    image: image,
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
                              key: const ValueKey('poster-crop-zoom'),
                              value: transform.scale,
                              min: PosterCropTransform.minScale(size),
                              max: PosterCropTransform.maxScale(size),
                              activeColor: AppColors.primary,
                              inactiveColor: Colors.white24,
                              semanticFormatterCallback: (_) => l.spCropZoom,
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
                              key: const ValueKey('poster-crop-fill'),
                              icon: AppIcons.expand,
                              label: l.spCropFill,
                              onTap: () =>
                                  _update(PosterCropTransform.cover(size)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _AutoButton(
                              key: const ValueKey('poster-crop-fit'),
                              icon: AppIcons.image,
                              label: l.spCropFit,
                              onTap: () =>
                                  _update(PosterCropTransform.contain(size)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        lowRes ? l.spCropLowRes : l.spCropHint,
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
