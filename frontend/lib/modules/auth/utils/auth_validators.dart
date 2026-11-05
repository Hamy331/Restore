class AuthValidators {
  AuthValidators._();

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Vui lòng nhập email.';
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
        ? null
        : 'Email chưa đúng định dạng.';
  }

  static String? fullName(String? value) {
    final name = value?.trim().replaceAll(RegExp(r'\s+'), ' ') ?? '';
    return name.length >= 2 && name.length <= 80
        ? null
        : 'Họ tên phải có từ 2 đến 80 ký tự.';
  }

  static String? username(String? value) {
    final username = value?.trim().toLowerCase() ?? '';
    return RegExp(r'^[a-z0-9._]{3,30}$').hasMatch(username)
        ? null
        : 'Dùng 3-30 ký tự: chữ thường, số, dấu chấm hoặc gạch dưới.';
  }

  static String? password(String? value) {
    final password = value ?? '';
    return RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,72}$').hasMatch(password)
        ? null
        : 'Mật khẩu cần 8-72 ký tự, có chữ hoa, chữ thường và số.';
  }

  static String? requiredPassword(String? value) =>
      (value == null || value.isEmpty) ? 'Vui lòng nhập mật khẩu.' : null;

  static String? confirmation(String? value, String password) =>
      value == password ? null : 'Mật khẩu xác nhận chưa trùng khớp.';
}
