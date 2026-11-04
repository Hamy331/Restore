import { Role } from '@prisma/client';

/**
 * Quyền trong hệ thống. Route kiểm tra quyền, không kiểm tra vai trò trực tiếp:
 *   router.post('/:id/favorite', requirePermission(PERMISSION.FAVORITE_WRITE), ...)
 *
 * Muốn đổi ai được làm gì thì chỉ sửa ROLE_PERMISSIONS bên dưới.
 */
export const PERMISSION = {
  /** Xem hồ sơ của chính mình: GET /users/me, GET /auth/me */
  PROFILE_READ: 'profile:read',

  /** Đăng và quản lý tin của mình: tạo/sửa tin, nháp, ảnh, trạng thái, /listings/mine, /listings/summary */
  LISTING_MANAGE_OWN: 'listing:manage-own',
  /** Xem tin đã lưu: GET /listings/favorites, GET /listings/:id/favorite */
  FAVORITE_READ: 'favorite:read',
  /** Lưu / bỏ lưu tin: POST, PUT, DELETE /listings/:id/favorite */
  FAVORITE_WRITE: 'favorite:write',

  /** Mua gói cửa hàng: GET /stores/me, POST /stores/orders */
  STORE_PURCHASE: 'store:purchase',
  /** Mua và dùng gói đẩy tin: GET /promotions/my, POST /promotions/redeem, POST /promotions/orders */
  PROMOTION_PURCHASE: 'promotion:purchase',

  /** Báo cáo vi phạm: POST /content/reports, GET /content/reports/mine */
  REPORT_SUBMIT: 'report:submit',
  /** Gửi yêu cầu hỗ trợ: GET/POST /content/tickets, POST /content/tickets/:id/reply */
  SUPPORT_TICKET: 'support:ticket',
  /** Thông báo "Báo khi có hàng" của mình: /wanted-alerts */
  WANTED_ALERT_MANAGE: 'wanted-alert:manage',

  /** Vào khu quản trị /admin/*: /admin/me, /admin/dashboard, /admin/audit */
  ADMIN_ACCESS: 'admin:access',
  /** Quản lý thành viên: /admin/users (cảnh cáo, tạm khóa, cấm, mở lại), xử lý /admin/reports */
  USER_MANAGE: 'user:manage',
  /** Quản lý danh mục và tình trạng: /admin/catalog/* */
  CATALOG_MANAGE: 'catalog:manage',
  /** Quản lý banner trang chủ: /home/admin/banners */
  BANNER_MANAGE: 'banner:manage',
  /** Duyệt tin (/listings/admin/*, /admin/listings), xem ảnh tin của người khác */
  LISTING_MODERATE: 'listing:moderate',
  /** Gói cửa hàng và đơn mua gói: /stores/admin/orders, /admin/store-packages, /admin/store-orders */
  STORE_ORDER_MANAGE: 'store:order-manage',
  /** Quản lý gói và đơn đẩy tin: /promotions/packages, /promotions/admin/orders, /admin/promotion-orders */
  PROMOTION_MANAGE: 'promotion:manage',
  /** Quản lý nội dung: ảnh bài viết, /admin/posts, /admin/knowledge, /admin/tickets */
  CONTENT_MANAGE: 'content:manage',
} as const;

export type Permission = (typeof PERMISSION)[keyof typeof PERMISSION];

/**
 * Vai trò → quyền. Khớp đúng hành vi hiện tại:
 * USER là người mua/bán, ADMIN chỉ quản trị (ADMIN không đăng tin, không lưu tin).
 */
export const ROLE_PERMISSIONS: Readonly<Record<Role, readonly Permission[]>> = {
  [Role.USER]: [
    PERMISSION.PROFILE_READ,
    PERMISSION.LISTING_MANAGE_OWN,
    PERMISSION.FAVORITE_READ,
    PERMISSION.FAVORITE_WRITE,
    PERMISSION.STORE_PURCHASE,
    PERMISSION.PROMOTION_PURCHASE,
    PERMISSION.REPORT_SUBMIT,
    PERMISSION.SUPPORT_TICKET,
    PERMISSION.WANTED_ALERT_MANAGE,
  ],
  [Role.ADMIN]: [
    PERMISSION.PROFILE_READ,
    PERMISSION.ADMIN_ACCESS,
    PERMISSION.USER_MANAGE,
    PERMISSION.CATALOG_MANAGE,
    PERMISSION.BANNER_MANAGE,
    PERMISSION.LISTING_MODERATE,
    PERMISSION.STORE_ORDER_MANAGE,
    PERMISSION.PROMOTION_MANAGE,
    PERMISSION.CONTENT_MANAGE,
  ],
};

/** Vai trò có đủ mọi quyền được liệt kê không */
export const hasPermission = (role: Role | undefined, ...permissions: Permission[]) =>
  role !== undefined && permissions.every((permission) => ROLE_PERMISSIONS[role].includes(permission));
