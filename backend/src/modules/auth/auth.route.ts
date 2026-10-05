import { Router } from 'express';
import {
  forgotPassword,
  getMe,
  login,
  logout,
  refresh,
  register,
  resendRegistrationOtp,
  resetPassword,
  verifyOtp,
  verifyRegistrationOtp,
} from './auth.controller.js';
import { authorizeRoles, verifyToken } from '../../middlewares/auth.middleware.js';

const authRouter = Router();

authRouter.get('/me', verifyToken, authorizeRoles('USER', 'ADMIN'), getMe);
authRouter.post('/login', login);
authRouter.post('/register', register); 
authRouter.post('/verify-registration-otp', verifyRegistrationOtp);
authRouter.post('/resend-registration-otp', resendRegistrationOtp);
authRouter.post('/forgot-password', forgotPassword);
authRouter.post('/verify-otp', verifyOtp);
authRouter.post('/reset-password', resetPassword);
authRouter.post('/refresh', refresh);
authRouter.post('/logout', logout);

export default authRouter;
