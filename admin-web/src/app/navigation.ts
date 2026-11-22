import { lazy } from 'react';

// Mỗi mục là một chunk riêng: trang đăng nhập và mục đầu tiên không phải tải cả bảng quản trị
const Dashboard = lazy(() =>
  import('../features/dashboard/Dashboard').then((m) => ({ default: m.Dashboard })),
);
const Audit = lazy(() => import('../features/audit/Audit').then((m) => ({ default: m.Audit })));
const Members = lazy(() =>
  import('../features/members/Members').then((m) => ({ default: m.Members })),
);
const Listings = lazy(() =>
  import('../features/listings/Listings').then((m) => ({ default: m.Listings })),
);
const Reports = lazy(() =>
  import('../features/reports/Reports').then((m) => ({ default: m.Reports })),
);
const Posts = lazy(() => import('../features/posts/Posts').then((m) => ({ default: m.Posts })));
const Tickets = lazy(() =>
  import('../features/support/Tickets').then((m) => ({ default: m.Tickets })),
);
const Knowledge = lazy(() =>
  import('../features/knowledge/Knowledge').then((m) => ({ default: m.Knowledge })),
);
const Catalog = lazy(() =>
  import('../features/catalog/Catalog').then((m) => ({ default: m.Catalog })),
);
const Stores = lazy(() =>
  import('../features/commerce/Commerce').then((m) => ({ default: m.Stores })),
);
const Promotions = lazy(() =>
  import('../features/commerce/Commerce').then((m) => ({ default: m.Promotions })),
);
const HomeBanners = lazy(() =>
  import('../features/banners/HomeBanners').then((m) => ({ default: m.HomeBanners })),
);
const ShopPosters = lazy(() =>
  import('../features/shop-posters/ShopPosters').then((m) => ({ default: m.ShopPosters })),
);

import {
  AppstoreOutlined,
  SafetyCertificateOutlined,
  FlagOutlined,
  ShopOutlined,
  RocketOutlined,
  TeamOutlined,
  ApartmentOutlined,
  FileTextOutlined,
  CustomerServiceOutlined,
  ReadOutlined,
  HistoryOutlined,
  PictureOutlined,
  NotificationOutlined,
} from '@ant-design/icons';

export const sections = [
  {
    key: 'dashboard',
    label: 'Tổng quan',
    group: '',
    icon: AppstoreOutlined,
    detail: 'Tình hình vận hành ReStore',
    permission: 'admin:access',
    View: Dashboard,
  },
  {
    key: 'listings',
    label: 'Kiểm duyệt tin',
    group: 'Vận hành',
    icon: SafetyCertificateOutlined,
    detail: 'Xem xét nội dung và xử lý tin đăng.',
    permission: 'listing:moderate',
    View: Listings,
  },
  {
    key: 'shopPosters',
    label: 'Duyệt banner shop',
    group: 'Vận hành',
    icon: NotificationOutlined,
    detail: 'Duyệt poster quảng bá mà shop gói Cửa hàng gửi lên.',
    permission: 'banner:manage',
    View: ShopPosters,
  },
  {
    key: 'reports',
    label: 'Báo cáo vi phạm',
    group: 'Vận hành',
    icon: FlagOutlined,
    detail: 'Xem xét báo cáo từ người dùng về tin đăng và tài khoản.',
    permission: 'user:manage',
    View: Reports,
  },
  {
    key: 'stores',
    label: 'Cửa hàng',
    group: 'Vận hành',
    icon: ShopOutlined,
    detail: 'Xét duyệt đơn đăng ký và quản lý gói cửa hàng.',
    permission: 'store:order-manage',
    View: Stores,
  },
  {
    key: 'promotions',
    label: 'Đẩy tin',
    group: 'Vận hành',
    icon: RocketOutlined,
    detail: 'Đối soát đơn mua và quản lý gói đẩy tin.',
    permission: 'promotion:manage',
    View: Promotions,
  },
  {
    key: 'members',
    label: 'Thành viên',
    group: 'Quản lý',
    icon: TeamOutlined,
    detail: 'Tra cứu thông tin và trạng thái tài khoản thành viên.',
    permission: 'user:manage',
    View: Members,
  },
  {
    key: 'catalog',
    label: 'Danh mục',
    group: 'Quản lý',
    icon: ApartmentOutlined,
    detail: 'Quản lý danh mục và tình trạng sản phẩm khi đăng tin.',
    permission: 'catalog:manage',
    View: Catalog,
  },
  {
    key: 'banners',
    label: 'Banner trang chủ',
    group: 'Nội dung & hỗ trợ',
    icon: PictureOutlined,
    detail: 'Quản lý banner hiển thị trên trang chủ ứng dụng.',
    permission: 'banner:manage',
    View: HomeBanners,
  },
  {
    key: 'posts',
    label: 'Bài viết',
    group: 'Nội dung & hỗ trợ',
    icon: FileTextOutlined,
    detail: 'Biên tập bài hướng dẫn và tin tức hiển thị cho người dùng.',
    permission: 'content:manage',
    View: Posts,
  },
  {
    key: 'tickets',
    label: 'Hỗ trợ',
    group: 'Nội dung & hỗ trợ',
    icon: CustomerServiceOutlined,
    detail: 'Theo dõi và phản hồi yêu cầu hỗ trợ của người dùng.',
    permission: 'content:manage',
    View: Tickets,
  },
  {
    key: 'knowledge',
    label: 'Kho tri thức',
    group: 'Nội dung & hỗ trợ',
    icon: ReadOutlined,
    detail: 'Quản lý tài liệu và chỉ mục tìm kiếm của trợ lý.',
    permission: 'content:manage',
    View: Knowledge,
  },
  {
    key: 'audit',
    label: 'Nhật ký quản trị',
    group: 'Hệ thống',
    icon: HistoryOutlined,
    detail: 'Tra cứu thao tác của quản trị viên để đối soát.',
    permission: 'admin:access',
    View: Audit,
  },
];
