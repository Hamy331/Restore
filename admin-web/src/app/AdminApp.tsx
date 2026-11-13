import { useState } from 'react';
import { Alert, Button, Card, Drawer, Form, Grid, Input, Menu, Typography } from 'antd';
import type { MenuProps } from 'antd';
import { Session, errorText } from '../shared/api/session';
import { CalendarOutlined, LogoutOutlined, SyncOutlined } from '@ant-design/icons';
import { MarketplaceLink } from './MarketplaceLink';
import { WorkspaceContext } from './workspace';
import { sections } from './navigation';

type NavigationProps = {
  items: MenuProps['items'];
  selected: string;
  onSelect: (key: string) => void;
};

function Brand() {
  return (
    <div className="identity">
      <span className="logo">
        <SyncOutlined />
      </span>
      <div>
        <b>ReStore</b>
        <small>Bảng quản trị</small>
      </div>
    </div>
  );
}
function Navigation({ items, selected, onSelect }: NavigationProps) {
  return (
    <nav aria-label="Menu quản trị">
      <Menu
        mode="inline"
        selectedKeys={[selected]}
        items={items}
        onClick={({ key }) => onSelect(key)}
      />
    </nav>
  );
}

function MobileNavigation(props: NavigationProps) {
  const [open, setOpen] = useState(false);
  return (
    <>
      <Button aria-label="Mở menu quản trị" aria-expanded={open} onClick={() => setOpen(true)}>
        <span aria-hidden="true">☰</span>
      </Button>
      <Drawer
        title="Menu quản trị"
        placement="left"
        size={252}
        open={open}
        onClose={() => setOpen(false)}
        styles={{ body: { padding: '12px 8px' } }}
      >
        <Navigation
          {...props}
          onSelect={(key) => {
            props.onSelect(key);
            setOpen(false);
          }}
        />
        <MarketplaceLink />
      </Drawer>
    </>
  );
}

export function AdminApp() {
  const { lg: desktop } = Grid.useBreakpoint();
  const [auth, setAuth] = useState<Awaited<ReturnType<typeof Session.login>>>();
  const [filter, setFilter] = useState('');
  const [key, select] = useState('dashboard'),
    [busy, setBusy] = useState(false),
    [error, setError] = useState('');
  async function login({ email, password }: { email: string; password: string }) {
    if (busy) return;
    setBusy(true);
    setError('');
    try {
      setAuth(
        await Session.login(email.trim(), password, () => {
          setAuth(undefined);
          setError('Phiên đăng nhập đã hết hạn.');
        }),
      );
      select('dashboard');
      setFilter('');
    } catch (err) {
      setError(errorText(err));
    } finally {
      setBusy(false);
    }
  }
  async function logout() {
    if (!auth || busy) return;
    setBusy(true);
    try {
      await auth.session.logout();
    } catch {
      setError('Đã đóng phiên trên tab này. Máy chủ chưa xác nhận đăng xuất.');
    } finally {
      setAuth(undefined);
      setBusy(false);
    }
  }
  if (!auth)
    return (
      <main className="login">
        <Card className="login-card">
          <div className="brand">ReStore</div>
          <Typography.Title level={2}>Đăng nhập quản trị</Typography.Title>
          <Form layout="vertical" onFinish={login}>
            <Form.Item
              name="email"
              label="Email"
              rules={[{ required: true, type: 'email', message: 'Nhập địa chỉ email hợp lệ.' }]}
            >
              <Input autoComplete="username" />
            </Form.Item>
            <Form.Item
              name="password"
              label="Mật khẩu"
              rules={[{ required: true, message: 'Nhập mật khẩu.' }]}
            >
              <Input.Password autoComplete="current-password" />
            </Form.Item>
            {error && <Alert type="error" title={error} className="notice" />}
            <Button type="primary" block htmlType="submit" loading={busy}>
              Đăng nhập
            </Button>
          </Form>
        </Card>
      </main>
    );
  const visible = sections.filter((item) => auth.admin.permissions.includes(item.permission));
  const active = visible.find((item) => item.key === key) ?? visible[0];
  const View = active.View;
  function openSection(next: string, nextFilter = '') {
    if (!visible.some((item) => item.key === next)) return;
    select(next);
    setFilter(nextFilter);
    window.scrollTo(0, 0);
  }
  const groups = [...new Set(visible.map((item) => item.group))];
  const items: MenuProps['items'] = groups.flatMap((group): NonNullable<MenuProps['items']> => {
    const children = visible
      .filter((item) => item.group === group)
      .map(({ key, label, icon: Icon }) => ({ key, label, icon: <Icon /> }));
    return group ? [{ type: 'group' as const, key: group, label: group, children }] : children;
  });
  const navigation = { items, selected: active.key, onSelect: openSection };
  const date = new Date().toLocaleDateString('vi-VN', {
    weekday: 'long',
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  });
  const name = auth.admin.fullName;
  return (
    <WorkspaceContext.Provider
      value={{ openSection, canOpen: (id) => visible.some((s) => s.key === id), filter }}
    >
      <div className="workspace">
        {desktop && (
          <aside className="admin-sidebar">
            <Brand />
            <Navigation {...navigation} />
            <MarketplaceLink />
          </aside>
        )}
        <div className="workspace-body">
          <header className="admin-header">
            {!desktop && <MobileNavigation {...navigation} />}
            <div className="crumb">
              <span>Quản trị</span>
              <i>›</i>
              <b>{active.label}</b>
            </div>
            <div className="account-area">
              <span className="date-chip">
                <CalendarOutlined /> {date}
              </span>
              <div className="account-chip">
                <span className="avatar">{name.slice(0, 2).toUpperCase()}</span>
                <div className="account-name">
                  <b>{name}</b>
                  <small>Quản trị viên</small>
                </div>
                <Button
                  type="text"
                  icon={<LogoutOutlined />}
                  aria-label="Đăng xuất"
                  loading={busy}
                  onClick={logout}
                >
                  <span className="logout-label">Đăng xuất</span>
                </Button>
              </div>
            </div>
          </header>
          <main className="content" key={active.key}>
            <div className="page-heading">
              {active.key === 'dashboard' && <div className="date-kicker">{date}</div>}
              <h1>{active.label}</h1>
              <p>{active.detail}</p>
            </div>
            <div
              className={
                ['dashboard', 'reports', 'posts', 'audit', 'members'].includes(active.key)
                  ? 'page-sections'
                  : 'panel module-panel'
              }
            >
              <View session={auth.session} />
            </div>
          </main>
        </div>
      </div>
    </WorkspaceContext.Provider>
  );
}
