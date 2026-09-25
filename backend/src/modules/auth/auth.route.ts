import { Router } from 'express';
import { getMe, login, register } from './auth.controller.js';
import { verifyToken } from '../../middlewares/auth.middleware.js';

const authRouter = Router();

authRouter.get('/me', verifyToken, getMe);
authRouter.post('/login', login);
authRouter.post('/register', register); 

export default authRouter;