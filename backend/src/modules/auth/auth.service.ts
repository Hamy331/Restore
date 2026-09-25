import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';

const prisma = new PrismaClient();
const JWT_SECRET = process.env.JWT_SECRET || 'supersecretkey';

export const loginUser = async (email: string, password: string) => {
  // 1. Tìm người dùng trong DB
  const user = await prisma.user.findUnique({ where: { email } });
  
  if (!user) {
    throw new Error('Email không tồn tại trong hệ thống.');
  }

  if (user.status !== 'ACTIVE') {
    throw new Error('Tài khoản của bạn đã bị khóa hoặc vô hiệu hóa.');
  }

  // 2. So sánh mật khẩu bằng bcrypt
  const isMatch = await bcrypt.compare(password, user.password as string);
  if (!isMatch) {
    throw new Error('Mật khẩu không chính xác.');
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
      throw new Error('Email hoặc Tên đăng nhập đã được sử dụng.');
    }
  
    // 2. Mã hóa mật khẩu
    const hashedPassword = await bcrypt.hash(password, 10);
  
    // 3. Tạo tài khoản mới lưu vào Database
    const newUser = await prisma.user.create({
      data: {
        email,
        username,
        fullName,
        password: hashedPassword,
      },
    });
  
    // 4. Trả về thông tin user (giấu mật khẩu)
    const { password: _, ...userWithoutPassword } = newUser;
    return userWithoutPassword;
  };