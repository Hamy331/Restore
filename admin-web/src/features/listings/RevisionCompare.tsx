import type { ReactNode } from 'react';
import { Image, Space, Table, Tag, Typography } from 'antd';
import { Session } from '../../shared/api/session';
import { vnd } from '../commerce/PackageFields';
import { ListingPhoto } from './ListingDetails';
import type { ContentFlag } from './ContentFlags';

/** Nội dung tin có thể sửa (bản đang hiển thị và bản sửa chờ duyệt có cùng các trường này) */
export type ListingContent = {
  title: string;
  description: string;
  price: string;
  originalPrice: string | null;
  isNegotiable: boolean;
  condition: string | null;
  allowSale: boolean;
  allowExchange: boolean;
  exchangeWish: string;
  attributes: Record<string, unknown> | null;
  location: { ward?: { name?: string }; province?: { name?: string }; streetAddress?: string } | null;
  images: string[];
};
export type PendingEdit = ListingContent & {
  status: 'PENDING' | 'REJECTED';
  reviewReason: string | null;
  submittedAt: string;
  updatedAt: string;
  /** Cờ nội dung tự động của bản sửa */
  flags?: ContentFlag[];
  /** Bản sửa bị gắn cờ lúc gửi: người đăng đã được cảnh báo và vẫn gửi */
  flagged?: boolean;
};

export const conditionLabel: Record<string, string> = {
  NEW: 'Mới',
  LIKE_NEW: 'Như mới',
  USED_GOOD: 'Đã dùng – Tốt',
  USED_FAIR: 'Đã dùng – Khá',
  FOR_PARTS: 'Cần sửa chữa',
};

const yesNo = (v: boolean) => (v ? 'Có' : 'Không');
const money = (v: string | null) => (v == null || v === '' ? '—' : vnd(v));
const mode = (c: ListingContent) =>
  [c.allowSale && 'Bán', c.allowExchange && 'Trao đổi'].filter(Boolean).join(' + ') || '—';
const place = (c: ListingContent) =>
  [c.location?.streetAddress, c.location?.ward?.name, c.location?.province?.name].filter(Boolean).join(', ') || '—';
const attributes = (c: ListingContent) =>
  Object.entries(c.attributes ?? {})
    .filter(([, v]) => v != null && v !== '')
    .map(([k, v]) => `${k}: ${Array.isArray(v) ? v.join(', ') : String(v)}`)
    .join('\n') || '—';

/** Các dòng so sánh: nhãn + cách đọc giá trị thành chữ (so sánh trên chuỗi đã đọc) */
const fields: { key: string; label: string; read: (c: ListingContent) => string }[] = [
  { key: 'title', label: 'Tiêu đề', read: (c) => c.title },
  { key: 'description', label: 'Mô tả', read: (c) => c.description },
  { key: 'price', label: 'Giá bán', read: (c) => money(c.price) },
  { key: 'originalPrice', label: 'Giá trước giảm', read: (c) => money(c.originalPrice) },
  { key: 'isNegotiable', label: 'Cho thương lượng', read: (c) => yesNo(c.isNegotiable) },
  { key: 'condition', label: 'Tình trạng', read: (c) => (c.condition ? conditionLabel[c.condition] ?? c.condition : '—') },
  { key: 'mode', label: 'Hình thức', read: mode },
  { key: 'exchangeWish', label: 'Muốn đổi lấy', read: (c) => c.exchangeWish || '—' },
  { key: 'attributes', label: 'Thông số', read: attributes },
  { key: 'location', label: 'Khu vực', read: place },
];

function Photos({ session, images }: { session: Session; images: string[] }) {
  if (!images.length) return <span>Không có ảnh</span>;
  return (
    <Space wrap>
      <Image.PreviewGroup>
        {images.map((path, i) => (
          <ListingPhoto key={path + i} session={session} path={path} index={i} />
        ))}
      </Image.PreviewGroup>
    </Space>
  );
}

type Row = { key: string; label: string; before: ReactNode; after: ReactNode; changed: boolean };

/** Bảng so sánh bản đang hiển thị (current) với bản sửa chờ duyệt (edit); dòng có thay đổi được tô nổi */
export function RevisionCompare({
  session,
  current,
  edit,
}: {
  session: Session;
  current: ListingContent;
  edit: PendingEdit;
}) {
  const rows: Row[] = fields.map(({ key, label, read }) => {
    const before = read(current),
      after = read(edit);
    return {
      key,
      label,
      changed: before !== after,
      before: <span className="value-text">{before}</span>,
      after: <span className="value-text">{after}</span>,
    };
  });
  rows.push({
    key: 'images',
    label: 'Ảnh',
    changed: current.images.join('|') !== edit.images.join('|'),
    before: <Photos session={session} images={current.images} />,
    after: <Photos session={session} images={edit.images} />,
  });
  const changes = rows.filter((r) => r.changed).length;
  return (
    <div className="revision-compare">
      <Typography.Paragraph>
        Người bán gửi bản sửa lúc {new Date(edit.submittedAt).toLocaleString('vi-VN')}. Tin vẫn hiện bản cũ
        cho tới khi bản sửa được duyệt; chuyên mục, thời gian hiển thị, xu đã trả, đẩy tin và Hot sale
        không đổi.{' '}
        <Tag color={changes ? 'orange' : 'default'}>
          {changes ? `${changes} mục thay đổi` : 'Không có mục nào thay đổi'}
        </Tag>
      </Typography.Paragraph>
      <Table<Row>
        size="small"
        rowKey="key"
        pagination={false}
        dataSource={rows}
        scroll={{ x: 640 }}
        rowClassName={(r) => (r.changed ? 'changed-row' : '')}
        columns={[
          {
            title: 'Mục',
            dataIndex: 'label',
            width: 130,
            render: (label: string, r) => (
              <>
                {label}
                {r.changed && (
                  <>
                    <br />
                    <Tag color="orange">Đã sửa</Tag>
                  </>
                )}
              </>
            ),
          },
          { title: 'Đang hiển thị', dataIndex: 'before' },
          { title: 'Bản sửa chờ duyệt', dataIndex: 'after' },
        ]}
      />
    </div>
  );
}
