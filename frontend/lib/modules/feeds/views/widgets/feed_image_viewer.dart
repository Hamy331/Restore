import 'package:flutter/material.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_local_image.dart';

/// Xem ảnh toàn màn hình, chụm hai ngón để phóng to.
Future<void> showFeedImage(
  BuildContext context,
  String url, {
  required String heroTag,
}) => Navigator.of(context, rootNavigator: true).push<void>(
  PageRouteBuilder(
    opaque: false,
    barrierColor: Colors.black,
    pageBuilder: (_, _, _) => _FeedImageViewer(url: url, heroTag: heroTag),
    transitionsBuilder: (_, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  ),
);

class _FeedImageViewer extends StatelessWidget {
  const _FeedImageViewer({required this.url, required this.heroTag});
  final String url, heroTag;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: Stack(
      children: [
        Positioned.fill(
          child: InteractiveViewer(
            maxScale: 4,
            child: Center(
              child: Hero(
                tag: heroTag,
                child: AppLocalImage(path: url, fit: BoxFit.contain),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: IconButton(
              tooltip: AppLocalizations.of(context)!.feedCloseImage,
              color: Colors.white,
              icon: const Icon(AppIcons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ],
    ),
  );
}
