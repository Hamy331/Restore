import type { ReactNode } from 'react';
import { CheckCircleFilled, InboxOutlined } from '@ant-design/icons';

export function Panel({
  title,
  detail,
  action,
  children,
}: {
  title: string;
  detail?: string;
  action?: ReactNode;
  children: ReactNode;
}) {
  return (
    <section className="panel">
      <div className="panel-head">
        <div>
          <h2>{title}</h2>
          {detail && <p>{detail}</p>}
        </div>
        {action}
      </div>
      {children}
    </section>
  );
}
export function EmptyState({
  title,
  detail,
  icon = <InboxOutlined />,
  cleared = false,
}: {
  title: string;
  detail: string;
  icon?: ReactNode;
  cleared?: boolean;
}) {
  return (
    <div className="empty-state">
      <div className="empty-icon">
        {icon}
        {cleared && <CheckCircleFilled className="done" />}
      </div>
      <strong>{title}</strong>
      <p>{detail}</p>
    </div>
  );
}
