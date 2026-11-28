/// Số di động Việt Nam như backend (parsePhone): bỏ khoảng trắng, dấu chấm,
/// gạch, ngoặc; +84 / 84 thành 0; đủ 10 số bắt đầu 03, 05, 07, 08, 09.
/// Rỗng trả '' (xoá số), sai định dạng trả null.
String? normalizePhone(String text) {
  final digits = text.replaceAll(RegExp(r'[\s.\-()]'), '');
  if (digits.isEmpty) return '';
  final local = digits.replaceFirst(
    RegExp(r'^(\+84|84)(?=[35789]\d{8}$)'),
    '0',
  );
  return RegExp(r'^0[35789]\d{8}$').hasMatch(local) ? local : null;
}
