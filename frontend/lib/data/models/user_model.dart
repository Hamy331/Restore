import 'package:equatable/equatable.dart';
import 'package:restore/data/models/enums/account_status.dart';
import 'package:restore/data/models/enums/user_role.dart';

/// Một dòng của bảng User (prisma/schema.prisma).
///
/// Chỉ giữ các cột được phép trả về app: không có password, otp* hay
/// authVersion. Tên khoá JSON giống tên cột (camelCase).
class UserModel extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String username;
  final String? phone;
  final String? avatarUrl;
  final UserRole role;
  final AccountStatus status;
  final double ratingAverage;
  final int ratingCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.username,
    this.phone,
    this.avatarUrl,
    this.role = UserRole.user,
    this.status = AccountStatus.unverified,
    this.ratingAverage = 0,
    this.ratingCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: '${json['id']}',
    email: json['email'] as String,
    fullName: json['fullName'] as String? ?? '',
    username: json['username'] as String? ?? '',
    phone: json['phone'] as String?,
    avatarUrl: json['avatarUrl'] as String?,
    role: UserRole.fromApi(json['role'] as String?),
    status: AccountStatus.fromApi(json['status'] as String?),
    ratingAverage: (json['ratingAverage'] as num?)?.toDouble() ?? 0,
    ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
    createdAt: DateTime.tryParse('${json['createdAt']}'),
    updatedAt: DateTime.tryParse('${json['updatedAt']}'),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'fullName': fullName,
    'username': username,
    'phone': phone,
    'avatarUrl': avatarUrl,
    'role': role.apiValue,
    'status': status.apiValue,
    'ratingAverage': ratingAverage,
    'ratingCount': ratingCount,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    id,
    email,
    fullName,
    username,
    phone,
    avatarUrl,
    role,
    status,
    ratingAverage,
    ratingCount,
    createdAt,
    updatedAt,
  ];
}
