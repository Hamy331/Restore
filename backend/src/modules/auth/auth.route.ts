import { Router } from 'express';
import { getMe, login, register, resendRegistrationOtp, verifyRegistrationOtp, forgotPassword, verifyOtp, resetPassword } from './auth.controller.js';
import { verifyToken } from '../../middlewares/auth.middleware.js';

const authRouter = Router();

authRouter.get('/me', verifyToken, getMe);
authRouter.post('/login', login);
authRouter.post('/register', register); 
authRouter.post('/verify-registration-otp', verifyRegistrationOtp);
authRouter.post('/resend-registration-otp', resendRegistrationOtp);
authRouter.post('/forgot-password', forgotPassword);
authRouter.post('/verify-otp', verifyOtp);
authRouter.post('/reset-password', resetPassword);

export default authRouter;