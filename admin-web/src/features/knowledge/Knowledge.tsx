import { useState } from 'react';
import { Button, Form, Input, Space, Switch, Table } from 'antd';
import { Session } from '../../shared/api/session';
import { usePage } from '../../shared/api/usePage';
import { Failure } from '../../shared/ui/Failure';
import { EditDialog } from '../../shared/ui/EditDialog';

type Fields = { title: string; content: string; active: boolean };
type Doc = Fields & { id: string; syncedAt: string | null; updatedAt: string };
type Editor =
  | { type: 'edit'; row?: Doc }
  | { type: 'index' | 'delete'; row: Doc }
  | { type: 'file' | 'catalog' };
export function Knowledge({ session }: { session: Session }) {
  const list = usePage<Doc>(session, '/admin/knowledge');
  const [editor, setEditor] = useState<Editor>(),
    [file, setFile] = useState<File>();
  const close = () => {
    setEditor(undefined);
    setFile(undefined);
  };
  const row = editor && 'row' in editor ? editor.row : undefined;
  async function save(v: Fields) {
    if (!editor) return;
    const path = '/admin/knowledge' + (row ? '/' + encodeURIComponent(row.id) : '');
    switch (editor.type) {
      case 'catalog':
        return session.call('/admin/knowledge/catalog-sync', {});
      case 'index':
        return session.call(path + '/sync', { updatedAt: editor.row.updatedAt });
      case 'delete':
        return session.remove(path, editor.row.updatedAt);
      case 'file': {
        if (!file || !/\.(md|txt)$/i.test(file.name) || file.size > 100 * 1024)
          throw Error('Chọn tệp TXT hoặc Markdown tối đa 100 KB.');
        let content: string;
        try {
          content = new TextDecoder('utf-8', { fatal: true }).decode(await file.arrayBuffer());
        } catch {
          throw Error('Tệp cần được lưu dưới dạng UTF-8.');
        }
        return session.upload(
          '/content/knowledge/upload?' + new URLSearchParams({ title: v.title.trim() }),
          new Blob([content]),
          'text/plain',
        );
      }
      case 'edit': {
        const body = { title: v.title.trim(), content: v.content.trim(), active: v.active };
        return row
          ? session.put(path, { ...body, updatedAt: row.updatedAt })
          : session.call(path, body);
      }
    }
  }
  const titles = {
    edit: row ? 'Sửa tài liệu' : 'Tạo tài liệu',
    file: 'Nhập từ tệp',
    index: 'Lập chỉ mục',
    delete: 'Xóa tài liệu',
    catalog: 'Đồng bộ danh mục',
  };
  return (
    <>
      <Space wrap className="notice">
        <Button type="primary" onClick={() => setEditor({ type: 'edit' })}>
          Tạo tài liệu
        </Button>
        <Button onClick={() => setEditor({ type: 'file' })}>Nhập từ tệp</Button>
        <Button onClick={() => setEditor({ type: 'catalog' })}>Đồng bộ danh mục</Button>
      </Space>
      {list.error ? (
        <Failure error={list.error} reload={list.reload} />
      ) : (
        <Table<Doc>
          rowKey="id"
          dataSource={list.data?.items}
          loading={!list.data}
          pagination={list.pagination}
          scroll={{ x: 650 }}
          columns={[
            { title: 'Tài liệu', dataIndex: 'title' },
            { title: 'Sử dụng', render: (_, r) => (r.active ? 'Đang bật' : 'Đã tắt') },
            {
              title: 'Lập chỉ mục',
              render: (_, r) =>
                r.syncedAt ? new Date(r.syncedAt).toLocaleString('vi-VN') : 'Chưa lập',
            },
            {
              title: 'Thao tác',
              render: (_, row) => (
                <Space>
                  <Button onClick={() => setEditor({ type: 'edit', row })}>Sửa</Button>
                  <Button onClick={() => setEditor({ type: 'index', row })}>Lập chỉ mục</Button>
                  <Button danger onClick={() => setEditor({ type: 'delete', row })}>
                    Xóa
                  </Button>
                </Space>
              ),
            },
          ]}
        />
      )}
      {editor && (
        <EditDialog<Fields>
          title={titles[editor.type]}
          submitLabel={editor.type === 'edit' ? 'Lưu tài liệu' : titles[editor.type]}
          close={close}
          saved={editor.type === 'delete' ? list.refresh : list.reload}
          onStale={list.reload}
          initialValues={row ?? { active: true }}
          save={save}
        >
          {(editor.type === 'edit' || editor.type === 'file') && (
            <Form.Item
              name="title"
              label="Tên tài liệu"
              rules={[{ required: true, min: 3, max: 160 }]}
            >
              <Input maxLength={160} />
            </Form.Item>
          )}
          {editor.type === 'file' && (
            <label>
              Tệp TXT hoặc Markdown (UTF-8)
              <input type="file" accept=".md,.txt" onChange={(e) => setFile(e.target.files?.[0])} />
            </label>
          )}
          {editor.type === 'edit' && (
            <>
              <Form.Item
                name="content"
                label="Nội dung"
                rules={[{ required: true, min: 10, max: 100000 }]}
              >
                <Input.TextArea rows={8} />
              </Form.Item>
              <Form.Item name="active" label="Đang sử dụng" valuePropName="checked">
                <Switch />
              </Form.Item>
            </>
          )}
          {editor.type === 'index' && (
            <p>Lập chỉ mục để có thể tìm kiếm tài liệu “{row?.title}”.</p>
          )}
          {editor.type === 'delete' && (
            <p>Xóa “{row?.title}” cùng chỉ mục tìm kiếm của tài liệu?</p>
          )}
          {editor.type === 'catalog' && (
            <p>Cập nhật tài liệu hệ thống từ các danh mục đang sử dụng và lập lại chỉ mục?</p>
          )}
        </EditDialog>
      )}
    </>
  );
}
