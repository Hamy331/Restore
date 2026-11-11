import { Form, Input, InputNumber } from 'antd';

export const vnd = (amount: string | number) =>
  new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(Number(amount));
export function PackageName() {
  return (
    <Form.Item
      name="name"
      label="Tên gói"
      rules={[{ required: true, min: 3, max: 80, transform: (v) => v?.trim() }]}
    >
      <Input maxLength={80} />
    </Form.Item>
  );
}
export function PriceField({
  name,
  disabled = false,
  free = false,
}: {
  name: string;
  disabled?: boolean;
  free?: boolean;
}) {
  return (
    <Form.Item
      name={name}
      label="Giá (đồng)"
      rules={[
        {
          required: true,
          pattern: free ? /^(0|[1-9]\d{0,11})$/ : /^[1-9]\d{0,11}$/,
          message: 'Nhập giá nguyên bằng đồng, tối đa 12 chữ số.',
        },
      ]}
    >
      <Input inputMode="numeric" maxLength={12} disabled={disabled} />
    </Form.Item>
  );
}
export function NumberField({
  name,
  label,
  min,
  max,
  disabled = false,
}: {
  name: string;
  label: string;
  min: number;
  max: number;
  disabled?: boolean;
}) {
  return (
    <Form.Item
      name={name}
      label={label}
      rules={[
        {
          required: true,
          type: 'integer',
          min,
          max,
          message: 'Nhập số nguyên từ ' + min + ' đến ' + max + '.',
        },
      ]}
    >
      <InputNumber min={min} max={max} disabled={disabled} />
    </Form.Item>
  );
}
