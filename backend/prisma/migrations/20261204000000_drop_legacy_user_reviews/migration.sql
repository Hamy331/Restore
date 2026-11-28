-- Bỏ hệ thống đánh giá cũ (seller_reviews): đánh giá giờ dùng ListingTrade và TradeReview.
-- Hai bảng không còn code nào đọc / ghi. Dừng lại nếu còn dữ liệu để không mất đánh giá.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM "UserReview") OR EXISTS (SELECT 1 FROM "ListingDeal") THEN
    RAISE EXCEPTION 'UserReview / ListingDeal still contain rows; migrate them before dropping';
  END IF;
END $$;

-- UserReview tham chiếu ListingDeal nên xóa trước
DROP TABLE "UserReview";
DROP TABLE "ListingDeal";
