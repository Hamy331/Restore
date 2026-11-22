import { useWorkspace } from '../../app/workspace';
import { useState } from 'react';
import { Button, Input, Modal, Select, Space, Table, Tag } from 'antd';
import { Session } from '../../shared/api/session';
import { useResource, type Page } from '../../shared/api/useResource';
import { Failure } from '../../shared/ui/Failure';
import { DecisionForm, type Action } from '../moderation/DecisionForm';
import { ListingDetails, listingStatus, type Listing } from './ListingDetails';
import { RevisionCompare } from './RevisionCompare';

/** Giá trị bộ lọc riêng: tin đã duyệt có bản sửa đang chờ duyệt (gửi edit=PENDING thay cho status) */
const EDIT_FILTER = 'EDIT';

/** Bản sửa đang chờ duyệt của tin (không tính bản sửa đã bị từ chối) */
const pendingEdit = (item?: Listing) =>
  item?.pendingEdit?.status === 'PENDING' && item.current ? item.pendingEdit : undefined;

export function Listings({ session }: { session: Session }) {
  const { filter } = useWorkspace();
  const [page, setPage] = useState(1),
    [status, setStatus] = useState(filter || 'PENDING'),
    [q, setQuery] = useState('');
  const [item, select] = useState<Listing>(),
    [busy, setBusy] = useState(false);
  const params = new URLSearchParams({ page: String(page), q });
  if (status === EDIT_FILTER) params.set('edit', 'PENDING');
  else params.set('status', status);
  const { data, error, reload } = useResource<Page<Listing>>(session, '/admin/listings?' + params);
  const edit = pendingEdit(item);
  // Tin có bản sửa chờ duyệt: duyệt / từ chối / yêu cầu sửa áp lên bản sửa, gỡ tin áp lên tin
  const actions: Action[] = edit
    ? ['APPROVE', 'REQUEST_CHANGES', 'REJECT', ...(item?.status === 'AVAILABLE' ? (['REMOVE'] as const) : [])]
    : item?.status === 'PENDING'
      ? ['APPROVE', 'REQUEST_CHANGES', 'REJECT']
      : item?.status === 'AVAILABLE'
        ? ['REMOVE']
        : [];
  return (
    <>
      <Space wrap className="notice">
        <Select
          aria-label="Trạng thái tin"
          value={status}
          style={{ minWidth: 190 }}
          onChange={(s) => {
            setStatus(s);
            setPage(1);
          }}
          options={[
            ...Object.entries({ '': 'Tất cả trạng thái', ...listingStatus }).map(([value, label]) => ({
              value,
              label,
            })),
            { value: EDIT_FILTER, label: 'Bản sửa chờ duyệt' },
          ]}
        />
        <Input.Search
          aria-label="Tìm theo tiêu đề"
          placeholder="Tìm theo tiêu đề"
          allowClear
          maxLength={100}
          onSearch={(v) => {
            setQuery(v.trim());
            setPage(1);
          }}
        />
      </Space>
      {error ? (
        <Failure error={error} reload={reload} />
      ) : (
        <Table<Listing>
          rowKey="id"
          loading={!data}
          dataSource={data?.items}
          scroll={{ x: 650 }}
          columns={[
            { title: 'Tin đăng', dataIndex: 'title' },
            { title: 'Người đăng', render: (_, r) => r.owner?.fullName },
            {
              title: 'Trạng thái',
              render: (_, r) => (
                <Space size={4} wrap>
                  {listingStatus[r.status] ?? r.status}
                  {pendingEdit(r) && <Tag color="orange">Có bản sửa chờ duyệt</Tag>}
                </Space>
              ),
            },
            {
              title: 'Chi tiết',
              render: (_, r) => (
                <Button onClick={() => select(r)}>{pendingEdit(r) ? 'So sánh bản sửa' : 'Xem tin'}</Button>
              ),
            },
          ]}
          pagination={{
            current: page,
            total: data?.total,
            pageSize: 25,
            showSizeChanger: false,
            onChange: setPage,
          }}
        />
      )}
      {item && (
        <Modal
          open
          title={edit ? 'Duyệt bản sửa tin đăng' : 'Chi tiết tin đăng'}
          width={edit ? 900 : undefined}
          footer={null}
          onCancel={() => !busy && select(undefined)}
          closable={!busy}
          mask={{ closable: false }}
        >
          {edit && item.current ? (
            <>
              <ListingDetails session={session} item={item} summary />
              <RevisionCompare session={session} current={item.current} edit={edit} />
            </>
          ) : (
            <ListingDetails session={session} item={item} />
          )}
          <DecisionForm
            actions={actions}
            actionLabels={
              edit
                ? {
                    APPROVE: 'Duyệt bản sửa (thay vào tin)',
                    REQUEST_CHANGES: 'Yêu cầu người bán sửa lại',
                    REJECT: 'Từ chối bản sửa (giữ bản cũ)',
                    REMOVE: 'Gỡ cả tin đăng',
                  }
                : undefined
            }
            busy={busy}
            setBusy={setBusy}
            onConflict={reload}
            onSaved={() => {
              select(undefined);
              reload();
            }}
            save={(value) =>
              session.call('/admin/listings/' + encodeURIComponent(item.id) + '/decision', {
                ...value,
                // Quyết định trên bản sửa gửi updatedAt của bản sửa; gỡ tin gửi updatedAt của tin
                updatedAt: edit && value.action !== 'REMOVE' ? edit.updatedAt : item.updatedAt,
              })
            }
          />
        </Modal>
      )}
    </>
  );
}
