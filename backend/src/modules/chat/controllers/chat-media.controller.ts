import { createHash, randomUUID } from 'node:crypto';
import jwt from 'jsonwebtoken';
import type { Request, Response, NextFunction } from 'express';
import type { AuthRequest } from '../../../middlewares/auth.middleware.js';
import { getRequiredEnv } from '../../../config/env.js';
import { AppError } from '../../../common/errors/app-error.js';
import { prisma } from '../../../lib/prisma.js';
import { putObject, getObject, removeObject, contentTypeOf } from '../../../services/storage.service.js';
import { imageExtension } from '../../media/media.service.js';
import { parseId } from '../chat.validator.js';
import * as chat from '../repositories/chat.repository.js';
import { publish } from '../services/chat.events.js';

export function attachmentExtension(bytes: Buffer) {
  if (!Buffer.isBuffer(bytes) || bytes.length === 0)
    throw new AppError(415, 'INVALID_MEDIA', 'Tệp không hợp lệ.');
  if (bytes.toString('ascii', 4, 8) === 'ftyp') {
    const brand = bytes.toString('ascii', 8, 12);
    if (brand === 'qt  ') return 'mov';
    if (/^(isom|iso[2-9]|mp4[12]|M4V |avc1)$/.test(brand)) return 'mp4';
  }
  if (
    bytes.subarray(0, 4).equals(Buffer.from([0x1a, 0x45, 0xdf, 0xa3])) &&
    bytes.subarray(0, 128).includes('webm')
  )
    return 'webm';
  return imageExtension(bytes);
}

export async function sendMedia(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const user = req.user!.userId,
      root = await chat.threadFor(parseId(req.params.id, 'id'), user);
    const clientId = parseId(req.query.clientId, 'clientId'),
      bytes = req.body;
    const ext = attachmentExtension(bytes);
    const suffix = '_' + createHash('sha256').update(bytes).digest('hex') + '.' + ext;
    const checkRetry = async () => {
      const existing = await chat.findMessageByClientId(user, clientId);
      if (!existing) return false;
      if (existing.conversationId !== root || !existing.mediaName?.endsWith(suffix))
        throw new AppError(409, 'CLIENT_ID_REUSED', 'Mã tin nhắn đã được sử dụng.');
      res.json({ success: true, data: existing });
      return true;
    };
    if (await checkRetry()) return;
    const name = randomUUID() + suffix;
    await putObject('chat', name, bytes);
    let message;
    try {
      message = await chat.createMessage(
        root,
        user,
        clientId,
        contentTypeOf(name).startsWith('video/') ? 'Video' : 'Hình ảnh',
        undefined,
        name,
      );
    } catch (error) {
      await removeObject('chat', name);
      if (await checkRetry()) return;
      throw error;
    }
    publish(
      (await chat.findMembers(root)).map((m) => m.userId),
      'message',
      message,
    );
    res.status(201).json({ success: true, data: message });
  } catch (error) {
    next(error);
  }
}

const audience = 'restore-chat-attachment';
export async function mediaLink(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const root = await chat.threadFor(parseId(req.params.id, 'id'), req.user!.userId);
    const message = await prisma.message.findFirst({
      where: { id: parseId(req.params.messageId, 'messageId'), conversation: chat.inThread(root) },
      select: { mediaName: true },
    });
    if (!message?.mediaName) throw new AppError(404, 'MEDIA_NOT_FOUND', 'Không tìm thấy tệp.');
    const ticket = jwt.sign({ file: message.mediaName }, getRequiredEnv('JWT_SECRET'), {
      audience,
      expiresIn: '30m',
      algorithm: 'HS256',
    });
    res.setHeader('Cache-Control', 'no-store');
    res.json({ success: true, data: { url: '/api/v1/conversations/media/file?ticket=' + ticket } });
  } catch (error) {
    next(error);
  }
}
export async function readMedia(req: Request, res: Response, next: NextFunction) {
  try {
    let payload;
    try {
      payload = jwt.verify(String(req.query.ticket), getRequiredEnv('JWT_SECRET'), {
        audience,
        algorithms: ['HS256'],
      });
    } catch {
      throw new AppError(403, 'INVALID_MEDIA_LINK', 'Liên kết đã hết hạn.');
    }
    if (typeof payload === 'string' || typeof payload.file !== 'string')
      throw new AppError(403, 'INVALID_MEDIA_LINK', 'Liên kết không hợp lệ.');
    const bytes = await getObject('chat', payload.file);
    if (!bytes) throw new AppError(404, 'MEDIA_NOT_FOUND', 'Không tìm thấy tệp.');
    res
      .type(contentTypeOf(payload.file))
      .set({
        'Cache-Control': 'private, max-age=300',
        'Accept-Ranges': 'bytes',
        'X-Content-Type-Options': 'nosniff',
      });
    const range = req.range(bytes.length);
    if (range === -1) {
      res
        .status(416)
        .set('Content-Range', 'bytes */' + bytes.length)
        .end();
      return;
    }
    if (Array.isArray(range) && range.type === 'bytes' && range.length === 1) {
      const { start, end } = range[0];
      res
        .status(206)
        .set('Content-Range', `bytes ${start}-${end}/${bytes.length}`)
        .send(bytes.subarray(start, end + 1));
      return;
    }
    res.send(bytes);
  } catch (error) {
    next(error);
  }
}
