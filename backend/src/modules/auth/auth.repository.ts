import { OtpPurpose, Prisma } from '@prisma/client';
import { prisma } from '../../lib/prisma.js';
import { AppError } from '../../errors/app-error.js';

const publicUserSelect = {
  id: true,
  email: true,
  fullName: true,
  username: true,
  phone: true,
  avatarUrl: true,
  role: true,
  status: true,
  ratingAverage: true,
  ratingCount: true,
  createdAt: true,
  updatedAt: true,
} satisfies Prisma.UserSelect;

export const findUserByEmail = (email: string) =>
  prisma.user.findUnique({ where: { email } });

export const findPublicUserById = (id: string) =>
  prisma.user.findUnique({ where: { id }, select: publicUserSelect });

export const findAuthUserById = (id: string) =>
  prisma.user.findUnique({
    where: { id },
    select: {
      id: true,
      email: true,
      role: true,
      status: true,
      authVersion: true,
    },
  });

export const findUserByUsername = (username: string) =>
  prisma.user.findUnique({ where: { username } });

export const createUnverifiedUser = (data: {
  email: string;
  username: string;
  fullName: string;
  password: string;
  otpCode: string;
  otpExpires: Date;
}) =>
  prisma.user.create({
    data: { ...data, status: 'UNVERIFIED', otpPurpose: 'REGISTER' },
  });

export const updateUnverifiedUser = (
  id: string,
  data: {
    username: string;
    fullName: string;
    password: string;
    otpCode: string;
    otpExpires: Date;
  },
) =>
  prisma.user.update({
    where: { id },
    data: {
      ...data,
      otpPurpose: 'REGISTER',
      otpAttempts: 0,
    },
  });

export const setOtp = (
  id: string,
  data: { otpCode: string; otpExpires: Date; otpPurpose: OtpPurpose },
) =>
  prisma.user.update({
    where: { id },
    data: { ...data, otpAttempts: 0 },
  });

export const markOtpSent = (id: string) =>
  prisma.user.update({ where: { id }, data: { otpLastSentAt: new Date() } });

export const incrementOtpAttempts = (id: string) =>
  prisma.user.update({ where: { id }, data: { otpAttempts: { increment: 1 } } });

export const activateUserAndClearOtp = (id: string) =>
  prisma.user.update({
    where: { id },
    data: {
      status: 'ACTIVE',
      otpCode: null,
      otpExpires: null,
      otpPurpose: null,
      otpAttempts: 0,
      otpLastSentAt: null,
    },
  });

export const updatePasswordAndRevokeSessions = async (id: string, password: string) =>
  prisma.$transaction([
    prisma.user.update({
      where: { id },
      data: {
        password,
        authVersion: { increment: 1 },
        otpCode: null,
        otpExpires: null,
        otpPurpose: null,
        otpAttempts: 0,
        otpLastSentAt: null,
      },
    }),
    prisma.authSession.updateMany({
      where: { userId: id, revokedAt: null },
      data: { revokedAt: new Date() },
    }),
  ]);

export const createSession = (data: {
  id: string;
  userId: string;
  tokenHash: string;
  expiresAt: Date;
}) => prisma.authSession.create({ data });

export const findSessionWithUser = (id: string) =>
  prisma.authSession.findUnique({ where: { id }, include: { user: true } });

export const rotateSession = async (
  oldSessionId: string,
  next: { id: string; userId: string; tokenHash: string; expiresAt: Date },
) => {
  await prisma.$transaction(async (tx) => {
    const revoked = await tx.authSession.updateMany({
      where: { id: oldSessionId, revokedAt: null },
      data: { revokedAt: new Date() },
    });
    if (revoked.count !== 1) {
      throw new AppError(401, 'REFRESH_TOKEN_REUSED', 'Phiên đăng nhập đã hết hiệu lực.');
    }
    await tx.authSession.create({ data: next });
  });
};

export const revokeSession = (id: string) =>
  prisma.authSession.updateMany({
    where: { id, revokedAt: null },
    data: { revokedAt: new Date() },
  });
