import { Alert, Button } from 'antd';
export function Failure({ error, reload }: { error: string; reload: () => void }) {
  return <Alert type="error" title={error} action={<Button onClick={reload}>Thử lại</Button>} />;
}
