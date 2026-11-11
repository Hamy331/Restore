import { Tag, Typography } from 'antd';
import { actions, modules } from './auditLabels';
import type { Entry } from './auditColumns';

const colors: Record<string, string> = {
  CONFIRM: 'green',
  APPROVE: 'green',
  RESOLVED: 'cyan',
  DELETE: 'red',
  BAN: 'red',
  INDEX: 'purple',
  REPLY: 'blue',
  UPLOAD: 'blue',
  CREATE: 'volcano',
};
export function RecordId({ value }: { value: string }) {
  const short = value.length > 16 ? value.slice(0, 8) + '…' + value.slice(-4) : value;
  return (
    <Typography.Text
      className="record-id"
      title={value}
      copyable={{ text: value, tooltips: ['Sao chép mã', 'Đã sao chép'] }}
    >
      {short}
    </Typography.Text>
  );
}
export const auditColumns = [
  {
    title: 'Thời điểm',
    dataIndex: 'createdAt',
    render: (s: string) => (
      <div className="cell-stack">
        <b>{new Date(s).toLocaleTimeString('vi-VN')}</b>
        <small>{new Date(s).toLocaleDateString('vi-VN')}</small>
      </div>
    ),
  },
  {
    title: 'Thao tác',
    dataIndex: 'action',
    render: (s: string) => <Tag color={colors[s]}>{actions[s] ?? s}</Tag>,
  },
  { title: 'Phân hệ', dataIndex: 'targetType', render: (s: string) => modules[s] ?? s },
  { title: 'Đối tượng', dataIndex: 'targetId', render: (s: string) => <RecordId value={s} /> },
  { title: 'Lý do', dataIndex: 'reason' },
  {
    title: 'Người xử lý',
    dataIndex: 'actorId',
    render: (s: string, _r: Entry) => (
      <span className="actor">
        <span className="avatar tiny">{s.slice(0, 2).toUpperCase()}</span>
        {s}
      </span>
    ),
  },
];
