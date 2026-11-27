/// Đường dẫn trang hồ sơ công khai: `/u/@tên-người-dùng`.
///
/// Chưa biết tên người dùng thì dùng `/users/<id>`; trang đó tự chuyển sang
/// dạng `/u/@tên` sau khi tải xong hồ sơ.
String profilePath({required String id, String? username}) {
  final name = username?.trim() ?? '';
  return name.isEmpty ? '/users/$id' : '/u/@$name';
}

/// `/u/:handle` mang dạng `@tên`; trả về tên không có `@`, hoặc null nếu
/// [param] không phải dạng tên người dùng (VD là UUID của đường dẫn cũ).
String? usernameFromHandle(String param) =>
    param.startsWith('@') && param.length > 1 ? param.substring(1) : null;
