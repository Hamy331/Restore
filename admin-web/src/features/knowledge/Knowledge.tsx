import { useState } from 'react';
import { Button, Form, Input, Space, Switch, Table, Tag, Tooltip, message } from 'antd';
import { Session } from '../../shared/api/session';
import { usePage } from '../../shared/api/usePage';
import { useResource } from '../../shared/api/useResource';
import { Failure } from '../../shared/ui/Failure';
import { EditDialog } from '../../shared/ui/EditDialog';

type Fields = { title: string; content: string; active: boolean };
type Doc = Fields & { id: string; syncedAt: string | null; updatedAt: string };
type Editor =
  | { type: 'edit'; row?: Doc }
  | { type: 'index' | 'embed' | 'delete'; row: Doc }
  | { type: 'file' | 'catalog' | 'cleanup' };
type EmbedIndex = {
  status: string;
  model: string | null;
  indexedAt: string | null;
  documentVersion: string | null;
  errorCode: string | null;
} | null;
const ragPath = (id: string) => '/ai/rag/documents/' + encodeURIComponent(id) + '/index';

// Trạng thái embedding AI của một tài liệu; READY nhưng tài liệu đã sửa sau đó thì cần tạo lại
function EmbedStatus({ session, row }: { session: Session; row: Doc }) {
  const { data, error } = useResource<EmbedIndex>(session, ragPath(row.id));
  if (data === undefined && !error) return <span className="muted">Đang tải…</span>;
  const built = data?.indexedAt
    ? `${data.model} · ${new Date(data.indexedAt).toLocaleString('vi-VN')}`
    : undefined;
  const current = !!data?.documentVersion && +new Date(data.documentVersion) === +new Date(row.updatedAt);
  const [color, label, hint] = error
    ? ['default', 'Không rõ', error]
    : !data || data.status === 'IDLE'
      ? ['default', 'Chưa tạo']
      : data.status === 'INDEXING'
        ? ['processing', 'Đang tạo']
        : data.status === 'FAILED'
          ? ['error', 'Lỗi', 'Mã lỗi: ' + (data.errorCode ?? 'không rõ')]
          : current
            ? ['success', 'Sẵn sàng', built]
            : ['warning', 'Cần tạo lại', 'Tài liệu đã sửa sau lần tạo embedding · ' + built];
  return (
    <Tooltip title={hint}>
      <Tag color={color}>{label}</Tag>
    </Tooltip>
  );
}
export function Knowledge({ session }: { session: Session }) {
  const list = usePage<Doc>(session, '/admin/knowledge');
  const [editor, setEditor] = useState<Editor>(),
    [file, setFile] = useState<File>(),
    [embedRun, setEmbedRun] = useState(0);
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
      case 'embed': {
        try {
          const { chunks, cleanupPending } = await session.call<{
            chunks: number;
            cleanupPending: boolean;
          }>(ragPath(editor.row.id), {});
          message.success(
            `Đã tạo embedding ${chunks} đoạn.` + (cleanupPending ? ' Vector cũ sẽ được dọn sau.' : ''),
          );
        } finally {
          setEmbedRun((n) => n + 1); // Lỗi cũng đổi trạng thái (FAILED), nên luôn tải lại cột
        }
        return;
      }
      case 'cleanup': {
        const { deleted, remaining } = await session.call<{ deleted: number; remaining: number }>(
          '/ai/rag/cleanup',
          {},
        );
        message.success(
          `Đã xóa ${deleted} vector cũ.` + (remaining ? ` Còn ${remaining} chờ xóa.` : ''),
        );
        return;
      }
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
    embed: 'Tạo embedding AI',
    cleanup: 'Dọn vector cũ',
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
        <Button onClick={() => setEditor({ type: 'cleanup' })}>Dọn vector cũ</Button>
      </Space>
      {list.error ? (
        <Failure error={list.error} reload={list.reload} />
      ) : (
        <Table<Doc>
          rowKey="id"
          dataSource={list.data?.items}
          loading={!list.data}
          pagination={list.pagination}
          scroll={{ x: 860 }}
          columns={[
            { title: 'Tài liệu', dataIndex: 'title' },
            { title: 'Sử dụng', render: (_, r) => (r.active ? 'Đang bật' : 'Đã tắt') },
            {
              title: 'Lập chỉ mục',
              render: (_, r) =>
                r.syncedAt ? new Date(r.syncedAt).toLocaleString('vi-VN') : 'Chưa lập',
            },
            {
              title: 'Embedding AI',
              render: (_, r) => (
                <EmbedStatus key={r.updatedAt + '/' + embedRun} session={session} row={r} />
              ),
            },
            {
              title: 'Thao tác',
              render: (_, row) => (
                <Space>
                  <Button onClick={() => setEditor({ type: 'edit', row })}>Sửa</Button>
                  <Button onClick={() => setEditor({ type: 'index', row })}>Lập chỉ mục</Button>
                  <Button onClick={() => setEditor({ type: 'embed', row })}>Tạo embedding</Button>
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
          {editor.type === 'embed' && (
            <p>
              Tạo embedding cho “{row?.title}” để trợ lý AI dùng tài liệu khi trả lời. Tài liệu cần
              đang bật và đã lập chỉ mục; tài liệu dài hơn 40 đoạn cần được chia nhỏ. Có thể mất
              đến 2–3 phút.
            </p>
          )}
          {editor.type === 'cleanup' && (
            <p>Xóa khỏi Qdrant các vector của tài liệu đã sửa, đã tắt hoặc đã xóa?</p>
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
