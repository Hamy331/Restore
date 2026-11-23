import { Alert, Space, Tag } from 'antd';
import { vnd } from '../commerce/PackageFields';

/** Cờ nội dung tự động của tin (backend quét tiêu đề và mô tả); chỉ để admin duyệt kỹ hơn */
export type ContentFlag = { code: 'CONTACT' | 'LINK' | 'BANNED'; match: string };

const labels: Record<ContentFlag['code'], { label: string; color: string; detail: string }> = {
  CONTACT: { label: 'Có SĐT / liên hệ ngoài', color: 'orange', detail: 'Số điện thoại hoặc rủ liên hệ ngoài ứng dụng' },
  LINK: { label: 'Có đường link', color: 'orange', detail: 'Đường dẫn web hoặc tên miền' },
  BANNED: { label: 'Nghi hàng cấm', color: 'red', detail: 'Từ ngữ về hàng cấm hoặc hàng giả' },
};

/** Giá bất thường (backend tính): dưới 10.000đ, hoặc dưới 1/10 giá thường gặp của chuyên mục */
export type PriceWarning = { reason: 'TOO_LOW' } | { reason: 'BELOW_TYPICAL'; typical: string };

const priceText = (warning: PriceWarning) =>
  warning.reason === 'TOO_LOW'
    ? 'Giá dưới 10.000đ, dễ là giá ảo để câu khách'
    : `Giá thấp hơn nhiều so với giá thường gặp của chuyên mục (khoảng ${vnd(warning.typical)})`;

const IGNORED = 'Người đăng đã được cảnh báo nhưng vẫn gửi';

/**
 * Thẻ cờ cho bảng; trùng loại (tin và bản sửa cùng bị gắn) chỉ hiện một thẻ.
 * ignored: người đăng đã được cảnh báo lúc gửi mà vẫn gửi (cột flagged của tin / bản sửa)
 */
export function FlagTags({
  flags,
  ignored,
  price,
}: {
  flags: (ContentFlag[] | undefined)[];
  ignored?: boolean;
  price?: PriceWarning | null;
}) {
  const codes = [...new Set(flags.flatMap((list) => list ?? []).map((flag) => flag.code))];
  if (!codes.length && !ignored && !price) return null;
  return (
    <Space size={4} wrap>
      {price && (
        <Tag color="gold" title={priceText(price)}>
          Giá bất thường
        </Tag>
      )}
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
  price,
  title = 'Tin bị gắn cờ tự động',
}: {
  flags?: ContentFlag[];
  ignored?: boolean;
  price?: PriceWarning | null;
  title?: string;
}) {
  if (!flags?.length && !ignored && !price) return null;
  return (
    <Alert
      type="warning"
      className="notice"
      title={title}
      description={
        <ul style={{ margin: 0, paddingInlineStart: 18 }}>
          {ignored && <li>{IGNORED}.</li>}
          {price && <li>{priceText(price)}.</li>}
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
