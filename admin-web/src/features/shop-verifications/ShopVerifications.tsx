import { useState } from 'react';
import { Alert, Button, Form, Input, Modal, Radio, Segmented, Select, Space, Table, Tag, message } from 'antd';
import { Session, errorText } from '../../shared/api/session';
import { useResource } from '../../shared/api/useResource';
import { Failure } from '../../shared/ui/Failure';
import { Panel } from '../../shared/ui/Panel';
import { PosterImage } from '../shop-posters/ShopPosters';

type Status = 'PENDING' | 'APPROVED' | 'REJECTED';
type VerificationType = 'CERTIFIED' | 'OFFICIAL_BRAND';
type Verification = {
  id: string;
  status: Status;
  businessName: string;
  taxCode: string;
  documentUrls: string[];
  submittedAt: string;
  reviewedAt: string | null;
  rejectNote: string | null;
  shop: {
    id: string;
    name: string;
    logoUrl: string | null;
    address: string | null;
    status: Status;
    verificationType: VerificationType | null;
    certificateCode: string | null;
    owner: { id: string; email: string; fullName: string; phone: string | null; status: string };
  };
};
type Overview = { pendingCount: number; items: Verification[] };

const statusTags: Record<Status, { label: string; color: string }> = {
  PENDING: { label: 'Chờ duyệt', color: 'gold' },
  APPROVED: { label: 'Đã xác minh', color: 'green' },
  REJECTED: { label: 'Đã từ chối', color: 'red' },
};
const typeLabels: Record<VerificationType, string> = { CERTIFIED: 'Shop uy tín', OFFICIAL_BRAND: 'Thương hiệu chính hãng' };
const presetReasons = [
  'Ảnh giấy phép kinh doanh bị mờ, mất góc hoặc không đọc được.',
  'Tên doanh nghiệp / hộ kinh doanh không khớp với giấy phép.',
  'Mã số thuế không khớp với giấy phép hoặc doanh nghiệp đã ngừng hoạt động.',
  'Ngành nghề trên giấy phép không phù hợp với mặt hàng shop đang bán.',
];

const dateText = (value: string | null) => (value ? new Date(value).toLocaleString('vi-VN') : '—');

export function ShopVerifications({ session }: { session: Session }) {
  const [status, setStatus] = useState<Status | 'ALL'>('PENDING');
  const { data, error, reload } = useResource<Overview>(session, '/admin/shop-verifications?status=' + status);
  const [busy, setBusy] = useState('');
  const [approving, setApproving] = useState<Verification>();
  const [rejecting, setRejecting] = useState<Verification>();
  const [dialogError, setDialogError] = useState('');
  const [approveForm] = Form.useForm<{ type: VerificationType }>();
  const [rejectForm] = Form.useForm<{ note: string }>();

  async function decide(item: Verification, action: 'approve' | 'reject', body: object, done: string) {
    if (busy) return;
    setBusy(item.id);
    setDialogError('');
    try {
      await session.call(`/admin/shop-verifications/${encodeURIComponent(item.id)}/${action}`, body);
      message.success(done);
      setApproving(undefined);
      setRejecting(undefined);
      reload();
    } catch (err) {
      setDialogError(errorText(err));
    } finally {
      setBusy('');
    }
  }

  const open = (item: Verification, which: 'approve' | 'reject') => {
    setDialogError('');
    if (which === 'approve') {
      approveForm.setFieldsValue({ type: 'CERTIFIED' });
      setApproving(item);
    } else {
      rejectForm.resetFields();
      setRejecting(item);
    }
  };

  const pending = data?.pendingCount ?? 0;
  return (
    <>
      <Panel
        title="Xác minh cửa hàng"
        detail={
          data
            ? pending
              ? `${pending} hồ sơ đang chờ. Đối chiếu tên và mã số thuế với ảnh giấy phép kinh doanh trước khi duyệt.`
              : 'Không còn hồ sơ nào chờ duyệt.'
            : 'Hồ sơ giấy phép kinh doanh của shop gói Cửa hàng'
        }
        action={
          <Segmented
            value={status}
            onChange={(value) => setStatus(value as Status | 'ALL')}
            options={[
              { value: 'PENDING', label: `Chờ duyệt${pending ? ` (${pending})` : ''}` },
              { value: 'APPROVED', label: 'Đã xác minh' },
              { value: 'REJECTED', label: 'Đã từ chối' },
              { value: 'ALL', label: 'Tất cả' },
            ]}
          />
        }
      >
        {error ? (
          <Failure error={error} reload={reload} />
        ) : (
          <Table<Verification>
            rowKey="id"
            loading={!data}
            dataSource={data?.items}
            pagination={false}
            scroll={{ x: 1100 }}
            locale={{ emptyText: status === 'PENDING' ? 'Không có hồ sơ nào chờ duyệt.' : 'Chưa có hồ sơ.' }}
            columns={[
              {
                title: 'Giấy phép kinh doanh',
                width: 280,
                render: (_, item) => (
                  <Space wrap size={6}>
                    {item.documentUrls.map((url, index) => (
                      <PosterImage key={url} session={session} path={url} alt={`Giấy tờ ${index + 1}`} width={120} />
                    ))}
                  </Space>
                ),
              },
              {
                title: 'Thông tin trên giấy phép',
                render: (_, item) => (
                  <Space orientation="vertical" size={2}>
                    <b>{item.businessName}</b>
                    <span>Mã số thuế: {item.taxCode}</span>
                  </Space>
                ),
              },
              {
                title: 'Shop / chủ shop',
                width: 240,
                render: (_, item) => (
                  <Space orientation="vertical" size={2}>
                    <b>{item.shop.name}</b>
                    {item.shop.address && <small className="muted">{item.shop.address}</small>}
                    <span>{item.shop.owner.fullName}</span>
                    <small>{item.shop.owner.email}{item.shop.owner.phone ? ` · ${item.shop.owner.phone}` : ''}</small>
                    {item.shop.owner.status !== 'ACTIVE' && <Tag color="red">Tài khoản {item.shop.owner.status}</Tag>}
                  </Space>
                ),
              },
              {
                title: 'Trạng thái',
                width: 220,
                render: (_, item) => (
                  <Space orientation="vertical" size={2}>
                    <Tag color={statusTags[item.status].color}>{statusTags[item.status].label}</Tag>
                    {item.status === 'APPROVED' && item.shop.verificationType && (
                      <small>
                        {typeLabels[item.shop.verificationType]}
                        {item.shop.certificateCode ? ` · ${item.shop.certificateCode}` : ''}
                      </small>
                    )}
                    <small className="muted">Gửi lúc {dateText(item.submittedAt)}</small>
                    {item.rejectNote && <small>{item.rejectNote}</small>}
                  </Space>
                ),
              },
              {
                title: 'Thao tác',
                width: 190,
                render: (_, item) =>
                  item.status === 'PENDING' ? (
                    <Space>
                      <Button type="primary" disabled={!!busy} onClick={() => open(item, 'approve')}>
                        Xác minh
                      </Button>
                      <Button danger disabled={!!busy} onClick={() => open(item, 'reject')}>
                        Từ chối
                      </Button>
                    </Space>
                  ) : (
                    <span className="muted">{item.reviewedAt ? `Xử lý ${dateText(item.reviewedAt)}` : '—'}</span>
                  ),
              },
            ]}
          />
        )}
      </Panel>
      <Modal
        title={approving ? `Xác minh shop “${approving.shop.name}”` : 'Xác minh shop'}
        open={!!approving}
        okText="Xác minh"
        okButtonProps={{ loading: !!busy }}
        cancelText="Hủy"
        onOk={() => approveForm.submit()}
        onCancel={() => setApproving(undefined)}
        destroyOnHidden
      >
        <Form
          layout="vertical"
          form={approveForm}
          disabled={!!busy}
          onFinish={({ type }) => approving && decide(approving, 'approve', { type }, 'Đã xác minh shop, chủ shop sẽ nhận được thông báo.')}
        >
          <Form.Item name="type" label="Nhãn xác minh">
            <Radio.Group
              options={[
                { value: 'CERTIFIED', label: 'Shop uy tín: đã đối chiếu giấy phép kinh doanh' },
                { value: 'OFFICIAL_BRAND', label: 'Thương hiệu chính hãng: chủ thương hiệu hoặc nhà phân phối chính thức' },
              ]}
            />
          </Form.Item>
          <Alert type="info" title="Shop nhận nhãn và mã chứng nhận, hiện ở mục Shop uy tín. Tên shop vẫn bị khoá." className="notice" />
          {dialogError && <Alert type="error" title={dialogError} className="notice" />}
        </Form>
      </Modal>
      <Modal
        title={rejecting ? `Từ chối hồ sơ của “${rejecting.shop.name}”` : 'Từ chối hồ sơ'}
        open={!!rejecting}
        okText="Từ chối"
        okButtonProps={{ danger: true, loading: !!busy }}
        cancelText="Hủy"
        onOk={() => rejectForm.submit()}
        onCancel={() => setRejecting(undefined)}
        destroyOnHidden
      >
        <Form
          layout="vertical"
          form={rejectForm}
          disabled={!!busy}
          onFinish={({ note }) => rejecting && decide(rejecting, 'reject', { note: note.trim() }, 'Đã từ chối hồ sơ, chủ shop sẽ nhận được lý do.')}
        >
          <Form.Item label="Lý do mẫu">
            <Select
              placeholder="Chọn để điền nhanh"
              options={presetReasons.map((value) => ({ value, label: value }))}
              onChange={(value: string) => rejectForm.setFieldValue('note', value)}
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
          <Alert type="info" title="Chủ shop bổ sung giấy tờ rồi gửi lại hồ sơ mới." className="notice" />
          {dialogError && <Alert type="error" title={dialogError} className="notice" />}
        </Form>
      </Modal>
    </>
  );
}
