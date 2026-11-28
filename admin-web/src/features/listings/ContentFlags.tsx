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

/**
 * AI xem ảnh và nội dung lúc chờ duyệt (khi backend bật AI): SUSPECT = nghi hàng cấm, kèm lý do.
 * Chỉ để tham khảo, AI có thể nhầm. null: chưa xem hoặc nội dung vừa đổi, đang chờ xem lại.
 */
export type AiReview = { verdict: 'OK' | 'SUSPECT' | 'UNKNOWN'; reason: string; checkedAt: string };

const aiText = (review: AiReview) => `AI xem ảnh nghi là hàng cấm: ${review.reason || 'không nêu lý do'} (AI có thể nhầm)`;

const IGNORED = 'Người đăng đã được cảnh báo nhưng vẫn gửi';

/**
 * Thẻ cờ cho bảng; trùng loại (tin và bản sửa cùng bị gắn) chỉ hiện một thẻ.
 * ignored: người đăng đã được cảnh báo lúc gửi mà vẫn gửi (cột flagged của tin / bản sửa)
 */
export function FlagTags({
  flags,
  ignored,
  price,
  ai,
}: {
  flags: (ContentFlag[] | undefined)[];
  ignored?: boolean;
  price?: PriceWarning | null;
  ai?: AiReview | null;
}) {
  const codes = [...new Set(flags.flatMap((list) => list ?? []).map((flag) => flag.code))];
  const suspect = ai?.verdict === 'SUSPECT';
  if (!codes.length && !ignored && !price && !suspect) return null;
  return (
    <Space size={4} wrap>
      {suspect && (
        <Tag color="magenta" title={aiText(ai)}>
          AI nghi hàng cấm
        </Tag>
      )}
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
  ai,
  title = 'Tin bị gắn cờ tự động',
}: {
  flags?: ContentFlag[];
  ignored?: boolean;
  price?: PriceWarning | null;
  ai?: AiReview | null;
  title?: string;
}) {
  const suspect = ai?.verdict === 'SUSPECT';
  if (!flags?.length && !ignored && !price && !suspect) return null;
  return (
    <Alert
      type="warning"
      className="notice"
      title={title}
      description={
        <ul style={{ margin: 0, paddingInlineStart: 18 }}>
          {suspect && <li>{aiText(ai)}.</li>}
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
