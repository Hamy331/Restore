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
}
