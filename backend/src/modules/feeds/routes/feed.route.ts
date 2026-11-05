import { Router } from 'express';
import { verifyToken } from '../../../middlewares/auth.middleware.js';
import * as controller from '../controllers/feed.controller.js';
export const feedRouter = Router();

feedRouter.get('/feeds', verifyToken, controller.listPosts);
feedRouter.post('/feeds', verifyToken, controller.createPost);
feedRouter.delete('/feeds/:id', verifyToken, controller.deletePost);
feedRouter.get('/feeds/:id/comments', verifyToken, controller.listComments);
feedRouter.post('/feeds/:id/comments', verifyToken, controller.createComment);
feedRouter.put('/feeds/:id/like', verifyToken, controller.likePost);
feedRouter.delete('/feeds/:id/like', verifyToken, controller.unlikePost);
feedRouter.put('/feed-comments/:id/like', verifyToken, controller.likeComment);
feedRouter.delete('/feed-comments/:id/like', verifyToken, controller.unlikeComment);
