-- Gói BASIC hiển thị là "Bán chuyên" (không có trang cửa hàng); chỉ đổi khi admin chưa tự đặt tên khác
UPDATE "StorePackage" SET "name" = 'Bán chuyên' WHERE "tier" = 'BASIC' AND "name" = 'Cửa hàng Basic';
