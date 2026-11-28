-- Kết quả AI xem ảnh và nội dung tin / bản sửa đang chờ duyệt (chỉ để admin tham khảo, không tự từ chối tin)
ALTER TABLE "Listing" ADD COLUMN "aiReview" JSONB;
ALTER TABLE "ListingRevision" ADD COLUMN "aiReview" JSONB;
