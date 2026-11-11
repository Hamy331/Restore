import { useState } from 'react';
import { Button, Form, Select, Switch, Table } from 'antd';
import { Session } from '../../shared/api/session';
import { useResource } from '../../shared/api/useResource';
import { EditDialog } from '../../shared/ui/EditDialog';
import { Failure } from '../../shared/ui/Failure';
import { PackageName, PriceField, NumberField, vnd } from './PackageFields';

type Fields = {
  name: string;
  price: string;
  durationDays: number;
  priority: number;
  kind: 'BUMP' | 'FEATURED';
  active: boolean;
};
type Promotion = Fields & { id: string };
const kinds = { BUMP: 'Đẩy tin', FEATURED: 'Tin ưu tiên' };
function PriorityField() {
  const kind = Form.useWatch('kind');
  return kind === 'FEATURED' ? (
    <NumberField name="priority" label="Mức ưu tiên" min={1} max={10} />
  ) : null;
}
export function PromotionPackages({ session }: { session: Session }) {
  const { data, error, reload } = useResource<Promotion[]>(session, '/promotions/packages');
  const [editor, edit] = useState<{ row?: Promotion }>();
  if (error) return <Failure error={error} reload={reload} />;
  function save(v: Fields) {
    const body = { ...v, name: v.name.trim(), priority: v.kind === 'BUMP' ? 0 : v.priority };
    return editor?.row
      ? session.put('/promotions/packages/' + encodeURIComponent(editor.row.id), body)
      : session.call('/promotions/packages', body);
  }
  return (
    <>
      <Button type="primary" className="notice" onClick={() => edit({})}>
        Tạo gói đẩy tin
      </Button>
      <Table<Promotion>
        rowKey="id"
        dataSource={data}
        loading={!data}
        scroll={{ x: 650 }}
        columns={[
          { title: 'Tên gói', dataIndex: 'name' },
          { title: 'Loại', dataIndex: 'kind', render: (k: Fields['kind']) => kinds[k] },
          { title: 'Thời hạn (ngày)', dataIndex: 'durationDays' },
          { title: 'Giá', dataIndex: 'price', render: vnd },
          {
            title: 'Trạng thái',
            dataIndex: 'active',
            render: (a: boolean) => (a ? 'Đang bán' : 'Ngừng bán'),
          },
          { title: '', render: (_, row) => <Button onClick={() => edit({ row })}>Sửa gói</Button> },
        ]}
      />
      {editor && (
        <EditDialog<Fields>
          title={editor.row ? 'Sửa gói đẩy tin' : 'Tạo gói đẩy tin'}
          save={save}
          close={() => edit(undefined)}
          saved={reload}
          initialValues={editor.row ?? { kind: 'BUMP', durationDays: 1, priority: 1, active: true }}
        >
          <PackageName />
          <Form.Item name="kind" label="Loại gói">
            <Select options={Object.entries(kinds).map(([value, label]) => ({ value, label }))} />
          </Form.Item>
          <PriceField name="price" />
          <NumberField name="durationDays" label="Thời hạn (ngày)" min={1} max={30} />
          <PriorityField />
          <Form.Item name="active" label="Đang bán" valuePropName="checked">
            <Switch />
          </Form.Item>
        </EditDialog>
      )}
    </>
  );
}
