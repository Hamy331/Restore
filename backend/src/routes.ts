import { Router } from 'express';
import adminRouter from './modules/admin/admin.route.js';
import contentRouter from './modules/admin/content.route.js';
import authRouter from './modules/auth/auth.route.js';
import { catalogRouter } from './modules/catalog/catalog.js';
import { homeRouter } from './modules/home/index.js';
import { listingsRouter } from './modules/listings/index.js';
import promotionRouter from './modules/promotions/promotion.route.js';
import storeRouter from './modules/stores/store.route.js';
import { usersRouter } from './modules/users/index.js';

/** Toàn bộ API, gắn dưới tiền tố /api/v1 trong app.ts. */
export const apiRouter = Router();

apiRouter.use('/auth', authRouter);
apiRouter.use('/users', usersRouter);
apiRouter.use('/home', homeRouter);

apiRouter.use('/listings', listingsRouter);

apiRouter.use('/stores', storeRouter);
apiRouter.use('/promotions', promotionRouter);
apiRouter.use('/content', contentRouter);
apiRouter.use('/admin', adminRouter);
// catalog gắn ở gốc: /categories, /conditions, /locations/...
apiRouter.use('/', catalogRouter);
