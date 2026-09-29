import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { sendOtpEmail } from '../../services/email.service.js';


const prisma = new PrismaClient();
const JWT_SECRET = process.env.JWT_SECRET || 'supersecretkey';

export const loginUser = async (email: string, password: string) => {
  // 1. Tìm người dùng trong DB
  const user = await prisma.user.findUnique({ where: { email } });
  
  if (!user) {
    throw new Error('Email does not exist in the system.');
  }

  if (user.status === 'UNVERIFIED') {
    throw new Error('Please verify your email to log in.');
  } else if (user.status !== 'ACTIVE') {
    throw new Error('Your account is suspended or disabled.');
  }

  // 2. So sánh mật khẩu bằng bcrypt
  const isMatch = await bcrypt.compare(password, user.password as string);
  if (!isMatch) {
    throw new Error('Incorrect password.');
  }

  // 3. Tạo JWT Token chứa thông tin phân quyền (RBAC)
  const token = jwt.sign(
    { userId: user.id, email: user.email, role: user.role },
    JWT_SECRET,
    { expiresIn: '7d' } // Token sống 7 ngày
  );

  // Xóa password trước khi trả về client
  const { password: _, ...userWithoutPassword } = user;

  return { user: userWithoutPassword, token };
};

export const registerUser = async (data: { email: string; password: string; username: string; fullName: string }) => {
    const { email, password, username, fullName } = data;
  
    // 1. Kiểm tra xem email hoặc username đã tồn tại chưa
    const existingUser = await prisma.user.findFirst({
      where: {
        OR: [{ email }, { username }],
      },
    });
  
    if (existingUser) {
      throw new Error('Email or Username is already in use.');
    }
  
    // 2. Mã hóa mật khẩu
    const hashedPassword = await bcrypt.hash(password, 10);
  
    const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
    const otpExpires = new Date(Date.now() + 15 * 60 * 1000); // 15 mins

    // 3. Tạo tài khoản mới lưu vào Database
    const newUser = await prisma.user.create({
      data: {
        email,
        username,
        fullName,
        password: hashedPassword,
        status: 'UNVERIFIED',
        otpCode,
        otpExpires,
      },
    });
  
    // 4. Gửi OTP qua email
    await sendOtpEmail(email, otpCode);

    // 5. Trả về thông tin user (giấu mật khẩu)
    const { password: _, ...userWithoutPassword } = newUser;
    return userWithoutPassword;
  };

export const resendRegistrationOtp = async (email: string) => {
  const user = await prisma.user.findUnique({ where: { email } });
  if (!user) throw new Error('Không tìm thấy tài khoản.');

  if (user.status !== 'UNVERIFIED') {
    throw new Error('Tài khoản đã được xác thực.');
  }

  const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
  const otpExpires = new Date(Date.now() + 15 * 60 * 1000); // 15 mins

  await prisma.user.update({
    where: { id: user.id },
    data: { otpCode, otpExpires },
  });

  await sendOtpEmail(email, otpCode);
  return { message: 'OTP mới đã được gửi đến email của bạn.' };
};

export const verifyRegistrationOtp = async (email: string, otp: string) => {
  const user = await prisma.user.findUnique({ where: { email } });
  if (!user) throw new Error('Không tìm thấy tài khoản.');

  if (user.status !== 'UNVERIFIED') {
    throw new Error('Tài khoản đã được xác thực.');
  }

  if (!user.otpCode || user.otpCode !== otp) {
    throw new Error('Mã OTP không chính xác.');
  }

  if (!user.otpExpires || user.otpExpires < new Date()) {
    throw new Error('Mã OTP đã hết hạn.');
  }

  // Update status to ACTIVE, clear OTP
  const updatedUser = await prisma.user.update({
    where: { id: user.id },
    data: {
      status: 'ACTIVE',
      otpCode: null,
      otpExpires: null,
    },
  });

  // Generate JWT Token
  const token = jwt.sign(
    { userId: updatedUser.id, email: updatedUser.email, role: updatedUser.role },
    JWT_SECRET,
    { expiresIn: '7d' }
  );

  const { password: _, ...userWithoutPassword } = updatedUser;
  return { user: userWithoutPassword, token };
};

export const forgotPassword = async (email: string) => {
  const user = await prisma.user.findUnique({ where: { email } });
  if (!user) throw new Error('Không tìm thấy tài khoản với email này.');

  // Generate 6 digit OTP
  const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
  const otpExpires = new Date(Date.now() + 15 * 60 * 1000); // 15 mins

  await prisma.user.update({
    where: { id: user.id },
    data: { otpCode, otpExpires },
  });

  await sendOtpEmail(email, otpCode);
  return { message: 'OTP đã được gửi đến email của bạn.' };
};

export const verifyOtp = async (email: string, otp: string) => {
  const user = await prisma.user.findUnique({ where: { email } });
  if (!user) throw new Error('Không tìm thấy tài khoản.');

  if (!user.otpCode || user.otpCode !== otp) {
    throw new Error('Mã OTP không chính xác.');
  }

  if (!user.otpExpires || user.otpExpires < new Date()) {
    throw new Error('Mã OTP đã hết hạn.');
  }

  return { message: 'Xác thực OTP thành công.' };
};

export const resetPassword = async (email: string, otp: string, newPassword: string) => {
  // First verify OTP again
  const user = await prisma.user.findUnique({ where: { email } });
  if (!user || user.otpCode !== otp || !user.otpExpires || user.otpExpires < new Date()) {
    throw new Error('Yêu cầu đổi mật khẩu không hợp lệ hoặc đã hết hạn.');
  }

  const hashedPassword = await bcrypt.hash(newPassword, 10);

  await prisma.user.update({
    where: { id: user.id },
    data: {
      password: hashedPassword,
      otpCode: null,
      otpExpires: null,
    },
  });

  return { message: 'Đổi mật khẩu thành công.' };
};