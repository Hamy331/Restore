import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/shared/widgets/app_field_message.dart';

/// Kiểu chữ dùng chung trong form đăng tin
class ListingFormStyle {
  ListingFormStyle._();

  static const TextStyle label = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 14,
    height: 1.35,
    color: AppColors.textSecondary,
  );

  static const TextStyle input = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static const TextStyle hint = TextStyle(
    fontSize: 16,
    color: Color(0xFFA9A49C),
  );

  static const double radius = 6;
}

/// Nhãn trường + nội dung + dòng lỗi bên dưới
class ListingLabeledField extends StatelessWidget {
  const ListingLabeledField({
    super.key,
    required this.label,
    required this.child,
    this.errorText,
    this.trailing,
  });

  final String label;
  final Widget child;
  final String? errorText;

  /// Nội dung nhỏ bên phải nhãn (VD số ảnh 2/20)
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: ListingFormStyle.label)),
            ?trailing,
          ],
        ),
        const SizedBox(height: 10),
        child,
        AppFieldMessage(errorText: errorText),
      ],
    );
  }
}

/// Ô nhập nền xám, không viền; viền màu chính khi đang nhập, viền đỏ khi lỗi
class ListingFilledTextField extends StatelessWidget {
  const ListingFilledTextField({
    super.key,
    required this.controller,
    this.hintText,
    this.onChanged,
    this.hasError = false,
    this.minLines,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.inputFormatters,
    this.suffixText,
    this.suffix,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final bool hasError;
  final int? minLines;
  final int? maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? suffixText;

  /// Nội dung cuối ô (VD nút chọn đơn vị); có thì bỏ qua [suffixText]
  final Widget? suffix;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(ListingFormStyle.radius),
      borderSide: BorderSide(color: color),
    );
    return TextField(
      controller: controller,
      onChanged: onChanged,
      minLines: minLines,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      style: ListingFormStyle.input,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: ListingFormStyle.hint,
        hintMaxLines: 3,
        suffixText: suffix == null ? suffixText : null,
        suffixIcon: suffix == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Align(widthFactor: 1, heightFactor: 1, child: suffix),
              ),
        filled: true,
        fillColor: AppColors.fill,
        // Đếm ký tự hiện qua maxLength nhưng không chiếm thêm chỗ
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: border(Colors.transparent),
        enabledBorder: border(hasError ? AppColors.error : Colors.transparent),
        focusedBorder: border(
          hasError ? AppColors.error : AppColors.actionPrimary,
        ),
      ),
    );
  }
}

/// Ô chọn nền xám: giá trị (hoặc gợi ý) và mũi tên xuống, chạm để mở sheet
class ListingSelectBox extends StatelessWidget {
  const ListingSelectBox({
    super.key,
    required this.placeholder,
    required this.onTap,
    this.value,
    this.hasError = false,
  });

  final String placeholder;
  final String? value;
  final bool hasError;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(ListingFormStyle.radius);
    return Material(
      color: AppColors.fill,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color: hasError ? AppColors.error : Colors.transparent,
        ),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value ?? placeholder,
                  style: value == null
                      ? ListingFormStyle.hint
                      : ListingFormStyle.input,
                ),
              ),
              const Icon(
                AppIcons.chevronDown,
                size: 20,
                color: AppColors.textPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dòng bật / tắt: tiêu đề, mô tả nhỏ và công tắc
class ListingSwitchRow extends StatelessWidget {
  const ListingSwitchRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.titleStyle = ListingFormStyle.label,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final TextStyle titleStyle;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: titleStyle),
                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(subtitle!, style: ListingFormStyle.subtitle),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ListingSwitch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

/// Công tắc kiểu iOS màu hành động của app
class ListingSwitch extends StatelessWidget {
  const ListingSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: Colors.white,
      activeTrackColor: AppColors.actionPrimary,
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: AppColors.border,
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      thumbIcon: const WidgetStatePropertyAll(null),
    );
  }
}

/// Vòng tròn chọn (radio / ô đánh dấu tròn)
class ListingRadioMark extends StatelessWidget {
  const ListingRadioMark({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.actionSoft : Colors.transparent,
        border: Border.all(
          color: selected ? AppColors.actionPrimary : const Color(0xFFC9C9C9),
          width: selected ? 2 : 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        scale: selected ? 1 : 0,
        child: Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: AppColors.actionPrimary,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
