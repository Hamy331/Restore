import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

export interface AuthRequest extends Request {
  user?: any;
}

const JWT_SECRET = process.env.JWT_SECRET || 'supersecretkey';

export const verifyToken = (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    // 1. Lấy token từ header 'Authorization'
    const authHeader = req.headers.authorization;
    
    // Chuẩn là: "Bearer eyJhbGciOiJIUz..."
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Token not found or invalid authorization format.' });
    }

    // 2. Cắt lấy đúng phần chuỗi token (bỏ chữ Bearer và dấu cách)
    const token = authHeader.split(' ')[1];

    // 3. Giải mã và kiểm tra tính hợp lệ của Token
    const decoded = jwt.verify(token, JWT_SECRET);

    // 4. Nhét thông tin user (id, role...) vào request để các Controller phía sau dùng
    req.user = decoded;

    // 5. Cho phép đi tiếp vào Controller
    next();
  } catch (error: any) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Session expired. Please login again.' });
    }
    return res.status(401).json({ error: 'Invalid token.' });
  }
};