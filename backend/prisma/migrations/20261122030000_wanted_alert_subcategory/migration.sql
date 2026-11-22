-- Danh mục con của thông báo "Báo khi có hàng" (id trong Category.metadata.subcategories); null là mọi danh mục con
ALTER TABLE "WantedAlert" ADD COLUMN "subcategoryId" TEXT;
