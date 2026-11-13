import { createRoot } from 'react-dom/client';
import { ConfigProvider } from 'antd';
import viVN from 'antd/locale/vi_VN';
import { AdminApp } from './app/AdminApp';
import './style.css';
createRoot(document.getElementById('root')!).render(
  <ConfigProvider
    locale={viVN}
    theme={{
      token: {
        colorPrimary: '#bb430c',
        colorText: '#242427',
        colorBorderSecondary: '#ececee',
        borderRadius: 10,
        fontFamily: 'Inter, Segoe UI, Arial, sans-serif',
      },
      components: {
        Menu: { itemSelectedBg: '#f6f5f4', itemSelectedColor: '#aa3c0b' },
        Table: { headerBg: '#fafafa' },
      },
    }}
  >
    <AdminApp />
  </ConfigProvider>,
);
