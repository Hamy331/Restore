import { ShopOutlined, RocketOutlined } from '@ant-design/icons';
import { EmptyState } from '../../shared/ui/Panel';
import { useState } from 'react';
import { Alert, Button, Checkbox, Form, Input, Select, Space, Table } from 'antd';
import { ApiError, Session } from '../../shared/api/session';
import { useResource, type Page } from '../../shared/api/useResource';
import { Failure } from '../../shared/ui/Failure';
import { EditDialog } from '../../shared/ui/EditDialog';
import { vnd } from './PackageFields';

export type OrderKind = 'store' | 'promotion';
const statuses = { PENDING: 'Chờ đối soát', CONFIRMED: 'Đã xác nhận', REJECTED: 'Đã từ chối' };
type Order = {
  id: string;
  status: keyof typeof statuses;
  amount: string;
  createdAt: string;
  decidedAt: string | null;
  package: { name: string };
  user: { fullName: string; email: string };
  category?: { name: string };
  listing?: { title: string };
};
type Decision = { row: Order; action: 'confirm' | 'reject' };
const date = (v: string) => new Date(v).toLocaleString('vi-VN');

export function Orders({ session, kind }: { session: Session; kind: OrderKind }) {
  const [page, setPage] = useState(1),
    [status, setStatus] = useState('PENDING'),
    [editor, edit] = useState<Decision>(),
    [notice, setNotice] = useState('');
  const path = '/admin/' + kind + '-orders?' + new URLSearchParams({ page: String(page), status });
  const { data, error, reload } = useResource<Page<Order>>(session, path);
  const target = (row: Order) => row.category?.name ?? row.listing?.title;
  const confirm = editor?.action === 'confirm';
  async function submit({ reason }: { reason?: string }) {
    if (!editor) return;
    const group = kind === 'store' ? 'stores' : 'promotions';
    try {
      await session.call(
        '/' + group + '/admin/orders/' + encodeURIComponent(editor.row.id) + '/' + editor.action,
        { reason: reason?.trim() || 'Đã đối soát thanh toán' },
      );
    } catch (err) {
      if (err instanceof ApiError && err.status === 409) {
        setNotice(err.message);
        reload();
        edit(undefined);
      }
      throw err;
    }
  }
  return (
    <>
      <div className="toolbar compact">
        <strong>{kind === 'store' ? 'Đơn đăng ký cửa hàng' : 'Đơn mua gói đẩy tin'}</strong>
        <span className="toolbar-end">{data && data.total + ' đơn'}</span>
        <Select
          className="notice"
          aria-label="Trạng thái đơn"
          style={{ minWidth: 170 }}
          value={status}
          onChange={(v) => {
            setStatus(v);
            setPage(1);
          }}
          options={Object.entries({ '': 'Tất cả trạng thái', ...statuses }).map(
            ([value, label]) => ({
              value,
              label,
            }),
          )}
        />
      </div>
      {notice && <Alert type="warning" closable title={notice} onClose={() => setNotice('')} />}
      {error ? (
        <Failure error={error} reload={reload} />
      ) : data?.total === 0 ? (
        <EmptyState
          icon={kind === 'store' ? <ShopOutlined /> : <RocketOutlined />}
          cleared={status === 'PENDING'}
          title={status === 'PENDING' ? 'Không có đơn nào chờ xử lý' : 'Không có đơn phù hợp'}
          detail={
            status === 'PENDING'
              ? 'Đơn mua mới của người bán sẽ xuất hiện tại đây để bạn đối soát.'
              : 'Chọn trạng thái khác để xem các đơn đã ghi nhận.'
          }
        />
      ) : (
        <Table<Order>
          rowKey="id"
          dataSource={data?.items}
          loading={!data}
          scroll={{ x: 950 }}
          expandable={{
            expandedRowRender: (r) => (
              <>
                <p>Mã đơn: {r.id}</p>
                <p>
                  {r.user.email} · {target(r)}
                </p>
                {r.decidedAt && <p>Xử lý lúc {date(r.decidedAt)}</p>}
              </>
            ),
          }}
          columns={[
            { title: 'Thời điểm tạo', dataIndex: 'createdAt', render: date },
            { title: 'Người mua', render: (_, r) => r.user.fullName },
            { title: 'Gói', render: (_, r) => r.package.name },
            { title: 'Số tiền', dataIndex: 'amount', render: vnd },
            {
              title: 'Trạng thái',
              dataIndex: 'status',
              render: (s: Order['status']) => statuses[s],
            },
            {
              title: 'Xử lý',
              render: (_, row) =>
                row.status === 'PENDING' ? (
                  <Space>
                    <Button
                      onClick={() => {
                        setNotice('');
                        edit({ row, action: 'confirm' });
                      }}
                    >
                      Đối soát
                    </Button>
                    <Button
                      danger
                      onClick={() => {
                        setNotice('');
                        edit({ row, action: 'reject' });
                      }}
                    >
                      Từ chối
                    </Button>
                  </Space>
                ) : (
                  '—'
                ),
            },
          ]}
          pagination={{
            current: page,
            pageSize: 25,
            total: data?.total,
            showSizeChanger: false,
            onChange: setPage,
          }}
        />
      )}
      {editor && (
        <EditDialog
          title={confirm ? 'Đối soát thanh toán' : 'Từ chối đơn mua'}
          submitLabel={confirm ? 'Xác nhận thanh toán' : 'Từ chối đơn'}
          save={submit}
          close={() => edit(undefined)}
          saved={reload}
        >
          <p>Mã đơn: {editor.row.id}</p>
          <p>
            {editor.row.user.email} · {editor.row.package.name} · {target(editor.row)}
          </p>
          <p>
            Số tiền: <strong>{vnd(editor.row.amount)}</strong>
          </p>
          {confirm && (
            <Form.Item
              name="verified"
              valuePropName="checked"
              rules={[
                {
                  validator: (_, value) =>
                    value
                      ? Promise.resolve()
                      : Promise.reject(new Error('Hãy đối chiếu giao dịch trước khi xác nhận.')),
                },
              ]}
            >
              <Checkbox>Đã kiểm tra tiền thực nhận và mã đơn</Checkbox>
            </Form.Item>
          )}
          <Form.Item
            name="reason"
            label={confirm ? 'Ghi chú đối soát (nếu có)' : 'Lý do từ chối'}
            rules={[
              {
                required: !confirm,
                min: 5,
                max: 300,
                transform: (v) => v?.trim(),
                message: 'Nhập từ 5 đến 300 ký tự.',
              },
            ]}
          >
            <Input.TextArea maxLength={300} />
          </Form.Item>
        </EditDialog>
      )}
    </>
  );
}
