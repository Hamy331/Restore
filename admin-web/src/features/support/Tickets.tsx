import { useState } from 'react';
import { Button, Form, Input, Radio, Space, Table } from 'antd';
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
};
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
  const list = usePage<Ticket>(session, '/admin/tickets');
  const [row, select] = useState<Ticket>();
  return (
    <>
      {list.error ? (
        <Failure error={list.error} reload={list.reload} />
      ) : (
        <Table<Ticket>
          rowKey="id"
          loading={!list.data}
          dataSource={list.data?.items}
          pagination={list.pagination}
          columns={[
            { title: 'Yêu cầu', dataIndex: 'subject' },
            { title: 'Người gửi', dataIndex: 'userId' },
            {
              title: 'Trạng thái',
              render: (_, r) => (r.status === 'OPEN' ? 'Đang mở' : 'Đã giải quyết'),
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
