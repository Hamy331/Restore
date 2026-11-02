/// Tài khoản mẫu cho [MockAuthRepository], cùng dạng JSON `user` của API /auth.
class AuthMockData {
  AuthMockData._();

  /// Mật khẩu chung của mọi tài khoản mẫu
  static const String password = 'Password@123';

  /// Mã OTP mẫu (xác minh email, quên mật khẩu)
  static const String otp = '123456';

  /// Token mẫu = tiền tố + email, để mở lại app vẫn biết ai đang đăng nhập
  static const String tokenPrefix = 'mock-session:';

  static const List<Map<String, dynamic>> accounts = [
    {
      'id': 'user_me',
      'email': 'minhanh@example.com',
      'fullName': 'Nguyễn Minh Anh',
      'username': 'minhanh',
      'role': 'USER',
      'status': 'ACTIVE',
    },
    {
      'id': 'user_admin',
      'email': 'admin@restore.vn',
      'fullName': 'Quản trị ReStore',
      'username': 'admin',
      'role': 'ADMIN',
      'status': 'ACTIVE',
    },
  ];
}
