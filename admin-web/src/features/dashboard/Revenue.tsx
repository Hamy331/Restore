import { useState } from 'react';
import { Segmented, Tooltip } from 'antd';
import { WalletOutlined } from '@ant-design/icons';
import { Panel } from '../../shared/ui/Panel';
import { vnd } from '../commerce/PackageFields';

export type Insights = {
  asOf: string;
  categories: number;
  openTickets: number;
  daily: { day: string; packageId: string; amount: string; orders: number }[];
  packages: { id: string; name: string; price: string; active: boolean }[];
};
const periods = [
  { value: 7, label: '7 ngày' },
  { value: 30, label: '30 ngày' },
  { value: 12, label: '12 tháng' },
];
function calendarKeys(asOf: string, period: number) {
  const today = new Intl.DateTimeFormat('sv-SE', { timeZone: 'Asia/Ho_Chi_Minh' }).format(
    new Date(asOf),
  );
  return Array.from({ length: period }, (_, i) => {
    const d = new Date(today + 'T00:00:00Z');
    if (period === 12) {
      d.setUTCDate(1);
      d.setUTCMonth(d.getUTCMonth() - 11 + i);
    } else d.setUTCDate(d.getUTCDate() - period + 1 + i);
    return d.toISOString().slice(0, period === 12 ? 7 : 10);
  });
}
export function Revenue({ insights }: { insights: Insights }) {
  const [period, setPeriod] = useState(7);
  const keys = calendarKeys(insights.asOf, period);
  const series = new Map(keys.map((key) => [key, 0]));
  const totals = new Map<string, { amount: number; orders: number }>();
  let sum = 0,
    orders = 0;
  for (const row of insights.daily) {
    const key = row.day.slice(0, keys[0].length);
    if (!series.has(key)) continue;
    const amount = Number(row.amount);
    series.set(key, series.get(key)! + amount);
    const pack = totals.get(row.packageId) ?? { amount: 0, orders: 0 };
    totals.set(row.packageId, { amount: pack.amount + amount, orders: pack.orders + row.orders });
    sum += amount;
    orders += row.orders;
  }
  const max = Math.max(1, ...series.values());
  const packages = insights.packages.filter((p) => p.active || totals.has(p.id));
  const label = (s: string) => s.split('-').reverse().slice(0, 2).join('/');
  return (
    <Panel
      title="Doanh thu đẩy tin"
      detail="Theo ngày xác nhận thanh toán"
      action={
        <Segmented
          aria-label="Khoảng thời gian"
          size="small"
          options={periods}
          value={period}
          onChange={setPeriod}
        />
      }
    >
      <div className="revenue-summary">
        <strong>{vnd(sum)}</strong>
        <small>
          {orders} giao dịch đã xác nhận · {periods.find((p) => p.value === period)?.label} qua
        </small>
      </div>
      <div className="chart-wrap">
        <div className="chart" aria-label="Biểu đồ doanh thu">
          {[...series].map(([key, amount]) => (
            <Tooltip key={key} title={label(key) + ' · ' + vnd(amount)}>
              <div className="bar-slot" aria-label={label(key) + ' · ' + vnd(amount)}>
                <div
                  className="bar"
                  style={{ height: (amount / max) * 96 + '%', minHeight: amount ? 3 : 0 }}
                />
              </div>
            </Tooltip>
          ))}
          {!orders && (
            <span className="chart-empty">
              <WalletOutlined /> Chưa có giao dịch trong kỳ
            </span>
          )}
        </div>
        <div className="chart-axis">
          <span>{label(keys[0])}</span>
          <span>{label(keys[Math.floor(period / 2)])}</span>
          <span>{label(keys[period - 1])}</span>
        </div>
      </div>
      {!!packages.length && (
        <div className="package-grid">
          {packages.map((p) => (
            <div key={p.id}>
              <b>{p.name}</b>
              <small>{vnd(p.price)}</small>
              <small>
                {totals.get(p.id)?.orders ?? 0} đơn · {vnd(totals.get(p.id)?.amount ?? 0)}
              </small>
            </div>
          ))}
        </div>
      )}
    </Panel>
  );
}
