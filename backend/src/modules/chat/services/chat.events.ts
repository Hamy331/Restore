import { Response } from 'express';

const listeners = new Map<string, Set<Response>>();

export const subscribe = (userId: string, res: Response) => {
  const group = listeners.get(userId) ?? new Set<Response>();
  group.add(res);
  listeners.set(userId, group);
  const keepAlive = setInterval(() => res.write(': keep-alive\n\n'), 25000);
  res.on('close', () => {
    clearInterval(keepAlive);
    group.delete(res);
    if (!group.size) listeners.delete(userId);
  });
};

export const publish = (userIds: string[], event: string, data: unknown) => {
  const payload = `event: ${event}\ndata: ${JSON.stringify(data)}\n\n`;
  for (const userId of new Set(userIds)) {
    for (const res of listeners.get(userId) ?? []) res.write(payload);
  }
};
