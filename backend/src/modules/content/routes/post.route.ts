import { Router } from 'express';
import { validate } from '../../../middlewares/validate.middleware.js';
import { pageOnlyQuery, slugParams } from '../content.validator.js';
import * as postController from '../controllers/post.controller.js';

/** Bài viết công khai, gắn tại /api/v1/content */
const postRouter = Router();

/**
 * Bài viết đã đăng, mới trước, 20 bài mỗi trang
 *
 * Query params:
 *  - page?: number (mặc định 1)
 *
 * Trả về: { items: [{ id, slug, title, category, coverUrl, createdAt }] }
 */
postRouter.get('/posts', validate({ query: pageOnlyQuery }), postController.list);

/**
 * Một bài viết đã đăng kèm các tin liên quan còn hiển thị
 *
 * Path params:
 *  - slug: string
 *
 * Trả về: BlogPost + listings [{ id, title, price, images }]
 */
postRouter.get('/posts/:slug', validate({ params: slugParams }), postController.getBySlug);

export default postRouter;
