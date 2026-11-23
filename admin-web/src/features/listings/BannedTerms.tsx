import { useState } from 'react';
import { Button, Input, Popconfirm, Select, Space, Table, Tag, Typography, message } from 'antd';
import { Session, errorText } from '../../shared/api/session';
import { useResource } from '../../shared/api/useResource';
import { Failure } from '../../shared/ui/Failure';

type Term = { id: string; term: string; code: 'CONTACT' | 'BANNED'; createdAt: string };

const codes = {
  BANNED: { label: 'Hàng cấm', color: 'red' },
  CONTACT: { label: 'Liên hệ ngoài', color: 'orange' },
} as const;

/** Từ admin thêm vào bộ lọc nội dung tin (ngoài luật có sẵn); áp dụng cho tin gửi sau khi thêm */
export function BannedTerms({ session }: { session: Session }) {
  const { data, error, reload } = useResource<Term[]>(session, '/admin/banned-terms');
  const [term, setTerm] = useState(''),
    [code, setCode] = useState<Term['code']>('BANNED'),
    [busy, setBusy] = useState(false);
  const run = async (action: () => Promise<unknown>) => {
    setBusy(true);
    try {
      await action();
      reload();
      return true;
    } catch (err) {
      message.error(errorText(err));
      return false;
    } finally {
      setBusy(false);
    }
  };
  const add = async () => {
    if (term.trim().length < 2) return;
    if (await run(() => session.call('/admin/banned-terms', { term, code }))) setTerm('');
  };
  if (error) return <Failure error={error} reload={reload} />;
  return (
    <>
      <Typography.Paragraph type="secondary">
        Từ thêm ở đây được gắn cờ như luật có sẵn (SĐT, link, hàng cấm): người đăng được cảnh báo, admin thấy cờ.
        Khớp nguyên từ, không phân biệt hoa thường; có dấu và không dấu là hai từ khác nhau.
      </Typography.Paragraph>
      <Space.Compact className="notice" style={{ width: '100%' }}>
        <Select<Term['code']>
          aria-label="Loại từ"
          value={code}
          onChange={setCode}
          style={{ width: 150 }}
          options={Object.entries(codes).map(([value, { label }]) => ({ value, label }))}
        />
        <Input
          aria-label="Từ hoặc cụm từ"
          placeholder="VD: kakaotalk, hàng xách tay lậu"
          maxLength={60}
          value={term}
          onChange={(e) => setTerm(e.target.value)}
          onPressEnter={add}
        />
        <Button type="primary" loading={busy} disabled={term.trim().length < 2} onClick={add}>
          Thêm
        </Button>
      </Space.Compact>
      <Table<Term>
        size="small"
        rowKey="id"
        loading={!data}
        dataSource={data}
        pagination={{ pageSize: 10, hideOnSinglePage: true }}
        locale={{ emptyText: 'Chưa có từ nào được thêm' }}
        columns={[
          { title: 'Từ', dataIndex: 'term' },
          {
            title: 'Loại',
            dataIndex: 'code',
            render: (value: Term['code']) => <Tag color={codes[value].color}>{codes[value].label}</Tag>,
          },
          {
            title: '',
            width: 80,
            render: (_, row) => (
              <Popconfirm
                title={`Bỏ "${row.term}" khỏi bộ lọc?`}
                okText="Bỏ"
                cancelText="Thôi"
                onConfirm={() => run(() => session.delete('/admin/banned-terms/' + encodeURIComponent(row.id)))}
              >
                <Button size="small" danger disabled={busy}>
                  Bỏ
                </Button>
              </Popconfirm>
            ),
          },
        ]}
      />
    </>
  );
}
