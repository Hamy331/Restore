import { useWorkspace } from '../../app/workspace';
import { useState } from 'react';
import { Button, Input, Modal, Select, Space, Table } from 'antd';
import { Session } from '../../shared/api/session';
import { useResource, type Page } from '../../shared/api/useResource';
import { Failure } from '../../shared/ui/Failure';
import { DecisionForm, type Action } from '../moderation/DecisionForm';
import { ListingDetails, listingStatus, type Listing } from './ListingDetails';

export function Listings({ session }: { session: Session }) {
  const { filter } = useWorkspace();
  const [page, setPage] = useState(1),
    [status, setStatus] = useState(filter || 'PENDING'),
    [q, setQuery] = useState('');
  const [item, select] = useState<Listing>(),
    [busy, setBusy] = useState(false);
  const params = new URLSearchParams({ page: String(page), status, q });
  const { data, error, reload } = useResource<Page<Listing>>(session, '/admin/listings?' + params);
  const actions: Action[] =
    item?.status === 'PENDING'
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
          style={{ minWidth: 150 }}
          onChange={(s) => {
            setStatus(s);
            setPage(1);
          }}
          options={Object.entries({ '': 'Tất cả trạng thái', ...listingStatus }).map(
            ([value, label]) => ({ value, label }),
          )}
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
              dataIndex: 'status',
              render: (s: string) => listingStatus[s] ?? s,
            },
            {
              title: 'Chi tiết',
              render: (_, r) => <Button onClick={() => select(r)}>Xem tin</Button>,
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
          title="Chi tiết tin đăng"
          footer={null}
          onCancel={() => !busy && select(undefined)}
          closable={!busy}
          maskClosable={false}
        >
          <ListingDetails session={session} item={item} />
          <DecisionForm
            actions={actions}
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
                updatedAt: item.updatedAt,
              })
            }
          />
        </Modal>
      )}
    </>
  );
}
