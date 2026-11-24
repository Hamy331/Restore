import { useState } from 'react';
import { Alert, Button, Form, Input, Modal, Popconfirm, Segmented, Select, Space, Table, Tag, message } from 'antd';
import { Session, errorText } from '../../shared/api/session';
import { useResource } from '../../shared/api/useResource';
import { Failure } from '../../shared/ui/Failure';
import { EditDialog } from '../../shared/ui/EditDialog';
import { Panel } from '../../shared/ui/Panel';
import { PosterImage } from '../shop-posters/ShopPosters';

type ShopStatus = 'PENDING' | 'APPROVED' | 'REJECTED';
type VerificationType = 'OFFICIAL_BRAND' | 'CERTIFIED';
type Shop = {
  id: string;
  name: string;
  tagline: string;
  description: string;
  address: string | null;
  logoUrl: string | null;
  coverUrl: string | null;
  status: ShopStatus;
  submittedAt: string;
  reviewedAt: string | null;
  rejectNote: string | null;
  verified: boolean;
  verificationType: VerificationType | null;
  certificateCode: string | null;
  categoryIds: string[];
  owner: { id: string; email: string; fullName: string; status: string };
  planTier: string;
  planEndsAt: string | null;
};
type Overview = { pendingCount: number; items: Shop[] };

const statusTags: Record<ShopStatus, { label: string; color: string }> = {
  PENDING: { label: 'Chờ duyệt', color: 'gold' },
  APPROVED: { label: 'Đã duyệt', color: 'green' },
  REJECTED: { label: 'Đã từ chối', color: 'red' },
};
const verificationTypes: Record<VerificationType, string> = {
  OFFICIAL_BRAND: 'Thương hiệu chính hãng',
  CERTIFIED: 'Shop được chứng nhận',
};
const tierLabels: Record<string, string> = { PRO: 'Cửa hàng', BASIC: 'Bán chuyên', PERSONAL: 'Cá nhân' };
/** Lý do mẫu theo quy định kiểm duyệt cửa hàng của Chợ Tốt; admin sửa thêm được */
const presetReasons = [
  'Tên shop dùng tên thương hiệu hoặc gây hiểu lầm là đại lý, trung tâm bảo hành chính thức.',
  'Tên shop có số điện thoại, đường dẫn web, từ ngữ quảng cáo quá mức hoặc từ ngữ không phù hợp.',
  'Ảnh đại diện hoặc ảnh bìa có logo thương hiệu khác, logo ReStore hoặc nội dung nhạy cảm.',
  'Mô tả có số điện thoại, đường dẫn web, từ khoá spam hoặc hàng cấm.',
  'Sản phẩm giới thiệu không thuộc chuyên mục của shop.',
];

const dateText = (value: string | null) => (value ? new Date(value).toLocaleString('vi-VN') : '—');

export function ShopReviews({ session }: { session: Session }) {
  const [status, setStatus] = useState<ShopStatus | 'ALL'>('PENDING');
  const { data, error, reload } = useResource<Overview>(session, '/admin/shops?status=' + status);
  // Tên danh mục mặt hàng chính shop chọn lúc đăng ký
  const catalog = useResource<{ categories: { id: string; name: string }[] }>(session, '/admin/catalog').data;
  const categoryName = (id: string) => catalog?.categories.find((c) => c.id === id)?.name ?? id;
  const [busy, setBusy] = useState('');
  const [rejecting, setRejecting] = useState<Shop>();
  const [rejectError, setRejectError] = useState('');
  const [form] = Form.useForm<{ note: string }>();
  // Shop đã duyệt đang mở hộp thoại xác minh / thu hồi xác minh
  const [verifying, setVerifying] = useState<Shop>();

  async function approve(shop: Shop) {
    if (busy) return;
    setBusy(shop.id);
    try {
      await session.call(`/admin/shops/${encodeURIComponent(shop.id)}/approve`, {});
      message.success('Đã duyệt cửa hàng, chủ shop sẽ nhận được thông báo.');
    } catch (err) {
      message.error(errorText(err));
    } finally {
      setBusy('');
      reload();
    }
  }

  async function reject({ note }: { note: string }) {
    if (!rejecting || busy) return;
    setBusy(rejecting.id);
    setRejectError('');
    try {
      await session.call(`/admin/shops/${encodeURIComponent(rejecting.id)}/reject`, { note: note.trim() });
      message.success('Đã từ chối cửa hàng, chủ shop sẽ nhận được lý do.');
      setRejecting(undefined);
      reload();
    } catch (err) {
      setRejectError(errorText(err));
    } finally {
      setBusy('');
    }
  }

  async function saveVerification({ type, reason }: { type?: VerificationType; reason?: string }) {
    if (!verifying) return;
    const verify = !verifying.verified;
    await session.call(`/admin/shops/${encodeURIComponent(verifying.id)}/${verify ? 'verify' : 'unverify'}`, {
      ...(verify ? { type } : {}),
      reason: reason?.trim() || undefined,
    });
    message.success(verify ? 'Đã xác minh, shop hiện ở Shop uy tín.' : 'Đã thu hồi xác minh, shop rời Shop uy tín.');
  }

  const pending = data?.pendingCount ?? 0;
  return (
    <>
      <Panel
        title="Duyệt cửa hàng"
        detail={
          data
            ? pending
              ? `${pending} cửa hàng đang chờ duyệt. Người mua chỉ xem được trang shop sau khi được duyệt.`
              : 'Không còn cửa hàng nào chờ duyệt.'
            : 'Cửa hàng mới mở hoặc vừa sửa sau khi bị từ chối'
        }
        action={
          <Segmented
            value={status}
            onChange={(value) => setStatus(value as ShopStatus | 'ALL')}
            options={[
              { value: 'PENDING', label: `Chờ duyệt${pending ? ` (${pending})` : ''}` },
              { value: 'APPROVED', label: 'Đã duyệt' },
              { value: 'REJECTED', label: 'Đã từ chối' },
              { value: 'ALL', label: 'Tất cả' },
            ]}
          />
        }
      >
        {error ? (
          <Failure error={error} reload={reload} />
        ) : (
          <Table<Shop>
            rowKey="id"
            loading={!data}
            dataSource={data?.items}
            pagination={false}
            scroll={{ x: 1100 }}
            locale={{ emptyText: status === 'PENDING' ? 'Không có cửa hàng nào chờ duyệt.' : 'Chưa có cửa hàng.' }}
            columns={[
              {
                title: 'Ảnh đại diện / ảnh bìa',
                width: 240,
                render: (_, shop) => (
                  <Space orientation="vertical" size={4}>
                    {shop.logoUrl ? <PosterImage session={session} path={shop.logoUrl} alt="Ảnh đại diện" width={64} /> : <span className="muted">Chưa có ảnh đại diện</span>}
                    {shop.coverUrl ? <PosterImage session={session} path={shop.coverUrl} alt="Ảnh bìa" /> : <span className="muted">Chưa có ảnh bìa</span>}
                  </Space>
                ),
              },
              {
                title: 'Thông tin shop',
                render: (_, shop) => (
                  <Space orientation="vertical" size={2}>
                    <b>{shop.name}</b>
                    {shop.categoryIds.length > 0 && (
                      <span>
                        {shop.categoryIds.map((id) => (
                          <Tag key={id} color="blue">{categoryName(id)}</Tag>
                        ))}
                      </span>
                    )}
                    {shop.tagline && <span>{shop.tagline}</span>}
                    {shop.description && <small style={{ whiteSpace: 'pre-line' }}>{shop.description}</small>}
                    {shop.address && <small className="muted">{shop.address}</small>}
                  </Space>
                ),
              },
              {
                title: 'Chủ shop',
                width: 220,
                render: (_, shop) => (
                  <Space orientation="vertical" size={2}>
                    <span>{shop.owner.fullName}</span>
                    <small>{shop.owner.email}</small>
                    <span>
                      <Tag color={shop.planTier === 'PRO' ? 'purple' : 'default'}>Gói {tierLabels[shop.planTier] ?? shop.planTier}</Tag>
                      {shop.verified && (
                        <Tag color="green" title={shop.verificationType ? verificationTypes[shop.verificationType] : undefined}>
                          Shop uy tín{shop.certificateCode && ` · ${shop.certificateCode}`}
                        </Tag>
                      )}
                      {shop.owner.status !== 'ACTIVE' && <Tag color="red">Tài khoản {shop.owner.status}</Tag>}
                    </span>
                  </Space>
                ),
              },
              {
                title: 'Trạng thái',
                width: 220,
                render: (_, shop) => (
                  <Space orientation="vertical" size={2}>
                    <Tag color={statusTags[shop.status].color}>{statusTags[shop.status].label}</Tag>
                    <small className="muted">Gửi lúc {dateText(shop.submittedAt)}</small>
                    {shop.rejectNote && <small>{shop.rejectNote}</small>}
                  </Space>
                ),
              },
              {
                title: 'Thao tác',
                width: 190,
                render: (_, shop) =>
                  shop.status === 'PENDING' ? (
                    <Space>
                      <Popconfirm
                        title="Duyệt cửa hàng này?"
                        description="Người mua sẽ xem được trang shop, tên shop bị khoá."
                        okText="Duyệt"
                        cancelText="Hủy"
                        onConfirm={() => approve(shop)}
                      >
                        <Button type="primary" loading={busy === shop.id} disabled={!!busy}>
                          Duyệt
                        </Button>
                      </Popconfirm>
                      <Button
                        danger
                        disabled={!!busy}
                        onClick={() => {
                          form.resetFields();
                          setRejectError('');
                          setRejecting(shop);
                        }}
                      >
                        Từ chối
                      </Button>
                    </Space>
                  ) : (
                    <Space orientation="vertical" size={4}>
                      <span className="muted">{shop.reviewedAt ? `Xử lý ${dateText(shop.reviewedAt)}` : '—'}</span>
                      {shop.status === 'APPROVED' && (
                        <Button size="small" danger={shop.verified} disabled={!!busy} onClick={() => setVerifying(shop)}>
                          {shop.verified ? 'Thu hồi xác minh' : 'Xác minh'}
                        </Button>
                      )}
                    </Space>
                  ),
              },
            ]}
          />
        )}
      </Panel>
      <Modal
        title={rejecting ? `Từ chối cửa hàng “${rejecting.name}”` : 'Từ chối cửa hàng'}
        open={!!rejecting}
        okText="Từ chối"
        okButtonProps={{ danger: true, loading: !!busy }}
        cancelText="Hủy"
        onOk={() => form.submit()}
        onCancel={() => setRejecting(undefined)}
        destroyOnHidden
      >
        <Form layout="vertical" form={form} onFinish={reject} disabled={!!busy}>
          <Form.Item label="Lý do mẫu">
            <Select
              placeholder="Chọn để điền nhanh"
              options={presetReasons.map((value) => ({ value, label: value }))}
              onChange={(value: string) => form.setFieldValue('note', value)}
            />
          </Form.Item>
          <Form.Item
            name="note"
            label="Lý do gửi chủ shop"
            rules={[
              { required: true, whitespace: true, message: 'Hãy ghi lý do từ chối.' },
              { max: 300, message: 'Tối đa 300 ký tự.' },
            ]}
          >
            <Input.TextArea rows={3} />
          </Form.Item>
          <Alert type="info" title="Chủ shop sửa thông tin rồi lưu là cửa hàng tự vào lại hàng chờ duyệt." className="notice" />
          {rejectError && <Alert type="error" title={rejectError} className="notice" />}
        </Form>
      </Modal>
      {verifying && (
        <EditDialog<{ type?: VerificationType; reason?: string }>
          title={verifying.verified ? `Thu hồi xác minh “${verifying.name}”` : `Xác minh “${verifying.name}”`}
          submitLabel={verifying.verified ? 'Thu hồi xác minh' : 'Xác minh shop'}
          initialValues={{ type: 'CERTIFIED' }}
          save={saveVerification}
          close={() => setVerifying(undefined)}
          saved={reload}
        >
          <p>
            {verifying.verified
              ? `Shop sẽ rời "Shop uy tín" và mất mã chứng nhận ${verifying.certificateCode ?? ''}.`
              : 'Shop sẽ hiện ở "Shop uy tín" và được cấp mã chứng nhận.'}
          </p>
          {!verifying.verified && (
            <Form.Item name="type" label="Loại xác minh" rules={[{ required: true }]}>
              <Select options={Object.entries(verificationTypes).map(([value, label]) => ({ value, label }))} />
            </Form.Item>
          )}
          <Form.Item
            name="reason"
            label={verifying.verified ? 'Lý do thu hồi' : 'Ghi chú (nếu có)'}
            rules={[
              {
                required: verifying.verified,
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
