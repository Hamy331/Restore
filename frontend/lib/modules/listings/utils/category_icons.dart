import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_icons.dart';

/// Đổi khoá icon từ API (VD "phone") sang IconData của app.
/// Thêm danh mục mới ở backend chỉ cần dùng một khoá có sẵn ở đây.
class CategoryIcons {
  CategoryIcons._();

  static const IconData fallback = AppIcons.category;

  static const Map<String, IconData> _icons = {
    'phone': AppIcons.categoryPhone,
    'electronics': AppIcons.categoryElectronics,
    'vehicle': AppIcons.categoryVehicle,
    'fashion': AppIcons.categoryFashion,
    'appliance': AppIcons.categoryAppliance,
    'pet': AppIcons.categoryPet,
    'home': AppIcons.categoryHome,
    'book': AppIcons.categoryBook,
    'sport': AppIcons.categorySport,
    'baby': AppIcons.categoryBaby,
    'other': AppIcons.categoryOther,
  };

  static IconData resolve(String? key) => _icons[key] ?? fallback;
}
