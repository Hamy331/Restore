import { Tabs } from 'antd';
import { Session } from '../../shared/api/session';
import { StorePackages } from './StorePackages';
import { PromotionPackages } from './PromotionPackages';
import { Orders } from './Orders';

export function Stores({ session }: { session: Session }) {
  return (
    <Tabs
      defaultActiveKey="orders"
      destroyOnHidden
      items={[
        { key: 'packages', label: 'Gói cửa hàng', children: <StorePackages session={session} /> },
        { key: 'orders', label: 'Đơn mua', children: <Orders kind="store" session={session} /> },
      ]}
    />
  );
}
export function Promotions({ session }: { session: Session }) {
  return (
    <Tabs
      defaultActiveKey="orders"
      destroyOnHidden
      items={[
        {
          key: 'packages',
          label: 'Gói đẩy tin',
          children: <PromotionPackages session={session} />,
        },
        {
          key: 'orders',
          label: 'Đơn mua',
          children: <Orders kind="promotion" session={session} />,
        },
      ]}
    />
  );
}
