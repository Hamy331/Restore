import { Router } from 'express';
import { adminRouter } from './modules/admin/index.js';
import { authRouter } from './modules/auth/index.js';
import { catalogRouter } from './modules/catalog/index.js';
import { homeRouter } from './modules/home/index.js';
import { promotionRouter, storeRouter } from './modules/commerce/index.js';
import { contentRouter } from './modules/content/index.js';
import { listingsRouter } from './modules/listings/index.js';
import { usersRouter } from './modules/users/index.js';
import { wantedAlertRouter } from './modules/wanted-alerts/index.js';

/** Toàn bộ API, gắn dưới tiền tố /api/v1 trong app.ts. */
export const apiRouter = Router();

apiRouter.use('/auth', authRouter);
apiRouter.use('/users', usersRouter);
apiRouter.use('/home', homeRouter);

apiRouter.use('/listings', listingsRouter);
apiRouter.use('/wanted-alerts', wantedAlertRouter);

apiRouter.use('/stores', storeRouter);
apiRouter.use('/promotions', promotionRouter);
apiRouter.use('/content', contentRouter);
apiRouter.use('/admin', adminRouter);
// catalog gắn ở gốc: /categories, /conditions, /locations/...
apiRouter.use('/', catalogRouter);
