import { useState } from 'react';
import { Button, Form, Input, Modal } from 'antd';
import { EditOutlined, ExportOutlined, ShopOutlined } from '@ant-design/icons';

const key = 'restore.admin.marketplace';
function webAddress(value: string) {
  try {
    const url = new URL(value);
    return ['http:', 'https:'].includes(url.protocol) ? url.href : '';
  } catch {
    return '';
  }
}
export function MarketplaceLink() {
  const [address, setAddress] = useState(() =>
    webAddress(localStorage.getItem(key) || import.meta.env.VITE_MARKETPLACE_URL || ''),
  );
  const [editing, setEditing] = useState(false);
  const label = (
    <>
      <ShopOutlined />
      <span>
        <b>Trang mua bán</b>
        <small>Giao diện người dùng</small>
      </span>
      <ExportOutlined />
    </>
  );
  return (
    <div className="market-footer">
      {address ? (
        <>
          <a className="market-link" href={address} target="_blank" rel="noreferrer">
            {label}
          </a>
          <Button
            type="text"
            aria-label="Đổi địa chỉ trang mua bán"
            icon={<EditOutlined />}
            onClick={() => setEditing(true)}
          />
        </>
      ) : (
        <button type="button" className="market-link" onClick={() => setEditing(true)}>
          {label}
        </button>
      )}
      {editing && (
        <Modal open title="Địa chỉ trang mua bán" onCancel={() => setEditing(false)} footer={null}>
          <Form
            layout="vertical"
            initialValues={{ url: address }}
            onFinish={({ url }) => {
              const next = webAddress(url.trim());
              localStorage.setItem(key, next);
              setAddress(next);
              setEditing(false);
            }}
          >
            <Form.Item
              name="url"
              label="Địa chỉ web ReStore đang chạy"
              rules={[
                {
                  validator: (_, v) =>
                    webAddress(v || '')
                      ? Promise.resolve()
                      : Promise.reject(
                          new Error('Nhập địa chỉ đầy đủ bắt đầu bằng http hoặc https.'),
                        ),
                },
              ]}
            >
              <Input type="url" placeholder="http://localhost:5200" autoComplete="url" />
            </Form.Item>
            <Button type="primary" htmlType="submit">
              Lưu địa chỉ
            </Button>
          </Form>
        </Modal>
      )}
    </div>
  );
}
