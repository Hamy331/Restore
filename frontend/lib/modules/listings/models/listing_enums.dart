/// Người bán là cá nhân hay bán chuyên
enum SellerType { personal, business }

/// Hình thức giao dịch theo SRS: Bán / Trao đổi / Cả bán và trao đổi
enum TradeType {
  sell,
  exchange,
  sellOrExchange;

  bool get requiresPrice => this != TradeType.exchange;
  bool get allowsExchange => this != TradeType.sell;

  /// Khớp cột allowSale / allowExchange của bảng Listing ở backend
  bool get allowsSale => requiresPrice;
}
