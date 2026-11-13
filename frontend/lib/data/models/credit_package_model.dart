import 'package:equatable/equatable.dart';

/// Gói nạp xu (bảng CreditPackage). 1 xu = 1.000 đ.
class CreditPackageModel extends Equatable {
  final String id;
  final int priceVnd;

  /// Xu nạp
  final int credits;

  /// Xu tặng kèm
  final int bonusCredits;
  final bool popular;

  const CreditPackageModel({
    required this.id,
    required this.priceVnd,
    required this.credits,
    this.bonusCredits = 0,
    this.popular = false,
  });

  /// Tổng xu nhận được
  int get totalCredits => credits + bonusCredits;

  factory CreditPackageModel.fromJson(Map<String, dynamic> json) =>
      CreditPackageModel(
        id: '${json['id']}',
        priceVnd: (json['priceVnd'] as num?)?.toInt() ?? 0,
        credits: (json['credits'] as num?)?.toInt() ?? 0,
        bonusCredits: (json['bonusCredits'] as num?)?.toInt() ?? 0,
        popular: json['popular'] == true,
      );

  @override
  List<Object?> get props => [id, priceVnd, credits, bonusCredits, popular];
}
