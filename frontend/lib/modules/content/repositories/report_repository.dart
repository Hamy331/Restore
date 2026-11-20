import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class ListingReportReason {
  const ListingReportReason({
    required this.code,
    required this.labelVi,
    required this.labelEn,
    required this.requiresDescription,
    this.guidanceVi,
    this.guidanceEn,
  });
  final String code;
  final String labelVi, labelEn;
  final bool requiresDescription;
  final String? guidanceVi, guidanceEn;

  String label(String language) => language == 'vi' ? labelVi : labelEn;
  String? guidance(String language) =>
      language == 'vi' ? guidanceVi : guidanceEn;

  factory ListingReportReason.fromJson(Map<String, dynamic> json) =>
      ListingReportReason(
        code: json['code'] as String,
        labelVi: json['labelVi'] as String,
        labelEn: json['labelEn'] as String,
        requiresDescription: json['requiresDescription'] as bool,
        guidanceVi: json['guidanceVi'] as String?,
        guidanceEn: json['guidanceEn'] as String?,
      );
}

/// Contact information is sent only with this report, not written to the profile.
class ReportRepository {
  ReportRepository({Dio? dio}) : _dio = dio ?? ApiClient().dio;
  final Dio _dio;

  Future<List<ListingReportReason>> getReasons() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/content/reports/reasons',
    );
    final items = (response.data!['data'] as Map)['items'] as List;
    return items
        .map(
          (item) => ListingReportReason.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<void> submitListing({
    required String listingId,
    required ListingReportReason reason,
    required String phone,
    required String email,
  }) async {
    await _dio.post<void>(
      '/content/reports',
      data: {
        'targetType': 'LISTING',
        'targetId': listingId,
        'reasonCode': reason.code,
        'evidence': '',
        'contactPhone': phone.trim(),
        'contactEmail': email.trim(),
      },
    );
  }
}
