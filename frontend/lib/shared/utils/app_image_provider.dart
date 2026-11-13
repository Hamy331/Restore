import 'package:flutter/widgets.dart';

/// Ảnh từ URL (http/https) hoặc ảnh trong assets của app (VD logo shop seed
/// "assets/images/shops/samsung.png"), dùng cho CircleAvatar.foregroundImage.
ImageProvider appImageProvider(String path) =>
    path.startsWith('assets/') ? AssetImage(path) : NetworkImage(path);
