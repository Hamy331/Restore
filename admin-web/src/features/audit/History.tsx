import { Button, Spin } from 'antd';
import { HistoryOutlined, RightOutlined } from '@ant-design/icons';
import { useWorkspace } from '../../app/workspace';
import { Session } from '../../shared/api/session';
import { useResource, type Page } from '../../shared/api/useResource';
import { Panel } from '../../shared/ui/Panel';
import { Failure } from '../../shared/ui/Failure';
import { actions } from './auditLabels';
import { RecordId } from './AuditTable';
import { actorName, type Entry } from './auditColumns';

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
        data.items.slice(0, 4).map((r) => <HistoryRow key={r.id} entry={r} showTarget />)
      )}
    </Panel>
  );
}
function HistoryRow({ entry: r, showTarget }: { entry: Entry; showTarget?: boolean }) {
  return (
    <div className="history-row">
      <span className="metric-icon">
        <HistoryOutlined />
      </span>
      <div>
        <b>{actions[r.action] ?? r.action}</b>
        {r.reason && ' · ' + r.reason}
        <div className="history-meta">
          {showTarget && <RecordId value={r.targetId} />}
          <span>{actorName(r)}</span>
          <time>{new Date(r.createdAt).toLocaleString('vi-VN')}</time>
        </div>
      </div>
    </div>
  );
}
/** Các lần xử lý trước của một đối tượng (vd. một thành viên), mới nhất trước; ẩn nếu không xem được nhật ký */
export function TargetHistory({ session, type, id }: { session: Session; type: string; id: string }) {
  const { canOpen } = useWorkspace();
  if (!canOpen('audit')) return null;
  return <TargetHistoryList session={session} type={type} id={id} />;
}
function TargetHistoryList({ session, type, id }: { session: Session; type: string; id: string }) {
  const { data, error } = useResource<Page<Entry>>(
    session,
    '/admin/audit?' + new URLSearchParams({ targetType: type, targetId: id }),
  );
  if (error) return <p className="muted">Không tải được lịch sử xử lý: {error}</p>;
  if (!data) return <Spin size="small" />;
  return (
    <section className="target-history" aria-label="Lịch sử xử lý">
      <b>
        {data.total ? `Đã xử lý ${data.total} lần` : 'Chưa từng bị xử lý'}
      </b>
      {data.items.slice(0, 5).map((r) => (
        <HistoryRow key={r.id} entry={r} />
      ))}
    </section>
  );
}
