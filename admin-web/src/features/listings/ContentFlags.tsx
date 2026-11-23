import { Alert, Space, Tag } from 'antd';

/** Cờ nội dung tự động của tin (backend quét tiêu đề và mô tả); chỉ để admin duyệt kỹ hơn */
export type ContentFlag = { code: 'CONTACT' | 'LINK' | 'BANNED'; match: string };

const labels: Record<ContentFlag['code'], { label: string; color: string; detail: string }> = {
  CONTACT: { label: 'Có SĐT / liên hệ ngoài', color: 'orange', detail: 'Số điện thoại hoặc rủ liên hệ ngoài ứng dụng' },
  LINK: { label: 'Có đường link', color: 'orange', detail: 'Đường dẫn web hoặc tên miền' },
  BANNED: { label: 'Nghi hàng cấm', color: 'red', detail: 'Từ ngữ về hàng cấm hoặc hàng giả' },
};

const IGNORED = 'Người đăng đã được cảnh báo nhưng vẫn gửi';

/**
 * Thẻ cờ cho bảng; trùng loại (tin và bản sửa cùng bị gắn) chỉ hiện một thẻ.
 * ignored: người đăng đã được cảnh báo lúc gửi mà vẫn gửi (cột flagged của tin / bản sửa)
 */
export function FlagTags({ flags, ignored }: { flags: (ContentFlag[] | undefined)[]; ignored?: boolean }) {
  const codes = [...new Set(flags.flatMap((list) => list ?? []).map((flag) => flag.code))];
  if (!codes.length && !ignored) return null;
  return (
    <Space size={4} wrap>
      {ignored && (
        <Tag color="volcano" title={IGNORED}>
          Bỏ qua cảnh báo
        </Tag>
      )}
      {codes.map((code) => (
        <Tag key={code} color={labels[code].color}>
          {labels[code].label}
        </Tag>
      ))}
    </Space>
  );
}

/** Giải thích trong chi tiết tin: loại cờ và đoạn bị khớp */
export function FlagNotice({
  flags,
  ignored,
  title = 'Tin bị gắn cờ tự động',
}: {
  flags?: ContentFlag[];
  ignored?: boolean;
  title?: string;
}) {
  if (!flags?.length && !ignored) return null;
  return (
    <Alert
      type="warning"
      className="notice"
      title={title}
      description={
        <ul style={{ margin: 0, paddingInlineStart: 18 }}>
          {ignored && <li>{IGNORED}.</li>}
          {flags?.map((flag) => (
            <li key={flag.code}>
              {labels[flag.code].detail}: <strong>“{flag.match}”</strong>
            </li>
          ))}
        </ul>
      }
    />
  );
}
