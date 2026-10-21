import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

String adminMoney(int value) =>
    '${NumberFormat.decimalPattern('vi').format(value)} đ';

typedef AdminListing = ({
  String id,
  String title,
  String owner,
  String category,
  String image,
  int price,
  String status,
  String note,
});
typedef AdminUser = ({
  String id,
  String name,
  String email,
  String status,
  double rating,
  String joined,
});
typedef AdminReport = ({
  String id,
  String target,
  bool isUser,
  String reason,
  String reporter,
  String status,
  String evidence,
});
typedef AdminLog = ({
  String target,
  String action,
  String reason,
  DateTime time,
});
typedef AdminPackage = ({
  String id,
  String name,
  int days,
  int price,
  int priority,
  bool active,
});
typedef AdminPayment = ({
  String id,
  String user,
  String listing,
  String package,
  int amount,
  String payment,
  String boost,
  DateTime date,
});

const pendingListing = 'Chờ duyệt';
const activeListing = 'Đang hiển thị';
const listingStatuses = [
  pendingListing,
  activeListing,
  'Cần chỉnh sửa',
  'Từ chối',
  'Đã gỡ',
];

class AdminPreviewData {
  const AdminPreviewData({
    required this.listings,
    required this.users,
    required this.reports,
    required this.packages,
    this.logs = const [],
  });
  final List<AdminListing> listings;
  final List<AdminUser> users;
  final List<AdminReport> reports;
  final List<AdminPackage> packages;
  final List<AdminLog> logs;

  AdminPreviewData copyWith({
    List<AdminListing>? listings,
    List<AdminUser>? users,
    List<AdminReport>? reports,
    List<AdminPackage>? packages,
    List<AdminLog>? logs,
  }) => AdminPreviewData(
    listings: List.unmodifiable(listings ?? this.listings),
    users: List.unmodifiable(users ?? this.users),
    reports: List.unmodifiable(reports ?? this.reports),
    packages: List.unmodifiable(packages ?? this.packages),
    logs: List.unmodifiable(logs ?? this.logs),
  );
}

// Presentation-only fixtures. No account, listing or payment is changed remotely.
class AdminPreviewCubit extends Cubit<AdminPreviewData> {
  AdminPreviewCubit() : super(_seed());

  void reset() => emit(_seed());

  List<AdminLog> _log(String id, String action, String reason) => [
    (target: id, action: action, reason: reason, time: DateTime.now()),
    ...state.logs,
  ];

  bool moderate(
    String id,
    String expectedStatus,
    String status,
    String reason,
  ) {
    final index = state.listings.indexWhere((item) => item.id == id);
    if (index < 0 || state.listings[index].status != expectedStatus) {
      return false;
    }
    final allowed = expectedStatus == pendingListing
        ? [activeListing, 'Cần chỉnh sửa', 'Từ chối']
        : expectedStatus == activeListing
        ? ['Đã gỡ']
        : <String>[];
    if (!allowed.contains(status) ||
        (status != activeListing && reason.trim().isEmpty)) {
      return false;
    }
    emit(
      state.copyWith(
        listings: _listingStatus(id, status),
        logs: _log(id, status, reason.trim()),
      ),
    );
    return true;
  }

  List<AdminListing> _listingStatus(String id, String status) => [
    for (final x in state.listings)
      (
        id: x.id,
        title: x.title,
        owner: x.owner,
        category: x.category,
        image: x.image,
        price: x.price,
        status: x.id == id ? status : x.status,
        note: x.note,
      ),
  ];

  List<AdminUser> _userStatus(String id, String action) => [
    for (final x in state.users)
      (
        id: x.id,
        name: x.name,
        email: x.email,
        status: x.id == id && action != 'Cảnh báo' ? action : x.status,
        rating: x.rating,
        joined: x.joined,
      ),
  ];

  bool sanction(String id, String action, String reason, {int days = 7}) {
    if (reason.trim().isEmpty ||
        !['Cảnh báo', 'Đình chỉ', 'Đã cấm'].contains(action) ||
        days <= 0) {
      return false;
    }
    final user = state.users.where((x) => x.id == id).firstOrNull;
    if (user == null ||
        user.status == 'Đã cấm' ||
        (user.status == 'Đình chỉ' && action == 'Đình chỉ')) {
      return false;
    }
    final note = action == 'Đình chỉ'
        ? '${reason.trim()} · $days ngày, đến ${DateFormat('dd/MM/yyyy').format(DateTime.now().add(Duration(days: days)))}'
        : reason.trim();
    emit(
      state.copyWith(
        users: _userStatus(id, action),
        logs: _log(id, action, note),
      ),
    );
    return true;
  }

  bool resolve(String id, String action, String reason, {int days = 7}) {
    final report = state.reports.where((x) => x.id == id).firstOrNull;
    if (report == null ||
        report.status != 'Chưa xử lý' ||
        reason.trim().isEmpty ||
        days <= 0) {
      return false;
    }
    final allowed = report.isUser
        ? ['Cảnh báo', 'Đình chỉ', 'Đã cấm', 'Bác báo cáo']
        : ['Gỡ tin', 'Giữ tin', 'Bác báo cáo'];
    if (!allowed.contains(action)) return false;
    if (action == 'Gỡ tin' &&
        !state.listings.any(
          (x) => x.id == report.target && x.status == activeListing,
        )) {
      return false;
    }
    if (report.isUser && action != 'Bác báo cáo') {
      final user = state.users.where((x) => x.id == report.target).firstOrNull;
      if (user == null || user.status == 'Đã cấm') return false;
    }
    final logs = _log(id, action, reason.trim());
    if (action != 'Bác báo cáo' && action != 'Giữ tin') {
      logs.insert(0, (
        target: report.target,
        action: action,
        reason:
            '$id · ${reason.trim()}${action == 'Đình chỉ' ? ' · $days ngày, đến ${DateFormat('dd/MM/yyyy').format(DateTime.now().add(Duration(days: days)))}' : ''}',
        time: DateTime.now(),
      ));
    }
    emit(
      state.copyWith(
        listings: action == 'Gỡ tin'
            ? _listingStatus(report.target, 'Đã gỡ')
            : null,
        users: report.isUser && action != 'Bác báo cáo'
            ? _userStatus(report.target, action)
            : null,
        reports: [
          for (final x in state.reports)
            (
              id: x.id,
              target: x.target,
              isUser: x.isUser,
              reason: x.reason,
              reporter: x.reporter,
              status: x.id == id
                  ? (action == 'Bác báo cáo' ? 'Đã bác bỏ' : 'Đã giải quyết')
                  : x.status,
              evidence: x.evidence,
            ),
        ],
        logs: logs,
      ),
    );
    return true;
  }

  void savePackage(AdminPackage item) {
    if (item.name.trim().isEmpty ||
        item.price <= 0 ||
        item.days <= 0 ||
        item.priority <= 0) {
      return;
    }
    final exists = state.packages.any((x) => x.id == item.id);
    emit(
      state.copyWith(
        packages: [
          for (final x in state.packages)
            if (x.id == item.id) item else x,
          if (!exists) item,
        ],
        logs: _log(
          item.id,
          exists ? 'Cập nhật gói Boost' : 'Tạo gói Boost',
          item.name,
        ),
      ),
    );
  }

  void record(String id, String action, String reason) =>
      emit(state.copyWith(logs: _log(id, action, reason)));

  static AdminPreviewData _seed() => AdminPreviewData(
    listings: const [
      (
        id: 'TD-0248',
        title: 'Canon AE-1 + lens 50mm',
        owner: 'ND-001',
        category: 'Máy ảnh',
        image: 'camera',
        price: 2450000,
        status: pendingListing,
        note: 'Ảnh cần kiểm tra',
      ),
      (
        id: 'TD-0247',
        title: 'Đèn bàn đồng cổ điển',
        owner: 'ND-002',
        category: 'Nội thất',
        image: 'lamp',
        price: 590000,
        status: pendingListing,
        note: 'Nội dung cần xem',
      ),
      (
        id: 'TD-0246',
        title: 'Ghế gỗ sồi Bắc Âu',
        owner: 'ND-003',
        category: 'Nội thất',
        image: 'chair',
        price: 1200000,
        status: pendingListing,
        note: 'Kiểm tra danh mục',
      ),
      (
        id: 'TD-0245',
        title: 'Máy ảnh film Canon AE-1',
        owner: 'ND-001',
        category: 'Máy ảnh',
        image: 'camera',
        price: 2100000,
        status: activeListing,
        note: 'Đã kiểm duyệt',
      ),
      (
        id: 'TD-0244',
        title: 'Đèn đọc sách vintage',
        owner: 'ND-002',
        category: 'Nội thất',
        image: 'lamp',
        price: 450000,
        status: activeListing,
        note: 'Đã kiểm duyệt',
      ),
      (
        id: 'TD-0243',
        title: 'Ghế gỗ phòng khách',
        owner: 'ND-004',
        category: 'Nội thất',
        image: 'chair',
        price: 980000,
        status: 'Cần chỉnh sửa',
        note: 'Cần bổ sung ảnh thực tế',
      ),
      (
        id: 'TD-0242',
        title: 'Máy ảnh film đã qua sử dụng',
        owner: 'ND-003',
        category: 'Máy ảnh',
        image: 'camera',
        price: 1850000,
        status: 'Từ chối',
        note: 'Nội dung chưa đáp ứng quy định',
      ),
      (
        id: 'TD-0241',
        title: 'Ghế gỗ thanh lý',
        owner: 'ND-004',
        category: 'Nội thất',
        image: 'chair',
        price: 650000,
        status: 'Đã gỡ',
        note: 'Tin trùng lặp',
      ),
    ],
    users: const [
      (
        id: 'ND-001',
        name: 'Minh Anh',
        email: 'minhanh@example.com',
        status: 'Hoạt động',
        rating: 4.9,
        joined: '12/08/2026',
      ),
      (
        id: 'ND-002',
        name: 'Hoàng Phúc',
        email: 'hoangphuc@example.com',
        status: 'Hoạt động',
        rating: 4.8,
        joined: '15/08/2026',
      ),
      (
        id: 'ND-003',
        name: 'Gia Hân',
        email: 'giahan@example.com',
        status: 'Hoạt động',
        rating: 4.7,
        joined: '01/09/2026',
      ),
      (
        id: 'ND-004',
        name: 'Thành Trần',
        email: 'thanhtran@example.com',
        status: 'Hoạt động',
        rating: 3.5,
        joined: '07/09/2026',
      ),
    ],
    reports: const [
      (
        id: 'BC-1035',
        target: 'TD-0245',
        isUser: false,
        reason: 'Nội dung gây hiểu nhầm',
        reporter: 'ND-003',
        status: 'Chưa xử lý',
        evidence:
            'Người gửi cho biết tình trạng máy ảnh khác với mô tả. Cần đối chiếu nội dung tin và liên hệ xác minh.',
      ),
      (
        id: 'BC-1034',
        target: 'ND-004',
        isUser: true,
        reason: 'Ngôn ngữ không phù hợp',
        reporter: 'ND-001',
        status: 'Chưa xử lý',
        evidence:
            'Người gửi phản ánh thái độ không phù hợp khi thương lượng. Đây là nội dung bằng chứng minh họa, chưa có tệp đính kèm.',
      ),
      (
        id: 'BC-1033',
        target: 'TD-0244',
        isUser: false,
        reason: 'Tin đăng trùng lặp',
        reporter: 'ND-003',
        status: 'Chưa xử lý',
        evidence:
            'Người gửi phát hiện hai tin có hình ảnh và nội dung tương tự.',
      ),
    ],
    packages: const [
      (
        id: 'GOI-01',
        name: 'Khởi đầu',
        days: 1,
        price: 19000,
        priority: 1,
        active: true,
      ),
      (
        id: 'GOI-02',
        name: 'Nổi bật',
        days: 3,
        price: 49000,
        priority: 2,
        active: true,
      ),
      (
        id: 'GOI-03',
        name: 'Bứt phá',
        days: 7,
        price: 99000,
        priority: 3,
        active: false,
      ),
    ],
  );
}

final adminPayments = <AdminPayment>[
  (
    id: 'BT-2084',
    user: 'Minh Anh',
    listing: 'TD-0245',
    package: 'Nổi bật · 3 ngày',
    amount: 49000,
    payment: 'Thành công',
    boost: 'Đang chạy',
    date: DateTime(2026, 9, 29),
  ),
  (
    id: 'BT-2083',
    user: 'Hoàng Phúc',
    listing: 'TD-0244',
    package: 'Khởi đầu · 1 ngày',
    amount: 19000,
    payment: 'Thành công',
    boost: 'Hết hạn',
    date: DateTime(2026, 9, 26),
  ),
  (
    id: 'BT-2082',
    user: 'Gia Hân',
    listing: 'TD-0246',
    package: 'Nổi bật · 3 ngày',
    amount: 49000,
    payment: 'Chờ xác nhận',
    boost: 'Chưa kích hoạt',
    date: DateTime(2026, 9, 25),
  ),
  (
    id: 'BT-2081',
    user: 'Thành Trần',
    listing: 'TD-0243',
    package: 'Khởi đầu · 1 ngày',
    amount: 19000,
    payment: 'Thất bại',
    boost: 'Chưa kích hoạt',
    date: DateTime(2026, 9, 22),
  ),
  (
    id: 'BT-2080',
    user: 'Minh Anh',
    listing: 'TD-0245',
    package: 'Bứt phá · 7 ngày',
    amount: 99000,
    payment: 'Thành công',
    boost: 'Lỗi kích hoạt',
    date: DateTime(2026, 9, 18),
  ),
];
