import { useRef, useState, type ReactNode } from 'react';
import { Alert, Form, Modal, type FormProps } from 'antd';
import { ApiError, errorText } from '../api/session';

type Props<T> = {
  title: string;
  submitLabel?: string;
  initialValues?: FormProps<T>['initialValues'];
  children: ReactNode;
  save: (values: T) => Promise<unknown>;
  close: () => void;
  saved: () => void;
  onStale?: () => void;
};
export function EditDialog<T>({
  title,
  submitLabel = 'Lưu thay đổi',
  initialValues,
  children,
  save,
  close,
  saved,
  onStale,
}: Props<T>) {
  const [form] = Form.useForm<T>();
  const pending = useRef(false);
  const [stale, setStale] = useState(false);
  const [busy, setBusy] = useState(false),
    [error, setError] = useState('');
  async function submit(values: T) {
    if (pending.current || stale) return;
    pending.current = true;
    setBusy(true);
    setError('');
    try {
      await save(values);
      saved();
      close();
    } catch (err) {
      setError(errorText(err));
      if (onStale && err instanceof ApiError && err.status === 409) {
        setStale(true);
        onStale();
      }
    } finally {
      pending.current = false;
      setBusy(false);
    }
  }
  return (
    <Modal
      open
      title={title}
      okText={submitLabel}
      cancelText="Hủy"
      confirmLoading={busy}
      okButtonProps={{ disabled: stale }}
      cancelButtonProps={{ disabled: busy }}
      maskClosable={false}
      closable={!busy}
      keyboard={!busy}
      onCancel={() => {
        if (!pending.current) close();
      }}
      onOk={() => form.submit()}
    >
      <Form
        form={form}
        layout="vertical"
        initialValues={initialValues}
        disabled={busy}
        onFinish={submit}
      >
        {children}
        {error && (
          <Alert
            type="error"
            title={error}
            description={stale ? 'Đóng cửa sổ và mở lại dữ liệu mới nhất.' : undefined}
          />
        )}
      </Form>
    </Modal>
  );
}
