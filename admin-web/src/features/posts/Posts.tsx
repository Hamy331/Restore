import { FileTextOutlined, PlusOutlined } from '@ant-design/icons';
import { Panel } from '../../shared/ui/Panel';
import { History } from '../audit/History';
import { RecordId } from '../audit/AuditTable';
import { useEffect, useRef, useState } from 'react';
import { Button, Checkbox, Form, Image, Input, Modal, Select, Space, Table } from 'antd';
import { Session } from '../../shared/api/session';
import { Failure } from '../../shared/ui/Failure';
import { usePage } from '../../shared/api/usePage';
import { EditDialog } from '../../shared/ui/EditDialog';

const statuses = {
  DRAFT: 'Bản nháp',
  PUBLISHED: 'Đã xuất bản',
  HIDDEN: 'Đã ẩn',
  ARCHIVED: 'Lưu trữ',
};
type Fields = {
  title: string;
  slug: string;
  category: string;
  content: string;
  listingIds: string[];
  status: keyof typeof statuses;
  removeCover?: boolean;
};
type Post = Fields & {
  author: string | null;
  id: string;
  createdAt: string;
  coverUrl: string | null;
  updatedAt: string;
};
function Cover({ session, url }: { session: Session; url: string }) {
  const [src, setSrc] = useState(''),
    [failed, setFailed] = useState(false);
  useEffect(() => {
    let live = true,
      objectUrl = '';
    session
      .coverImage(url.split('/').pop()!)
      .then((blob) => {
        if (live) {
          objectUrl = URL.createObjectURL(blob);
          setSrc(objectUrl);
        }
      })
      .catch(() => {
        if (live) setFailed(true);
      });
    return () => {
      live = false;
      if (objectUrl) URL.revokeObjectURL(objectUrl);
    };
  }, [session, url]);
  return src ? (
    <Image src={src} width={112} alt="Ảnh bìa hiện tại" />
  ) : failed ? (
    <p>Không tải được ảnh bìa.</p>
  ) : null;
}
function Editor({
  session,
  row,
  close,
  reload,
}: {
  session: Session;
  row?: Post;
  close: () => void;
  reload: () => void;
}) {
  const [file, setFile] = useState<File>();
  const cached = useRef<{ file: File; url: string } | undefined>(undefined);
  async function save(v: Fields) {
    let coverUrl = v.removeCover ? null : (row?.coverUrl ?? null);
    if (file) {
      if (
        !['image/jpeg', 'image/png', 'image/webp'].includes(file.type) ||
        file.size > 5 * 1024 * 1024
      )
        throw Error('Chọn ảnh JPEG, PNG hoặc WebP tối đa 5 MB.');
      if (cached.current?.file !== file) {
        const data = await session.upload<{ url: string }>('/content/media', file, file.type);
        cached.current = { file, url: data.url };
      }
      coverUrl = cached.current.url;
    }
    const body = {
      title: v.title.trim(),
      slug: v.slug.trim(),
      category: v.category.trim(),
      content: v.content.trim(),
      status: v.status,
      listingIds: v.listingIds ?? [],
      coverUrl,
    };
    return row
      ? session.put('/admin/posts/' + encodeURIComponent(row.id), {
          ...body,
          updatedAt: row.updatedAt,
        })
      : session.call('/admin/posts', body);
  }
  return (
    <EditDialog<Fields>
      title={row ? 'Sửa bài viết' : 'Viết bài'}
      initialValues={row ?? { status: 'DRAFT', category: 'Hướng dẫn', listingIds: [] }}
      save={save}
      close={close}
      saved={reload}
      onStale={reload}
    >
      <Form.Item name="title" label="Tiêu đề" rules={[{ required: true, min: 5, max: 160 }]}>
        <Input maxLength={160} />
      </Form.Item>
      <Form.Item
        name="slug"
        label="Đường dẫn (slug)"
        rules={[
          {
            required: true,
            pattern: /^[a-z0-9-]{3,160}$/,
            message: 'Dùng 3–160 chữ thường, số hoặc dấu gạch ngang.',
          },
        ]}
      >
        <Input />
      </Form.Item>
      <Form.Item name="category" label="Chuyên mục" rules={[{ required: true, min: 2, max: 100 }]}>
        <Input />
      </Form.Item>
      <Form.Item name="content" label="Nội dung" rules={[{ required: true, min: 20, max: 50000 }]}>
        <Input.TextArea rows={6} />
      </Form.Item>
      <Form.Item name="listingIds" label="Mã tin liên quan (tối đa 10)">
        <Select mode="tags" maxCount={10} tokenSeparators={[',']} open={false} />
      </Form.Item>
      {row?.coverUrl && (
        <>
          <Cover session={session} url={row.coverUrl} />
          <Form.Item name="removeCover" valuePropName="checked">
            <Checkbox disabled={!!file}>Gỡ ảnh bìa hiện tại</Checkbox>
          </Form.Item>
        </>
      )}
      <label>
        Ảnh bìa{' '}
        <input
          type="file"
          accept="image/png,image/jpeg,image/webp"
          onChange={(e) => setFile(e.target.files?.[0])}
        />
      </label>
      <Form.Item name="status" label="Trạng thái">
        <Select options={Object.entries(statuses).map(([value, label]) => ({ value, label }))} />
      </Form.Item>
    </EditDialog>
  );
}
export function Posts({ session }: { session: Session }) {
  const list = usePage<Post>(session, '/admin/posts?include=author');
  const [preview, setPreview] = useState<Post>();
  const [historyVersion, setHistoryVersion] = useState(0);
  const [edit, setEdit] = useState<{ row?: Post }>();
  return (
    <>
      <Panel
        title="Tất cả bài viết"
        detail={list.data ? list.data.total + ' bài viết' : undefined}
        action={
          <Button icon={<PlusOutlined />} type="primary" onClick={() => setEdit({})}>
            Viết bài
          </Button>
        }
      >
        {list.error ? (
          <Failure error={list.error} reload={list.reload} />
        ) : (
          <Table<Post>
            rowKey="id"
            scroll={{ x: 720 }}
            dataSource={list.data?.items}
            loading={!list.data}
            pagination={list.pagination}
            columns={[
              {
                title: 'Bài viết',
                render: (_, r) => (
                  <div className="person">
                    <span className="metric-icon">
                      <FileTextOutlined />
                    </span>
                    <div className="cell-stack">
                      <b>{r.title}</b>
                      <RecordId value={r.id} />
                    </div>
                  </div>
                ),
              },
              { title: 'Tác giả', render: (_, r) => r.author ?? 'Chưa ghi nhận' },
              { title: 'Tạo lúc', render: (_, r) => new Date(r.createdAt).toLocaleString('vi-VN') },
              { title: 'Chuyên mục', dataIndex: 'category' },
              { title: 'Trạng thái', render: (_, r) => statuses[r.status] },
              {
                title: 'Thao tác',
                render: (_, row) => (
                  <Space>
                    <Button onClick={() => setPreview(row)}>Xem</Button>
                    <Button onClick={() => setEdit({ row })}>Sửa</Button>
                  </Space>
                ),
              },
            ]}
          />
        )}
      </Panel>
      <History key={historyVersion} session={session} type="POST" />
      {preview && (
        <Modal open title={preview.title} footer={null} onCancel={() => setPreview(undefined)}>
          <p className="muted">
            {preview.category} · {statuses[preview.status]}
          </p>
          {preview.coverUrl && <Cover session={session} url={preview.coverUrl} />}
          <p className="post-preview">{preview.content}</p>
        </Modal>
      )}
      {edit && (
        <Editor
          session={session}
          row={edit.row}
          close={() => setEdit(undefined)}
          reload={() => {
            list.reload();
            setHistoryVersion((n) => n + 1);
          }}
        />
      )}
    </>
  );
}
