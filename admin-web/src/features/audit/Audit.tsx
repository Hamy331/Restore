import { useState } from 'react';
import { Alert, Button, Input, Select, Table } from 'antd';
import { DownloadOutlined } from '@ant-design/icons';
import { auditColumns } from './AuditTable';
import type { Entry } from './auditColumns';
import { actions, modules } from './auditLabels';
import { Session, errorText } from '../../shared/api/session';
import { useResource, type Page } from '../../shared/api/useResource';
import { Failure } from '../../shared/ui/Failure';
import { useWorkspace } from '../../app/workspace';

function downloadCsv(rows: Entry[]) {
  const values = [
    ['Thời điểm', 'Thao tác', 'Phân hệ', 'Đối tượng', 'Lý do', 'Người xử lý'],
    ...rows.map((r) => [
      r.createdAt,
      actions[r.action] ?? r.action,
      modules[r.targetType] ?? r.targetType,
      r.targetId,
      r.reason,
      r.actorId,
    ]),
  ];
  const csv = values
    .map((row) =>
      row
        .map((v) => '"' + (/^[\s]*[=+@-]/.test(v) ? "'" : '') + v.replaceAll('"', '""') + '"')
        .join(','),
    )
    .join('\r\n');
  const url = URL.createObjectURL(new Blob(['\uFEFF', csv], { type: 'text/csv;charset=utf-8' }));
  const a = document.createElement('a');
  a.href = url;
  a.download = 'nhat-ky-quan-tri.csv';
  a.click();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}
export function Audit({ session }: { session: Session }) {
  const { filter } = useWorkspace();
  const [targetType, setType] = useState(filter),
    [q, setQuery] = useState(''),
    [action, setAction] = useState(''),
    [page, setPage] = useState(1);
  const { data, error, reload } = useResource<Page<Entry>>(
    session,
    '/admin/audit?' + new URLSearchParams({ page: String(page), targetType, action, q }),
  );
  const [exporting, setExporting] = useState(false),
    [exportError, setExportError] = useState('');
  async function exportCsv() {
    if (exporting) return;
    setExporting(true);
    setExportError('');
    try {
      const params = new URLSearchParams({
        targetType,
        action,
        q,
        before: new Date().toISOString(),
      });
      const rows: Entry[] = [];
      let next = 1;
      while (true) {
        params.set('page', String(next++));
        const batch = await session.call<Page<Entry>>('/admin/audit?' + params);
        rows.push(...batch.items);
        if (!batch.items.length || rows.length >= batch.total) break;
      }
      downloadCsv(rows);
    } catch (err) {
      setExportError(errorText(err));
    } finally {
      setExporting(false);
    }
  }
  const options = (labels: Record<string, string>) =>
    Object.entries(labels).map(([value, label]) => ({ value, label }));
  return (
    <section className="panel">
      <div className="toolbar">
        <Input.Search
          className="filter-search"
          aria-label="Tìm nhật ký"
          placeholder="Tìm mã đối tượng, người xử lý, lý do"
          allowClear
          maxLength={100}
          onSearch={(v) => {
            setQuery(v.trim());
            setPage(1);
          }}
        />
        <Select
          aria-label="Phân hệ"
          value={targetType}
          options={[{ value: '', label: 'Tất cả phân hệ' }, ...options(modules)]}
          onChange={(v) => {
            setType(v);
            setPage(1);
          }}
        />
        <Select
          aria-label="Thao tác"
          value={action}
          options={[{ value: '', label: 'Tất cả thao tác' }, ...options(actions)]}
          onChange={(v) => {
            setAction(v);
            setPage(1);
          }}
        />
        <span className="toolbar-end">{data && data.total + ' bản ghi'}</span>
        <Button
          disabled={!data?.total}
          loading={exporting}
          icon={<DownloadOutlined />}
          onClick={exportCsv}
        >
          Xuất CSV
        </Button>
      </div>
      {exportError && <Alert type="error" title={exportError} />}{' '}
      {error ? (
        <Failure error={error} reload={reload} />
      ) : (
        <Table
          columns={auditColumns}
          rowKey="id"
          loading={!data}
          dataSource={data?.items}
          scroll={{ x: 850 }}
          locale={{ emptyText: 'Không có bản ghi phù hợp với bộ lọc.' }}
          pagination={{
            current: page,
            total: data?.total,
            pageSize: 25,
            hideOnSinglePage: true,
            showSizeChanger: false,
            onChange: setPage,
          }}
        />
      )}
    </section>
  );
}
