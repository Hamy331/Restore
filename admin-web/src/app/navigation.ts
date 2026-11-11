import { Dashboard } from '../features/dashboard/Dashboard';
import { Audit } from '../features/audit/Audit';
import { Members } from '../features/members/Members';
import { Listings } from '../features/listings/Listings';
import { Reports } from '../features/reports/Reports';
import { Posts } from '../features/posts/Posts';
import { Tickets } from '../features/support/Tickets';
import { Knowledge } from '../features/knowledge/Knowledge';
import { Catalog } from '../features/catalog/Catalog';
import { Stores, Promotions } from '../features/commerce/Commerce';
import { HomeBanners } from '../features/banners/HomeBanners';

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
