import { useState } from 'react';
import { Button, Table } from 'antd';
import { useResource } from '../../shared/api/useResource';
import { Session } from '../../shared/api/session';
import { Failure } from '../../shared/ui/Failure';
import { EditDialog } from '../../shared/ui/EditDialog';
import { PackageName, PriceField, NumberField, vnd } from './PackageFields';

type Fields = {
  name: string;
  monthlyPrice: string;
  dailyListingLimit: number;
  activeListingLimit: number;
  draftLimit: number;
  monthlyPromotionQuota: number;
  priorityLevel: number;
};
type StorePackage = Fields & { id: string; tier: string };
export function StorePackages({ session }: { session: Session }) {
  const { data, error, reload } = useResource<StorePackage[]>(session, '/admin/store-packages');
  const [row, edit] = useState<StorePackage>();
  const personal = row?.tier === 'PERSONAL';
  if (error) return <Failure error={error} reload={reload} />;
  return (
    <>
      <Table<StorePackage>
        rowKey="id"
        dataSource={data}
        loading={!data}
        pagination={false}
        scroll={{ x: 620 }}
        columns={[
          { title: 'Tên gói', dataIndex: 'name' },
          { title: 'Giá mỗi tháng', dataIndex: 'monthlyPrice', render: vnd },
          { title: 'Tin mỗi ngày', dataIndex: 'dailyListingLimit' },
          { title: 'Tin đang hiển thị', dataIndex: 'activeListingLimit' },
          { title: '', render: (_, r) => <Button onClick={() => edit(r)}>Sửa gói</Button> },
        ]}
      />
      {row && (
        <EditDialog<Fields>
          title={'Sửa gói ' + row.name}
          initialValues={row}
          close={() => edit(undefined)}
          saved={reload}
          save={(v) =>
            session.put('/admin/store-packages/' + encodeURIComponent(row.id), {
              ...v,
              name: v.name.trim(),
            })
          }
        >
          <PackageName />
          <PriceField name="monthlyPrice" disabled={personal} free />
          <NumberField
            name="dailyListingLimit"
            label="Số tin được đăng mỗi ngày"
            min={1}
            max={10000}
          />
          <NumberField
            name="activeListingLimit"
            label="Số tin đang hiển thị tối đa"
            min={1}
            max={100000}
          />
          <NumberField name="draftLimit" label="Số tin nháp tối đa" min={1} max={1000} />
          <NumberField
            name="monthlyPromotionQuota"
            label="Lượt đẩy tin mỗi tháng"
            min={0}
            max={10000}
            disabled={personal}
          />
          <NumberField
            name="priorityLevel"
            label="Mức ưu tiên"
            min={0}
            max={10}
            disabled={personal}
          />
        </EditDialog>
      )}
    </>
  );
}
