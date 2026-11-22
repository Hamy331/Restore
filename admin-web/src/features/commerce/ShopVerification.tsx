import { SafetyCertificateOutlined } from '@ant-design/icons';
import { useState } from 'react';
import { Alert, Button, Form, Input, Select, Table, Tag } from 'antd';
import { ApiError, Session } from '../../shared/api/session';
import { useResource, type Page } from '../../shared/api/useResource';
import { EditDialog } from '../../shared/ui/EditDialog';
import { EmptyState } from '../../shared/ui/Panel';
import { Failure } from '../../shared/ui/Failure';
import { TargetHistory } from '../audit/History';
import { MemberLink, memberStatus } from '../members/MemberLink';

type Status = 'PENDING' | 'VERIFIED' | 'ALL';
type VerificationType = 'OFFICIAL_BRAND' | 'CERTIFIED';
type Shop = {
  id: string;
  name: string;
  tagline: string;
  description: string;
  address: string | null;
  createdAt: string;
  verificationType: VerificationType | null;
  verifiedAt: string | null;
  certificateCode: string | null;
  owner: { id: string; fullName: string; email: string; status: string };
  plan: { tier: 'PERSONAL' | 'BASIC' | 'PRO'; endsAt: string | null };
};
const statuses: Record<Status, string> = {
  PENDING: 'Chờ xác minh',
  VERIFIED: 'Đã xác minh',
  ALL: 'Tất cả shop',
};
const types: Record<VerificationType, string> = {
  OFFICIAL_BRAND: 'Thương hiệu chính hãng',
  CERTIFIED: 'Shop được chứng nhận',
};
const tiers = { PERSONAL: 'Cá nhân', BASIC: 'Bán chuyên', PRO: 'Cửa hàng Pro' };
const date = (v: string) => new Date(v).toLocaleDateString('vi-VN');

/** Shop chỉ hiện ở "Shop uy tín" sau khi admin xác minh; thu hồi thì shop rời danh sách đó */
export function ShopVerification({ session }: { session: Session }) {
  const [page, setPage] = useState(1),
    [status, setStatus] = useState<Status>('PENDING'),
    [query, setQuery] = useState(''),
    [editor, edit] = useState<Shop>(),
    [notice, setNotice] = useState('');
  const path = '/admin/shops?' + new URLSearchParams({ page: String(page), status, q: query });
  const { data, error, reload } = useResource<Page<Shop> & { pending: number }>(session, path);
  const verify = !editor?.verificationType;

  async function submit(values: { type?: VerificationType; reason?: string }) {
    if (!editor) return;
    const action = verify ? 'verify' : 'unverify';
    try {
      await session.call('/admin/shops/' + encodeURIComponent(editor.id) + '/' + action, {
        ...(verify ? { type: values.type } : {}),
        reason: values.reason?.trim() || undefined,
      });
    } catch (err) {
      // Admin khác vừa xử lý shop này: tải lại danh sách và báo
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
        <strong>Xác minh shop</strong>
        <Input.Search
          className="filter-search"
          aria-label="Tìm shop"
          placeholder="Tìm tên shop, tên hoặc email chủ shop"
          allowClear
          maxLength={100}
          onSearch={(value) => {
            setPage(1);
            setQuery(value.trim());
          }}
        />
        <Select
          aria-label="Trạng thái xác minh"
          style={{ minWidth: 170 }}
          value={status}
          onChange={(value) => {
            setStatus(value);
            setPage(1);
          }}
          options={Object.entries(statuses).map(([value, label]) => ({
            value,
            label: value === 'PENDING' && data ? `${label} (${data.pending})` : label,
          }))}
        />
        <span className="toolbar-end">{data && data.total + ' shop'}</span>
      </div>
      {notice && <Alert type="warning" closable title={notice} onClose={() => setNotice('')} />}
      {error ? (
        <Failure error={error} reload={reload} />
      ) : data?.total === 0 ? (
        <EmptyState
          icon={<SafetyCertificateOutlined />}
          cleared={status === 'PENDING' && !query}
          title={status === 'PENDING' && !query ? 'Không có shop nào chờ xác minh' : 'Không có shop phù hợp'}
          detail="Shop mới mở (gói Cửa hàng Pro) sẽ xuất hiện tại đây để bạn kiểm tra và xác minh."
        />
      ) : (
        <Table<Shop>
          rowKey="id"
          dataSource={data?.items}
          loading={!data}
          scroll={{ x: 950 }}
          expandable={{
            expandedRowRender: (shop) => (
              <>
                {shop.tagline && <p>{shop.tagline}</p>}
                {shop.description && <p>{shop.description}</p>}
                {shop.address && <p>Địa chỉ: {shop.address}</p>}
                {shop.certificateCode && (
                  <p>
                    Mã chứng nhận {shop.certificateCode}
                    {shop.verifiedAt && ', xác minh ngày ' + date(shop.verifiedAt)}
                  </p>
                )}
                <TargetHistory session={session} type="SHOP" id={shop.id} />
              </>
            ),
          }}
          columns={[
            { title: 'Shop', dataIndex: 'name' },
            { title: 'Chủ shop', render: (_, shop) => <MemberLink person={shop.owner} /> },
            {
              title: 'Gói',
              render: (_, { plan }) =>
                tiers[plan.tier] + (plan.endsAt ? ' · hết hạn ' + date(plan.endsAt) : ''),
            },
            { title: 'Mở ngày', dataIndex: 'createdAt', render: date },
            {
              title: 'Trạng thái',
              render: (_, shop) => (
                <>
                  {shop.verificationType ? (
                    <Tag color="green">{types[shop.verificationType]}</Tag>
                  ) : (
                    <Tag color="gold">Chờ xác minh</Tag>
                  )}
                  {shop.owner.status !== 'ACTIVE' && (
                    <Tag color="red">Chủ shop: {memberStatus[shop.owner.status] ?? shop.owner.status}</Tag>
                  )}
                </>
              ),
            },
            {
              title: 'Xử lý',
              render: (_, shop) => (
                <Button
                  danger={!!shop.verificationType}
                  onClick={() => {
                    setNotice('');
                    edit(shop);
                  }}
                >
                  {shop.verificationType ? 'Thu hồi' : 'Xác minh'}
                </Button>
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
        <EditDialog<{ type?: VerificationType; reason?: string }>
          title={verify ? 'Xác minh shop' : 'Thu hồi xác minh'}
          submitLabel={verify ? 'Xác minh shop' : 'Thu hồi xác minh'}
          initialValues={{ type: 'CERTIFIED' }}
          save={submit}
          close={() => edit(undefined)}
          saved={reload}
        >
          <p>
            <strong>{editor.name}</strong> · {editor.owner.fullName} · {editor.owner.email}
          </p>
          <p>
            {verify
              ? 'Shop sẽ hiện ở "Shop uy tín", được cấp mã chứng nhận và không đổi tên được nữa.'
              : 'Shop sẽ rời "Shop uy tín" và mất mã chứng nhận ' + editor.certificateCode + '.'}
          </p>
          {verify && (
            <Form.Item name="type" label="Loại xác minh" rules={[{ required: true }]}>
              <Select options={Object.entries(types).map(([value, label]) => ({ value, label }))} />
            </Form.Item>
          )}
          <Form.Item
            name="reason"
            label={verify ? 'Ghi chú (nếu có)' : 'Lý do thu hồi'}
            rules={[
              {
                required: !verify,
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
