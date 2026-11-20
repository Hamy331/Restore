import { Router } from 'express';
import { PERMISSION } from '../../../../common/auth/permissions.js';
import { requirePermission } from '../../../../middlewares/auth.middleware.js';
import * as controller from '../controllers/assistant.controller.js';

export const assistantRouter = Router();
assistantRouter.use(requirePermission(PERMISSION.LISTING_MANAGE_OWN, PERMISSION.STORE_PURCHASE));
assistantRouter.post('/conversations/:id/messages', controller.send);
assistantRouter.post('/conversations/:id/messages/stream', controller.stream);
assistantRouter.get('/conversations/:id', controller.history);
assistantRouter.get('/conversations', controller.list);
assistantRouter.delete('/conversations/:id', controller.remove);
