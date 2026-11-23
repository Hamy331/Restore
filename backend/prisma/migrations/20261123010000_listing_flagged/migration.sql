-- Nội dung tin / bản sửa bị gắn cờ lúc gửi duyệt (người đăng đã được cảnh báo và vẫn gửi); bộ lọc "chỉ tin bị gắn cờ" dùng cột này
ALTER TABLE "Listing" ADD COLUMN "flagged" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "ListingRevision" ADD COLUMN "flagged" BOOLEAN NOT NULL DEFAULT false;
