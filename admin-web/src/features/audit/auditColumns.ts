export type Entry = {
  id: string;
  action: string;
  targetType: string;
  targetId: string;
  actorId: string;
  actor: { fullName: string; email: string } | null;
  reason: string;
  createdAt: string;
};
/** Tên người xử lý; tài khoản đã xoá thì hiện mã */
export const actorName = (r: Entry) => r.actor?.fullName ?? r.actorId;
