/// Dữ liệu mẫu dạng JSON giống response API `/locations/...`.
/// Chỉ gồm 6 thành phố trực thuộc trung ương và vài phường tiêu biểu,
/// toạ độ tâm là gần đúng. Danh sách đầy đủ 34 tỉnh/thành và các phường/xã
/// sẽ do backend cung cấp (seed từ bộ dữ liệu hành chính chính thức).
class LocationMockData {
  LocationMockData._();

  static const List<Map<String, dynamic>> provinces = [
    {'code': '79', 'name': 'TP. Hồ Chí Minh', 'level': 'province'},
    {'code': '01', 'name': 'TP. Hà Nội', 'level': 'province'},
    {'code': '48', 'name': 'TP. Đà Nẵng', 'level': 'province'},
    {'code': '31', 'name': 'TP. Hải Phòng', 'level': 'province'},
    {'code': '92', 'name': 'TP. Cần Thơ', 'level': 'province'},
    {'code': '46', 'name': 'TP. Huế', 'level': 'province'},
  ];

  static final Map<String, List<Map<String, dynamic>>> wardsByProvince = {
    '79': [
      _ward('79-SG', 'Phường Sài Gòn', '79', 10.7769, 106.7009),
      _ward('79-BT', 'Phường Bến Thành', '79', 10.7725, 106.6980),
      _ward('79-TD', 'Phường Tân Định', '79', 10.7905, 106.6897),
      _ward('79-BC', 'Phường Bàn Cờ', '79', 10.7700, 106.6800),
      _ward('79-XH', 'Phường Xuân Hòa', '79', 10.7790, 106.6890),
      _ward('79-GV', 'Phường Gò Vấp', '79', 10.8387, 106.6653),
      _ward('79-AK', 'Phường An Khánh', '79', 10.7880, 106.7310),
      _ward('79-THD', 'Phường Thủ Đức', '79', 10.8494, 106.7537),
    ],
    '01': [
      _ward('01-HK', 'Phường Hoàn Kiếm', '01', 21.0285, 105.8542),
      _ward('01-CN', 'Phường Cửa Nam', '01', 21.0245, 105.8412),
      _ward('01-BD', 'Phường Ba Đình', '01', 21.0368, 105.8346),
      _ward('01-NH', 'Phường Ngọc Hà', '01', 21.0390, 105.8200),
      _ward('01-DD', 'Phường Đống Đa', '01', 21.0180, 105.8290),
      _ward('01-CG', 'Phường Cầu Giấy', '01', 21.0333, 105.7940),
      _ward('01-HBT', 'Phường Hai Bà Trưng', '01', 21.0090, 105.8580),
    ],
    '48': [
      _ward('48-HC', 'Phường Hải Châu', '48', 16.0600, 108.2200),
      _ward('48-HCU', 'Phường Hòa Cường', '48', 16.0400, 108.2200),
      _ward('48-TK', 'Phường Thanh Khê', '48', 16.0670, 108.1900),
      _ward('48-ST', 'Phường Sơn Trà', '48', 16.0860, 108.2440),
      _ward('48-NHS', 'Phường Ngũ Hành Sơn', '48', 16.0010, 108.2560),
    ],
    '31': [
      _ward('31-HB', 'Phường Hồng Bàng', '31', 20.8650, 106.6830),
      _ward('31-LC', 'Phường Lê Chân', '31', 20.8500, 106.6800),
      _ward('31-NQ', 'Phường Ngô Quyền', '31', 20.8600, 106.7000),
    ],
    '92': [
      _ward('92-NK', 'Phường Ninh Kiều', '92', 10.0340, 105.7880),
      _ward('92-CK', 'Phường Cái Khế', '92', 10.0450, 105.7850),
      _ward('92-BTH', 'Phường Bình Thủy', '92', 10.0700, 105.7500),
    ],
    '46': [
      _ward('46-PX', 'Phường Phú Xuân', '46', 16.4700, 107.5800),
      _ward('46-TH', 'Phường Thuận Hóa', '46', 16.4600, 107.5900),
    ],
  };

  static Map<String, dynamic> _ward(
    String code,
    String name,
    String provinceCode,
    double latitude,
    double longitude,
  ) => {
    'code': code,
    'name': name,
    'level': 'ward',
    'parentCode': provinceCode,
    'center': {'latitude': latitude, 'longitude': longitude},
  };
}
