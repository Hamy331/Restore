import { Request, Response } from 'express';
import * as authService from './auth.service.js';

export const getMe = async (req: any, res: Response) => {
  return res.status(200).json({
    success: true,
    message: 'User information retrieved successfully',
    data: req.user 
  });
};

export const login = async (req: Request, res: Response) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required.' });
    }

    const result = await authService.loginUser(email, password);
    
    return res.status(200).json({
      success: true,
      message: 'Login successful',
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
        return res.status(400).json({ error: 'Please fill in all required fields.' });
      }
  
      const newUser = await authService.registerUser({ email, password, username, fullName });
      
      return res.status(201).json({
        success: true,
        message: 'Account registered successfully',
        data: newUser,
      });
    } catch (error: any) {
      return res.status(400).json({ success: false, error: error.message });
    }
  };