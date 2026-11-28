import { Server } from 'socket.io';
import type { Server as HttpServer } from 'node:http';
import { verifyAccessToken } from '../../auth/services/token.service.js';
import { findSessionWithUser } from '../../auth/repositories/auth.repository.js';
import { touchPresence, findPeers } from '../repositories/chat.repository.js';

let io: Server | undefined;
const active = new Set<string>();
const pendingOffline = new Map<string, NodeJS.Timeout>();
export const connectedUserIds = () => [...active];
export const isOnline = (id: string) => active.has(id);
export const disconnectUser = (id: string) => io?.in('user:' + id).disconnectSockets(true);
export const disconnectSession = (id: string) => io?.in('session:' + id).disconnectSockets(true);
export function publish(ids: string[], event: string, data: unknown) {
  for (const id of new Set(ids)) io?.to('user:' + id).emit(event, data);
}
async function presence(userId: string, online: boolean) {
  const user = await touchPresence(userId);
  const peers = await findPeers(userId, connectedUserIds());
  if (active.has(userId) === online) publish(peers.map(p => p.userId), 'presence',
    { userId, isOnline: online, lastActiveAt: user.lastActiveAt });
}
export function attachChat(server: HttpServer) {
  const allowed = (process.env.CORS_ORIGINS ?? '').split(',').map(s => s.trim());
  const sockets = new Server(server, { transports: ['websocket'], serveClient: false,
    allowRequest: (req, done) => {
      const origin = req.headers.origin;
      done(null, !origin || allowed.includes(origin) ||
        (process.env.NODE_ENV !== 'production' && /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin)));
    },
  });
  io = sockets;
  sockets.use(async (socket, next) => {
    try {
      const claims = verifyAccessToken(socket.handshake.auth.token);
      const session = claims.sessionId ? await findSessionWithUser(claims.sessionId) : null;
      if (!session || session.revokedAt || session.userId !== claims.userId || session.expiresAt <= new Date()) throw new Error();
      const user = session.user;
      socket.data.sessionId = session.id;
      if (!user || user.status !== 'ACTIVE' || user.authVersion !== claims.authVersion || !claims.exp)
        throw new Error();
      socket.data.userId = user.id;
      socket.data.exp = claims.exp;
      next();
    } catch { next(new Error('AUTH_REQUIRED')); }
  });
  sockets.on('connection', socket => {
    const id: string = socket.data.userId;
    const room = 'user:' + id;
    socket.join(room);
    socket.join('session:' + socket.data.sessionId);
    clearTimeout(pendingOffline.get(id));
    pendingOffline.delete(id);
    if (!active.has(id)) {
      active.add(id);
      void presence(id, true).catch(() => console.warn('Chat presence update failed'));
    }
    const expiry = setTimeout(() => socket.disconnect(true), Math.max(0, socket.data.exp * 1000 - Date.now()));
    socket.on('disconnect', () => {
      clearTimeout(expiry);
      if (sockets.sockets.adapter.rooms.has(room)) return;
      pendingOffline.set(id, setTimeout(() => {
        pendingOffline.delete(id);
        active.delete(id);
        void presence(id, false).catch(() => console.warn('Chat presence update failed'));
      }, 30000).unref());
    });
  });
}
