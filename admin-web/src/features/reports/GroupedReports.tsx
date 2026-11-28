import { useEffect, useRef, useState, type Key } from 'react';
import { Button, Form, InputNumber, Select, Space, Table, Tabs, Tag, Typography } from 'antd';
import { ReloadOutlined } from '@ant-design/icons';
import { Session } from '../../shared/api/session';
import { useResource, type Page } from '../../shared/api/useResource';
import { Failure } from '../../shared/ui/Failure';
import type { Report } from './Reports';
import type { GroupPage, ReasonConfig, ReportGroup } from './reportTypes';

type Filters = {
  targetType?: string; reason?: string; minWaitHours?: number; maxWaitHours?: number;
  sort?: 'oldest' | 'newest' | 'most_reports';
};
const groupKey = (row: ReportGroup) => JSON.stringify([row.targetType, row.targetId]);
const dateLabel = (value: string) => new Date(value).toLocaleString('vi-VN');
const hoursLabel = (since: string, asOf: string) =>
  new Intl.NumberFormat('vi-VN', { maximumFractionDigits: 1 }).format(
    Math.max(0, (Date.parse(asOf) - Date.parse(since)) / 3_600_000),
  ) + ' giờ';

function GroupReports({ session, query, group, review, asOf, limit }: {
  session: Session; query: string; group: ReportGroup; review: (report: Report) => void; asOf: string; limit: number;
}) {
  const [page, setPage] = useState(1);
  const params = new URLSearchParams(query);
  params.set('targetType', group.targetType);
  params.set('targetId', group.targetId);
  params.set('page', String(page));
  params.set('limit', String(limit));
  params.set('asOf', asOf);
  const { data, error, reload } = useResource<Page<Report>>(session, '/admin/reports?' + params);
  if (error) return <Failure error={error} reload={reload} />;
  return <Table<Report>
    size="small" rowKey="id" loading={!data} dataSource={data?.items} scroll={{ x: 680 }}
    columns={[
      { title: 'Lý do', dataIndex: 'reason' },
      { title: 'Mô tả', dataIndex: 'evidence', ellipsis: true },
      { title: 'Thời điểm gửi', dataIndex: 'createdAt', render: dateLabel },
      { title: 'Đã chờ', render: (_, row) => row.status === 'OPEN' ? hoursLabel(row.createdAt, asOf) : 'Đã đóng' },
      { title: 'Xử lý', render: (_, row) => <Button onClick={() => review(row)}>Xem báo cáo</Button> },
    ]}
    pagination={{ current: page, total: data?.total, pageSize: limit, showSizeChanger: false, onChange: setPage }}
  />;
}

export function GroupedReports({ session, reasons, revision, review }: {
  session: Session; reasons: ReasonConfig[] | undefined; revision: number; review: (report: Report) => void;
}) {
  const [form] = Form.useForm<Filters>();
  const [status, setStatus] = useState('OPEN');
  const [filters, setFilters] = useState<Filters>({ targetType: 'LISTING', sort: 'oldest' });
  const [page, setPage] = useState(1);
  const [limit, setLimit] = useState<number>();
  const [expanded, setExpanded] = useState<Key[]>([]);
  const params = new URLSearchParams({ page: String(page), status });
  if (limit) params.set('limit', String(limit));
  if (filters.targetType) params.set('targetType', filters.targetType);
  if (filters.reason === '__legacy__') params.set('uncategorized', 'true');
  else if (filters.reason) params.set('reasonCode', filters.reason);
  if (filters.sort) params.set('sort', filters.sort);
  if (status === 'OPEN') {
    if (filters.minWaitHours !== undefined && filters.minWaitHours !== null) params.set('minWaitHours', String(filters.minWaitHours));
    if (filters.maxWaitHours !== undefined && filters.maxWaitHours !== null) params.set('maxWaitHours', String(filters.maxWaitHours));
  }
  const query = params.toString();
  const { data, error, reload } = useResource<GroupPage>(session, '/admin/report-groups?' + query);
  const seenRevision = useRef(revision);
  useEffect(() => {
    if (seenRevision.current !== revision) { seenRevision.current = revision; reload(); }
  }, [revision, reload]);

  return <section className="panel">
    <Tabs activeKey={status} onChange={value => {
      setStatus(value); setPage(1); setExpanded([]);
      form.setFieldsValue({ minWaitHours: undefined, maxWaitHours: undefined });
      setFilters(previous => ({ ...previous, minWaitHours: undefined, maxWaitHours: undefined }));
    }} items={[
      { key: 'OPEN', label: 'Đang chờ' }, { key: 'RESOLVED', label: 'Đã xử lý' },
      { key: 'DISMISSED', label: 'Đã bác' }, { key: '', label: 'Tất cả' },
    ]} />
    <Form form={form} layout="inline" initialValues={filters} onFinish={values => {
      setFilters(values); setPage(1); setExpanded([]);
    }} style={{ gap: 12, marginBottom: 20, alignItems: 'flex-start' }}>
      <Form.Item name="targetType" label="Đối tượng">
        <Select allowClear placeholder="Tất cả" style={{ width: 160 }} options={[
          { value: 'LISTING', label: 'Tin đăng' }, { value: 'USER', label: 'Thành viên' }, { value: 'FEED_POST', label: 'Bài viết bảng tin' }, { value: 'REVIEW', label: 'Đánh giá' },
        ]} />
      </Form.Item>
      <Form.Item name="reason" label="Lý do">
        <Select allowClear showSearch optionFilterProp="label" placeholder="Tất cả lý do"
          loading={!reasons} disabled={!reasons} style={{ width: 250 }} options={[
            ...(reasons ?? []).map(reason => ({ value: reason.code, label: reason.labelVi + (reason.active ? '' : ' (đã tắt)') })),
            { value: '__legacy__', label: 'Báo cáo cũ / không có mã lý do' },
          ]} />
      </Form.Item>
      <Form.Item name="minWaitHours" label="Chờ từ (giờ)">
        <InputNumber min={0} disabled={status !== 'OPEN'} placeholder="Không giới hạn" style={{ width: 150 }} />
      </Form.Item>
      <Form.Item name="maxWaitHours" label="Đến (giờ)" dependencies={['minWaitHours']}
        rules={[({ getFieldValue }) => ({ validator(_, value) {
          const min = getFieldValue('minWaitHours');
          return value == null || min == null || value >= min ? Promise.resolve() : Promise.reject(new Error('Giờ tối đa phải lớn hơn hoặc bằng tối thiểu.'));
        } })]}>
        <InputNumber min={0} disabled={status !== 'OPEN'} placeholder="Không giới hạn" style={{ width: 150 }} />
      </Form.Item>
      <Form.Item name="sort" label="Sắp xếp">
        <Select style={{ width: 200 }} options={[
          { value: 'oldest', label: 'Báo cáo cũ nhất trước' },
          { value: 'most_reports', label: 'Nhiều báo cáo nhất' },
          { value: 'newest', label: 'Báo cáo mới nhất trước' },
        ]} />
      </Form.Item>
      <Form.Item><Space><Button type="primary" htmlType="submit">Áp dụng</Button>
        <Button icon={<ReloadOutlined />} onClick={reload}>Làm mới</Button></Space></Form.Item>
    </Form>
    {data && <Typography.Paragraph type="secondary">
      {data.total} đối tượng · {data.reportCount} báo cáo khớp bộ lọc. Thời gian chờ tính lúc {dateLabel(data.asOf)}.
    </Typography.Paragraph>}
    {error ? <Failure error={error} reload={reload} /> : <Table<ReportGroup>
      rowKey={groupKey} loading={!data} dataSource={data?.items} scroll={{ x: 900 }}
      locale={{ emptyText: 'Không có báo cáo khớp bộ lọc.' }}
      columns={[
        { title: 'Tin / đối tượng bị báo cáo', render: (_, row) => <>
          <strong>{row.listing?.title ?? (row.targetType === 'USER' ? 'Thành viên' : row.targetType === 'FEED_POST' ? 'Bài viết bảng tin' : row.targetType === 'REVIEW' ? 'Đánh giá' : 'Tin không còn tồn tại')}</strong>
          <div><Typography.Text type="secondary" copyable>{row.targetId}</Typography.Text></div>
        </> },
        { title: 'Số báo cáo khớp', dataIndex: 'reportCount', width: 140 },
        { title: 'Lý do', render: (_, row) => <Space wrap>{row.reasons.map(reason =>
          <Tag key={JSON.stringify([reason.code, reason.label])}>{reason.label} · {reason.count}</Tag>)}</Space> },
        { title: status === 'OPEN' ? 'Chờ lâu nhất' : 'Báo cáo đầu tiên', render: (_, row) => <>
          {status === 'OPEN' && data && <div>{hoursLabel(row.oldestAt, data.asOf)}</div>}{dateLabel(row.oldestAt)}
        </> },
        { title: 'Gửi gần nhất', dataIndex: 'latestAt', render: dateLabel },
        { title: 'Chi tiết', render: (_, row) => <Button onClick={() => {
          const key = groupKey(row);
          setExpanded(current => current.includes(key) ? current.filter(item => item !== key) : [...current, key]);
        }}>Xem báo cáo</Button> },
      ]}
      expandable={{ expandedRowKeys: expanded, onExpandedRowsChange: keys => setExpanded([...keys]),
        expandedRowRender: group => data && <GroupReports key={groupKey(group) + query + revision} session={session}
          query={query} group={group} review={review} asOf={data.asOf} limit={data.limit} /> }}
      pagination={{ current: page, total: data?.total, pageSize: data?.limit, showSizeChanger: true,
        onChange: (current, size) => { setPage(current); setLimit(size); setExpanded([]); } }}
    />}
  </section>;
}
