import { useState } from 'react';
import { Button, Form, Input, Radio, Segmented, Space, Table, Tag } from 'antd';
import { useWorkspace } from '../../app/workspace';
import { pickFilter } from '../../app/route';
import { MemberLink } from '../members/MemberLink';
import { Session } from '../../shared/api/session';
import { usePage } from '../../shared/api/usePage';
import { EditDialog } from '../../shared/ui/EditDialog';
import { Failure } from '../../shared/ui/Failure';

type Message = { id: string; isAdmin: boolean; content: string; createdAt: string };
type Ticket = {
  id: string;
  subject: string;
  userId: string;
  status: 'OPEN' | 'RESOLVED';
  messages: Message[];
  updatedAt: string;
  sender: { fullName: string; email: string } | null;
};
const statuses = [
  { value: 'OPEN', label: 'Đang mở' },
  { value: 'RESOLVED', label: 'Đã giải quyết' },
  { value: '', label: 'Tất cả' },
];
const senderText = (t: Ticket) => (t.sender ? `${t.sender.fullName} · ${t.sender.email}` : t.userId);
type Fields = { action: 'reply' | 'status'; content?: string };
function ReplyInput() {
  const action = Form.useWatch('action');
  return action === 'reply' ? (
    <Form.Item
      name="content"
      label="Nội dung trả lời"
      rules={[{ required: true, whitespace: true, max: 4000 }]}
    >
      <Input.TextArea rows={4} maxLength={4000} />
    </Form.Item>
  ) : null;
}
export function Tickets({ session }: { session: Session }) {
  const { filter } = useWorkspace();
  // Mặc định chỉ xem yêu cầu đang mở; link từ Tổng quan cũng mở bộ lọc này
  const [status, setStatus] = useState(pickFilter(filter || 'OPEN', statuses.map((s) => s.value), 'OPEN'));
  const list = usePage<Ticket>(session, '/admin/tickets' + (status ? '?status=' + status : ''));
  const [row, select] = useState<Ticket>();
  return (
    <>
      <Segmented className="notice" value={status} onChange={setStatus} options={statuses} />
      {list.error ? (
        <Failure error={list.error} reload={list.reload} />
      ) : (
        <Table<Ticket>
          rowKey="id"
          loading={!list.data}
          dataSource={list.data?.items}
          scroll={{ x: 760 }}
          pagination={list.pagination}
          columns={[
            { title: 'Yêu cầu', dataIndex: 'subject' },
            { title: 'Người gửi', render: (_, r) => senderText(r) },
            {
              title: 'Trạng thái',
              render: (_, r) =>
                r.status === 'OPEN' ? <Tag color="orange">Đang mở</Tag> : <Tag>Đã giải quyết</Tag>,
            },
            {
              title: 'Cập nhật',
              render: (_, r) => new Date(r.updatedAt).toLocaleString('vi-VN'),
            },
            { title: '', render: (_, r) => <Button onClick={() => select(r)}>Xem yêu cầu</Button> },
          ]}
        />
      )}
      {row && (
        <EditDialog<Fields>
          title={row.subject}
          initialValues={{ action: row.status === 'OPEN' ? 'reply' : 'status' }}
          saved={list.reload}
          onStale={list.reload}
          close={() => select(undefined)}
          submitLabel="Xác nhận"
          save={(v) =>
            session.call(
              '/admin/tickets/' + encodeURIComponent(row.id) + '/' + v.action,
              v.action === 'reply'
                ? { updatedAt: row.updatedAt, content: v.content?.trim() }
                : { updatedAt: row.updatedAt, status: row.status === 'OPEN' ? 'RESOLVED' : 'OPEN' },
            )
          }
        >
          <p className="muted">Người gửi: {row.sender ? <MemberLink person={row.sender} /> : row.userId}</p>
          <Space orientation="vertical" className="notice">
            {row.messages.map((m) => (
              <div key={m.id}>
                <strong>{m.isAdmin ? 'Quản trị viên' : 'Người dùng'}</strong> ·{' '}
                {new Date(m.createdAt).toLocaleString('vi-VN')}
                <div style={{ whiteSpace: 'pre-wrap' }}>{m.content}</div>
              </div>
            ))}
          </Space>
          <Form.Item name="action" label="Thao tác">
            <Radio.Group
              options={[
                ...(row.status === 'OPEN' ? [{ value: 'reply', label: 'Trả lời' }] : []),
                {
                  value: 'status',
                  label: row.status === 'OPEN' ? 'Đánh dấu đã giải quyết' : 'Mở lại yêu cầu',
                },
              ]}
            />
          </Form.Item>
          <ReplyInput />
        </EditDialog>
      )}
    </>
  );
}
