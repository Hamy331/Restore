import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppSizes {
  AppSizes._();

  // Padding & Margin (Dùng .w cho chiều ngang, .h cho chiều dọc)
  static final double p8 = 8.w;
  static final double p16 = 16.w;
  static final double p24 = 24.w;

  // Radius bo góc (Dùng .r để bo đều các góc)
  static final double radius8 = 8.r;
  static final double radius12 = 12.r;

  // Icon Sizes
  static final double iconSm = 16.w;
  static final double iconMd = 24.w;
  static final double iconLg = 32.w;

  // Font Sizes (Dùng .sp để scale theo tỷ lệ màn hình và cấu hình chữ của hệ điều hành)
  static final double fontSm = 12.sp;
  static final double fontMd = 14.sp;
  static final double fontLg = 16.sp;
  static final double fontXl = 28.sp;
}
