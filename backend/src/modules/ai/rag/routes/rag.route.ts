import { Router } from 'express';
import { PERMISSION } from '../../../../common/auth/permissions.js';
import { requirePermission } from '../../../../middlewares/auth.middleware.js';
import * as controller from '../controllers/rag.controller.js';

export const ragRouter = Router();
ragRouter.use(requirePermission(PERMISSION.CONTENT_MANAGE));
ragRouter.post('/documents/:id/index', controller.index);
ragRouter.get('/documents/:id/index', controller.status);
ragRouter.post('/cleanup', controller.cleanup);
