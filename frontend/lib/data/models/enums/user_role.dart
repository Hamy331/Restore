/// Vai trò tài khoản (Role). 
enum UserRole {
  user('USER'),
  admin('ADMIN');

  const UserRole(this.apiValue);

  final String apiValue;

  static UserRole fromApi(String? value) => values.firstWhere(
    (role) => role.apiValue == value,
    orElse: () => UserRole.user,
  );
}
