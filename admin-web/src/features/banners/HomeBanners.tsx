import { useRef, useState } from 'react';
import { Alert, Button, Form, Input, InputNumber, Popconfirm, Space, Switch, Table, Tag, message } from 'antd';
import { PlusOutlined } from '@ant-design/icons';
import { Session, errorText } from '../../shared/api/session';
import { useResource } from '../../shared/api/useResource';
import { Failure } from '../../shared/ui/Failure';
import { Panel } from '../../shared/ui/Panel';
import { EditDialog } from '../../shared/ui/EditDialog';
import { History } from '../audit/History';

type Banner = {
  id: string;
  title: string;
  imageUrl: string | null;
  route: string | null;
  sortOrder: number;
  active: boolean;
  startsAt: string | null;
  endsAt: string | null;
  updatedAt: string;
};
type Fields = Omit<Banner, 'id' | 'updatedAt'> & { reason?: string };

function localInput(value: string | null) {
  if (!value) return '';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return '';
  const pad = (part: number) => String(part).padStart(2, '0');
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}`;
}

function isoValue(value: string | null | undefined) {
  if (!value) return null;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) throw new Error('Thời gian banner không hợp lệ.');
  return date.toISOString();
}

export function HomeBanners({ session }: { session: Session }) {
  const { data, error, reload } = useResource<Banner[]>(session, '/home/admin/banners');
  const [row, edit] = useState<Banner>();
  const [creating, setCreating] = useState(false);
  const [deleting, setDeleting] = useState('');
  const [file, setFile] = useState<File>();
  const cachedUpload = useRef<{ file: File; url: string } | undefined>(undefined);

  async function remove(banner: Banner) {
    if (deleting) return;
    setDeleting(banner.id);
    try {
      await session.delete('/home/admin/banners/' + encodeURIComponent(banner.id));
      reload();
    } catch (err) {
      message.error(errorText(err));
    } finally {
      setDeleting('');
    }
  }

  async function save(values: Fields) {
    let imageUrl = values.imageUrl?.trim() || null;
    if (file) {
      if (!['image/jpeg', 'image/png', 'image/webp'].includes(file.type) || file.size > 5 * 1024 * 1024) {
        throw new Error('Chọn ảnh JPEG, PNG hoặc WebP tối đa 5 MB.');
      }
      if (cachedUpload.current?.file !== file) {
        const uploaded = await session.upload<{ url: string }>('/content/media', file, file.type);
        cachedUpload.current = { file, url: uploaded.url };
      }
      imageUrl = cachedUpload.current.url;
    }
    const body = {
      title: values.title.trim(),
      imageUrl,
      route: values.route?.trim() || null,
      sortOrder: values.sortOrder,
      active: values.active,
      startsAt: isoValue(values.startsAt),
      endsAt: isoValue(values.endsAt),
      reason: values.reason?.trim() || '',
    };
    return row
      ? session.put('/home/admin/banners/' + encodeURIComponent(row.id), body)
      : session.call('/home/admin/banners', body);
  }

  const initial = row
    ? {
        ...row,
        startsAt: localInput(row.startsAt),
        endsAt: localInput(row.endsAt),
      }
    : { title: '', imageUrl: '', route: '', sortOrder: 0, active: true, startsAt: '', endsAt: '' };

  return (
    <>
      <Panel
        title="Banner trang chủ"
        detail={data ? `${data.length} banner trong hệ thống` : 'Dữ liệu lấy từ cấu hình trang chủ'}
        action={
          <Button type="primary" icon={<PlusOutlined />} onClick={() => setCreating(true)}>
            Tạo banner
          </Button>
        }
      >
        {error ? (
          <Failure error={error} reload={reload} />
        ) : (
          <Table<Banner>
            rowKey="id"
            loading={!data}
            dataSource={data}
            pagination={false}
            scroll={{ x: 780 }}
            locale={{ emptyText: 'Chưa có banner trang chủ.' }}
            columns={[
              { title: 'Tên nội bộ', dataIndex: 'title' },
              { title: 'Thứ tự', dataIndex: 'sortOrder', width: 90 },
              {
                title: 'Trạng thái',
                dataIndex: 'active',
                render: (active: boolean) => <Tag color={active ? 'green' : 'default'}>{active ? 'Đang bật' : 'Đang tắt'}</Tag>,
              },
              {
                title: 'Lịch chạy',
                render: (_, banner) => (
                  <span>
                    {banner.startsAt ? new Date(banner.startsAt).toLocaleString('vi-VN') : 'Không giới hạn'}
                    {banner.endsAt ? ` – ${new Date(banner.endsAt).toLocaleString('vi-VN')}` : ''}
                  </span>
                ),
              },
              { title: 'Đường dẫn', dataIndex: 'route', render: (route: string | null) => route || '—' },
              {
                title: 'Thao tác',
                width: 175,
                render: (_, banner) => (
                  <Space>
                    <Button onClick={() => edit(banner)}>Sửa</Button>
                    <Popconfirm
                      title="Xóa banner này?"
                      description="Thao tác sẽ gỡ banner khỏi trang chủ."
                      okText="Xóa"
                      cancelText="Hủy"
                      onConfirm={() => remove(banner)}
                    >
                      <Button danger loading={deleting === banner.id} disabled={!!deleting}>
                        Xóa
                      </Button>
                    </Popconfirm>
                  </Space>
                ),
              },
            ]}
          />
        )}
      </Panel>
      {(creating || row) && (
        <EditDialog<Fields>
          title={row ? 'Sửa banner' : 'Tạo banner'}
          submitLabel={row ? 'Lưu banner' : 'Tạo banner'}
          initialValues={initial as Fields}
          close={() => {
            setCreating(false);
            edit(undefined);
            setFile(undefined);
          }}
          saved={reload}
          save={save}
        >
          {row?.imageUrl && <p className="muted">Ảnh hiện tại: {row.imageUrl}</p>}
          <Form.Item name="title" label="Tên nội bộ" rules={[{ required: true, max: 120 }]}>
            <Input maxLength={120} />
          </Form.Item>
          <Form.Item name="imageUrl" label="Địa chỉ ảnh" rules={[{ max: 500 }]}>
            <Input maxLength={500} placeholder="https://... hoặc đường dẫn ảnh /..." />
          </Form.Item>
          <label>
            Tải ảnh banner (tỉ lệ khuyến nghị 2:1, tối đa 5 MB){' '}
            <input
              type="file"
              accept="image/png,image/jpeg,image/webp"
              onChange={(event) => setFile(event.target.files?.[0])}
            />
          </label>
          {file && <Alert className="notice" type="info" title={`Ảnh mới: ${file.name}`} />}
          <Form.Item name="route" label="Đường dẫn trong ứng dụng" rules={[{ max: 200 }]}>
            <Input maxLength={200} placeholder="/trusted-shops" />
          </Form.Item>
          <Form.Item name="sortOrder" label="Thứ tự hiển thị" rules={[{ required: true, type: 'number', min: 0, max: 1000 }]}>
            <InputNumber min={0} max={1000} className="full-width" />
          </Form.Item>
          <Form.Item name="active" label="Hiển thị" valuePropName="checked">
            <Switch checkedChildren="Bật" unCheckedChildren="Tắt" />
          </Form.Item>
          <Form.Item name="startsAt" label="Bắt đầu (để trống nếu không giới hạn)">
            <Input type="datetime-local" />
          </Form.Item>
          <Form.Item name="endsAt" label="Kết thúc (để trống nếu không giới hạn)">
            <Input type="datetime-local" />
          </Form.Item>
          <Form.Item name="reason" label="Ghi chú nhật ký (không bắt buộc)" rules={[{ max: 300 }]}>
            <Input.TextArea maxLength={300} rows={2} />
          </Form.Item>
        </EditDialog>
      )}
      <History session={session} type="HOME_BANNER" />
    </>
  );
}
