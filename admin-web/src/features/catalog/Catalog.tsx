import { useState } from 'react';
import { Button, Form, Input, Switch, Table, Tabs } from 'antd';
import { Session } from '../../shared/api/session';
import { useResource } from '../../shared/api/useResource';
import { Failure } from '../../shared/ui/Failure';
import { EditDialog } from '../../shared/ui/EditDialog';

type LocalText = string | { vi?: string; en?: string };
type Category = {
  id: string;
  name: string;
  active: boolean;
  metadata?: { description?: LocalText } | null;
};
type Condition = { condition: string; name: string; active: boolean };
type Editor = { type: 'condition'; item: Condition } | { type: 'category'; item?: Category };
type Fields = { id?: string; name: string; description?: string; active: boolean };
const activeLabel = (active: boolean) => (active ? 'Đang sử dụng' : 'Đã tắt');
function description(row?: Category) {
  const value = row?.metadata?.description;
  return typeof value === 'string' ? value : (value?.vi ?? value?.en ?? '');
}
export function Catalog({ session }: { session: Session }) {
  const { data, error, reload } = useResource<{ categories: Category[]; conditions: Condition[] }>(
    session,
    '/admin/catalog',
  );
  const [editor, setEditor] = useState<Editor>();
  if (error) return <Failure error={error} reload={reload} />;
  function save(values: Fields) {
    const body = { name: values.name.trim(), active: values.active };
    if (editor?.type === 'condition')
      return session.put(
        '/admin/catalog/conditions/' + encodeURIComponent(editor.item.condition),
        body,
      );
    const category = { ...body, description: values.description?.trim() ?? '' };
    if (editor?.item)
      return session.put(
        '/admin/catalog/categories/' + encodeURIComponent(editor.item.id),
        category,
      );
    return session.call('/admin/catalog/categories', { ...category, id: values.id });
  }
  return (
    <>
      <Tabs
        items={[
          {
            key: 'categories',
            label: 'Danh mục',
            children: (
              <>
                <Button
                  type="primary"
                  className="notice"
                  onClick={() => setEditor({ type: 'category' })}
                >
                  Tạo danh mục
                </Button>
                <Table<Category>
                  rowKey="id"
                  loading={!data}
                  dataSource={data?.categories}
                  columns={[
                    { title: 'Tên danh mục', dataIndex: 'name' },
                    { title: 'Mã', dataIndex: 'id' },
                    { title: 'Trạng thái', dataIndex: 'active', render: activeLabel },
                    {
                      title: '',
                      render: (_, item) => (
                        <Button onClick={() => setEditor({ type: 'category', item })}>Sửa</Button>
                      ),
                    },
                  ]}
                />
              </>
            ),
          },
          {
            key: 'conditions',
            label: 'Tình trạng sản phẩm',
            children: (
              <Table<Condition>
                rowKey="condition"
                loading={!data}
                dataSource={data?.conditions}
                columns={[
                  { title: 'Tên tình trạng', dataIndex: 'name' },
                  { title: 'Mã', dataIndex: 'condition' },
                  { title: 'Trạng thái', dataIndex: 'active', render: activeLabel },
                  {
                    title: '',
                    render: (_, item) => (
                      <Button onClick={() => setEditor({ type: 'condition', item })}>Sửa</Button>
                    ),
                  },
                ]}
              />
            ),
          },
        ]}
      />
      {editor && (
        <EditDialog<Fields>
          title={
            editor.type === 'condition'
              ? 'Sửa tình trạng'
              : editor.item
                ? 'Sửa danh mục'
                : 'Tạo danh mục'
          }
          close={() => setEditor(undefined)}
          saved={reload}
          save={save}
          initialValues={{
            name: editor.item?.name,
            active: editor.item?.active ?? true,
            description: editor.type === 'category' ? description(editor.item) : undefined,
          }}
        >
          {!editor.item && (
            <Form.Item
              name="id"
              label="Mã danh mục"
              rules={[
                {
                  required: true,
                  pattern: /^[a-z0-9-]{2,80}$/,
                  message: 'Dùng 2–80 chữ thường, số hoặc dấu gạch ngang.',
                },
              ]}
            >
              <Input />
            </Form.Item>
          )}
          <Form.Item
            name="name"
            label="Tên hiển thị"
            rules={[{ required: true, min: 2, max: 100, transform: (v) => v?.trim() }]}
          >
            <Input maxLength={100} />
          </Form.Item>
          {editor.type === 'category' && (
            <Form.Item name="description" label="Mô tả">
              <Input.TextArea maxLength={500} />
            </Form.Item>
          )}
          <Form.Item name="active" label="Đang sử dụng" valuePropName="checked">
            <Switch />
          </Form.Item>
        </EditDialog>
      )}
    </>
  );
}
