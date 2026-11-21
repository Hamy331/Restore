import { useState } from 'react';
import { Alert, Button, Form, Input, InputNumber, Modal, Segmented, Select, Space, Table, Tag, Tooltip } from 'antd';
import { Session, ApiError, errorText } from '../../shared/api/session';
import { useResource, type Page } from '../../shared/api/useResource';
import { Failure } from '../../shared/ui/Failure';
import { useWorkspace } from '../../app/workspace';
type Member = {
  phone: string | null;
  _count: { listings: number };
  id: string;
  username: string | null;
  role: string;
  createdAt: string;
  fullName: string;
  email: string;
  status: string;
  updatedAt: string;
  /** Gói đang dùng (hết hạn tính là PERSONAL) */
  planTier: 'PERSONAL' | 'BASIC' | 'PRO';
  planEndsAt: string | null;
  shop: { name: string; verified: boolean } | null;
};
type MemberType = 'PERSONAL' | 'BASIC' | 'PRO' | 'ADMIN';
type MemberPage = Page<Member> & { counts?: Record<MemberType, number> };
/** Phân loại tài khoản: theo gói đang dùng, hoặc quản trị viên (chỉ xem) */
const types: { value: MemberType | ''; label: string }[] = [
  { value: '', label: 'Tất cả thành viên' },
  { value: 'PERSONAL', label: 'Cá nhân' },
  { value: 'BASIC', label: 'Bán chuyên' },
  { value: 'PRO', label: 'Cửa hàng Pro' },
  { value: 'ADMIN', label: 'Quản trị viên' },
];
const tiers: Record<Member['planTier'], { label: string; color: string }> = {
  PERSONAL: { label: 'Cá nhân', color: 'default' },
  BASIC: { label: 'Bán chuyên', color: 'blue' },
  PRO: { label: 'Cửa hàng Pro', color: 'purple' },
};
const statuses: Record<string, string> = {
  ACTIVE: 'Hoạt động',
  BANNED: 'Đã cấm',
  SUSPENDED: 'Tạm khóa',
  UNVERIFIED: 'Chưa xác minh',
};
const actions = {
  WARN: 'Cảnh cáo',
  SUSPEND: 'Tạm khóa',
  BAN: 'Cấm tài khoản',
  RESTORE: 'Khôi phục',
} as const;
type Decision = { action: keyof typeof actions; reason: string; days?: number };
function MemberAction({
  session,
  member,
  close,
  updated,
}: {
  session: Session;
  member: Member;
  close: () => void;
  updated: () => void;
}) {
  const [form] = Form.useForm<Decision>();
  const action = Form.useWatch('action', form);
  const [busy, setBusy] = useState(false),
    [error, setError] = useState(''),
    [stale, setStale] = useState(false);
  const allowed: Decision['action'][] =
    member.status === 'BANNED'
      ? ['RESTORE']
      : member.status === 'SUSPENDED'
        ? ['WARN', 'SUSPEND', 'BAN', 'RESTORE']
        : ['WARN', 'SUSPEND', 'BAN'];
  async function save(values: Decision) {
    if (busy || stale) return;
    setBusy(true);
    setError('');
    try {
      await session.call('/admin/users/' + encodeURIComponent(member.id) + '/action', {
        action: values.action,
        reason: values.reason.trim(),
        updatedAt: member.updatedAt,
        ...(values.action === 'SUSPEND' ? { days: values.days } : {}),
      });
      updated();
      close();
    } catch (err) {
      setError(errorText(err));
      if (err instanceof ApiError && err.status === 409) {
        setStale(true);
        updated();
      }
    } finally {
      setBusy(false);
    }
  }
  return (
    <Modal
      open
      title={'Xử lý tài khoản · ' + member.email}
      onCancel={close}
      closable={!busy}
      maskClosable={false}
      keyboard={!busy}
      footer={
        <Space>
          <Button disabled={busy} onClick={close}>
            Đóng
          </Button>
          <Button type="primary" loading={busy} disabled={stale} onClick={() => form.submit()}>
            Xác nhận
          </Button>
        </Space>
      }
    >
      <Form
        form={form}
        layout="vertical"
        onFinish={save}
        initialValues={{ action: allowed[0], days: 7 }}
      >
        <Form.Item name="action" label="Thao tác">
          <Select options={allowed.map((value) => ({ value, label: actions[value] }))} />
        </Form.Item>
        {action === 'SUSPEND' && (
          <Form.Item
            name="days"
            label="Số ngày"
            rules={[{ required: true, type: 'integer', min: 1, max: 365 }]}
          >
            <InputNumber min={1} max={365} />
          </Form.Item>
        )}
        <Form.Item
          name="reason"
          label="Lý do"
          rules={[
            {
              required: true,
              min: 5,
              max: 300,
              transform: (s) => s?.trim(),
              message: 'Nhập từ 5 đến 300 ký tự.',
            },
          ]}
        >
          <Input.TextArea maxLength={300} />
        </Form.Item>
        {error && <Alert type="error" title={error} />}
      </Form>
    </Modal>
  );
}
export function Members({ session }: { session: Session }) {
  const { filter } = useWorkspace();
  const [page, setPage] = useState(1),
    [query, setQuery] = useState(''),
    [status, setStatus] = useState(filter),
    [type, setType] = useState<MemberType | ''>(''),
    [member, setMember] = useState<Member>();
  const { data, error, reload } = useResource<MemberPage>(
    session,
    '/admin/users?' +
      new URLSearchParams({ page: String(page), q: query, status, details: '1', ...(type ? { type } : {}) }),
  );
  const counts = data?.counts;
  const memberTotal = counts ? counts.PERSONAL + counts.BASIC + counts.PRO : undefined;
  return (
    <>
      <section className="panel">
        <Segmented
          className="notice"
          value={type}
          onChange={(value) => {
            setType(value as MemberType | '');
            setPage(1);
          }}
          options={types.map(({ value, label }) => {
            const count = value ? counts?.[value] : memberTotal;
            return { value, label: count === undefined ? label : `${label} (${count})` };
          })}
        />
        <div className="toolbar">
          <Input.Search
            className="filter-search"
            aria-label="Tìm thành viên"
            placeholder="Tìm tên, tài khoản, email hoặc số điện thoại"
            allowClear
            maxLength={100}
            onSearch={(value) => {
              setPage(1);
              setQuery(value.trim());
            }}
          />
          <Select
            aria-label="Trạng thái thành viên"
            value={status}
            style={{ minWidth: 165 }}
            onChange={(value) => {
              setStatus(value);
              setPage(1);
            }}
            options={[
              { value: '', label: 'Tất cả trạng thái' },
              ...Object.entries(statuses).map(([value, label]) => ({ value, label })),
            ]}
          />
          <span className="toolbar-end">{data && data.total + ' thành viên'}</span>
        </div>
        {error ? (
          <Failure error={error} reload={reload} />
        ) : (
          <Table<Member>
            rowKey="id"
            loading={!data}
            dataSource={data?.items}
            scroll={{ x: 650 }}
            columns={[
              {
                title: 'Thành viên',
                render: (_, r) => (
                  <div className="person">
                    <span className="avatar member">{r.fullName.slice(0, 1)}</span>
                    <div className="cell-stack">
                      <b>{r.fullName}</b>
                      {r.username && <small>@{r.username}</small>}
                    </div>
                  </div>
                ),
              },
              {
                title: 'Phân loại',
                render: (_, r) =>
                  r.role === 'ADMIN' ? (
                    <Tag color="red">Quản trị viên</Tag>
                  ) : (
                    <div className="cell-stack">
                      <span>
                        <Tag color={tiers[r.planTier]?.color}>{tiers[r.planTier]?.label ?? r.planTier}</Tag>
                      </span>
                      {r.shop && (
                        <small>
                          {r.shop.name}
                          {r.shop.verified ? ' · đã xác minh' : ''}
                        </small>
                      )}
                      {r.planEndsAt && <small>Hết hạn {new Date(r.planEndsAt).toLocaleDateString('vi-VN')}</small>}
                    </div>
                  ),
              },
              {
                title: 'Tham gia',
                render: (_, r) => new Date(r.createdAt).toLocaleDateString('vi-VN'),
              },
              {
                title: 'Liên hệ',
                render: (_, r) => (
                  <div className="cell-stack">
                    {r.email}
                    {r.phone && <small>{r.phone}</small>}
                  </div>
                ),
              },
              { title: 'Tin đăng', render: (_, r) => r._count?.listings ?? '—' },
              {
                title: 'Trạng thái',
                dataIndex: 'status',
                render: (s: string) => (
                  <Tag color={s === 'ACTIVE' ? 'green' : s === 'BANNED' ? 'red' : 'orange'}>
                    {statuses[s] ?? s}
                  </Tag>
                ),
              },
              {
                title: 'Thao tác',
                render: (_, row) =>
                  row.role === 'ADMIN' ? (
                    <Tooltip title="Tài khoản quản trị không xử lý ở đây.">
                      <Tag>Chỉ xem</Tag>
                    </Tooltip>
                  ) : (
                    <Button disabled={row.status === 'UNVERIFIED'} onClick={() => setMember(row)}>
                      Xử lý
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
      </section>
      {member && (
        <MemberAction
          session={session}
          member={member}
          close={() => setMember(undefined)}
          updated={reload}
        />
      )}
    </>
  );
}
