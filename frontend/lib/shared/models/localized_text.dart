import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

/// Chuỗi đa ngôn ngữ nhận từ API, VD: {"vi": "Điện thoại", "en": "Phones"}.
/// Dùng cho dữ liệu động (danh mục, thuộc tính) nên không nằm trong file arb.
class LocalizedText extends Equatable {
  static const String fallbackLanguage = 'vi';

  final Map<String, String> values;

  const LocalizedText(this.values);

  /// Chuỗi không cần dịch (tên riêng như Apple, 128 GB)
  LocalizedText.plain(String text) : values = {fallbackLanguage: text};

  /// API có thể trả về một chuỗi hoặc một map theo mã ngôn ngữ
  factory LocalizedText.fromJson(Object? json) {
    if (json is String) return LocalizedText.plain(json);
    if (json is Map) {
      return LocalizedText({
        for (final entry in json.entries)
          if (entry.value is String) '${entry.key}': entry.value as String,
      });
    }
    return const LocalizedText({});
  }

  Map<String, String> toJson() => values;

  String resolve(String languageCode) =>
      values[languageCode] ??
      values[fallbackLanguage] ??
      (values.isEmpty ? '' : values.values.first);

  /// Lấy theo ngôn ngữ đang dùng của app
  String of(BuildContext context) =>
      resolve(Localizations.localeOf(context).languageCode);

  @override
  List<Object?> get props => [values];
}
