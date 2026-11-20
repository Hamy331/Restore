-- Theo dõi shop = theo dõi chủ shop: chép ShopFollow sang UserFollow (giữ ngày theo dõi sớm nhất, không trùng).
-- Bảng ShopFollow giữ lại để đối chiếu, app không dùng nữa; xoá ở migration sau.
INSERT INTO "UserFollow" ("followerId", "followingId", "createdAt")
SELECT sf."userId", s."ownerId", MIN(sf."createdAt")
FROM "ShopFollow" sf
JOIN "Shop" s ON s.id = sf."shopId"
WHERE sf."userId" <> s."ownerId"
GROUP BY sf."userId", s."ownerId"
ON CONFLICT ("followerId", "followingId")
DO UPDATE SET "createdAt" = LEAST("UserFollow"."createdAt", EXCLUDED."createdAt");
