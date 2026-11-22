import { useEffect, useState } from 'react';
import { Alert, Button, Form, Image, Input, Modal, Popconfirm, Segmented, Select, Space, Table, Tag, message } from 'antd';
import { Session, errorText } from '../../shared/api/session';
import { useResource } from '../../shared/api/useResource';
import { Failure } from '../../shared/ui/Failure';
import { Panel } from '../../shared/ui/Panel';

type PosterStatus = 'PENDING' | 'APPROVED' | 'REJECTED' | 'STOPPED';
type Poster = {
  id: string;
  title: string;
  imageUrl: string;
  status: PosterStatus;
  /** Trạng thái hiển thị: thêm SCHEDULED / RUNNING / ENDED cho poster đã duyệt */
  state: string;
  startsAt: string | null;
  endsAt: string | null;
  days: number | null;
  rejectReason: string | null;
  rejectNote: string | null;
  reviewedAt: string | null;
  createdAt: string;
  listing: { id: string; title: string; image: string | null; available: boolean } | null;
  shop: {
    id: string;
    name: string;
    verified: boolean;
    ownerEmail: string;
    ownerName: string;
    planTier: string;
    planEndsAt: string | null;
  };
};
type Overview = { pendingCount: number; items: Poster[] };
type RejectFields = { reason: string; note?: string };

const statusLabels: Record<PosterStatus, string> = {
  PENDING: 'Chờ duyệt',
  APPROVED: 'Đã duyệt',
  REJECTED: 'Đã từ chối',
  STOPPED: 'Đã dừng',
};
const stateLabels: Record<string, { label: string; color: string }> = {
  PENDING: { label: 'Chờ duyệt', color: 'gold' },
  SCHEDULED: { label: 'Đã lên lịch', color: 'blue' },
  RUNNING: { label: 'Đang chạy', color: 'green' },
  ENDED: { label: 'Đã kết thúc', color: 'default' },
  REJECTED: { label: 'Đã từ chối', color: 'red' },
  STOPPED: { label: 'Đã dừng', color: 'default' },
};
/** Khớp REJECT_REASONS ở backend (poster.rules.ts) */
const rejectReasons: Record<string, string> = {
  WRONG_SIZE: 'Sai kích thước ảnh (cần 2:1, 1200×600)',
  MISLEADING_PRICE: 'Giá hoặc ưu đãi gây hiểu lầm',
  BRAND_MISUSE: 'Dùng logo, thương hiệu không thuộc shop',
  PROHIBITED: 'Nội dung bị cấm',
  TOO_MUCH_TEXT: 'Quá nhiều chữ trên ảnh',
  OTHER: 'Lý do khác (ghi rõ)',
};
const tierLabels: Record<string, string> = { PRO: 'Cửa hàng Pro', BASIC: 'Bán chuyên', PERSONAL: 'Cá nhân' };

const dateText = (value: string | null) => (value ? new Date(value).toLocaleDateString('vi-VN') : '—');

/** Ảnh poster / shop: file tải lên (/api/v1/media/posters|shops/...) tải qua session; ảnh mẫu trong app không xem được ở web */
export function PosterImage({ session, path, alt, width = 200 }: { session: Session; path: string; alt: string; width?: number }) {
  const [src, setSrc] = useState<string>(),
    [failed, setFailed] = useState(false);
  useEffect(() => {
    let active = true;
    let blobUrl: string | undefined;
    setFailed(false);
    setSrc(undefined);
    const media = path.match(/^\/api\/v1\/media\/(posters|shops)\/([^/?#]+)$/);
    if (media) {
      (media[1] === 'shops' ? session.shopImage(media[2]) : session.posterImage(media[2]))
        .then((blob) => {
          if (!active) return;
          blobUrl = URL.createObjectURL(blob);
          setSrc(blobUrl);
        })
        .catch(() => {
          if (active) setFailed(true);
        });
    } else if (/^https?:\/\//i.test(path)) setSrc(path);
    else setFailed(true);
    return () => {
      active = false;
      if (blobUrl) URL.revokeObjectURL(blobUrl);
    };
  }, [session, path]);
  if (failed) return <span className="muted">{path.startsWith('assets/') ? 'Ảnh mẫu trong app' : 'Không tải được ảnh'}</span>;
  return src ? <Image width={width} src={src} alt={alt} onError={() => setFailed(true)} /> : <span>Đang tải ảnh…</span>;
}

export function ShopPosters({ session }: { session: Session }) {
  const [status, setStatus] = useState<PosterStatus | 'ALL'>('PENDING');
  const { data, error, reload } = useResource<Overview>(session, '/admin/shop-posters?status=' + status);
  const [busy, setBusy] = useState('');
  const [rejecting, setRejecting] = useState<Poster>();
  const [rejectError, setRejectError] = useState('');
  const [form] = Form.useForm<RejectFields>();
  const reason = Form.useWatch('reason', form);

  async function approve(poster: Poster) {
    if (busy) return;
    setBusy(poster.id);
    try {
      await session.call(`/admin/shop-posters/${encodeURIComponent(poster.id)}/approve`, {});
      message.success('Đã duyệt poster, shop sẽ nhận được thông báo.');
    } catch (err) {
      message.error(errorText(err));
    } finally {
      setBusy('');
      reload();
    }
  }

  async function reject(values: RejectFields) {
    if (!rejecting || busy) return;
    setBusy(rejecting.id);
    setRejectError('');
    try {
      const note = values.note?.trim();
      await session.call(`/admin/shop-posters/${encodeURIComponent(rejecting.id)}/reject`, {
        reason: values.reason,
        ...(note ? { note } : {}),
      });
      message.success('Đã từ chối poster, shop sẽ nhận được lý do.');
      setRejecting(undefined);
      reload();
    } catch (err) {
      setRejectError(errorText(err));
    } finally {
      setBusy('');
    }
  }

  const pending = data?.pendingCount ?? 0;
  return (
    <>
      <Panel
        title="Banner shop"
        detail={
          data
            ? pending
              ? `${pending} poster đang chờ duyệt. Poster chỉ hiện trên trang shop và mục Shop uy tín sau khi được duyệt.`
              : 'Không còn poster nào chờ duyệt.'
            : 'Poster quảng bá do shop gói Cửa hàng gửi lên'
        }
        action={
          <Segmented
            value={status}
            onChange={(value) => setStatus(value as PosterStatus | 'ALL')}
            options={[
              { value: 'PENDING', label: `Chờ duyệt${pending ? ` (${pending})` : ''}` },
              { value: 'APPROVED', label: 'Đã duyệt' },
              { value: 'REJECTED', label: 'Đã từ chối' },
              { value: 'STOPPED', label: 'Đã dừng' },
              { value: 'ALL', label: 'Tất cả' },
            ]}
          />
        }
      >
        {error ? (
          <Failure error={error} reload={reload} />
        ) : (
          <Table<Poster>
            rowKey="id"
            loading={!data}
            dataSource={data?.items}
            pagination={false}
            scroll={{ x: 980 }}
            locale={{ emptyText: status === 'PENDING' ? 'Không có poster nào chờ duyệt.' : 'Chưa có poster.' }}
            columns={[
              {
                title: 'Poster',
                width: 220,
                render: (_, poster) => <PosterImage session={session} path={poster.imageUrl} alt={poster.title} />,
              },
              {
                title: 'Nội dung',
                render: (_, poster) => (
                  <Space orientation="vertical" size={2}>
                    <b>{poster.title}</b>
                    {poster.listing ? (
                      <span>
                        Mở tin: {poster.listing.title}
                        {!poster.listing.available && <Tag color="orange" style={{ marginLeft: 6 }}>Tin không còn hiển thị</Tag>}
                      </span>
                    ) : (
                      <span className="muted">Mở trang shop</span>
                    )}
                    <small className="muted">Gửi lúc {new Date(poster.createdAt).toLocaleString('vi-VN')}</small>
                  </Space>
                ),
              },
              {
                title: 'Shop',
                render: (_, poster) => (
                  <Space orientation="vertical" size={2}>
                    <b>{poster.shop.name}</b>
                    <span>
                      {poster.shop.ownerName} · {poster.shop.ownerEmail}
                    </span>
                    <span>
                      <Tag color={poster.shop.planTier === 'PRO' ? 'purple' : 'default'}>
                        {tierLabels[poster.shop.planTier] ?? poster.shop.planTier}
                      </Tag>
                      {poster.shop.verified ? <Tag color="green">Đã xác minh</Tag> : <Tag color="orange">Chưa xác minh</Tag>}
                    </span>
                  </Space>
                ),
              },
              {
                title: 'Lịch chạy',
                width: 170,
                render: (_, poster) => (
                  <span>
                    {dateText(poster.startsAt)} – {dateText(poster.endsAt)}
                    {poster.days ? <small className="muted"> ({poster.days} ngày)</small> : null}
                  </span>
                ),
              },
              {
                title: 'Trạng thái',
                width: 190,
                render: (_, poster) => {
                  const state = stateLabels[poster.state] ?? { label: statusLabels[poster.status], color: 'default' };
                  return (
                    <Space orientation="vertical" size={2}>
                      <Tag color={state.color}>{state.label}</Tag>
                      {poster.rejectReason && (
                        <small>
                          {rejectReasons[poster.rejectReason] ?? poster.rejectReason}
                          {poster.rejectNote ? `: ${poster.rejectNote}` : ''}
                        </small>
                      )}
                    </Space>
                  );
                },
              },
              {
                title: 'Thao tác',
                width: 190,
                render: (_, poster) =>
                  poster.status === 'PENDING' ? (
                    <Space>
                      <Popconfirm
                        title="Duyệt poster này?"
                        description="Poster sẽ chạy theo lịch shop đã chọn."
                        okText="Duyệt"
                        cancelText="Hủy"
                        onConfirm={() => approve(poster)}
                      >
                        <Button type="primary" loading={busy === poster.id} disabled={!!busy}>
                          Duyệt
                        </Button>
                      </Popconfirm>
                      <Button
                        danger
                        disabled={!!busy}
                        onClick={() => {
                          form.resetFields();
                          setRejectError('');
                          setRejecting(poster);
                        }}
                      >
                        Từ chối
                      </Button>
                    </Space>
                  ) : (
                    <span className="muted">{poster.reviewedAt ? `Xử lý ${dateText(poster.reviewedAt)}` : '—'}</span>
                  ),
              },
            ]}
          />
        )}
      </Panel>
      <Modal
        title={rejecting ? `Từ chối poster “${rejecting.title}”` : 'Từ chối poster'}
        open={!!rejecting}
        okText="Từ chối"
        okButtonProps={{ danger: true, loading: !!busy }}
        cancelText="Hủy"
        onOk={() => form.submit()}
        onCancel={() => setRejecting(undefined)}
        destroyOnHidden
      >
        <Form layout="vertical" form={form} onFinish={reject} disabled={!!busy}>
          <Form.Item name="reason" label="Lý do" rules={[{ required: true, message: 'Chọn lý do từ chối.' }]}>
            <Select options={Object.entries(rejectReasons).map(([value, label]) => ({ value, label }))} />
          </Form.Item>
          <Form.Item
            name="note"
            label="Ghi chú cho shop"
            rules={[
              { required: reason === 'OTHER', whitespace: true, message: 'Hãy ghi rõ lý do.' },
              { max: 300, message: 'Tối đa 300 ký tự.' },
            ]}
          >
            <Input.TextArea rows={3} placeholder={reason === 'OTHER' ? 'Bắt buộc khi chọn lý do khác' : 'Không bắt buộc'} />
          </Form.Item>
          <Alert
            type="info"
            title="Shop bị từ chối 3 lần trong 30 ngày sẽ bị khóa gửi poster 7 ngày."
            className="notice"
          />
          {rejectError && <Alert type="error" title={rejectError} className="notice" />}
        </Form>
      </Modal>
    </>
  );
}
