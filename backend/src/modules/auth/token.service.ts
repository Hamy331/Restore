import { createHash, randomUUID, timingSafeEqual } from 'node:crypto';
import jwt, { JwtPayload } from 'jsonwebtoken';
import { Role } from '@prisma/client';
import { getRequiredEnv, getSecuritySecret } from '../../config/env.js';
import { AppError } from '../../errors/app-error.js';
import * as repository from './auth.repository.js';

const ISSUER = 'restore-api';
const AUDIENCE = 'restore-mobile';
const ACCESS_TTL_SECONDS = 15 * 60;
const REFRESH_TTL_SECONDS = 30 * 24 * 60 * 60;
const RESET_TTL_SECONDS = 10 * 60;

type AuthUser = { id: string; email: string; role: Role; authVersion: number };
type TypedPayload = JwtPayload & {
  type?: string;
  email?: string;
  role?: Role;
  authVersion?: number;
};

const hashToken = (token: string) =>
  createHash('sha256').update(token).digest('hex');

const matchesHash = (token: string, storedHash: string) => {
  const candidate = Buffer.from(hashToken(token), 'hex');
  const stored = Buffer.from(storedHash, 'hex');
  return candidate.length === stored.length && timingSafeEqual(candidate, stored);
};

const signAccessToken = (user: AuthUser) =>
  jwt.sign(
    {
      email: user.email,
      role: user.role,
      authVersion: user.authVersion,
      type: 'access',
    },
    getRequiredEnv('JWT_SECRET'),
    {
      subject: user.id,
      issuer: ISSUER,
      audience: AUDIENCE,
      expiresIn: ACCESS_TTL_SECONDS,
    },
  );

const buildRefreshToken = (user: AuthUser) => {
  const sessionId = randomUUID();
  const expiresAt = new Date(Date.now() + REFRESH_TTL_SECONDS * 1000);
  const token = jwt.sign(
    { type: 'refresh' },
    getSecuritySecret('JWT_REFRESH_SECRET'),
    {
      subject: user.id,
      jwtid: sessionId,
      issuer: ISSUER,
      audience: AUDIENCE,
      expiresIn: REFRESH_TTL_SECONDS,
    },
  );
  return { sessionId, token, expiresAt, tokenHash: hashToken(token) };
};

const verifyTypedToken = (token: string, secret: string, type: string) => {
  try {
    const payload = jwt.verify(token, secret, {
      issuer: ISSUER,
      audience: AUDIENCE,
    }) as TypedPayload;
    if (payload.type !== type || !payload.sub) throw new Error('Wrong token type');
    return payload;
  } catch {
    throw new AppError(401, 'INVALID_TOKEN', 'Phiên đăng nhập không hợp lệ hoặc đã hết hạn.');
  }
};

export const issueAuthTokens = async (user: AuthUser) => {
  const refresh = buildRefreshToken(user);
  await repository.createSession({
    id: refresh.sessionId,
    userId: user.id,
    tokenHash: refresh.tokenHash,
    expiresAt: refresh.expiresAt,
  });
  return {
    accessToken: signAccessToken(user),
    refreshToken: refresh.token,
    expiresIn: ACCESS_TTL_SECONDS,
  };
};

export const rotateRefreshToken = async (token: string) => {
  const payload = verifyTypedToken(token, getSecuritySecret('JWT_REFRESH_SECRET'), 'refresh');
  if (!payload.jti) throw new AppError(401, 'INVALID_TOKEN', 'Phiên đăng nhập không hợp lệ.');

  const session = await repository.findSessionWithUser(payload.jti);
  if (
    !session ||
    session.revokedAt ||
    session.expiresAt <= new Date() ||
    !matchesHash(token, session.tokenHash) ||
    session.user.status !== 'ACTIVE'
  ) {
    throw new AppError(401, 'INVALID_REFRESH_TOKEN', 'Phiên đăng nhập đã hết hiệu lực.');
  }

  const user = session.user;
  const refresh = buildRefreshToken(user);
  await repository.rotateSession(session.id, {
    id: refresh.sessionId,
    userId: user.id,
    tokenHash: refresh.tokenHash,
    expiresAt: refresh.expiresAt,
  });
  return {
    accessToken: signAccessToken(user),
    refreshToken: refresh.token,
    expiresIn: ACCESS_TTL_SECONDS,
  };
};

export const revokeRefreshToken = async (token: string) => {
  try {
    const payload = verifyTypedToken(token, getSecuritySecret('JWT_REFRESH_SECRET'), 'refresh');
    if (payload.jti) await repository.revokeSession(payload.jti);
  } catch {
    // Logout is idempotent; local credentials will still be cleared by the client.
  }
};

export const verifyAccessToken = (token: string) => {
  const payload = verifyTypedToken(token, getRequiredEnv('JWT_SECRET'), 'access');
  return {
    userId: payload.sub!,
    email: payload.email,
    role: payload.role,
    authVersion: payload.authVersion,
  };
};

export const issuePasswordResetToken = (user: Pick<AuthUser, 'id' | 'email'>) =>
  jwt.sign(
    { email: user.email, type: 'password-reset' },
    getSecuritySecret('JWT_RESET_SECRET'),
    {
      subject: user.id,
      issuer: ISSUER,
      audience: AUDIENCE,
      expiresIn: RESET_TTL_SECONDS,
    },
  );

export const verifyPasswordResetToken = (token: string) => {
  const payload = verifyTypedToken(
    token,
    getSecuritySecret('JWT_RESET_SECRET'),
    'password-reset',
  );
  return { userId: payload.sub!, email: payload.email ?? '' };
};
