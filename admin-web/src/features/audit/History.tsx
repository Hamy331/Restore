import { Button, Spin } from 'antd';
import { HistoryOutlined, RightOutlined } from '@ant-design/icons';
import { useWorkspace } from '../../app/workspace';
import { Session } from '../../shared/api/session';
import { useResource, type Page } from '../../shared/api/useResource';
import { Panel } from '../../shared/ui/Panel';
import { Failure } from '../../shared/ui/Failure';
import { actions } from './auditLabels';
import { RecordId } from './AuditTable';
import type { Entry } from './auditColumns';

export function History({ session, type }: { session: Session; type: string }) {
  const { openSection, canOpen } = useWorkspace();
  if (!canOpen('audit')) return null;
  return <HistoryList session={session} type={type} open={() => openSection('audit', type)} />;
}
function HistoryList({
  session,
  type,
  open,
}: {
  session: Session;
  type: string;
  open: () => void;
}) {
  const { data, error, reload } = useResource<Page<Entry>>(
    session,
    '/admin/audit?targetType=' + encodeURIComponent(type),
  );
  return (
    <Panel
      title="Lịch sử xử lý"
      detail="Các thao tác gần nhất trong phân hệ"
      action={
        <Button type="link" onClick={open}>
          Xem nhật ký <RightOutlined />
        </Button>
      }
    >
      {error ? (
        <Failure error={error} reload={reload} />
      ) : !data ? (
        <Spin className="pad" />
      ) : !data.items.length ? (
        <p className="pad muted">Chưa có thao tác được ghi nhận.</p>
      ) : (
        data.items.slice(0, 4).map((r) => (
          <div className="history-row" key={r.id}>
            <span className="metric-icon">
              <HistoryOutlined />
            </span>
            <div>
              <b>{actions[r.action] ?? r.action}</b> · {r.reason}
              <div className="history-meta">
                <RecordId value={r.targetId} />
                <span>{r.actorId}</span>
                <time>{new Date(r.createdAt).toLocaleString('vi-VN')}</time>
              </div>
            </div>
          </div>
        ))
      )}
    </Panel>
  );
}
