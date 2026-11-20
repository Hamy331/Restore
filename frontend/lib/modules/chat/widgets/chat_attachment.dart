import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../models/chat_models.dart';
import '../repositories/chat_repository.dart';

class ChatAttachment extends StatefulWidget {
  const ChatAttachment({
    super.key,
    required this.thread,
    required this.message,
  });
  final String thread;
  final ChatMessage message;
  @override
  State<ChatAttachment> createState() => _ChatAttachmentState();
}

class _ChatAttachmentState extends State<ChatAttachment> {
  late Future<Uri> link = _link();
  Future<Uri> _link() =>
      ApiChatRepository().mediaLink(widget.thread, widget.message.id);
  void retry() => setState(() => link = _link());
  @override
  Widget build(BuildContext context) {
    if (widget.message.isVideo) {
      return TextButton.icon(
        icon: const Icon(Icons.play_circle_fill),
        label: const Text('Xem video'),
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => _VideoViewer(link: _link),
        ),
      );
    }
    return FutureBuilder<Uri>(
      future: link,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return IconButton(
            tooltip: 'Tải lại tệp',
            onPressed: retry,
            icon: const Icon(Icons.refresh),
          );
        }
        final uri = snapshot.data;
        if (uri == null) {
          return const SizedBox.square(
            dimension: 26,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }
        return InkWell(
          onTap: () => showDialog<void>(
            context: context,
            builder: (ctx) => Dialog.fullscreen(
              child: Stack(
                children: [
                  Center(
                    child: InteractiveViewer(
                      maxScale: 5,
                      child: Image.network(uri.toString()),
                    ),
                  ),
                  SafeArea(
                    child: CloseButton(onPressed: () => Navigator.pop(ctx)),
                  ),
                ],
              ),
            ),
          ),
          child: Image.network(
            uri.toString(),
            fit: BoxFit.cover,
            height: 130,
            width: 180,
            errorBuilder: (_, e, s) => IconButton(
              tooltip: 'Tải lại ảnh',
              onPressed: retry,
              icon: const Icon(Icons.refresh),
            ),
          ),
        );
      },
    );
  }
}

class _VideoViewer extends StatefulWidget {
  const _VideoViewer({required this.link});
  final Future<Uri> Function() link;
  @override
  State<_VideoViewer> createState() => _VideoViewerState();
}

class _VideoViewerState extends State<_VideoViewer> {
  VideoPlayerController? player;
  Uri? url;
  late final ready = initialize();
  Future<void> initialize() async {
    url = await widget.link();
    if (!mounted) return;
    final controller = VideoPlayerController.networkUrl(url!);
    player = controller;
    await controller.initialize();
    if (mounted) await controller.play();
  }

  @override
  void dispose() {
    player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog.fullscreen(
    child: Scaffold(
      appBar: AppBar(title: const Text('Video'), leading: const CloseButton()),
      body: Center(
        child: FutureBuilder<void>(
          future: ready,
          builder: (context, snap) {
            if (snap.hasError) {
              return TextButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text('Mở bằng trình phát trên thiết bị'),
                onPressed: url == null
                    ? null
                    : () async {
                        if (!await launchUrl(url!) && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Thiết bị không mở được video này.',
                              ),
                            ),
                          );
                        }
                      },
              );
            }
            if (snap.connectionState != ConnectionState.done) {
              return const CircularProgressIndicator();
            }
            final controller = player!;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: VideoPlayer(controller),
                  ),
                ),
                VideoProgressIndicator(controller, allowScrubbing: true),
                ValueListenableBuilder<VideoPlayerValue>(
                  valueListenable: controller,
                  builder: (_, value, child) => IconButton(
                    tooltip: value.isPlaying ? 'Tạm dừng' : 'Phát',
                    icon: Icon(
                      value.isPlaying ? Icons.pause : Icons.play_arrow,
                    ),
                    onPressed: value.isPlaying
                        ? controller.pause
                        : controller.play,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}
