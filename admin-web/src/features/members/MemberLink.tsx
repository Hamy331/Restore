import { Button } from 'antd';
import { useWorkspace } from '../../app/workspace';

/** Tên · email; admin xem được Thành viên thì bấm để mở hồ sơ (Thành viên tìm theo email) */
export function MemberLink({ person }: { person: { fullName: string; email: string } }) {
  const { canOpen, openSection } = useWorkspace();
  const text = `${person.fullName} · ${person.email}`;
  return canOpen('members') ? (
    <Button
      type="link"
      className="member-link"
      title="Mở hồ sơ thành viên"
      onClick={() => openSection('members', person.email)}
    >
      {text}
    </Button>
  ) : (
    text
  );
}
