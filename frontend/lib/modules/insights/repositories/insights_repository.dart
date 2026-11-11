import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/network/api_client.dart';

import '../models/seller_insights.dart';

/// Nguồn dữ liệu trang Thống kê
abstract class InsightsRepository {
  /// Các khoảng thời gian chọn được (ngày)
  static const List<int> ranges = [7, 30];

  factory InsightsRepository() => AppEnvironment.useMockData
      ? MockInsightsRepository()
      : ApiInsightsRepository();

  Future<SellerInsights> load(int days);
}

/// `GET /listings/insights?days=7|30`
class ApiInsightsRepository implements InsightsRepository {
  ApiInsightsRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<SellerInsights> load(int days) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/listings/insights',
      queryParameters: {'days': days},
    );
    final data = response.data?['data'];
    if (data is! Map) throw const FormatException('Missing insights data');
    return SellerInsights.fromJson(Map<String, dynamic>.from(data));
  }
}

/// Số liệu mẫu cố định (không ngẫu nhiên) để giao diện và test ổn định
class MockInsightsRepository implements InsightsRepository {
  MockInsightsRepository({this.latency = const Duration(milliseconds: 300)});

  final Duration latency;

  @override
  Future<SellerInsights> load(int days) async {
    await Future<void>.delayed(latency);
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final daily = [
      for (var i = 0; i < days; i++)
        InsightDay(
          date: start.subtract(Duration(days: days - 1 - i)),
          views: 6 + (i * 7) % 11 + (i % 5 == 0 ? 9 : 0),
          saves: i % 3,
        ),
    ];
    final views = daily.fold<int>(0, (sum, d) => sum + d.views);
    final saves = daily.fold<int>(0, (sum, d) => sum + d.saves);
    return SellerInsights(
      days: days,
      views: InsightMetric(views, (views * 0.8).round()),
      saves: InsightMetric(saves, saves + 2),
      chats: InsightMetric(days == 7 ? 4 : 13, days == 7 ? 4 : 9),
      active: 3,
      pending: 1,
      hidden: 2,
      sold: 5,
      expiringSoon: 1,
      boosts: days == 7 ? 1 : 3,
      features: days == 7 ? 0 : 1,
      daily: daily,
      top: [
        InsightListing(
          id: 'l1',
          title: 'iPhone 13 Pro Max 256GB',
          price: 15500000,
          image: 'assets/images/marketplace/detail-macbook.jpg',
          views: (views * 0.5).round(),
          saves: (saves * 0.6).round(),
          totalViews: 212,
          expiresAt: start.add(const Duration(days: 2)),
        ),
        InsightListing(
          id: 'l2',
          title: 'Xe Honda Vision 2021',
          price: 23000000,
          image: 'assets/images/marketplace/detail-canon.jpg',
          views: (views * 0.3).round(),
          saves: (saves * 0.3).round(),
          totalViews: 87,
          featuredUntil: start.add(const Duration(days: 2)),
        ),
        InsightListing(
          id: 'l3',
          title: 'Sofa da 3 chỗ',
          price: 4500000,
          image: 'assets/images/marketplace/detail-bookshelf.jpg',
          views: (views * 0.2).round(),
          totalViews: 34,
        ),
      ],
    );
  }
}
