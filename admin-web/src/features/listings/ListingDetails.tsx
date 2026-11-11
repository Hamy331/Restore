import { useEffect, useState } from 'react';
import { Image, Space, Typography } from 'antd';
import { Session } from '../../shared/api/session';
export type Listing = {
  id: string;
  title: string;
  description: string;
  status: string;
  images: string[];
  updatedAt: string;
  owner?: { fullName: string };
  category?: { name: string };
  reviewReason?: string;
};
export const listingStatus: Record<string, string> = {
  DRAFT: 'Bản nháp',
  PENDING: 'Chờ duyệt',
  REJECTED: 'Đã từ chối',
  AVAILABLE: 'Đang hiển thị',
  HIDDEN: 'Đã ẩn',
  RESERVED: 'Đã đặt trước',
  SOLD: 'Đã bán',
  EXCHANGED: 'Đã trao đổi',
};

function ListingPhoto({ session, path, index }: { session: Session; path: string; index: number }) {
  const [src, setSrc] = useState<string>(),
    [failed, setFailed] = useState(false);
  useEffect(() => {
    let active = true;
    let blobUrl: string | undefined;
    setFailed(false);
    setSrc(undefined);
    const media = path.match(/^\/api\/v1\/listings\/media\/([^/?#]+)$/);
    if (media) {
      session
        .listingImage(media[1])
        .then((blob) => {
          if (active) {
            blobUrl = URL.createObjectURL(blob);
            setSrc(blobUrl);
          }
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
  if (failed) return <span>Ảnh {index + 1} không tải được.</span>;
  return src ? (
    <Image
      width={110}
      src={src}
      alt={'Ảnh tin đăng ' + (index + 1)}
      onError={() => setFailed(true)}
    />
  ) : (
    <span>Đang tải ảnh…</span>
  );
}
export function ListingDetails({ item, session }: { item: Listing; session: Session }) {
  return (
    <>
      <Typography.Title level={4}>{item.title}</Typography.Title>
      <p>
        {[item.owner?.fullName, item.category?.name, listingStatus[item.status] ?? item.status]
          .filter(Boolean)
          .join(' · ')}
      </p>
      <Typography.Paragraph style={{ whiteSpace: 'pre-wrap' }}>
        {item.description}
      </Typography.Paragraph>
      {item.reviewReason && <p>Lý do kiểm duyệt trước đó: {item.reviewReason}</p>}
      <Space wrap className="notice">
        <Image.PreviewGroup>
          {item.images.map((path, i) => (
            <ListingPhoto key={path + i} session={session} path={path} index={i} />
          ))}
        </Image.PreviewGroup>
      </Space>
    </>
  );
}
