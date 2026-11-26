/// Tạo và đọc đường dẫn có tên dễ đọc, VD
/// `/listings/smart-tivi-samsung-fb7069e6-b353-4024-87f2-e5a7eeb6ca66`.
///
/// Phần tên chỉ để đẹp; id (UUID) ở cuối mới là thứ app dùng để tải dữ liệu,
/// nên đổi tên tin hay sửa tên trong link vẫn mở đúng trang.
library;

const _from =
    'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
const _to =
    'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';

final _uuidTail = RegExp(
  r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

/// "Smart Tivi Mini LED 65 inch" -> "smart-tivi-mini-led-65-inch"
String slugify(String text, {int maxLength = 60}) {
  final out = StringBuffer();
  for (final ch in text.toLowerCase().split('')) {
    final i = _from.indexOf(ch);
    out.write(i >= 0 ? _to[i] : ch);
  }
  var slug = out
      .toString()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  if (slug.length > maxLength) {
    slug = slug.substring(0, maxLength).replaceAll(RegExp(r'-+$'), '');
  }
  return slug;
}

/// `/listings/<tên>-<id>`; không có tên thì chỉ còn `/listings/<id>`.
String slugPath(String base, String id, String? title) {
  final slug = slugify(title ?? '');
  return slug.isEmpty ? '$base/$id' : '$base/$slug-$id';
}

/// Lấy id từ phần cuối đường dẫn. Dạng cũ (chỉ có id) vẫn dùng được.
String idFromSlug(String param) => _uuidTail.stringMatch(param) ?? param;

/// Mã số ngắn ở cuối đường dẫn (`ten-tin-12345` hoặc `12345`); null nếu không có.
int? shortIdFromSlug(String param) {
  final match = RegExp(r'(?:^|-)(\d{1,10})$').firstMatch(param);
  return match == null ? null : int.tryParse(match.group(1)!);
}

/// Đường dẫn dạng UUID đầy đủ (link cũ)?
bool hasUuid(String param) => _uuidTail.hasMatch(param);
