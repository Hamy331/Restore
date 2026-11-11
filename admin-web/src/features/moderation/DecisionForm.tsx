import { useState } from 'react';
import { Alert, Button, Form, Input, InputNumber, Select } from 'antd';
import { ApiError, errorText } from '../../shared/api/session';

const labels = {
  APPROVE: 'Duyệt đăng',
  REJECT: 'Từ chối',
  REQUEST_CHANGES: 'Yêu cầu chỉnh sửa',
  REMOVE: 'Gỡ tin',
  DISMISS: 'Bác báo cáo',
  KEEP: 'Giữ tin',
  WARN: 'Cảnh cáo',
  SUSPEND: 'Tạm khóa',
  BAN: 'Cấm tài khoản',
};
export type Action = keyof typeof labels;
export type Decision = { action: Action; reason: string; days?: number };
type Props = {
  actions: Action[];
  save: (value: Decision) => Promise<unknown>;
  onSaved: () => void;
  onConflict: () => void;
  busy: boolean;
  setBusy: (busy: boolean) => void;
};
export function DecisionForm({ actions, save, onSaved, onConflict, busy, setBusy }: Props) {
  const [form] = Form.useForm<Decision>();
  const action = Form.useWatch('action', form);
  const [error, setError] = useState(''),
    [conflict, setConflict] = useState(false);
  async function submit(values: Decision) {
    if (busy || conflict || !actions.includes(values.action)) return;
    setError('');
    setBusy(true);
    try {
      await save({
        action: values.action,
        reason: values.reason?.trim() || '',
        ...(values.action === 'SUSPEND' ? { days: values.days } : {}),
      });
      onSaved();
    } catch (err) {
      setError(errorText(err));
      if (err instanceof ApiError && err.status === 409) {
        setConflict(true);
        onConflict();
      }
    } finally {
      setBusy(false);
    }
  }
  if (!actions.length) return null;
  return (
    <Form
      layout="vertical"
      form={form}
      onFinish={submit}
      disabled={busy || conflict}
      initialValues={{ days: 7 }}
    >
      <Form.Item
        name="action"
        label="Quyết định"
        rules={[{ required: true, message: 'Chọn quyết định.' }]}
      >
        <Select
          placeholder="Chọn quyết định"
          options={actions.map((value) => ({ value, label: labels[value] }))}
        />
      </Form.Item>
      {action === 'SUSPEND' && (
        <Form.Item
          name="days"
          label="Số ngày tạm khóa"
          rules={[{ required: true, type: 'integer', min: 1, max: 365 }]}
        >
          <InputNumber min={1} max={365} />
        </Form.Item>
      )}
      <Form.Item
        name="reason"
        label="Lý do"
        dependencies={['action']}
        rules={[
          {
            required: action !== 'APPROVE',
            min: action === 'APPROVE' ? 0 : 5,
            max: 300,
            transform: (v) => v?.trim(),
            message: 'Nhập lý do từ 5 đến 300 ký tự.',
          },
        ]}
      >
        <Input.TextArea maxLength={300} rows={3} />
      </Form.Item>
      {error && (
        <Alert
          type="error"
          title={error}
          description={conflict ? 'Đóng cửa sổ và mở lại bản ghi để xem dữ liệu mới.' : undefined}
        />
      )}
      <Button className="section" type="primary" htmlType="submit" loading={busy}>
        Xác nhận quyết định
      </Button>
    </Form>
  );
}
