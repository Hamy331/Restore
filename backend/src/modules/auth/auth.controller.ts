import { Request, Response } from 'express';
import * as authService from './auth.service.js';

export const login = async (req: Request, res: Response) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Vui lòng nhập đầy đủ email và mật khẩu.' });
    }

    const result = await authService.loginUser(email, password);
    
    return res.status(200).json({
      success: true,
      message: 'Đăng nhập thành công',
      data: result,
    });
  } catch (error: any) {
    return res.status(401).json({ success: false, error: error.message });
  }
};

export const register = async (req: Request, res: Response) => {
    try {
      const { email, password, username, fullName } = req.body;
  
      if (!email || !password || !username || !fullName) {
        return res.status(400).json({ error: 'Vui lòng điền đầy đủ thông tin.' });
      }
  
      const newUser = await authService.registerUser({ email, password, username, fullName });
      
      return res.status(201).json({
        success: true,
        message: 'Đăng ký tài khoản thành công',
        data: newUser,
      });
    } catch (error: any) {
      return res.status(400).json({ success: false, error: error.message });
    }
  };