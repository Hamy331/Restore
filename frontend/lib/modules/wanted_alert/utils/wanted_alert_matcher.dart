import 'dart:math' as math;

import 'package:restore/core/utils/helpers/vietnamese_text.dart';

/// Chấm điểm "gần giống" giữa mô tả món cần tìm và một tin đăng (0..1).
///
/// Cùng công thức với backend (`backend/src/modules/wanted-alert/
/// wanted-alert.matcher.ts`), ở app chỉ dùng cho dữ liệu mẫu. Ý tưởng:
/// 1. Chuẩn hoá: chữ thường, bỏ dấu, bỏ ký tự đặc biệt, bỏ từ thừa
///    ("cần", "mua", "tìm"...). Không bỏ
///    "ban" vì vừa là "bán" vừa là "bàn".
/// 2. Mỗi từ khoá tìm từ giống nhất trong tiêu đề theo trigram (giống
///    `similarity()` của pg_trgm) nên gõ sai nhẹ ("cannon") vẫn khớp.
///    Độ phủ = trung bình điểm các từ khoá. Mô tả tin được tính nhẹ hơn.
/// 3. Điểm = 75% độ phủ + 25% trigram cả cụm so với tiêu đề.
/// Tin đạt ngưỡng của mức độ giống (WantedAlertMatchLevel) mới được báo.
class WantedAlertMatcher {
  WantedAlertMatcher._();

  /// Từ người dùng hay gõ kèm nhưng không mô tả món đồ
  static const Set<String> stopWords = {
    'can',
    'mua',
    'tim',
    'cho',
    'va',
    'voi',
    'cua',
    'loai',
    'mot',
    'the',
    'and',
    'for',
    'with',
    'want',
    'need',
    'buy',
  };

  /// Điểm từ khoá dưới mức này coi như không khớp (tránh "may" khớp "mau")
  static const double tokenFloor = 0.3;

  /// Mô tả tin thường dài và lan man nên chỉ tính 80%
  static const double descriptionWeight = 0.8;

  static double score(
    String keywords,
    String title, {
    String description = '',
  }) {
    final wanted = tokens(keywords);
    if (wanted.isEmpty) return 0;
    final titleTokens = tokens(title);
    final coverage = math.max(
      _coverage(wanted, titleTokens),
      _coverage(wanted, tokens(description)) * descriptionWeight,
    );
    final phrase = similarity(wanted.join(' '), titleTokens.join(' '));
    return (0.75 * coverage + 0.25 * phrase).clamp(0.0, 1.0);
  }

  /// Từ đã chuẩn hoá, bỏ từ thừa
  static List<String> tokens(String text) => [
    for (final word in VietnameseText.normalize(
      text,
    ).replaceAll(RegExp(r'[^a-z0-9]+'), ' ').split(' '))
      if (word.isNotEmpty && !stopWords.contains(word)) word,
  ];

  /// Độ giống trigram như pg_trgm: số trigram chung / tổng trigram
  static double similarity(String a, String b) {
    final ta = trigrams(a);
    final tb = trigrams(b);
    if (ta.isEmpty || tb.isEmpty) return 0;
    final common = ta.intersection(tb).length;
    return common / (ta.length + tb.length - common);
  }

  /// Trigram của từng từ, thêm 2 khoảng trắng đầu và 1 ở cuối (như pg_trgm)
  static Set<String> trigrams(String text) {
    final result = <String>{};
    for (final word in text.split(' ')) {
      if (word.isEmpty) continue;
      final padded = '  $word ';
      for (var i = 0; i + 3 <= padded.length; i++) {
        result.add(padded.substring(i, i + 3));
      }
    }
    return result;
  }

  static double _coverage(List<String> wanted, List<String> candidates) {
    if (candidates.isEmpty) return 0;
    var total = 0.0;
    for (final word in wanted) {
      var best = 0.0;
      for (final candidate in candidates) {
        final value = word == candidate ? 1.0 : similarity(word, candidate);
        if (value > best) best = value;
        if (best == 1) break;
      }
      if (best >= tokenFloor) total += best;
    }
    return total / wanted.length;
  }
}
