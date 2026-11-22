import { GroupedReports } from './GroupedReports';
import type { ReasonConfig } from './reportTypes';
import { History } from '../audit/History';
import { Alert, Image, Modal, Spin } from 'antd';
import { useEffect, useState } from 'react';
import { Session } from '../../shared/api/session';
import { useResource } from '../../shared/api/useResource';
import { Failure } from '../../shared/ui/Failure';
import { DecisionForm, type Action } from '../moderation/DecisionForm';
import { ListingDetails, type Listing } from '../listings/ListingDetails';

export type Report = {
  id: string;
  reporterId: string;
  reporter?: { fullName: string; email: string } | null;
  targetId: string;
  targetType: 'USER' | 'LISTING' | 'FEED_POST';
  reason: string;
  evidence: string;
  contactPhone?: string | null;
  contactEmail?: string | null;
  status: string;
  resolution?: string;
  updatedAt: string;
  createdAt: string;
};
type ReportedUser = { fullName: string; email: string; status: string; updatedAt: string };
type ReportedFeedPost = {
  id: string;
  text: string;
  imageUrl: string | null;
  createdAt: string;
  updatedAt: string;
  author: { id: string; fullName: string; status: string };
};
type Target = Listing | ReportedUser | ReportedFeedPost;

function FeedPostImage({ session, url }: { session: Session; url: string }) {
  const [src, setSrc] = useState('');
  useEffect(() => {
    let live = true;
    let objectUrl = '';
    session
      .feedImage(url.split('/').pop()!)
      .then((blob) => {
        if (!live) return;
        objectUrl = URL.createObjectURL(blob);
        setSrc(objectUrl);
      })
      .catch(() => undefined);
    return () => {
      live = false;
      if (objectUrl) URL.revokeObjectURL(objectUrl);
    };
  }, [session, url]);
  return src ? <Image src={src} alt="Ảnh trong bài viết bị báo cáo" width={240} /> : null;
}

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
    if (target.data && 'images' in target.data) {
      actions.push('KEEP');
      if (target.data.status === 'AVAILABLE') actions.push('REMOVE');
    }
  } else if (report.targetType === 'FEED_POST') {
    if (target.data) actions.push('REMOVE');
  } else if (target.data && 'email' in target.data && target.data.status !== 'UNVERIFIED') {
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
      mask={{ closable: false }}
    >
      <p>
        <strong>Lý do báo cáo</strong> · {report.reason}
      </p>
      {report.evidence && (
        <p>
          <strong>Bằng chứng</strong> · {report.evidence}
        </p>
      )}
      <p>
        Người báo cáo ·{' '}
        {report.reporter ? `${report.reporter.fullName} · ${report.reporter.email}` : report.reporterId}
      </p>
      {(report.contactPhone || report.contactEmail) && (
        <div>
          <strong>Thông tin liên hệ của người báo cáo</strong>
          {report.contactPhone && <p>Điện thoại · {report.contactPhone}</p>}
          {report.contactEmail && <p>Email · {report.contactEmail}</p>}
        </div>
      )}
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
          ) : 'text' in target.data ? (
            <>
              <p>
                <strong>Tác giả</strong> · {target.data.author.fullName} · {target.data.author.status}
              </p>
              <p>
                <strong>Đăng lúc</strong> · {new Date(target.data.createdAt).toLocaleString('vi-VN')}
              </p>
              <p className="post-preview">{target.data.text || 'Bài viết chỉ có hình ảnh.'}</p>
              {target.data.imageUrl && <FeedPostImage session={session} url={target.data.imageUrl} />}
            </>
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
  const [revision, setRevision] = useState(0);
  const [report, select] = useState<Report>();
  const reasons = useResource<{ items: ReasonConfig[] }>(session, '/admin/report-reasons');
  return <>
    {reasons.error && <Failure error={reasons.error} reload={reasons.reload} />}
    <GroupedReports session={session} reasons={reasons.data?.items} revision={revision} review={select} />
    <History key={revision} session={session} type="REPORT" />
    {report && <Review key={report.id} report={report} session={session} close={() => select(undefined)}
      reload={() => { select(undefined); setRevision(value => value + 1); }} />}
  </>;
}
