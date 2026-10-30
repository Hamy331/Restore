/// Xử lý chuỗi tiếng Việt, VD tìm "thu duc" vẫn ra "Thủ Đức"
class VietnameseText {
  VietnameseText._();

  static const String _withMarks =
      'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
  static const String _withoutMarks =
      'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';

  static final Map<String, String> _map = {
    for (var i = 0; i < _withMarks.length; i++) _withMarks[i]: _withoutMarks[i],
  };

  /// Chữ thường, bỏ dấu, gộp khoảng trắng
  static String normalize(String input) {
    final buffer = StringBuffer();
    for (final char in input.toLowerCase().split('')) {
      buffer.write(_map[char] ?? char);
    }
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static bool matches(String text, String query) =>
      normalize(text).contains(normalize(query));

  /// Vị trí [query] trong [text] khi so không dấu, để tô đậm phần khớp
  /// trong gợi ý tìm kiếm. Trả về null nếu không khớp.
  static (int, int)? matchRange(String text, String query) {
    final needle = _fold(query.trim());
    if (needle.isEmpty) return null;
    final start = _fold(text).indexOf(needle);
    return start < 0 ? null : (start, start + needle.length);
  }

  /// Chữ thường bỏ dấu, giữ nguyên độ dài để vị trí khớp với chuỗi gốc
  static String _fold(String input) =>
      input.toLowerCase().split('').map((char) => _map[char] ?? char).join();
}
