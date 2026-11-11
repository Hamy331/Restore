import { Tabs } from 'antd';
import { FlagOutlined } from '@ant-design/icons';
import { EmptyState } from '../../shared/ui/Panel';
import { History } from '../audit/History';
import { useState } from 'react';
import { Alert, Button, Modal, Spin, Table } from 'antd';
import { Session } from '../../shared/api/session';
import { useResource, type Page } from '../../shared/api/useResource';
import { Failure } from '../../shared/ui/Failure';
import { DecisionForm, type Action } from '../moderation/DecisionForm';
import { ListingDetails, type Listing } from '../listings/ListingDetails';

type Report = {
  id: string;
  reporterId: string;
  targetId: string;
  targetType: 'USER' | 'LISTING';
  reason: string;
  evidence: string;
  status: string;
  resolution?: string;
  updatedAt: string;
};
type ReportedUser = { fullName: string; email: string; status: string; updatedAt: string };
type Target = Listing | ReportedUser;
const statuses: Record<string, string> = {
  OPEN: 'Chờ xử lý',
  RESOLVED: 'Đã xử lý',
  DISMISSED: 'Đã bác',
};

function Review({
  report,
  session,
  close,
  reload,
}: {
  report: Report;
  session: Session;
  close: () => void;
  reload: () => void;
}) {
  const [busy, setBusy] = useState(false);
  const path = '/admin/reports/' + encodeURIComponent(report.id);
  const target = useResource<Target | null>(session, path + '/target');
  const actions: Action[] = ['DISMISS'];
  if (report.targetType === 'LISTING') {
    if (target.data) actions.push('KEEP');
    if (target.data?.status === 'AVAILABLE') actions.push('REMOVE');
  } else if (target.data && target.data.status !== 'UNVERIFIED') {
    actions.push('WARN');
    if (target.data.status !== 'BANNED') actions.push('SUSPEND', 'BAN');
  }
  return (
    <Modal
      open
      title="Chi tiết báo cáo"
      footer={null}
      onCancel={() => !busy && close()}
      closable={!busy}
      maskClosable={false}
    >
      <p>
        <strong>Lý do báo cáo</strong> · {report.reason}
      </p>
      {report.evidence && (
        <p>
          <strong>Bằng chứng</strong> · {report.evidence}
        </p>
      )}
      <p>Người báo cáo · {report.reporterId}</p>
      <p>Đối tượng · {report.targetId}</p>
      {report.resolution && <p>Kết quả xử lý · {report.resolution}</p>}
      {target.error ? (
        <Failure error={target.error} reload={target.reload} />
      ) : target.data === undefined ? (
        <Spin />
      ) : (
        <>
          {target.data === null ? (
            <Alert title="Đối tượng đã bị xóa." type="warning" />
          ) : 'images' in target.data ? (
            <ListingDetails session={session} item={target.data} />
          ) : (
            <p>
              {target.data.fullName} · {target.data.email}
            </p>
          )}
          {report.status === 'OPEN' && (
            <DecisionForm
              actions={actions}
              busy={busy}
              setBusy={setBusy}
              save={(value) =>
                session.call(path + '/resolve', {
                  ...value,
                  updatedAt: report.updatedAt,
                  targetUpdatedAt: target.data?.updatedAt,
                })
              }
              onConflict={reload}
              onSaved={() => {
                close();
                reload();
              }}
            />
          )}
        </>
      )}
    </Modal>
  );
}
export function Reports({ session }: { session: Session }) {
  const [historyVersion, setHistoryVersion] = useState(0);
  const [page, setPage] = useState(1),
    [status, setStatus] = useState('OPEN'),
    [report, select] = useState<Report>();
  const { data, error, reload } = useResource<Page<Report>>(
    session,
    '/admin/reports?' + new URLSearchParams({ page: String(page), status }),
  );
  return (
    <>
      <section className="panel">
        <Tabs
          className="report-tabs"
          activeKey={status}
          onChange={(v) => {
            setStatus(v);
            setPage(1);
          }}
          items={Object.entries({ ...statuses, OPEN: 'Đang mở', '': 'Tất cả' }).map(
            ([key, label]) => ({
              key,
              label: label + (status === key && data ? ' · ' + data.total : ''),
            }),
          )}
        />
        {error ? (
          <Failure error={error} reload={reload} />
        ) : data?.total === 0 ? (
          <EmptyState
            cleared={status === 'OPEN'}
            icon={<FlagOutlined />}
            title={
              status === 'OPEN'
                ? 'Không có báo cáo nào đang mở'
                : 'Chưa có báo cáo ở trạng thái này'
            }
            detail={
              status === 'OPEN'
                ? 'Báo cáo vi phạm mới từ người dùng sẽ xuất hiện tại đây để bạn xem xét.'
                : 'Các quyết định xử lý sẽ được lưu tại đây.'
            }
          />
        ) : (
          <Table<Report>
            rowKey="id"
            loading={!data}
            dataSource={data?.items}
            scroll={{ x: 650 }}
            columns={[
              { title: 'Lý do', dataIndex: 'reason' },
              {
                title: 'Đối tượng',
                render: (_, r) => (r.targetType === 'USER' ? 'Thành viên' : 'Tin đăng'),
              },
              { title: 'Trạng thái', dataIndex: 'status', render: (s: string) => statuses[s] ?? s },
              {
                title: 'Chi tiết',
                render: (_, r) => <Button onClick={() => select(r)}>Xem báo cáo</Button>,
              },
            ]}
            pagination={{
              current: page,
              total: data?.total,
              pageSize: 25,
              showSizeChanger: false,
              onChange: setPage,
            }}
          />
        )}
      </section>
      <History key={historyVersion} session={session} type="REPORT" />
      {report && (
        <Review
          key={report.id}
          report={report}
          session={session}
          close={() => select(undefined)}
          reload={() => {
            reload();
            setHistoryVersion((n) => n + 1);
          }}
        />
      )}
    </>
  );
}
