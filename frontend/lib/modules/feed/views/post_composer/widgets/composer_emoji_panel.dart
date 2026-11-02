import 'package:flutter/material.dart';

/// Bảng biểu cảm hay dùng thay chỗ bàn phím; bấm để chèn vào nội dung.
class ComposerEmojiPanel extends StatelessWidget {
  final ValueChanged<String> onSelected;

  const ComposerEmojiPanel({super.key, required this.onSelected});

  static const List<String> _emojis = [
    '😀', '😂', '🥰', '😍', '😎', '🤩', '😉', '😊', //
    '🤔', '😅', '😭', '😡', '🥳', '😴', '🤗', '🙏', //
    '👍', '👏', '🙌', '💪', '🤝', '👌', '✌️', '👀', //
    '❤️', '🧡', '💛', '💚', '💙', '💜', '🔥', '✨', //
    '🎉', '🎁', '🛍️', '📦', '💸', '🏷️', '♻️', '🌱', //
    '📱', '💻', '📷', '🎧', '⌚', '🪑', '🛋️', '🚲', //
  ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white.withValues(alpha: 0.55),
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
        ),
        itemCount: _emojis.length,
        itemBuilder: (_, index) => InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onSelected(_emojis[index]),
          child: Center(
            child: Text(_emojis[index], style: const TextStyle(fontSize: 26)),
          ),
        ),
      ),
    );
  }
}
