import { Button, Skeleton, Table } from 'antd';
import {
  SafetyCertificateOutlined,
  FlagOutlined,
  ShopOutlined,
  RocketOutlined,
  TeamOutlined,
  EyeOutlined,
  AppstoreOutlined,
  CustomerServiceOutlined,
  RightOutlined,
  ReloadOutlined,
  CheckCircleOutlined,
} from '@ant-design/icons';
import { useWorkspace } from '../../app/workspace';
import { auditColumns } from '../audit/AuditTable';
import type { Entry } from '../audit/auditColumns';
import { Session } from '../../shared/api/session';
import { useResource } from '../../shared/api/useResource';
import { Failure } from '../../shared/ui/Failure';
import { Panel } from '../../shared/ui/Panel';
import { Revenue, type Insights } from './Revenue';

const queue = [
  {
    key: 'pendingListings',
    section: 'listings',
    label: 'Tin chờ duyệt',
    icon: SafetyCertificateOutlined,
  },
  { key: 'openReports', section: 'reports', label: 'Báo cáo đang mở', icon: FlagOutlined },
  { key: 'pendingStores', section: 'stores', label: 'Đơn cửa hàng chờ xử lý', icon: ShopOutlined },
  {
    key: 'pendingPromotions',
    section: 'promotions',
    label: 'Đơn đẩy tin chờ xử lý',
    icon: RocketOutlined,
  },
] as const;
type Overview = Record<(typeof queue)[number]['key'] | 'activeListings' | 'activeUsers', number> & {
  logs: Entry[];
};
export function Dashboard({ session }: { session: Session }) {
  const { openSection, canOpen } = useWorkspace();
  const overview = useResource<Overview>(session, '/admin/dashboard');
  const insights = useResource<Insights>(session, '/admin/dashboard/insights');
  const data = overview.data;
  if (overview.error) return <Failure error={overview.error} reload={overview.reload} />;
  if (!data) return <Skeleton active />;
  const pending = queue.reduce((n, q) => n + data[q.key], 0);
  const platform = [
    {
      key: 'members',
      label: 'Thành viên hoạt động',
      count: data.activeUsers,
      icon: TeamOutlined,
      filter: 'ACTIVE',
    },
    {
      key: 'listings',
      label: 'Tin đang hiển thị',
      count: data.activeListings,
      icon: EyeOutlined,
      filter: 'AVAILABLE',
    },
    {
      key: 'catalog',
      label: 'Danh mục đang dùng',
      count: insights.data?.categories,
      icon: AppstoreOutlined,
    },
    {
      key: 'tickets',
      label: 'Yêu cầu hỗ trợ đang mở',
      count: insights.data?.openTickets,
      icon: CustomerServiceOutlined,
    },
  ];
  return (
    <>
      <div className="dashboard-tools">
        <Button
          icon={<ReloadOutlined />}
          onClick={() => {
            overview.reload();
            insights.reload();
          }}
        >
          Làm mới
        </Button>
      </div>
      <Panel
        title="Hàng chờ xử lý"
        detail="Những việc cần quản trị viên xem xét"
        action={
          <span className={'queue-status ' + (pending ? 'pending' : '')}>
            <CheckCircleOutlined />{' '}
            {pending ? pending + ' việc đang chờ' : 'Không có việc tồn đọng'}
          </span>
        }
      >
        <div className="queue-grid">
          {queue.map(({ key, section, label, icon: Icon }) => (
            <button
              type="button"
              disabled={!canOpen(section)}
              key={key}
              onClick={() => openSection(section)}
              className="queue-item"
            >
              <span className="metric-icon">
                <Icon />
              </span>
              <strong>{data[key]}</strong>
              <span>{label}</span>
              <small className={data[key] ? 'warm' : 'good'}>
                {data[key] ? 'Xem hàng chờ ›' : '✓ Đã xử lý hết'}
              </small>
            </button>
          ))}
        </div>
      </Panel>
      <div className="dashboard-split">
        {insights.error ? (
          <Failure error={insights.error} reload={insights.reload} />
        ) : insights.data ? (
          <Revenue insights={insights.data} />
        ) : (
          <Skeleton active />
        )}
        <Panel title="Nền tảng" detail="Số liệu hiện tại trên ReStore">
          <div className="platform">
            {platform.map(({ key, label, count, icon: Icon, filter }) => (
              <button
                type="button"
                key={key}
                disabled={!canOpen(key)}
                onClick={() => openSection(key, filter)}
              >
                <span className="metric-icon">
                  <Icon />
                </span>
                <span>{label}</span>
                <b>{count ?? '—'}</b>
                {canOpen(key) && <RightOutlined />}
              </button>
            ))}
          </div>
        </Panel>
      </div>
      <Panel
        title="Hoạt động gần đây"
        detail="Các thao tác mới nhất của quản trị viên"
        action={
          <Button type="link" onClick={() => openSection('audit')}>
            Xem toàn bộ nhật ký ›
          </Button>
        }
      >
        <Table
          rowKey="id"
          columns={auditColumns}
          dataSource={data.logs}
          pagination={false}
          scroll={{ x: 820 }}
        />
      </Panel>
    </>
  );
}
